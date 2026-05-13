import uuid

from database import get_db


async def create_post(user_id: str, song_id: str, title: str,
                      audio_url: str | None = None) -> dict:
    db = await get_db()
    try:
        post_id = str(uuid.uuid4())
        await db.execute(
            """INSERT INTO community_posts (id, user_id, song_id, title, audio_url, likes, created_at)
               VALUES (?, ?, ?, ?, ?, 0, datetime('now'))""",
            (post_id, user_id, song_id, title, audio_url),
        )
        await db.commit()

        cursor = await db.execute(
            """SELECT cp.*, u.nickname
               FROM community_posts cp
               JOIN users u ON u.id = cp.user_id
               WHERE cp.id = ?""",
            (post_id,),
        )
        row = await cursor.fetchone()
        return dict(row)
    finally:
        await db.close()


async def list_posts(song_id: str | None = None,
                     sort: str = "latest",
                     page: int = 1,
                     page_size: int = 20,
                     current_user_id: str | None = None) -> list[dict]:
    db = await get_db()
    try:
        conditions: list[str] = []
        params: list[str | int] = []

        if song_id:
            conditions.append("cp.song_id = ?")
            params.append(song_id)

        where_clause = " AND ".join(conditions) if conditions else "1=1"

        order_clause = ("cp.created_at DESC" if sort == "latest"
                        else "cp.likes DESC, cp.created_at DESC")

        offset = (page - 1) * page_size
        cursor = await db.execute(
            f"""SELECT cp.*, u.nickname
                FROM community_posts cp
                JOIN users u ON u.id = cp.user_id
                WHERE {where_clause}
                ORDER BY {order_clause}
                LIMIT ? OFFSET ?""",
            params + [page_size, offset],
        )
        rows = await cursor.fetchall()

        posts = []
        for row in rows:
            post = dict(row)
            if current_user_id:
                cursor2 = await db.execute(
                    "SELECT 1 FROM community_likes WHERE post_id = ? AND user_id = ?",
                    (post["id"], current_user_id),
                )
                post["liked_by_me"] = await cursor2.fetchone() is not None
            else:
                post["liked_by_me"] = False
            posts.append(post)

        return posts
    finally:
        await db.close()


async def get_post(post_id: str, current_user_id: str | None = None) -> dict | None:
    db = await get_db()
    try:
        cursor = await db.execute(
            """SELECT cp.*, u.nickname
               FROM community_posts cp
               JOIN users u ON u.id = cp.user_id
               WHERE cp.id = ?""",
            (post_id,),
        )
        row = await cursor.fetchone()
        if row is None:
            return None

        post = dict(row)
        if current_user_id:
            cursor2 = await db.execute(
                "SELECT 1 FROM community_likes WHERE post_id = ? AND user_id = ?",
                (post_id, current_user_id),
            )
            post["liked_by_me"] = await cursor2.fetchone() is not None
        else:
            post["liked_by_me"] = False
        return post
    finally:
        await db.close()


async def like_post(post_id: str, user_id: str) -> bool:
    """Returns True if a new like was added, False if already liked."""
    db = await get_db()
    try:
        cursor = await db.execute(
            "SELECT 1 FROM community_likes WHERE post_id = ? AND user_id = ?",
            (post_id, user_id),
        )
        if await cursor.fetchone() is not None:
            return False

        await db.execute(
            "INSERT INTO community_likes (post_id, user_id) VALUES (?, ?)",
            (post_id, user_id),
        )
        await db.execute(
            "UPDATE community_posts SET likes = likes + 1 WHERE id = ?",
            (post_id,),
        )
        await db.commit()
        return True
    finally:
        await db.close()


async def unlike_post(post_id: str, user_id: str) -> bool:
    """Returns True if a like was removed, False if not liked."""
    db = await get_db()
    try:
        cursor = await db.execute(
            "SELECT 1 FROM community_likes WHERE post_id = ? AND user_id = ?",
            (post_id, user_id),
        )
        if await cursor.fetchone() is None:
            return False

        await db.execute(
            "DELETE FROM community_likes WHERE post_id = ? AND user_id = ?",
            (post_id, user_id),
        )
        await db.execute(
            "UPDATE community_posts SET likes = MAX(0, likes - 1) WHERE id = ?",
            (post_id,),
        )
        await db.commit()
        return True
    finally:
        await db.close()
