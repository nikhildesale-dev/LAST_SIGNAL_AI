import React from 'react';
import { Waves, TrendingUp, ShieldAlert, Clock, Zap, Database } from 'lucide-react';
import type { PredictResponse } from '../types/api';

interface OverviewCardsProps {
  prediction: PredictResponse | null;
  loading: boolean;
  isCustomCsv?: boolean;
}

export const OverviewCards: React.FC<OverviewCardsProps> = ({ prediction, loading, isCustomCsv }) => {
  const currentStage = prediction?.current_river_level_m;
  const f6 = prediction?.forecast_plus_6h;
  const f24 = prediction?.forecast_plus_24h;
  const isAvailable = prediction?.prediction_available ?? false;
  const regime = prediction?.hydrological_regime ?? 'BASEFLOW';

  const getRegimeBadge = () => {
    if (loading) {
      return {
        bg: 'bg-slate-800/40 border-slate-700/50 text-slate-300',
        dot: 'bg-sky-400',
        label: 'EVALUATING TELEMETRY...',
        desc: 'Analyzing upstream deltas, rainfall, and sensor health',
        engine: 'Evaluating...',
      };
    }
    if (regime === 'SURGE') {
      return {
        bg: 'bg-amber-500/10 border-amber-500/30 text-amber-400',
        dot: 'bg-amber-400',
        label: 'SURGE REGIME (RIDGE)',
        desc: 'Active hydraulic pulse from upstream Warna / rainfall',
        engine: 'Ridge Config C',
      };
    }
    if (regime === 'DEGRADED_UNUSABLE' || (!isAvailable && prediction !== null)) {
      return {
        bg: 'bg-rose-500/10 border-rose-500/30 text-rose-400',
        dot: 'bg-rose-400',
        label: 'SENSOR FAULT (WITHHELD)',
        desc: prediction?.fallback_reason || 'Target sensor stale/frozen or critical telemetry failure',
        engine: 'Forecast Suppressed',
      };
    }
    if (regime === 'DEGRADED' || prediction?.uncertainty_warning === 'UPSTREAM_TELEMETRY_DEGRADED') {
      return {
        bg: 'bg-amber-500/10 border-amber-500/30 text-amber-400',
        dot: 'bg-amber-400',
        label: 'DEGRADED REGIME',
        desc: prediction?.fallback_reason || 'Upstream telemetry suspect or dropout; conservative persistence dispatched',
        engine: 'Conservative Persistence',
      };
    }
    return {
      bg: 'bg-emerald-500/10 border-emerald-500/30 text-emerald-400',
      dot: 'bg-emerald-400',
      label: 'BASEFLOW REGIME (PERSISTENCE)',
      desc: 'Quiescent river stage with minimal upstream change',
      engine: 'Static Persistence',
    };
  };

  const badge = getRegimeBadge();

  return (
    <div className="mb-6">
      {/* Mode Indicator Banner directly above forecast cards */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between bg-slate-900 border border-slate-800 rounded-xl px-3.5 sm:px-4 py-2.5 mb-3.5 text-xs gap-2">
        <div className="flex items-center space-x-2 min-w-0">
          <span
            className={`px-2 py-0.5 rounded font-black uppercase tracking-wider text-[10px] shrink-0 border ${
              isCustomCsv
                ? 'bg-sky-500/20 text-sky-300 border-sky-500/30'
                : 'bg-amber-500/20 text-amber-300 border-amber-500/30'
            }`}
          >
            {isCustomCsv ? 'CUSTOM CSV TELEMETRY' : 'HISTORICAL REPLAY'}
          </span>
          <span className="text-slate-300 font-medium truncate">
            {isCustomCsv
              ? 'User-Uploaded Multi-Station Sequence — Causal Gated Inference (<= T)'
              : 'Archived Hydrological Replay — Krishna Basin Audit Pilot'}
          </span>
        </div>
        <div className="flex items-center space-x-2 text-slate-400 text-[11px] shrink-0">
          <Database className={`w-3.5 h-3.5 shrink-0 ${isCustomCsv ? 'text-sky-400' : 'text-amber-400'}`} />
          <span>{isCustomCsv ? 'Custom Data Feed' : 'Offline Pilot Archive'}</span>
          <span className="text-slate-600">•</span>
          <span className="text-sky-300/90 font-medium">Empirical Calibration</span>
        </div>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-3 sm:gap-4">
        {/* 1. Latest Observed Stage */}
        <div className="bg-slate-900/90 border border-slate-800 rounded-xl p-3.5 sm:p-4 flex flex-col justify-between shadow-lg min-w-0">
          <div className="flex items-center justify-between text-slate-400 mb-2">
            <span className="text-xs font-semibold uppercase tracking-wider">Observed River Stage</span>
            <Waves className="w-4 h-4 text-sky-400 shrink-0" />
          </div>
          <div className="my-2">
            {loading ? (
              <div className="h-8 w-24 bg-slate-800 animate-pulse rounded" />
            ) : currentStage !== null && currentStage !== undefined ? (
              <div className="flex items-baseline space-x-2">
                <span className="text-2xl sm:text-3xl font-extrabold text-white">
                  {currentStage.toFixed(3)}
                </span>
                <span className="text-sm font-semibold text-slate-400">m</span>
              </div>
            ) : (
              <span className="text-lg sm:text-xl font-bold text-rose-400">Telemetry Offline</span>
            )}
          </div>
          <div className="text-[11px] text-slate-400 flex items-center space-x-1.5 pt-1.5 border-t border-slate-800/60">
            <Clock className="w-3.5 h-3.5 text-slate-500 shrink-0" />
            <span className="truncate">
              {prediction?.prediction_timestamp || 'Pending Telemetry'}
            </span>
          </div>
        </div>

        {/* 2. +6h Forecast */}
        <div className="bg-slate-900/90 border border-slate-800 rounded-xl p-3.5 sm:p-4 flex flex-col justify-between shadow-lg min-w-0">
          <div className="flex items-center justify-between text-slate-400 mb-2">
            <div className="flex items-center space-x-1.5 min-w-0">
              <span className="text-xs font-semibold uppercase tracking-wider truncate">+6h Forecast</span>
              <span className="text-[9px] px-1.5 py-0.2 rounded bg-amber-500/20 text-amber-300 font-mono shrink-0">
                REPLAY
              </span>
            </div>
            <TrendingUp className="w-4 h-4 text-sky-400 shrink-0" />
          </div>
          <div className="my-2">
            {loading ? (
              <div className="h-8 w-24 bg-slate-800 animate-pulse rounded" />
            ) : isAvailable && f6 !== null && f6 !== undefined ? (
              <div className="flex items-baseline space-x-2 flex-wrap">
                <span className="text-2xl sm:text-3xl font-extrabold text-sky-400">
                  {f6.toFixed(4)}
                </span>
                <span className="text-sm font-semibold text-slate-400">m</span>
                {currentStage !== null && currentStage !== undefined && (
                  <span className={`text-xs font-bold ${f6 >= currentStage ? 'text-amber-400' : 'text-emerald-400'}`}>
                    {f6 >= currentStage ? `+${(f6 - currentStage).toFixed(4)}m` : `${(f6 - currentStage).toFixed(4)}m`}
                  </span>
                )}
              </div>
            ) : (
              <div className="flex items-center space-x-1.5 text-rose-400 font-bold text-lg">
                <ShieldAlert className="w-5 h-5 shrink-0" />
                <span>WITHHELD</span>
              </div>
            )}
          </div>
          <div className="text-[11px] text-slate-400 flex items-center justify-between pt-1.5 border-t border-slate-800/60">
            <span>Status:</span>
            <span className={`font-semibold ${isAvailable ? 'text-emerald-400' : 'text-rose-400'}`}>
              {isAvailable ? 'Valid Prediction' : 'Forecast Withheld'}
            </span>
          </div>
        </div>

        {/* 3. +24h Forecast */}
        <div className="bg-slate-900/90 border border-slate-800 rounded-xl p-3.5 sm:p-4 flex flex-col justify-between shadow-lg min-w-0">
          <div className="flex items-center justify-between text-slate-400 mb-2">
            <div className="flex items-center space-x-1.5 min-w-0">
              <span className="text-xs font-semibold uppercase tracking-wider truncate">+24h Forecast</span>
              <span className="text-[9px] px-1.5 py-0.2 rounded bg-amber-500/20 text-amber-300 font-mono shrink-0">
                REPLAY
              </span>
            </div>
            <TrendingUp className="w-4 h-4 text-indigo-400 shrink-0" />
          </div>
          <div className="my-2">
            {loading ? (
              <div className="h-8 w-24 bg-slate-800 animate-pulse rounded" />
            ) : isAvailable && f24 !== null && f24 !== undefined ? (
              <div className="flex items-baseline space-x-2 flex-wrap">
                <span className="text-2xl sm:text-3xl font-extrabold text-indigo-400">
                  {f24.toFixed(4)}
                </span>
                <span className="text-sm font-semibold text-slate-400">m</span>
                {currentStage !== null && currentStage !== undefined && (
                  <span className={`text-xs font-bold ${f24 >= currentStage ? 'text-amber-400' : 'text-emerald-400'}`}>
                    {f24 >= currentStage ? `+${(f24 - currentStage).toFixed(4)}m` : `${(f24 - currentStage).toFixed(4)}m`}
                  </span>
                )}
              </div>
            ) : (
              <div className="flex items-center space-x-1.5 text-rose-400 font-bold text-lg">
                <ShieldAlert className="w-5 h-5 shrink-0" />
                <span>WITHHELD</span>
              </div>
            )}
          </div>
          <div className="text-[11px] text-slate-400 flex items-center justify-between pt-1.5 border-t border-slate-800/60">
            <span>Target Gauge:</span>
            <span className="font-semibold text-slate-300">Ankali Bridge</span>
          </div>
        </div>

        {/* 4. Active Regime */}
        <div className={`bg-slate-900/90 border rounded-xl p-3.5 sm:p-4 flex flex-col justify-between shadow-lg min-w-0 ${badge.bg}`}>
          <div className="flex items-center justify-between mb-2">
            <span className="text-xs font-semibold uppercase tracking-wider">Active Forecasting Regime</span>
            <Zap className="w-4 h-4 shrink-0" />
          </div>
          <div className="my-1">
            <div className="flex items-center space-x-2 min-w-0">
              <span className={`w-2.5 h-2.5 rounded-full ${badge.dot} animate-pulse shrink-0`} />
              <span className="text-base sm:text-lg font-black tracking-tight truncate">{badge.label}</span>
            </div>
            <p className="text-xs text-slate-300/80 mt-1 line-clamp-2 leading-relaxed">
              {badge.desc}
            </p>
          </div>
          <div className="text-[11px] flex items-center justify-between pt-1.5 border-t border-slate-800/60">
            <span>Engine:</span>
            <span className="font-mono font-bold">
              {badge.engine}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};
