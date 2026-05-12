# Learn Chinese by Music — 技术设计文档

**日期**：2026-05-06
**状态**：已确认

---

## 1. 系统架构

```
┌──────────────────────────────────────┐
│            Flutter 客户端             │
│  ┌──────────┐ ┌────────┐ ┌────────┐ │
│  │ 播放+歌词 │ │ 跟唱+  │ │ 离线   │ │
│  │ 同步显示  │ │ 本地评分│ │ 存储   │ │
│  └──────────┘ └────────┘ └────────┘ │
└──────────────┬───────────────────────┘
               │ HTTP / CDN
┌──────────────┴───────────────────────┐
│        Python FastAPI 服务端          │
│  ┌─────────┐ ┌──────────┐ ┌───────┐ │
│  │ 用户API  │ │ 歌曲API   │ │社区API│ │
│  └─────────┘ └──────────┘ └───────┘ │
│  ┌─────────┐ ┌──────────┐ ┌───────┐ │
│  │ Auth API │ │支付回调   │ │管理API│ │
│  └─────────┘ └──────────┘ └───────┘ │
└──────────────┬───────────────────────┘
               │
┌──────────────┴───────────────────────┐
│           异步 Worker 层             │
│  ┌──────────────────────────┐       │
│  │  歌词生成 (LLM)           │       │
│  └──────────────────────────┘       │
│  ┌──────────────────────────┐       │
│  │  歌曲生成 (SongBloom)     │       │
│  └──────────────────────────┘       │
│  ┌──────────────────────────┐       │
│  │  人声分离 (Demucs/UVR)    │       │
│  └──────────────────────────┘       │
│  ┌──────────────────────────┐       │
│  │  后处理 (ffmpeg + LRC)    │       │
│  └──────────────────────────┘       │
└──────────────┬───────────────────────┘
               │
┌──────────────┴───────────────────────┐
│              存储层                  │
│  ┌──────────┐    ┌──────────────┐   │
│  │  SQLite  │    │ 对象存储(CDN)│   │
│  └──────────┘    └──────────────┘   │
└──────────────────────────────────────┘
```

---

## 2. 服务端设计 (Python FastAPI)

### 2.1 API 路由

```
/api/auth/       — 登录验证、token 颁发
/api/users/      — 用户信息、水平等级、订阅状态
/api/songs/      — 歌曲列表、搜索、详情、下载
/api/progress/   — 学习进度同步（批量上行）
/api/community/  — 发布跟唱、浏览、点赞
/api/admin/      — 歌曲管理（CRUD、上架/下架）
/api/payments/   — App Store / Google Play 回调
```

### 2.2 数据库设计 (SQLite)

