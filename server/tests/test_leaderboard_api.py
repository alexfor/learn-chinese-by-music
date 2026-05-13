import sqlite3
from pathlib import Path

import pytest
from services.auth_service import create_jwt
from config import settings


def _seed():
    db_path = Path(settings.database_path)
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path))
    try:
        conn.execute("PRAGMA foreign_keys=ON")
        conn.execute("DELETE FROM song_leaderboard")
        conn.execute(
            "INSERT OR IGNORE INTO users (id, auth_provider, provider_id, nickname) VALUES (?, ?, ?, ?)",
            ("lb-user-1", "apple", "lb-sub-1", "Player One"),
        )
        conn.execute(
            "INSERT OR IGNORE INTO users (id, auth_provider, provider_id, nickname) VALUES (?, ?, ?, ?)",
            ("lb-user-2", "google", "lb-sub-2", "Player Two"),
        )
        conn.execute(
            "INSERT OR IGNORE INTO songs (id, title, style, difficulty, status) VALUES (?, ?, ?, ?, ?)",
            ("lb-song-1", "Leaderboard Test Song", "pop", 5.0, "published"),
        )
        conn.commit()
    finally:
        conn.close()


@pytest.fixture(autouse=True)
def seed_db():
    _seed()


class TestLeaderboardAPI:
    def test_get_leaderboard_no_scores(self, client):
        token = create_jwt(user_id="lb-user-1", provider="apple")
        resp = client.get(
            "/api/leaderboard/songs/lb-song-1",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["song_id"] == "lb-song-1"
        assert data["entries"] == []

    def test_get_leaderboard_requires_auth(self, client):
        resp = client.get("/api/leaderboard/songs/lb-song-1")
        assert resp.status_code == 401

    def test_submit_and_get_leaderboard(self, client):
        token1 = create_jwt(user_id="lb-user-1", provider="apple")
        token2 = create_jwt(user_id="lb-user-2", provider="google")

        for token, score in [(token1, 85.0), (token2, 92.5)]:
            client.post(
                "/api/leaderboard/submit",
                json={
                    "song_id": "lb-song-1",
                    "best_score": score,
                    "sentence_scores": [score],
                },
                headers={"Authorization": f"Bearer {token}"},
            )

        resp = client.get(
            "/api/leaderboard/songs/lb-song-1",
            headers={"Authorization": f"Bearer {token1}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert len(data["entries"]) == 2
        assert data["entries"][0]["score"] == 92.5  # highest first
        assert data["entries"][1]["score"] == 85.0

    def test_submit_updates_existing_score(self, client):
        token = create_jwt(user_id="lb-user-1", provider="apple")

        client.post(
            "/api/leaderboard/submit",
            json={"song_id": "lb-song-1", "best_score": 70.0, "sentence_scores": [70.0]},
            headers={"Authorization": f"Bearer {token}"},
        )
        client.post(
            "/api/leaderboard/submit",
            json={"song_id": "lb-song-1", "best_score": 95.0, "sentence_scores": [95.0]},
            headers={"Authorization": f"Bearer {token}"},
        )

        resp = client.get(
            "/api/leaderboard/songs/lb-song-1",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert len(data["entries"]) == 1
        assert data["entries"][0]["score"] == 95.0
        assert data["entries"][0]["attempts"] == 2

    def test_get_my_rank(self, client):
        token = create_jwt(user_id="lb-user-1", provider="apple")
        client.post(
            "/api/leaderboard/submit",
            json={"song_id": "lb-song-1", "best_score": 88.0, "sentence_scores": [88.0]},
            headers={"Authorization": f"Bearer {token}"},
        )

        resp = client.get(
            "/api/leaderboard/songs/lb-song-1/me",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["rank"] == 1
        assert data["score"] == 88.0
