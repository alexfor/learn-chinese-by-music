from database import get_db


async def list_songs(
    style: str | None = None,
    difficulty_min: float | None = None,
    difficulty_max: float | None = None,
    keyword: str | None = None,
    status: str = "published",
    page: int = 1,
    page_size: int = 20,
) -> tuple[list[dict], int]:
    db = await get_db()
    try:
        conditions = ["status = ?"]
        params: list = [status]

        if style:
            conditions.append("style = ?")
            params.append(style)
        if difficulty_min is not None:
            conditions.append("difficulty >= ?")
            params.append(difficulty_min)
        if difficulty_max is not None:
            conditions.append("difficulty <= ?")
            params.append(difficulty_max)
        if keyword:
            conditions.append("title LIKE ?")
            params.append(f"%{keyword}%")

        where = " AND ".join(conditions)

        count_row = await db.execute(f"SELECT COUNT(*) FROM songs WHERE {where}", params)
        total = (await count_row.fetchone())[0]

        offset = (page - 1) * page_size
        params.extend([page_size, offset])
        cursor = await db.execute(
            f"SELECT id, title, style, difficulty, status FROM songs WHERE {where} ORDER BY difficulty ASC, created_at DESC LIMIT ? OFFSET ?",
            params,
        )
        rows = await cursor.fetchall()
        songs = [dict(row) for row in rows]
        return songs, total
    finally:
        await db.close()


async def get_song(song_id: str) -> dict | None:
    db = await get_db()
    try:
        cursor = await db.execute("SELECT * FROM songs WHERE id = ?", (song_id,))
        row = await cursor.fetchone()
        return dict(row) if row else None
    finally:
        await db.close()


async def create_song(data: dict) -> str:
    db = await get_db()
    try:
        await db.execute(
            """INSERT INTO songs (id, title, style, difficulty, lyric_json, lrc,
               vocal_url_cn, vocal_url_global, accompaniment_url_cn, accompaniment_url_global,
               full_song_url_cn, full_song_url_global, status)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (
                data["id"], data["title"], data["style"], data["difficulty"],
                data.get("lyric_json"), data.get("lrc"),
                data.get("vocal_url_cn"), data.get("vocal_url_global"),
                data.get("accompaniment_url_cn"), data.get("accompaniment_url_global"),
                data.get("full_song_url_cn"), data.get("full_song_url_global"),
                data.get("status", "draft"),
            ),
        )
        await db.commit()
        return data["id"]
    finally:
        await db.close()


async def update_song(song_id: str, data: dict) -> bool:
    db = await get_db()
    try:
        sets = []
        params = []
        for key in (
            "title", "style", "difficulty", "lyric_json", "lrc", "status",
            "vocal_url_cn", "vocal_url_global", "accompaniment_url_cn", "accompaniment_url_global",
            "full_song_url_cn", "full_song_url_global",
        ):
            if key in data and data[key] is not None:
                sets.append(f"{key} = ?")
                params.append(data[key])
        if not sets:
            return False
        params.append(song_id)
        await db.execute(f"UPDATE songs SET {', '.join(sets)} WHERE id = ?", params)
        await db.commit()
        return True
    finally:
        await db.close()


async def delete_song(song_id: str) -> bool:
    db = await get_db()
    try:
        cursor = await db.execute("UPDATE songs SET status = 'archived' WHERE id = ?", (song_id,))
        await db.commit()
        return cursor.rowcount > 0
    finally:
        await db.close()
