from pydantic import BaseModel, Field
from typing import Optional
from enum import Enum


class SongStyle(str, Enum):
    pop = "pop"
    folk = "folk"
    gufeng = "gufeng"
    children = "children"


class SongStatus(str, Enum):
    draft = "draft"
    published = "published"
    archived = "archived"


class SongCreate(BaseModel):
    id: Optional[str] = None
    title: str
    style: SongStyle
    difficulty: float = Field(ge=1.0, le=10.0)
    lyric_json: Optional[str] = None
    lrc: Optional[str] = None
    vocal_url_cn: Optional[str] = None
    vocal_url_global: Optional[str] = None
    accompaniment_url_cn: Optional[str] = None
    accompaniment_url_global: Optional[str] = None
    full_song_url_cn: Optional[str] = None
    full_song_url_global: Optional[str] = None


class SongUpdate(BaseModel):
    title: Optional[str] = None
    style: Optional[SongStyle] = None
    difficulty: Optional[float] = Field(default=None, ge=1.0, le=10.0)
    lyric_json: Optional[str] = None
    lrc: Optional[str] = None
    vocal_url_cn: Optional[str] = None
    vocal_url_global: Optional[str] = None
    accompaniment_url_cn: Optional[str] = None
    accompaniment_url_global: Optional[str] = None
    full_song_url_cn: Optional[str] = None
    full_song_url_global: Optional[str] = None
    status: Optional[SongStatus] = None


class SongListItem(BaseModel):
    id: str
    title: str
    style: str
    difficulty: float
    status: str


class SongResponse(BaseModel):
    id: str
    title: str
    style: str
    difficulty: float
    lyric_json: Optional[str] = None
    lrc: Optional[str] = None
    vocal_url: Optional[str] = None
    accompaniment_url: Optional[str] = None
    full_song_url: Optional[str] = None
    status: str


class SongListResponse(BaseModel):
    songs: list[SongListItem]
    total: int
    page: int
    page_size: int
