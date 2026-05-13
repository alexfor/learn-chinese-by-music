import sqlite3
from pathlib import Path

import pytest
from services.auth_service import create_jwt
from config import settings


def _seed_test_data():
    db_path = Path(settings.database_path)
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path))
    try:
        conn.execute("PRAGMA foreign_keys=ON")
        conn.execute("DELETE FROM streaks")
        conn.execute("DELETE FROM achievements")
        conn.execute(
            "INSERT OR IGNORE INTO users (id, auth_provider, provider_id, nickname) VALUES (?, ?, ?, ?)",
            ("test-streak-user", "apple", "test-streak-sub", "StreakUser"),
        )
        conn.execute(
            "INSERT OR IGNORE INTO users (id, auth_provider, provider_id, nickname) VALUES (?, ?, ?, ?)",
            ("test-achievement-user", "apple", "test-achievement-sub", "AchUser"),
        )
        conn.execute(
            "INSERT OR IGNORE INTO users (id, auth_provider, provider_id, nickname) VALUES (?, ?, ?, ?)",
            ("test-empty-achievement-user", "apple", "test-empty-ach-sub", "EmptyAchUser"),
        )
        conn.execute(
            "INSERT OR IGNORE INTO songs (id, title, style, difficulty, status) VALUES (?, ?, ?, ?, ?)",
            ("ach-song-1", "Test Song", "pop", 5.0, "published"),
        )
        # Seed progress so achievement_user has completed a song
        conn.execute(
            "INSERT OR IGNORE INTO progress (user_id, song_id, sentence_scores, best_score, passed) VALUES (?, ?, ?, ?, ?)",
            ("test-achievement-user", "ach-song-1", "[90, 95]", 92.5, 1),
        )
        conn.commit()
    finally:
        conn.close()


@pytest.fixture(autouse=True)
def seed_db():
    _seed_test_data()


class TestStreakAPI:
    def test_checkin_requires_auth(self, client):
        resp = client.post("/api/streak/checkin")
        assert resp.status_code == 401

    def test_get_streak_requires_auth(self, client):
        resp = client.get("/api/streak")
        assert resp.status_code == 401

    def test_first_checkin_creates_streak(self, client):
        token = create_jwt(user_id="test-streak-user", provider="apple")
        resp = client.post(
            "/api/streak/checkin",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["current_streak"] == 1
        assert data["longest_streak"] == 1
        assert data["checked_in_today"] is True

    def test_double_checkin_same_day(self, client):
        token = create_jwt(user_id="test-streak-user", provider="apple")
        client.post("/api/streak/checkin", headers={"Authorization": f"Bearer {token}"})
        resp = client.post(
            "/api/streak/checkin",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["current_streak"] == 1
        assert data["checked_in_today"] is True

    def test_get_streak(self, client):
        token = create_jwt(user_id="test-streak-user", provider="apple")
        client.post("/api/streak/checkin", headers={"Authorization": f"Bearer {token}"})
        resp = client.get(
            "/api/streak",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["current_streak"] >= 1
        assert "last_checkin" in data

    def test_streak_continuation(self, client):
        """Check in on consecutive days continues the streak."""
        from datetime import date, timedelta
        yesterday = (date.today() - timedelta(days=1)).isoformat()

        import sqlite3
        from pathlib import Path
        conn = sqlite3.connect(str(Path(settings.database_path)))
        try:
            conn.execute(
                "INSERT OR REPLACE INTO streaks (user_id, current_streak, longest_streak, last_checkin) VALUES (?, ?, ?, ?)",
                ("test-streak-user", 3, 5, yesterday),
            )
            conn.commit()
        finally:
            conn.close()

        token = create_jwt(user_id="test-streak-user", provider="apple")
        resp = client.post(
            "/api/streak/checkin",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["current_streak"] == 4  # incremented from 3
        assert data["longest_streak"] == 5  # unchanged
        assert data["checked_in_today"] is True

    def test_streak_reset_after_miss(self, client):
        """Missing a day resets the streak to 1."""
        from datetime import date, timedelta
        two_days_ago = (date.today() - timedelta(days=2)).isoformat()

        import sqlite3
        from pathlib import Path
        conn = sqlite3.connect(str(Path(settings.database_path)))
        try:
            conn.execute(
                "INSERT OR REPLACE INTO streaks (user_id, current_streak, longest_streak, last_checkin) VALUES (?, ?, ?, ?)",
                ("test-streak-user", 3, 5, two_days_ago),
            )
            conn.commit()
        finally:
            conn.close()

        token = create_jwt(user_id="test-streak-user", provider="apple")
        resp = client.post(
            "/api/streak/checkin",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["current_streak"] == 1  # reset
        assert data["longest_streak"] == 5  # still the longest


class TestAchievementAPI:
    def test_list_achievements_requires_auth(self, client):
        resp = client.get("/api/achievements")
        assert resp.status_code == 401

    def test_list_achievements_empty(self, client):
        token = create_jwt(user_id="test-empty-achievement-user", provider="apple")
        resp = client.get(
            "/api/achievements",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        assert resp.json() == []

    def test_unlock_achievement_and_list(self, client):
        token = create_jwt(user_id="test-achievement-user", provider="apple")
        resp = client.post(
            "/api/achievements/unlock",
            json={"achievement_key": "first_singalong"},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["achievement_key"] == "first_singalong"
        assert data["newly_unlocked"] is True

        resp2 = client.get(
            "/api/achievements",
            headers={"Authorization": f"Bearer {token}"},
        )
        achievements = resp2.json()
        assert len(achievements) == 1
        assert achievements[0]["achievement_key"] == "first_singalong"

    def test_unlock_duplicate_is_idempotent(self, client):
        token = create_jwt(user_id="test-achievement-user", provider="apple")
        client.post(
            "/api/achievements/unlock",
            json={"achievement_key": "perfect_score"},
            headers={"Authorization": f"Bearer {token}"},
        )
        resp = client.post(
            "/api/achievements/unlock",
            json={"achievement_key": "perfect_score"},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["newly_unlocked"] is False

    def test_unlock_requires_auth(self, client):
        resp = client.post(
            "/api/achievements/unlock",
            json={"achievement_key": "first_singalong"},
        )
        assert resp.status_code == 401

    def test_get_available_achievement_definitions(self, client):
        token = create_jwt(user_id="test-achievement-user", provider="apple")
        resp = client.get(
            "/api/achievements/definitions",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        definitions = resp.json()
        assert len(definitions) > 0
        keys = [d["key"] for d in definitions]
        assert "first_singalong" in keys
        assert "perfect_score" in keys
        assert "five_songs_completed" in keys
        assert "seven_day_streak" in keys
