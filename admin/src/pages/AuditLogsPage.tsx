import React, { useEffect, useState } from 'react';
import { api } from '../api/client';
import { useFilter } from '../context/FilterContext';
import {
  ShieldAlert,
  ChevronLeft,
  ChevronRight,
  Eye,
  X,
  ShieldCheck,
} from 'lucide-react';

export const AuditLogsPage: React.FC = () => {
  const { refreshKey } = useFilter();
  const [logs, setLogs] = useState<any[]>([]);
  const [pagination, setPagination] = useState({ page: 1, limit: 20, total: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);

  // Filters
  const [action, setAction] = useState('ALL');
  const [targetType, setTargetType] = useState('ALL');

  // Selected Log Diff Modal
  const [selectedLog, setSelectedLog] = useState<any>(null);

  const fetchAuditLogs = async () => {
    setLoading(true);
    try {
      const q = new URLSearchParams({
        page: pagination.page.toString(),
        limit: pagination.limit.toString(),
        action,
        targetType,
      });

      const res = await api.get(`/api/v1/admin/audit-logs?${q.toString()}`);
      if (res.success) {
        setLogs(res.logs);
        setPagination(res.pagination);
      }
    } catch (err) {
      console.error('Failed to load audit logs:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAuditLogs();
  }, [pagination.page, action, targetType, refreshKey]);

  const getActionBadge = (act: string) => {
    if (act.includes('SUSPEND') || act.includes('CANCEL') || act.includes('REVOKE')) {
      return (
        <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-rose-500/10 text-rose-400 border border-rose-500/20 font-mono">
          {act}
        </span>
      );
    }
    if (act.includes('GRANT') || act.includes('RESTORE')) {
      return (
        <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-mono">
          {act}
        </span>
      );
    }
    return (
      <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-brand-500/10 text-brand-300 border border-brand-500/20 font-mono">
        {act}
      </span>
    );
  };

  return (
    <div className="space-y-6">
      {/* ── HEADER ────────────────────────────────────────────────────────── */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-white tracking-tight flex items-center gap-2">
            <ShieldAlert className="w-6 h-6 text-brand-400" />
            Administrative Audit Trail
          </h2>
          <p className="text-xs text-slate-400 mt-0.5">
            Immutable security log recording all administrator operations, suspensions, entitlement changes, and state mutations.
          </p>
        </div>
      </div>

      {/* ── FILTERS BAR ───────────────────────────────────────────────────── */}
      <div className="flex flex-wrap items-center gap-3">
        {/* Action Filter */}
        <div className="flex items-center gap-2 bg-surface-900 border border-surface-800 rounded-lg px-3 py-1.5 text-xs">
          <span className="text-slate-400 font-medium">Action:</span>
          <select
            value={action}
            onChange={(e) => {
              setAction(e.target.value);
              setPagination((p) => ({ ...p, page: 1 }));
            }}
            className="bg-transparent text-slate-200 focus:outline-none cursor-pointer"
          >
            <option value="ALL" className="bg-surface-900">All Actions</option>
            <option value="USER_SUSPEND" className="bg-surface-900">USER_SUSPEND</option>
            <option value="USER_RESTORE" className="bg-surface-900">USER_RESTORE</option>
            <option value="ENTITLEMENT_GRANT" className="bg-surface-900">ENTITLEMENT_GRANT</option>
            <option value="ENTITLEMENT_REVOKE" className="bg-surface-900">ENTITLEMENT_REVOKE</option>
            <option value="SUBSCRIPTION_CANCEL" className="bg-surface-900">SUBSCRIPTION_CANCEL</option>
            <option value="PLAN_UPDATE" className="bg-surface-900">PLAN_UPDATE</option>
            <option value="SETTINGS_UPDATE" className="bg-surface-900">SETTINGS_UPDATE</option>
          </select>
        </div>

        {/* Target Type Filter */}
        <div className="flex items-center gap-2 bg-surface-900 border border-surface-800 rounded-lg px-3 py-1.5 text-xs">
          <span className="text-slate-400 font-medium">Target Type:</span>
          <select
            value={targetType}
            onChange={(e) => {
              setTargetType(e.target.value);
              setPagination((p) => ({ ...p, page: 1 }));
            }}
            className="bg-transparent text-slate-200 focus:outline-none cursor-pointer"
          >
            <option value="ALL" className="bg-surface-900">All Targets</option>
            <option value="USER" className="bg-surface-900">USER</option>
            <option value="SUBSCRIPTION" className="bg-surface-900">SUBSCRIPTION</option>
            <option value="PLAN" className="bg-surface-900">PLAN</option>
            <option value="SYSTEM" className="bg-surface-900">SYSTEM</option>
          </select>
        </div>
      </div>

      {/* ── AUDIT LOGS TABLE ──────────────────────────────────────────────── */}
      <div className="bg-surface-900 border border-surface-800 rounded-xl overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead className="bg-surface-800/60 border-b border-surface-800 text-slate-400 uppercase tracking-wider font-semibold text-[10px]">
              <tr>
                <th className="py-3 px-4">Timestamp</th>
                <th className="py-3 px-4">Administrator</th>
                <th className="py-3 px-4">Action</th>
                <th className="py-3 px-4">Target (Type & ID)</th>
                <th className="py-3 px-4">Audit Reason</th>
                <th className="py-3 px-4">IP Address</th>
                <th className="py-3 px-4 text-right">State Diff</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-800/60">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-500">
                    <div className="flex items-center justify-center gap-2">
                      <div className="w-4 h-4 border-2 border-brand-500 border-t-transparent rounded-full animate-spin" />
                      <span>Loading audit logs...</span>
                    </div>
                  </td>
                </tr>
              ) : logs.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-500">
                    No administrative audit logs found matching criteria.
                  </td>
                </tr>
              ) : (
                logs.map((log) => (
                  <tr key={log.id} className="hover:bg-surface-800/40 transition">
                    <td className="py-3 px-4 text-slate-400 text-[11px] whitespace-nowrap">
                      {new Date(log.createdAt).toLocaleString()}
                    </td>
                    <td className="py-3 px-4">
                      <div className="font-semibold text-slate-200">{log.adminEmail}</div>
                      <div className="font-mono text-[10px] text-slate-500 truncate max-w-[120px]">
                        {log.adminId}
                      </div>
                    </td>
                    <td className="py-3 px-4">{getActionBadge(log.action)}</td>
                    <td className="py-3 px-4">
                      <span className="text-[10px] font-bold uppercase text-slate-400 tracking-wider">
                        {log.targetType}:{' '}
                      </span>
                      <span className="font-mono text-[11px] text-slate-300">
                        {log.targetId.substring(0, 12)}...
                      </span>
                    </td>
                    <td className="py-3 px-4 text-slate-300 max-w-xs truncate" title={log.reason}>
                      {log.reason || 'No reason specified'}
                    </td>
                    <td className="py-3 px-4 font-mono text-[11px] text-slate-400">
                      {log.ipAddress || 'Internal'}
                    </td>
                    <td className="py-3 px-4 text-right">
                      {log.previousValue || log.newValue ? (
                        <button
                          onClick={() => setSelectedLog(log)}
                          className="px-2.5 py-1 rounded bg-surface-800 hover:bg-surface-700 text-brand-300 border border-surface-700 font-medium inline-flex items-center gap-1 transition"
                        >
                          <Eye className="w-3 h-3" />
                          <span>View Diff</span>
                        </button>
                      ) : (
                        <span className="text-slate-600 text-[11px]">-</span>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Footer */}
        <div className="px-4 py-3 bg-surface-800/30 border-t border-surface-800 flex items-center justify-between text-xs text-slate-400">
          <div>
            Showing {logs.length > 0 ? (pagination.page - 1) * pagination.limit + 1 : 0} to{' '}
            {Math.min(pagination.page * pagination.limit, pagination.total)} of {pagination.total} audit logs
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setPagination((p) => ({ ...p, page: p.page - 1 }))}
              disabled={pagination.page <= 1}
              className="p-1 rounded bg-surface-800 hover:bg-surface-700 disabled:opacity-40 transition"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <span>
              Page {pagination.page} of {Math.max(1, pagination.totalPages)}
            </span>
            <button
              onClick={() => setPagination((p) => ({ ...p, page: p.page + 1 }))}
              disabled={pagination.page >= pagination.totalPages}
              className="p-1 rounded bg-surface-800 hover:bg-surface-700 disabled:opacity-40 transition"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* ── STATE DIFF MODAL ──────────────────────────────────────────────── */}
      {selectedLog && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-surface-900 border border-surface-700 rounded-xl max-w-2xl w-full p-6 space-y-4 shadow-2xl">
            <div className="flex items-center justify-between border-b border-surface-800 pb-3">
              <div className="flex items-center gap-2">
                <ShieldCheck className="w-5 h-5 text-brand-400" />
                <h3 className="text-sm font-semibold text-white">
                  Audit Log Details & State Diff
                </h3>
              </div>
              <button
                onClick={() => setSelectedLog(null)}
                className="text-slate-400 hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {/* Meta summary */}
            <div className="grid grid-cols-2 gap-3 text-xs bg-surface-950 p-3 rounded-lg border border-surface-800">
              <div>
                <span className="text-slate-400 block text-[10px] uppercase font-semibold">Action</span>
                <span className="font-mono text-brand-300 font-bold">{selectedLog.action}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[10px] uppercase font-semibold">Administrator</span>
                <span className="text-slate-200">{selectedLog.adminEmail}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[10px] uppercase font-semibold">Target</span>
                <span className="font-mono text-slate-200">{selectedLog.targetType}: {selectedLog.targetId}</span>
              </div>
              <div>
                <span className="text-slate-400 block text-[10px] uppercase font-semibold">Timestamp</span>
                <span className="text-slate-200">{new Date(selectedLog.createdAt).toLocaleString()}</span>
              </div>
              <div className="col-span-2 pt-1 border-t border-surface-800">
                <span className="text-slate-400 block text-[10px] uppercase font-semibold">Audit Justification</span>
                <span className="text-slate-200">{selectedLog.reason}</span>
              </div>
            </div>

            {/* Side-by-side or Stacked Diffs */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-3 text-xs">
              <div>
                <span className="text-rose-400 font-semibold block mb-1">Previous Value</span>
                <pre className="bg-surface-950 p-3 rounded-lg border border-surface-800 text-[11px] font-mono text-slate-300 overflow-x-auto max-h-56">
                  {selectedLog.previousValue
                    ? JSON.stringify(selectedLog.previousValue, null, 2)
                    : '// No prior state recorded'}
                </pre>
              </div>

              <div>
                <span className="text-emerald-400 font-semibold block mb-1">New Value</span>
                <pre className="bg-surface-950 p-3 rounded-lg border border-surface-800 text-[11px] font-mono text-slate-300 overflow-x-auto max-h-56">
                  {selectedLog.newValue
                    ? JSON.stringify(selectedLog.newValue, null, 2)
                    : '// No mutation payload'}
                </pre>
              </div>
            </div>

            <div className="pt-2 flex justify-end">
              <button
                onClick={() => setSelectedLog(null)}
                className="px-4 py-2 rounded-lg bg-surface-800 hover:bg-surface-700 text-xs text-slate-200 font-medium transition"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
