import React, { useEffect, useState } from 'react';
import { api } from '../api/client';
import { useFilter } from '../context/FilterContext';
import {
  Users,
  UserCheck,
  Crown,
  Sparkles,
  CreditCard,
  Banknote,
  Mic,
  Bot,
  TrendingUp,
  TrendingDown,
  AlertTriangle,
  ShieldCheck,
} from 'lucide-react';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  BarChart,
  Bar,
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
} from 'recharts';

export const DashboardPage: React.FC = () => {
  const { dateRange, customStart, customEnd, refreshKey } = useFilter();
  const [data, setData] = useState<any>(null);
  const [healthData, setHealthData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;
    setLoading(true);
    setError(null);

    const query = new URLSearchParams({ range: dateRange });
    if (customStart) query.append('customStart', customStart);
    if (customEnd) query.append('customEnd', customEnd);

    Promise.all([
      api.get(`/api/v1/admin/dashboard?${query.toString()}`),
      api.get('/api/v1/admin/system-health'),
    ])
      .then(([dashRes, healthRes]) => {
        if (!isMounted) return;
        if (dashRes.success) setData(dashRes.data);
        if (healthRes.success) setHealthData(healthRes.data);
      })
      .catch((err) => {
        if (!isMounted) return;
        setError(err.message || 'Failed to load dashboard metrics');
      })
      .finally(() => {
        if (isMounted) setLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, [dateRange, customStart, customEnd, refreshKey]);

  if (loading && !data) {
    return (
      <div className="flex h-64 items-center justify-center">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-brand-500 border-t-transparent rounded-full animate-spin" />
          <span className="text-xs text-slate-400">Loading production analytics...</span>
        </div>
      </div>
    );
  }

  if (error || !data) {
    return (
      <div className="p-4 rounded-xl bg-rose-500/10 border border-rose-500/30 text-rose-300 text-xs flex items-center gap-3">
        <AlertTriangle className="w-5 h-5 text-rose-400 flex-shrink-0" />
        <span>{error || 'Unable to retrieve dashboard data. Ensure backend is running.'}</span>
      </div>
    );
  }

  const { kpis, charts, subscriptionDistribution, aiUsageSummary, recentPayments, recentErrors } = data;

  const contributionMarginRupees = kpis.revenueRupees.value - kpis.aiCostRupees.value;

  return (
    <div className="space-y-6">
      {/* ── TOP 8 KPI CARDS ─────────────────────────────────────────────────── */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {/* Total Users */}
        <KpiCard
          title="Total Users"
          value={kpis.totalUsers.value.toLocaleString()}
          changePercent={kpis.totalUsers.changePercent}
          icon={Users}
          color="indigo"
        />

        {/* Active Users */}
        <KpiCard
          title="Active Users"
          value={kpis.activeUsers.value.toLocaleString()}
          changePercent={kpis.activeUsers.changePercent}
          icon={UserCheck}
          color="blue"
        />

        {/* Pro Users */}
        <KpiCard
          title="Pro Users"
          value={kpis.proUsers.value.toLocaleString()}
          changePercent={kpis.proUsers.changePercent}
          icon={Crown}
          color="amber"
        />

        {/* Free Users */}
        <KpiCard
          title="Free Users"
          value={kpis.freeUsers.value.toLocaleString()}
          changePercent={kpis.freeUsers.changePercent}
          icon={Sparkles}
          color="slate"
        />

        {/* Active Subscriptions */}
        <KpiCard
          title="Active Subscriptions"
          value={kpis.activeSubscriptions.value.toLocaleString()}
          changePercent={kpis.activeSubscriptions.changePercent}
          icon={CreditCard}
          color="violet"
        />

        {/* Monthly Revenue */}
        <KpiCard
          title="Revenue"
          value={`₹${kpis.revenueRupees.value.toLocaleString()}`}
          changePercent={kpis.revenueRupees.changePercent}
          icon={Banknote}
          color="emerald"
        />

        {/* Completed Interviews */}
        <KpiCard
          title="Interviews"
          value={kpis.interviewsCompleted.value.toLocaleString()}
          changePercent={kpis.interviewsCompleted.changePercent}
          icon={Mic}
          color="cyan"
        />

        {/* AI Cost (Month/Period) */}
        <KpiCard
          title="Estimated AI Cost"
          value={`₹${kpis.aiCostRupees.value.toLocaleString()}`}
          changePercent={kpis.aiCostRupees.changePercent}
          icon={Bot}
          color="purple"
          subtext="Estimated API cost"
        />
      </div>

      {/* ── BUSINESS CONTRIBUTION MARGIN BANNER ─────────────────────────────── */}
      <div className="p-4 rounded-xl bg-gradient-to-r from-surface-900 to-surface-850 border border-surface-800 flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-emerald-500/10 border border-emerald-500/30 flex items-center justify-center text-emerald-400">
            <Banknote className="w-5 h-5" />
          </div>
          <div>
            <div className="text-xs text-slate-400">Estimated Contribution Margin (Revenue – AI Cost)</div>
            <div className="text-lg font-bold text-white flex items-center gap-2">
              <span>₹{contributionMarginRupees.toLocaleString()}</span>
              <span className="text-[11px] font-normal text-slate-400">
                (Gross Margin: {kpis.revenueRupees.value > 0 ? Math.round((contributionMarginRupees / kpis.revenueRupees.value) * 100) : 0}%)
              </span>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-6 text-xs text-slate-400">
          <div>
            Revenue: <span className="font-semibold text-slate-200">₹{kpis.revenueRupees.value.toLocaleString()}</span>
          </div>
          <div>
            AI Cost: <span className="font-semibold text-slate-200">₹{kpis.aiCostRupees.value.toLocaleString()}</span>
          </div>
          <div className="text-[10px] text-amber-400 bg-amber-500/10 px-2 py-0.5 rounded border border-amber-500/20">
            Estimated application-side
          </div>
        </div>
      </div>

      {/* ── CHARTS SECTION ─────────────────────────────────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Revenue Over Time */}
        <div className="p-5 rounded-2xl bg-surface-900 border border-surface-800">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-sm font-semibold text-white">Revenue Over Time</h2>
              <p className="text-[11px] text-slate-400">Daily successful payment transactions</p>
            </div>
            <span className="text-xs font-bold text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded-full border border-emerald-500/20">
              Captured Only
            </span>
          </div>
          <div className="h-56">
            {charts.revenueOverTime.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={charts.revenueOverTime}>
                  <defs>
                    <linearGradient id="revGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#10b981" stopOpacity={0.4} />
                      <stop offset="95%" stopColor="#10b981" stopOpacity={0.0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.4} />
                  <XAxis dataKey="date" stroke="#64748b" fontSize={10} tickLine={false} />
                  <YAxis stroke="#64748b" fontSize={10} tickLine={false} tickFormatter={(v) => `₹${v}`} />
                  <Tooltip
                    contentStyle={{ backgroundColor: '#0f172a', borderColor: '#334155', borderRadius: '8px', fontSize: '11px' }}
                    formatter={(val: any) => [`₹${Number(val).toLocaleString()}`, 'Revenue']}
                  />
                  <Area type="monotone" dataKey="revenue" stroke="#10b981" strokeWidth={2} fillOpacity={1} fill="url(#revGrad)" />
                </AreaChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-full flex items-center justify-center text-xs text-slate-500">
                No revenue transactions in this period
              </div>
            )}
          </div>
        </div>

        {/* User Signups Growth */}
        <div className="p-5 rounded-2xl bg-surface-900 border border-surface-800">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-sm font-semibold text-white">User Growth</h2>
              <p className="text-[11px] text-slate-400">New registered candidates per day</p>
            </div>
            <span className="text-xs font-bold text-indigo-400 bg-indigo-500/10 px-2 py-0.5 rounded-full border border-indigo-500/20">
              Registrations
            </span>
          </div>
          <div className="h-56">
            {charts.userGrowthOverTime.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={charts.userGrowthOverTime}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.4} />
                  <XAxis dataKey="date" stroke="#64748b" fontSize={10} tickLine={false} />
                  <YAxis stroke="#64748b" fontSize={10} tickLine={false} />
                  <Tooltip
                    contentStyle={{ backgroundColor: '#0f172a', borderColor: '#334155', borderRadius: '8px', fontSize: '11px' }}
                    formatter={(val: any) => [`${val} users`, 'New Signups']}
                  />
                  <Line type="monotone" dataKey="users" stroke="#6366f1" strokeWidth={2} dot={{ r: 2 }} />
                </LineChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-full flex items-center justify-center text-xs text-slate-500">
                No new registrations in this period
              </div>
            )}
          </div>
        </div>
      </div>

      {/* ── ROW: INTERVIEW ACTIVITY & SUBSCRIPTIONS BREAKDOWN ────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Interview Activity Chart */}
        <div className="lg:col-span-2 p-5 rounded-2xl bg-surface-900 border border-surface-800">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h2 className="text-sm font-semibold text-white">Interview Activity</h2>
              <p className="text-[11px] text-slate-400">Sessions practiced and average candidate performance</p>
            </div>
            <span className="text-xs font-bold text-cyan-400 bg-cyan-500/10 px-2 py-0.5 rounded-full border border-cyan-500/20">
              Sessions
            </span>
          </div>
          <div className="h-56">
            {charts.interviewActivityOverTime.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={charts.interviewActivityOverTime}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#334155" opacity={0.4} />
                  <XAxis dataKey="date" stroke="#64748b" fontSize={10} tickLine={false} />
                  <YAxis stroke="#64748b" fontSize={10} tickLine={false} />
                  <Tooltip
                    contentStyle={{ backgroundColor: '#0f172a', borderColor: '#334155', borderRadius: '8px', fontSize: '11px' }}
                    formatter={(val: any, name: any) => [name === 'total' ? `${val} sessions` : `${val}/100`, name === 'total' ? 'Sessions' : 'Avg Score']}
                  />
                  <Bar dataKey="total" fill="#06b6d4" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            ) : (
              <div className="h-full flex items-center justify-center text-xs text-slate-500">
                No interview sessions in this period
              </div>
            )}
          </div>
        </div>

        {/* Subscription Tier Distribution */}
        <div className="p-5 rounded-2xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div>
            <h2 className="text-sm font-semibold text-white mb-1">Subscription Tiers</h2>
            <p className="text-[11px] text-slate-400 mb-4">Customer membership classification</p>

            <div className="space-y-3.5">
              <DistributionBar
                label="Free Plan"
                count={subscriptionDistribution.freeUsers}
                total={kpis.totalUsers.value}
                color="bg-slate-500"
              />
              <DistributionBar
                label="Pro Monthly"
                count={subscriptionDistribution.proMonthly}
                total={kpis.totalUsers.value}
                color="bg-brand-500"
              />
              <DistributionBar
                label="Pro Yearly"
                count={subscriptionDistribution.proYearly}
                total={kpis.totalUsers.value}
                color="bg-emerald-500"
              />
              <DistributionBar
                label="Cancelled"
                count={subscriptionDistribution.cancelled}
                total={kpis.totalUsers.value}
                color="bg-rose-500"
              />
            </div>
          </div>

          <div className="pt-4 mt-4 border-t border-surface-800 flex items-center justify-between text-xs">
            <span className="text-slate-400">Pro Conversion Rate</span>
            <span className="font-bold text-brand-300">
              {kpis.totalUsers.value > 0
                ? `${Math.round((kpis.proUsers.value / kpis.totalUsers.value) * 1000) / 10}%`
                : '0%'}
            </span>
          </div>
        </div>
      </div>

      {/* ── ROW: AI USAGE SNAPSHOT & SYSTEM HEALTH ───────────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* AI Usage Snapshot */}
        <div className="p-5 rounded-2xl bg-surface-900 border border-surface-800">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <Bot className="w-4 h-4 text-purple-400" />
              <h2 className="text-sm font-semibold text-white">AI Telemetry Snapshot</h2>
            </div>
            <span className="text-[10px] text-purple-300 bg-purple-500/10 px-2 py-0.5 rounded border border-purple-500/20">
              Gemini
            </span>
          </div>

          <div className="grid grid-cols-2 gap-3 text-xs mb-4">
            <div className="p-3 rounded-xl bg-surface-800/60 border border-surface-700/50">
              <span className="text-slate-400 text-[11px]">Requests</span>
              <div className="text-base font-bold text-white mt-0.5">{aiUsageSummary.totalRequests.toLocaleString()}</div>
            </div>
            <div className="p-3 rounded-xl bg-surface-800/60 border border-surface-700/50">
              <span className="text-slate-400 text-[11px]">Avg Latency</span>
              <div className="text-base font-bold text-white mt-0.5">{aiUsageSummary.averageLatencyMs}ms</div>
            </div>
            <div className="p-3 rounded-xl bg-surface-800/60 border border-surface-700/50">
              <span className="text-slate-400 text-[11px]">Total Tokens</span>
              <div className="text-base font-bold text-white mt-0.5">
                {(aiUsageSummary.totalTokens / 1_000_000).toFixed(2)}M
              </div>
            </div>
            <div className="p-3 rounded-xl bg-surface-800/60 border border-surface-700/50">
              <span className="text-slate-400 text-[11px]">Error Rate</span>
              <div className="text-base font-bold text-emerald-400 mt-0.5">{aiUsageSummary.errorRatePercent}%</div>
            </div>
          </div>

          <div className="text-[11px] text-slate-400 flex items-center justify-between pt-2 border-t border-surface-800">
            <span>Input: {(aiUsageSummary.inputTokens / 1_000_000).toFixed(2)}M tokens</span>
            <span>Output: {(aiUsageSummary.outputTokens / 1_000_000).toFixed(2)}M tokens</span>
          </div>
        </div>

        {/* Quick System Health */}
        <div className="p-5 rounded-2xl bg-surface-900 border border-surface-800">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <ShieldCheck className="w-4 h-4 text-emerald-400" />
              <h2 className="text-sm font-semibold text-white">System Subsystems</h2>
            </div>
            <span className={`text-[10px] px-2 py-0.5 rounded font-semibold uppercase ${
              healthData?.overallStatus === 'HEALTHY'
                ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                : 'bg-amber-500/10 text-amber-400 border border-amber-500/20'
            }`}>
              {healthData?.overallStatus || 'HEALTHY'}
            </span>
          </div>

          <div className="space-y-2.5">
            {healthData?.services?.map((s: any) => (
              <div key={s.service} className="flex items-center justify-between p-2 rounded-lg bg-surface-800/40 border border-surface-700/40 text-xs">
                <div className="flex items-center gap-2">
                  <span className={`w-2 h-2 rounded-full ${s.status === 'HEALTHY' ? 'bg-emerald-400' : 'bg-amber-400'}`} />
                  <span className="font-medium text-slate-200">{s.service}</span>
                </div>
                <div className="text-slate-400 text-[11px]">{s.latencyMs}ms</div>
              </div>
            )) || (
              <div className="text-xs text-slate-500">Checking subsystems...</div>
            )}
          </div>
        </div>

        {/* Recent Operational Errors */}
        <div className="p-5 rounded-2xl bg-surface-900 border border-surface-800">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 text-amber-400" />
              <h2 className="text-sm font-semibold text-white">Recent Errors</h2>
            </div>
            <span className="text-[10px] text-slate-400">Latest 10</span>
          </div>

          <div className="space-y-2 overflow-y-auto max-h-52">
            {recentErrors.length > 0 ? (
              recentErrors.map((err: any) => (
                <div key={err.id} className="p-2 rounded-lg bg-surface-800/60 border border-surface-700/40 text-xs">
                  <div className="flex items-center justify-between text-[11px]">
                    <span className="font-semibold text-rose-400">HTTP {err.status}</span>
                    <span className="text-slate-500 text-[10px]">
                      {new Date(err.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </span>
                  </div>
                  <div className="text-slate-300 font-mono text-[10px] mt-0.5 truncate">{err.error}</div>
                  <div className="text-[10px] text-slate-500 mt-0.5 capitalize">{err.service} · {err.operation}</div>
                </div>
              ))
            ) : (
              <div className="h-32 flex flex-col items-center justify-center text-xs text-slate-500">
                <ShieldCheck className="w-6 h-6 text-emerald-400 mb-1 opacity-60" />
                <span>Zero recent errors</span>
              </div>
            )}
          </div>
        </div>
      </div>

      {/* ── RECENT PAYMENTS TABLE ────────────────────────────────────────────── */}
      <div className="p-5 rounded-2xl bg-surface-900 border border-surface-800">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h2 className="text-sm font-semibold text-white">Recent Transactions</h2>
            <p className="text-[11px] text-slate-400">Real-time payment gateway activity</p>
          </div>
          <span className="text-xs text-slate-400">Auto-audited</span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="border-b border-surface-800 text-slate-400">
                <th className="pb-3 font-medium">User</th>
                <th className="pb-3 font-medium">Plan</th>
                <th className="pb-3 font-medium">Amount</th>
                <th className="pb-3 font-medium">Status</th>
                <th className="pb-3 font-medium">Razorpay ID</th>
                <th className="pb-3 font-medium">Date</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-800/50">
              {recentPayments.length > 0 ? (
                recentPayments.map((p: any) => (
                  <tr key={p.id} className="hover:bg-surface-800/30 transition">
                    <td className="py-2.5 font-medium text-slate-200">{p.userEmail}</td>
                    <td className="py-2.5 text-slate-400">{p.planName}</td>
                    <td className="py-2.5 font-semibold text-white">₹{p.amountRupees}</td>
                    <td className="py-2.5">
                      <span className={`px-2 py-0.5 rounded text-[10px] font-semibold ${
                        p.status === 'CAPTURED'
                          ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                          : p.status === 'FAILED'
                          ? 'bg-rose-500/10 text-rose-400 border border-rose-500/20'
                          : 'bg-amber-500/10 text-amber-400 border border-amber-500/20'
                      }`}>
                        {p.status}
                      </span>
                    </td>
                    <td className="py-2.5 text-slate-400 font-mono text-[11px]">{p.providerPaymentId || '—'}</td>
                    <td className="py-2.5 text-slate-500 text-[11px]">
                      {p.paidAt ? new Date(p.paidAt).toLocaleDateString() : '—'}
                    </td>
                  </tr>
                ))
              ) : (
                <tr>
                  <td colSpan={6} className="py-6 text-center text-slate-500">
                    No transactions found in this date range.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

interface KpiCardProps {
  title: string;
  value: string;
  changePercent: number | null;
  icon: any;
  color: 'indigo' | 'blue' | 'amber' | 'slate' | 'violet' | 'emerald' | 'cyan' | 'purple';
  subtext?: string;
}

const KpiCard: React.FC<KpiCardProps> = ({ title, value, changePercent, icon: Icon, color, subtext }) => {
  const colorMap = {
    indigo: 'text-indigo-400 bg-indigo-500/10 border-indigo-500/20',
    blue: 'text-blue-400 bg-blue-500/10 border-blue-500/20',
    amber: 'text-amber-400 bg-amber-500/10 border-amber-500/20',
    slate: 'text-slate-300 bg-slate-500/10 border-slate-500/20',
    violet: 'text-brand-400 bg-brand-500/10 border-brand-500/20',
    emerald: 'text-emerald-400 bg-emerald-500/10 border-emerald-500/20',
    cyan: 'text-cyan-400 bg-cyan-500/10 border-cyan-500/20',
    purple: 'text-purple-400 bg-purple-500/10 border-purple-500/20',
  };

  return (
    <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between transition hover:border-surface-700">
      <div className="flex items-center justify-between mb-2">
        <span className="text-[11px] font-medium text-slate-400">{title}</span>
        <div className={`p-2 rounded-lg border ${colorMap[color]}`}>
          <Icon className="w-4 h-4" />
        </div>
      </div>

      <div>
        <div className="text-xl font-bold text-white tracking-tight">{value}</div>
        <div className="mt-1 flex items-center gap-1.5 text-[10px]">
          {changePercent !== null ? (
            <span className={`flex items-center gap-0.5 font-semibold ${changePercent >= 0 ? 'text-emerald-400' : 'text-rose-400'}`}>
              {changePercent >= 0 ? <TrendingUp className="w-3 h-3" /> : <TrendingDown className="w-3 h-3" />}
              {changePercent >= 0 ? `+${changePercent}%` : `${changePercent}%`}
            </span>
          ) : null}
          <span className="text-slate-500">{subtext || (changePercent !== null ? 'vs previous period' : '')}</span>
        </div>
      </div>
    </div>
  );
};

const DistributionBar: React.FC<{ label: string; count: number; total: number; color: string }> = ({
  label,
  count,
  total,
  color,
}) => {
  const percent = total > 0 ? Math.round((count / total) * 100) : 0;
  return (
    <div>
      <div className="flex justify-between text-xs mb-1">
        <span className="text-slate-300 font-medium">{label}</span>
        <span className="text-slate-400 font-mono text-[11px]">
          {count} ({percent}%)
        </span>
      </div>
      <div className="w-full h-2 bg-surface-800 rounded-full overflow-hidden">
        <div className={`h-full ${color} rounded-full transition-all duration-500`} style={{ width: `${percent}%` }} />
      </div>
    </div>
  );
};
