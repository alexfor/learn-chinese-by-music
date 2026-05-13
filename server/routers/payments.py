from fastapi import APIRouter, Depends, HTTPException

from middleware.auth import get_current_user_id
from models.payment import (
    VerifyPaymentRequest,
    VerifyPaymentResponse,
    SubscriptionResponse,
)
from services.payment_service import (
    process_purchase,
    get_user_subscription,
)

router = APIRouter(prefix="/api/payments", tags=["payments"])


@router.post("/verify", response_model=VerifyPaymentResponse)
async def verify_payment(
    req: VerifyPaymentRequest,
    user_id: str = Depends(get_current_user_id),
):
    try:
        result = await process_purchase(
            user_id=user_id,
            product_id=req.product_id,
            receipt=req.receipt,
            platform=req.platform,
        )
        return VerifyPaymentResponse(**result)
    except (ValueError, NotImplementedError) as e:
        raise HTTPException(status_code=400, detail=str(e))


@router.get("/subscription", response_model=SubscriptionResponse)
async def get_subscription(
    user_id: str = Depends(get_current_user_id),
):
    result = await get_user_subscription(user_id=user_id)
    return SubscriptionResponse(**result)