```sql
-- SQLite：UUID 存为 TEXT，时间戳存为 TEXT (ISO8601)，JSON 存为 TEXT

CREATE TABLE users (
    id            TEXT PRIMARY KEY,       -- UUID
    auth_provider TEXT,                   -- 'apple' | 'google'
    provider_id   TEXT,                   -- 平台返回的用户ID
    level_score   REAL DEFAULT 0,         -- 动态水平评分
    subscription  TEXT DEFAULT 'free',    -- 'free'|'monthly'|'yearly'
    created_at    TEXT DEFAULT (datetime('now'))
);

CREATE TABLE songs (
    id              TEXT PRIMARY KEY,      -- UUID
    title           TEXT,
    style           TEXT,                  -- 'pop'|'folk'|'gufeng'|'children'
    difficulty      REAL NOT NULL DEFAULT 5.0, -- 难度评分 1-10，创建时必填
    lyric_json      TEXT,                  -- 歌词 + 拼音 + 多语种翻译 (JSON string，见下方结构)
    lrc             TEXT,                  -- LRC 格式时间戳
    vocal_url_cn           TEXT,           -- 纯人声（七牛云/国内）
    vocal_url_global       TEXT,           -- 纯人声（Cloudflare R2/海外）
    accompaniment_url_cn   TEXT,           -- 纯伴奏（七牛云/国内）
    accompaniment_url_global TEXT,         -- 纯伴奏（Cloudflare R2/海外）
    full_song_url_cn       TEXT,           -- 完整混音（七牛云/国内）
    full_song_url_global   TEXT,           -- 完整混音（Cloudflare R2/海外）
    status          TEXT DEFAULT 'draft',  -- 'draft'|'published'|'archived'
    created_at      TEXT DEFAULT (datetime('now'))
);

CREATE TABLE progress (
    user_id         TEXT REFERENCES users(id),
    song_id         TEXT REFERENCES songs(id),
    sentence_scores TEXT,                  -- {"0": 85, "1": 72, ...} JSON string
    best_score      REAL,
    passed          INTEGER DEFAULT 0,     -- SQLite 无 BOOLEAN，0/1
    updated_at      TEXT DEFAULT (datetime('now')),
    PRIMARY KEY (user_id, song_id)
);

CREATE TABLE community_posts (
    id              TEXT PRIMARY KEY,      -- UUID
    user_id         TEXT REFERENCES users(id),
    song_id         TEXT REFERENCES songs(id),
    audio_url       TEXT,
    title           TEXT,
    likes           INTEGER DEFAULT 0,
    created_at      TEXT DEFAULT (datetime('now'))
);

-- 歌曲排行榜（跟唱得分）
CREATE TABLE song_leaderboard (
    user_id         TEXT REFERENCES users(id),
    song_id         TEXT REFERENCES songs(id),
    best_score      REAL,                  -- 该用户此歌最高分
    sentence_scores TEXT,                  -- 最佳一次的逐句得分 JSON
    attempts        INTEGER DEFAULT 1,     -- 累计唱了几次
    updated_at      TEXT DEFAULT (datetime('now')),
    PRIMARY KEY (user_id, song_id)
);

-- 每周比赛
CREATE TABLE contests (
    id              TEXT PRIMARY KEY,      -- UUID
    title           TEXT,                  -- 比赛名称，如 "第3周挑战赛"
    song_ids        TEXT,                  -- 参赛歌曲列表 JSON ["id1","id2"]
    start_date      TEXT,                  -- 开始日期 ISO8601
    end_date        TEXT,                  -- 结束日期 ISO8601
    status          TEXT DEFAULT 'upcoming', -- 'upcoming'|'active'|'ended'
    created_at      TEXT DEFAULT (datetime('now'))
);

-- 比赛参赛记录
CREATE TABLE contest_entries (
    contest_id      TEXT REFERENCES contests(id),
    user_id         TEXT REFERENCES users(id),
    song_id         TEXT REFERENCES songs(id),
    score           REAL,                  -- 本次提交得分
    sentence_scores TEXT,                  -- 逐句得分 JSON
    created_at      TEXT DEFAULT (datetime('now')),
    PRIMARY KEY (contest_id, user_id, song_id)
);
```

**SQLite 注意事项**：
- 服务端使用 `aiosqlite` + `sqlite-utils` 做异步访问
- JSON 字段存为 TEXT，Python 端 `json.dumps/loads` 序列化
- 并发写入用 WAL 模式 (`PRAGMA journal_mode=WAL`)
- 单文件部署，无需独立数据库进程，适合 MVP

**lyric_json 结构（多语种翻译）**：

```json
{
  "title": "朋友",
  "lines": [
    {
      "zh": "朋友一生一起走",
      "pinyin": "péng you yī shēng yī qǐ zǒu",
      "translations": {
        "en": "Friends walk together for a lifetime",
        "ja": "友よ一生一緒に歩もう",
        "ko": "친구여 평생 함께 가자"
      },
      "vocab": [
        { "word": "朋友", "pinyin": "péng you", "meaning": { "en": "friend", "ja": "友", "ko": "친구" } }
      ]
    }
  ]
}
```

- `translations` 的 key 为 ISO 639-1 语言代码
- 热门语种（en/ja/ko/fr/es/th）随歌曲生成时预填，冷门语种按需补
- 客户端请求歌曲时，只下发用户 App 语言对应的翻译（减少传输量）
- 词汇释义 `vocab[].meaning` 同理，按语种提供

