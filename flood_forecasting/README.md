# LAST_SIGNAL_AI: Multi-Station Hydrological Forecasting Service

**LAST_SIGNAL_AI** is a modular, production-ready machine learning service designed for short-term and medium-term river stage forecasting in the Krishna River Basin at the **Ankali Bridge** gauging station (Maharashtra, India).

The system integrates multi-station upstream telemetry (Warna River at Shigaon and Koyna Reservoir at Koyna_1) and regional rainfall data (Sangli) with an operational **Gated Dual-Regime Forecaster (V2)** and real-time **Target Sensor Health Hardening**.

---

## Architecture & Data Flow

```
                      +-------------------------------------------------------------+
                      |               Incoming Telemetry Observations               |
                      |   - Target: Ankali Bridge stage (m) & timestamp             |
                      |   - Upstream River: Shigaon deltas (1h, 3h, 6h, 24h)        |
                      |   - Reservoir: Koyna_1 deltas (1h, 3h, 6h, 24h)             |
                      |   - Rainfall: Sangli cumulative sums (24h, 48h, 72h, 6h)    |
                      +-------------------------------------------------------------+
                                                     |
                                                     v
                      +-------------------------------------------------------------+
                      |         Target Sensor Health Monitor (Ankali Bridge)        |
                      |  - Telemetry Latency Check: gap > 3h  --> STALE             |
                      |  - Invariant Flatline Check: >= 24h & std = 0 --> STALE     |
                      |  - Low Variability Plateau: >= 12h identical --> SUSPECT    |
                      |  - Null / Missing Current Stage       --> MISSING           |
                      +-------------------------------------------------------------+
                                    |                                 |
                        [STALE / MISSING / FLATLINE]        [HEALTHY / SUSPECT_STALE]
                                    |                                 |
                                    v                                 v
                      +---------------------------+     +---------------------------+
                      | Forecast Safely Withheld  |     | Regime Detection Engine   |
                      | - prediction_available:   |     | - Surge Trigger (slope)   |
                      |   false                   |     | - Upstream Warna Pulse    |
                      | - forecast_6h: null       |     | - 24h Hysteresis Hold     |
                      | - forecast_24h: null      |     +---------------------------+
                      | - fallback_reason: STALE  |               /       \
                      +---------------------------+     [BASEFLOW]         [SURGE]
                                                           /                 \
                                                          v                   v
                                             +--------------------+   +--------------------+
                                             | Persistence Engine |   | Multi-Station      |
                                             | y_pred(t+h) = y(t) |   | Ridge Pipeline     |
                                             | Minimizes variance |   | StandardScaler +   |
                                             | in dry baseflow    |   | Ridge Regression   |
                                             +--------------------+   +--------------------+
                                                          \                   /
                                                           \                 /
                                                            v               v
                                             +---------------------------------------------+
                                             |          FastAPI PredictResponse            |
                                             | - forecast_plus_6h (m)                      |
                                             | - forecast_plus_24h (m)                     |
                                             | - hydrological_regime                       |
                                             | - target_sensor_health                      |
                                             | - upstream_sensor_availability              |
                                             | - uncertainty_warning                       |
                                             +---------------------------------------------+
```

---

## Key Features

1. **Dual-Regime Hydrological Dispatching**:
   - **Baseflow Regime**: Quiescent dry periods and slow recessions are routed directly to persistence forecasting ($\hat{y}_{t+h} = y_t$). This eliminates the variance inflation and drift exhibited by linear regression during flat periods.
   - **Surge Regime**: Rapid rising limbs, upstream dam pulses, or intense precipitation events trigger the multi-station Ridge Regression pipeline, capturing non-local hydraulic wave propagation from the upstream Warna and Koyna catchments.
   - **Timestamp-Based Hysteresis**: Once a surge is triggered, the system enforces a 24-hour minimum hold time to prevent high-frequency regime oscillation during transient peak plateaus.

2. **Sensor-Failure Hardening**:
   - Automated detection of sensor latency gaps ($>3$ hours) and frozen/stuck float stages ($\ge 24$ consecutive identical readings with zero variance).
   - If the target sensor is compromised, **numerical forecasts are strictly withheld** (`null`), preventing misleading predictions while issuing structured operational warnings.
   - Degraded upstream sensors are tracked and flagged in telemetry health checks without blocking local persistence fallback.

