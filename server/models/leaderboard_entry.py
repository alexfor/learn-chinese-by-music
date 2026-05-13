from pydantic import BaseModel


class LeaderboardSubmitRequest(BaseModel):
    song_id: str
    best_score: float
    sentence_scores: list[float]


class LeaderboardEntry(BaseModel):
    rank: int
    user_id: str
    nickname: str
    score: float
    attempts: int


class LeaderboardResponse(BaseModel):
    song_id: str
    entries: list[LeaderboardEntry]


class MyRankResponse(BaseModel):
    rank: int
    score: float
    attempts: int
