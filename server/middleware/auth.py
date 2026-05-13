from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from typing import Optional

from services.auth_service import verify_jwt
from database import get_db

security = HTTPBearer()
optional_security = HTTPBearer(auto_error=False)


async def get_current_user_id(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security),
) -> str:
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Not authenticated",
        )

    payload = verify_jwt(credentials.credentials)
    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )

    return payload["user_id"]


async def require_admin(
    user_id: str = Depends(get_current_user_id),
) -> str:
    db = await get_db()
    try:
        row = await db.execute_fetchall(
            "SELECT role FROM users WHERE id = ?", (user_id,),
        )
        if not row or row[0]["role"] != "admin":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Admin access required",
            )
        return user_id
    finally:
        await db.close()


async def optional_user_id(
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(optional_security),
) -> Optional[str]:
    if credentials is None:
        return None
    payload = verify_jwt(credentials.credentials)
    if payload is None:
        return None
    return payload["user_id"]
