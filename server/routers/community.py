from fastapi import APIRouter, Depends, HTTPException, Query

from middleware.auth import get_current_user_id, optional_user_id
from models.community import CreatePostRequest, PostResponse
from services.community_service import (
    create_post,
    list_posts,
    get_post,
    like_post,
    unlike_post,
)

router = APIRouter(prefix="/api/community", tags=["community"])


@router.post("/posts", response_model=PostResponse)
async def create(
    req: CreatePostRequest,
    user_id: str = Depends(get_current_user_id),
):
    row = await create_post(
        user_id=user_id,
        song_id=req.song_id,
        title=req.title,
        audio_url=req.audio_url,
    )
    return PostResponse(
        id=row["id"],
        user_id=row["user_id"],
        nickname=row["nickname"],
        song_id=row["song_id"],
        title=row["title"],
        audio_url=row.get("audio_url"),
        likes=row["likes"],
        liked_by_me=False,
        created_at=row["created_at"],
    )


@router.get("/posts")
async def list_all(
    song_id: str | None = Query(None),
    sort: str = Query("latest", pattern="^(latest|hot)$"),
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    current_user_id: str | None = Depends(optional_user_id),
):
    rows = await list_posts(
        song_id=song_id,
        sort=sort,
        page=page,
        page_size=page_size,
        current_user_id=current_user_id,
    )
    return [
        PostResponse(
            id=r["id"],
            user_id=r["user_id"],
            nickname=r["nickname"],
            song_id=r["song_id"],
            title=r["title"],
            audio_url=r.get("audio_url"),
            likes=r["likes"],
            liked_by_me=r.get("liked_by_me", False),
            created_at=r["created_at"],
        )
        for r in rows
    ]


@router.get("/posts/{post_id}", response_model=PostResponse)
async def get_one(
    post_id: str,
    current_user_id: str | None = Depends(optional_user_id),
):
    row = await get_post(post_id=post_id, current_user_id=current_user_id)
    if row is None:
        raise HTTPException(status_code=404, detail="Post not found")

    return PostResponse(
        id=row["id"],
        user_id=row["user_id"],
        nickname=row["nickname"],
        song_id=row["song_id"],
        title=row["title"],
        audio_url=row.get("audio_url"),
        likes=row["likes"],
        liked_by_me=row.get("liked_by_me", False),
        created_at=row["created_at"],
    )


@router.post("/posts/{post_id}/like")
async def like(
    post_id: str,
    user_id: str = Depends(get_current_user_id),
):
    added = await like_post(post_id=post_id, user_id=user_id)
    return {"liked": added, "status": "ok"}


@router.delete("/posts/{post_id}/like")
async def unlike(
    post_id: str,
    user_id: str = Depends(get_current_user_id),
):
    removed = await unlike_post(post_id=post_id, user_id=user_id)
    return {"unliked": removed, "status": "ok"}
