from fastapi import APIRouter, Depends, HTTPException, status

from database import get_db
from middleware.auth import get_current_user_id
from models.user import UserResponse

router = APIRouter(prefix="/api/users", tags=["users"])


@router.get("/me", response_model=UserResponse)
async def get_me(user_id: str = Depends(get_current_user_id)):
    db = await get_db()
    try:
        row = await db.execute_fetchall(
            "SELECT id, nickname, avatar_url, level_score, subscription FROM users WHERE id = ?",
            (user_id,),
        )

        if not row:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )

        return UserResponse(
            id=row[0]["id"],
            nickname=row[0]["nickname"],
            avatar_url=row[0]["avatar_url"],
            level_score=row[0]["level_score"],
            subscription=row[0]["subscription"],
        )
    finally:
        await db.close()
