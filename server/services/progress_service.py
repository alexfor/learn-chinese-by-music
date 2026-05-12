import json

from database import get_db


def _scores_to_json(scores: list[float]) -> str:
    return json.dumps(scores, ensure_ascii=False)


def _scores_from_json(raw: str) -> list[float]:
    return json.loads(raw)


async def sync_progress(user_id: str, song_id: str, sentence_scores: list[float],
                        best_score: float, passed: bool) -> dict:
    db = await get_db()
    try:
        scores_json = _scores_to_json(sentence_scores)

        await db.execute(
            """INSERT INTO progress (user_id, song_id, sentence_scores, best_score, passed, updated_at)
               VALUES (?, ?, ?, ?, ?, datetime('now'))
               ON CONFLICT(user_id, song_id) DO UPDATE SET
                   sentence_scores = excluded.sentence_scores,
                   best_score = excluded.best_score,
                   passed = excluded.passed,
                   updated_at = datetime('now')""",
            (user_id, song_id, scores_json, best_score, 1 if passed else 0),
        )
        await db.commit()

        # Read back the updated_at value
        cursor = await db.execute(
            "SELECT updated_at FROM progress WHERE user_id = ? AND song_id = ?",
            (user_id, song_id),
        )
        row = await cursor.fetchone()
        updated_at = row["updated_at"] if row else ""

        return {
            "song_id": song_id,
            "sentence_scores": sentence_scores,
            "best_score": best_score,
            "passed": passed,
            "updated_at": updated_at,
        }
    finally:
        await db.close()


async def get_progress(user_id: str, song_id: str) -> dict | None:
    db = await get_db()
    try:
        cursor = await db.execute(
            "SELECT * FROM progress WHERE user_id = ? AND song_id = ?",
            (user_id, song_id),
        )
        row = await cursor.fetchone()
        if row is None:
            return None

        row_dict = dict(row)
        return {
            "song_id": row_dict["song_id"],
            "sentence_scores": _scores_from_json(row_dict["sentence_scores"]),
            "best_score": row_dict["best_score"],
            "passed": bool(row_dict["passed"]),
            "updated_at": row_dict["updated_at"],
        }
    finally:
        await db.close()
