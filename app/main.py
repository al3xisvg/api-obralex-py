from fastapi import FastAPI

from app.api.health import router as health_router

app = FastAPI(title="Obralex API", version="1.0.0")

app.include_router(health_router, prefix="/api/v1", tags=["health"])


@app.get("/")
async def root():
    return {"message": "Obralex API"}
