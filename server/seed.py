"""Seed the database with demo songs for development."""

import asyncio
import json
from database import get_db, init_db

DEMO_SONGS = [
    {
        "id": "demo-001",
        "title": "朋友",
        "style": "pop",
        "difficulty": 3.5,
        "lyric_json": json.dumps({
            "title": "朋友",
            "lines": [
                {
                    "zh": "朋友一生一起走",
                    "pinyin": "péng you yī shēng yī qǐ zǒu",
                    "translations": {
                        "en": "Friends walk together for a lifetime",
                        "ja": "友よ一生一緒に歩もう",
                        "ko": "친구여 평생 함께 가자",
                        "fr": "Les amis marchent ensemble toute la vie",
                        "es": "Los amigos caminan juntos toda la vida",
                        "th": "เพื่อนเดินไปด้วยกันตลอดชีวิต"
                    },
                    "vocab": [
                        {"word": "朋友", "pinyin": "péng you", "meaning": {"en": "friend", "ja": "友", "ko": "친구"}},
                        {"word": "一起", "pinyin": "yī qǐ", "meaning": {"en": "together", "ja": "一緒に", "ko": "함께"}}
                    ]
                },
                {
                    "zh": "那些日子不再有",
                    "pinyin": "nà xiē rì zi bù zài yǒu",
                    "translations": {
                        "en": "Those days will never return",
                        "ja": "あの日々はもう戻らない",
                        "ko": "그런 날들은 다시 없다",
                        "fr": "Ces jours ne reviendront plus",
                        "es": "Esos días no volverán",
                        "th": "วันเหล่านั้นจะไม่กลับมาอีก"
                    },
                    "vocab": [
                        {"word": "日子", "pinyin": "rì zi", "meaning": {"en": "days", "ja": "日々", "ko": "날들"}}
                    ]
                },
                {
                    "zh": "一句话一辈子",
                    "pinyin": "yī jù huà yī bèi zi",
                    "translations": {
                        "en": "One word, a whole lifetime",
                        "ja": "一言で一生",
                        "ko": "한마디 평생",
                        "fr": "Un mot pour toute une vie",
                        "es": "Una palabra, toda una vida",
                        "th": "หนึ่งคำตลอดชีวิต"
                    },
                    "vocab": [
                        {"word": "一辈子", "pinyin": "yī bèi zi", "meaning": {"en": "a lifetime", "ja": "一生", "ko": "평생"}}
                    ]
                },
                {
                    "zh": "一生情一杯酒",
                    "pinyin": "yī shēng qíng yī bēi jiǔ",
                    "translations": {
                        "en": "A lifetime of friendship, a cup of wine",
                        "ja": "一生の友情、一杯の酒",
                        "ko": "평생의 정 한 잔의 술",
                        "fr": "Une vie d'amitié, un verre de vin",
                        "es": "Una vida de amistad, una copa de vino",
                        "th": "มิตรภาตลอดชีวิต หนึ่งแก้วเหล้า"
                    },
                    "vocab": [
                        {"word": "情", "pinyin": "qíng", "meaning": {"en": "friendship/feeling", "ja": "情", "ko": "정"}}
                    ]
                }
            ]
        }, ensure_ascii=False),
        "lrc": "[00:00.00]朋友一生一起走\n[00:05.50]那些日子不再有\n[00:11.00]一句话一辈子\n[00:16.50]一生情一杯酒\n",
        "vocal_url_cn": "",
        "vocal_url_global": "",
        "accompaniment_url_cn": "",
        "accompaniment_url_global": "",
        "full_song_url_cn": "",
        "full_song_url_global": "",
        "status": "published",
    },
    {
        "id": "demo-002",
        "title": "小星星",
        "style": "children",
        "difficulty": 1.0,
        "lyric_json": json.dumps({
            "title": "小星星",
            "lines": [
                {
                    "zh": "一闪一闪亮晶晶",
                    "pinyin": "yī shǎn yī shǎn liàng jīng jīng",
                    "translations": {
                        "en": "Twinkle twinkle little star",
                        "ja": "きらきらひかる",
                        "ko": "반짝반짝 작은 별",
                        "fr": "Brille brille petite étoile",
                        "es": "Brilla brilla pequeña estrella",
                        "th": "ระยิบระยิบดาวเล็ก"
                    },
                    "vocab": [
                        {"word": "闪", "pinyin": "shǎn", "meaning": {"en": "twinkle", "ja": "きらきら", "ko": "반짝"}},
                        {"word": "星星", "pinyin": "xīng xīng", "meaning": {"en": "star", "ja": "星", "ko": "별"}}
                    ]
                },
                {
                    "zh": "满天都是小星星",
                    "pinyin": "mǎn tiān dōu shì xiǎo xīng xīng",
                    "translations": {
                        "en": "How I wonder what you are",
                        "ja": "おそらのまちがはかせ",
                        "ko": "하늘에는 작은 별",
                        "fr": "Comment je me demande ce que tu es",
                        "es": "Cómo me pregunto qué serás",
                        "th": "นึกสงสัยว่าเธอนั้นคืออะไร"
                    },
                    "vocab": [
                        {"word": "满天", "pinyin": "mǎn tiān", "meaning": {"en": "all over the sky", "ja": "空いっぱい", "ko": "하늘 가득"}}
                    ]
                },
                {
                    "zh": "挂在天空放光明",
                    "pinyin": "guà zài tiān kōng fàng guāng míng",
                    "translations": {
                        "en": "Up above the world so high",
                        "ja": "せかいのうえにたかく",
                        "ko": "세상 위 높이 떠서",
                        "fr": "Là-haut dans le ciel",
                        "es": "Allá en lo alto del cielo",
                        "th": "สูงเด่นอยู่เหนือโลก"
                    },
                    "vocab": [
                        {"word": "天空", "pinyin": "tiān kōng", "meaning": {"en": "sky", "ja": "空", "ko": "하늘"}}
                    ]
                },
                {
                    "zh": "好像许多小眼睛",
                    "pinyin": "hǎo xiàng xǔ duō xiǎo yǎn jīng",
                    "translations": {
                        "en": "Like a diamond in the sky",
                        "ja": "そらのダイヤモンドみたい",
                        "ko": "하늘의 다이아몬드 같이",
                        "fr": "Comme un diamant dans le ciel",
                        "es": "Como un diamante en el cielo",
                        "th": "ดุจเพชรในท้องฟ้า"
                    },
                    "vocab": [
                        {"word": "眼睛", "pinyin": "yǎn jīng", "meaning": {"en": "eyes", "ja": "目", "ko": "눈"}}
                    ]
                }
            ]
        }, ensure_ascii=False),
        "lrc": "[00:00.00]一闪一闪亮晶晶\n[00:04.00]满天都是小星星\n[00:08.00]挂在天空放光明\n[00:12.00]好像许多小眼睛\n",
        "vocal_url_cn": "",
        "vocal_url_global": "",
        "accompaniment_url_cn": "",
        "accompaniment_url_global": "",
        "full_song_url_cn": "",
        "full_song_url_global": "",
        "status": "published",
    },
    {
        "id": "demo-003",
        "title": "追梦人",
        "style": "pop",
        "difficulty": 6.5,
        "lyric_json": json.dumps({
            "title": "追梦人",
            "lines": [
                {
                    "zh": "让青春吹动了你的长发",
                    "pinyin": "ràng qīng chūn chuī dòng le nǐ de cháng fà",
                    "translations": {
                        "en": "Let youth blow your long hair",
                        "ja": "青春があなたの長い髪を揺らす",
                        "ko": "청춘이 당신의 긴 머리카락을 흔들게",
                        "fr": "Que la jeunesse ébouriffe tes longs cheveux",
                        "es": "Que la juventud mueva tu cabello largo",
                        "th": "ให้วัยรุ่นพัดผมยาวของคุณ"
                    },
                    "vocab": [
                        {"word": "青春", "pinyin": "qīng chūn", "meaning": {"en": "youth", "ja": "青春", "ko": "청춘"}},
                        {"word": "追梦", "pinyin": "zhuī mèng", "meaning": {"en": "chasing dreams", "ja": "夢を追う", "ko": "꿈을 좇다"}}
                    ]
                },
                {
                    "zh": "让它牵引你的梦",
                    "pinyin": "ràng tā qiān yǐn nǐ de mèng",
                    "translations": {
                        "en": "Let it guide your dreams",
                        "ja": "それがあなたの夢を導く",
                        "ko": "그것이 당신의 꿈을 이끌게",
                        "fr": "Qu'il guide tes rêves",
                        "es": "Que guíe tus sueños",
                        "th": "ให้มันนำทางความฝันของคุณ"
                    },
                    "vocab": [
                        {"word": "牵引", "pinyin": "qiān yǐn", "meaning": {"en": "guide/lead", "ja": "導く", "ko": "이끌다"}}
                    ]
                },
                {
                    "zh": "不知不觉这城市的历史",
                    "pinyin": "bù zhī bù jué zhè chéng shì de lì shǐ",
                    "translations": {
                        "en": "Unknowingly the history of this city",
                        "ja": "知らず知らずのうちにこの街の歴史",
                        "ko": "모르는 사이 이 도시의 역사가",
                        "fr": "Sans s'en rendre compte l'histoire de cette ville",
                        "es": "Sin darse cuenta la historia de esta ciudad",
                        "th": "โดยไม่รู้ตัวประวัติของเมืองนี้"
                    },
                    "vocab": [
                        {"word": "不知不觉", "pinyin": "bù zhī bù jué", "meaning": {"en": "unknowingly", "ja": "知らず知らず", "ko": "모르는 사이"}},
                        {"word": "历史", "pinyin": "lì shǐ", "meaning": {"en": "history", "ja": "歴史", "ko": "역사"}}
                    ]
                },
                {
                    "zh": "已记取了你的笑容",
                    "pinyin": "yǐ jì qǔ le nǐ de xiào róng",
                    "translations": {
                        "en": "Has recorded your smile",
                        "ja": "あなたの笑顔を記録した",
                        "ko": "당신의 미소를 기록했다",
                        "fr": "A enregistré ton sourire",
                        "es": "Ha grabado tu sonrisa",
                        "th": "ได้บันทึกรอยยิ้มของคุณ"
                    },
                    "vocab": [
                        {"word": "笑容", "pinyin": "xiào róng", "meaning": {"en": "smile", "ja": "笑顔", "ko": "미소"}}
                    ]
                }
            ]
        }, ensure_ascii=False),
        "lrc": "[00:00.00]让青春吹动了你的长发\n[00:06.00]让它牵引你的梦\n[00:12.00]不知不觉这城市的历史\n[00:18.00]已记取了你的笑容\n",
        "vocal_url_cn": "",
        "vocal_url_global": "",
        "accompaniment_url_cn": "",
        "accompaniment_url_global": "",
        "full_song_url_cn": "",
        "full_song_url_global": "",
        "status": "published",
    },
]


async def seed():
    await init_db()
    db = await get_db()
    try:
        for song in DEMO_SONGS:
            await db.execute(
                """INSERT OR IGNORE INTO songs
                   (id, title, style, difficulty, lyric_json, lrc,
                    vocal_url_cn, vocal_url_global, accompaniment_url_cn, accompaniment_url_global,
                    full_song_url_cn, full_song_url_global, status)
                   VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
                (
                    song["id"], song["title"], song["style"], song["difficulty"],
                    song["lyric_json"], song["lrc"],
                    song["vocal_url_cn"], song["vocal_url_global"],
                    song["accompaniment_url_cn"], song["accompaniment_url_global"],
                    song["full_song_url_cn"], song["full_song_url_global"],
                    song["status"],
                ),
            )
        await db.commit()
        print(f"Seeded {len(DEMO_SONGS)} demo songs.")
    finally:
        await db.close()


if __name__ == "__main__":
    asyncio.run(seed())
