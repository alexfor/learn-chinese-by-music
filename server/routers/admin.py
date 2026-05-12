from fastapi import APIRouter, Query
from uuid import uuid4

from models.song import SongCreate, SongUpdate
from services.song_service import create_song, update_song, delete_song, get_song

router = APIRouter(prefix="/api/admin", tags=["admin"])


@router.post("/songs")
async def admin_create_song(data: SongCreate):
    song_id = data.id or str(uuid4())
    song_dict = data.model_dump()
    song_dict["id"] = song_id
    if song_dict.get("lyric_json") and not isinstance(song_dict["lyric_json"], str):
        import json
        song_dict["lyric_json"] = json.dumps(song_dict["lyric_json"], ensure_ascii=False)
    await create_song(song_dict)
    return {"id": song_id}


@router.put("/songs/{song_id}")
async def admin_update_song(song_id: str, data: SongUpdate):
    update_dict = data.model_dump(exclude_none=True)
    if update_dict.get("lyric_json") and not isinstance(update_dict["lyric_json"], str):
        import json
        update_dict["lyric_json"] = json.dumps(update_dict["lyric_json"], ensure_ascii=False)
    ok = await update_song(song_id, update_dict)
    if not ok:
        return {"error": "Song not found or no changes"}
    return {"updated": True}


@router.delete("/songs/{song_id}")
async def admin_delete_song(song_id: str):
    ok = await delete_song(song_id)
    if not ok:
        return {"error": "Song not found"}
    return {"deleted": True}


@router.patch("/songs/{song_id}/status")
async def admin_update_status(song_id: str, status: str = Query(...)):
    ok = await update_song(song_id, {"status": status})
    if not ok:
        return {"error": "Song not found"}
    return {"updated": True}
