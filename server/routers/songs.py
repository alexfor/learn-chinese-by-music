from fastapi import APIRouter, Query, Request
from starlette.responses import RedirectResponse

from models.song import SongListResponse, SongListItem, SongResponse
from services.song_service import list_songs, get_song
from services.region_service import detect_region
from services.storage_service import generate_download_url
from services.translation_service import filter_lyric_json_by_lang, get_translation

router = APIRouter(prefix="/api/songs", tags=["songs"])


@router.get("", response_model=SongListResponse)
async def song_list(
    request: Request,
    style: str | None = None,
    difficulty_min: float | None = None,
    difficulty_max: float | None = None,
    keyword: str | None = None,
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
):
    songs, total = await list_songs(
        style=style,
        difficulty_min=difficulty_min,
        difficulty_max=difficulty_max,
        keyword=keyword,
        page=page,
        page_size=page_size,
    )
    return SongListResponse(
        songs=[SongListItem(**s) for s in songs],
        total=total,
        page=page,
        page_size=page_size,
    )


@router.get("/{song_id}")
async def song_detail(song_id: str, request: Request):
    song = await get_song(song_id)
    if not song:
        return {"error": "Song not found"}, 404

    region = await detect_region(request.client.host if request.client else None)

    response_data = SongResponse(
        id=song["id"],
        title=song["title"],
        style=song["style"],
        difficulty=song["difficulty"],
        lyric_json=filter_lyric_json_by_lang(song.get("lyric_json", ""), _get_lang(request)),
        lrc=song.get("lrc"),
        vocal_url=song.get(f"vocal_url_{region}") or None,
        accompaniment_url=song.get(f"accompaniment_url_{region}") or None,
        full_song_url=song.get(f"full_song_url_{region}") or None,
        status=song["status"],
    )
    return response_data


@router.get("/{song_id}/download/{file_type}")
async def song_download(song_id: str, file_type: str, request: Request):
    if file_type not in ("full", "accompaniment", "vocal", "lrc", "lyric"):
        return {"error": "Invalid file type"}, 400

    song = await get_song(song_id)
    if not song:
        return {"error": "Song not found"}, 404

    if file_type in ("lrc", "lyric"):
        if file_type == "lrc":
            content = song.get("lrc", "")
            return {"lrc": content}
        lang = _get_lang(request)
        lyric_json = filter_lyric_json_by_lang(song.get("lyric_json", ""), lang)
        return {"lyric_json": lyric_json}

    region = await detect_region(request.client.host if request.client else None)
    url = generate_download_url(song, file_type, region)

    if not url:
        return {"error": "File not available"}, 404

    return RedirectResponse(url=url)


def _get_lang(request: Request) -> str:
    accept_lang = request.headers.get("accept-language", "en")
    lang = accept_lang.split(",")[0].split("-")[0].strip().lower()
    return lang if lang else "en"
