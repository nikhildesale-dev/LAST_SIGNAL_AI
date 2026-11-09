import React from 'react';
import { Activity, Waves, Cpu } from 'lucide-react';
import type { HealthResponse } from '../types/api';

interface HeaderProps {
  health: HealthResponse | null;
  modelVersion: string;
}

export const Header: React.FC<HeaderProps> = ({ health, modelVersion }) => {
  const isHealthy = health?.status === 'HEALTHY';

  return (
    <header className="bg-slate-900 border-b border-slate-800 px-3 py-3 sm:px-6">
      <div className="max-w-[1600px] mx-auto flex flex-col md:flex-row md:items-center md:justify-between gap-3">
        {/* Title and Station */}
        <div className="flex items-center space-x-3 min-w-0">
          <div className="p-2 sm:p-2.5 bg-sky-500/10 border border-sky-500/20 rounded-xl text-sky-400 shrink-0">
            <Waves className="w-5 h-5 sm:w-6 sm:h-6 animate-pulse" />
          </div>
          <div className="min-w-0">
            <div className="flex items-center space-x-2 flex-wrap">
              <h1 className="text-lg sm:text-xl md:text-2xl font-black tracking-tight text-white">
                LAST_SIGNAL_AI
              </h1>
              <span className="text-[11px] font-semibold px-2 py-0.5 rounded-full bg-sky-500/20 text-sky-300 border border-sky-500/30">
                v{modelVersion}
              </span>
            </div>
            <p className="text-[11px] sm:text-xs md:text-sm text-slate-400 truncate sm:whitespace-normal">
              Krishna River Basin Hydrological Monitoring & Forecast Service (Ankali Bridge Target)
            </p>
          </div>
        </div>

        {/* Backend Connectivity Status */}
        <div className="flex items-center space-x-3 text-xs sm:text-sm">
          <div className="flex items-center space-x-2 bg-slate-800/80 border border-slate-700/60 rounded-lg px-3 py-1.5">
            <Cpu className="w-4 h-4 text-slate-400" />
            <span className="text-slate-400">Backend API:</span>
            <div className="flex items-center space-x-1.5">
              <span
                className={`w-2 h-2 rounded-full ${
                  isHealthy ? 'bg-emerald-400 animate-pulse' : 'bg-rose-400'
                }`}
              />
              <span
                className={`font-semibold ${
                  isHealthy ? 'text-emerald-400' : 'text-rose-400'
                }`}
              >
                {health?.status || 'DISCONNECTED'}
              </span>
            </div>
          </div>

          <div className="hidden sm:flex items-center space-x-1 text-slate-400 bg-slate-800/50 border border-slate-700/40 rounded-lg px-2.5 py-1.5 text-xs">
            <Activity className="w-3.5 h-3.5 text-sky-400" />
            <span>Horizons: +6h / +24h</span>
          </div>
        </div>
      </div>
    </header>
  );
};
