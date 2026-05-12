import sqlite3
from pathlib import Path

import pytest
from services.auth_service import create_jwt
from config import settings


def _seed_test_data():
    """Insert test user and songs into the database synchronously."""
    db_path = Path(settings.database_path)
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path))
    try:
        conn.execute("PRAGMA foreign_keys=ON")
        conn.execute(
            "INSERT OR IGNORE INTO users (id, auth_provider, provider_id, nickname) VALUES (?, ?, ?, ?)",
            ("test-progress-user", "apple", "test-progress-sub", "TestUser"),
        )
        conn.execute(
            "INSERT OR IGNORE INTO songs (id, title, style, difficulty, status) VALUES (?, ?, ?, ?, ?)",
            ("song-456", "Test Song", "pop", 5.0, "published"),
        )
        conn.execute(
            "INSERT OR IGNORE INTO songs (id, title, style, difficulty, status) VALUES (?, ?, ?, ?, ?)",
            ("song-789", "Test Song 2", "pop", 5.0, "published"),
        )
        conn.commit()
    finally:
        conn.close()


@pytest.fixture(autouse=True)
def seed_db():
    _seed_test_data()


class TestProgressAPI:
    def test_sync_progress_requires_auth(self, client):
        resp = client.post("/api/progress/sync", json={
            "song_id": "song-123",
            "sentence_scores": [85.0, 90.0],
            "best_score": 87.5,
            "passed": True,
        })
        assert resp.status_code == 401

    def test_get_progress_requires_auth(self, client):
        resp = client.get("/api/progress/song-123")
        assert resp.status_code == 401

    def test_sync_and_get_progress(self, client):
        token = create_jwt(user_id="test-progress-user", provider="apple")

        resp = client.post(
            "/api/progress/sync",
            json={
                "song_id": "song-456",
                "sentence_scores": [75.0, 82.5, 91.0],
                "best_score": 82.8,
                "passed": True,
            },
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["song_id"] == "song-456"
        assert data["best_score"] == 82.8
        assert data["passed"] is True

        resp = client.get(
            "/api/progress/song-456",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["song_id"] == "song-456"
        assert data["best_score"] == 82.8
        assert data["passed"] is True

    def test_sync_update_existing_progress(self, client):
        token = create_jwt(user_id="test-progress-user", provider="apple")

        client.post(
            "/api/progress/sync",
            json={
                "song_id": "song-789",
                "sentence_scores": [60.0],
                "best_score": 60.0,
                "passed": False,
            },
            headers={"Authorization": f"Bearer {token}"},
        )

        resp = client.post(
            "/api/progress/sync",
            json={
                "song_id": "song-789",
                "sentence_scores": [95.0],
                "best_score": 95.0,
                "passed": True,
            },
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["best_score"] == 95.0
        assert data["passed"] is True

    def test_get_progress_not_found(self, client):
        token = create_jwt(user_id="test-progress-user", provider="apple")
        resp = client.get(
            "/api/progress/nonexistent-song",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 404
