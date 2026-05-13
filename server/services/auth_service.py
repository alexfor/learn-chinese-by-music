import uuid
from datetime import datetime, timedelta, timezone
from typing import Optional

import httpx
from jose import JWTError, jwt
from jose.constants import Algorithms

from config import settings


def create_jwt(user_id: str, provider: str, expires_minutes: int | None = None) -> str:
    now = datetime.now(timezone.utc)
    expire_minutes = expires_minutes if expires_minutes is not None else settings.jwt_expire_minutes
    payload = {
        "user_id": user_id,
        "auth_provider": provider,
        "iat": now,
        "exp": now + timedelta(minutes=expire_minutes),
    }
    return jwt.encode(payload, settings.secret_key, algorithm=Algorithms.HS256)


def create_refresh_token(user_id: str, provider: str) -> str:
    """Create a longer-lived refresh token."""
    return create_jwt(user_id, provider, expires_minutes=settings.jwt_refresh_expire_minutes)


def verify_jwt(token: str) -> Optional[dict]:
    try:
        payload = jwt.decode(token, settings.secret_key, algorithms=[Algorithms.HS256])
        return payload
    except JWTError:
        return None


class AppleTokenValidator:
    """Validates Apple Sign-In identity tokens."""

    _keys_url = "https://appleid.apple.com/auth/keys"

    async def validate(self, identity_token: str) -> Optional[dict]:
        if not identity_token:
            return None
        try:
            # Fetch Apple's public keys
            async with httpx.AsyncClient() as client:
                resp = await client.get(self._keys_url, timeout=10)
                if resp.status_code != 200:
                    return None
                keys = resp.json()

            # Decode and verify the token
            audience = settings.apple_bundle_id or settings.app_name
            payload = jwt.decode(
                identity_token,
                keys,
                algorithms=[Algorithms.RS256],
                audience=audience,
                issuer="https://appleid.apple.com",
            )
            return payload
        except Exception:
            return None


class GoogleTokenValidator:
    """Validates Google Sign-In ID tokens."""

    _keys_url = "https://www.googleapis.com/oauth2/v3/certs"

    async def validate(self, id_token: str) -> Optional[dict]:
        if not id_token:
            return None
        try:
            # Fetch Google's public keys
            async with httpx.AsyncClient() as client:
                resp = await client.get(self._keys_url, timeout=10)
                if resp.status_code != 200:
                    return None
                keys = resp.json()

            # Decode and verify the token
            audience = settings.google_client_id or settings.app_name
            payload = jwt.decode(
                id_token,
                keys,
                algorithms=[Algorithms.RS256],
                audience=audience,
                issuer="https://accounts.google.com",
            )
            return payload
        except Exception:
            return None


def generate_user_id() -> str:
    return str(uuid.uuid4())
