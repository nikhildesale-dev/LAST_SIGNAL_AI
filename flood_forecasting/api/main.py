"""
LAST_SIGNAL_AI: FastAPI Main Application Factory
"""

import os
import sys
from contextlib import asynccontextmanager
import pandas as pd
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# Ensure repo root is in python path
repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if repo_root not in sys.path:
    sys.path.insert(0, repo_root)

from src.forecaster import RiverLevelForecaster
from api.routes import router


def load_pilot_dataset() -> pd.DataFrame:
    """Load verified multi-station pilot dataset for telemetry history inspection."""
    pilot_csv = os.path.join(repo_root, "data", "processed", "multistation_upstream_pilot.csv")
    if os.path.exists(pilot_csv):
        return pd.read_csv(pilot_csv)
    return pd.DataFrame()


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Lifespan context manager: loads pre-trained forecaster pipelines on startup.
    """
    if getattr(app.state, "forecaster", None) is None:
        print("[Startup] Initializing RiverLevelForecaster V2...")
        app.state.forecaster = RiverLevelForecaster()
    if getattr(app.state, "pilot_data", None) is None:
        app.state.pilot_data = load_pilot_dataset()
    print(f"[Startup] Forecaster V2 ready. Loaded horizons: {list(app.state.forecaster.models.keys())}")
    yield
    print("[Shutdown] Cleaning up forecaster state.")


def create_app() -> FastAPI:
    """
    Create and configure the FastAPI application.
    """
    app = FastAPI(
        title="LAST_SIGNAL_AI River-Level Forecasting Service",
        version="2.0.0",
        description=(
            "Operational API for multi-station hydrological forecasting at Ankali Bridge (Krishna River Basin). "
            "Features dual-regime dispatch (Persistence for Baseflow, Multi-Station Ridge for Surge) "
            "and automated target-sensor health validation."
        ),
        lifespan=lifespan
    )

    # Eagerly initialize forecaster and pilot data in application state for direct access and testing
    app.state.forecaster = RiverLevelForecaster()
    app.state.pilot_data = load_pilot_dataset()

    # Enable CORS for local and remote dashboard access
    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Include route endpoints
    app.include_router(router, prefix="/api/v1")
    app.include_router(router, prefix="") # Also mount at root for convenient direct access

    return app


app = create_app()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("api.main:app", host="127.0.0.1", port=8000, reload=True)

