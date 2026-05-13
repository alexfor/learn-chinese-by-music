import json

from fastapi import APIRouter, Depends, HTTPException

from middleware.auth import get_current_user_id
from models.contest_entry import (
    ContestSubmitRequest,
    ContestEntryResponse,
    ContestDetailResponse,
)
from services.contest_service import list_contests, get_contest, submit_entry

router = APIRouter(prefix="/api/contests", tags=["contests"])

SONG_IDS_CACHE: dict[str, list[str]] = {}


def _parse_song_ids(raw: str) -> list[str]:
    if raw not in SONG_IDS_CACHE:
        SONG_IDS_CACHE[raw] = json.loads(raw)
    return SONG_IDS_CACHE[raw]


@router.get("")
async def list_all_contests():
    contests = await list_contests()
    result = []
    for c in contests:
        entry = dict(c)
        entry["song_ids"] = _parse_song_ids(entry.pop("song_ids"))
        result.append(entry)
    return result


@router.get("/{contest_id}", response_model=ContestDetailResponse)
async def get_contest_detail(contest_id: str):
    data = await get_contest(contest_id=contest_id)
    if data is None:
        raise HTTPException(status_code=404, detail="Contest not found")

    contest = data["contest"]
    entries_raw = data["entries"]

    entries = [
        ContestEntryResponse(rank=i + 1, **e)
        for i, e in enumerate(entries_raw)
    ]

    return ContestDetailResponse(
        id=contest["id"],
        title=contest["title"],
        song_ids=_parse_song_ids(contest["song_ids"]),
        start_date=contest["start_date"],
        end_date=contest["end_date"],
        status=contest["status"],
        created_at=contest["created_at"],
        entries=entries,
    )


@router.post("/{contest_id}/submit")
async def submit_contest_score(
    contest_id: str,
    req: ContestSubmitRequest,
    user_id: str = Depends(get_current_user_id),
):
    await submit_entry(
        contest_id=contest_id,
        user_id=user_id,
        song_id=req.song_id,
        score=req.score,
        sentence_scores=req.sentence_scores,
    )
    return {"status": "ok"}
