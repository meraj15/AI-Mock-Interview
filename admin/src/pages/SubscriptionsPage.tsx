import React, { useEffect, useState } from 'react';
import { api } from '../api/client';
import { useFilter } from '../context/FilterContext';
import {
  Search,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react';

export const SubscriptionsPage: React.FC = () => {
  const { refreshKey } = useFilter();
  const [subscriptions, setSubscriptions] = useState<any[]>([]);
  const [stats, setStats] = useState<any>(null);
  const [pagination, setPagination] = useState({ page: 1, limit: 15, total: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);

  // Filters
  const [search, setSearch] = useState('');
  const [status, setStatus] = useState('ALL');

  // Cancel action modal
  const [cancelModal, setCancelModal] = useState<{ sub: any; reason: string } | null>(null);
  const [cancelLoading, setCancelLoading] = useState(false);

  const fetchSubscriptions = async () => {
    setLoading(true);
    try {
      const q = new URLSearchParams({
        page: pagination.page.toString(),
        limit: pagination.limit.toString(),
      });
      if (search.trim()) q.append('search', search.trim());
      if (status !== 'ALL') q.append('status', status);

      const [listRes, statsRes] = await Promise.all([
        api.get(`/api/v1/admin/subscriptions?${q.toString()}`),
        api.get('/api/v1/admin/subscriptions/stats'),
      ]);

      if (listRes.success) {
        setSubscriptions(listRes.subscriptions);
        setPagination(listRes.pagination);
      }
      if (statsRes.success) {
        setStats(statsRes.data);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSubscriptions();
  }, [pagination.page, status, refreshKey]);

  const handleCancelSubscription = async () => {
    if (!cancelModal) return;
    setCancelLoading(true);
    try {
      await api.post(`/api/v1/admin/subscriptions/${cancelModal.sub.id}/cancel`, {
        reason: cancelModal.reason,
      });
      setCancelModal(null);
      fetchSubscriptions();
    } catch (err) {
      console.error(err);
    } finally {
      setCancelLoading(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* ── TOP STATS CARDS ──────────────────────────────────────────────── */}
      {stats && (
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="p-4 rounded-xl bg-surface-900 border border-surface-800">
            <span className="text-slate-400 text-xs">Monthly Recurring Revenue</span>
            <div className="text-2xl font-bold text-white mt-1">₹{stats.mrrRupees.toLocaleString()}</div>
            <span className="text-[11px] text-slate-500">ARR: ₹{stats.arrRupees.toLocaleString()}</span>
          </div>

          <div className="p-4 rounded-xl bg-surface-900 border border-surface-800">
            <span className="text-slate-400 text-xs">Active Subscriptions</span>
            <div className="text-2xl font-bold text-emerald-400 mt-1">{stats.activeSubscriptions}</div>
            <span className="text-[11px] text-slate-500">
              {stats.monthlySubscriptions} Monthly · {stats.yearlySubscriptions} Yearly
            </span>
          </div>

          <div className="p-4 rounded-xl bg-surface-900 border border-surface-800">
            <span className="text-slate-400 text-xs">Churn Rate</span>
            <div className="text-2xl font-bold text-amber-400 mt-1">{stats.churnRatePercent}%</div>
            <span className="text-[11px] text-slate-500">{stats.cancelledSubscriptions} cancelled total</span>
          </div>

          <div className="p-4 rounded-xl bg-surface-900 border border-surface-800">
            <span className="text-slate-400 text-xs">Halted / Past Due</span>
            <div className="text-2xl font-bold text-rose-400 mt-1">{stats.haltedSubscriptions}</div>
            <span className="text-[11px] text-slate-500">Payment failure halts</span>
          </div>
        </div>
      )}

      {/* ── FILTER & SEARCH ──────────────────────────────────────────────── */}
      <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-wrap items-center justify-between gap-4">
        <form onSubmit={(e) => { e.preventDefault(); setPagination(p => ({ ...p, page: 1 })); fetchSubscriptions(); }} className="flex items-center gap-2 flex-1 min-w-[240px] max-w-md">
          <div className="relative w-full">
            <Search className="w-3.5 h-3.5 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search by customer email or Razorpay subscription ID..."
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

        <div className="flex items-center gap-2.5 text-xs">
          <select
            value={status}
            onChange={(e) => { setStatus(e.target.value); setPagination(p => ({ ...p, page: 1 })); }}
            className="bg-surface-800 border border-surface-700/60 rounded-lg px-2.5 py-1.5 text-slate-200 focus:outline-none"
          >
            <option value="ALL">All Statuses</option>
            <option value="ACTIVE">Active</option>
            <option value="CANCELLED">Cancelled</option>
            <option value="HALTED">Halted</option>
            <option value="EXPIRED">Expired</option>
          </select>
        </div>
      </div>

      {/* ── SUBSCRIPTIONS TABLE ──────────────────────────────────────────── */}
      <div className="rounded-xl bg-surface-900 border border-surface-800 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="border-b border-surface-800 bg-surface-850/50 text-slate-400">
                <th className="py-3 px-4 font-medium">Customer</th>
                <th className="py-3 px-4 font-medium">Plan</th>
                <th className="py-3 px-4 font-medium">Amount</th>
                <th className="py-3 px-4 font-medium">Interval</th>
                <th className="py-3 px-4 font-medium">Status</th>
                <th className="py-3 px-4 font-medium">Razorpay ID</th>
                <th className="py-3 px-4 font-medium">Current Period</th>
                <th className="py-3 px-4 font-medium text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-800/60">
              {loading ? (
                <tr>
                  <td colSpan={8} className="py-12 text-center text-slate-500">
                    Loading subscriptions...
                  </td>
                </tr>
              ) : subscriptions.length === 0 ? (
                <tr>
                  <td colSpan={8} className="py-12 text-center text-slate-500">
                    No subscriptions found.
                  </td>
                </tr>
              ) : (
                subscriptions.map((s) => (
                  <tr key={s.id} className="hover:bg-surface-800/30 transition">
                    <td className="py-3 px-4">
                      <div className="font-semibold text-slate-200">{s.userName}</div>
                      <div className="text-[11px] text-slate-400">{s.userEmail}</div>
                    </td>
                    <td className="py-3 px-4 font-medium text-white">{s.planName}</td>
                    <td className="py-3 px-4 font-semibold text-slate-200">₹{s.priceRupees}</td>
                    <td className="py-3 px-4 text-slate-400 capitalize">{s.billingInterval.toLowerCase()}</td>
                    <td className="py-3 px-4">
                      <span className={`px-2 py-0.5 rounded text-[10px] font-semibold ${
                        s.status === 'ACTIVE'
                          ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                          : s.status === 'CANCELLED'
                          ? 'bg-rose-500/10 text-rose-400 border border-rose-500/20'
                          : 'bg-amber-500/10 text-amber-400 border border-amber-500/20'
                      }`}>
                        {s.status}
                      </span>
                    </td>
                    <td className="py-3 px-4 font-mono text-[11px] text-slate-400">
                      {s.providerSubscriptionId || '—'}
                    </td>
                    <td className="py-3 px-4 text-slate-400 text-[11px]">
                      {s.currentPeriodEnd ? new Date(s.currentPeriodEnd).toLocaleDateString() : '—'}
                    </td>
                    <td className="py-3 px-4 text-right">
                      {s.status === 'ACTIVE' ? (
                        <button
                          onClick={() => setCancelModal({ sub: s, reason: '' })}
                          className="px-2.5 py-1 bg-surface-800 hover:bg-rose-500/20 text-slate-400 hover:text-rose-400 rounded-md transition font-medium"
                        >
                          Cancel
                        </button>
                      ) : (
                        <span className="text-slate-600">—</span>
                      )}
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
            Showing <span className="font-semibold text-slate-200">{subscriptions.length}</span> of{' '}
            <span className="font-semibold text-slate-200">{pagination.total}</span> subscriptions
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

      {/* ── CANCEL CONFIRMATION MODAL ─────────────────────────────────────── */}
      {cancelModal && (
        <div className="fixed inset-0 z-50 bg-black/80 flex items-center justify-center p-4">
          <div className="w-full max-w-md bg-surface-900 border border-surface-800 rounded-2xl p-6 shadow-2xl">
            <h4 className="text-sm font-bold text-white mb-1">Confirm Subscription Cancellation</h4>
            <p className="text-xs text-slate-400 mb-4">
              Cancelling subscription for <span className="text-slate-200 font-semibold">{cancelModal.sub.userEmail}</span>. This will immediately revoke their active entitlement.
            </p>

            <div className="mb-4">
              <label className="block text-[11px] font-medium text-slate-400 mb-1">
                Cancellation Reason <span className="text-rose-400">*</span>
              </label>
              <textarea
                required
                rows={3}
                placeholder="State the reason for cancelling this subscription..."
                value={cancelModal.reason}
                onChange={(e) => setCancelModal({ ...cancelModal, reason: e.target.value })}
                className="w-full bg-surface-800 border border-surface-700 rounded-lg p-2.5 text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:border-brand-500"
              />
            </div>

            <div className="flex items-center justify-end gap-2.5">
              <button
                type="button"
                onClick={() => setCancelModal(null)}
                className="px-3.5 py-2 rounded-lg bg-surface-800 hover:bg-surface-700 text-xs font-medium text-slate-300"
              >
                Keep Active
              </button>
              <button
                type="button"
                disabled={cancelLoading || !cancelModal.reason.trim()}
                onClick={handleCancelSubscription}
                className="px-4 py-2 rounded-lg bg-rose-600 hover:bg-rose-500 text-xs font-semibold text-white shadow-lg shadow-rose-500/20 disabled:opacity-50 transition"
              >
                {cancelLoading ? 'Cancelling...' : 'Cancel Subscription (Audited)'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
