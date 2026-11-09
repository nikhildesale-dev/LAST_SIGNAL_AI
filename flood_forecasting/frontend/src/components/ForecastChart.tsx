import React from 'react';
import {
  ResponsiveContainer,
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ReferenceLine,
} from 'recharts';
import type { TelemetryPoint, PredictResponse } from '../types/api';

interface ForecastChartProps {
  telemetry: TelemetryPoint[];
  prediction: PredictResponse | null;
  loading?: boolean;
}

interface ChartRow {
  timestamp: string;
  formattedTime: string;
  actual_stage: number | null;
  forecast_stage: number | null;
  future_ground_truth: number | null;
  marker_type?: 'CURRENT' | '+6H' | '+24H';
}

function parseSqlTimestamp(ts: string): Date {
  const parts = ts.trim().replace('T', ' ').split(/[- :]/);
  return new Date(
    parseInt(parts[0], 10),
    parseInt(parts[1], 10) - 1,
    parseInt(parts[2], 10),
    parseInt(parts[3] || '0', 10),
    parseInt(parts[4] || '0', 10),
    parseInt(parts[5] || '0', 10)
  );
}

function formatSqlTimestamp(d: Date): string {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  const h = String(d.getHours()).padStart(2, '0');
  const min = String(d.getMinutes()).padStart(2, '0');
  const s = String(d.getSeconds()).padStart(2, '0');
  return `${y}-${m}-${day} ${h}:${min}:${s}`;
}

function formatDisplayTime(d: Date, suffix?: string): string {
  const m = d.getMonth() + 1;
  const day = d.getDate();
  const h = String(d.getHours()).padStart(2, '0');
  const base = `${m}/${day} ${h}:00`;
  return suffix ? `${base} ${suffix}` : base;
}

