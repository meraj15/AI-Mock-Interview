import React, { useEffect, useState } from 'react';
import { api } from '../api/client';
import { useFilter } from '../context/FilterContext';
import {
  Bot,
  Zap,
  Clock,
  AlertTriangle,
  Download,
  IndianRupee,
  Layers,
  Activity,
  Cpu,
  CheckCircle2,
  XCircle,
} from 'lucide-react';

export const AiUsagePage: React.FC = () => {
  const { dateRange, refreshKey } = useFilter();
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  const fetchAiUsage = async () => {
    setLoading(true);
    try {
      const res = await api.get(`/api/v1/admin/ai-usage?range=${dateRange}`);
      if (res.success) {
        setData(res.data);
      }
    } catch (err) {
      console.error('Failed to load AI usage metrics:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAiUsage();
  }, [dateRange, refreshKey]);

  const handleExportCsv = () => {
    api.downloadCsv(`/api/v1/admin/ai-usage/export?range=${dateRange}`, `ai_usage_${dateRange}.csv`);
  };

  return (
    <div className="space-y-6">
      {/* ── HEADER ────────────────────────────────────────────────────────── */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-white tracking-tight flex items-center gap-2">
            <Bot className="w-6 h-6 text-brand-400" />
            AI Usage & Observability
          </h2>
          <p className="text-xs text-slate-400 mt-0.5">
            Monitor Gemini AI token consumption, estimated inference cost in INR, latency percentiles (P50/P95), and failure categories.
          </p>
        </div>

        <button
          onClick={handleExportCsv}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-surface-800 hover:bg-surface-700 text-slate-200 border border-surface-700 text-xs font-medium transition self-start sm:self-auto"
        >
          <Download className="w-3.5 h-3.5 text-slate-400" />
          <span>Export AI Telemetry CSV</span>
        </button>
      </div>

      {/* ── TOP KPI METRIC CARDS ──────────────────────────────────────────── */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Total Requests Card */}
        <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-medium uppercase tracking-wider">AI Requests</span>
            <Activity className="w-4 h-4 text-brand-400" />
          </div>
          <div className="mt-2 text-2xl font-bold text-white">
            {loading ? '...' : (data?.requestsOverview?.selectedRange || 0).toLocaleString()}
          </div>
          <div className="mt-2 pt-2 border-t border-surface-800 flex justify-between text-[10px] text-slate-400">
            <span>Today: <strong className="text-slate-200">{data?.requestsOverview?.today || 0}</strong></span>
            <span>7d: <strong className="text-slate-200">{data?.requestsOverview?.last7Days || 0}</strong></span>
            <span>30d: <strong className="text-slate-200">{data?.requestsOverview?.last30Days || 0}</strong></span>
          </div>
        </div>

        {/* Token Consumption Card */}
        <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-medium uppercase tracking-wider">Token Consumption</span>
            <Cpu className="w-4 h-4 text-indigo-400" />
          </div>
          <div className="mt-2 text-2xl font-bold text-indigo-300">
            {loading ? '...' : (data?.tokenUsage?.totalTokens || 0).toLocaleString()}
          </div>
          <div className="mt-2 pt-2 border-t border-surface-800 flex justify-between text-[10px] text-slate-400">
            <span>Input: <strong className="text-slate-200">{(data?.tokenUsage?.inputTokens || 0).toLocaleString()}</strong></span>
            <span>Output: <strong className="text-slate-200">{(data?.tokenUsage?.outputTokens || 0).toLocaleString()}</strong></span>
          </div>
        </div>

        {/* Estimated AI Cost Card */}
        <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-medium uppercase tracking-wider">Estimated AI Cost</span>
            <IndianRupee className="w-4 h-4 text-emerald-400" />
          </div>
          <div className="mt-2 text-2xl font-bold text-emerald-400">
            {loading ? '...' : `₹${(data?.estimatedCost?.totalCostRupees || 0).toLocaleString('en-IN')}`}
          </div>
          <div className="mt-2 pt-2 border-t border-surface-800 flex justify-between text-[10px] text-slate-400">
            <span>Input: <strong className="text-slate-200">₹{data?.estimatedCost?.inputCostRupees || 0}</strong></span>
            <span>Output: <strong className="text-slate-200">₹{data?.estimatedCost?.outputCostRupees || 0}</strong></span>
          </div>
        </div>

        {/* Latency Percentiles Card */}
        <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-medium uppercase tracking-wider">Latency Profile</span>
            <Clock className="w-4 h-4 text-amber-400" />
          </div>
          <div className="mt-2 flex items-baseline gap-2">
            <span className="text-2xl font-bold text-white">
              {loading ? '...' : `${data?.latencyMetrics?.averageLatencyMs || 0}ms`}
            </span>
            <span className="text-xs text-slate-400 font-medium">avg</span>
          </div>
          <div className="mt-2 pt-2 border-t border-surface-800 flex justify-between text-[10px] text-slate-400">
            <span>P50: <strong className="text-emerald-400">{data?.latencyMetrics?.p50LatencyMs || 0}ms</strong></span>
            <span>P95: <strong className="text-amber-400">{data?.latencyMetrics?.p95LatencyMs || 0}ms</strong></span>
          </div>
        </div>
      </div>

      {/* ── PIPELINE LATENCY BREAKDOWN ────────────────────────────────────── */}
      <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 space-y-3">
        <div className="flex items-center justify-between">
          <h3 className="text-xs font-semibold text-slate-200 uppercase tracking-wider flex items-center gap-2">
            <Zap className="w-4 h-4 text-brand-400" />
            AI Execution Stage Breakdown (Averages)
          </h3>
          <span className="text-[11px] text-slate-400">
            End-to-end Avg: <strong className="text-white">{data?.latencyMetrics?.avgTotalLatencyMs || 0}ms</strong>
          </span>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-3 text-xs">
          <div className="bg-surface-800/60 p-3 rounded-lg border border-surface-700/40">
            <span className="text-slate-400 block text-[10px] uppercase font-medium">1. Prompt Construction</span>
            <span className="text-base font-bold text-white mt-1 block">
              {data?.latencyMetrics?.avgPromptBuildMs || 0} ms
            </span>
          </div>
          <div className="bg-surface-800/60 p-3 rounded-lg border border-surface-700/40">
            <span className="text-slate-400 block text-[10px] uppercase font-medium">2. Gemini Inference</span>
            <span className="text-base font-bold text-brand-300 mt-1 block">
              {data?.latencyMetrics?.avgAiLatencyMs || 0} ms
            </span>
          </div>
          <div className="bg-surface-800/60 p-3 rounded-lg border border-surface-700/40">
            <span className="text-slate-400 block text-[10px] uppercase font-medium">3. JSON Extraction & Parse</span>
            <span className="text-base font-bold text-white mt-1 block">
              {data?.latencyMetrics?.avgParseMs || 0} ms
            </span>
          </div>
          <div className="bg-surface-800/60 p-3 rounded-lg border border-surface-700/40">
            <span className="text-slate-400 block text-[10px] uppercase font-medium">4. Database Persistence</span>
            <span className="text-base font-bold text-white mt-1 block">
              {data?.latencyMetrics?.avgDbMs || 0} ms
            </span>
          </div>
        </div>
      </div>

      {/* ── OPERATIONS BREAKDOWN TABLE ────────────────────────────────────── */}
      <div className="bg-surface-900 border border-surface-800 rounded-xl overflow-hidden shadow-sm space-y-2">
        <div className="px-5 py-4 border-b border-surface-800 flex items-center justify-between">
          <h3 className="text-sm font-semibold text-white flex items-center gap-2">
            <Layers className="w-4 h-4 text-brand-400" />
            Operations Telemetry Breakdown
          </h3>
          <span className="text-xs text-slate-400">
            {data?.operations?.length || 0} AI Operations
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-surface-800/50 border-b border-surface-800 text-slate-400 uppercase tracking-wider font-semibold text-[10px]">
              <tr>
                <th className="py-3 px-4">Operation</th>
                <th className="py-3 px-4">Requests</th>
                <th className="py-3 px-4">Tokens (In / Out)</th>
                <th className="py-3 px-4">Total Tokens</th>
                <th className="py-3 px-4">Avg Latency</th>
                <th className="py-3 px-4">P95 Latency</th>
                <th className="py-3 px-4">Retries</th>
                <th className="py-3 px-4">Errors</th>
                <th className="py-3 px-4 text-right">Est. Cost</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-800/60">
              {loading ? (
                <tr>
                  <td colSpan={9} className="py-8 text-center text-slate-500">
                    Loading operations telemetry...
                  </td>
                </tr>
              ) : !data?.operations || data.operations.length === 0 ? (
                <tr>
                  <td colSpan={9} className="py-8 text-center text-slate-500">
                    No operations telemetry recorded for this period.
                  </td>
                </tr>
              ) : (
                data.operations.map((op: any) => (
                  <tr key={op.operation} className="hover:bg-surface-800/40 transition">
                    <td className="py-3 px-4 font-mono font-semibold text-brand-300">
                      {op.operation}
                    </td>
                    <td className="py-3 px-4 text-white font-medium">
                      {op.requests.toLocaleString()}
                    </td>
                    <td className="py-3 px-4 text-slate-400 text-[11px]">
                      {op.inputTokens.toLocaleString()} / {op.outputTokens.toLocaleString()}
                    </td>
                    <td className="py-3 px-4 text-slate-300 font-mono">
                      {op.totalTokens.toLocaleString()}
                    </td>
                    <td className="py-3 px-4 text-slate-300">
                      {op.avgLatencyMs} ms
                    </td>
                    <td className="py-3 px-4 text-amber-400 font-mono font-medium">
                      {op.p95LatencyMs} ms
                    </td>
                    <td className="py-3 px-4 text-slate-400">
                      {op.retriesCount}
                    </td>
                    <td className="py-3 px-4">
                      {op.errorCount > 0 ? (
                        <span className="px-2 py-0.5 rounded text-[10px] font-semibold bg-rose-500/10 text-rose-400 border border-rose-500/20">
                          {op.errorCount}
                        </span>
                      ) : (
                        <span className="text-slate-600 text-[11px]">0</span>
                      )}
                    </td>
                    <td className="py-3 px-4 text-right font-medium text-emerald-400">
                      ₹{op.estimatedCostRupees}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* ── ERROR & ANOMALY MONITORING ────────────────────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Error Category Breakdown */}
        <div className="p-5 rounded-xl bg-surface-900 border border-surface-800 space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-semibold text-white flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 text-rose-400" />
              Failure Categories
            </h3>
          </div>

          <div className="space-y-2">
            {!data?.errorCategories || data.errorCategories.length === 0 ? (
              <div className="text-xs text-slate-500 py-6 text-center">
                <CheckCircle2 className="w-6 h-6 text-emerald-400 mx-auto mb-1 opacity-80" />
                No errors recorded in this time range!
              </div>
            ) : (
              data.errorCategories.map((c: any) => (
                <div
                  key={c.category}
                  className="flex items-center justify-between p-2.5 rounded-lg bg-surface-800/50 border border-surface-700/50 text-xs"
                >
                  <span className="font-mono text-rose-300 font-medium">{c.category}</span>
                  <span className="px-2 py-0.5 rounded-full bg-rose-500/15 text-rose-400 font-bold text-[11px]">
                    {c.count}
                  </span>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Recent Errors Table */}
        <div className="lg:col-span-2 p-5 rounded-xl bg-surface-900 border border-surface-800 space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-semibold text-white flex items-center gap-2">
              <XCircle className="w-4 h-4 text-rose-400" />
              Recent AI Errors & Circuit Breaker Triggers
            </h3>
            <span className="text-xs text-slate-500">Last 20 failures</span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-surface-800/50 border-b border-surface-800 text-slate-400 uppercase tracking-wider font-semibold text-[10px]">
                <tr>
                  <th className="py-2 px-3">Time</th>
                  <th className="py-2 px-3">Operation</th>
                  <th className="py-2 px-3">Category</th>
                  <th className="py-2 px-3">Status</th>
                  <th className="py-2 px-3">Latency</th>
                  <th className="py-2 px-3">Details</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-surface-800/60 font-mono text-[11px]">
                {!data?.recentErrors || data.recentErrors.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-6 text-center text-slate-500 font-sans">
                      All AI operations running smoothly without errors.
                    </td>
                  </tr>
                ) : (
                  data.recentErrors.map((err: any) => (
                    <tr key={err.id} className="hover:bg-surface-800/40">
                      <td className="py-2 px-3 text-slate-400 whitespace-nowrap">
                        {new Date(err.timestamp).toLocaleTimeString()}
                      </td>
                      <td className="py-2 px-3 text-brand-300 font-semibold">{err.operation}</td>
                      <td className="py-2 px-3 text-rose-400">{err.errorCategory}</td>
                      <td className="py-2 px-3">
                        <span className="px-1.5 py-0.5 rounded text-[10px] bg-rose-500/20 text-rose-300 font-bold">
                          {err.httpStatus}
                        </span>
                      </td>
                      <td className="py-2 px-3 text-slate-400">{err.latencyMs}ms</td>
                      <td className="py-2 px-3 font-sans text-slate-300 truncate max-w-xs" title={err.errorMessage}>
                        {err.errorMessage}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  );
};
