import sqlite3
from pathlib import Path

import pytest
from services.auth_service import create_jwt
from config import settings


def _seed_test_data():
    """Insert test users into the database synchronously."""
    db_path = Path(settings.database_path)
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(str(db_path))
    try:
        conn.execute("PRAGMA foreign_keys=ON")
        conn.execute("DELETE FROM purchase_history")
        conn.execute("DELETE FROM user_purchased_songs")
        conn.execute(
            "INSERT OR IGNORE INTO users (id, auth_provider, provider_id, nickname) VALUES (?, ?, ?, ?)",
            ("test-pay-user", "apple", "test-pay-sub", "PayUser"),
        )
        conn.execute(
            "INSERT OR IGNORE INTO users (id, auth_provider, provider_id, nickname) VALUES (?, ?, ?, ?)",
            ("test-free-user", "apple", "test-free-sub", "FreeUser"),
        )
        conn.execute(
            "INSERT OR IGNORE INTO users (id, auth_provider, provider_id, nickname, subscription, subscription_expires_at) VALUES (?, ?, ?, ?, ?, ?)",
            ("test-premium-user", "google", "test-premium-sub", "PremiumUser", "premium", "2099-12-31T23:59:59Z"),
        )
        conn.execute(
            "INSERT OR IGNORE INTO songs (id, title, style, difficulty, status) VALUES (?, ?, ?, ?, ?)",
            ("pay-song-1", "Premium Song", "pop", 5.0, "published"),
        )
        conn.commit()
    finally:
        conn.close()


@pytest.fixture(autouse=True)
def seed_db():
    _seed_test_data()


class TestPaymentAPI:
    def test_verify_requires_auth(self, client):
        resp = client.post("/api/payments/verify", json={
            "product_id": "monthly_subscription",
            "receipt": "mock-receipt-xxx",
            "platform": "ios",
        })
        assert resp.status_code == 401

    def test_subscription_info_requires_auth(self, client):
        resp = client.get("/api/payments/subscription")
        assert resp.status_code == 401

    def test_verify_monthly_subscription(self, client):
        token = create_jwt(user_id="test-pay-user", provider="apple")
        resp = client.post(
            "/api/payments/verify",
            json={
                "product_id": "monthly_subscription",
                "receipt": "mock-receipt-monthly",
                "platform": "ios",
            },
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "ok"
        assert data["subscription"] == "premium"
        assert "expires_at" in data

    def test_verify_yearly_subscription(self, client):
        token = create_jwt(user_id="test-pay-user", provider="apple")
        resp = client.post(
            "/api/payments/verify",
            json={
                "product_id": "yearly_subscription",
                "receipt": "mock-receipt-yearly",
                "platform": "ios",
            },
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["subscription"] == "premium"

    def test_verify_single_song_purchase(self, client):
        token = create_jwt(user_id="test-pay-user", provider="apple")
        resp = client.post(
            "/api/payments/verify",
            json={
                "product_id": "song_pay-song-1",
                "receipt": "mock-receipt-song-pay-song-1",
                "platform": "android",
            },
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["status"] == "ok"

    def test_get_subscription_free_user(self, client):
        token = create_jwt(user_id="test-free-user", provider="apple")
        resp = client.get(
            "/api/payments/subscription",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["subscription"] == "free"
        assert data["expires_at"] is None
        assert data["purchased_songs"] == []

    def test_get_subscription_premium_user(self, client):
        token = create_jwt(user_id="test-premium-user", provider="google")
        resp = client.get(
            "/api/payments/subscription",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["subscription"] == "premium"
        assert data["expires_at"] == "2099-12-31T23:59:59Z"

    def test_invalid_receipt(self, client):
        token = create_jwt(user_id="test-pay-user", provider="apple")
        resp = client.post(
            "/api/payments/verify",
            json={
                "product_id": "monthly_subscription",
                "receipt": "invalid-receipt",
                "platform": "ios",
            },
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 400

    def test_song_purchase_adds_to_purchased_songs(self, client):
        token = create_jwt(user_id="test-pay-user", provider="apple")
        resp = client.post(
            "/api/payments/verify",
            json={
                "product_id": "song_pay-song-1",
                "receipt": "mock-receipt-song-pay-song-1-v2",
                "platform": "android",
            },
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200

        resp2 = client.get(
            "/api/payments/subscription",
            headers={"Authorization": f"Bearer {token}"},
        )
        data = resp2.json()
        assert "pay-song-1" in data["purchased_songs"]

    def test_premium_user_can_access_premium_content(self, client):
        token = create_jwt(user_id="test-premium-user", provider="google")
        resp = client.get(
            "/api/payments/subscription",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["subscription"] == "premium"
        assert data["has_access"] is True

    def test_free_user_cannot_access_premium_content(self, client):
        token = create_jwt(user_id="test-free-user", provider="apple")
        resp = client.get(
            "/api/payments/subscription",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["subscription"] == "free"
        assert data["has_access"] is False

    def test_unknown_product_id(self, client):
        token = create_jwt(user_id="test-pay-user", provider="apple")
        resp = client.post(
            "/api/payments/verify",
            json={
                "product_id": "nonexistent_product",
                "receipt": "mock-receipt-unknown",
                "platform": "ios",
            },
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 400
        data = resp.json()
        assert "Unknown product_id" in data["detail"]

    def test_premium_song_gated_for_free_user(self, client):
        """Free user should get 403 when accessing a premium song."""
        # First, make a song premium in the database
        import sqlite3
        from pathlib import Path
        conn = sqlite3.connect(str(Path(settings.database_path)))
        try:
            conn.execute("INSERT OR IGNORE INTO songs (id, title, style, difficulty, status, access_level) VALUES (?, ?, ?, ?, ?, ?)",
                         ("premium-song-1", "Premium Only", "pop", 5.0, "published", "premium"))
            conn.commit()
        finally:
            conn.close()

        token = create_jwt(user_id="test-free-user", provider="apple")
        resp = client.get(
            "/api/songs/premium-song-1",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 403
        data = resp.json()
        assert "subscribe" in data["detail"].lower()

    def test_premium_song_accessible_for_premium_user(self, client):
        """Premium user should be able to access a premium song."""
        import sqlite3
        from pathlib import Path
        conn = sqlite3.connect(str(Path(settings.database_path)))
        try:
            conn.execute("INSERT OR IGNORE INTO songs (id, title, style, difficulty, status, access_level) VALUES (?, ?, ?, ?, ?, ?)",
                         ("premium-song-2", "Premium Only 2", "pop", 5.0, "published", "premium"))
            conn.commit()
        finally:
            conn.close()

        token = create_jwt(user_id="test-premium-user", provider="google")
        resp = client.get(
            "/api/songs/premium-song-2",
            headers={"Authorization": f"Bearer {token}"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["id"] == "premium-song-2"
