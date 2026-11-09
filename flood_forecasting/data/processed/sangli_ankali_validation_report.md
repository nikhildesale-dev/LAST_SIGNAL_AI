# Phase 1 to Phase 5 Comprehensive Validation & Feasibility Report
## Project: LAST_SIGNAL_AI
### Pilot Study: Sangli Rainfall & Ankali Bridge River-Level Telemetry

---

### Executive Summary

As part of the **LAST_SIGNAL_AI** flood risk investigation, this report documents the empirical validation and pilot time-series construction for the **SANGLI** rainfall station and the **Ankali Bridge** river gauging station.

- **Rainfall Station**: `SANGLI` (Sangli District, Maharashtra; Lat: `16.951944`, Lon: `74.605833`)
- **River Station**: `Ankali Bridge` (Sangli District, Krishna Basin; Lat: `16.802778`, Lon: `74.566389`)
- **Reported Geodesic Distance**: `17.11 km`
- **Output Dataset**: [`sangli_ankali_pilot.csv`](file:///c:/Users/pranj/OneDrive/Desktop/LAST_SIGNAL_AI/data/processed/sangli_ankali_pilot.csv) (`21,604` hourly steps, `21` columns)

---

### Phase 1 — Verification of Input Data

#### 1. Input Datasets & Records Loaded
- **Rainfall Source**: [`maharashtra_rainfall_cleaned.csv`](file:///c:/Users/pranj/OneDrive/Desktop/LAST_SIGNAL_AI/maharashtra_rainfall_cleaned.csv)
  - Records matching `Station == 'SANGLI'`: **1,537 rows**
  - Columns: 21 (including `Manual Hourly Rainfall (mm)`, `Data Acquisition Time`, coordinates)
  - Coordinate consistency: 100% constant (`16.951944° N`, `74.605833° E`)
- **River Source**: [`river_water_level_krishna.csv`](file:///c:/Users/pranj/OneDrive/Desktop/LAST_SIGNAL_AI/river_water_level_krishna.csv)
  - Records matching `Station == 'Ankali Bridge'`: **69,993 rows**
  - Columns: 23 (including `River Water Level Telemetry Hourly (meter)`, coordinates)
  - Coordinate consistency: 100% constant (`16.802778° N`, `74.566389° E`)

#### 2. Exact Timestamp Formats & Parsing Integrity
- **Rainfall timestamps**: Stored in ISO format `YYYY-MM-DD HH:MM:SS` (e.g., `2021-01-05 00:30:00`).
  - Parsing rate: **100.0% successful** (0 NaT parse failures out of 1,537).
  - First timestamp: `2021-01-05 00:30:00`
  - Last timestamp: `2024-07-31 17:30:00`
- **River timestamps**: Stored in day-first format `DD-MM-YYYY HH:MM` (e.g., `12-02-2022 14:00`).
  - Parsing rate: **100.0% successful** (0 NaT parse failures out of 69,993).
  - First timestamp: `2022-02-12 14:00:00`
  - Last timestamp: `2024-12-18 17:15:00`

#### 3. Duplicates, Nulls, and Outliers
- **Duplicates**: Exactly **0 duplicate timestamps** and **0 duplicate rows** in both datasets for these stations.
- **Null Values**: Exactly **0 missing/NaN measurement values** in both filtered series.
- **Outliers / Invalid Codes**:
  - Rainfall: All values strictly $\ge 0.1\text{ mm}$ (range: $0.1\text{ mm}$ to $77.0\text{ mm}$, mean: $1.75\text{ mm}$). Exactly 0 negative values.
  - River: Water level ranges from $526.10\text{ m}$ to $546.15\text{ m}$ (mean: $527.73\text{ m}$). Exactly 0 occurrences of sensor fault codes (such as `-99.99`).

#### 4. Observation Intervals
- **River telemetry frequency**:
  - Sampled nominally every **15 minutes** (65,544 steps at $\Delta t = 15\text{ min}$; 3,153 at $30\text{ min}$; 681 at $45\text{ min}$).
  - Expected readings per full day: $24 \times 4 = 96$ observations.
- **Rainfall frequency**:
  - **100% of all 1,537 timestamps occur at the 30th minute of the hour** (`HH:30:00`).
  - Time intervals between successive readings: 918 consecutive hours ($1\text{h}$ apart), 134 at $2\text{h}$, 59 at $3\text{h}$, and larger multi-day gaps during dry weather.

#### 5. Discrepancy Investigation: The "174 Overlap Days" Finding
Earlier reports cited **174 common calendar days** between Sangli rainfall and Ankali Bridge river levels:
1. **Origin of 174 days**: A set intersection of calendar dates where both stations had at least one row in their CSV ($|\text{dates}_{\text{rain}} \cap \text{dates}_{\text{river}}| = 174$).
2. **Calendar span**: The first common date is `2022-04-28` and the last common date is `2024-05-26`, spanning **760 calendar days**.
3. **Summer 2024 Telemetry Dropout**: In 2024, Sangli rainfall recorded active rainfall events throughout July 2024 (`2024-07-01` to `2024-07-31`, 192 records). However, Ankali Bridge river telemetry suffered an **84-day outage from 2024-05-29 to 2024-08-22**. Because river recording ceased throughout June and July 2024, none of July 2024 rain has concurrent river observations.
4. **Reality**: The "174 common days" represents only **sparse rain-event days** when both stations happened to record on that date. It does not represent 174 complete, contiguous days of data.

---

### Phase 2 — Rainfall Data Validation & Zero-Imputation Assessment

#### 1. Why the Rainfall File Contains Only Positive Values
- In [`maharashtra_rainfall_cleaned.csv`](file:///c:/Users/pranj/OneDrive/Desktop/LAST_SIGNAL_AI/maharashtra_rainfall_cleaned.csv), out of all 170,490 records across Maharashtra, **there is not a single 0.0 mm entry** ($\min = 0.01\text{ mm}$).
- The state monitoring agency (*Maharashtra SW*) logs entries **by exception**: a record is posted only when a tipping bucket tips or when a manual gauge accumulates measurable precipitation.
- Station logs confirm that during dry afternoons or dry weeks in winter/pre-monsoon, zero rows were transmitted.

#### 2. Timestamp Semantics
- Because every timestamp is stamped at `HH:30:00` (e.g., `14:30:00`), standard meteorological practice denotes that this reading represents cumulative precipitation over the preceding hourly window (i.e. $13:30$ to $14:30$, floored to hour $14:00$).

#### 3. Legitimate Zero-Filling Justification
- **Verdict**: In a regularized hourly grid, missing timestamps during active station deployment periods **legitimately represent 0.0 mm of rainfall**.
- **Preservation of Indicators**: To maintain data provenance, the pilot dataset retains:
  - `rainfall_event_positive`: binary flag ($1$ if an active rain event was logged, $0$ if absent).
  - `rainfall_measured_mm`: the raw measured value ($\text{NaN}$ when absent).
  - `rainfall_imputed_zero_mm`: the justified meteorological imputation ($0.0\text{ mm}$ when absent).

---

### Phase 3 — River Data Processing & Aggregation

#### 1. Sampling & Daily Completeness
Across the 839 active river days:
- 167 days had complete 96 observations ($100\%$).
- 508 days had $\ge 90$ observations ($>93.7\%$).
- 206 days had between 4 and 79 observations (partial telemetry capture).

#### 2. Aggregation Methodology
Rather than discarding 15-minute granularity or relying on arbitrary linear interpolation across telemetry dropouts:
- Observations were grouped by hourly window (`timestamp = HH:00:00`).
- For each hourly window, we computed:
  - `river_mean`: arithmetic mean of available 15-min telemetry readings ($526.10\text{ m}$ to $546.15\text{ m}$).
  - `river_max`: peak stage in the hour.
  - `river_min`: minimum stage in the hour.
  - `river_count`: number of valid 15-min readings in the hour (1 to 4).
- Gaps longer than 2 hours were **never interpolated**, preventing synthetic artifacts in training targets.

---

### Phase 4 — Pilot Time-Series Dataset Architecture

#### 1. Temporal Resolution Decision: Hourly vs. Daily
- **Decision**: **Hourly resolution** is chosen as the primary pilot architecture.
- **Hydrological Rationale**:
  - The distance between Sangli and Ankali Bridge is $17.11\text{ km}$.
  - In the Krishna River channel near Sangli, typical flood wave celerity ranges between $1.5\text{ m/s}$ and $3.0\text{ m/s}$ ($5.4\text{ km/h}$ to $10.8\text{ km/h}$).
  - The hydraulic travel time for flood pulses from Sangli to Ankali Bridge is approximately **2 to 4 hours**.
  - Daily averaging washes out the kinematic wave arrival peak and instantaneous rainfall burst dynamics.
  - Hourly discretization yields **21,604 time steps**, providing sufficient statistical power for autoregressive models.

#### 2. Features and Schema of [`sangli_ankali_pilot.csv`](file:///c:/Users/pranj/OneDrive/Desktop/LAST_SIGNAL_AI/data/processed/sangli_ankali_pilot.csv)

| Column Name | Type | Description |
| :--- | :--- | :--- |
| `timestamp` | `datetime` | Regularized hourly timestamp (`YYYY-MM-DD HH:00:00`) from 2022-02-12 14:00 to 2024-07-31 17:00 |
| `rainfall_station` | `string` | `SANGLI` |
| `river_station` | `string` | `Ankali Bridge` |
| `station_distance_km` | `float` | `17.11` |
| `river_telemetry_available` | `binary` | 1 if river sensor had readings in this hour, 0 if missing |
| `river_count` | `int` | Number of 15-min readings (1 to 4) |
| `river_mean` | `float` | Hourly mean water level (meters above MSL) |
| `river_max` | `float` | Hourly maximum water level (meters above MSL) |
| `river_min` | `float` | Hourly minimum water level (meters above MSL) |
| `rainfall_event_positive` | `binary` | 1 if rainfall $>0$ was reported in this hour, 0 otherwise |
| `rainfall_measured_mm` | `float` | Raw measured rainfall in mm (NaN if dry) |
| `rainfall_imputed_zero_mm` | `float` | Zero-imputed rainfall (0.0 mm if dry) |
| `rain_intensity_6h` | `float` | Rolling 6-hour mean rainfall intensity (mm/h) |
| `rain_sum_24h` | `float` | Cumulative rainfall over previous 24 hours (Antecedent Precipitation) |
| `rain_sum_48h` | `float` | Cumulative rainfall over previous 48 hours |
| `rain_sum_72h` | `float` | Cumulative rainfall over previous 72 hours |
| `river_lag_1h` | `float` | Autoregressive river level at $t-1\text{ hour}$ |
| `river_lag_6h` | `float` | Autoregressive river level at $t-6\text{ hours}$ |
| `river_lag_24h` | `float` | Autoregressive river level at $t-24\text{ hours}$ |
| `target_river_plus_6h` | `float` | Forecast target: River water level at $t+6\text{ hours}$ |
| `target_river_plus_24h` | `float` | Forecast target: River water level at $t+24\text{ hours}$ |

---

### Phase 5 — Model Feasibility & Statistical Viability

#### 1. Usable Complete Training Samples
- Total hourly grid rows: **21,604**
- Rows with valid river telemetry: **16,385** ($75.8\%$)
- Complete cases for $t+6\text{h}$ forecasting (`river_lag_1h, 6h, 24h`, `rain_sum_24h, 48h, 72h, intensity_6h` and `target_river_plus_6h` all non-null): **15,203 complete samples**.
- Complete cases for $t+24\text{h}$ forecasting: **14,833 complete samples**.

#### 2. Temporal Distribution of Complete Training Cases
- **2022**: 5,515 hourly cases (continuous through late monsoon, winter, and spring)
- **2023**: 7,151 hourly cases (complete monsoon season coverage)
- **2024**: 2,537 hourly cases (Jan to May 2024)

#### 3. Hydrological Correlation Analysis
Correlations with future water level targets provide critical insights into model feasibility:

- **Autoregressive Persistence**:
  - `river_lag_1h` $\to$ `target_river_plus_6h`: $r = +0.973$
  - `river_lag_6h` $\to$ `target_river_plus_6h`: $r = +0.947$
  - `river_lag_24h` $\to$ `target_river_plus_24h`: $r = +0.856$
  River water level is strongly autocorrelated; autoregressive persistence serves as an essential baseline.
- **Precipitation Coupling**:
  - `rain_sum_72h` $\to$ `target_river_plus_6h`: $r = +0.319$
  - `rain_sum_72h` $\to$ `target_river_plus_24h`: $r = +0.342$
  - Multi-day cumulative rainfall exhibits significant positive correlation with river stage rises, confirming that antecedent rainfall carries informative predictive signal over a 24- to 72-hour lag.

#### 4. Proposed Chronological Train / Validation / Test Split
To avoid data leakage in time-series forecasting, random splitting must **never** be used. A strictly chronological split is proposed:
1. **Train Set (2022-02-12 to 2023-06-30)**:
   - Covers 2022 Monsoon and dry season (~9,000 samples).
2. **Validation Set (2023-07-01 to 2023-10-31)**:
   - Covers the intense 2023 Monsoon flood peaks (~2,500 samples).
3. **Test Set (2023-11-01 to 2024-05-29)**:
   - Out-of-sample evaluation period (~3,700 samples).

#### 5. Proposed Baseline Models
- **Baseline 1 (Persistence Baseline)**:
  $\hat{y}_{t+h} = y_t$ (predicts the current river level forward; benchmark to beat).
- **Baseline 2 (Linear / Ridge Regression)**:
  Evaluates linear additive contribution of rainfall lags over autoregressive stage.
- **Baseline 3 (Random Forest Regressor / Gradient Boosting)**:
  Evaluates non-linear stage-discharge thresholds and soil-saturation hysteresis.

---

### Critical Limitations & Recommendations

1. **Absence of Official Flood Warning Thresholds**:
   - The river stage in this dataset ranges between $526\text{ m}$ and $546\text{ m}$ (mean sea level datum).
   - The dataset contains **no official Danger Level or Warning Level metadata** for Ankali Bridge.
   - Therefore, the problem must remain formulated as a **continuous regression problem** (predicting water level in meters). Fabricating arbitrary classification labels (e.g. "flood vs. no flood") without CWC or state gazette thresholds would be scientifically ungrounded.
2. **Upstream Catchment Unmeasured**:
   - Sangli rainfall is only a point measurement $17.11\text{ km}$ from the bridge. The Krishna River upstream catchment at Ankali Bridge exceeds $15,000\text{ km}^2$, draining heavy Western Ghats rainfall (e.g., Mahabaleshwar, Koyna). While local Sangli rain adds useful predictive signal ($r \approx 0.34$), major flood crests are governed by upstream dam releases and catchment-wide rainfall.
3. **Summer 2024 Telemetry Dropout**:
   - Due to the river sensor outage from June to August 2024, the dataset cannot evaluate the 2024 monsoon flood wave. Model evaluation must focus on the 2022 and 2023 seasons.

---

### Final Recommendation

The pilot dataset [`data/processed/sangli_ankali_pilot.csv`](file:///c:/Users/pranj/OneDrive/Desktop/LAST_SIGNAL_AI/data/processed/sangli_ankali_pilot.csv) has been successfully verified, regularized, and engineered with zero data leakage. 

With **15,203 valid training samples** and verified antecedent rainfall correlations ($r \approx 0.34$), **the pilot is ready for baseline model training (Persistence, Linear Regression, Random Forest)** once confirmed.