3. **Production FastAPI Service**:
   - RESTful endpoints (`/health`, `/model-info`, `/predict`, `/telemetry/history`, `/telemetry/scenarios`) with full Pydantic V2 schema validation.
   - Fully asynchronous, stateless, and container-friendly.
   - Self-documenting OpenAPI (Swagger UI) interface.

4. **Interactive River Monitoring & Forecasting Dashboard**:
   - Responsive web interface built with **React**, **Vite**, **Tailwind CSS**, and **Recharts**.
   - Real-time KPI cards for latest river level, +6h forecast, +24h forecast, and active regime.
   - Interactive stage visualization with un-interpolated missing data gaps and distinct model projection horizons.
   - Upstream trend monitoring for Warna River at Shigaon, Koyna Reservoir, and Sangli precipitation.
   - One-click historical episode replay (Baseflow, Surge, Stale Sensor Flatline, Plateau, Upstream Outage).

---

## Directory Layout

```
LAST_SIGNAL_AI/
├── api/                        # FastAPI REST API service
│   ├── __init__.py
│   ├── main.py                 # Application factory & lifespan manager
│   ├── routes.py               # REST route handlers (/health, /model-info, /predict, /telemetry/*)
│   └── schemas.py              # Pydantic V2 request & response models
├── frontend/                   # Interactive React + Vite + Tailwind CSS Dashboard
│   ├── src/
│   │   ├── components/         # Modular UI components (Header, Charts, Health, Details)
│   │   ├── services/           # Typed API fetch client
│   │   ├── types/              # TypeScript definitions matching Pydantic schemas
│   │   ├── App.tsx             # Main dashboard view & scenario coordinator
│   │   └── main.tsx            # React application entrypoint
│   ├── package.json
│   ├── vite.config.ts          # Vite configuration with API reverse proxy
│   └── tailwind.config.js
├── src/                        # Modular hydrological forecasting package
│   ├── __init__.py             # Clean namespace export
│   ├── data_loader.py          # Data ingestion and station filtering
│   ├── features.py             # Feature engineering & schema validation
│   ├── forecaster.py           # Core RiverLevelForecaster V2 engine
│   ├── regime_detection.py     # Dual-regime detector & hysteresis state
│   └── sensor_health.py        # Telemetry latency & flatline health monitor
├── models/                     # Serialized pre-trained model pipelines
│   ├── multistation/           # Production Config C Ridge models (+6h, +24h) and benchmarks
│   ├── gated_forecaster/       # Regime configuration parameters & prototype implementations
│   └── sangli_ankali_*.joblib  # Baseline single-station pilot models
├── data/                       # Structured hydrological datasets
│   ├── raw/                    # Immutable original telemetry (river levels, rainfall)
│   ├── cleaned/                # Preprocessed hourly telemetry datasets
│   ├── processed/              # Unified multi-station and pilot time series
│   ├── indofloods/             # National IndoFloods benchmark datasets
│   └── audit_intermediates/    # Intermediate station matching & overlap calculations
├── scripts/                    # Research & quality assurance scripts
│   └── data_audit/             # 23 exploratory data audit & telemetry gap scripts
├── tests/                      # Pytest operational verification suite
│   ├── test_api.py             # 13-scenario unit & model tests
│   └── test_dashboard_integration.py # 7-scenario dashboard contract tests
├── results/                    # Validation, audit, manifests, and benchmark reports
├── preprocess_data.py          # Active reproducible data cleaning pipeline
├── requirements.txt            # Python dependencies
└── README.md                   # System documentation & deployment guide
```

---

## Installation & Setup

### 1. Prerequisites
- Python 3.10, 3.11, 3.12, or 3.13
- Node.js >= 18.0.0 and npm
- Git

### 2. Python Backend Setup

```bash
git clone <repo-url> LAST_SIGNAL_AI
cd LAST_SIGNAL_AI

python -m venv venv
# On Windows:
venv\Scripts\activate
# On Linux/macOS:
source venv/bin/activate

pip install -r requirements.txt
```

### 3. Frontend Dashboard Setup

```bash
cd frontend
npm install
cd ..
```

---

## Starting the Application

### 1. Start the FastAPI Backend

From the project root:

