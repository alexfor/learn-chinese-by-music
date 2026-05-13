-- Learn Chinese by Music — Database Schema

CREATE TABLE IF NOT EXISTS users (
    id                TEXT PRIMARY KEY,
    auth_provider     TEXT,
    provider_id       TEXT,
    nickname          TEXT,
    avatar_url        TEXT,
    level_score       REAL DEFAULT 0,
    role              TEXT DEFAULT 'user',
    subscription      TEXT DEFAULT 'free',
    subscription_expires_at TEXT,
    purchased_songs   TEXT DEFAULT '[]',
    created_at        TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS songs (
    id                    TEXT PRIMARY KEY,
    title                 TEXT,
    style                 TEXT,
    difficulty            REAL NOT NULL DEFAULT 5.0,
    access_level          TEXT DEFAULT 'free',
    lyric_json            TEXT,
    lrc                   TEXT,
    vocal_url_cn          TEXT,
    vocal_url_global      TEXT,
    accompaniment_url_cn  TEXT,
    accompaniment_url_global TEXT,
    full_song_url_cn      TEXT,
    full_song_url_global  TEXT,
    status                TEXT DEFAULT 'draft',
    created_at            TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS progress (
    user_id         TEXT REFERENCES users(id),
    song_id         TEXT REFERENCES songs(id),
    sentence_scores TEXT,
    best_score      REAL,
    passed          INTEGER DEFAULT 0,
    updated_at      TEXT DEFAULT (datetime('now')),
    PRIMARY KEY (user_id, song_id)
);

CREATE TABLE IF NOT EXISTS community_posts (
    id              TEXT PRIMARY KEY,
    user_id         TEXT REFERENCES users(id),
    song_id         TEXT REFERENCES songs(id),
    audio_url       TEXT,
    title           TEXT,
    likes           INTEGER DEFAULT 0,
    created_at      TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS song_leaderboard (
    user_id         TEXT REFERENCES users(id),
    song_id         TEXT REFERENCES songs(id),
    best_score      REAL,
    sentence_scores TEXT,
    attempts        INTEGER DEFAULT 1,
    updated_at      TEXT DEFAULT (datetime('now')),
    PRIMARY KEY (user_id, song_id)
);

CREATE TABLE IF NOT EXISTS contests (
    id              TEXT PRIMARY KEY,
    title           TEXT,
    song_ids        TEXT,
    start_date      TEXT,
    end_date        TEXT,
    status          TEXT DEFAULT 'upcoming',
    created_at      TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS contest_entries (
    contest_id      TEXT REFERENCES contests(id),
    user_id         TEXT REFERENCES users(id),
    song_id         TEXT REFERENCES songs(id),
    score           REAL,
    sentence_scores TEXT,
    created_at      TEXT DEFAULT (datetime('now')),
    PRIMARY KEY (contest_id, user_id, song_id)
);

CREATE TABLE IF NOT EXISTS community_likes (
    post_id TEXT REFERENCES community_posts(id),
    user_id TEXT REFERENCES users(id),
    created_at TEXT DEFAULT (datetime('now')),
    PRIMARY KEY (post_id, user_id)
);

CREATE TABLE IF NOT EXISTS song_translations (
    song_id         TEXT REFERENCES songs(id),
    lang            TEXT,
    content         TEXT,
    created_at      TEXT DEFAULT (datetime('now')),
    PRIMARY KEY (song_id, lang)
);

CREATE TABLE IF NOT EXISTS purchase_history (
    id              TEXT PRIMARY KEY,
    user_id         TEXT REFERENCES users(id),
    product_id      TEXT,
    platform        TEXT,
    receipt         TEXT,
    created_at      TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS streaks (
    user_id         TEXT PRIMARY KEY REFERENCES users(id),
    current_streak  INTEGER DEFAULT 0,
    longest_streak  INTEGER DEFAULT 0,
    last_checkin    TEXT,
    updated_at      TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS achievements (
    id              TEXT PRIMARY KEY,
    user_id         TEXT REFERENCES users(id),
    achievement_key TEXT,
    unlocked_at     TEXT DEFAULT (datetime('now')),
    UNIQUE(user_id, achievement_key)
);

CREATE TABLE IF NOT EXISTS user_purchased_songs (
    user_id         TEXT REFERENCES users(id),
    song_id         TEXT,
    purchased_at    TEXT DEFAULT (datetime('now')),
    PRIMARY KEY (user_id, song_id)
);
