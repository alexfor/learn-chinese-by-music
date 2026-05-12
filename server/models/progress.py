from pydantic import BaseModel
from typing import Optional


class ProgressSyncRequest(BaseModel):
    song_id: str
    sentence_scores: list[float]
    best_score: float
    passed: bool


class ProgressResponse(BaseModel):
    song_id: str
    sentence_scores: list[float]
    best_score: float
    passed: bool
    updated_at: str
