from pydantic import BaseModel


class TranslationResponse(BaseModel):
    song_id: str
    lang: str
    content: str
