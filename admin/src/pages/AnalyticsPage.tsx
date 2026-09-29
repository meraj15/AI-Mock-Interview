import React, { useEffect, useState } from 'react';
import { api } from '../api/client';
import { useFilter } from '../context/FilterContext';
import {
  BarChart3,
  Users,
  Target,
  Award,
  Crown,
  TrendingUp,
  Percent,
} from 'lucide-react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';

export const AnalyticsPage: React.FC = () => {
  const { dateRange, refreshKey } = useFilter();
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  const fetchAnalytics = async () => {
    setLoading(true);
    try {
      const res = await api.get(`/api/v1/admin/analytics?range=${dateRange}`);
      if (res.success) {
        setData(res.data);
      }
    } catch (err) {
      console.error('Failed to load analytics:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchAnalytics();
  }, [dateRange, refreshKey]);

  return (
    <div className="space-y-6">
      {/* ── HEADER ────────────────────────────────────────────────────────── */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-white tracking-tight flex items-center gap-2">
            <BarChart3 className="w-6 h-6 text-brand-400" />
            Product & Candidate Analytics
          </h2>
          <p className="text-xs text-slate-400 mt-0.5">
            Engagement metrics (DAU/WAU/MAU), top practiced job roles, candidate score distribution, Free vs Pro usage, and conversion funnel.
          </p>
        </div>
      </div>

      {/* ── ENGAGEMENT CARDS ──────────────────────────────────────────────── */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {/* DAU */}
        <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-medium uppercase tracking-wider">DAU</span>
            <Users className="w-4 h-4 text-brand-400" />
          </div>
          <div className="mt-2 text-2xl font-bold text-white">
            {loading ? '...' : (data?.engagement?.dau || 0).toLocaleString()}
          </div>
          <span className="text-[10px] text-slate-500 mt-1">Daily active candidates</span>
        </div>

        {/* WAU */}
        <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-medium uppercase tracking-wider">WAU</span>
            <TrendingUp className="w-4 h-4 text-indigo-400" />
          </div>
          <div className="mt-2 text-2xl font-bold text-indigo-300">
            {loading ? '...' : (data?.engagement?.wau || 0).toLocaleString()}
          </div>
          <span className="text-[10px] text-slate-500 mt-1">Weekly active candidates</span>
        </div>

        {/* MAU */}
        <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-medium uppercase tracking-wider">MAU</span>
            <Award className="w-4 h-4 text-emerald-400" />
          </div>
          <div className="mt-2 text-2xl font-bold text-emerald-400">
            {loading ? '...' : (data?.engagement?.mau || 0).toLocaleString()}
          </div>
          <span className="text-[10px] text-slate-500 mt-1">Monthly active candidates</span>
        </div>

        {/* DAU / MAU Stickiness */}
        <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-medium uppercase tracking-wider">Stickiness</span>
            <Percent className="w-4 h-4 text-amber-400" />
          </div>
          <div className="mt-2 text-2xl font-bold text-amber-300">
            {loading ? '...' : `${data?.engagement?.dauToMauRatioPercent || 0}%`}
          </div>
          <span className="text-[10px] text-slate-500 mt-1">DAU / MAU ratio</span>
        </div>
      </div>

      {/* ── CHARTS ROW 1: ROLES & SCORE DISTRIBUTION ──────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Top Practicing Roles */}
        <div className="p-5 rounded-xl bg-surface-900 border border-surface-800 space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-semibold text-white flex items-center gap-2">
              <Target className="w-4 h-4 text-brand-400" />
              Top Job Roles Practiced
            </h3>
            <span className="text-xs text-slate-400">By interview volume</span>
          </div>

          {!data?.rolesPracticed || data.rolesPracticed.length === 0 ? (
            <div className="py-12 text-center text-xs text-slate-500">
              No interview sessions recorded for this range.
            </div>
          ) : (
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={data.rolesPracticed} layout="vertical" margin={{ top: 5, right: 20, left: 40, bottom: 5 }}>
                  <XAxis type="number" stroke="#64748b" fontSize={11} />
                  <YAxis type="category" dataKey="role" stroke="#cbd5e1" fontSize={11} width={100} />
                  <Tooltip
                    contentStyle={{ backgroundColor: '#0f172a', borderColor: '#334155', borderRadius: '8px', fontSize: '12px' }}
                    formatter={(value: any, name: any) => [value, name === 'interviewsCount' ? 'Interviews' : name]}
                  />
                  <Bar dataKey="interviewsCount" fill="#6366f1" radius={[0, 4, 4, 0]} name="Interviews" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}
        </div>

        {/* Candidate Score Distribution */}
        <div className="p-5 rounded-xl bg-surface-900 border border-surface-800 space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-sm font-semibold text-white flex items-center gap-2">
              <Award className="w-4 h-4 text-emerald-400" />
              Candidate Score Distribution
            </h3>
            <span className="text-xs text-slate-400">Graded performance bands</span>
          </div>

          {!data?.scoreDistribution || data.scoreDistribution.length === 0 ? (
            <div className="py-12 text-center text-xs text-slate-500">
              No evaluations found.
            </div>
          ) : (
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={data.scoreDistribution} margin={{ top: 10, right: 10, left: -10, bottom: 20 }}>
                  <XAxis dataKey="band" stroke="#64748b" fontSize={10} angle={-15} textAnchor="end" />
                  <YAxis stroke="#64748b" fontSize={11} />
                  <Tooltip
                    contentStyle={{ backgroundColor: '#0f172a', borderColor: '#334155', borderRadius: '8px', fontSize: '12px' }}
                  />
                  <Bar dataKey="count" fill="#10b981" radius={[4, 4, 0, 0]} name="Interviews" />
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}
        </div>
      </div>

      {/* ── CHARTS ROW 2: DIFFICULTY & TYPE BREAKDOWN ─────────────────────── */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Interview Type Breakdown */}
        <div className="p-5 rounded-xl bg-surface-900 border border-surface-800 space-y-4">
          <h3 className="text-sm font-semibold text-white">Interview Type Distribution</h3>
          <div className="grid grid-cols-2 gap-3">
            {!data?.typeBreakdown || data.typeBreakdown.length === 0 ? (
              <div className="col-span-2 py-6 text-center text-xs text-slate-500">No data available</div>
            ) : (
              data.typeBreakdown.map((item: any) => (
                <div
                  key={item.type}
                  className="p-3 rounded-lg bg-surface-800/50 border border-surface-700/50 flex flex-col justify-between"
                >
                  <span className="text-xs font-semibold text-slate-300">{item.type}</span>
                  <div className="mt-2 text-lg font-bold text-brand-300">
                    {item.count.toLocaleString()}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Difficulty Breakdown */}
        <div className="p-5 rounded-xl bg-surface-900 border border-surface-800 space-y-4">
          <h3 className="text-sm font-semibold text-white">Difficulty Breakdown</h3>
          <div className="grid grid-cols-3 gap-3">
            {!data?.difficultyBreakdown || data.difficultyBreakdown.length === 0 ? (
              <div className="col-span-3 py-6 text-center text-xs text-slate-500">No data available</div>
            ) : (
              data.difficultyBreakdown.map((item: any) => {
                const isEasy = item.difficulty === 'EASY';
                const isHard = item.difficulty === 'HARD';
                return (
                  <div
                    key={item.difficulty}
                    className="p-3 rounded-lg bg-surface-800/50 border border-surface-700/50 flex flex-col justify-between text-center"
                  >
                    <span
                      className={`text-xs font-bold uppercase ${
                        isEasy ? 'text-emerald-400' : isHard ? 'text-rose-400' : 'text-amber-400'
                      }`}
                    >
                      {item.difficulty}
                    </span>
                    <div className="mt-2 text-xl font-bold text-white">
                      {item.count.toLocaleString()}
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </div>
      </div>

      {/* ── FREE VS PRO CANDIDATE COMPARISON ──────────────────────────────── */}
      <div className="p-5 rounded-xl bg-surface-900 border border-surface-800 space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="text-sm font-semibold text-white flex items-center gap-2">
            <Crown className="w-4 h-4 text-amber-400" />
            Free vs. Pro Candidate Behavior Comparison
          </h3>
          <span className="text-xs text-slate-400">Cohort engagement analysis</span>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {/* User Pool */}
          <div className="p-4 rounded-xl bg-surface-800/40 border border-surface-700/40">
            <span className="text-[11px] font-medium uppercase text-slate-400 block">Candidate Pool</span>
            <div className="mt-2 space-y-1">
              <div className="flex justify-between text-xs">
                <span className="text-slate-400">Free:</span>
                <strong className="text-slate-200">{(data?.freeVsProComparison?.freeUsers || 0).toLocaleString()}</strong>
              </div>
              <div className="flex justify-between text-xs">
                <span className="text-amber-400 font-medium">Pro:</span>
                <strong className="text-amber-300">{(data?.freeVsProComparison?.proUsers || 0).toLocaleString()}</strong>
              </div>
            </div>
          </div>

          {/* Average Score */}
          <div className="p-4 rounded-xl bg-surface-800/40 border border-surface-700/40">
            <span className="text-[11px] font-medium uppercase text-slate-400 block">Average Score</span>
            <div className="mt-2 space-y-1">
              <div className="flex justify-between text-xs">
                <span className="text-slate-400">Free:</span>
                <strong className="text-slate-200">{data?.freeVsProComparison?.freeAverageScore || 0}%</strong>
              </div>
              <div className="flex justify-between text-xs">
                <span className="text-emerald-400 font-medium">Pro:</span>
                <strong className="text-emerald-300">{data?.freeVsProComparison?.proAverageScore || 0}%</strong>
              </div>
            </div>
          </div>

          {/* Interviews Practiced */}
          <div className="p-4 rounded-xl bg-surface-800/40 border border-surface-700/40">
            <span className="text-[11px] font-medium uppercase text-slate-400 block">Avg Sessions / User</span>
            <div className="mt-2 space-y-1">
              <div className="flex justify-between text-xs">
                <span className="text-slate-400">Free:</span>
                <strong className="text-slate-200">{data?.freeVsProComparison?.freeAvgInterviewsPerUser || 0}</strong>
              </div>
              <div className="flex justify-between text-xs">
                <span className="text-brand-400 font-medium">Pro:</span>
                <strong className="text-brand-300">{data?.freeVsProComparison?.proAvgInterviewsPerUser || 0}</strong>
              </div>
            </div>
          </div>

          {/* Voice & Resume Usage */}
          <div className="p-4 rounded-xl bg-surface-800/40 border border-surface-700/40">
            <span className="text-[11px] font-medium uppercase text-slate-400 block">Pro Feature Usage</span>
            <div className="mt-2 space-y-1">
              <div className="flex justify-between text-xs">
                <span className="text-slate-400">Voice Mins:</span>
                <strong className="text-slate-200">{(data?.freeVsProComparison?.proTotalVoiceMinutes || 0).toLocaleString()}m</strong>
              </div>
              <div className="flex justify-between text-xs">
                <span className="text-slate-400">Resume Scans:</span>
                <strong className="text-slate-200">{(data?.freeVsProComparison?.proTotalResumeScans || 0).toLocaleString()}</strong>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* ── CONVERSION FUNNEL ─────────────────────────────────────────────── */}
      <div className="p-5 rounded-xl bg-surface-900 border border-surface-800 space-y-4">
        <div className="flex items-center justify-between">
          <h3 className="text-sm font-semibold text-white flex items-center gap-2">
            <TrendingUp className="w-4 h-4 text-emerald-400" />
            Product Conversion Funnel
          </h3>
          <span className="text-xs text-slate-400">Acquisition to recurring Pro membership</span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-5 gap-3 pt-2">
          {!data?.conversionFunnel || data.conversionFunnel.length === 0 ? (
            <div className="col-span-5 py-6 text-center text-xs text-slate-500">No funnel data available</div>
          ) : (
            data.conversionFunnel.map((step: any, idx: number) => (
              <div
                key={step.stage}
                className="relative p-4 rounded-xl bg-surface-800/60 border border-surface-700/50 flex flex-col justify-between"
              >
                <div>
                  <div className="text-[10px] font-bold uppercase text-slate-400 tracking-wider">
                    Stage {idx + 1}
                  </div>
                  <div className="text-xs font-semibold text-slate-200 mt-1">
                    {step.stage}
                  </div>
                </div>

                <div className="mt-4">
                  <div className="text-xl font-bold text-white">
                    {step.count.toLocaleString()}
                  </div>
                  <div className="mt-1 text-[11px] font-semibold text-brand-400 flex items-center gap-1">
                    <span>{step.conversionPercent}%</span>
                    <span className="text-slate-500 font-normal">conversion</span>
                  </div>
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
};
