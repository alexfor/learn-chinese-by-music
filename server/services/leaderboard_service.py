import json

from database import get_db


def _scores_to_json(scores: list[float]) -> str:
    return json.dumps(scores, ensure_ascii=False)


async def update_leaderboard(user_id: str, song_id: str,
                             best_score: float, sentence_scores: list[float]) -> None:
    db = await get_db()
    try:
        scores_json = _scores_to_json(sentence_scores)
        await db.execute(
            """INSERT INTO song_leaderboard (user_id, song_id, best_score, sentence_scores, attempts, updated_at)
               VALUES (?, ?, ?, ?, 1, datetime('now'))
               ON CONFLICT(user_id, song_id) DO UPDATE SET
                   best_score = CASE WHEN excluded.best_score > best_score
                                     THEN excluded.best_score ELSE best_score END,
                   sentence_scores = excluded.sentence_scores,
                   attempts = attempts + 1,
                   updated_at = datetime('now')""",
            (user_id, song_id, best_score, scores_json),
        )
        await db.commit()
    finally:
        await db.close()


async def get_song_leaderboard(song_id: str) -> list[dict]:
    db = await get_db()
    try:
        cursor = await db.execute(
            """SELECT sl.user_id, sl.best_score, sl.attempts, u.nickname
               FROM song_leaderboard sl
               JOIN users u ON u.id = sl.user_id
               WHERE sl.song_id = ?
               ORDER BY sl.best_score DESC""",
            (song_id,),
        )
        rows = await cursor.fetchall()
        return [
            {
                "user_id": row["user_id"],
                "score": row["best_score"],
                "attempts": row["attempts"],
                "nickname": row["nickname"],
            }
            for row in rows
        ]
    finally:
        await db.close()


async def get_user_rank(user_id: str, song_id: str) -> dict | None:
    db = await get_db()
    try:
        cursor = await db.execute(
            "SELECT best_score, attempts FROM song_leaderboard WHERE user_id = ? AND song_id = ?",
            (user_id, song_id),
        )
        row = await cursor.fetchone()
        if row is None:
            return None

        best_score = row["best_score"]
        cursor2 = await db.execute(
            "SELECT COUNT(*) + 1 AS rank FROM song_leaderboard WHERE song_id = ? AND best_score > ?",
            (song_id, best_score),
        )
        rank_row = await cursor2.fetchone()
        return {
            "rank": rank_row["rank"],
            "score": best_score,
            "attempts": row["attempts"],
        }
    finally:
        await db.close()
