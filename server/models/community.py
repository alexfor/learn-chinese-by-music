from pydantic import BaseModel
from typing import Optional


class CreatePostRequest(BaseModel):
    song_id: str
    title: str
    audio_url: Optional[str] = None


class PostResponse(BaseModel):
    id: str
    user_id: str
    nickname: str
    song_id: str
    title: str
    audio_url: Optional[str] = None
    likes: int
    liked_by_me: bool = False
    created_at: str
