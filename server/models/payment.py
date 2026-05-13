from pydantic import BaseModel
from typing import Optional


class VerifyPaymentRequest(BaseModel):
    product_id: str  # "monthly_subscription" | "yearly_subscription" | "song_<song_id>"
    receipt: str     # Platform receipt data (mock in dev/test)
    platform: str    # "ios" | "android"


class VerifyPaymentResponse(BaseModel):
    status: str
    subscription: Optional[str] = None
    expires_at: Optional[str] = None


class SubscriptionResponse(BaseModel):
    subscription: str
    expires_at: Optional[str] = None
    purchased_songs: list[str] = []
    has_access: bool = False


class PurchaseHistoryEntry(BaseModel):
    id: str
    user_id: str
    product_id: str
    platform: str
    receipt: str
    created_at: str
