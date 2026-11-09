import React from 'react';
import {
  ResponsiveContainer,
  LineChart,
  Line,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
} from 'recharts';
import { CloudRain, Navigation, Mountain, AlertCircle, SunMedium, RadioOff } from 'lucide-react';
import type { TelemetryPoint } from '../types/api';

interface UpstreamMonitoringPanelProps {
  telemetry: TelemetryPoint[];
}

function parseSqlTimestamp(ts: string): Date {
  const parts = ts.trim().split(/[- :]/);
  return new Date(
    parseInt(parts[0], 10),
    parseInt(parts[1], 10) - 1,
    parseInt(parts[2], 10),
    parseInt(parts[3] || '0', 10),
    parseInt(parts[4] || '0', 10),
    parseInt(parts[5] || '0', 10)
  );
}

export const UpstreamMonitoringPanel: React.FC<UpstreamMonitoringPanelProps> = ({ telemetry }) => {
  const chartData = telemetry.map((pt) => {
    const d = parseSqlTimestamp(pt.timestamp);
    const formatted = `${d.getMonth() + 1}/${d.getDate()} ${d.getHours().toString().padStart(2, '0')}:00`;

    return {
      timestamp: pt.timestamp,
      formattedTime: formatted,
      shigaon: pt.shigaon_stage_m,
      koyna: pt.koyna_stage_m,
      rain: pt.rainfall_mm,
    };
  });

  // Calculate observation counts
  const validShigaon = chartData.filter((p) => p.shigaon !== null && !isNaN(p.shigaon));
  const validKoyna = chartData.filter((p) => p.koyna !== null && !isNaN(p.koyna));
  const validRainEvents = chartData.filter((p) => p.rain !== null && !isNaN(p.rain) && p.rain > 0);

  return (
    <div className="bg-slate-900/90 border border-slate-800 rounded-xl p-3.5 sm:p-5 mb-6 shadow-lg min-w-0">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-4 pb-3 border-b border-slate-800">
        <div className="min-w-0">
          <h2 className="text-sm sm:text-base md:text-lg font-bold text-white tracking-wide">
            Multi-Station Upstream & Rainfall Telemetry Trends
          </h2>
          <p className="text-xs text-slate-400 mt-0.5">
            Real upstream signals providing 6h–24h lead-time hydraulic information to Ankali Bridge.
          </p>
        </div>
        <div className="flex items-center space-x-1.5 text-xs text-amber-300 bg-amber-500/10 border border-amber-500/20 px-2.5 py-1 rounded-lg shrink-0">
          <span>Un-interpolated telemetry: Gaps indicate real station outages</span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 sm:gap-5">
        {/* 1. Shigaon Warna River */}
        <div className="bg-slate-800/40 border border-slate-700/60 rounded-xl p-3.5 flex flex-col justify-between min-w-0">
          <div>
            <div className="flex items-center justify-between text-xs text-slate-300 mb-2">
              <div className="flex items-center space-x-1.5 min-w-0">
                <Navigation className="w-4 h-4 text-emerald-400 rotate-45 shrink-0" />
                <span className="font-bold text-white truncate">Shigaon (Warna River)</span>
              </div>
              <span className="text-[10px] px-1.5 py-0.5 rounded bg-emerald-500/10 text-emerald-300 font-mono shrink-0">
                {validShigaon.length > 0 ? `${validShigaon.length}/${chartData.length}h` : 'OFFLINE'}
              </span>
            </div>

            {validShigaon.length === 0 ? (
              <div className="h-44 w-full flex flex-col items-center justify-center text-center p-3 bg-slate-900/60 rounded-lg border border-slate-700/50">
                <RadioOff className="w-7 h-7 text-rose-400 mb-2 shrink-0" />
                <span className="text-xs font-bold text-rose-300">Telemetry Temporarily Unavailable</span>
                <p className="text-[11px] text-slate-400 mt-1 max-w-xs leading-relaxed">
                  Shigaon upstream station was offline and not transmitting telemetry during this replay window.
                </p>
                <span className="text-[10px] text-slate-500 mt-1.5 font-mono">Status: TELEMETRY_DROPOUT</span>
              </div>
            ) : (
              <div className="h-44 w-full min-w-0">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={chartData} margin={{ top: 5, right: 10, left: -10, bottom: 20 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.4} />
                    <XAxis
                      dataKey="formattedTime"
                      stroke="#94a3b8"
                      fontSize={9}
                      tickLine={false}
                      interval="preserveStartEnd"
                      angle={-25}
                      textAnchor="end"
                    />
                    <YAxis
                      stroke="#94a3b8"
                      fontSize={10}
                      domain={['auto', 'auto']}
                      tickFormatter={(v) => `${v.toFixed(1)}m`}
                    />
                    <Tooltip
                      contentStyle={{
                        backgroundColor: '#0f172a',
                        borderColor: '#334155',
                        borderRadius: '6px',
                        fontSize: '11px',
                      }}
                      formatter={(val: any) => [
                        val !== null ? `${Number(val).toFixed(3)} m` : 'Missing Telemetry',
                        'Warna Stage',
                      ]}
                    />
                    <Line
                      type="monotone"
                      dataKey="shigaon"
                      stroke="#10b981"
                      strokeWidth={2}
                      dot={false}
                      connectNulls={false}
                      isAnimationActive={false}
                    />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            )}
          </div>
          <div className="text-[10px] text-slate-400 mt-2 flex justify-between border-t border-slate-700/40 pt-1.5">
            <span>Surge Rate-of-Rise Predictor</span>
            <span>Lead: ~6–12h</span>
          </div>
        </div>

        {/* 2. Koyna_1 Dam Reservoir */}
        <div className="bg-slate-800/40 border border-slate-700/60 rounded-xl p-3.5 flex flex-col justify-between min-w-0">
          <div>
            <div className="flex items-center justify-between text-xs text-slate-300 mb-2">
              <div className="flex items-center space-x-1.5 min-w-0">
                <Mountain className="w-4 h-4 text-sky-400 shrink-0" />
                <span className="font-bold text-white truncate">Koyna_1 (Reservoir)</span>
              </div>
              <span className="text-[10px] px-1.5 py-0.5 rounded bg-sky-500/10 text-sky-300 font-mono shrink-0">
                {validKoyna.length > 0 ? `${validKoyna.length}/${chartData.length}h` : 'NO DATA'}
              </span>
            </div>

            {validKoyna.length === 0 ? (
              <div className="h-44 w-full flex flex-col items-center justify-center text-center p-3 bg-slate-900/60 rounded-lg border border-slate-700/50">
                <AlertCircle className="w-7 h-7 text-sky-400 mb-2 shrink-0" />
                <span className="text-xs font-bold text-sky-300">Outside Station Coverage Period</span>
                <p className="text-[11px] text-slate-400 mt-1 max-w-xs leading-relaxed">
                  Koyna Dam reservoir telemetry was not recorded or falls outside the active station coverage window.
                </p>
                <span className="text-[10px] text-slate-500 mt-1.5 font-mono">Status: UNRECORDED_COVERAGE</span>
              </div>
            ) : (
              <div className="h-44 w-full min-w-0">
                <ResponsiveContainer width="100%" height="100%">
                  <LineChart data={chartData} margin={{ top: 5, right: 10, left: -10, bottom: 20 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.4} />
                    <XAxis
                      dataKey="formattedTime"
                      stroke="#94a3b8"
                      fontSize={9}
                      tickLine={false}
                      interval="preserveStartEnd"
                      angle={-25}
                      textAnchor="end"
                    />
                    <YAxis
                      stroke="#94a3b8"
                      fontSize={10}
                      domain={['auto', 'auto']}
                      tickFormatter={(v) => `${v.toFixed(1)}m`}
                    />
                    <Tooltip
                      contentStyle={{
                        backgroundColor: '#0f172a',
                        borderColor: '#334155',
                        borderRadius: '6px',
                        fontSize: '11px',
                      }}
                      formatter={(val: any) => [
                        val !== null ? `${Number(val).toFixed(3)} m` : 'Missing Telemetry',
                        'Koyna Reservoir Stage',
                      ]}
                    />
                    <Line
                      type="monotone"
                      dataKey="koyna"
                      stroke="#38bdf8"
                      strokeWidth={2}
                      dot={false}
                      connectNulls={false}
                      isAnimationActive={false}
                    />
                  </LineChart>
                </ResponsiveContainer>
              </div>
            )}
          </div>
          <div className="text-[10px] text-slate-400 mt-2 flex justify-between border-t border-slate-700/40 pt-1.5">
            <span>Reservoir Impoundment</span>
            <span>Lead: ~18–24h</span>
          </div>
        </div>

        {/* 3. Sangli Rainfall Network */}
        <div className="bg-slate-800/40 border border-slate-700/60 rounded-xl p-3.5 flex flex-col justify-between min-w-0">
          <div>
            <div className="flex items-center justify-between text-xs text-slate-300 mb-1">
              <div className="flex items-center space-x-1.5 min-w-0">
                <CloudRain className="w-4 h-4 text-indigo-400 shrink-0" />
                <span className="font-bold text-white truncate">SANGLI Point-Gauge Rainfall</span>
              </div>
              <span className="text-[10px] px-1.5 py-0.5 rounded bg-indigo-500/10 text-indigo-300 font-mono shrink-0">
                {validRainEvents.length > 0 ? `${validRainEvents.length} Rain Events` : 'DRY PERIOD'}
              </span>
            </div>
            <p className="text-[11px] text-slate-400 mb-2">
              Observed rainfall events and derived rolling precipitation features.
            </p>

            {validRainEvents.length === 0 ? (
              <div className="h-44 w-full flex flex-col items-center justify-center text-center p-3 bg-slate-900/60 rounded-lg border border-slate-700/50">
                <SunMedium className="w-7 h-7 text-amber-400 mb-2 shrink-0" />
                <span className="text-xs font-bold text-amber-300">Dry Weather Interval (Zero-Imputed)</span>
                <p className="text-[11px] text-slate-400 mt-1 max-w-xs leading-relaxed">
                  Zero positive rainfall events measured in this window. Consistent with IMD meteorological convention, dry intervals are zero-imputed (0.0 mm/h) for feature calculations.
                </p>
                <span className="text-[10px] text-slate-500 mt-1.5 font-mono">Effective Input: 0.0 mm/h</span>
              </div>
            ) : (
              <div className="h-44 w-full min-w-0">
                <ResponsiveContainer width="100%" height="100%">
                  <BarChart data={chartData} margin={{ top: 5, right: 10, left: -10, bottom: 20 }}>
                    <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.4} />
                    <XAxis
                      dataKey="formattedTime"
                      stroke="#94a3b8"
                      fontSize={9}
                      tickLine={false}
                      interval="preserveStartEnd"
                      angle={-25}
                      textAnchor="end"
                    />
                    <YAxis
                      stroke="#94a3b8"
                      fontSize={10}
                      domain={[0, 'auto']}
                      tickFormatter={(v) => `${v.toFixed(1)}mm`}
                    />
                    <Tooltip
                      contentStyle={{
                        backgroundColor: '#0f172a',
                        borderColor: '#334155',
                        borderRadius: '6px',
                        fontSize: '11px',
                      }}
                      formatter={(val: any) => [
                        val !== null ? `${Number(val).toFixed(1)} mm/h` : 'Zero-reporting (Dry)',
                        'Raw Measured Event Rain',
                      ]}
                    />
                    <Bar
                      dataKey="rain"
                      fill="#818cf8"
                      radius={[2, 2, 0, 0]}
                      isAnimationActive={false}
                    />
                  </BarChart>
                </ResponsiveContainer>
              </div>
            )}
          </div>
          <div className="text-[10px] text-slate-400 mt-2 flex justify-between border-t border-slate-700/40 pt-1.5">
            <span>SANGLI Point-Gauge Rainfall</span>
            <span>Raw vs Imputed</span>
          </div>
        </div>
      </div>
    </div>
  );
};
