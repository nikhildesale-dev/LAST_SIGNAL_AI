import React, { useRef, useState } from 'react';
import {
  UploadCloud,
  FileText,
  Download,
  AlertCircle,
  CheckCircle2,
  AlertTriangle,
  Play,
  RotateCcw,
  Sparkles,
  Calendar,
} from 'lucide-react';
import type { CsvValidationResponse } from '../types/api';
import {
  validateCsv,
  validateCsvFile,
  predictCustomCsv,
  CSV_BLANK_TEMPLATE_URL,
  CSV_SAMPLE_TEMPLATE_URL,
} from '../services/api';

interface CustomCsvPanelProps {
  onPredictionSuccess: (csvPred: any) => void;
  onClearPrediction: () => void;
  loading: boolean;
  setLoading: (l: boolean) => void;
}

export const CustomCsvPanel: React.FC<CustomCsvPanelProps> = ({
  onPredictionSuccess,
  onClearPrediction,
  loading,
  setLoading,
}) => {
  const [csvContent, setCsvContent] = useState<string | null>(null);
  const [filename, setFilename] = useState<string>('');
  const [validation, setValidation] = useState<CsvValidationResponse | null>(null);
  const [selectedTimestamp, setSelectedTimestamp] = useState<string>('');
  const [validating, setValidating] = useState<boolean>(false);
  const [uploadError, setUploadError] = useState<string | null>(null);

  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleProcessCsvText = async (text: string, name: string) => {
    try {
      setValidating(true);
      setUploadError(null);
      onClearPrediction();

      const val = await validateCsv(text, name);
      setCsvContent(text);
      setFilename(name);
      setValidation(val);

      if (val.is_valid && val.available_timestamps.length > 0) {
        // Default to the first timestamp with full history, or the latest available timestamp
        const defaultTs =
          val.timestamps_with_sufficient_history.length > 0
            ? val.timestamps_with_sufficient_history[val.timestamps_with_sufficient_history.length - 1]
            : val.available_timestamps[val.available_timestamps.length - 1];
        setSelectedTimestamp(defaultTs);
      } else {
        setSelectedTimestamp('');
      }
    } catch (err: any) {
      setUploadError(err.message || 'Failed to parse and validate CSV file.');
      setValidation(null);
    } finally {
      setValidating(false);
    }
  };

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    try {
      setValidating(true);
      setUploadError(null);
      onClearPrediction();

      // Read text content for local state and prediction dispatch
      const text = await file.text();
      setCsvContent(text);
      setFilename(file.name);

      // Validate using direct FormData multipart upload (browser sets boundary)
      const val = await validateCsvFile(file);
      setValidation(val);

      if (val.is_valid && val.available_timestamps.length > 0) {
        const defaultTs =
          val.timestamps_with_sufficient_history.length > 0
            ? val.timestamps_with_sufficient_history[val.timestamps_with_sufficient_history.length - 1]
            : val.available_timestamps[val.available_timestamps.length - 1];
        setSelectedTimestamp(defaultTs);
      } else {
        setSelectedTimestamp('');
      }
    } catch (err: any) {
      setUploadError(err.message || 'Failed to parse and validate CSV file.');
      setValidation(null);
    } finally {
      setValidating(false);
    }
  };

  const handleLoadSample = async () => {
    try {
      setValidating(true);
      setUploadError(null);
      const resp = await fetch(CSV_SAMPLE_TEMPLATE_URL);
      if (!resp.ok) {
        throw new Error(`Failed to download sample pilot template: HTTP ${resp.status}`);
      }
      const text = await resp.text();
      await handleProcessCsvText(text, 'sample_historical_telemetry.csv');
    } catch (err: any) {
      if (err.name === 'TypeError' || err.message === 'Failed to fetch') {
        setUploadError('Unable to connect to backend server (http://127.0.0.1:8000). Please verify FastAPI is running.');
      } else {
        setUploadError(err.message || 'Error loading sample telemetry.');
      }
    } finally {
      setValidating(false);
    }
  };

  const handleRunPrediction = async () => {
    if (!csvContent || !selectedTimestamp) return;

    try {
      setLoading(true);
      setUploadError(null);
      onClearPrediction();

      const predResponse = await predictCustomCsv(csvContent, selectedTimestamp, filename);
      onPredictionSuccess(predResponse);
    } catch (err: any) {
      setUploadError(err.message || 'Failed to generate prediction from CSV.');
    } finally {
      setLoading(false);
    }
  };

  const handleClear = () => {
    setCsvContent(null);
    setFilename('');
    setValidation(null);
    setSelectedTimestamp('');
    setUploadError(null);
    onClearPrediction();
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  return (
    <div className="bg-slate-900/90 border border-slate-800 rounded-xl p-4 sm:p-5 mb-6 shadow-lg">
      {/* Header & Templates Bar */}
      <div className="flex flex-col lg:flex-row lg:items-center lg:justify-between gap-3 pb-4 border-b border-slate-800">
        <div>
          <div className="flex items-center space-x-2">
            <UploadCloud className="w-5 h-5 text-sky-400" />
            <h2 className="text-base sm:text-lg font-bold text-white tracking-wide">
              Custom CSV Telemetry Ingestion & Causal Prediction
            </h2>
          </div>
          <p className="text-xs text-slate-400 mt-1 max-w-2xl leading-relaxed">
            Upload custom multi-station Krishna Basin observations. The pipeline validates schemas, checks sensor flatlines,
            computes 15 causal features strictly &le; T, and evaluates dual-regime dispatch.
          </p>
        </div>

        {/* Action Buttons: Blank template, Sample template, Load Sample */}
        <div className="flex items-center flex-wrap gap-2 text-xs">
          <a
            href={CSV_BLANK_TEMPLATE_URL}
            download="LAST_SIGNAL_AI_blank_telemetry_template.csv"
            className="flex items-center space-x-1 px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 font-medium transition-colors"
          >
            <Download className="w-3.5 h-3.5 text-sky-400" />
            <span>Blank Template</span>
          </a>

          <a
            href={CSV_SAMPLE_TEMPLATE_URL}
            download="LAST_SIGNAL_AI_sample_historical_telemetry.csv"
            className="flex items-center space-x-1 px-3 py-1.5 rounded-lg bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 font-medium transition-colors"
          >
            <Download className="w-3.5 h-3.5 text-amber-400" />
            <span>Sample Pilot CSV</span>
          </a>

          <button
            onClick={handleLoadSample}
            disabled={validating || loading}
            className="flex items-center space-x-1.5 px-3 py-1.5 rounded-lg bg-sky-950/80 hover:bg-sky-900/80 text-sky-300 border border-sky-500/40 font-semibold transition-all cursor-pointer shadow-sm"
          >
            <Sparkles className="w-3.5 h-3.5 text-sky-400" />
            <span>{validating ? 'Loading Pilot...' : '1-Click Sample Telemetry'}</span>
          </button>
        </div>
      </div>

      {/* Error alert banner */}
      {uploadError && (
        <div className="mt-4 p-3.5 bg-rose-950/60 border border-rose-600/50 rounded-lg flex items-center space-x-2 text-rose-200 text-xs">
          <AlertCircle className="w-4 h-4 text-rose-400 shrink-0" />
          <span>{uploadError}</span>
        </div>
      )}

      {/* Upload Drop Zone if no CSV uploaded */}
      {!validation ? (
        <div className="mt-4">
          <label className="flex flex-col items-center justify-center p-6 sm:p-8 border-2 border-dashed border-slate-700/80 hover:border-sky-500/60 rounded-xl bg-slate-950/40 hover:bg-slate-950/60 cursor-pointer transition-all text-center">
            <input
              ref={fileInputRef}
              type="file"
              accept=".csv"
              onChange={handleFileChange}
              className="hidden"
            />
            <FileText className="w-10 h-10 text-sky-400/80 mb-2" />
            <span className="text-sm font-semibold text-white">
              Click to select or drag and drop a telemetry CSV
            </span>
            <span className="text-xs text-slate-400 mt-1">
              Required columns: timestamp, ankali_stage_m, shigaon_stage_m, koyna_stage_m, sangli_rainfall_mm, rainfall_status
            </span>
            <div className="mt-3 inline-flex items-center space-x-1.5 px-3 py-1 bg-slate-800 text-sky-300 rounded text-xs border border-slate-700">
              <span>Standard 1-hour temporal resolution recommended</span>
            </div>
          </label>
        </div>
      ) : (
        <div className="mt-4 space-y-4">
          {/* File Meta & Validation Badge */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between bg-slate-950/50 border border-slate-800 rounded-lg p-3 gap-2">
            <div className="flex items-center space-x-2.5 min-w-0">
              <FileText className="w-5 h-5 text-sky-400 shrink-0" />
              <div className="min-w-0">
                <div className="font-bold text-xs sm:text-sm text-white truncate">{filename}</div>
                <div className="text-[11px] text-slate-400">
                  {validation.total_rows} total rows &bull; {validation.start_timestamp} to {validation.end_timestamp}
                </div>
              </div>
            </div>

            <div className="flex items-center space-x-2 shrink-0">
              {validation.is_valid ? (
                <span className="flex items-center space-x-1 px-2.5 py-1 rounded bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 text-xs font-bold">
                  <CheckCircle2 className="w-3.5 h-3.5" />
                  <span>Validation Passed</span>
                </span>
              ) : (
                <span className="flex items-center space-x-1 px-2.5 py-1 rounded bg-rose-500/20 text-rose-300 border border-rose-500/30 text-xs font-bold">
                  <AlertCircle className="w-3.5 h-3.5" />
                  <span>Validation Errors</span>
                </span>
              )}
              <button
                onClick={handleClear}
                className="px-2.5 py-1 rounded bg-slate-800 hover:bg-slate-700 text-slate-300 text-xs transition-colors cursor-pointer"
              >
                Clear
              </button>
            </div>
          </div>

          {/* Validation Errors & Warnings */}
          {validation.validation_errors.length > 0 && (
            <div className="p-3 bg-rose-950/40 border border-rose-700/50 rounded-lg text-xs text-rose-200 space-y-1">
              <div className="font-bold text-rose-400 flex items-center space-x-1.5">
                <AlertCircle className="w-4 h-4 shrink-0" />
                <span>Validation Errors:</span>
              </div>
              <ul className="list-disc list-inside space-y-0.5 text-[11px] text-rose-300 pl-1">
                {validation.validation_errors.map((e, idx) => (
                  <li key={idx}>{e}</li>
                ))}
              </ul>
            </div>
          )}

          {validation.validation_warnings.length > 0 && (
            <div className="p-3 bg-amber-950/40 border border-amber-700/50 rounded-lg text-xs text-amber-200 space-y-1">
              <div className="font-bold text-amber-400 flex items-center space-x-1.5">
                <AlertTriangle className="w-4 h-4 shrink-0" />
                <span>Advisory Telemetry Notices:</span>
              </div>
              <ul className="list-disc list-inside space-y-0.5 text-[11px] text-amber-300 pl-1">
                {validation.validation_warnings.map((w, idx) => (
                  <li key={idx}>{w}</li>
                ))}
              </ul>
            </div>
          )}

          {/* Telemetry Availability & Missing Summary Cards */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-2.5">
            {Object.entries(validation.station_stats).map(([col, st]) => {
              const hasMissing = st.missing_count > 0;
              return (
                <div key={col} className="bg-slate-800/40 border border-slate-800 rounded-lg p-2.5 min-w-0">
                  <div className="text-[11px] font-semibold text-slate-300 truncate">{st.station_name}</div>
                  <div className="mt-1 flex items-baseline justify-between">
                    <span className="text-xs font-mono text-slate-400">
                      {st.valid_count}/{st.total_records} valid
                    </span>
                    <span
                      className={`text-[10px] font-bold px-1.5 py-0.2 rounded border ${
                        hasMissing
                          ? 'bg-amber-500/10 text-amber-400 border-amber-500/30'
                          : 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30'
                      }`}
                    >
                      {hasMissing ? `${st.missing_pct}% Missing` : '100% Intact'}
                    </span>
                  </div>
                  <div className="text-[10px] text-slate-500 mt-1 truncate">
                    Range:{' '}
                    {st.min_val !== null ? `${st.min_val} to ${st.max_val} ${st.unit}` : 'No valid readings'}
                  </div>
                </div>
              );
            })}
          </div>

          {/* Rainfall Status Distribution Summary */}
          {Object.keys(validation.rainfall_status_counts).length > 0 && (
            <div className="flex items-center space-x-2 text-[11px] text-slate-400 bg-slate-950/30 p-2 rounded border border-slate-800/80 flex-wrap gap-y-1">
              <span className="font-semibold text-slate-300">Rainfall Status Breakdown:</span>
              {Object.entries(validation.rainfall_status_counts).map(([stat, cnt]) => (
                <span key={stat} className="px-1.5 py-0.5 rounded bg-slate-800 text-slate-300 font-mono text-[10px]">
                  {stat}: <strong>{cnt}</strong>
                </span>
              ))}
            </div>
          )}

          {/* Forecast Issuance Timestamp Selector & Execution Controls */}
          {validation.is_valid && (
            <div className="bg-slate-950/70 border border-sky-900/50 rounded-xl p-3 sm:p-4 flex flex-col md:flex-row md:items-center justify-between gap-3">
              <div className="flex-1 min-w-0">
                <label className="block text-xs font-semibold text-slate-200 mb-1 flex items-center space-x-1.5">
                  <Calendar className="w-3.5 h-3.5 text-sky-400" />
                  <span>Forecast Issuance Timestamp (T):</span>
                </label>
                <div className="flex items-center space-x-2">
                  <select
                    value={selectedTimestamp}
                    onChange={(e) => setSelectedTimestamp(e.target.value)}
                    className="bg-slate-900 border border-slate-700 text-white text-xs rounded-lg px-3 py-2 focus:ring-1 focus:ring-sky-500 focus:border-sky-500 outline-none w-full max-w-md font-mono cursor-pointer"
                  >
                    {validation.available_timestamps.map((ts, idx) => {
                      const isFull = validation.timestamps_with_sufficient_history.includes(ts);
                      return (
                        <option key={ts} value={ts}>
                          {ts} {isFull ? '(>= 24h Full Lookback)' : `(Lookback: ${idx}h)`}
                        </option>
                      );
                    })}
                  </select>
                </div>
                <div className="text-[11px] text-slate-400 mt-1">
                  Strictly causal: All observations after this timestamp are withheld from the model.
                </div>
              </div>

              <div className="flex items-center space-x-2 shrink-0">
                <button
                  onClick={handleRunPrediction}
                  disabled={loading || !selectedTimestamp}
                  className="flex items-center justify-center space-x-2 px-5 py-2.5 rounded-lg bg-sky-600 hover:bg-sky-500 disabled:opacity-50 text-white font-semibold text-xs sm:text-sm transition-all shadow-md shadow-sky-950 cursor-pointer"
                >
                  {loading ? (
                    <RotateCcw className="w-4 h-4 animate-spin" />
                  ) : (
                    <Play className="w-4 h-4 fill-current" />
                  )}
                  <span>{loading ? 'Evaluating Model...' : 'Generate Prediction'}</span>
                </button>
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
};
