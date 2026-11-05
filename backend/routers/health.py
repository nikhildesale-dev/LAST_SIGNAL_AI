"""routers/health.py — GET /api/health"""

from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix="/api", tags=["health"])


class HealthResponse(BaseModel):
    status: str
    message: str
    version: str


@router.get("/health", response_model=HealthResponse)
def health_check():
    """
    Called by Flutter ApiService.checkBackendHealth().
    Returns 200 so the app knows the backend is reachable.
    """
    return HealthResponse(
        status="ok",
        message="LAST SIGNAL AI backend is operational.",
        version="1.0.0",
    )
