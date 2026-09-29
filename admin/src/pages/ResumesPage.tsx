import React, { useEffect, useState } from 'react';
import { api } from '../api/client';
import { useFilter } from '../context/FilterContext';
import {
  FileText,
  CheckCircle2,
  XCircle,
  Clock,
  Percent,
  AlertTriangle,
  UploadCloud,
  FileCheck,
  FileX,
  FileSpreadsheet,
} from 'lucide-react';

export const ResumesPage: React.FC = () => {
  const { dateRange, refreshKey } = useFilter();
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  const fetchResumes = async () => {
    setLoading(true);
    try {
      const res = await api.get(`/api/v1/admin/resumes?range=${dateRange}`);
      if (res.success) {
        setData(res.data);
      }
    } catch (err) {
      console.error('Failed to load resume analytics:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchResumes();
  }, [dateRange, refreshKey]);

  return (
    <div className="space-y-6">
      {/* ── HEADER ────────────────────────────────────────────────────────── */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-white tracking-tight flex items-center gap-2">
            <FileText className="w-6 h-6 text-brand-400" />
            Resume Parsing Analytics
          </h2>
          <p className="text-xs text-slate-400 mt-0.5">
            Monitor candidate resume uploads, PDF extraction success rates, parse durations, and extraction error reasons.
          </p>
        </div>
      </div>

      {/* ── METRIC CARDS ──────────────────────────────────────────────────── */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-3">
        {/* Total Uploads */}
        <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-medium uppercase tracking-wider">Total Uploads</span>
            <UploadCloud className="w-4 h-4 text-brand-400" />
          </div>
          <div className="mt-2 text-2xl font-bold text-white">
            {loading ? '...' : (data?.totalUploads || 0).toLocaleString()}
          </div>
          <span className="text-[10px] text-slate-500 mt-1">Uploaded resumes</span>
        </div>

        {/* Successful Parses */}
        <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-medium uppercase tracking-wider">Successful</span>
            <CheckCircle2 className="w-4 h-4 text-emerald-400" />
          </div>
          <div className="mt-2 text-2xl font-bold text-emerald-400">
            {loading ? '...' : (data?.successfulParses || 0).toLocaleString()}
          </div>
          <span className="text-[10px] text-slate-500 mt-1">Parsed & indexed</span>
        </div>

        {/* Failed Parses */}
        <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-medium uppercase tracking-wider">Failed</span>
            <XCircle className="w-4 h-4 text-rose-400" />
          </div>
          <div className="mt-2 text-2xl font-bold text-rose-400">
            {loading ? '...' : (data?.failedParses || 0).toLocaleString()}
          </div>
          <span className="text-[10px] text-slate-500 mt-1">Corrupted / Timeouts</span>
        </div>

        {/* Success Rate */}
        <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-medium uppercase tracking-wider">Success Rate</span>
            <Percent className="w-4 h-4 text-brand-400" />
          </div>
          <div className="mt-2 text-2xl font-bold text-white">
            {loading ? '...' : `${data?.successRatePercent ?? 100}%`}
          </div>
          <span className="text-[10px] text-slate-500 mt-1">Parsing reliability</span>
        </div>

        {/* Average Duration */}
        <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-medium uppercase tracking-wider">Avg Duration</span>
            <Clock className="w-4 h-4 text-amber-400" />
          </div>
          <div className="mt-2 text-2xl font-bold text-amber-300">
            {loading ? '...' : `${data?.averageParsingTimeMs || 0}ms`}
          </div>
          <span className="text-[10px] text-slate-500 mt-1">Extraction pipeline</span>
        </div>
      </div>

      {/* ── FAILURE REASONS BREAKDOWN ─────────────────────────────────────── */}
      <div className="p-5 rounded-xl bg-surface-900 border border-surface-800 space-y-4">
        <h3 className="text-sm font-semibold text-white flex items-center gap-2">
          <AlertTriangle className="w-4 h-4 text-rose-400" />
          Failure Categories & Diagnostic Reasons
        </h3>

        {!data?.failureReasons || data.failureReasons.length === 0 ? (
          <div className="p-4 rounded-lg bg-surface-800/40 border border-surface-700/40 text-xs text-slate-400 flex items-center gap-2">
            <CheckCircle2 className="w-4 h-4 text-emerald-400 flex-shrink-0" />
            <span>Zero parsing errors recorded for the selected date range. All candidate resumes parsed successfully.</span>
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
            {data.failureReasons.map((f: any) => (
              <div
                key={f.reason}
                className="p-3 rounded-lg bg-surface-800/60 border border-surface-700/50 flex items-center justify-between"
              >
                <div className="truncate pr-2">
                  <div className="text-xs font-mono text-rose-300 truncate font-medium">
                    {f.reason}
                  </div>
                  <div className="text-[10px] text-slate-500 mt-0.5">Parse failure</div>
                </div>
                <span className="px-2 py-0.5 rounded-full bg-rose-500/15 text-rose-400 text-xs font-bold">
                  {f.count}
                </span>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* ── RECENT UPLOADS TABLE ──────────────────────────────────────────── */}
      <div className="bg-surface-900 border border-surface-800 rounded-xl overflow-hidden shadow-sm space-y-2">
        <div className="px-5 py-4 border-b border-surface-800 flex items-center justify-between">
          <h3 className="text-sm font-semibold text-white flex items-center gap-2">
            <FileSpreadsheet className="w-4 h-4 text-brand-400" />
            Recent Candidate Resume Uploads
          </h3>
          <span className="text-xs text-slate-400">
            Last 20 uploads
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-surface-800/50 border-b border-surface-800 text-slate-400 uppercase tracking-wider font-semibold text-[10px]">
              <tr>
                <th className="py-3 px-4">File Name</th>
                <th className="py-3 px-4">User ID</th>
                <th className="py-3 px-4">Size</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4">Duration</th>
                <th className="py-3 px-4">Error Diagnostics</th>
                <th className="py-3 px-4">Uploaded At</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-800/60">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-slate-500">
                    Loading resume upload records...
                  </td>
                </tr>
              ) : !data?.recentUploads || data.recentUploads.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-slate-500">
                    No resume uploads recorded yet.
                  </td>
                </tr>
              ) : (
                data.recentUploads.map((log: any) => {
                  const isSuccess = log.status === 'SUCCESS';
                  return (
                    <tr key={log.id} className="hover:bg-surface-800/40 transition">
                      <td className="py-3 px-4 font-medium text-slate-200 flex items-center gap-2">
                        {isSuccess ? (
                          <FileCheck className="w-4 h-4 text-emerald-400 flex-shrink-0" />
                        ) : (
                          <FileX className="w-4 h-4 text-rose-400 flex-shrink-0" />
                        )}
                        <span className="truncate max-w-[200px]" title={log.fileName}>
                          {log.fileName}
                        </span>
                      </td>
                      <td className="py-3 px-4 font-mono text-[11px] text-slate-400">
                        {log.userId ? `${log.userId.substring(0, 10)}...` : 'Anonymous'}
                      </td>
                      <td className="py-3 px-4 text-slate-300">
                        {log.fileSizeKb ? `${log.fileSizeKb} KB` : 'N/A'}
                      </td>
                      <td className="py-3 px-4">
                        <span
                          className={`inline-flex items-center gap-1 px-2 py-0.5 rounded text-[11px] font-semibold ${
                            isSuccess
                              ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                              : 'bg-rose-500/10 text-rose-400 border border-rose-500/20'
                          }`}
                        >
                          {isSuccess ? 'SUCCESS' : 'FAILED'}
                        </span>
                      </td>
                      <td className="py-3 px-4 text-slate-300 font-mono text-[11px]">
                        {log.durationMs ? `${log.durationMs} ms` : 'N/A'}
                      </td>
                      <td className="py-3 px-4 text-slate-400 max-w-xs truncate" title={log.errorReason || 'None'}>
                        {log.errorReason ? (
                          <span className="text-rose-400 font-mono text-[11px]">{log.errorReason}</span>
                        ) : (
                          <span className="text-slate-600">-</span>
                        )}
                      </td>
                      <td className="py-3 px-4 text-slate-400 text-[11px] whitespace-nowrap">
                        {new Date(log.createdAt).toLocaleString()}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
