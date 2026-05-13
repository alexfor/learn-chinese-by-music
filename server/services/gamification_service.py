from datetime import datetime, date, timezone

from database import get_db


ACHIEVEMENT_DEFINITIONS = [
    {"key": "first_singalong", "title": "First Singalong",
     "description": "Complete your first singalong session",
     "icon": "mic"},
    {"key": "perfect_score", "title": "Perfect Score",
     "description": "Get a score of 100 on any song",
     "icon": "emoji_events"},
    {"key": "five_songs_completed", "title": "Song Explorer",
     "description": "Complete 5 different songs",
     "icon": "library_music"},
    {"key": "seven_day_streak", "title": "Dedicated Learner",
     "description": "Maintain a 7-day practice streak",
     "icon": "whatshot"},
    {"key": "first_share", "title": "Sharing is Caring",
     "description": "Share your singing result",
     "icon": "share"},
]


async def checkin_streak(user_id: str) -> dict:
    """Record a daily check-in and calculate the current streak."""
    db = await get_db()
    try:
        today = date.today()
        today_iso = today.isoformat()

        row = await db.execute_fetchall(
            "SELECT current_streak, longest_streak, last_checkin FROM streaks WHERE user_id = ?",
            (user_id,),
        )

        current_streak = 0
        longest_streak = 0
        last_checkin = None

        if row:
            current_streak = row[0]["current_streak"] or 0
            longest_streak = row[0]["longest_streak"] or 0
            last_checkin = row[0]["last_checkin"]

            # Already checked in today
            if last_checkin and last_checkin.startswith(today_iso):
                return {
                    "current_streak": current_streak,
                    "longest_streak": longest_streak,
                    "last_checkin": last_checkin,
                    "checked_in_today": True,
                }

            # Consecutive day = increment, otherwise reset to 1
            if last_checkin:
                last_date_str = last_checkin[:10]
                try:
                    last_date = date.fromisoformat(last_date_str)
                    diff = (today - last_date).days
                    if diff == 1:
                        current_streak += 1
                    elif diff > 1:
                        current_streak = 1
                except ValueError:
                    current_streak = 1
            else:
                current_streak = 1
        else:
            current_streak = 1

        longest_streak = max(longest_streak, current_streak)
        now_iso = datetime.now(timezone.utc).isoformat()

        await db.execute(
            """INSERT INTO streaks (user_id, current_streak, longest_streak, last_checkin, updated_at)
               VALUES (?, ?, ?, ?, ?)
               ON CONFLICT(user_id) DO UPDATE SET
                   current_streak = excluded.current_streak,
                   longest_streak = excluded.longest_streak,
                   last_checkin = excluded.last_checkin,
                   updated_at = excluded.updated_at""",
            (user_id, current_streak, longest_streak, now_iso, now_iso),
        )
        await db.commit()

        return {
            "current_streak": current_streak,
            "longest_streak": longest_streak,
            "last_checkin": now_iso,
            "checked_in_today": True,
        }
    finally:
        await db.close()


async def get_streak(user_id: str) -> dict:
    """Get the current streak for a user."""
    db = await get_db()
    try:
        today = date.today()
        today_iso = today.isoformat()

        row = await db.execute_fetchall(
            "SELECT current_streak, longest_streak, last_checkin FROM streaks WHERE user_id = ?",
            (user_id,),
        )

        if not row:
            return {
                "current_streak": 0,
                "longest_streak": 0,
                "last_checkin": None,
                "checked_in_today": False,
            }

        last_checkin = row[0]["last_checkin"]
        checked_in_today = last_checkin is not None and last_checkin.startswith(today_iso)

        return {
            "current_streak": row[0]["current_streak"] or 0,
            "longest_streak": row[0]["longest_streak"] or 0,
            "last_checkin": last_checkin,
            "checked_in_today": checked_in_today,
        }
    finally:
        await db.close()


async def unlock_achievement(user_id: str, achievement_key: str) -> dict:
    """Unlock an achievement for a user. Idempotent."""
    definition = None
    for d in ACHIEVEMENT_DEFINITIONS:
        if d["key"] == achievement_key:
            definition = d
            break

    if not definition:
        raise ValueError(f"Unknown achievement_key: {achievement_key}")

    db = await get_db()
    try:
        existing = await db.execute_fetchall(
            "SELECT id FROM achievements WHERE user_id = ? AND achievement_key = ?",
            (user_id, achievement_key),
        )

        if existing:
            row = await db.execute_fetchall(
                "SELECT id, achievement_key, unlocked_at FROM achievements WHERE id = ?",
                (existing[0]["id"],),
            )
            return {
                "achievement_key": achievement_key,
                "newly_unlocked": False,
                "title": definition["title"],
                "description": definition["description"],
            }

        import uuid
        achievement_id = str(uuid.uuid4())
        now_iso = datetime.now(timezone.utc).isoformat()
        await db.execute(
            "INSERT INTO achievements (id, user_id, achievement_key, unlocked_at) VALUES (?, ?, ?, ?)",
            (achievement_id, user_id, achievement_key, now_iso),
        )
        await db.commit()

        return {
            "achievement_key": achievement_key,
            "newly_unlocked": True,
            "title": definition["title"],
            "description": definition["description"],
        }
    finally:
        await db.close()


async def list_achievements(user_id: str) -> list[dict]:
    """List all unlocked achievements for a user."""
    db = await get_db()
    try:
        rows = await db.execute_fetchall(
            "SELECT id, achievement_key, unlocked_at FROM achievements WHERE user_id = ? ORDER BY unlocked_at ASC",
            (user_id,),
        )

        results = []
        for row in rows:
            definition = None
            for d in ACHIEVEMENT_DEFINITIONS:
                if d["key"] == row["achievement_key"]:
                    definition = d
                    break

            entry = {
                "id": row["id"],
                "achievement_key": row["achievement_key"],
                "unlocked_at": row["unlocked_at"],
            }
            if definition:
                entry["title"] = definition["title"]
                entry["description"] = definition["description"]
            results.append(entry)

        return results
    finally:
        await db.close()


def get_achievement_definitions() -> list[dict]:
    return [dict(d) for d in ACHIEVEMENT_DEFINITIONS]
