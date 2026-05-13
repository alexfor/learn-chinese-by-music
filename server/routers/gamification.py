from fastapi import APIRouter, Depends, HTTPException

from middleware.auth import get_current_user_id
from models.gamification import (
    StreakResponse,
    AchievementResponse,
    UnlockAchievementRequest,
    UnlockAchievementResponse,
    AchievementDefinition,
)
from services.gamification_service import (
    checkin_streak,
    get_streak,
    unlock_achievement,
    list_achievements,
    get_achievement_definitions,
)

router = APIRouter(tags=["gamification"])


@router.post("/api/streak/checkin", response_model=StreakResponse)
async def checkin(
    user_id: str = Depends(get_current_user_id),
):
    result = await checkin_streak(user_id=user_id)
    return StreakResponse(**result)


@router.get("/api/streak", response_model=StreakResponse)
async def read_streak(
    user_id: str = Depends(get_current_user_id),
):
    result = await get_streak(user_id=user_id)
    return StreakResponse(**result)


@router.get("/api/achievements", response_model=list[AchievementResponse])
async def read_achievements(
    user_id: str = Depends(get_current_user_id),
):
    return await list_achievements(user_id=user_id)


@router.post("/api/achievements/unlock", response_model=UnlockAchievementResponse)
async def unlock(
    req: UnlockAchievementRequest,
    user_id: str = Depends(get_current_user_id),
):
    try:
        result = await unlock_achievement(user_id=user_id, achievement_key=req.achievement_key)
        return UnlockAchievementResponse(**result)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/api/achievements/definitions", response_model=list[AchievementDefinition])
async def read_achievement_definitions(
    user_id: str = Depends(get_current_user_id),
):
    return get_achievement_definitions()