export const ForecastChart: React.FC<ForecastChartProps> = ({ telemetry, prediction, loading }) => {
  const isAvailable = prediction?.prediction_available && prediction.forecast_plus_6h !== null;
  const currTimeStr = prediction?.prediction_timestamp;
  const currStage = prediction?.current_river_level_m;

  // Build a chronologically sorted map of rows
  const rowMap = new Map<string, ChartRow>();

  // 1. Ingest telemetry series
  telemetry.forEach((pt) => {
    const d = parseSqlTimestamp(pt.timestamp);
    const isPastOrPresent = !currTimeStr || pt.timestamp <= currTimeStr;

    rowMap.set(pt.timestamp, {
      timestamp: pt.timestamp,
      formattedTime: formatDisplayTime(d),
      actual_stage: isPastOrPresent ? pt.ankali_stage_m : null,
      forecast_stage: null,
      future_ground_truth: !isPastOrPresent ? pt.ankali_stage_m : null,
    });
  });

  // 2. Compute forecast timestamps (+6h and +24h)
  let currFormatted = '';
  let plus6Str = '';
  let plus24Str = '';

  if (currTimeStr && isAvailable && currStage !== null && currStage !== undefined) {
    const d0 = parseSqlTimestamp(currTimeStr);
    currFormatted = formatDisplayTime(d0);

    const d6 = new Date(d0.getTime() + 6 * 3600 * 1000);
    plus6Str = formatSqlTimestamp(d6);

    const d24 = new Date(d0.getTime() + 24 * 3600 * 1000);
    plus24Str = formatSqlTimestamp(d24);

    // Current observation point (origin of forecast line)
    const currRow = rowMap.get(currTimeStr);
    if (currRow) {
      currRow.forecast_stage = currStage;
      currRow.marker_type = 'CURRENT';
    } else {
      rowMap.set(currTimeStr, {
        timestamp: currTimeStr,
        formattedTime: formatDisplayTime(d0, '(Now)'),
        actual_stage: currStage,
        forecast_stage: currStage,
        future_ground_truth: null,
        marker_type: 'CURRENT',
      });
    }

    // +6h forecast point
    if (prediction.forecast_plus_6h !== null) {
      const row6 = rowMap.get(plus6Str);
      if (row6) {
        row6.forecast_stage = prediction.forecast_plus_6h;
        row6.formattedTime = formatDisplayTime(d6, '(+6h)');
        row6.marker_type = '+6H';
      } else {
        rowMap.set(plus6Str, {
          timestamp: plus6Str,
          formattedTime: formatDisplayTime(d6, '(+6h)'),
          actual_stage: null,
          forecast_stage: prediction.forecast_plus_6h,
          future_ground_truth: null,
          marker_type: '+6H',
        });
      }
    }

    // +24h forecast point
    if (prediction.forecast_plus_24h !== null) {
      const row24 = rowMap.get(plus24Str);
      if (row24) {
        row24.forecast_stage = prediction.forecast_plus_24h;
        row24.formattedTime = formatDisplayTime(d24, '(+24h)');
        row24.marker_type = '+24H';
      } else {
        rowMap.set(plus24Str, {
          timestamp: plus24Str,
          formattedTime: formatDisplayTime(d24, '(+24h)'),
          actual_stage: null,
          forecast_stage: prediction.forecast_plus_24h,
          future_ground_truth: null,
          marker_type: '+24H',
        });
      }
    }
  }

  // Sort chronologically
  const chartData = Array.from(rowMap.values()).sort((a, b) =>
    a.timestamp.localeCompare(b.timestamp)
  );

  // Compute dynamic domain bounds
  const allStages = chartData
    .flatMap((d) => [d.actual_stage, d.forecast_stage, d.future_ground_truth])
    .filter((v): v is number => v !== null && v !== undefined && !isNaN(v));

  const minStage = allStages.length > 0 ? Math.floor(Math.min(...allStages) * 10) / 10 - 0.2 : 525.0;
  const maxStage = allStages.length > 0 ? Math.ceil(Math.max(...allStages) * 10) / 10 + 0.4 : 532.0;

  return (
    <div className="bg-slate-900/90 border border-slate-800 rounded-xl p-3.5 sm:p-5 mb-6 shadow-lg min-w-0">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2 mb-4 pb-3 border-b border-slate-800">
        <div className="min-w-0">
          <div className="flex items-center space-x-2 flex-wrap">
            <h2 className="text-sm sm:text-base md:text-lg font-bold text-white tracking-wide">
              Ankali Bridge Stage Timeline & Forecasting Trajectory
            </h2>
            <span className="text-[10px] px-2 py-0.5 rounded bg-sky-500/20 text-sky-300 font-mono font-bold">
              Station 527-ANKALI
            </span>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">
            Solid line shows actual measured telemetry up to forecast time; dashed line shows +6h and +24h projections.
          </p>
        </div>
        <div className="flex items-center space-x-3 text-xs flex-wrap gap-y-1">
          <div className="flex items-center space-x-1.5">
            <span className="w-3 h-0.5 bg-cyan-400 inline-block" />
            <span className="text-slate-300">Measured Stage (&le; T)</span>
          </div>
          <div className="flex items-center space-x-1.5">
            <span className="w-3 h-0.5 bg-indigo-400 border-t-2 border-dashed border-indigo-400 inline-block" />
            <span className="text-indigo-300 font-semibold">Forecast (+6h, +24h)</span>
          </div>
          <div className="flex items-center space-x-1.5">
            <span className="w-3 h-0.5 bg-slate-500 border-t border-dotted border-slate-500 inline-block" />
            <span className="text-slate-500">Actual (&gt; T Reference)</span>
          </div>
        </div>
      </div>

      <div className="relative h-72 sm:h-96 w-full min-w-0">
        {loading && (
          <div className="absolute inset-0 bg-slate-950/60 backdrop-blur-xs flex items-center justify-center z-10 rounded-xl">
            <div className="flex items-center space-x-2 text-sky-400 text-xs sm:text-sm font-semibold bg-slate-900/90 px-4 py-2 rounded-lg border border-sky-500/30 shadow-lg">
              <span className="w-2 h-2 rounded-full bg-sky-400 animate-ping" />
              <span>Updating Forecast Projections...</span>
            </div>
          </div>
        )}
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={chartData} margin={{ top: 15, right: 15, left: -5, bottom: 25 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.4} />
            <XAxis
              dataKey="formattedTime"
              stroke="#94a3b8"
              fontSize={10}
              tickLine={false}
              interval="preserveStartEnd"
              angle={-30}
              textAnchor="end"
            />
            <YAxis
              domain={[minStage, maxStage]}
              stroke="#94a3b8"
              fontSize={10}
              tickFormatter={(v) => `${v.toFixed(1)}m`}
              tickLine={false}
            />
            <Tooltip
              contentStyle={{
                backgroundColor: '#0f172a',
                borderColor: '#334155',
                borderRadius: '8px',
                fontSize: '12px',
                color: '#f8fafc',
              }}
              formatter={(val: any, name: any) => {
                if (val === null || val === undefined) return ['Telemetry Missing', name];
                const stageStr = `${Number(val).toFixed(3)} m`;
                if (name === 'actual_stage') return [stageStr, 'Measured River Stage (Actual)'];
                if (name === 'forecast_stage') return [stageStr, 'Projected Stage (Forecast)'];
                return [stageStr, 'Subsequent Actual (Ground Truth)'];
              }}
              labelFormatter={(label) => `Time: ${label}`}
            />
            <Legend
              verticalAlign="top"
              height={36}
              formatter={(value) => (
                <span className="text-xs text-slate-300 font-medium">
                  {value === 'actual_stage'
                    ? 'Measured River Stage (Historical Observations \u2264 T)'
                    : value === 'forecast_stage'
                    ? 'Forecast Trajectory (+6h & +24h Projections)'
                    : 'Subsequent River Stage (Post-Forecast Ground Truth)'}
                </span>
              )}
            />

            {/* Vertical Marker for Prediction Timestamp */}
            {currFormatted && (
              <ReferenceLine
                x={currFormatted}
                stroke="#38bdf8"
                strokeDasharray="3 3"
                label={{
                  value: 'Forecast Time T',
                  fill: '#38bdf8',
                  fontSize: 10,
                  position: 'top',
                }}
              />
            )}

            {/* Indicative advisory stage guide */}
            <ReferenceLine
              y={530.0}
              stroke="#f59e0b"
              strokeDasharray="4 4"
              label={{
                value: 'Indicative Advisory Level (530.0m)',
                fill: '#f59e0b',
                fontSize: 10,
                position: 'insideTopRight',
              }}
            />

            {/* Historical measured actual stage (solid line up to T, breaks for dropouts) */}
            <Line
              type="monotone"
              dataKey="actual_stage"
              stroke="#06b6d4"
              strokeWidth={2.5}
              dot={{ r: 2, fill: '#06b6d4' }}
              activeDot={{ r: 5, fill: '#38bdf8' }}
              connectNulls={false}
              isAnimationActive={false}
              name="actual_stage"
            />

            {/* Subsequent Ground Truth after T (dotted reference) */}
            <Line
              type="monotone"
              dataKey="future_ground_truth"
              stroke="#64748b"
              strokeWidth={1.5}
              strokeDasharray="2 2"
              dot={false}
              connectNulls={false}
              isAnimationActive={false}
              name="future_ground_truth"
            />

            {/* Model forecast trajectory connecting Current -> +6h -> +24h */}
            <Line
              type="linear"
              dataKey="forecast_stage"
              stroke="#818cf8"
              strokeWidth={2.5}
              strokeDasharray="5 5"
              dot={{ r: 5, fill: '#6366f1', stroke: '#c7d2fe', strokeWidth: 2 }}
              activeDot={{ r: 7, fill: '#818cf8' }}
              connectNulls={true}
              isAnimationActive={false}
              name="forecast_stage"
            />
          </LineChart>
        </ResponsiveContainer>
      </div>

      <div className="mt-3 flex flex-col sm:flex-row sm:items-center sm:justify-between text-[11px] text-slate-400 border-t border-slate-800/60 pt-2 gap-1.5">
        <div className="flex items-center space-x-2 flex-wrap">
          <span className="font-semibold text-slate-300">Timeline Verification:</span>
          <span className="text-sky-300 font-mono">Current = {currTimeStr?.slice(5, 16) || 'N/A'}</span>
          <span>&bull;</span>
          <span className="text-indigo-300 font-mono">+6h = {plus6Str?.slice(5, 16) || 'N/A'}</span>
          <span>&bull;</span>
          <span className="text-indigo-300 font-mono">+24h = {plus24Str?.slice(5, 16) || 'N/A'}</span>
        </div>
        <span className="text-amber-400/90 font-medium">
          Horizontal advisory reference line is for contextual reference only and does not denote statutory flood evacuation.
        </span>
      </div>
    </div>
  );
};
