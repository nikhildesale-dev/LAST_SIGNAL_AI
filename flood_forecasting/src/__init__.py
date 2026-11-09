"""
LAST_SIGNAL_AI: Core Hydrological Time-Series and Forecasting Package
"""

from .sensor_health import SensorHealthMonitor, SensorStatus
from .regime_detection import RegimeDetector, HydrologicalRegime
from .features import FeatureEngineer, FEATURES_SCHEMA
from .forecaster import RiverLevelForecaster

__all__ = [
    "SensorHealthMonitor",
    "SensorStatus",
    "RegimeDetector",
    "HydrologicalRegime",
    "FeatureEngineer",
    "FEATURES_SCHEMA",
    "RiverLevelForecaster"
]

