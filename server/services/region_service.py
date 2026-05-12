import httpx


async def detect_region(ip: str | None) -> str:
    """Detect if user is in China or overseas. Returns 'cn' or 'global'."""
    if not ip or ip in ("127.0.0.1", "::1", "localhost"):
        return "cn"

    # Check common China IP patterns or use a geo-IP service
    try:
        async with httpx.AsyncClient(timeout=3.0) as client:
            resp = await client.get(f"http://ip-api.com/json/{ip}")
            if resp.status_code == 200:
                data = resp.json()
                if data.get("countryCode") == "CN":
                    return "cn"
    except Exception:
        pass

    return "global"
