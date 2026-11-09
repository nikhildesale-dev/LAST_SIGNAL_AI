import React, { useEffect, useState } from 'react';
import { Header } from './components/Header';
import { DisclaimerBanner } from './components/DisclaimerBanner';
import { OverviewCards } from './components/OverviewCards';
import { SensorHealthPanel } from './components/SensorHealthPanel';
import { ForecastChart } from './components/ForecastChart';
import { UpstreamMonitoringPanel } from './components/UpstreamMonitoringPanel';
import { ScenarioSelector } from './components/ScenarioSelector';
import { CustomCsvPanel } from './components/CustomCsvPanel';
import { ForecastDetailsPanel } from './components/ForecastDetailsPanel';

import {
  fetchHealth,
  fetchModelInfo,
  fetchScenarios,
  fetchTelemetryHistory,
  executeForecast,
} from './services/api';
import type {
  HealthResponse,
  ModelInfoResponse,
  ScenarioItem,
  TelemetryPoint,
  PredictResponse,
  CsvPredictResponse,
} from './types/api';
import { AlertCircle, RefreshCw, Database, UploadCloud } from 'lucide-react';

export const App: React.FC = () => {
  const [health, setHealth] = useState<HealthResponse | null>(null);
  const [modelInfo, setModelInfo] = useState<ModelInfoResponse | null>(null);
  const [scenarios, setScenarios] = useState<ScenarioItem[]>([]);
  const [selectedScenario, setSelectedScenario] = useState<ScenarioItem | null>(null);
  const [telemetry, setTelemetry] = useState<TelemetryPoint[]>([]);
  const [prediction, setPrediction] = useState<PredictResponse | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  // Operating Mode: 'REPLAY' for 5 curated historical episodes, 'CSV' for custom telemetry upload
  const [operatingMode, setOperatingMode] = useState<'REPLAY' | 'CSV'>('REPLAY');
  const [customFeatures, setCustomFeatures] = useState<Record<string, number | null> | null>(null);

  const loadScenarioData = async (sc: ScenarioItem) => {
    try {
      setLoading(true);
      setError(null);
      // Clear previous prediction so stale values do not persist during evaluation
      setPrediction(null);

      // 1. Fetch real historical timeline centered on scenario
      const hist = await fetchTelemetryHistory(sc.id, 96);
      setTelemetry(hist.series);

      // 2. Execute forecast via FastAPI /predict endpoint with complete multi-station telemetry
      const pred = await executeForecast({
        current_stage_m: sc.current_stage_m,
        prediction_timestamp: sc.prediction_timestamp,
        features: sc.features,
        history_stages: sc.history_stages,
        history_timestamps: sc.history_timestamps,
        history_shigaon_stages: sc.history_shigaon_stages,
        history_shigaon_timestamps: sc.history_shigaon_timestamps,
        history_koyna_stages: sc.history_koyna_stages,
        history_koyna_timestamps: sc.history_koyna_timestamps,
        rainfall_measured_mm: sc.rainfall_measured_mm,
      });
      setPrediction(pred);
    } catch (err: any) {
      console.error('Scenario load error:', err);
      setError(err.message || 'Error executing forecast on selected scenario.');
    } finally {
      setLoading(false);
    }
  };

  // Initial bootstrap
  useEffect(() => {
    async function initDashboard() {
      try {
        setLoading(true);
        setError(null);

        // Fetch system metadata
        const [h, mi, scData] = await Promise.all([
          fetchHealth().catch(() => null),
          fetchModelInfo().catch(() => null),
          fetchScenarios().catch(() => ({ scenarios: [] })),
        ]);

        if (h) setHealth(h);
        if (mi) setModelInfo(mi);

        if (scData && scData.scenarios.length > 0) {
          setScenarios(scData.scenarios);
          // Default to Surge scenario if available, or first
          const defaultSc =
            scData.scenarios.find((s) => s.category === 'SURGE') || scData.scenarios[0];
          setSelectedScenario(defaultSc);

          // Fetch historical timeline & run forecast
          await loadScenarioData(defaultSc);
        } else {
          // Fallback to recent telemetry
          const hist = await fetchTelemetryHistory(undefined, 96);
          setTelemetry(hist.series);
        }
      } catch (err: any) {
        console.error('Initialization error:', err);
        setError(err.message || 'Failed to initialize river forecasting dashboard.');
      } finally {
        setLoading(false);
      }
    }

    initDashboard();
  }, []);

  const handleSelectScenario = (sc: ScenarioItem) => {
    setSelectedScenario(sc);
    loadScenarioData(sc);
  };

  const handleRunForecast = () => {
    if (selectedScenario) {
      loadScenarioData(selectedScenario);
    }
  };

  // CSV Prediction Handlers
  const handleCsvPredictionSuccess = (csvPred: CsvPredictResponse) => {
    setPrediction(csvPred);
    setTelemetry(csvPred.telemetry_series);
    setCustomFeatures(csvPred.features_engineered);
    setError(null);
  };

  const handleClearPrediction = () => {
    setPrediction(null);
    setCustomFeatures(null);
  };

  const handleSwitchMode = (mode: 'REPLAY' | 'CSV') => {
    if (mode === operatingMode) return;
    setOperatingMode(mode);
    setPrediction(null);
    setError(null);

    if (mode === 'REPLAY' && selectedScenario) {
      loadScenarioData(selectedScenario);
    } else if (mode === 'CSV') {
      setCustomFeatures(null);
      setTelemetry([]);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col font-sans overflow-x-hidden w-full">
      {/* 1. Header with health & version */}
      <Header
        health={health}
        modelVersion={modelInfo?.model_version || '2.0.0-hardened'}
      />

      {/* Main Container */}
      <main className="flex-1 max-w-[1600px] w-full mx-auto px-3 sm:px-4 md:px-6 py-4 sm:py-6 min-w-0">
        {/* 2. Operational Disclaimer Banner */}
        <DisclaimerBanner />

        {/* Global Error Banner if API Fails */}
        {error && (
          <div className="mb-6 p-4 bg-rose-950/60 border border-rose-600/50 rounded-xl flex items-center justify-between text-rose-200 text-sm">
            <div className="flex items-center space-x-3">
              <AlertCircle className="w-5 h-5 text-rose-400 shrink-0" />
              <span>{error}</span>
            </div>
            <button
              onClick={() => handleRunForecast()}
              className="px-3 py-1 bg-rose-800 hover:bg-rose-700 text-white rounded text-xs font-semibold flex items-center space-x-1 cursor-pointer"
            >
              <RefreshCw className="w-3.5 h-3.5" />
              <span>Retry</span>
            </button>
          </div>
        )}

        {/* Operating Mode Switcher Bar */}
        <div className="flex items-center space-x-2 mb-4 bg-slate-900/90 p-1.5 rounded-xl border border-slate-800 w-fit">
          <button
            onClick={() => handleSwitchMode('REPLAY')}
            className={`flex items-center space-x-2 px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer ${
              operatingMode === 'REPLAY'
                ? 'bg-sky-600 text-white shadow-md shadow-sky-950'
                : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/60'
            }`}
          >
            <Database className="w-4 h-4" />
            <span>Curated Historical Replays (5 Episodes)</span>
          </button>

          <button
            onClick={() => handleSwitchMode('CSV')}
            className={`flex items-center space-x-2 px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all cursor-pointer ${
              operatingMode === 'CSV'
                ? 'bg-sky-600 text-white shadow-md shadow-sky-950'
                : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/60'
            }`}
          >
            <UploadCloud className="w-4 h-4" />
            <span>Custom CSV Prediction</span>
          </button>
        </div>

        {/* 3. Replay Mode or CSV Mode Ingestion Controls */}
        {operatingMode === 'REPLAY' ? (
          <ScenarioSelector
            scenarios={scenarios}
            selectedScenario={selectedScenario}
            onSelectScenario={handleSelectScenario}
            onRunForecast={handleRunForecast}
            loading={loading}
          />
        ) : (
          <CustomCsvPanel
            onPredictionSuccess={handleCsvPredictionSuccess}
            onClearPrediction={handleClearPrediction}
            loading={loading}
            setLoading={setLoading}
          />
        )}

        {/* 4. Top KPI Overview Cards (+6h, +24h, Regime, Current Stage) */}
        <OverviewCards
          prediction={prediction}
          loading={loading}
          isCustomCsv={operatingMode === 'CSV'}
        />

        {/* 5. Target Sensor Health Monitor & Upstream Status */}
        <SensorHealthPanel prediction={prediction} loading={loading} />

        {/* 6. Primary Interactive River Stage Forecast Chart */}
        <ForecastChart telemetry={telemetry} prediction={prediction} loading={loading} />

        {/* 7. Multi-Station Upstream & Catchment Rainfall Trends */}
        <UpstreamMonitoringPanel telemetry={telemetry} />

        {/* 8. Forecaster Engine Dispatch Details & Feature Inspector */}
        <ForecastDetailsPanel
          prediction={prediction}
          modelInfo={modelInfo}
          features={operatingMode === 'CSV' ? customFeatures : (selectedScenario?.features || null)}
          loading={loading}
        />
      </main>

      {/* Footer */}
      <footer className="bg-slate-900 border-t border-slate-800 py-4 px-6 text-center text-xs text-slate-500">
        <p>
          LAST_SIGNAL_AI &copy; {new Date().getFullYear()} — Krishna River Basin Hydrological Forecasting Service.
          Empirical stage predictions for Ankali Bridge (Sangli, Maharashtra).
        </p>
      </footer>
    </div>
  );
};

export default App;
