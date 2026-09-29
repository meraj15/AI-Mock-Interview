import React, { useEffect, useState } from 'react';
import { api } from '../api/client';
import { useFilter } from '../context/FilterContext';
import {
  Search,
  Download,
  ChevronLeft,
  ChevronRight,
  ShieldAlert,
  ShieldCheck,
  Eye,
  X,
} from 'lucide-react';

export const UsersPage: React.FC = () => {
  const { refreshKey } = useFilter();
  const [users, setUsers] = useState<any[]>([]);
  const [pagination, setPagination] = useState({ page: 1, limit: 15, total: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);

  // Filters & Search state
  const [search, setSearch] = useState('');
  const [tier, setTier] = useState('ALL');
  const [status, setStatus] = useState('ALL');
  const [sort, setSort] = useState('newest');
  const [paymentFailed, setPaymentFailed] = useState(false);

  // User Detail modal state
  const [selectedUserId, setSelectedUserId] = useState<string | null>(null);
  const [selectedUserDetail, setSelectedUserDetail] = useState<any>(null);
  const [detailLoading, setDetailLoading] = useState(false);

  // Action Dialog state (Suspend, Restore, Entitlement)
  const [actionModal, setActionModal] = useState<{
    type: 'SUSPEND' | 'RESTORE' | 'ENTITLEMENT_GRANT' | 'ENTITLEMENT_REVOKE';
    user: any;
    reason: string;
  } | null>(null);
  const [actionLoading, setActionLoading] = useState(false);
  const [actionError, setActionError] = useState<string | null>(null);

  const fetchUsers = async () => {
    setLoading(true);
    try {
      const q = new URLSearchParams({
        page: pagination.page.toString(),
        limit: pagination.limit.toString(),
        tier,
        status,
        sort,
      });
      if (search.trim()) q.append('search', search.trim());
      if (paymentFailed) q.append('paymentFailed', 'true');

      const res = await api.get(`/api/v1/admin/users?${q.toString()}`);
      if (res.success) {
        setUsers(res.users);
        setPagination(res.pagination);
      }
    } catch (err: any) {
      console.error('Failed to fetch users:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, [pagination.page, tier, status, sort, paymentFailed, refreshKey]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setPagination((prev) => ({ ...prev, page: 1 }));
    fetchUsers();
  };

  const handleOpenDetail = async (userId: string) => {
    setSelectedUserId(userId);
    setDetailLoading(true);
    try {
      const res = await api.get(`/api/v1/admin/users/${userId}`);
      if (res.success) {
        setSelectedUserDetail(res.data);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setDetailLoading(false);
    }
  };

  const handleExecuteAction = async () => {
    if (!actionModal) return;
    setActionLoading(true);
    setActionError(null);

    try {
      const { type, user, reason } = actionModal;
      if (type === 'SUSPEND') {
        await api.post(`/api/v1/admin/users/${user.id}/suspend`, { reason });
      } else if (type === 'RESTORE') {
        await api.post(`/api/v1/admin/users/${user.id}/restore`, { reason });
      } else if (type === 'ENTITLEMENT_GRANT') {
        await api.post(`/api/v1/admin/users/${user.id}/entitlement`, { status: 'ACTIVE', reason });
      } else if (type === 'ENTITLEMENT_REVOKE') {
        await api.post(`/api/v1/admin/users/${user.id}/entitlement`, { status: 'INACTIVE', reason });
      }

      setActionModal(null);
      fetchUsers();
      if (selectedUserId === user.id) {
        handleOpenDetail(user.id);
      }
    } catch (err: any) {
      setActionError(err.message || 'Action failed');
    } finally {
      setActionLoading(false);
    }
  };

  const handleExportCsv = () => {
    const q = new URLSearchParams({ tier, status, sort });
    if (search.trim()) q.append('search', search.trim());
    api.downloadCsv(`/api/v1/admin/users/export?${q.toString()}`, 'interview-coach-users.csv');
  };

  return (
    <div className="space-y-5">
      {/* ── CONTROLS / FILTER BAR ────────────────────────────────────────── */}
      <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-wrap items-center justify-between gap-4">
        {/* Search */}
        <form onSubmit={handleSearchSubmit} className="flex items-center gap-2 flex-1 min-w-[240px] max-w-md">
          <div className="relative w-full">
            <Search className="w-3.5 h-3.5 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search by name, email, or user ID..."
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              className="w-full bg-surface-800 border border-surface-700/60 rounded-lg pl-9 pr-3 py-1.5 text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:border-brand-500"
            />
          </div>
          <button
            type="submit"
            className="px-3 py-1.5 bg-surface-800 hover:bg-surface-700 border border-surface-700 text-xs font-medium text-slate-200 rounded-lg transition"
          >
            Search
          </button>
        </form>

        {/* Filters */}
        <div className="flex items-center gap-2.5 flex-wrap text-xs">
          {/* Tier filter */}
          <select
            value={tier}
            onChange={(e) => {
              setTier(e.target.value);
              setPagination((p) => ({ ...p, page: 1 }));
            }}
            className="bg-surface-800 border border-surface-700/60 rounded-lg px-2.5 py-1.5 text-slate-200 focus:outline-none"
          >
            <option value="ALL">All Tiers</option>
            <option value="FREE">Free Plan</option>
            <option value="PRO">Pro Tier</option>
          </select>

          {/* Status filter */}
          <select
            value={status}
            onChange={(e) => {
              setStatus(e.target.value);
              setPagination((p) => ({ ...p, page: 1 }));
            }}
            className="bg-surface-800 border border-surface-700/60 rounded-lg px-2.5 py-1.5 text-slate-200 focus:outline-none"
          >
            <option value="ALL">All Status</option>
            <option value="ACTIVE">Active Accounts</option>
            <option value="INACTIVE">Suspended Accounts</option>
          </select>

          {/* Sort */}
          <select
            value={sort}
            onChange={(e) => setSort(e.target.value)}
            className="bg-surface-800 border border-surface-700/60 rounded-lg px-2.5 py-1.5 text-slate-200 focus:outline-none"
          >
            <option value="newest">Newest First</option>
            <option value="oldest">Oldest First</option>
            <option value="latest_active">Latest Active</option>
          </select>

          {/* Payment Failed checkbox */}
          <label className="flex items-center gap-1.5 text-slate-400 cursor-pointer select-none">
            <input
              type="checkbox"
              checked={paymentFailed}
              onChange={(e) => setPaymentFailed(e.target.checked)}
              className="rounded bg-surface-800 border-surface-700 text-brand-500 focus:ring-0"
            />
            <span>Payment Failed</span>
          </label>

          {/* Export CSV */}
          <button
            onClick={handleExportCsv}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-surface-800 hover:bg-surface-700 border border-surface-700 text-slate-200 rounded-lg transition"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Export CSV</span>
          </button>
        </div>
      </div>

      {/* ── USERS TABLE ──────────────────────────────────────────────────── */}
      <div className="rounded-xl bg-surface-900 border border-surface-800 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="border-b border-surface-800 bg-surface-850/50 text-slate-400">
                <th className="py-3 px-4 font-medium">User</th>
                <th className="py-3 px-4 font-medium">Tier & Plan</th>
                <th className="py-3 px-4 font-medium">Subscription</th>
                <th className="py-3 px-4 font-medium text-center">Interviews Used</th>
                <th className="py-3 px-4 font-medium text-center">Remaining</th>
                <th className="py-3 px-4 font-medium">Spend</th>
                <th className="py-3 px-4 font-medium">Last Active</th>
                <th className="py-3 px-4 font-medium">Status</th>
                <th className="py-3 px-4 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-800/60">
              {loading ? (
                <tr>
                  <td colSpan={9} className="py-12 text-center text-slate-500">
                    Loading users database...
                  </td>
                </tr>
              ) : users.length === 0 ? (
                <tr>
                  <td colSpan={9} className="py-12 text-center text-slate-500">
                    No users match current filters.
                  </td>
                </tr>
              ) : (
                users.map((u) => (
                  <tr key={u.id} className="hover:bg-surface-800/30 transition">
                    <td className="py-3 px-4">
                      <div className="font-semibold text-slate-200">{u.name}</div>
                      <div className="text-[11px] text-slate-400">{u.email}</div>
                    </td>
                    <td className="py-3 px-4">
                      <div className="flex items-center gap-1.5">
                        <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                          u.tier === 'PRO'
                            ? 'bg-amber-500/15 text-amber-400 border border-amber-500/30'
                            : 'bg-slate-500/15 text-slate-400 border border-slate-500/30'
                        }`}>
                          {u.tier}
                        </span>
                        <span className="text-[11px] text-slate-300 truncate max-w-[120px]">{u.planName}</span>
                      </div>
                    </td>
                    <td className="py-3 px-4">
                      <span className={`px-2 py-0.5 rounded text-[10px] font-semibold ${
                        u.subscriptionStatus === 'ACTIVE'
                          ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                          : u.subscriptionStatus === 'CANCELLED'
                          ? 'bg-rose-500/10 text-rose-400 border border-rose-500/20'
                          : 'text-slate-400'
                      }`}>
                        {u.subscriptionStatus}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-center font-mono font-semibold text-slate-200">
                      {u.interviewsUsed}
                    </td>
                    <td className="py-3 px-4 text-center font-mono text-brand-300">
                      {u.interviewsRemaining}
                    </td>
                    <td className="py-3 px-4 font-semibold text-slate-200">
                      ₹{u.totalSpendRupees}
                    </td>
                    <td className="py-3 px-4 text-[11px] text-slate-400">
                      {u.lastLoginAt ? new Date(u.lastLoginAt).toLocaleDateString() : 'Never'}
                    </td>
                    <td className="py-3 px-4">
                      <span className={`px-2 py-0.5 rounded text-[10px] font-semibold ${
                        u.isActive
                          ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                          : 'bg-rose-500/10 text-rose-400 border border-rose-500/20'
                      }`}>
                        {u.isActive ? 'Active' : 'Suspended'}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <button
                          onClick={() => handleOpenDetail(u.id)}
                          className="p-1.5 bg-surface-800 hover:bg-surface-700 text-slate-300 hover:text-white rounded-md transition"
                          title="View User Dossier"
                        >
                          <Eye className="w-3.5 h-3.5" />
                        </button>
                        {u.isActive ? (
                          <button
                            onClick={() => setActionModal({ type: 'SUSPEND', user: u, reason: '' })}
                            className="p-1.5 bg-surface-800 hover:bg-rose-500/20 text-slate-400 hover:text-rose-400 rounded-md transition"
                            title="Suspend User"
                          >
                            <ShieldAlert className="w-3.5 h-3.5" />
                          </button>
                        ) : (
                          <button
                            onClick={() => setActionModal({ type: 'RESTORE', user: u, reason: '' })}
                            className="p-1.5 bg-surface-800 hover:bg-emerald-500/20 text-slate-400 hover:text-emerald-400 rounded-md transition"
                            title="Restore User"
                          >
                            <ShieldCheck className="w-3.5 h-3.5" />
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination Bar */}
        <div className="p-4 border-t border-surface-800 flex items-center justify-between text-xs text-slate-400">
          <div>
            Showing <span className="font-semibold text-slate-200">{users.length}</span> of{' '}
            <span className="font-semibold text-slate-200">{pagination.total}</span> users
          </div>
          <div className="flex items-center gap-2">
            <button
              disabled={pagination.page <= 1}
              onClick={() => setPagination((p) => ({ ...p, page: p.page - 1 }))}
              className="p-1.5 rounded-md bg-surface-800 hover:bg-surface-700 disabled:opacity-40 transition"
            >
              <ChevronLeft className="w-4 h-4" />
            </button>
            <span className="font-medium text-slate-300">
              Page {pagination.page} of {pagination.totalPages || 1}
            </span>
            <button
              disabled={pagination.page >= pagination.totalPages}
              onClick={() => setPagination((p) => ({ ...p, page: p.page + 1 }))}
              className="p-1.5 rounded-md bg-surface-800 hover:bg-surface-700 disabled:opacity-40 transition"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* ── USER DETAIL MODAL / DRAWER ───────────────────────────────────── */}
      {selectedUserId && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex justify-end">
          <div className="w-full max-w-2xl bg-surface-900 border-l border-surface-800 h-full overflow-y-auto p-6 flex flex-col justify-between shadow-2xl animate-in slide-in-from-right duration-200">
            <div>
              {/* Header */}
              <div className="flex items-center justify-between pb-4 border-b border-surface-800">
                <div>
                  <h3 className="text-base font-bold text-white">User Dossier</h3>
                  <p className="text-xs text-slate-400 font-mono">{selectedUserId}</p>
                </div>
                <button
                  onClick={() => setSelectedUserId(null)}
                  className="p-2 text-slate-400 hover:text-white rounded-lg hover:bg-surface-800"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {detailLoading || !selectedUserDetail ? (
                <div className="py-20 text-center text-xs text-slate-500">
                  Loading user data...
                </div>
              ) : (
                <div className="space-y-6 pt-5 text-xs">
                  {/* Profile Card */}
                  <div className="p-4 rounded-xl bg-surface-800/40 border border-surface-700/50">
                    <div className="flex justify-between items-start mb-3">
                      <div>
                        <div className="text-sm font-bold text-white">
                          {selectedUserDetail.profile?.fullName || 'Anonymous Candidate'}
                        </div>
                        <div className="text-slate-400">{selectedUserDetail.user.email}</div>
                      </div>
                      <span className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                        selectedUserDetail.entitlement.isPro
                          ? 'bg-amber-500/15 text-amber-400 border border-amber-500/30'
                          : 'bg-slate-500/15 text-slate-400 border border-slate-500/30'
                      }`}>
                        {selectedUserDetail.entitlement.isPro ? 'PRO SUBSCRIBER' : 'FREE USER'}
                      </span>
                    </div>

                    <div className="grid grid-cols-2 gap-3 text-slate-300">
                      <div>Target Role: <span className="font-semibold text-white">{selectedUserDetail.profile?.targetRole || 'Not specified'}</span></div>
                      <div>Experience: <span className="font-semibold text-white">{selectedUserDetail.profile?.experienceYears || 0} years</span></div>
                      <div>Account Created: <span className="text-slate-400">{new Date(selectedUserDetail.user.createdAt).toLocaleDateString()}</span></div>
                      <div>Account Status: <span className={`font-semibold ${selectedUserDetail.user.isActive ? 'text-emerald-400' : 'text-rose-400'}`}>{selectedUserDetail.user.isActive ? 'Active' : 'Suspended'}</span></div>
                    </div>

                    {selectedUserDetail.profile?.skills?.length > 0 && (
                      <div className="mt-3 pt-3 border-t border-surface-700/50">
                        <span className="text-slate-400 block mb-1.5 font-medium">Extracted Skills:</span>
                        <div className="flex flex-wrap gap-1.5">
                          {selectedUserDetail.profile.skills.map((s: string) => (
                            <span key={s} className="px-2 py-0.5 bg-surface-700 text-slate-200 rounded text-[10px]">
                              {s}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>

                  {/* Quotas & Usage */}
                  <div className="p-4 rounded-xl bg-surface-800/40 border border-surface-700/50">
                    <h4 className="font-bold text-slate-200 mb-3 uppercase tracking-wider text-[11px]">Period Usage & Quotas</h4>
                    <div className="grid grid-cols-3 gap-3 text-center">
                      <div className="p-2.5 rounded-lg bg-surface-900 border border-surface-700/40">
                        <span className="text-slate-400 block text-[10px]">Interviews Used</span>
                        <span className="text-base font-bold text-white">{selectedUserDetail.usage.interviewsUsed}</span>
                      </div>
                      <div className="p-2.5 rounded-lg bg-surface-900 border border-surface-700/40">
                        <span className="text-slate-400 block text-[10px]">Interviews Remaining</span>
                        <span className="text-base font-bold text-brand-400">{selectedUserDetail.usage.interviewsRemaining}</span>
                      </div>
                      <div className="p-2.5 rounded-lg bg-surface-900 border border-surface-700/40">
                        <span className="text-slate-400 block text-[10px]">Resume Scans</span>
                        <span className="text-base font-bold text-cyan-400">{selectedUserDetail.usage.resumeScansUsed}</span>
                      </div>
                    </div>
                  </div>

                  {/* Interview Performance */}
                  <div className="p-4 rounded-xl bg-surface-800/40 border border-surface-700/50">
                    <h4 className="font-bold text-slate-200 mb-3 uppercase tracking-wider text-[11px]">Interview History</h4>
                    <div className="grid grid-cols-3 gap-2 mb-3 text-center">
                      <div>Total: <span className="font-bold text-white">{selectedUserDetail.interviewMetrics.totalInterviews}</span></div>
                      <div>Average Score: <span className="font-bold text-emerald-400">{selectedUserDetail.interviewMetrics.averageScore}/100</span></div>
                      <div>Best Score: <span className="font-bold text-cyan-400">{selectedUserDetail.interviewMetrics.highestScore}/100</span></div>
                    </div>

                    <div className="space-y-1.5 max-h-40 overflow-y-auto">
                      {selectedUserDetail.interviewMetrics.recentSessions.map((s: any) => (
                        <div key={s.id} className="p-2 rounded bg-surface-900 flex items-center justify-between text-[11px]">
                          <div>
                            <span className="font-medium text-slate-200">{s.role}</span>
                            <span className="text-slate-500 ml-1.5 capitalize">({s.difficulty})</span>
                          </div>
                          <div className="flex items-center gap-3">
                            <span className="font-bold text-emerald-400">{s.score}/100</span>
                            <span className="text-slate-500">{new Date(s.createdAt).toLocaleDateString()}</span>
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>

                  {/* Privileged Admin Actions */}
                  <div className="p-4 rounded-xl bg-surface-800/50 border border-brand-500/20">
                    <h4 className="font-bold text-brand-300 mb-2 uppercase tracking-wider text-[11px]">Administrative Actions (Audited)</h4>
                    <div className="flex flex-wrap gap-2 pt-1">
                      {selectedUserDetail.entitlement.isPro ? (
                        <button
                          onClick={() => setActionModal({ type: 'ENTITLEMENT_REVOKE', user: selectedUserDetail.user, reason: '' })}
                          className="px-3 py-1.5 rounded-lg bg-rose-500/20 hover:bg-rose-500/30 text-rose-300 border border-rose-500/30 font-medium"
                        >
                          Revoke Pro Entitlement
                        </button>
                      ) : (
                        <button
                          onClick={() => setActionModal({ type: 'ENTITLEMENT_GRANT', user: selectedUserDetail.user, reason: '' })}
                          className="px-3 py-1.5 rounded-lg bg-emerald-500/20 hover:bg-emerald-500/30 text-emerald-300 border border-emerald-500/30 font-medium"
                        >
                          Manually Grant Pro Entitlement
                        </button>
                      )}

                      {selectedUserDetail.user.isActive ? (
                        <button
                          onClick={() => setActionModal({ type: 'SUSPEND', user: selectedUserDetail.user, reason: '' })}
                          className="px-3 py-1.5 rounded-lg bg-rose-600/20 hover:bg-rose-600/30 text-rose-300 border border-rose-600/30 font-medium"
                        >
                          Suspend User Account
                        </button>
                      ) : (
                        <button
                          onClick={() => setActionModal({ type: 'RESTORE', user: selectedUserDetail.user, reason: '' })}
                          className="px-3 py-1.5 rounded-lg bg-emerald-600/20 hover:bg-emerald-600/30 text-emerald-300 border border-emerald-600/30 font-medium"
                        >
                          Restore Account
                        </button>
                      )}
                    </div>
                  </div>
                </div>
              )}
            </div>

            <div className="pt-4 border-t border-surface-800">
              <button
                onClick={() => setSelectedUserId(null)}
                className="w-full py-2 bg-surface-800 hover:bg-surface-700 text-slate-300 rounded-lg font-medium text-xs transition"
              >
                Close Dossier
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── PRIVILEGED ACTION CONFIRMATION MODAL ─────────────────────────── */}
      {actionModal && (
        <div className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-4">
          <div className="w-full max-w-md bg-surface-900 border border-surface-800 rounded-2xl p-6 shadow-2xl">
            <div className="flex items-center gap-3 mb-4">
              <div className="w-10 h-10 rounded-xl bg-amber-500/10 border border-amber-500/30 flex items-center justify-center text-amber-400">
                <ShieldAlert className="w-5 h-5" />
              </div>
              <div>
                <h4 className="text-sm font-bold text-white capitalize">
                  Confirm {actionModal.type.replace('_', ' ')}
                </h4>
                <p className="text-[11px] text-slate-400">{actionModal.user.email}</p>
              </div>
            </div>

            {actionError && (
              <div className="mb-4 p-2.5 rounded bg-rose-500/10 border border-rose-500/20 text-rose-300 text-xs">
                {actionError}
              </div>
            )}

            <p className="text-xs text-slate-300 mb-3">
              This is a privileged administrative operation. A permanent audit log will be created recording your Admin ID, timestamp, and justification reason.
            </p>

            <div className="mb-4">
              <label className="block text-[11px] font-medium text-slate-400 mb-1">
                Reason / Justification <span className="text-rose-400">*</span>
              </label>
              <textarea
                required
                rows={3}
                placeholder="State the administrative reason for this action..."
                value={actionModal.reason}
                onChange={(e) => setActionModal({ ...actionModal, reason: e.target.value })}
                className="w-full bg-surface-800 border border-surface-700 rounded-lg p-2.5 text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:border-brand-500"
              />
            </div>

            <div className="flex items-center justify-end gap-2.5">
              <button
                type="button"
                onClick={() => setActionModal(null)}
                className="px-3.5 py-2 rounded-lg bg-surface-800 hover:bg-surface-700 text-xs font-medium text-slate-300"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={actionLoading || !actionModal.reason.trim()}
                onClick={handleExecuteAction}
                className="px-4 py-2 rounded-lg bg-brand-600 hover:bg-brand-500 text-xs font-semibold text-white shadow-lg shadow-brand-500/20 disabled:opacity-50 transition"
              >
                {actionLoading ? 'Processing...' : 'Confirm & Audit Action'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
