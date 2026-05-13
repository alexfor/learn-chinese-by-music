import time
from collections import defaultdict
from collections.abc import Callable

from fastapi import Request, Response
from fastapi.responses import JSONResponse
from starlette.middleware.base import BaseHTTPMiddleware


class RateLimitMiddleware(BaseHTTPMiddleware):
    """Simple in-memory rate limiter: max N requests per window_seconds per client IP."""

    def __init__(self, app, max_requests: int = 60, window_seconds: int = 60):
        super().__init__(app)
        self.max_requests = max_requests
        self.window_seconds = window_seconds
        self._clients: dict[str, list[float]] = defaultdict(list)

    async def dispatch(self, request: Request, call_next: Callable) -> Response:
        # Only rate-limit auth and payment endpoints
        path = request.url.path
        if not (path.startswith("/api/auth/") or path.startswith("/api/payments/")):
            return await call_next(request)

        client_ip = request.client.host if request.client else "unknown"
        now = time.monotonic()
        window_start = now - self.window_seconds

        timestamps = self._clients[client_ip]
        # Prune timestamps outside the window
        self._clients[client_ip] = [t for t in timestamps if t > window_start]

        if len(self._clients[client_ip]) >= self.max_requests:
            return JSONResponse(
                status_code=429,
                content={"detail": "Too many requests. Please try again later."},
            )

        self._clients[client_ip].append(now)
        return await call_next(request)