**翻译缓存表（冷门语种按需生成后缓存）**：

```sql
CREATE TABLE song_translations (
    song_id   TEXT REFERENCES songs(id),
    lang      TEXT,                    -- ISO 639-1 语言代码
    content   TEXT,                    -- 该语种的翻译 JSON（结构与 lyric_json 中 translations 对应）
    created_at TEXT DEFAULT (datetime('now')),
    PRIMARY KEY (song_id, lang)
);
```

### 2.3 AI 流水线 Worker

```
输入：歌曲主题 + 风格 + 难度 + 参考音频(10s)
  │
  ├─ 1. 歌词生成 Worker
  │      LLM prompt（内置安全过滤规则）→ 结构化歌词 JSON（中文 + 拼音 + 热门语种翻译）
  │      → 直接入库，无需额外审核步骤
  │      热门语种：en / ja / ko / fr / es / th（随歌曲一起预生成）
  │      冷门语种：用户下载时按需生成，结果缓存供后续同语种用户复用
  │
  ├─ 2. 歌曲生成 Worker (SongBloom)
  │      输入：10s 参考音频 + 结构化歌词
  │      输出：完整歌曲 wav (48kHz, 最长 4min)
  │      内置音素对齐 → 可导出时间戳
  │
  ├─ 3. 人声分离 Worker (Demucs/UVR)
  │      从完整歌曲提取纯伴奏 wav + 纯人声 wav
  │      CPU 可跑，不占用 GPU
  │
  └─ 4. 后处理 Worker
         三轨分别 ffmpeg 压缩 → MP3/AAC (<10MB)
         导出 LRC（SongBloom 内置对齐）
         → 上传云存储 + 更新 songs.status = 'published'
```

**选型依据**：实际对比听感，SongBloom 中文歌声自然度优于 SongGeneration，更像真人演唱。

**GPU 需求**：RTX 4090 (24GB)，租用云端 GPU（AutoDL / 腾讯云 GPU）。

**云存储选型**：

国内+海外双区域存储，按用户地域分发：

| 区域 | 存储 | CDN | 说明 |
|------|------|-----|------|
| 国内 | 七牛云 Kodo | 七牛 CDN | 国内节点密集，速度快 |
| 海外 | Cloudflare R2 | Cloudflare CDN | 全球 300+ 城市节点，无出站流量费 |

- 歌曲文件生成后同时上传两套存储，双写保证一致
- 客户端请求下载时，服务端根据用户 IP 或区域返回对应存储的 CDN URL
- 服务器只存元数据（SQLite）和两套文件 URL
- 用户上传的社区录音同样按区域存对应存储
- 数据库 songs 表存储 URL 字段改为按区域存储（见下方 schema 变更）

**songs 表 URL 字段变更**：

```sql
-- 原设计：单一 URL
-- vocal_url, accompaniment_url, full_song_url

-- 新设计：按区域存 URL
vocal_url_cn           TEXT,    -- 七牛云 URL（国内）
vocal_url_global       TEXT,    -- Cloudflare R2 URL（海外）
accompaniment_url_cn   TEXT,
accompaniment_url_global TEXT,
full_song_url_cn       TEXT,
full_song_url_global   TEXT,
```

**下载路由逻辑**：

```
客户端 GET /api/songs/:id/download/:type
  → 服务端判断用户区域（IP 或客户端传 region 参数）
  → 国内 → 302 重定向到七牛 CDN URL
  → 海外 → 302 重定向到 Cloudflare CDN URL
```

### 2.4 音频格式与压缩

```
混音输出：
  - 默认：MP3 320kbps → 3-6 MB（3-5分钟歌曲）
  - 备选：AAC 256kbps → 比 MP3 同等码率体积更小、音质更好
  - 低端机/Opt：Opus 96kbps → <2 MB，省带宽

目标：
  - 完整歌曲 <10MB
  - 纯伴奏 <5MB
  - 支持 CDN 按客户端能力返回不同码率（HLS 自适应可选）

存储格式：
  - 母带保留 wav，客户端下发压缩版
```

