import React, { useState } from 'react';
import { Layers, ChevronDown, ChevronRight, Server, AlertCircle, Info } from 'lucide-react';
import type { PredictResponse, ModelInfoResponse } from '../types/api';

interface ForecastDetailsPanelProps {
  prediction: PredictResponse | null;
  modelInfo: ModelInfoResponse | null;
  features: Record<string, number | null> | null;
  loading?: boolean;
}

export const ForecastDetailsPanel: React.FC<ForecastDetailsPanelProps> = ({
  prediction,
  modelInfo,
  features,
  loading,
}) => {
  const [showFeatures, setShowFeatures] = useState<boolean>(true);

  const regime = prediction?.hydrological_regime ?? 'BASEFLOW';
  const isSurge = regime === 'SURGE';
  const isDegraded = regime === 'DEGRADED';
  const isWithheld = !prediction?.prediction_available;
  const featureStatuses = prediction?.feature_statuses ?? {};

  const getReasoning = () => {
    if (loading) {
      return {
        engine: 'Evaluating Telemetry & Gating...',
        reason: 'Evaluating historical stage trends, rainfall accumulation, and sensor health before model dispatch.',
        badge: 'bg-sky-500/20 text-sky-300 border-sky-500/30',
      };
    }
    if (isWithheld) {
      return {
        engine: 'Forecast Safely Suppressed',
        reason:
          prediction?.fallback_reason ||
          'Target river sensor failure: Telemetry gap > 3.0 hours or 24-hour invariant float stage flatline detected. No numerical forecast emitted.',
        badge: 'bg-rose-500/20 text-rose-300 border-rose-500/30',
      };
    }
    if (isDegraded) {
      return {
        engine: 'Conservative Persistence (Degraded Fallback)',
        reason:
          prediction?.fallback_reason ||
          'Upstream telemetry suspect or stale: Hydraulic continuity cannot be corroborated from invariant upstream stage. Fallback persistence dispatched.',
        badge: 'bg-amber-500/20 text-amber-300 border-amber-500/30',
      };
    }
    if (isSurge) {
      return {
        engine: 'Multi-Station Ridge Regression (Config C)',
        reason:
          'Active surge condition triggered: Upstream Warna River at Shigaon 6h rate-of-rise exceeded 0.08m threshold OR heavy catchment rainfall detected. Ridge model captures non-local hydraulic wave propagation.',
        badge: 'bg-amber-500/20 text-amber-300 border-amber-500/30',
      };
    }
    return {
      engine: 'Persistence Forecaster (Baseflow Baseline)',
      reason:
        'Quiescent baseflow condition: Minor water stage variation without upstream flood surge. Persistence baseline y_hat(t+h) = y(t) minimizes empirical variance and prevents model drift during flat river stages.',
      badge: 'bg-emerald-500/20 text-emerald-300 border-emerald-500/30',
    };
  };

  const dispatch = getReasoning();

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'OK':
        return (
          <span className="text-[10px] px-2 py-0.5 rounded font-bold bg-emerald-500/20 text-emerald-300 border border-emerald-500/30">
            OK
          </span>
        );
      case 'MEASURED_ZERO':
        return (
          <span className="text-[10px] px-2 py-0.5 rounded font-bold bg-emerald-500/20 text-emerald-300 border border-emerald-500/30">
            MEASURED_ZERO
          </span>
        );
      case 'ASSUMED_ZERO':
        return (
          <span className="text-[10px] px-2 py-0.5 rounded font-bold bg-amber-500/20 text-amber-300 border border-amber-500/30">
            ASSUMED_ZERO
          </span>
        );
      case 'ZERO_IMPUTED':
        return (
          <span className="text-[10px] px-2 py-0.5 rounded font-bold bg-amber-500/20 text-amber-300 border border-amber-500/30">
            ZERO_IMPUTED
          </span>
        );
      case 'INSUFFICIENT_HISTORY':
        return (
          <span className="text-[10px] px-2 py-0.5 rounded font-bold bg-amber-500/20 text-amber-300 border border-amber-500/30">
            INSUFFICIENT_HISTORY
          </span>
        );
      case 'TELEMETRY_DROPOUT':
        return (
          <span className="text-[10px] px-2 py-0.5 rounded font-bold bg-rose-500/20 text-rose-300 border border-rose-500/30">
            TELEMETRY_DROPOUT
          </span>
        );
      case 'MISSING':
      default:
        return (
          <span className="text-[10px] px-2 py-0.5 rounded font-bold bg-slate-700 text-slate-300 border border-slate-600">
            MISSING
          </span>
        );
    }
  };

  const getFeatureDetails = (key: string, _val: number | null, status: string) => {
    // Feature-specific descriptions for rainfall
    if (key === 'rain_sum_24h') {
      return 'Rolling cumulative rainfall over the previous 24 hours.';
    }
    if (key === 'rain_sum_48h') {
      return 'Rolling cumulative rainfall over the previous 48 hours.';
    }
    if (key === 'rain_sum_72h') {
      return 'Rolling cumulative rainfall over the previous 72 hours.';
    }
    if (key === 'rain_intensity_6h') {
      return 'Derived six-hour rainfall intensity.';
    }

    if (status === 'INSUFFICIENT_HISTORY') {
      return 'Insufficient lookback: Historical replay window has fewer hours than required for this lead-time lag.';
    }
    if (status === 'TELEMETRY_DROPOUT') {
      return 'Telemetry dropout: Monitoring station offline / no sensor transmission during observation window.';
    }
    if (status === 'ASSUMED_ZERO' || status === 'ZERO_IMPUTED') {
      return 'Assumed-zero period: No rainfall report received; unrecorded interval treated as assumed 0.0 mm under IMD convention. Not physically confirmed dry weather.';
    }
    if (status === 'MEASURED_ZERO') {
      return 'Confirmed 0.0 mm measured precipitation from active weather station.';
    }
    if (status === 'OK') {
      return 'Direct telemetry observation: Causal lag/delta calculated from valid sensor readings.';
    }
    return 'Telemetry unrecorded or undefined.';
  };

  return (
    <div className="bg-slate-900/90 border border-slate-800 rounded-xl p-3.5 sm:p-5 mb-6 shadow-lg min-w-0">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 pb-3 border-b border-slate-800">
        <div className="flex items-center space-x-2 min-w-0">
          <Layers className="w-5 h-5 text-sky-400 shrink-0" />
          <h2 className="text-sm sm:text-base md:text-lg font-bold text-white tracking-wide truncate">
            Hydrological Forecaster Dispatch & Feature Inspection
          </h2>
        </div>
        <div className="flex items-center space-x-2 text-xs shrink-0">
          <Server className="w-4 h-4 text-slate-400 shrink-0" />
          <span className="text-slate-400">Architecture:</span>
          <span className="font-mono text-slate-200">Gated Dual-Regime V2</span>
        </div>
      </div>

      {/* Dispatch explanation card */}
      <div className="mt-4 bg-slate-800/40 border border-slate-700/60 rounded-xl p-3.5 sm:p-4 min-w-0">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 mb-2">
          <div className="text-xs uppercase tracking-wider text-slate-400 font-semibold">
            Active Forecasting Engine:
          </div>
          <span className={`text-xs font-bold px-2.5 py-0.5 rounded-full border ${dispatch.badge}`}>
            {dispatch.engine}
          </span>
        </div>
        <p className="text-xs sm:text-sm text-slate-300 leading-relaxed break-words">{dispatch.reason}</p>

        {prediction?.uncertainty_warning && (
          <div className="mt-3 pt-2.5 border-t border-slate-700/40 flex items-center space-x-2 text-xs text-amber-300 flex-wrap">
            <AlertCircle className="w-4 h-4 shrink-0" />
            <span>
              <strong>Diagnostic Warning Tag:</strong> {prediction.uncertainty_warning}
            </span>
          </div>
        )}
      </div>

      {/* Model Metadata & Horizons */}
      <div className="mt-4 grid grid-cols-1 sm:grid-cols-4 gap-3 text-xs">
        <div className="bg-slate-800/30 border border-slate-800 rounded-lg p-3 min-w-0">
          <div className="text-slate-400 mb-1">Target Monitoring Gauge</div>
          <div className="text-white font-bold truncate">{modelInfo?.target_station || 'Ankali Bridge (Krishna Basin)'}</div>
          <div className="text-[11px] text-slate-500 mt-1">Lead: +6h / +24h</div>
        </div>
        <div className="bg-slate-800/30 border border-slate-800 rounded-lg p-3 min-w-0">
          <div className="text-slate-400 mb-1">Upstream Hydraulic Stations</div>
          <div className="text-white font-bold truncate">Shigaon (Warna) + Koyna_1</div>
          <div className="text-[11px] text-slate-500 mt-1">Lead time: 6h–24h</div>
        </div>
        <div className="bg-slate-800/30 border border-slate-800 rounded-lg p-3 min-w-0">
          <div className="text-slate-400 mb-1">+6h Ridge / Baseline Dispatch</div>
          <div className="text-sky-300 font-mono font-bold truncate">
            {prediction?.prediction_available && prediction?.forecast_plus_6h !== null && prediction?.forecast_plus_6h !== undefined
              ? `${prediction.forecast_plus_6h.toFixed(4)} m`
              : 'WITHHELD'}
          </div>
          <div className="text-[11px] text-slate-500 mt-1">Horizon: T + 6 hours</div>
        </div>
        <div className="bg-slate-800/30 border border-slate-800 rounded-lg p-3 min-w-0">
          <div className="text-slate-400 mb-1">+24h Ridge / Baseline Dispatch</div>
          <div className="text-indigo-300 font-mono font-bold truncate">
            {prediction?.prediction_available && prediction?.forecast_plus_24h !== null && prediction?.forecast_plus_24h !== undefined
              ? `${prediction.forecast_plus_24h.toFixed(4)} m`
              : 'WITHHELD'}
          </div>
          <div className="text-[11px] text-slate-500 mt-1">Horizon: T + 24 hours</div>
        </div>
      </div>

      {/* Feature Vector Inspection Toggle */}
      <div className="mt-4 pt-3 border-t border-slate-800 min-w-0">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
          <button
            onClick={() => setShowFeatures(!showFeatures)}
            className="flex items-center space-x-2 text-xs font-semibold text-sky-400 hover:text-sky-300 transition-colors cursor-pointer"
          >
            {showFeatures ? <ChevronDown className="w-4 h-4 shrink-0" /> : <ChevronRight className="w-4 h-4 shrink-0" />}
            <span>
              {showFeatures ? 'Hide' : 'Inspect'} Engineered Hydrological Feature Vector (15 features)
            </span>
          </button>
          <div className="flex items-center space-x-1.5 text-[11px] text-slate-400">
            <Info className="w-3.5 h-3.5 text-sky-400 shrink-0" />
            <span>Telemetry Dropouts vs Insufficient History distinguished below</span>
          </div>
        </div>

        {showFeatures && features && (
          <div className="mt-3 w-full overflow-x-auto rounded-lg border border-slate-800">
            <table className="min-w-[650px] w-full text-xs text-left">
              <thead className="bg-slate-800/90 text-slate-300 font-semibold uppercase text-[10px] tracking-wider border-b border-slate-700/60">
                <tr>
                  <th className="py-2.5 px-3">Feature Name</th>
                  <th className="py-2.5 px-3">Telemetry Domain</th>
                  <th className="py-2.5 px-3">Model-Input Value</th>
                  <th className="py-2.5 px-3">Availability Status</th>
                  <th className="py-2.5 px-3">Hydrological Telemetry Context</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/80 bg-slate-900/60">
                {Object.entries(features).map(([key, val]) => {
                  let domain = 'Target River Lag';
                  if (key.startsWith('rain')) domain = 'Sangli Precipitation';
                  if (key.startsWith('shigaon')) domain = 'Shigaon Warna Delta';
                  if (key.startsWith('koyna')) domain = 'Koyna Reservoir Delta';

                  const isNull = val === null || val === undefined;
                  const status = featureStatuses[key] || (isNull ? 'MISSING' : 'OK');
                  const contextNote = getFeatureDetails(key, val, status);

                  return (
                    <tr key={key} className="hover:bg-slate-800/40 transition-colors">
                      <td className="py-2 px-3 font-mono font-semibold text-slate-200">{key}</td>
                      <td className="py-2 px-3 text-slate-400">{domain}</td>
                      <td className="py-2 px-3 font-mono font-bold text-white">
                        {isNull ? (
                          <span className="text-slate-500 font-normal">null</span>
                        ) : (
                          `${Number(val).toFixed(4)}`
                        )}
                      </td>
                      <td className="py-2 px-3 whitespace-nowrap">{getStatusBadge(status)}</td>
                      <td className="py-2 px-3 text-[11px] text-slate-400 leading-normal max-w-xs">{contextNote}</td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
};
