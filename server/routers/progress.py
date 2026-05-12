from fastapi import APIRouter, Depends, HTTPException

from middleware.auth import get_current_user_id
from models.progress import ProgressSyncRequest, ProgressResponse
from services.progress_service import sync_progress, get_progress

router = APIRouter(prefix="/api/progress", tags=["progress"])


@router.post("/sync", response_model=ProgressResponse)
async def sync(
    req: ProgressSyncRequest,
    user_id: str = Depends(get_current_user_id),
):
    result = await sync_progress(
        user_id=user_id,
        song_id=req.song_id,
        sentence_scores=req.sentence_scores,
        best_score=req.best_score,
        passed=req.passed,
    )
    return result


@router.get("/{song_id}", response_model=ProgressResponse)
async def get(
    song_id: str,
    user_id: str = Depends(get_current_user_id),
):
    result = await get_progress(user_id=user_id, song_id=song_id)
    if result is None:
        raise HTTPException(status_code=404, detail="Progress not found")
    return result
