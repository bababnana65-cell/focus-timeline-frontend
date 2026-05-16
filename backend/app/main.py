from fastapi import FastAPI

from .api import router
from .config import settings
from .database import SessionLocal, create_schema
from .services import seed_demo_data

app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    docs_url="/docs",
    redoc_url="/redoc",
)
app.include_router(router)


@app.on_event("startup")
def startup() -> None:
    if settings.auto_create_schema:
        create_schema()
    if settings.seed_demo_data:
        db = SessionLocal()
        try:
            seed_demo_data(db)
        finally:
            db.close()
