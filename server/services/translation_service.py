import json
from database import get_db

HOT_LANGUAGES = {"en", "ja", "ko", "fr", "es", "th"}


async def get_translation(song_id: str, lang: str) -> str | None:
    """Get translation for a specific language.

    For hot languages, they're already in lyric_json.
    For cold languages, check song_translations cache.
    """
    if lang in HOT_LANGUAGES:
        return None  # Already included in lyric_json

    db = await get_db()
    try:
        cursor = await db.execute(
            "SELECT content FROM song_translations WHERE song_id = ? AND lang = ?",
            (song_id, lang),
        )
        row = await cursor.fetchone()
        return dict(row)["content"] if row else None
    finally:
        await db.close()


async def cache_translation(song_id: str, lang: str, content: str):
    db = await get_db()
    try:
        await db.execute(
            """INSERT OR REPLACE INTO song_translations (song_id, lang, content, created_at)
               VALUES (?, ?, ?, datetime('now'))""",
            (song_id, lang, content),
        )
        await db.commit()
    finally:
        await db.close()


def filter_lyric_json_by_lang(lyric_json_str: str, lang: str) -> str:
    """Filter lyric_json to only include the requested language translation.

    For hot languages, keep the translation in the JSON.
    For other languages, strip translations to save bandwidth (cold lang fetched separately).
    """
    if not lyric_json_str:
        return lyric_json_str

    data = json.loads(lyric_json_str)
    for line in data.get("lines", []):
        translations = line.get("translations", {})
        if lang in translations:
            line["translations"] = {lang: translations[lang]}
        else:
            line["translations"] = {}

        for vocab in line.get("vocab", []):
            meanings = vocab.get("meaning", {})
            if lang in meanings:
                vocab["meaning"] = {lang: meanings[lang]}
            else:
                vocab["meaning"] = {}

    return json.dumps(data, ensure_ascii=False)
