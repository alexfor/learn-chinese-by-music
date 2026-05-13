import json

from database import get_db


def _scores_to_json(scores: list[float]) -> str:
    return json.dumps(scores, ensure_ascii=False)


async def list_contests() -> list[dict]:
    db = await get_db()
    try:
        cursor = await db.execute(
            "SELECT * FROM contests ORDER BY created_at DESC",
        )
        rows = await cursor.fetchall()
        return [dict(row) for row in rows]
    finally:
        await db.close()


async def get_contest(contest_id: str) -> dict | None:
    db = await get_db()
    try:
        cursor = await db.execute(
            "SELECT * FROM contests WHERE id = ?",
            (contest_id,),
        )
        row = await cursor.fetchone()
        if row is None:
            return None

        contest = dict(row)

        cursor2 = await db.execute(
            """SELECT ce.user_id, ce.song_id, ce.score, u.nickname
               FROM contest_entries ce
               JOIN users u ON u.id = ce.user_id
               WHERE ce.contest_id = ?
               ORDER BY ce.score DESC""",
            (contest_id,),
        )
        entries_rows = await cursor2.fetchall()
        entries = [
            {"user_id": r["user_id"], "nickname": r["nickname"],
             "song_id": r["song_id"], "score": r["score"]}
            for r in entries_rows
        ]

        return {"contest": contest, "entries": entries}
    finally:
        await db.close()


async def submit_entry(contest_id: str, user_id: str, song_id: str,
                       score: float, sentence_scores: list[float]) -> None:
    db = await get_db()
    try:
        scores_json = _scores_to_json(sentence_scores)
        await db.execute(
            """INSERT INTO contest_entries (contest_id, user_id, song_id, score, sentence_scores, created_at)
               VALUES (?, ?, ?, ?, ?, datetime('now'))
               ON CONFLICT(contest_id, user_id, song_id) DO UPDATE SET
                   score = excluded.score,
                   sentence_scores = excluded.sentence_scores,
                   created_at = datetime('now')""",
            (contest_id, user_id, song_id, score, scores_json),
        )
        await db.commit()
    finally:
        await db.close()