```bash
uvicorn api.main:app --host 127.0.0.1 --port 8000 --reload
```

The API service runs on `http://127.0.0.1:8000`.
- **Interactive OpenAPI Docs**: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
- **ReDoc**: [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc)

### 2. Start the Frontend Dashboard

In a separate terminal window:

```bash
cd frontend
npm run dev
```

Navigate to **`http://localhost:5173`** in your browser. The Vite development server proxies API requests directly to the FastAPI backend.

To build the dashboard for static production hosting:
```bash
cd frontend
npm run build
```
The optimized bundle is generated in `frontend/dist/`.
git clone <repo-url> LAST_SIGNAL_AI
cd LAST_SIGNAL_AI

python -m venv venv
# On Windows:
venv\Scripts\activate
# On Linux/macOS:
source venv/bin/activate
```

### 3. Install Dependencies

```bash
pip install -r requirements.txt
```

---

## Running the API Service

### Local Development Server

Run the service using Uvicorn:

```bash
uvicorn api.main:app --host 127.0.0.1 --port 8000 --reload
```

The service will output startup logs confirming model availability:
```
[Startup] Forecaster V2 ready. Loaded horizons: [6, 24]
INFO:     Uvicorn running on http://127.0.0.1:8000 (Press CTRL+C to quit)
```

### Interactive API Documentation

Once running, navigate to:
- **Swagger UI**: [http://127.0.0.1:8000/docs](http://127.0.0.1:8000/docs)
- **ReDoc**: [http://127.0.0.1:8000/redoc](http://127.0.0.1:8000/redoc)

---

## Running Tests

Execute the complete 12-scenario operational test suite:

```bash
pytest tests/test_api.py -v
```

This verifies:
- Service health & model metadata introspection
- Baseflow and Surge routing
- Telemetry dropouts (rainfall, Shigaon, Koyna_1)
- Sensor latency exceeding 3 hours
- Frozen stage flatlines ($\ge 24$ hours)
- Low-variability warnings (SUSPECT_STALE)
- 24-hour hysteresis state hold
- Exact 15-feature schema vector ordering

---

## API Endpoint Reference

### 1. Health Check: `GET /health`

Returns service health, version, and model initialization state.

**Request:**
```bash
curl -X GET "http://127.0.0.1:8000/health"
```

**Response (HTTP 200):**
```json
{
  "status": "HEALTHY",
  "model_loaded": true,
  "horizons_hours": [6, 24],
  "version": "2.0.0",
  "timestamp": "2026-10-30T07:15:00.000000+00:00"
}
```

---

### 2. Model Metadata: `GET /model-info`

Returns architecture details, target station, upstream station mappings, required feature schema, and documented limitations.

**Request:**
```bash
curl -X GET "http://127.0.0.1:8000/model-info"
```

**Response (HTTP 200):**
```json
{
  "service_name": "LAST_SIGNAL_AI River-Level Forecasting Service",
  "model_version": "2.0.0-hardened",
  "architecture": "Gated Dual-Regime Forecaster (Persistence for Baseflow, Multi-Station Ridge for Surge)",
  "target_station": "Ankali Bridge (Krishna River Basin)",
  "upstream_stations": [
    "Shigaon (Warna River)",
    "Koyna_1 (Koyna Dam Reservoir)"
  ],
  "rainfall_station": "SANGLI (Maharashtra Rainfall Network)",
  "horizons_hours": [6, 24],
  "features_schema": [
    "rain_sum_24h",
    "rain_sum_48h",
    "rain_sum_72h",
    "rain_intensity_6h",
    "river_lag_1h",
    "river_lag_6h",
    "river_lag_24h",
    "shigaon_delta_1h",
    "shigaon_delta_3h",
    "shigaon_delta_6h",
    "shigaon_delta_24h",
    "koyna_delta_1h",
    "koyna_delta_3h",
    "koyna_delta_6h",
    "koyna_delta_24h"
  ],
  "supported_regimes": [
    "BASEFLOW",
    "SURGE",
    "DEGRADED",
    "DEGRADED_UNUSABLE"
  ],
  "known_limitations": [
    "Predicts continuous water stage (meters), not verified flood disaster occurrence or levee overtopping.",
    "Shows lag-following characteristics during abrupt non-monitored releases or sudden flash events.",
    "Target sensor failure withholds numerical forecasts to avoid transmitting misleading stage levels.",
    "Does not account for downstream backwater effects from Almatti Dam reservoir operations.",
    "Rainfall telemetry assumes zero-imputation during non-reporting dry periods based on IMD network standard."
  ]
}
```

---

### 3. Forecast Endpoint: `POST /predict`

#### Scenario A: Baseflow Condition (Persistence Dispatch)

**Request:**
```bash
curl -X POST "http://127.0.0.1:8000/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "current_stage_m": 527.20,
    "prediction_timestamp": "2023-08-01T12:00:00",
    "features": {
      "rain_sum_24h": 0.0,
      "rain_sum_48h": 0.0,
      "rain_sum_72h": 0.0,
      "rain_intensity_6h": 0.0,
      "river_lag_1h": 527.20,
      "river_lag_6h": 527.18,
      "river_lag_24h": 527.15,
      "shigaon_delta_1h": 0.00,
      "shigaon_delta_3h": 0.00,
      "shigaon_delta_6h": 0.00,
      "shigaon_delta_24h": 0.00,
      "koyna_delta_1h": -0.02,
      "koyna_delta_3h": -0.04,
      "koyna_delta_6h": -0.06,
      "koyna_delta_24h": -0.10
    },
    "history_stages": [527.15, 527.18, 527.20],
    "history_timestamps": ["2023-08-01T10:00:00", "2023-08-01T11:00:00"]
  }'
