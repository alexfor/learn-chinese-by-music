from datetime import datetime, timedelta, timezone

from database import get_db
from config import settings


def _generate_id() -> str:
    import uuid
    return str(uuid.uuid4())


def _is_mock_receipt(receipt: str) -> bool:
    return receipt.startswith("mock-receipt-")


async def verify_receipt(product_id: str, receipt: str, platform: str) -> dict:
    """
    Verify a purchase receipt.

    In production, this would validate the platform receipt (App Store / Google Play).
    In dev/test, mock receipts starting with 'mock-receipt-' are accepted
    only when settings.debug is True.
    """
    if not settings.debug or not _is_mock_receipt(receipt):
        raise NotImplementedError(
            "Production receipt validation not implemented. "
            "Set APP_DEBUG=true and use mock-receipt- prefix for testing."
        )

    if product_id == "monthly_subscription":
        expires_at = (datetime.now(timezone.utc) + timedelta(days=30)).isoformat()
        return {"subscription": "premium", "expires_at": expires_at,
                "duration_days": 30}

    if product_id == "yearly_subscription":
        expires_at = (datetime.now(timezone.utc) + timedelta(days=365)).isoformat()
        return {"subscription": "premium", "expires_at": expires_at,
                "duration_days": 365}

    if product_id.startswith("song_"):
        song_id = product_id[5:]
        return {"subscription": None, "expires_at": None,
                "song_id": song_id}

    raise ValueError("Unknown product_id")


async def process_purchase(user_id: str, product_id: str, receipt: str,
                           platform: str) -> dict:
    """Verify and process a purchase, updating the user's subscription or purchased songs."""
    result = await verify_receipt(product_id, receipt, platform)

    db = await get_db()
    try:
        # Dedup: reject already-used receipt
        existing = await db.execute_fetchall(
            "SELECT id FROM purchase_history WHERE receipt = ? AND user_id = ?",
            (receipt, user_id),
        )
        if existing:
            raise ValueError("Receipt already used")

        purchase_id = _generate_id()
        await db.execute(
            """INSERT INTO purchase_history (id, user_id, product_id, platform, receipt, created_at)
               VALUES (?, ?, ?, ?, ?, datetime('now'))""",
            (purchase_id, user_id, product_id, platform, receipt),
        )
        await db.commit()

        if result.get("subscription") == "premium":
            await db.execute(
                """UPDATE users
                   SET subscription = 'premium',
                       subscription_expires_at = ?
                   WHERE id = ?""",
                (result["expires_at"], user_id),
            )
            await db.commit()
            return {"status": "ok", "subscription": "premium",
                    "expires_at": result["expires_at"]}

        if "song_id" in result:
            song_id = result["song_id"]
            # Atomic insert via UNIQUE constraint on user_purchased_songs
            await db.execute(
                "INSERT OR IGNORE INTO user_purchased_songs (user_id, song_id) VALUES (?, ?)",
                (user_id, song_id),
            )
            await db.commit()
            return {"status": "ok", "subscription": None, "expires_at": None}

        return {"status": "ok"}
    finally:
        await db.close()


def _parse_expiry(expires_at: str | None) -> datetime | None:
    """Parse ISO datetime string, handling 'Z' suffix (Python 3.10 compat)."""
    if not expires_at:
        return None
    try:
        return datetime.fromisoformat(expires_at.replace("Z", "+00:00"))
    except (ValueError, TypeError):
        return None


async def get_user_subscription(user_id: str) -> dict:
    """Get the current subscription status for a user."""
    db = await get_db()
    try:
        row = await db.execute_fetchall(
            "SELECT subscription, subscription_expires_at FROM users WHERE id = ?",
            (user_id,),
        )
        if not row:
            return {"subscription": "free", "expires_at": None,
                    "purchased_songs": [], "has_access": False}

        subscription = row[0]["subscription"] or "free"
        expires_at = row[0]["subscription_expires_at"]

        # Read purchased songs from dedicated table
        purchased_rows = await db.execute_fetchall(
            "SELECT song_id FROM user_purchased_songs WHERE user_id = ? ORDER BY purchased_at ASC",
            (user_id,),
        )
        purchased_songs = [r["song_id"] for r in purchased_rows]

        has_access = False
        if subscription == "premium" and expires_at:
            exp = _parse_expiry(expires_at)
            has_access = exp is not None and exp > datetime.now(timezone.utc)

        return {
            "subscription": subscription,
            "expires_at": expires_at,
            "purchased_songs": purchased_songs,
            "has_access": has_access,
        }
    finally:
        await db.close()
