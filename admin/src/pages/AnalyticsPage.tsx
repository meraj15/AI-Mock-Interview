import React, { useEffect, useState, useMemo } from 'react';
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
  ListOrdered,
  BarChart2,
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
  const [rolesViewMode, setRolesViewMode] = useState<'leaderboard' | 'chart'>('leaderboard');

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

  // Clean & normalize roles (title case, trim, group case variations)
  const normalizedRoles = useMemo(() => {
    if (!data?.rolesPracticed || !Array.isArray(data.rolesPracticed)) return [];

    const map = new Map<string, { role: string; interviewsCount: number; totalScore: number }>();

    for (const r of data.rolesPracticed) {
      const raw = (r.role || 'General Software Engineer').trim();
      // Capitalize first letter of each word for clean presentation
      const cleanName = raw
        .toLowerCase()
        .replace(/\b\w/g, (char: string) => char.toUpperCase());

      const count = Number(r.interviewsCount) || 0;
      const score = (Number(r.averageScore) || 0) * count;

      if (map.has(cleanName)) {
        const existing = map.get(cleanName)!;
        existing.interviewsCount += count;
        existing.totalScore += score;
      } else {
        map.set(cleanName, {
          role: cleanName,
          interviewsCount: count,
          totalScore: score,
        });
      }
    }

    const totalInterviews = Array.from(map.values()).reduce((acc, curr) => acc + curr.interviewsCount, 0);

    return Array.from(map.values())
      .map((item) => ({
        role: item.role,
        interviewsCount: item.interviewsCount,
        averageScore: item.interviewsCount > 0 ? Math.round(item.totalScore / item.interviewsCount) : 0,
        percentage: totalInterviews > 0 ? Math.round((item.interviewsCount / totalInterviews) * 100) : 0,
      }))
      .sort((a, b) => b.interviewsCount - a.interviewsCount);
  }, [data]);

  // Total scores across cohort
  const scoreStats = useMemo(() => {
    if (!data?.scoreDistribution) return { total: 0, bands: [] };
    const bands = data.scoreDistribution;
    const total = bands.reduce((acc: number, curr: any) => acc + (curr.count || 0), 0);
    return { total, bands };
  }, [data]);

  const scoreTierDetails = [
    {
      name: 'Needs Practice',
      range: '0 – 49',
      color: 'rose',
      borderClass: 'border-rose-500/25',
      bgClass: 'bg-rose-500/10',
      textClass: 'text-rose-400',
      barBg: 'bg-rose-500',
      description: 'Requires fundamentals revision & more mock drills',
    },
    {
      name: 'Average',
      range: '50 – 69',
      color: 'amber',
      borderClass: 'border-amber-500/25',
      bgClass: 'bg-amber-500/10',
      textClass: 'text-amber-400',
      barBg: 'bg-amber-500',
      description: 'Meets foundational baseline interview standards',
    },
    {
      name: 'Strong',
      range: '70 – 84',
      color: 'indigo',
      borderClass: 'border-indigo-500/25',
      bgClass: 'bg-indigo-500/10',
      textClass: 'text-indigo-400',
      barBg: 'bg-indigo-500',
      description: 'Demonstrates strong technical & behavioral skills',
    },
    {
      name: 'Exceptional',
      range: '85 – 100',
      color: 'emerald',
      borderClass: 'border-emerald-500/25',
      bgClass: 'bg-emerald-500/10',
      textClass: 'text-emerald-400',
      barBg: 'bg-emerald-500',
      description: 'Top-tier performance, interview ready candidate',
    },
  ];

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
            Engagement metrics (DAU/WAU/MAU), practiced roles leaderboard, candidate performance tiers, and conversion funnel.
          </p>
        </div>
      </div>

      {/* ── ENGAGEMENT CARDS ──────────────────────────────────────────────── */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {/* DAU */}
        <div className="p-4 rounded-2xl bg-surface-900/90 border border-white/[0.06] backdrop-blur-sm flex flex-col justify-between shadow-sm">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-semibold uppercase tracking-wider text-slate-400">DAU</span>
            <Users className="w-4 h-4 text-brand-400" />
          </div>
          <div className="mt-2 text-2xl font-extrabold text-white">
            {loading ? '...' : (data?.engagement?.dau || 0).toLocaleString()}
          </div>
          <span className="text-[10px] text-slate-500 mt-1">Daily active candidates</span>
        </div>

        {/* WAU */}
        <div className="p-4 rounded-2xl bg-surface-900/90 border border-white/[0.06] backdrop-blur-sm flex flex-col justify-between shadow-sm">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-semibold uppercase tracking-wider text-slate-400">WAU</span>
            <TrendingUp className="w-4 h-4 text-indigo-400" />
          </div>
          <div className="mt-2 text-2xl font-extrabold text-indigo-300">
            {loading ? '...' : (data?.engagement?.wau || 0).toLocaleString()}
          </div>
          <span className="text-[10px] text-slate-500 mt-1">Weekly active candidates</span>
        </div>

        {/* MAU */}
        <div className="p-4 rounded-2xl bg-surface-900/90 border border-white/[0.06] backdrop-blur-sm flex flex-col justify-between shadow-sm">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-semibold uppercase tracking-wider text-slate-400">MAU</span>
            <Award className="w-4 h-4 text-emerald-400" />
          </div>
          <div className="mt-2 text-2xl font-extrabold text-emerald-400">
            {loading ? '...' : (data?.engagement?.mau || 0).toLocaleString()}
          </div>
          <span className="text-[10px] text-slate-500 mt-1">Monthly active candidates</span>
        </div>

        {/* DAU / MAU Stickiness */}
        <div className="p-4 rounded-2xl bg-surface-900/90 border border-white/[0.06] backdrop-blur-sm flex flex-col justify-between shadow-sm">
          <div className="flex items-center justify-between text-slate-400">
            <span className="text-[11px] font-semibold uppercase tracking-wider text-slate-400">Stickiness</span>
            <Percent className="w-4 h-4 text-amber-400" />
          </div>
          <div className="mt-2 text-2xl font-extrabold text-amber-300">
            {loading ? '...' : `${data?.engagement?.dauToMauRatioPercent || 0}%`}
          </div>
          <span className="text-[10px] text-slate-500 mt-1">DAU / MAU ratio</span>
        </div>
      </div>

      {/* ── ROW 1: ROLES & SCORE DISTRIBUTION ─────────────────────────────── */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 1. TOP PRACTICED JOB ROLES */}
        <div className="p-5 rounded-2xl bg-surface-900/90 border border-white/[0.06] backdrop-blur-sm space-y-4 shadow-sm">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <div className="p-1.5 rounded-lg bg-brand-500/10 border border-brand-500/20 text-brand-400">
                <Target className="w-4 h-4" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-white tracking-tight">Top Job Roles Practiced</h3>
                <p className="text-[11px] text-slate-400">Ranked by mock interview volume</p>
              </div>
            </div>

            {/* View Switcher: Leaderboard vs Chart */}
            <div className="flex items-center p-0.5 rounded-lg bg-surface-800/80 border border-white/[0.06] text-xs">
              <button
                onClick={() => setRolesViewMode('leaderboard')}
                className={`flex items-center gap-1 px-2.5 py-1 rounded-md text-[11px] font-semibold transition ${
                  rolesViewMode === 'leaderboard'
                    ? 'bg-brand-600 text-white shadow-sm'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                <ListOrdered className="w-3 h-3" />
                <span>Rankings</span>
              </button>
              <button
                onClick={() => setRolesViewMode('chart')}
                className={`flex items-center gap-1 px-2.5 py-1 rounded-md text-[11px] font-semibold transition ${
                  rolesViewMode === 'chart'
                    ? 'bg-brand-600 text-white shadow-sm'
                    : 'text-slate-400 hover:text-white'
                }`}
              >
                <BarChart2 className="w-3 h-3" />
                <span>Chart</span>
              </button>
            </div>
          </div>

          {normalizedRoles.length === 0 ? (
            <div className="py-12 text-center text-xs text-slate-500">
              No interview sessions recorded for this range.
            </div>
          ) : rolesViewMode === 'leaderboard' ? (
            /* Sleek Ranking List */
            <div className="space-y-2.5 max-h-[340px] overflow-y-auto pr-1">
              {normalizedRoles.map((r, idx) => {
                const isTop3 = idx < 3;
                const medalColors = [
                  'bg-amber-500/15 text-amber-300 border-amber-500/30',
                  'bg-slate-300/15 text-slate-200 border-slate-300/30',
                  'bg-amber-700/15 text-amber-500 border-amber-700/30',
                ];
                return (
                  <div
                    key={r.role}
                    className="p-3 rounded-xl bg-surface-800/40 border border-white/[0.04] hover:border-brand-500/30 transition-all hover:bg-surface-800/70"
                  >
                    <div className="flex items-center justify-between mb-1.5">
                      <div className="flex items-center gap-2.5 min-w-0">
                        <span
                          className={`w-6 h-6 rounded-lg flex items-center justify-center text-xs font-bold font-mono border ${
                            isTop3
                              ? medalColors[idx]
                              : 'bg-surface-700/50 text-slate-400 border-white/[0.05]'
                          }`}
                        >
                          #{idx + 1}
                        </span>
                        <span className="font-semibold text-xs text-white truncate max-w-[200px] sm:max-w-xs">
                          {r.role}
                        </span>
                      </div>

                      <div className="flex items-center gap-2 flex-shrink-0">
                        <span className="text-[11px] font-medium text-slate-400">
                          <strong className="text-white">{r.interviewsCount}</strong> {r.interviewsCount === 1 ? 'interview' : 'interviews'}
                        </span>
                        <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-brand-500/15 text-brand-300 border border-brand-500/25">
                          Avg {r.averageScore}%
                        </span>
                      </div>
                    </div>

                    {/* Progress meter */}
                    <div className="w-full h-1.5 bg-surface-950/80 rounded-full overflow-hidden">
                      <div
                        className="h-full bg-gradient-to-r from-brand-500 to-indigo-400 rounded-full transition-all duration-500"
                        style={{ width: `${Math.max(5, r.percentage)}%` }}
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            /* Clean Vertical Bar Chart View */
            <div className="h-72 pt-2">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={normalizedRoles.slice(0, 6)} margin={{ top: 10, right: 10, left: -20, bottom: 20 }}>
                  <defs>
                    <linearGradient id="roleBarGrad" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor="#8b5cf6" stopOpacity={0.9} />
                      <stop offset="100%" stopColor="#4c1d95" stopOpacity={0.5} />
                    </linearGradient>
                  </defs>
                  <XAxis
                    dataKey="role"
                    stroke="#64748b"
                    fontSize={11}
                    tickFormatter={(val: string) => (val.length > 12 ? `${val.substring(0, 12)}…` : val)}
                  />
                  <YAxis stroke="#64748b" fontSize={11} allowDecimals={false} />
                  <Tooltip
                    contentStyle={{
                      backgroundColor: '#0d131f',
                      borderColor: 'rgba(255,255,255,0.1)',
                      borderRadius: '12px',
                      fontSize: '12px',
                      boxShadow: '0 10px 25px -5px rgba(0,0,0,0.5)',
                    }}
                    formatter={(val: any) => [`${val} interviews`, 'Volume']}
                  />
                  <Bar dataKey="interviewsCount" fill="url(#roleBarGrad)" radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
          )}
        </div>

        {/* 2. CANDIDATE SCORE DISTRIBUTION */}
        <div className="p-5 rounded-2xl bg-surface-900/90 border border-white/[0.06] backdrop-blur-sm space-y-4 shadow-sm flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between mb-3">
              <div className="flex items-center gap-2">
                <div className="p-1.5 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-emerald-400">
                  <Award className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-white tracking-tight">Candidate Score Distribution</h3>
                  <p className="text-[11px] text-slate-400">Graded performance bands across all interviews</p>
                </div>
              </div>

              <div className="text-right">
                <span className="text-[10px] uppercase font-semibold text-slate-500 block">Total Graded</span>
                <span className="text-sm font-bold text-white font-mono">{scoreStats.total} sessions</span>
              </div>
            </div>

            {/* Continuous Stacked Ratio Bar */}
            <div className="mb-4">
              <div className="w-full h-3 bg-surface-950 rounded-full overflow-hidden flex p-0.5 gap-0.5 border border-white/[0.05]">
                {scoreStats.total === 0 ? (
                  <div className="w-full h-full bg-surface-800 rounded-full" />
                ) : (
                  scoreTierDetails.map((tier, idx) => {
                    const count = data?.scoreDistribution?.[idx]?.count || 0;
                    const pct = scoreStats.total > 0 ? (count / scoreStats.total) * 100 : 0;
                    if (pct === 0) return null;
                    return (
                      <div
                        key={tier.name}
                        title={`${tier.name}: ${count} (${Math.round(pct)}%)`}
                        className={`h-full ${tier.barBg} first:rounded-l-full last:rounded-r-full transition-all duration-500`}
                        style={{ width: `${pct}%` }}
                      />
                    );
                  })
                )}
              </div>
            </div>

            {/* 4 Performance Tier Breakdown Cards */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
              {scoreTierDetails.map((tier, idx) => {
                const count = data?.scoreDistribution?.[idx]?.count || 0;
                const percentage = scoreStats.total > 0 ? Math.round((count / scoreStats.total) * 100) : 0;

                return (
                  <div
                    key={tier.name}
                    className={`p-3 rounded-xl bg-surface-800/40 border ${tier.borderClass} flex flex-col justify-between space-y-2 hover:bg-surface-800/70 transition`}
                  >
                    <div className="flex items-center justify-between">
                      <div>
                        <div className={`text-xs font-bold ${tier.textClass}`}>
                          {tier.name}
                        </div>
                        <span className="text-[10px] font-mono text-slate-400">
                          Score {tier.range}
                        </span>
                      </div>

                      <div className="text-right">
                        <span className="text-base font-extrabold text-white font-mono block leading-none">
                          {count}
                        </span>
                        <span className="text-[10px] font-semibold text-slate-400">
                          {percentage}%
                        </span>
                      </div>
                    </div>

                    <div className="w-full h-1.5 bg-surface-950 rounded-full overflow-hidden">
                      <div
                        className={`h-full ${tier.barBg} rounded-full`}
                        style={{ width: `${percentage}%` }}
                      />
                    </div>

                    <p className="text-[10px] text-slate-400 leading-tight">
                      {tier.description}
                    </p>
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      </div>

      {/* ── ROW 2: DIFFICULTY & TYPE BREAKDOWN ─────────────────────────────── */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Interview Type Breakdown */}
        <div className="p-5 rounded-2xl bg-surface-900/90 border border-white/[0.06] backdrop-blur-sm space-y-4 shadow-sm">
          <h3 className="text-sm font-bold text-white tracking-tight">Interview Type Distribution</h3>
          <div className="grid grid-cols-2 gap-3">
            {!data?.typeBreakdown || data.typeBreakdown.length === 0 ? (
              <div className="col-span-2 py-6 text-center text-xs text-slate-500">No data available</div>
            ) : (
              data.typeBreakdown.map((item: any) => (
                <div
                  key={item.type}
                  className="p-3.5 rounded-xl bg-surface-800/40 border border-white/[0.05] hover:border-brand-500/30 flex flex-col justify-between transition"
                >
                  <span className="text-xs font-semibold text-slate-300">{item.type}</span>
                  <div className="mt-2 text-xl font-extrabold text-brand-300 font-mono">
                    {item.count.toLocaleString()}
                  </div>
                </div>
              ))
            )}
          </div>
        </div>

        {/* Difficulty Breakdown */}
        <div className="p-5 rounded-2xl bg-surface-900/90 border border-white/[0.06] backdrop-blur-sm space-y-4 shadow-sm">
          <h3 className="text-sm font-bold text-white tracking-tight">Difficulty Breakdown</h3>
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
                    className="p-3.5 rounded-xl bg-surface-800/40 border border-white/[0.05] hover:border-white/[0.15] flex flex-col justify-between text-center transition"
                  >
                    <span
                      className={`text-xs font-extrabold uppercase tracking-wider ${
                        isEasy ? 'text-emerald-400' : isHard ? 'text-rose-400' : 'text-amber-400'
                      }`}
                    >
                      {item.difficulty}
                    </span>
                    <div className="mt-2 text-2xl font-extrabold text-white font-mono">
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
      <div className="p-5 rounded-2xl bg-surface-900/90 border border-white/[0.06] backdrop-blur-sm space-y-4 shadow-sm">
        <div className="flex items-center justify-between">
          <h3 className="text-sm font-bold text-white flex items-center gap-2">
            <Crown className="w-4 h-4 text-amber-400" />
            Free vs. Pro Candidate Behavior Comparison
          </h3>
          <span className="text-xs text-slate-400">Cohort engagement analysis</span>
        </div>

        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {/* User Pool */}
          <div className="p-4 rounded-xl bg-surface-800/40 border border-white/[0.05]">
            <span className="text-[11px] font-semibold uppercase text-slate-400 block">Candidate Pool</span>
            <div className="mt-2 space-y-1">
              <div className="flex justify-between text-xs">
                <span className="text-slate-400">Free:</span>
                <strong className="text-slate-200 font-mono">{(data?.freeVsProComparison?.freeUsers || 0).toLocaleString()}</strong>
              </div>
              <div className="flex justify-between text-xs">
                <span className="text-amber-400 font-medium">Pro:</span>
                <strong className="text-amber-300 font-mono">{(data?.freeVsProComparison?.proUsers || 0).toLocaleString()}</strong>
              </div>
            </div>
          </div>

          {/* Average Score */}
          <div className="p-4 rounded-xl bg-surface-800/40 border border-white/[0.05]">
            <span className="text-[11px] font-semibold uppercase text-slate-400 block">Average Score</span>
            <div className="mt-2 space-y-1">
              <div className="flex justify-between text-xs">
                <span className="text-slate-400">Free:</span>
                <strong className="text-slate-200 font-mono">{data?.freeVsProComparison?.freeAverageScore || 0}%</strong>
              </div>
              <div className="flex justify-between text-xs">
                <span className="text-emerald-400 font-medium">Pro:</span>
                <strong className="text-emerald-300 font-mono">{data?.freeVsProComparison?.proAverageScore || 0}%</strong>
              </div>
            </div>
          </div>

          {/* Interviews Practiced */}
          <div className="p-4 rounded-xl bg-surface-800/40 border border-white/[0.05]">
            <span className="text-[11px] font-semibold uppercase text-slate-400 block">Avg Sessions / User</span>
            <div className="mt-2 space-y-1">
              <div className="flex justify-between text-xs">
                <span className="text-slate-400">Free:</span>
                <strong className="text-slate-200 font-mono">{data?.freeVsProComparison?.freeAvgInterviewsPerUser || 0}</strong>
              </div>
              <div className="flex justify-between text-xs">
                <span className="text-brand-400 font-medium">Pro:</span>
                <strong className="text-brand-300 font-mono">{data?.freeVsProComparison?.proAvgInterviewsPerUser || 0}</strong>
              </div>
            </div>
          </div>

          {/* Voice & Resume Usage */}
          <div className="p-4 rounded-xl bg-surface-800/40 border border-white/[0.05]">
            <span className="text-[11px] font-semibold uppercase text-slate-400 block">Pro Feature Usage</span>
            <div className="mt-2 space-y-1">
              <div className="flex justify-between text-xs">
                <span className="text-slate-400">Voice:</span>
                <strong className="text-slate-200 font-mono">{(data?.freeVsProComparison?.proTotalVoiceMinutes || 0).toLocaleString()}m</strong>
              </div>
              <div className="flex justify-between text-xs">
                <span className="text-slate-400">Resumes:</span>
                <strong className="text-slate-200 font-mono">{(data?.freeVsProComparison?.proTotalResumeScans || 0).toLocaleString()}</strong>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* ── CONVERSION FUNNEL ─────────────────────────────────────────────── */}
      <div className="p-5 rounded-2xl bg-surface-900/90 border border-white/[0.06] backdrop-blur-sm space-y-4 shadow-sm">
        <div className="flex items-center justify-between">
          <h3 className="text-sm font-bold text-white flex items-center gap-2">
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
                className="relative p-4 rounded-xl bg-surface-800/50 border border-white/[0.05] hover:border-brand-500/30 flex flex-col justify-between transition"
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
                  <div className="text-xl font-extrabold text-white font-mono">
                    {step.count.toLocaleString()}
                  </div>
                  <div className="mt-1 text-[11px] font-bold text-brand-400 flex items-center gap-1">
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