### 2.5 LRC 时间戳对齐

```
自动生成：
  - AI 音频分析逐句对齐，生成 LRC 时间戳
  - MVP 允许误差 ±0.2 秒
  - 歌词高亮切换在此误差内用户基本无感知

后续优化：
  - 收集用户反馈标记偏差较大的句子
  - 用小模型或规则做二次校正
  - 对质量要求高的歌曲可人工微调

存储：
  - LRC 文本存入 songs.lrc 字段
  - 出错时客户端 lyric_widget 有容错：超出范围的行不崩溃
```

### 2.6 歌曲难易度

每首歌必须标注难易度，在歌曲列表和详情页醒目展示，让用户直观了解学习门槛。

**难易度设计：**

| 等级 | 分值范围 | 标签 | 说明 |
|------|---------|------|------|
| 入门 | 1.0-2.9 | 简单 | 词汇基础、语速慢、句子短，适合零基础 |
| 初级 | 3.0-4.9 | 较易 | 词汇日常、句式简单，适合初学者 |
| 中级 | 5.0-6.9 | 中等 | 词汇丰富、正常语速，适合有基础者 |
| 高级 | 7.0-8.9 | 较难 | 词汇进阶、句式复杂、语速较快 |
| 挑战 | 9.0-10.0 | 困难 | 词汇生僻、语速快、文化内涵深 |

**规则：**
- 创建歌曲时必须指定难度值，不可为空
- 难度值由运营人员在管理后台手动标注，或 AI 生成时预设
- 歌曲列表按难度升序排列（默认），用户可按难度筛选
- 详情页展示难度标签（如"中级 · 6.5"）

**数据库约束补充：**
- `songs.difficulty` 字段 NOT NULL，默认值 5.0（中级）
- 管理后台创建歌曲时必填难度

---

## 3. 客户端设计 (Flutter)

### 3.1 目录结构

```
lib/
├── main.dart
├── app.dart                    # App 入口 + 路由
├── features/
│   ├── player/                 # 歌曲播放 + 歌词同步
│   │   ├── player_screen.dart
│   │   ├── lyric_widget.dart
│   │   └── player_controller.dart
│   ├── singalong/              # 跟唱 + 本地评分
│   │   ├── singalong_screen.dart
│   │   ├── audio_recorder.dart
│   │   └── scoring_engine.dart
│   ├── songs/                  # 歌曲浏览/搜索/下载
│   ├── progress/               # 学习进度
│   ├── community/              # 社区（发跟唱 + 点赞）
│   ├── auth/                   # 登录
│   ├── settings/               # 设置
│   └── admin/                  # 管理后台（Web 端或内嵌）
├── services/
│   ├── api_service.dart        # HTTP 客户端
│   ├── auth_service.dart       # Apple/Google 登录
│   ├── audio_service.dart      # 播放控制
│   └── storage_service.dart    # SQLite 本地存储
└── models/                     # 数据模型
    ├── song.dart
    ├── user.dart
    ├── progress.dart
    └── lyric.dart
```

### 3.2 本地评分引擎设计（纯 Dart）

```dart
// scoring_engine.dart
//
// 流程：
// 1. 分帧读取 WAV → 逐帧送入处理管线（避免一次性加载整段音频）
// 2. 逐帧 FFT → 频谱
// 3. YIN 算法 → 基频(F0)曲线（逐帧累加）
// 4. 与参考音频基频曲线做 DTW 对齐
// 5. 计算相似度 → 0-100 分

class ScoringEngine {
  /// 计算一句歌词的得分
  ScoreResult scoreSentence({
    required Float64List userAudio,    // 用户录音 (16kHz mono)
    required Float64List referenceAudio, // 原唱同段 (16kHz mono)
    PrecisionMode mode = PrecisionMode.normal,
  });
}

enum PrecisionMode {
  normal,    // 16kHz + 标准 FFT 窗口
  low,       // 8kHz 降采样 + 更小 FFT 窗口，低端机可用
}

class ScoreResult {
  final int score;          // 0-100
  final double pitchAccuracy;
  final double rhythmMatch;
}
```

