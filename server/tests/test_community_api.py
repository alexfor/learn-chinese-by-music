import sqlite3
from pathlib import Path

import pytest
from fastapi.testclient import TestClient
from services.auth_service import create_jwt
from config import settings


def _seed():
    db_path = Path(settings.database_path)
    conn = sqlite3.connect(str(db_path))
    try:
        conn.execute("PRAGMA foreign_keys=ON")
        conn.execute("DELETE FROM community_likes")
        conn.execute("DELETE FROM community_posts")
        conn.execute(
            "INSERT OR IGNORE INTO users (id, auth_provider, provider_id, nickname) VALUES (?, ?, ?, ?)",
            ("cm-user-1", "apple", "cm-sub-1", "Community User"),
        )
        conn.execute(
            "INSERT OR IGNORE INTO songs (id, title, style, difficulty, status) VALUES (?, ?, ?, ?, ?)",
            ("cm-song-1", "Community Song", "pop", 5.0, "published"),
        )
        conn.commit()
    finally:
        conn.close()


@pytest.fixture(autouse=True)
def seed_db(client: TestClient):
    _seed()


class TestCommunityAPI:
    def test_create_post_requires_auth(self, client):
        resp = client.post(
            "/api/community/posts",
            json={"song_id": "cm-song-1", "title": "My cover!"},
        )
        assert resp.status_code == 401

    def test_create_and_list_posts(self, client):
        token = create_jwt(user_id="cm-user-1", provider="apple")
        resp = client.post(
            "/api/community/posts",
            json={"song_id": "cm-song-1", "title": "My first cover"},
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        post_id = resp.json()["id"]

        resp = client.get("/api/community/posts")
        assert resp.status_code == 200
        data = resp.json()
        assert len(data) == 1
        assert data[0]["id"] == post_id
        assert data[0]["title"] == "My first cover"
        assert data[0]["nickname"] == "Community User"
        assert data[0]["likes"] == 0

    def test_list_posts_empty(self, client):
        resp = client.get("/api/community/posts")
        assert resp.status_code == 200
        assert resp.json() == []

    def test_list_posts_by_song(self, client):
        token = create_jwt(user_id="cm-user-1", provider="apple")
        client.post(
            "/api/community/posts",
            json={"song_id": "cm-song-1", "title": "Song 1 cover"},
            headers={"Authorization": f"Bearer {token}"},
        )

        resp = client.get("/api/community/posts?song_id=cm-song-1")
        assert resp.status_code == 200
        data = resp.json()
        assert len(data) == 1
        assert data[0]["song_id"] == "cm-song-1"

        resp = client.get("/api/community/posts?song_id=nonexistent")
        assert resp.status_code == 200
        assert resp.json() == []

    def test_like_requires_auth(self, client):
        token = create_jwt(user_id="cm-user-1", provider="apple")
        resp = client.post(
            "/api/community/posts",
            json={"song_id": "cm-song-1", "title": "Test"},
            headers={"Authorization": f"Bearer {token}"},
        )
        post_id = resp.json()["id"]

        resp = client.post(f"/api/community/posts/{post_id}/like")
        assert resp.status_code == 401

    def test_like_and_unlike(self, client):
        token = create_jwt(user_id="cm-user-1", provider="apple")
        resp = client.post(
            "/api/community/posts",
            json={"song_id": "cm-song-1", "title": "Test"},
            headers={"Authorization": f"Bearer {token}"},
        )
        post_id = resp.json()["id"]

        # Like
        resp = client.post(
            f"/api/community/posts/{post_id}/like",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200

        resp = client.get("/api/community/posts")
        assert resp.json()[0]["likes"] == 1

        # Unlike
        resp = client.delete(
            f"/api/community/posts/{post_id}/like",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200

        resp = client.get("/api/community/posts")
        assert resp.json()[0]["likes"] == 0

    def test_double_like_idempotent(self, client):
        token = create_jwt(user_id="cm-user-1", provider="apple")
        resp = client.post(
            "/api/community/posts",
            json={"song_id": "cm-song-1", "title": "Test"},
            headers={"Authorization": f"Bearer {token}"},
        )
        post_id = resp.json()["id"]

        for _ in range(3):
            client.post(
                f"/api/community/posts/{post_id}/like",
                headers={"Authorization": f"Bearer {token}"},
            )

        resp = client.get("/api/community/posts")
        assert resp.json()[0]["likes"] == 1

    def test_liked_by_me_flag(self, client):
        token = create_jwt(user_id="cm-user-1", provider="apple")
        resp = client.post(
            "/api/community/posts",
            json={"song_id": "cm-song-1", "title": "Test"},
            headers={"Authorization": f"Bearer {token}"},
        )
        post_id = resp.json()["id"]

        # Before like
        resp = client.get(
            "/api/community/posts",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.json()[0]["liked_by_me"] is False

        # Like
        client.post(
            f"/api/community/posts/{post_id}/like",
            headers={"Authorization": f"Bearer {token}"},
        )

        # After like
        resp = client.get(
            "/api/community/posts",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.json()[0]["liked_by_me"] is True
