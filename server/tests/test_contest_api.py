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
        conn.execute("DELETE FROM contest_entries")
        conn.execute("DELETE FROM contests")
        conn.execute(
            "INSERT OR IGNORE INTO users (id, auth_provider, provider_id, nickname) VALUES (?, ?, ?, ?)",
            ("ct-user-1", "apple", "ct-sub-1", "Contestant One"),
        )
        conn.execute(
            "INSERT OR IGNORE INTO users (id, auth_provider, provider_id, nickname) VALUES (?, ?, ?, ?)",
            ("ct-user-2", "google", "ct-sub-2", "Contestant Two"),
        )
        conn.execute(
            "INSERT OR IGNORE INTO songs (id, title, style, difficulty, status) VALUES (?, ?, ?, ?, ?)",
            ("ct-song-1", "Contest Song", "pop", 5.0, "published"),
        )
        conn.execute(
            "INSERT OR IGNORE INTO contests (id, title, song_ids, start_date, end_date, status) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            ("ct-contest-1", "Weekly Contest", '["ct-song-1"]',
             "2026-05-11", "2026-05-18", "active"),
        )
        conn.commit()
    finally:
        conn.close()


@pytest.fixture(autouse=True)
def seed_db():
    _seed()


class TestContestAPI:
    def test_list_contests_empty(self, client):
        conn = sqlite3.connect(str(Path(settings.database_path)))
        conn.execute("DELETE FROM contests")
        conn.commit()
        conn.close()

        resp = client.get("/api/contests")
        assert resp.status_code == 200
        assert resp.json() == []

    def test_list_contests(self, client):
        resp = client.get("/api/contests")
        assert resp.status_code == 200
        data = resp.json()
        assert len(data) == 1
        assert data[0]["id"] == "ct-contest-1"
        assert data[0]["title"] == "Weekly Contest"
        assert data[0]["status"] == "active"

    def test_get_contest_not_found(self, client):
        resp = client.get("/api/contests/nonexistent")
        assert resp.status_code == 404

    def test_get_contest(self, client):
        token = create_jwt(user_id="ct-user-1", provider="apple")
        client.post(
            "/api/contests/ct-contest-1/submit",
            json={"song_id": "ct-song-1", "score": 90.0, "sentence_scores": [90.0]},
            headers={"Authorization": f"Bearer {token}"},
        )

        resp = client.get("/api/contests/ct-contest-1")
        assert resp.status_code == 200
        data = resp.json()
        assert data["id"] == "ct-contest-1"
        assert len(data["entries"]) == 1
        assert data["entries"][0]["nickname"] == "Contestant One"
        assert data["entries"][0]["score"] == 90.0

    def test_submit_requires_auth(self, client):
        resp = client.post(
            "/api/contests/ct-contest-1/submit",
            json={"song_id": "ct-song-1", "score": 85.0, "sentence_scores": [85.0]},
        )
        assert resp.status_code == 401

    def test_submit_updates_existing_entry(self, client):
        token = create_jwt(user_id="ct-user-1", provider="apple")

        client.post(
            "/api/contests/ct-contest-1/submit",
            json={"song_id": "ct-song-1", "score": 70.0, "sentence_scores": [70.0]},
            headers={"Authorization": f"Bearer {token}"},
        )
        client.post(
            "/api/contests/ct-contest-1/submit",
            json={"song_id": "ct-song-1", "score": 95.0, "sentence_scores": [95.0]},
            headers={"Authorization": f"Bearer {token}"},
        )

        resp = client.get("/api/contests/ct-contest-1")
        assert resp.status_code == 200
        data = resp.json()
        assert len(data["entries"]) == 1
        assert data["entries"][0]["score"] == 95.0

    def test_submit_multiple_users(self, client):
        token1 = create_jwt(user_id="ct-user-1", provider="apple")
        token2 = create_jwt(user_id="ct-user-2", provider="google")

        client.post(
            "/api/contests/ct-contest-1/submit",
            json={"song_id": "ct-song-1", "score": 80.0, "sentence_scores": [80.0]},
            headers={"Authorization": f"Bearer {token1}"},
        )
        client.post(
            "/api/contests/ct-contest-1/submit",
            json={"song_id": "ct-song-1", "score": 95.0, "sentence_scores": [95.0]},
            headers={"Authorization": f"Bearer {token2}"},
        )

        resp = client.get("/api/contests/ct-contest-1")
        assert resp.status_code == 200
        data = resp.json()
        assert len(data["entries"]) == 2
        assert data["entries"][0]["score"] == 95.0  # highest first
        assert data["entries"][1]["score"] == 80.0
