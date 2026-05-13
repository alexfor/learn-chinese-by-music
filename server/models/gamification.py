from pydantic import BaseModel
from typing import Optional


class StreakResponse(BaseModel):
    current_streak: int = 0
    longest_streak: int = 0
    last_checkin: Optional[str] = None
    checked_in_today: bool = False


class AchievementResponse(BaseModel):
    id: str
    achievement_key: str
    unlocked_at: str
    title: Optional[str] = None
    description: Optional[str] = None


class UnlockAchievementRequest(BaseModel):
    achievement_key: str


class UnlockAchievementResponse(BaseModel):
    achievement_key: str
    newly_unlocked: bool
    title: Optional[str] = None
    description: Optional[str] = None


class AchievementDefinition(BaseModel):
    key: str
    title: str
    description: str
    icon: str = "emoji_events"
