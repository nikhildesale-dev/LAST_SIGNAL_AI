import React from 'react';
import { Play, RotateCcw, Check, Database } from 'lucide-react';
import type { ScenarioItem } from '../types/api';

interface ScenarioSelectorProps {
  scenarios: ScenarioItem[];
  selectedScenario: ScenarioItem | null;
  onSelectScenario: (scenario: ScenarioItem) => void;
  onRunForecast: () => void;
  loading: boolean;
}

export const ScenarioSelector: React.FC<ScenarioSelectorProps> = ({
  scenarios,
  selectedScenario,
  onSelectScenario,
  onRunForecast,
  loading,
}) => {
  return (
    <div className="bg-slate-900/90 border border-slate-800 rounded-xl p-4 sm:p-5 mb-6 shadow-lg">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 pb-3 border-b border-slate-800">
        <div>
          <div className="flex items-center space-x-2">
            <Database className="w-5 h-5 text-sky-400" />
            <h2 className="text-base sm:text-lg font-bold text-white tracking-wide">
              Historical Episode Replay & Benchmark Audits
            </h2>
          </div>
          <p className="text-xs text-slate-400 mt-0.5">
            Select verified Krishna Basin hydrological episodes to evaluate dual-regime dispatch and sensor-failure defenses.
          </p>
        </div>
        <button
          onClick={onRunForecast}
          disabled={loading}
          className="flex items-center justify-center space-x-2 px-4 py-2 rounded-lg bg-sky-600 hover:bg-sky-500 disabled:opacity-50 text-white font-semibold text-xs sm:text-sm transition-all shadow-md shadow-sky-950 cursor-pointer"
        >
          {loading ? (
            <RotateCcw className="w-4 h-4 animate-spin" />
          ) : (
            <Play className="w-4 h-4 fill-current" />
          )}
          <span>{loading ? 'Evaluating...' : 'Dispatch Forecast'}</span>
        </button>
      </div>

      <div className="mt-4 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-2.5">
        {scenarios.map((sc) => {
          const isSelected = selectedScenario?.id === sc.id;
          let catBadge = 'bg-slate-800 text-slate-300 border-slate-700';
          if (sc.category === 'BASEFLOW') catBadge = 'bg-emerald-500/10 text-emerald-300 border-emerald-500/30';
          if (sc.category === 'SURGE') catBadge = 'bg-amber-500/10 text-amber-300 border-amber-500/30';
          if (sc.category === 'STALE_FAULT') catBadge = 'bg-rose-500/10 text-rose-300 border-rose-500/30';
          if (sc.category === 'PLATEAU_WARNING') catBadge = 'bg-orange-500/10 text-orange-300 border-orange-500/30';
          if (sc.category === 'DROPOUT') catBadge = 'bg-purple-500/10 text-purple-300 border-purple-500/30';

          return (
            <button
              key={sc.id}
              onClick={() => onSelectScenario(sc)}
              className={`text-left p-2.5 sm:p-3 rounded-lg border transition-all cursor-pointer flex flex-col justify-between min-w-0 ${
                isSelected
                  ? 'bg-sky-950/40 border-sky-500 ring-1 ring-sky-500/50'
                  : 'bg-slate-800/40 border-slate-800 hover:border-slate-700 hover:bg-slate-800/80'
              }`}
            >
              <div className="min-w-0">
                <div className="flex items-center justify-between mb-1.5">
                  <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded border truncate ${catBadge}`}>
                    {sc.category}
                  </span>
                  {isSelected && <Check className="w-3.5 h-3.5 text-sky-400 shrink-0" />}
                </div>
                <div className="font-bold text-xs text-white truncate">{sc.name}</div>
                <div className="text-[11px] text-slate-400 mt-1 line-clamp-2 leading-relaxed break-words">
                  {sc.description}
                </div>
              </div>
              <div className="text-[10px] font-mono text-slate-500 mt-2 pt-1 border-t border-slate-800/60 truncate">
                {sc.prediction_timestamp}
              </div>
            </button>
          );
        })}
      </div>
    </div>
  );
};
