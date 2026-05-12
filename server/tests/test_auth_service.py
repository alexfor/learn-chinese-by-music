import pytest
from services.auth_service import create_jwt, verify_jwt, AppleTokenValidator, GoogleTokenValidator


class TestJWT:
    def test_create_and_verify_jwt(self):
        token = create_jwt(user_id="user-123", provider="apple")
        assert isinstance(token, str)
        assert len(token) > 20

        payload = verify_jwt(token)
        assert payload is not None
        assert payload["user_id"] == "user-123"
        assert payload["auth_provider"] == "apple"

    def test_verify_invalid_token_returns_none(self):
        assert verify_jwt("invalid.token.here") is None

    def test_verify_tampered_token_returns_none(self):
        token = create_jwt(user_id="user-123", provider="google")
        parts = token.split(".")
        tampered = f"{parts[0]}.{parts[1]}.invalidsignature"
        assert verify_jwt(tampered) is None


class TestAppleTokenValidator:
    @pytest.mark.asyncio
    async def test_validate_empty_token_returns_none(self):
        v = AppleTokenValidator()
        result = await v.validate("")
        assert result is None

    @pytest.mark.asyncio
    async def test_validate_garbage_returns_none(self):
        v = AppleTokenValidator()
        result = await v.validate("this.is.definitely.not.a.real.token")
        assert result is None


class TestGoogleTokenValidator:
    @pytest.mark.asyncio
    async def test_validate_empty_token_returns_none(self):
        v = GoogleTokenValidator()
        result = await v.validate("")
        assert result is None

    @pytest.mark.asyncio
    async def test_validate_garbage_returns_none(self):
        v = GoogleTokenValidator()
        result = await v.validate("this.is.definitely.not.a.real.token")
        assert result is None
