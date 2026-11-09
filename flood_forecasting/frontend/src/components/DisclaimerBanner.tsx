import React from 'react';
import { AlertTriangle, Info } from 'lucide-react';

export const DisclaimerBanner: React.FC = () => {
  return (
    <div className="bg-amber-950/40 border border-amber-600/30 rounded-xl p-3 sm:p-4 my-4 max-w-[1600px] mx-auto text-amber-200 min-w-0">
      <div className="flex items-start space-x-3 min-w-0">
        <AlertTriangle className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />
        <div className="text-xs sm:text-sm space-y-1 min-w-0 break-words">
          <p className="font-semibold text-amber-300">
            Operational Hydrological Disclaimer — Research & Stage Forecasting Model
          </p>
          <p className="text-amber-200/80 leading-relaxed">
            This dashboard predicts continuous river water stage (meters above datum) at Ankali Bridge. It is an algorithmic empirical model and{' '}
            <strong className="text-amber-100 font-bold">is NOT an official flood disaster warning or emergency evacuation alert</strong>.
            Statutory flood warnings and reservoir release mandates are issued exclusively by the Central Water Commission (CWC) and Maharashtra SDMA.
          </p>
          <div className="flex items-center space-x-1.5 text-xs text-amber-300/70 pt-1">
            <Info className="w-3.5 h-3.5 shrink-0" />
            <span>
              Telemetry Environment: Connected to verified Krishna River Basin audit pilot records. Real-time live sensor telemetry integration is currently simulated via verified historical series.
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};

