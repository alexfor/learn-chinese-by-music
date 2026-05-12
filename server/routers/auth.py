from fastapi import APIRouter, HTTPException, status
from database import get_db
from models.user import LoginRequest, LoginResponse
from services.auth_service import (
    AppleTokenValidator,
    GoogleTokenValidator,
    create_jwt,
    generate_user_id,
)

router = APIRouter(prefix="/api/auth", tags=["auth"])

_apple_validator = AppleTokenValidator()
_google_validator = GoogleTokenValidator()


@router.post("/login", response_model=LoginResponse)
async def login(req: LoginRequest):
    provider = req.provider.lower()
    if provider not in ("apple", "google"):
        raise HTTPException(status_code=400, detail="Unsupported provider")

    # Validate the identity token
    payload = None
    if provider == "apple":
        payload = await _apple_validator.validate(req.identity_token)
    elif provider == "google":
        payload = await _google_validator.validate(req.identity_token)

    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid identity token",
        )

    provider_id = payload.get("sub", "")
    nickname = payload.get("name") or payload.get("email", "")
    avatar_url = payload.get("picture") or ""

    # Find or create user
    db = await get_db()
    try:
        row = await db.execute_fetchall(
            "SELECT id FROM users WHERE auth_provider = ? AND provider_id = ?",
            (provider, provider_id),
        )

        if row:
            user_id = row[0]["id"]
        else:
            user_id = generate_user_id()
            await db.execute(
                """INSERT INTO users (id, auth_provider, provider_id, nickname, avatar_url)
                   VALUES (?, ?, ?, ?, ?)""",
                (user_id, provider, provider_id, nickname, avatar_url),
            )
            await db.commit()

        token = create_jwt(user_id=user_id, provider=provider)
        return LoginResponse(token=token, user_id=user_id)
    finally:
        await db.close()
