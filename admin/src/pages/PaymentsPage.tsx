import React, { useEffect, useState } from 'react';
import { api } from '../api/client';
import { useFilter } from '../context/FilterContext';
import {
  Banknote,
  Search,
  Download,
  ChevronLeft,
  ChevronRight,
  CheckCircle2,
  XCircle,
  Clock,
  RotateCcw,
  Webhook,
  ArrowUpRight,
  TrendingUp,
  Percent,
  X,
  CreditCard,
} from 'lucide-react';

export const PaymentsPage: React.FC = () => {
  const { refreshKey, dateRange } = useFilter();
  const [activeTab, setActiveTab] = useState<'transactions' | 'webhooks'>('transactions');

  // Stats state
  const [stats, setStats] = useState<any>(null);
  const [statsLoading, setStatsLoading] = useState(true);

  // Transactions state
  const [payments, setPayments] = useState<any[]>([]);
  const [paymentsLoading, setPaymentsLoading] = useState(true);
  const [pagination, setPagination] = useState({ page: 1, limit: 15, total: 0, totalPages: 1 });
  const [search, setSearch] = useState('');
  const [appliedSearch, setAppliedSearch] = useState('');
  const [status, setStatus] = useState('ALL');

  // Webhooks state
  const [webhooks, setWebhooks] = useState<any[]>([]);
  const [webhookPagination, setWebhookPagination] = useState({ page: 1, limit: 15, total: 0, totalPages: 1 });
  const [webhooksLoading, setWebhooksLoading] = useState(false);
  const [selectedWebhook, setSelectedWebhook] = useState<any>(null);

  // Fetch Payment Stats
  const fetchStats = async () => {
    setStatsLoading(true);
    try {
      const res = await api.get('/api/v1/admin/payments/stats');
      if (res.success) {
        setStats(res.data);
      }
    } catch (err) {
      console.error('Failed to load payment stats:', err);
    } finally {
      setStatsLoading(false);
    }
  };

  // Fetch Payments List
  const fetchPayments = async (overrideSearch?: string, overridePage?: number) => {
    setPaymentsLoading(true);
    try {
      const activeSearch = overrideSearch !== undefined ? overrideSearch : appliedSearch;
      const activePage = overridePage !== undefined ? overridePage : pagination.page;

      const q = new URLSearchParams({
        page: activePage.toString(),
        limit: pagination.limit.toString(),
        status,
      });
      if (activeSearch.trim()) q.append('search', activeSearch.trim());

      const res = await api.get(`/api/v1/admin/payments?${q.toString()}`);
      if (res.success) {
        setPayments(res.payments);
        setPagination(res.pagination);
      }
    } catch (err) {
      console.error('Failed to fetch payments:', err);
    } finally {
      setPaymentsLoading(false);
    }
  };

  // Fetch Webhooks List
  const fetchWebhooks = async () => {
    setWebhooksLoading(true);
    try {
      const q = new URLSearchParams({
        page: webhookPagination.page.toString(),
        limit: webhookPagination.limit.toString(),
      });
      const res = await api.get(`/api/v1/admin/webhooks?${q.toString()}`);
      if (res.success) {
        setWebhooks(res.events);
        setWebhookPagination(res.pagination);
      }
    } catch (err) {
      console.error('Failed to fetch webhooks:', err);
    } finally {
      setWebhooksLoading(false);
    }
  };

  useEffect(() => {
    fetchStats();
  }, [refreshKey, dateRange]);

  useEffect(() => {
    if (activeTab === 'transactions') {
      fetchPayments();
    } else {
      fetchWebhooks();
    }
  }, [activeTab, pagination.page, status, appliedSearch, webhookPagination.page, refreshKey]);

  // Live debounced search & instant reset when input is cleared ("when nothing then show all payments")
  useEffect(() => {
    if (search.trim() === '') {
      if (appliedSearch !== '') {
        setAppliedSearch('');
        setPagination((prev) => ({ ...prev, page: 1 }));
      }
      return;
    }

    const timer = setTimeout(() => {
      if (search.trim() !== appliedSearch) {
        setAppliedSearch(search.trim());
        setPagination((prev) => ({ ...prev, page: 1 }));
      }
    }, 350);

    return () => clearTimeout(timer);
  }, [search, appliedSearch]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = search.trim();
    setPagination((prev) => ({ ...prev, page: 1 }));
    if (trimmed === appliedSearch) {
      fetchPayments(trimmed, 1);
    } else {
      setAppliedSearch(trimmed);
    }
  };

  const handleClearSearch = () => {
    setSearch('');
    setPagination((prev) => ({ ...prev, page: 1 }));
    if (appliedSearch === '') {
      fetchPayments('', 1);
    } else {
      setAppliedSearch('');
    }
  };

  const handleExportCsv = () => {
    const q = new URLSearchParams({ status });
    if (appliedSearch.trim()) q.append('search', appliedSearch.trim());
    api.downloadCsv(`/api/v1/admin/payments/export?${q.toString()}`, 'payments.csv');
  };

  const getStatusBadge = (txStatus: string) => {
    switch (txStatus) {
      case 'CAPTURED':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
            <CheckCircle2 className="w-3 h-3" /> Captured
          </span>
        );
      case 'FAILED':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-rose-500/10 text-rose-400 border border-rose-500/20">
            <XCircle className="w-3 h-3" /> Failed
          </span>
        );
      case 'REFUNDED':
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-purple-500/10 text-purple-400 border border-purple-500/20">
            <RotateCcw className="w-3 h-3" /> Refunded
          </span>
        );
      case 'PENDING':
      default:
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[11px] font-semibold bg-amber-500/10 text-amber-400 border border-amber-500/20">
            <Clock className="w-3 h-3" /> Pending
          </span>
        );
    }
  };

  return (
    <div className="space-y-6">
      {/* ── HEADER ────────────────────────────────────────────────────────── */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-white tracking-tight flex items-center gap-2">
            <Banknote className="w-6 h-6 text-brand-400" />
            Payments & Revenue
          </h2>
          <p className="text-xs text-slate-400 mt-0.5">
            Audit payment gateway transactions, captured revenue, refunds, and Razorpay webhook events.
          </p>
        </div>

        <button
          onClick={handleExportCsv}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-surface-800 hover:bg-surface-700 text-slate-200 border border-surface-700 text-xs font-medium transition self-start sm:self-auto"
        >
          <Download className="w-3.5 h-3.5 text-slate-400" />
          <span>Export Payments CSV</span>
        </button>
      </div>

      {/* ── METRIC CARDS ──────────────────────────────────────────────────── */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3">
        {/* Gross Revenue */}
        <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-medium uppercase tracking-wider">Gross Revenue</span>
            <TrendingUp className="w-4 h-4 text-emerald-400" />
          </div>
          <div className="mt-2 text-xl font-bold text-white">
            {statsLoading ? '...' : `₹${(stats?.grossRevenueRupees || 0).toLocaleString('en-IN')}`}
          </div>
          <span className="text-[10px] text-slate-500 mt-1">Total captured</span>
        </div>

        {/* Net Revenue */}
        <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-medium uppercase tracking-wider">Net Revenue</span>
            <Banknote className="w-4 h-4 text-brand-400" />
          </div>
          <div className="mt-2 text-xl font-bold text-brand-300">
            {statsLoading ? '...' : `₹${(stats?.netRevenueRupees || 0).toLocaleString('en-IN')}`}
          </div>
          <span className="text-[10px] text-slate-500 mt-1">Gross minus refunds</span>
        </div>

        {/* Refunded */}
        <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-medium uppercase tracking-wider">Refunded</span>
            <RotateCcw className="w-4 h-4 text-purple-400" />
          </div>
          <div className="mt-2 text-xl font-bold text-purple-300">
            {statsLoading ? '...' : `₹${(stats?.refundRupees || 0).toLocaleString('en-IN')}`}
          </div>
          <span className="text-[10px] text-slate-500 mt-1">{stats?.refundedCount || 0} transactions</span>
        </div>

        {/* Captured */}
        <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-medium uppercase tracking-wider">Captured</span>
            <CheckCircle2 className="w-4 h-4 text-emerald-400" />
          </div>
          <div className="mt-2 text-xl font-bold text-emerald-400">
            {statsLoading ? '...' : (stats?.capturedCount || 0).toLocaleString()}
          </div>
          <span className="text-[10px] text-slate-500 mt-1">Successful payments</span>
        </div>

        {/* Failed */}
        <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-medium uppercase tracking-wider">Failed</span>
            <XCircle className="w-4 h-4 text-rose-400" />
          </div>
          <div className="mt-2 text-xl font-bold text-rose-400">
            {statsLoading ? '...' : (stats?.failedCount || 0).toLocaleString()}
          </div>
          <span className="text-[10px] text-slate-500 mt-1">Dropped / Declined</span>
        </div>

        {/* Success Rate */}
        <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-medium uppercase tracking-wider">Success Rate</span>
            <Percent className="w-4 h-4 text-brand-400" />
          </div>
          <div className="mt-2 text-xl font-bold text-white">
            {statsLoading ? '...' : `${stats?.successRatePercent ?? 100}%`}
          </div>
          <span className="text-[10px] text-slate-500 mt-1">Capture vs Fail</span>
        </div>
      </div>

      {/* ── TABS ──────────────────────────────────────────────────────────── */}
      <div className="flex items-center gap-2 border-b border-surface-800 pb-2">
        <button
          onClick={() => setActiveTab('transactions')}
          className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-semibold transition ${
            activeTab === 'transactions'
              ? 'bg-brand-600/20 text-brand-300 border border-brand-500/30'
              : 'text-slate-400 hover:text-slate-200 hover:bg-surface-800/60'
          }`}
        >
          <CreditCard className="w-4 h-4" />
          <span>Payment Transactions</span>
          <span className="ml-1 px-1.5 py-0.5 rounded-full text-[10px] bg-surface-800 text-slate-400">
            {pagination.total}
          </span>
        </button>

        <button
          onClick={() => setActiveTab('webhooks')}
          className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-semibold transition ${
            activeTab === 'webhooks'
              ? 'bg-brand-600/20 text-brand-300 border border-brand-500/30'
              : 'text-slate-400 hover:text-slate-200 hover:bg-surface-800/60'
          }`}
        >
          <Webhook className="w-4 h-4" />
          <span>Razorpay Webhooks</span>
          <span className="ml-1 px-1.5 py-0.5 rounded-full text-[10px] bg-surface-800 text-slate-400">
            {webhookPagination.total}
          </span>
        </button>
      </div>

      {/* ── TAB 1: TRANSACTIONS ───────────────────────────────────────────── */}
      {activeTab === 'transactions' && (
        <div className="space-y-4">
          {/* Filters Bar */}
          <div className="flex flex-col sm:flex-row gap-3">
            <form onSubmit={handleSearchSubmit} className="flex items-center gap-2 flex-1">
              <div className="relative flex-1">
                <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none" />
                <input
                  type="text"
                  value={search}
                  onChange={(e) => {
                    const val = e.target.value;
                    setSearch(val);
                    if (!val.trim() && appliedSearch) {
                      setPagination((p) => ({ ...p, page: 1 }));
                      setAppliedSearch('');
                    }
                  }}
                  placeholder="Search by Razorpay Payment ID, Order ID, or User Email..."
                  className="w-full bg-surface-900 border border-surface-800 rounded-lg pl-9 pr-8 py-2 text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:border-brand-500/50 transition"
                />
                {search.length > 0 && (
                  <button
                    type="button"
                    onClick={handleClearSearch}
                    className="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-white p-0.5 rounded transition"
                    title="Clear search and show all"
                  >
                    <X className="w-3.5 h-3.5" />
                  </button>
                )}
              </div>
              <button
                type="submit"
                className="px-3 py-2 bg-surface-900 hover:bg-surface-800 border border-surface-800 text-xs font-medium text-slate-200 rounded-lg transition"
              >
                Search
              </button>
            </form>

            <div className="flex items-center gap-2">
              <select
                value={status}
                onChange={(e) => {
                  setStatus(e.target.value);
                  setPagination((p) => ({ ...p, page: 1 }));
                }}
                className="bg-surface-900 border border-surface-800 rounded-lg px-3 py-2 text-xs text-slate-300 focus:outline-none focus:border-brand-500/50"
              >
                <option value="ALL">All Statuses</option>
                <option value="CAPTURED">Captured</option>
                <option value="PENDING">Pending</option>
                <option value="FAILED">Failed</option>
                <option value="REFUNDED">Refunded</option>
              </select>
            </div>
          </div>

          {/* Transactions Table */}
          <div className="bg-surface-900 border border-surface-800 rounded-xl overflow-hidden shadow-sm">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-surface-800/60 border-b border-surface-800 text-slate-400 uppercase tracking-wider font-semibold text-[10px]">
                  <tr>
                    <th className="py-3 px-4">Transaction ID</th>
                    <th className="py-3 px-4">Customer</th>
                    <th className="py-3 px-4">Plan / Interval</th>
                    <th className="py-3 px-4">Amount</th>
                    <th className="py-3 px-4">Status</th>
                    <th className="py-3 px-4">Razorpay Reference</th>
                    <th className="py-3 px-4">Paid At</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-surface-800/60">
                  {paymentsLoading ? (
                    <tr>
                      <td colSpan={7} className="py-12 text-center text-slate-500">
                        <div className="flex items-center justify-center gap-2">
                          <div className="w-4 h-4 border-2 border-brand-500 border-t-transparent rounded-full animate-spin" />
                          <span>Loading payments...</span>
                        </div>
                      </td>
                    </tr>
                  ) : payments.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="py-12 text-center text-slate-500">
                        No payment transactions found.
                      </td>
                    </tr>
                  ) : (
                    payments.map((p) => (
                      <tr key={p.id} className="hover:bg-surface-800/40 transition">
                        <td className="py-3 px-4 font-mono text-[11px] text-slate-400">
                          {p.id.substring(0, 10)}...
                        </td>
                        <td className="py-3 px-4">
                          <div className="font-medium text-slate-200">{p.userName}</div>
                          <div className="text-[11px] text-slate-400">{p.userEmail}</div>
                        </td>
                        <td className="py-3 px-4">
                          <div className="text-slate-300 font-medium">{p.planName}</div>
                          <div className="text-[10px] text-slate-500">{p.billingInterval}</div>
                        </td>
                        <td className="py-3 px-4 font-semibold text-white">
                          ₹{p.amountRupees.toLocaleString('en-IN')}
                        </td>
                        <td className="py-3 px-4">{getStatusBadge(p.status)}</td>
                        <td className="py-3 px-4 font-mono text-[11px]">
                          {p.providerPaymentId ? (
                            <span className="text-slate-300">{p.providerPaymentId}</span>
                          ) : p.providerOrderId ? (
                            <span className="text-slate-500">Order: {p.providerOrderId}</span>
                          ) : (
                            <span className="text-slate-600">N/A</span>
                          )}
                        </td>
                        <td className="py-3 px-4 text-slate-400 text-[11px] whitespace-nowrap">
                          {p.paidAt ? new Date(p.paidAt).toLocaleString() : new Date(p.createdAt).toLocaleString()}
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
                Showing {payments.length > 0 ? (pagination.page - 1) * pagination.limit + 1 : 0} to{' '}
                {Math.min(pagination.page * pagination.limit, pagination.total)} of {pagination.total} transactions
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
        </div>
      )}

      {/* ── TAB 2: WEBHOOK EVENTS ────────────────────────────────────────── */}
      {activeTab === 'webhooks' && (
        <div className="space-y-4">
          <div className="bg-surface-900 border border-surface-800 rounded-xl overflow-hidden shadow-sm">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs">
                <thead className="bg-surface-800/60 border-b border-surface-800 text-slate-400 uppercase tracking-wider font-semibold text-[10px]">
                  <tr>
                    <th className="py-3 px-4">Event ID</th>
                    <th className="py-3 px-4">Event Type</th>
                    <th className="py-3 px-4">Provider</th>
                    <th className="py-3 px-4">Payload Summary</th>
                    <th className="py-3 px-4">Processed At</th>
                    <th className="py-3 px-4 text-right">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-surface-800/60">
                  {webhooksLoading ? (
                    <tr>
                      <td colSpan={6} className="py-12 text-center text-slate-500">
                        <div className="flex items-center justify-center gap-2">
                          <div className="w-4 h-4 border-2 border-brand-500 border-t-transparent rounded-full animate-spin" />
                          <span>Loading webhook events...</span>
                        </div>
                      </td>
                    </tr>
                  ) : webhooks.length === 0 ? (
                    <tr>
                      <td colSpan={6} className="py-12 text-center text-slate-500">
                        No webhook events recorded yet.
                      </td>
                    </tr>
                  ) : (
                    webhooks.map((w) => (
                      <tr key={w.id} className="hover:bg-surface-800/40 transition">
                        <td className="py-3 px-4 font-mono text-[11px] text-slate-300">
                          {w.eventId}
                        </td>
                        <td className="py-3 px-4">
                          <span className="px-2 py-0.5 rounded text-[11px] font-mono font-medium bg-brand-500/10 text-brand-400 border border-brand-500/20">
                            {w.eventType}
                          </span>
                        </td>
                        <td className="py-3 px-4 text-slate-400 uppercase tracking-wider text-[10px] font-semibold">
                          {w.provider}
                        </td>
                        <td className="py-3 px-4 text-slate-400 font-mono text-[10px]">
                          {Array.isArray(w.payloadSummary) && w.payloadSummary.length > 0
                            ? w.payloadSummary.join(', ')
                            : 'Standard payload'}
                        </td>
                        <td className="py-3 px-4 text-slate-400 text-[11px] whitespace-nowrap">
                          {new Date(w.processedAt).toLocaleString()}
                        </td>
                        <td className="py-3 px-4 text-right">
                          <button
                            onClick={() => setSelectedWebhook(w)}
                            className="text-brand-400 hover:text-brand-300 text-xs font-medium hover:underline inline-flex items-center gap-1"
                          >
                            <span>Inspect</span>
                            <ArrowUpRight className="w-3 h-3" />
                          </button>
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>

            {/* Webhook Pagination Footer */}
            <div className="px-4 py-3 bg-surface-800/30 border-t border-surface-800 flex items-center justify-between text-xs text-slate-400">
              <div>
                Showing {webhooks.length > 0 ? (webhookPagination.page - 1) * webhookPagination.limit + 1 : 0} to{' '}
                {Math.min(webhookPagination.page * webhookPagination.limit, webhookPagination.total)} of{' '}
                {webhookPagination.total} events
              </div>

              <div className="flex items-center gap-2">
                <button
                  onClick={() => setWebhookPagination((p) => ({ ...p, page: p.page - 1 }))}
                  disabled={webhookPagination.page <= 1}
                  className="p-1 rounded bg-surface-800 hover:bg-surface-700 disabled:opacity-40 transition"
                >
                  <ChevronLeft className="w-4 h-4" />
                </button>
                <span>
                  Page {webhookPagination.page} of {Math.max(1, webhookPagination.totalPages)}
                </span>
                <button
                  onClick={() => setWebhookPagination((p) => ({ ...p, page: p.page + 1 }))}
                  disabled={webhookPagination.page >= webhookPagination.totalPages}
                  className="p-1 rounded bg-surface-800 hover:bg-surface-700 disabled:opacity-40 transition"
                >
                  <ChevronRight className="w-4 h-4" />
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* ── WEBHOOK INSPECTION MODAL ────────────────────────────────────── */}
      {selectedWebhook && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-surface-900 border border-surface-700 rounded-xl max-w-lg w-full p-5 space-y-4 shadow-xl">
            <div className="flex items-center justify-between border-b border-surface-800 pb-3">
              <div className="flex items-center gap-2">
                <Webhook className="w-5 h-5 text-brand-400" />
                <h3 className="text-sm font-semibold text-white">Webhook Details</h3>
              </div>
              <button
                onClick={() => setSelectedWebhook(null)}
                className="text-slate-400 hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="space-y-2 text-xs">
              <div className="flex justify-between py-1 border-b border-surface-800/60">
                <span className="text-slate-400">Event ID</span>
                <span className="font-mono text-slate-200">{selectedWebhook.eventId}</span>
              </div>
              <div className="flex justify-between py-1 border-b border-surface-800/60">
                <span className="text-slate-400">Event Type</span>
                <span className="font-mono text-brand-300 font-semibold">{selectedWebhook.eventType}</span>
              </div>
              <div className="flex justify-between py-1 border-b border-surface-800/60">
                <span className="text-slate-400">Provider</span>
                <span className="uppercase text-slate-200">{selectedWebhook.provider}</span>
              </div>
              <div className="flex justify-between py-1 border-b border-surface-800/60">
                <span className="text-slate-400">Processed At</span>
                <span className="text-slate-200">{new Date(selectedWebhook.processedAt).toLocaleString()}</span>
              </div>
              <div className="pt-2">
                <span className="text-slate-400 block mb-1.5 font-medium">Payload Keys / Summary:</span>
                <div className="bg-surface-950 p-3 rounded-lg font-mono text-[11px] text-slate-300 border border-surface-800">
                  {JSON.stringify(selectedWebhook.payloadSummary, null, 2)}
                </div>
              </div>
            </div>

            <div className="pt-2 flex justify-end">
              <button
                onClick={() => setSelectedWebhook(null)}
                className="px-4 py-1.5 rounded-lg bg-surface-800 hover:bg-surface-700 text-xs text-slate-200 font-medium transition"
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
