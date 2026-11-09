/**
 * LAST_SIGNAL_AI: API Type Definitions matching FastAPI Pydantic Schemas
 */

export interface HealthResponse {
  status: 'HEALTHY' | 'DEGRADED';
  model_loaded: boolean;
  horizons_hours: number[];
  version: string;
  timestamp: string;
}

export interface ModelInfoResponse {
  service_name: string;
  model_version: string;
  architecture: string;
  target_station: string;
  upstream_stations: string[];
  rainfall_station: string;
  horizons_hours: number[];
  features_schema: string[];
  supported_regimes: string[];
  known_limitations: string[];
}

export interface PredictRequest {
  current_stage_m?: number | null;
  prediction_timestamp: string;
  features: Record<string, number | null>;
  history_stages?: number[] | null;
  history_timestamps?: string[] | null;
  history_shigaon_stages?: number[] | null;
  history_shigaon_timestamps?: string[] | null;
  history_koyna_stages?: number[] | null;
  history_koyna_timestamps?: string[] | null;
  rainfall_measured_mm?: number | null;
}

export interface PredictResponse {
  prediction_available: boolean;
  forecast_plus_6h: number | null;
  forecast_plus_24h: number | null;
  current_river_level_m: number | null;
  hydrological_regime: 'BASEFLOW' | 'SURGE' | 'DEGRADED' | 'DEGRADED_UNUSABLE';
  target_sensor_health: 'HEALTHY' | 'SUSPECT_STALE' | 'STALE' | 'MISSING';
  upstream_sensor_availability: {
    target_gauge?: boolean;
    shigaon_gauge?: boolean;
    koyna_1_gauge?: boolean;
    sangli_rainfall?: boolean;
    [key: string]: boolean | undefined;
  };
  upstream_sensor_health?: {
    shigaon_gauge?: 'HEALTHY' | 'STABLE_BUT_PLAUSIBLE' | 'SUSPECT_FLATLINE' | 'STALE' | 'MISSING';
    koyna_1_gauge?: 'HEALTHY' | 'STABLE_BUT_PLAUSIBLE' | 'SUSPECT_FLATLINE' | 'STALE' | 'MISSING';
    sangli_rainfall?: 'MEASURED_POSITIVE' | 'MEASURED_ZERO' | 'ASSUMED_ZERO' | 'UNRECORDED_MISSING' | string;
    [key: string]: string | undefined;
  };
  fallback_reason: string | null;
  prediction_timestamp: string;
  uncertainty_warning: string | null;
  feature_statuses?: Record<string, string>;
}

export interface TelemetryPoint {
  timestamp: string;
  ankali_stage_m: number | null;
  shigaon_stage_m: number | null;
  koyna_stage_m: number | null;
  rainfall_mm: number | null;
  rainfall_status?: 'MEASURED_POSITIVE' | 'MEASURED_ZERO' | 'ASSUMED_ZERO' | 'UNRECORDED_MISSING' | string;
  ankali_avail: boolean;
  shigaon_avail: boolean;
  koyna_avail: boolean;
  rainfall_avail: boolean;
}

export interface TelemetryHistoryResponse {
  station: string;
  count: number;
  start_time: string;
  end_time: string;
  series: TelemetryPoint[];
}

export interface ScenarioItem {
  id: string;
  name: string;
  description: string;
  category: 'BASEFLOW' | 'SURGE' | 'STALE_FAULT' | 'PLATEAU_WARNING' | 'DROPOUT';
  prediction_timestamp: string;
  current_stage_m: number | null;
  features: Record<string, number | null>;
  history_stages?: number[] | null;
  history_timestamps?: string[] | null;
  history_shigaon_stages?: number[] | null;
  history_shigaon_timestamps?: string[] | null;
  history_koyna_stages?: number[] | null;
  history_koyna_timestamps?: string[] | null;
  rainfall_measured_mm?: number | null;
}

export interface ScenariosResponse {
  scenarios: ScenarioItem[];
}

export interface CsvStationStats {
  station_name: string;
  unit: string;
  total_records: number;
  valid_count: number;
  missing_count: number;
  missing_pct: number;
  min_val: number | null;
  max_val: number | null;
}

export interface CsvValidationResponse {
  is_valid: boolean;
  filename: string;
  total_rows: number;
  start_timestamp: string | null;
  end_timestamp: string | null;
  duplicate_timestamps_count: number;
  validation_errors: string[];
  validation_warnings: string[];
  station_stats: Record<string, CsvStationStats>;
  rainfall_status_counts: Record<string, number>;
  available_timestamps: string[];
  timestamps_with_sufficient_history: string[];
}

export interface CsvPredictResponse extends PredictResponse {
  filename: string;
  selected_timestamp: string;
  telemetry_series: TelemetryPoint[];
  features_engineered: Record<string, number | null>;
}