**性能兼容性**：
- 分帧处理：原始音频按 20-30ms 帧长切分，流水线式处理，避免一次性加载整段内存
- 低精度模式：降采样至 8kHz + 缩小 FFT 窗口，适配低端 Android 设备
- 用户可在设置中切换精度模式，首次启动根据设备型号自动推荐
- FFT / YIN / DTW 均纯 Dart 实现，无 native 依赖，零崩溃风险

### 3.3 本地缓存策略

```
优先级：
  1. 预置歌曲（随 App 安装）
  2. 用户手动下载的歌曲
  3. 最近播放的歌曲（自动缓存最近 N 首）

空间管理：
  - 缓存管理界面：显示每首歌占用空间、总缓存大小
  - 自动清理：存储空间不足时，优先清理最久未播放的非收藏歌曲
  - 用户可手动逐首删除缓存，或一键清空

下载：
  - 下载包 = 完整歌曲.mp3 + 伴奏.mp3 + lyric.json + lrc
  - 支持断点续传
  - 下载完成后更新本地缓存清单 → SQLite
```

### 3.3 离线策略

```
下载歌曲时获取：
- full_song.mp3      (完整歌曲)
- accompaniment.mp3  (纯伴奏)
- song.lyric.json    (歌词 + 拼音 + 用户语种翻译 + 词汇)
- song.lrc           (时间戳)

全部存入本地，离线时可：
✓ 播放完整歌曲 / 伴奏
✓ 歌词显示 + 拼音 + 高亮同步
✓ 跟唱录音 + 本地评分
✓ 学习进度记录 → SQLite

联网后：
→ 批量同步进度到服务端
```

### 3.4 生命周期处理

```
状态机：
PLAYING → (来电/切后台) → PAUSED
PAUSED → (用户点继续) → PLAYING（从断点续录）
PAUSED → (用户点退出) → DISCARD / SAVE

初始状态：
麦克风权限未授予 → 只能播放，跟唱入口置灰 + 权限引导
```

**Android 10+ 权限注意**：录音权限需动态申请（`RECORD_AUDIO`），需在 `AndroidManifest.xml` 声明，运行时通过 `permission_handler` 包请求。

### 3.5 用户激励体系

```
每日打卡（Streak）：
  - 每日完成一次跟唱即打卡
  - 连续打卡 N 天 → 展示连续天数徽章
  - 断签 → 提示，可选择通过观看广告或分享恢复（后期加）

成就系统：
  - 首次跟唱 / 首次满分 / 完成 5 首歌 / 连续打卡 7 天等
  - 本地存储成就列表，服务端同步
  - 轻量设计，不设复杂等级体系

分享练习成果：
  - 跟唱完成后 → "分享"按钮
  - 生成分享卡片图：歌曲封面 + 得分 + 一句歌词
  - 可附带简短录音片段（可选）
  - 调用系统分享菜单（图片/链接）
```

---

## 4. 接口设计（关键端点）

### 4.1 用户相关

```
POST /api/auth/login
  body: { provider: "apple"|"google", id_token: "..." }
  → { token, user }

GET /api/users/me
  → { id, level_score, subscription, ... }

POST /api/progress/sync
  body: { records: [{song_id, sentence_scores, best_score, passed}] }
  → { updated }
```

### 4.2 歌曲相关

```
GET /api/songs?style=&difficulty_min=&difficulty_max=&keyword=&page=
  → { songs: [...], total }

GET /api/songs/:id
  → { song detail + download_urls }

GET /api/songs/:id/download/:type   (type: full|accompaniment|lrc|lyric)
  → 302 → CDN
  lyric 类型：服务端根据请求头 Accept-Language 只返回用户语种的翻译
```

### 4.3 社区与排行榜

