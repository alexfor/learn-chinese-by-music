from fastapi import APIRouter, Depends

from middleware.auth import get_current_user_id
from models.leaderboard_entry import (
    LeaderboardResponse,
    LeaderboardEntry,
    MyRankResponse,
    LeaderboardSubmitRequest,
)
from services.leaderboard_service import (
    update_leaderboard,
    get_song_leaderboard,
    get_user_rank,
)

router = APIRouter(prefix="/api/leaderboard", tags=["leaderboard"])


@router.post("/submit")
async def submit(
    req: LeaderboardSubmitRequest,
    user_id: str = Depends(get_current_user_id),
):
    await update_leaderboard(
        user_id=user_id,
        song_id=req.song_id,
        best_score=req.best_score,
        sentence_scores=req.sentence_scores,
    )
    return {"status": "ok"}


@router.get("/songs/{song_id}", response_model=LeaderboardResponse)
async def get_leaderboard(
    song_id: str,
    user_id: str = Depends(get_current_user_id),
):
    entries_data = await get_song_leaderboard(song_id=song_id)
    entries = [
        LeaderboardEntry(rank=i + 1, **entry)
        for i, entry in enumerate(entries_data)
    ]
    return LeaderboardResponse(song_id=song_id, entries=entries)


@router.get("/songs/{song_id}/me", response_model=MyRankResponse)
async def get_my_rank(
    song_id: str,
    user_id: str = Depends(get_current_user_id),
):
    result = await get_user_rank(user_id=user_id, song_id=song_id)
    if result is None:
        return MyRankResponse(rank=0, score=0.0, attempts=0)
    return MyRankResponse(**result)
