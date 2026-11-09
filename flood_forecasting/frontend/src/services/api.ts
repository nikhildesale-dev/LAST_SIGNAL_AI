import type {
  HealthResponse,
  ModelInfoResponse,
  PredictRequest,
  PredictResponse,
  ScenariosResponse,
  TelemetryHistoryResponse,
  CsvValidationResponse,
  CsvPredictResponse,
} from '../types/api';

const API_BASE = import.meta.env.VITE_API_BASE_URL || '';

export const CSV_BLANK_TEMPLATE_URL = `${API_BASE}/csv/templates/blank`;
export const CSV_SAMPLE_TEMPLATE_URL = `${API_BASE}/csv/templates/sample`;

export async function fetchHealth(): Promise<HealthResponse> {
  const resp = await fetch(`${API_BASE}/health`);
  if (!resp.ok) {
    throw new Error(`Health check failed: HTTP ${resp.status}`);
  }
  return resp.json();
}

export async function fetchModelInfo(): Promise<ModelInfoResponse> {
  const resp = await fetch(`${API_BASE}/model-info`);
  if (!resp.ok) {
    throw new Error(`Model info check failed: HTTP ${resp.status}`);
  }
  return resp.json();
}

export async function fetchScenarios(): Promise<ScenariosResponse> {
  const resp = await fetch(`${API_BASE}/telemetry/scenarios`);
  if (!resp.ok) {
    throw new Error(`Failed to load historical episodes: HTTP ${resp.status}`);
  }
  return resp.json();
}

export async function fetchTelemetryHistory(
  scenarioId?: string,
  limit: number = 96
): Promise<TelemetryHistoryResponse> {
  const params = new URLSearchParams();
  if (scenarioId) params.append('scenario_id', scenarioId);
  params.append('limit', limit.toString());

  const resp = await fetch(`${API_BASE}/telemetry/history?${params.toString()}`);
  if (!resp.ok) {
    throw new Error(`Failed to load telemetry history: HTTP ${resp.status}`);
  }
  return resp.json();
}

export async function executeForecast(payload: PredictRequest): Promise<PredictResponse> {
  const resp = await fetch(`${API_BASE}/predict`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  if (!resp.ok) {
    const errorBody = await resp.json().catch(() => ({ detail: 'Unknown network error' }));
    throw new Error(errorBody.detail || `Prediction error: HTTP ${resp.status}`);
  }
  return resp.json();
}

export async function validateCsvFile(file: File): Promise<CsvValidationResponse> {
  const formData = new FormData();
  formData.append('file', file);

  try {
    const resp = await fetch(`${API_BASE}/csv/validate`, {
      method: 'POST',
      body: formData,
    });

    if (!resp.ok) {
      const errorBody = await resp.json().catch(() => ({ detail: `HTTP ${resp.status}` }));
      throw new Error(errorBody.detail || `Validation error: HTTP ${resp.status}`);
    }
    return resp.json();
  } catch (err: any) {
    if (err.name === 'TypeError' || err.message === 'Failed to fetch') {
      throw new Error('Unable to connect to backend server (http://127.0.0.1:8000). Please ensure FastAPI is running.');
    }
    throw err;
  }
}

export async function validateCsv(csvContent: string, filename: string = 'custom_telemetry.csv'): Promise<CsvValidationResponse> {
  try {
    const resp = await fetch(`${API_BASE}/csv/validate`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        csv_content: csvContent,
        filename,
      }),
    });

    if (!resp.ok) {
      const errorBody = await resp.json().catch(() => ({ detail: 'Validation request failed' }));
      throw new Error(errorBody.detail || `Validation error: HTTP ${resp.status}`);
    }
    return resp.json();
  } catch (err: any) {
    if (err.name === 'TypeError' || err.message === 'Failed to fetch') {
      throw new Error('Unable to connect to backend server (http://127.0.0.1:8000). Please ensure FastAPI is running.');
    }
    throw err;
  }
}

export async function predictCustomCsv(
  csvContent: string,
  selectedTimestamp: string,
  filename: string = 'custom_telemetry.csv'
): Promise<CsvPredictResponse> {
  try {
    const resp = await fetch(`${API_BASE}/csv/predict`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        csv_content: csvContent,
        selected_timestamp: selectedTimestamp,
        filename,
      }),
    });

    if (!resp.ok) {
      const errorBody = await resp.json().catch(() => ({ detail: 'Forecast execution failed' }));
      throw new Error(errorBody.detail || `CSV Prediction error: HTTP ${resp.status}`);
    }
    return resp.json();
  } catch (err: any) {
    if (err.name === 'TypeError' || err.message === 'Failed to fetch') {
      throw new Error('Unable to connect to backend server (http://127.0.0.1:8000). Please ensure FastAPI is running.');
    }
    throw err;
  }
}

