from pydantic import BaseModel


class ContestSubmitRequest(BaseModel):
    song_id: str
    score: float
    sentence_scores: list[float]


class ContestEntryResponse(BaseModel):
    user_id: str
    nickname: str
    song_id: str
    score: float
    rank: int


class ContestDetailResponse(BaseModel):
    id: str
    title: str
    song_ids: list[str]
    start_date: str
    end_date: str
    status: str
    created_at: str
    entries: list[ContestEntryResponse]
