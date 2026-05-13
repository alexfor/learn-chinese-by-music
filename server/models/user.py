from pydantic import BaseModel
from typing import Optional


class LoginRequest(BaseModel):
    provider: str  # 'apple' | 'google'
    identity_token: str


class LoginResponse(BaseModel):
    token: str
    user_id: str
    refresh_token: str = ""


class RefreshRequest(BaseModel):
    refresh_token: str


class RefreshResponse(BaseModel):
    token: str
    user_id: str


class UserResponse(BaseModel):
    id: str
    nickname: Optional[str] = None
    avatar_url: Optional[str] = None
    level_score: float = 0
    subscription: str = "free"


class UserCreate(BaseModel):
    id: str
    auth_provider: str
    provider_id: str
    nickname: Optional[str] = None
    avatar_url: Optional[str] = None