```

**Response (HTTP 200):**
```json
{
  "target_station": "Ankali Bridge",
  "prediction_timestamp": "2023-08-01T12:00:00",
  "current_stage_m": 527.2,
  "forecast_plus_6h": 527.2,
  "forecast_plus_24h": 527.2,
  "prediction_available": true,
  "hydrological_regime": "BASEFLOW",
  "target_sensor_health": "HEALTHY",
  "upstream_sensor_availability": {
    "target_gauge": true,
    "shigaon_gauge": true,
    "koyna_1_gauge": true,
    "sangli_rainfall": true
  },
  "uncertainty_warning": "NOMINAL_BASEFLOW_PERSISTENCE",
  "fallback_reason": null
}
```

---

#### Scenario B: Surge Condition (Multi-Station Ridge Dispatch)

When upstream Warna River at Shigaon experiences a rapid rise (`shigaon_delta_6h` $> 0.08$ m), the system switches to the multi-station ML pipeline:

**Request:**
```bash
curl -X POST "http://127.0.0.1:8000/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "current_stage_m": 527.20,
    "prediction_timestamp": "2023-07-25T12:00:00",
    "features": {
      "rain_sum_24h": 45.0,
      "rain_sum_48h": 82.0,
      "rain_sum_72h": 110.0,
      "rain_intensity_6h": 12.5,
      "river_lag_1h": 527.15,
      "river_lag_6h": 526.90,
      "river_lag_24h": 526.40,
      "shigaon_delta_1h": 0.12,
      "shigaon_delta_3h": 0.28,
      "shigaon_delta_6h": 0.35,
      "shigaon_delta_24h": 0.60,
      "koyna_delta_1h": 0.05,
      "koyna_delta_3h": 0.15,
      "koyna_delta_6h": 0.25,
      "koyna_delta_24h": 0.40
    },
    "history_stages": [526.90, 527.15, 527.20],
    "history_timestamps": ["2023-07-25T10:00:00", "2023-07-25T11:00:00"]
  }'
