from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from database import init_db
from config import settings
from middleware.rate_limit import RateLimitMiddleware
from routers import songs, admin, auth, users, progress, leaderboard, contest, community, payments, gamification


@asynccontextmanager
async def lifespan(app: FastAPI):
    if not settings.debug and settings.secret_key == "change-me-in-production":
        raise RuntimeError(
            "SECURITY: Must set APP_SECRET_KEY in .env for production. "
            "The default secret_key is not safe."
        )
    await init_db()
    yield


app = FastAPI(
    title="Learn Chinese by Music",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if settings.debug else [],
    allow_credentials=settings.debug,
    allow_methods=["*"] if settings.debug else ["GET", "POST", "PUT", "DELETE", "PATCH"],
    allow_headers=["*"] if settings.debug else ["Authorization", "Content-Type"],
)

app.add_middleware(RateLimitMiddleware, max_requests=60, window_seconds=60)

app.include_router(songs.router)
app.include_router(admin.router)
app.include_router(auth.router)
app.include_router(users.router)
app.include_router(progress.router)
app.include_router(leaderboard.router)
app.include_router(contest.router)
app.include_router(community.router)
app.include_router(payments.router)
app.include_router(gamification.router)


@app.get("/health")
async def health():
    return {"status": "ok"}
