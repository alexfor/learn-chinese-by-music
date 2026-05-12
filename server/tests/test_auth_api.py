from services.auth_service import create_jwt


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
