import React from 'react';
import { ShieldCheck, ShieldAlert, AlertTriangle, Radio, CheckCircle2, XCircle, Clock } from 'lucide-react';
import type { PredictResponse } from '../types/api';

interface SensorHealthPanelProps {
  prediction: PredictResponse | null;
  loading?: boolean;
}

export const SensorHealthPanel: React.FC<SensorHealthPanelProps> = ({ prediction, loading }) => {
  const health = prediction?.target_sensor_health ?? 'HEALTHY';
  const availability = prediction?.upstream_sensor_availability ?? {};
  const upstreamHealth = prediction?.upstream_sensor_health ?? {};
  const fallbackReason = prediction?.fallback_reason;
  const warning = prediction?.uncertainty_warning;
  const isWithheld = !prediction?.prediction_available;
  const featureStatuses = prediction?.feature_statuses ?? {};

  const shigaonStatus = upstreamHealth.shigaon_gauge ?? (availability.shigaon_gauge === false ? 'MISSING' : 'HEALTHY');
  const koynaStatus = upstreamHealth.koyna_1_gauge ?? (availability.koyna_1_gauge === false ? 'MISSING' : 'HEALTHY');

  const isUpstreamSuspect =
    shigaonStatus === 'SUSPECT_FLATLINE' ||
    shigaonStatus === 'STALE' ||
    koynaStatus === 'SUSPECT_FLATLINE' ||
    koynaStatus === 'STALE' ||
    warning?.includes('SUSPECT_FLATLINE') ||
    warning?.includes('UPSTREAM_SENSOR_STALE');

  const hasUpstreamOutage =
    availability.shigaon_gauge === false ||
    availability.koyna_1_gauge === false ||
    isUpstreamSuspect ||
    warning === 'UPSTREAM_TELEMETRY_DEGRADED';

  // Determine rainfall station status from feature analysis
  const rainStatus = featureStatuses['rain_sum_24h'] || upstreamHealth.sangli_rainfall || 'OK';
  const getRainBadge = () => {
    switch (rainStatus) {
      case 'INSUFFICIENT_HISTORY':
        return {
          label: 'INSUFFICIENT HISTORY (< 24h)',
          color: 'text-amber-400 font-semibold',
          sub: 'History window < required lookback',
          icon: <AlertTriangle className="w-4 h-4 text-amber-400 shrink-0" />,
        };
      case 'MEASURED_ZERO':
        return {
          label: 'MEASURED ZERO (0.0mm)',
          color: 'text-emerald-400 font-semibold',
          sub: 'Confirmed 0.0mm recorded by rain gauge',
          icon: <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />,
        };
      case 'ASSUMED_ZERO':
      case 'ZERO_IMPUTED':
        return {
          label: 'ASSUMED ZERO (NO REPORT)',
          color: 'text-sky-300 font-semibold',
          sub: 'Unrecorded interval assumed 0.0mm (IMD convention). Not confirmed dry.',
          icon: <Clock className="w-4 h-4 text-sky-400 shrink-0" />,
        };
      case 'TELEMETRY_DROPOUT':
      case 'UNRECORDED_MISSING':
      case 'MISSING':
        return {
          label: 'UNRECORDED / DROPOUT',
          color: 'text-rose-400 font-semibold',
          sub: 'Telemetry packet unrecorded or missing',
          icon: <XCircle className="w-4 h-4 text-rose-400 shrink-0" />,
        };
      case 'OK':
      case 'MEASURED_POSITIVE':
      default:
        return {
          label: 'MEASURING (ACTIVE RAIN)',
          color: 'text-emerald-400 font-semibold',
          sub: 'Active rainfall detected in telemetry',
          icon: <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />,
        };
    }
  };

  const rainInfo = getRainBadge();

  const getUpstreamBadge = (status: string, isAvail?: boolean) => {
    switch (status) {
      case 'STABLE_BUT_PLAUSIBLE':
        return {
          label: 'STABLE (PLAUSIBLE)',
          color: 'text-sky-300 font-semibold',
          sub: 'Invariant stage within natural baseflow limits',
          icon: <CheckCircle2 className="w-4 h-4 text-sky-400 shrink-0" />,
        };
      case 'SUSPECT_FLATLINE':
        return {
          label: 'SUSPECT FLATLINE (>= 24h)',
          color: 'text-amber-400 font-semibold',
          sub: 'Prolonged invariant reading; zero delta unverified',
          icon: <AlertTriangle className="w-4 h-4 text-amber-400 shrink-0" />,
        };
      case 'STALE':
        return {
          label: 'STALE / FLATLINED',
          color: 'text-rose-400 font-semibold',
          sub: 'Telemetry latency > 3h or flatlined >= 72h',
          icon: <ShieldAlert className="w-4 h-4 text-rose-400 shrink-0" />,
        };
      case 'MISSING':
        return {
          label: 'TELEMETRY DROPOUT',
          color: 'text-rose-400 font-semibold',
          sub: 'Station offline; no telemetry packet received',
          icon: <XCircle className="w-4 h-4 text-rose-400 shrink-0" />,
        };
      case 'HEALTHY':
      default:
        if (isAvail === false) {
          return {
            label: 'DROPOUT',
            color: 'text-rose-400 font-semibold',
            sub: 'Telemetry packet unavailable',
            icon: <XCircle className="w-4 h-4 text-rose-400 shrink-0" />,
          };
        }
        return {
          label: 'ONLINE (HEALTHY)',
          color: 'text-emerald-400 font-semibold',
          sub: 'Fresh packet with active physical variance',
          icon: <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />,
        };
    }
  };

  const shigaonBadge = getUpstreamBadge(shigaonStatus, availability.shigaon_gauge);
  const koynaBadge = getUpstreamBadge(koynaStatus, availability.koyna_1_gauge);

  const getHealthBanner = () => {
    if (loading) {
      return {
        bg: 'bg-slate-800/40 border-slate-700/50',
        text: 'text-slate-300',
        title: 'Evaluating Sensor Integrity...',
        desc: 'Analyzing historical variance, latency, and flatline patterns across Krishna Basin stations.',
        icon: <Clock className="w-5 h-5 text-sky-400 shrink-0" />,
      };
    }
    switch (health) {
      case 'HEALTHY':
        if (isUpstreamSuspect) {
          return {
            icon: <AlertTriangle className="w-5 h-5 text-amber-400 shrink-0" />,
            bg: 'bg-amber-500/10 border-amber-500/30 text-amber-300',
            badge: 'bg-amber-500/20 text-amber-300 border-amber-500/30',
            title: 'TARGET GAUGE HEALTHY — UPSTREAM GAUGE SUSPECT FLATLINE',
            desc: 'Target gauge (Ankali Bridge) is healthy and active. Upstream tributary telemetry has prolonged invariant readings (suspect flatline). Zero movement cannot confirm quiescent baseflow. The system operates in degraded mode and dispatches conservative local persistence.',
          };
        }
        if (hasUpstreamOutage) {
          return {
            icon: <AlertTriangle className="w-5 h-5 text-amber-400 shrink-0" />,
            bg: 'bg-amber-500/10 border-amber-500/30 text-amber-300',
            badge: 'bg-amber-500/20 text-amber-300 border-amber-500/30',
            title: 'TARGET GAUGE HEALTHY — UPSTREAM PARTIAL OUTAGE',
            desc: 'Target gauge (Ankali Bridge) telemetry is valid and healthy. Upstream monitoring network has partial station outages (e.g. Shigaon/Warna offline). The system safely falls back to local persistence.',
          };
        }
        return {
          icon: <ShieldCheck className="w-5 h-5 text-emerald-400 shrink-0" />,
          bg: 'bg-emerald-500/10 border-emerald-500/30 text-emerald-300',
          badge: 'bg-emerald-500/20 text-emerald-300 border-emerald-500/30',
          title: 'HEALTHY TELEMETRY',
          desc: 'Target sensor readings are fresh, fluctuating within expected physical variance bounds. Upstream network online.',
        };
      case 'SUSPECT_STALE':
        return {
          icon: <AlertTriangle className="w-5 h-5 text-amber-400 shrink-0" />,
          bg: 'bg-amber-500/10 border-amber-500/30 text-amber-300',
          badge: 'bg-amber-500/20 text-amber-300 border-amber-500/30',
          title: 'SUSPECT_STALE WARNING',
          desc: 'Target sensor has reported identical readings for >= 12h. Likely a stable dry-season river plateau, but flagged for monitoring.',
        };
      case 'STALE':
        return {
          icon: <ShieldAlert className="w-5 h-5 text-rose-400 shrink-0" />,
          bg: 'bg-rose-500/10 border-rose-500/30 text-rose-300',
          badge: 'bg-rose-500/20 text-rose-300 border-rose-500/30',
          title: 'STALE SENSOR FAILURE',
          desc: 'Telemetry latency exceeded 3.0h OR sensor flatlined with invariant float stage for >= 24h. Forecast safely withheld.',
        };
      case 'MISSING':
      default:
        return {
          icon: <XCircle className="w-5 h-5 text-slate-400 shrink-0" />,
          bg: 'bg-slate-800/60 border-slate-700 text-slate-300',
          badge: 'bg-slate-700 text-slate-300 border-slate-600',
          title: 'MISSING SENSOR TELEMETRY',
          desc: 'No observation available for target station. Forecast cannot be computed.',
        };
    }
  };

  const banner = getHealthBanner();

  return (
    <div className="bg-slate-900/90 border border-slate-800 rounded-xl p-3.5 sm:p-5 mb-6 shadow-lg">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 pb-3 border-b border-slate-800">
        <div className="flex items-center space-x-2.5">
          <Radio className="w-5 h-5 text-sky-400 shrink-0" />
          <h2 className="text-sm sm:text-base md:text-lg font-bold text-white tracking-wide">
            Telemetry & Sensor Health Architecture
          </h2>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <div className="flex items-center space-x-1.5 text-xs">
            <span className="text-slate-400">Target Gauge:</span>
            <span className={`font-bold px-2.5 py-0.5 rounded-full border ${banner.badge}`}>
              {health}
            </span>
          </div>
          <div className="flex items-center space-x-1.5 text-xs">
            <span className="text-slate-400">Upstream:</span>
            <span
              className={`font-bold px-2 py-0.5 rounded text-[11px] border ${
                isUpstreamSuspect
                  ? 'bg-amber-500/15 text-amber-300 border-amber-500/30'
                  : hasUpstreamOutage
                  ? 'bg-amber-500/15 text-amber-300 border-amber-500/30'
                  : 'bg-emerald-500/15 text-emerald-300 border-emerald-500/30'
              }`}
            >
              {isUpstreamSuspect ? 'SUSPECT / DEGRADED' : hasUpstreamOutage ? 'PARTIAL OUTAGE' : 'NOMINAL'}
            </span>
          </div>
        </div>
      </div>

      {/* Health Status Banner */}
      <div className={`mt-4 p-3.5 rounded-lg border ${banner.bg} flex items-start space-x-3`}>
        <div className="shrink-0 mt-0.5">{banner.icon}</div>
        <div className="text-xs sm:text-sm min-w-0">
          <div className="font-bold tracking-wide break-words">{banner.title}</div>
          <div className="text-slate-300/90 mt-1 leading-relaxed break-words">{banner.desc}</div>
          {fallbackReason && (
            <div className="mt-2 pt-2 border-t border-slate-700/40 text-xs font-mono text-slate-200 break-words">
              <strong className="text-white">Active Policy Action:</strong> {fallbackReason}
            </div>
          )}
        </div>
      </div>

      {/* Upstream & Network Telemetry Grid */}
      <div className="mt-4 grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-3">
        {/* Ankali Target */}
        <div className="bg-slate-800/60 border border-slate-700/60 rounded-lg p-3 min-w-0">
          <div className="flex items-center justify-between text-xs text-slate-400 mb-1">
            <span>Target Gauge</span>
            {health === 'HEALTHY' || health === 'SUSPECT_STALE' ? (
              <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
            ) : (
              <XCircle className="w-4 h-4 text-rose-400 shrink-0" />
            )}
          </div>
          <div className="text-sm font-bold text-white truncate">Ankali Bridge</div>
          <div className="text-[11px] text-slate-400 mt-1 truncate">
            Status: <span className="font-semibold text-slate-200">{health}</span>
          </div>
          <div className="text-[10px] text-slate-400 mt-0.5 truncate">
            Target early-warning station
          </div>
        </div>

        {/* Shigaon Warna */}
        <div className="bg-slate-800/60 border border-slate-700/60 rounded-lg p-3 min-w-0">
          <div className="flex items-center justify-between text-xs text-slate-400 mb-1">
            <span>Upstream Warna</span>
            {shigaonBadge.icon}
          </div>
          <div className="text-sm font-bold text-white truncate">Shigaon Gauge</div>
          <div className="text-[11px] text-slate-400 mt-1 truncate">
            Status: <span className={shigaonBadge.color}>{shigaonBadge.label}</span>
          </div>
          <div className="text-[10px] text-slate-400 mt-0.5 truncate">
            {shigaonBadge.sub}
          </div>
        </div>

        {/* Koyna_1 Dam */}
        <div className="bg-slate-800/60 border border-slate-700/60 rounded-lg p-3 min-w-0">
          <div className="flex items-center justify-between text-xs text-slate-400 mb-1">
            <span>Reservoir Gauge</span>
            {koynaBadge.icon}
          </div>
          <div className="text-sm font-bold text-white truncate">Koyna_1 Dam</div>
          <div className="text-[11px] text-slate-400 mt-1 truncate">
            Status: <span className={koynaBadge.color}>{koynaBadge.label}</span>
          </div>
          <div className="text-[10px] text-slate-400 mt-0.5 truncate">
            {koynaBadge.sub}
          </div>
        </div>

        {/* Sangli Rain */}
        <div className="bg-slate-800/60 border border-slate-700/60 rounded-lg p-3 min-w-0">
          <div className="flex items-center justify-between text-xs text-slate-400 mb-1">
            <span>Catchment Rain</span>
            {rainInfo.icon}
          </div>
          <div className="text-sm font-bold text-white truncate">Sangli Rain Station</div>
          <div className="text-[11px] text-slate-400 mt-1 truncate">
            Status: <span className={rainInfo.color}>{rainInfo.label}</span>
          </div>
          <div className="text-[10px] text-slate-400 mt-0.5 truncate">
            {rainInfo.sub}
          </div>
        </div>
      </div>

      {/* Forecast Withholding Warning if Applicable */}
      {isWithheld && (
        <div className="mt-4 p-3 bg-rose-950/60 border border-rose-600/50 rounded-lg flex items-center space-x-3 text-rose-200 text-xs sm:text-sm">
          <ShieldAlert className="w-5 h-5 text-rose-400 shrink-0" />
          <span className="leading-relaxed">
            <strong>Safety Constraint Engaged:</strong> Numerical stage forecasts are suppressed. Transmitting stage predictions based on a stuck float sensor risks producing dangerously misleading river projections.
          </span>
        </div>
      )}

      {/* Diagnostic Bar */}
      <div className="mt-3 pt-2.5 border-t border-slate-800/80 flex flex-wrap items-center justify-between text-xs gap-2">
        <div className="flex items-center space-x-2 text-slate-400 font-mono">
          <Clock className="w-3.5 h-3.5 text-sky-400 shrink-0" />
          <span>Diagnostic Tag:</span>
          <span className="font-bold text-amber-300 bg-amber-500/10 px-2 py-0.5 rounded border border-amber-500/30">
            {warning || 'NOMINAL'}
          </span>
        </div>
        <div className="text-slate-400 text-[11px]">
          Target Gauge: <span className="text-emerald-400 font-semibold">{health}</span>
          {' | '}
          Upstream: <span className={isUpstreamSuspect ? 'text-amber-400 font-semibold' : hasUpstreamOutage ? 'text-amber-400 font-semibold' : 'text-emerald-400 font-semibold'}>
            {isUpstreamSuspect ? 'SUSPECT FLATLINE' : hasUpstreamOutage ? 'PARTIAL OUTAGE' : 'HEALTHY'}
          </span>
        </div>
      </div>
    </div>
  );
};
