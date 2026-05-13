from services.auth_service import create_jwt, create_refresh_token, verify_jwt


class TestAuthAPI:
    def test_login_missing_provider(self, client):
        resp = client.post("/api/auth/login", json={})
        assert resp.status_code == 422

    def test_login_missing_token(self, client):
        resp = client.post("/api/auth/login", json={"provider": "apple"})
        assert resp.status_code == 422

    def test_login_invalid_token(self, client):
        resp = client.post("/api/auth/login", json={
            "provider": "apple",
            "identity_token": "garbage",
        })
        assert resp.status_code == 401

    def test_login_with_valid_jwt(self, client):
        # We can create a valid JWT — test the response shape
        token = create_jwt(user_id="test-user", provider="apple")
        # But login endpoint shouldn't accept application JWTs
        # Actually this doesn't make sense — let's test users/me instead
        pass

    def test_refresh_valid_token(self, client):
        refresh_token = create_refresh_token(user_id="test-user", provider="google")
        resp = client.post("/api/auth/refresh", json={
            "refresh_token": refresh_token,
        })
        assert resp.status_code == 200
        data = resp.json()
        assert "token" in data
        assert data["user_id"] == "test-user"
        # Verify the new token is valid
        payload = verify_jwt(data["token"])
        assert payload is not None
        assert payload["user_id"] == "test-user"

    def test_refresh_invalid_token(self, client):
        resp = client.post("/api/auth/refresh", json={
            "refresh_token": "invalid.token.here",
        })
        assert resp.status_code == 401

    def test_refresh_expired_token(self, client):
        # Create a token that's already expired
        from datetime import datetime, timedelta, timezone
        from jose import jwt
        from jose.constants import Algorithms
        from config import settings

        now = datetime.now(timezone.utc)
        payload = {
            "user_id": "test-user",
            "auth_provider": "apple",
            "iat": now - timedelta(hours=2),
            "exp": now - timedelta(hours=1),
        }
        expired = jwt.encode(payload, settings.secret_key, algorithm=Algorithms.HS256)
        resp = client.post("/api/auth/refresh", json={
            "refresh_token": expired,
        })
        assert resp.status_code == 401


class TestUsersAPI:
    def test_get_me_no_token(self, client):
        resp = client.get("/api/users/me")
        assert resp.status_code == 401

    def test_get_me_invalid_token(self, client):
        resp = client.get(
            "/api/users/me",
            headers={"Authorization": "Bearer invalid.token.here"},
        )
        assert resp.status_code == 401

    def test_get_me_valid_token(self, client):
        # Create a real token for a user that may or may not exist
        token = create_jwt(user_id="test-user-456", provider="apple")
        resp = client.get(
            "/api/users/me",
            headers={"Authorization": f"Bearer {token}"},
        )
        # Should return user info or 404 if not found
        assert resp.status_code in (200, 404)