```
-- 歌曲排行榜
GET /api/leaderboard/songs/:song_id
  query: page=1&limit=50
  → { rankings: [{user_id, nickname, avatar, best_score, rank}], total }

-- 用户自己的排名
GET /api/leaderboard/songs/:song_id/me
  → { rank, best_score, total_players }

-- 每周赛况
GET /api/contests/current
  → { contest_id, song_ids, title, start_date, end_date, status }

GET /api/contests/:contest_id/leaderboard
  query: page=1&limit=50
  → { rankings: [{user_id, nickname, avatar, total_score, rank}], total }

-- 用户参赛（提交分数，跟唱完成后自动触发）
POST /api/contests/:contest_id/submit
  body: { song_id, score, sentence_scores }
  → { rank, updated }

-- 社区动态（保留）
POST /api/community/posts
  multipart: audio_file + title + song_id
  → { post }

GET /api/community/posts?song_id=&sort=hot|new&page=
  → { posts: [...], total }

POST /api/community/posts/:id/like
  → { likes }
```

### 4.4 管理后台

```
POST   /api/admin/songs          → 创建歌曲
PUT    /api/admin/songs/:id      → 更新歌曲信息
DELETE /api/admin/songs/:id      → 下架歌曲
POST   /api/admin/songs/generate → 触发 AI 生成流水线
GET    /api/admin/generate/:task_id/status → 查询生成进度
```

---

## 5. 关键决策记录

| 决策 | 选择 | 理由 |
|------|------|------|
| 服务端语言 | Python FastAPI | AI 工具链生态优势 |
| 客户端框架 | Flutter | 团队已有经验 + 跨平台 |
| 评分引擎 | 纯 Dart | 避免 native crash，逐句评分计算量 Dart 够用 |
| 歌曲生成 | SongBloom | 腾讯开源，实际听感最好，更像中文歌 |
| 登录 | Apple/Google 原生 | 免密，支付直接对接 IAP |
| 审核 | LLM prompt 内置过滤 | 生成时把控，正能量主题无需独立审核步骤 |
| 社区 | 排行榜 + 每周赛 + 点赞 | 同歌竞技排行驱动活跃，赛事制造周期性回流 |

---

## 6. MVP 范围与可行性评估

### Phase 0 — 技术验证 ✅ 可行
- 搭建 SongBloom 推理环境（RTX 4090 / 云端 GPU）
- LLM 生成 2-3 首正能量歌词 → SongBloom 生成完整歌曲 → Demucs 分离
- 验证：歌声自然度（实际听感）+ 伴奏分离质量
- 产出：歌曲 demo（完整版+伴奏版+人声版）+ 流水线脚本
- **不写 APP 代码**

### Phase 1 — MVP ✅ 可行
- 歌曲播放 + 歌词同步 + 拼音（Flutter + just_audio，离线可用）
- 本地逐句跟唱评分（纯 Dart FFT+YIN+DTW，无需服务端）
- Apple/Google 登录（原生 SDK，成熟稳定）
- 订阅支付 (IAP)
- 管理后台（FastAPI + 简单前端页面）
- 离线支持（预置歌曲 + 手动下载 + 缓存管理）
- 歌词高亮 + 拼音 + 翻译无需网络

### Phase 2 — 迭代 ⚠️ 需额外设计
- AI 生成歌曲量大后需后台异步队列（Celery/Redis）+ GPU 资源
- 听写练习 + 社区模块需更多服务端设计
- 用户自定义 AI 生成 = 完整生成流水线自动化

---

## 7. 风险与缓解

| 风险 | 严重程度 | 缓解措施 |
|------|---------|---------|
| SongBloom 歌声质量不达标 | 高 | Phase 0 实际试听验证，不可用则回退 SongGeneration |
| GPU 成本过高 | 中 | RTX 4090 云端按需租用，量大后再评估自建 |
| 本地评分准确度不足 | 中 | 逐句评分 + DTW 容忍偏差，上线后调参 |
| App Store 审核（UGC 风险） | 低 | 社区不做评论，内容 AI+人工可控 |
| 歌曲版权争议 | 低 | AI 生成为主，真实歌曲仅用无版权或已授权 |