```

**Response (HTTP 200):**
```json
{
  "target_station": "Ankali Bridge",
  "prediction_timestamp": "2023-07-25T12:00:00",
  "current_stage_m": 527.2,
  "forecast_plus_6h": 527.42,
  "forecast_plus_24h": 528.09,
  "prediction_available": true,
  "hydrological_regime": "SURGE",
  "target_sensor_health": "HEALTHY",
  "upstream_sensor_availability": {
    "target_gauge": true,
    "shigaon_gauge": true,
    "koyna_1_gauge": true,
    "sangli_rainfall": true
  },
  "uncertainty_warning": "NOMINAL_SURGE_RIDGE",
  "fallback_reason": null
}
```

---

#### Scenario C: Frozen / Compromised Sensor (Numerical Forecast Withheld)

When the Ankali Bridge sensor flatlines for $\ge 24$ hours with zero variance:

**Request:**
```bash
curl -X POST "http://127.0.0.1:8000/predict" \
  -H "Content-Type: application/json" \
  -d '{
    "current_stage_m": 526.65,
    "prediction_timestamp": "2023-02-10T12:00:00",
    "features": {
      "rain_sum_24h": 0.0,
      "rain_sum_48h": 0.0,
      "rain_sum_72h": 0.0,
      "rain_intensity_6h": 0.0,
      "river_lag_1h": 526.65,
      "river_lag_6h": 526.65,
      "river_lag_24h": 526.65,
      "shigaon_delta_1h": 0.0,
      "shigaon_delta_3h": 0.0,
      "shigaon_delta_6h": 0.0,
      "shigaon_delta_24h": 0.0,
      "koyna_delta_1h": 0.0,
      "koyna_delta_3h": 0.0,
      "koyna_delta_6h": 0.0,
      "koyna_delta_24h": 0.0
    },
    "history_stages": [526.65, 526.65, 526.65, 526.65, 526.65, 526.65, 526.65, 526.65, 526.65, 526.65, 526.65, 526.65, 526.65, 526.65, 526.65, 526.65, 526.65, 526.65, 526.65, 526.65, 526.65, 526.65, 526.65, 526.65, 526.65],
    "history_timestamps": ["2023-02-10T11:00:00"]
  }'
```

**Response (HTTP 200):**
```json
{
  "target_station": "Ankali Bridge",
  "prediction_timestamp": "2023-02-10T12:00:00",
  "current_stage_m": 526.65,
  "forecast_plus_6h": null,
  "forecast_plus_24h": null,
  "prediction_available": false,
  "hydrological_regime": "DEGRADED_UNUSABLE",
  "target_sensor_health": "STALE",
  "upstream_sensor_availability": {
    "target_gauge": false,
    "shigaon_gauge": true,
    "koyna_1_gauge": true,
    "sangli_rainfall": true
  },
  "uncertainty_warning": "TARGET_SENSOR_STALE_OR_FLATLINE",
  "fallback_reason": "Target gauge sensor flatlined for >= 24 consecutive hours. Stage forecast safely withheld to prevent transmission of erroneous level."
}
```

---

## Operational Boundaries & Hydrological Limitations

> [!CAUTION]
> **Operational Disclaimer**:
> This service models continuous river stage levels (in meters above datum) at the Ankali Bridge monitoring site. It is an algorithmic empirical model, **NOT an official emergency evacuation alert or certified flood disaster warning system**.

1. **Continuous Stage vs. Flood Disaster Inundation**:
   The service outputs numeric forecasts for river water levels $\hat{y}_{t+h}$. It does not calculate levee overtopping, floodplain hydrodynamic inundation, or civic infrastructure breaches. Official alerts are the sole prerogative of the Central Water Commission (CWC) and Maharashtra State Disaster Management Authority (SDMA).

2. **Lag-Following Behavior**:
   During unannounced sudden reservoir releases or hyper-localized cloudbursts outside monitored catchments, statistical and linear models inherently exhibit lag-following characteristics. Forecasters must monitor raw telemetry alongside model outputs.

3. **Sensor-Failure Withholding Policy**:
   If the target sensor exhibits latency gaps exceeding 3 hours or flatlines for $\ge 24$ consecutive readings, numerical predictions are strictly withheld. This intentional safety feature prevents the dissemination of phantom water levels.

4. **Downstream Hydraulic Backwater Effects**:
   Ankali Bridge is situated upstream of the Almatti Dam (Karnataka). During peak monsoon backwater conditions, downstream impoundments can elevate local river levels independently of upstream catchment runoff. The current model configuration does not ingest Almatti stage/discharge telemetry.

5. **Rainfall Zero-Imputation Semantics**:
   The India Meteorological Department (IMD) / state telemetry network records positive rainfall when precipitation occurs and often omits zero reports during dry intervals. The model treats non-reported precipitation intervals as 0.0 mm/hr, consistent with regional dry-spell reporting mechanisms.

---

## License & Credits

Developed under the **LAST_SIGNAL_AI** project initiative for Krishna River Basin hydrological modeling. All model weights and pipeline configurations are reproducible via the archived audit datasets in `data/processed/`.

