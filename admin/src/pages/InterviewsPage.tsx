import React, { useEffect, useState } from 'react';
import { api } from '../api/client';
import { useFilter } from '../context/FilterContext';
import {
  Search,
  Download,
  ChevronLeft,
  ChevronRight,
  Eye,
  X,
  Bot,
} from 'lucide-react';

export const InterviewsPage: React.FC = () => {
  const { refreshKey } = useFilter();
  const [interviews, setInterviews] = useState<any[]>([]);
  const [pagination, setPagination] = useState({ page: 1, limit: 15, total: 0, totalPages: 1 });
  const [loading, setLoading] = useState(true);

  // Filters
  const [search, setSearch] = useState('');
  const [appliedSearch, setAppliedSearch] = useState('');
  const [difficulty, setDifficulty] = useState('ALL');
  const [type, setType] = useState('ALL');

  // Detail Modal
  const [selectedSessionId, setSelectedSessionId] = useState<string | null>(null);
  const [sessionDetail, setSessionDetail] = useState<any>(null);
  const [detailLoading, setDetailLoading] = useState(false);

  const fetchInterviews = async (overrideSearch?: string, overridePage?: number) => {
    setLoading(true);
    try {
      const activeSearch = overrideSearch !== undefined ? overrideSearch : appliedSearch;
      const activePage = overridePage !== undefined ? overridePage : pagination.page;

      const q = new URLSearchParams({
        page: activePage.toString(),
        limit: pagination.limit.toString(),
      });
      if (activeSearch.trim()) q.append('search', activeSearch.trim());
      if (difficulty !== 'ALL') q.append('difficulty', difficulty);
      if (type !== 'ALL') q.append('type', type);

      const res = await api.get(`/api/v1/admin/interviews?${q.toString()}`);
      if (res.success) {
        setInterviews(res.interviews);
        setPagination(res.pagination);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchInterviews();
  }, [pagination.page, difficulty, type, appliedSearch, refreshKey]);

  // Live debounced search & instant reset when input is cleared ("when nothing then show all interviews")
  useEffect(() => {
    if (search.trim() === '') {
      if (appliedSearch !== '') {
        setAppliedSearch('');
        setPagination((p) => ({ ...p, page: 1 }));
      }
      return;
    }

    const timer = setTimeout(() => {
      if (search.trim() !== appliedSearch) {
        setAppliedSearch(search.trim());
        setPagination((p) => ({ ...p, page: 1 }));
      }
    }, 350);

    return () => clearTimeout(timer);
  }, [search, appliedSearch]);

  const handleSearchSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = search.trim();
    setPagination((p) => ({ ...p, page: 1 }));
    if (trimmed === appliedSearch) {
      fetchInterviews(trimmed, 1);
    } else {
      setAppliedSearch(trimmed);
    }
  };

  const handleClearSearch = () => {
    setSearch('');
    setPagination((p) => ({ ...p, page: 1 }));
    if (appliedSearch === '') {
      fetchInterviews('', 1);
    } else {
      setAppliedSearch('');
    }
  };

  const handleOpenDetail = async (id: string) => {
    setSelectedSessionId(id);
    setDetailLoading(true);
    try {
      const res = await api.get(`/api/v1/admin/interviews/${id}`);
      if (res.success) {
        setSessionDetail(res.data);
      }
    } catch (err) {
      console.error(err);
    } finally {
      setDetailLoading(false);
    }
  };

  const handleExportCsv = () => {
    const q = new URLSearchParams();
    if (appliedSearch.trim()) q.append('search', appliedSearch.trim());
    if (difficulty !== 'ALL') q.append('difficulty', difficulty);
    if (type !== 'ALL') q.append('type', type);
    api.downloadCsv(`/api/v1/admin/interviews/export?${q.toString()}`, 'interviews-export.csv');
  };

  return (
    <div className="space-y-5">
      {/* ── FILTER & SEARCH BAR ────────────────────────────────────────── */}
      <div className="p-4 rounded-xl bg-surface-900 border border-surface-800 flex flex-wrap items-center justify-between gap-4">
        <form onSubmit={handleSearchSubmit} className="flex items-center gap-2 flex-1 min-w-[240px] max-w-md">
          <div className="relative w-full">
            <Search className="w-3.5 h-3.5 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2 pointer-events-none" />
            <input
              type="text"
              placeholder="Search by role, session ID, or user email..."
              value={search}
              onChange={(e) => {
                const val = e.target.value;
                setSearch(val);
                if (!val.trim() && appliedSearch) {
                  setPagination((p) => ({ ...p, page: 1 }));
                  setAppliedSearch('');
                }
              }}
              className="w-full bg-surface-800 border border-surface-700/60 rounded-lg pl-9 pr-8 py-1.5 text-xs text-slate-100 placeholder-slate-500 focus:outline-none focus:border-brand-500 transition"
            />
            {search.length > 0 && (
              <button
                type="button"
                onClick={handleClearSearch}
                className="absolute right-2.5 top-1/2 -translate-y-1/2 text-slate-400 hover:text-white p-0.5 rounded transition"
                title="Clear search and show all interviews"
              >
                <X className="w-3.5 h-3.5" />
              </button>
            )}
          </div>
          <button
            type="submit"
            className="px-3 py-1.5 bg-surface-800 hover:bg-surface-700 border border-surface-700 text-xs font-medium text-slate-200 rounded-lg transition"
          >
            Search
          </button>
        </form>

        <div className="flex items-center gap-2.5 flex-wrap text-xs">
          <select
            value={difficulty}
            onChange={(e) => { setDifficulty(e.target.value); setPagination(p => ({ ...p, page: 1 })); }}
            className="bg-surface-800 border border-surface-700/60 rounded-lg px-2.5 py-1.5 text-slate-200 focus:outline-none"
          >
            <option value="ALL">All Difficulties</option>
            <option value="junior">Junior</option>
            <option value="mid">Mid-Level</option>
            <option value="senior">Senior</option>
          </select>

          <select
            value={type}
            onChange={(e) => { setType(e.target.value); setPagination(p => ({ ...p, page: 1 })); }}
            className="bg-surface-800 border border-surface-700/60 rounded-lg px-2.5 py-1.5 text-slate-200 focus:outline-none"
          >
            <option value="ALL">All Types</option>
            <option value="TECHNICAL">Technical</option>
            <option value="BEHAVIORAL">Behavioral</option>
            <option value="SYSTEM_DESIGN">System Design</option>
          </select>

          <button
            onClick={handleExportCsv}
            className="flex items-center gap-1.5 px-3 py-1.5 bg-surface-800 hover:bg-surface-700 border border-surface-700 text-slate-200 rounded-lg transition"
          >
            <Download className="w-3.5 h-3.5" />
            <span>Export CSV</span>
          </button>
        </div>
      </div>

      {/* ── INTERVIEWS TABLE ────────────────────────────────────────────── */}
      <div className="rounded-xl bg-surface-900 border border-surface-800 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="border-b border-surface-800 bg-surface-850/50 text-slate-400">
                <th className="py-3 px-4 font-medium">Session ID & Candidate</th>
                <th className="py-3 px-4 font-medium">Role</th>
                <th className="py-3 px-4 font-medium">Type</th>
                <th className="py-3 px-4 font-medium">Difficulty</th>
                <th className="py-3 px-4 font-medium text-center">Questions</th>
                <th className="py-3 px-4 font-medium text-center">Score</th>
                <th className="py-3 px-4 font-medium">Hiring Band</th>
                <th className="py-3 px-4 font-medium">Duration</th>
                <th className="py-3 px-4 font-medium">Date</th>
                <th className="py-3 px-4 font-medium text-right">Inspect</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-surface-800/60">
              {loading ? (
                <tr>
                  <td colSpan={10} className="py-12 text-center text-slate-500">
                    Loading interview sessions...
                  </td>
                </tr>
              ) : interviews.length === 0 ? (
                <tr>
                  <td colSpan={10} className="py-12 text-center text-slate-500">
                    No interview sessions found.
                  </td>
                </tr>
              ) : (
                interviews.map((item) => (
                  <tr key={item.id} className="hover:bg-surface-800/30 transition">
                    <td className="py-3 px-4">
                      <div className="font-semibold text-slate-200">{item.userName}</div>
                      <div className="text-[11px] text-slate-400">{item.userEmail}</div>
                      <div className="text-[10px] text-slate-500 font-mono">{item.id.slice(0, 12)}...</div>
                    </td>
                    <td className="py-3 px-4 font-medium text-white">{item.role}</td>
                    <td className="py-3 px-4 text-slate-300 capitalize">{item.type}</td>
                    <td className="py-3 px-4">
                      <span className="px-2 py-0.5 rounded text-[10px] font-semibold bg-surface-800 text-slate-300 border border-surface-700 capitalize">
                        {item.difficulty}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-center font-mono text-slate-300">
                      {item.questionsAnswered}/{item.questionCount}
                    </td>
                    <td className="py-3 px-4 text-center">
                      <span className={`px-2 py-0.5 rounded text-[11px] font-bold ${
                        item.score >= 80
                          ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                          : item.score >= 60
                          ? 'bg-cyan-500/10 text-cyan-400 border border-cyan-500/20'
                          : 'bg-amber-500/10 text-amber-400 border border-amber-500/20'
                      }`}>
                        {item.score}/100
                      </span>
                    </td>
                    <td className="py-3 px-4 text-slate-300">{item.hiringBand}</td>
                    <td className="py-3 px-4 text-slate-400 text-[11px]">
                      {Math.floor(item.durationSecs / 60)}m {item.durationSecs % 60}s
                    </td>
                    <td className="py-3 px-4 text-slate-500 text-[11px]">
                      {new Date(item.createdAt).toLocaleDateString()}
                    </td>
                    <td className="py-3 px-4 text-right">
                      <button
                        onClick={() => handleOpenDetail(item.id)}
                        className="p-1.5 bg-surface-800 hover:bg-surface-700 text-slate-300 hover:text-white rounded-md transition"
                        title="Inspect Complete Interview"
                      >
                        <Eye className="w-3.5 h-3.5" />
                      </button>
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
            Showing <span className="font-semibold text-slate-200">{interviews.length}</span> of{' '}
            <span className="font-semibold text-slate-200">{pagination.total}</span> interviews
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

      {/* ── INTERVIEW DETAIL DRAWER ─────────────────────────────────────── */}
      {selectedSessionId && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex justify-end">
          <div className="w-full max-w-3xl bg-surface-900 border-l border-surface-800 h-full overflow-y-auto p-6 flex flex-col justify-between shadow-2xl animate-in slide-in-from-right duration-200">
            <div>
              <div className="flex items-center justify-between pb-4 border-b border-surface-800">
                <div>
                  <h3 className="text-base font-bold text-white">Interview Inspection</h3>
                  <p className="text-xs text-slate-400 font-mono">{selectedSessionId}</p>
                </div>
                <button
                  onClick={() => setSelectedSessionId(null)}
                  className="p-2 text-slate-400 hover:text-white rounded-lg hover:bg-surface-800"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              {detailLoading || !sessionDetail ? (
                <div className="py-20 text-center text-xs text-slate-500">
                  Loading complete transcript and evaluation...
                </div>
              ) : (
                <div className="space-y-6 pt-5 text-xs">
                  {/* Summary Card */}
                  <div className="p-4 rounded-xl bg-surface-800/40 border border-surface-700/50">
                    <div className="flex justify-between items-start mb-3">
                      <div>
                        <div className="text-sm font-bold text-white">{sessionDetail.session.role}</div>
                        <div className="text-slate-400">{sessionDetail.session.userEmail} · {sessionDetail.session.userName}</div>
                      </div>
                      <div className="text-right">
                        <span className="text-lg font-bold text-emerald-400 block">{sessionDetail.session.score}/100</span>
                        <span className="text-[10px] text-slate-400">{sessionDetail.session.hiringBand}</span>
                      </div>
                    </div>

                    <p className="text-slate-300 leading-relaxed bg-surface-900 p-3 rounded-lg border border-surface-800 mb-3">
                      {sessionDetail.session.summary}
                    </p>

                    <div className="grid grid-cols-2 gap-3">
                      <div className="p-2.5 rounded-lg bg-surface-900 border border-surface-800">
                        <span className="text-emerald-400 font-semibold block mb-1">Identified Strengths:</span>
                        <ul className="list-disc list-inside space-y-0.5 text-slate-300 text-[11px]">
                          {sessionDetail.session.strengths?.map((s: string, idx: number) => (
                            <li key={idx}>{s}</li>
                          ))}
                        </ul>
                      </div>
                      <div className="p-2.5 rounded-lg bg-surface-900 border border-surface-800">
                        <span className="text-amber-400 font-semibold block mb-1">Areas to Improve:</span>
                        <ul className="list-disc list-inside space-y-0.5 text-slate-300 text-[11px]">
                          {sessionDetail.session.areasToImprove?.map((a: string, idx: number) => (
                            <li key={idx}>{a}</li>
                          ))}
                        </ul>
                      </div>
                    </div>
                  </div>

                  {/* AI Telemetry Breakdown */}
                  {sessionDetail.aiTelemetry?.length > 0 && (
                    <div className="p-4 rounded-xl bg-purple-950/20 border border-purple-800/30">
                      <div className="flex items-center gap-2 mb-3">
                        <Bot className="w-4 h-4 text-purple-400" />
                        <h4 className="font-bold text-purple-200 text-xs">AI Telemetry For This Session</h4>
                      </div>
                      <div className="grid grid-cols-3 gap-2 text-center mb-3">
                        <div className="p-2 rounded bg-surface-900/60 border border-surface-700/40">
                          <span className="text-slate-400 block text-[10px]">AI Calls</span>
                          <span className="font-bold text-white">{sessionDetail.aiTelemetry.length}</span>
                        </div>
                        <div className="p-2 rounded bg-surface-900/60 border border-surface-700/40">
                          <span className="text-slate-400 block text-[10px]">Avg Turn Latency</span>
                          <span className="font-bold text-purple-300">
                            {Math.round(sessionDetail.aiTelemetry.reduce((a: number, b: any) => a + b.latencyMs, 0) / sessionDetail.aiTelemetry.length)}ms
                          </span>
                        </div>
                        <div className="p-2 rounded bg-surface-900/60 border border-surface-700/40">
                          <span className="text-slate-400 block text-[10px]">Total Session Tokens</span>
                          <span className="font-bold text-cyan-300">
                            {sessionDetail.aiTelemetry.reduce((a: number, b: any) => a + b.totalTokens, 0)}
                          </span>
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Question by Question Review */}
                  <div className="space-y-4">
                    <h4 className="font-bold text-slate-200 text-xs uppercase tracking-wider">
                      Transcript & Evaluation ({sessionDetail.questions?.length} Turns)
                    </h4>

                    {sessionDetail.questions?.map((q: any) => (
                      <div key={q.id} className="p-4 rounded-xl bg-surface-800/30 border border-surface-700/40 space-y-2.5">
                        <div className="flex items-center justify-between">
                          <span className="font-bold text-brand-300">Turn #{q.questionNumber}</span>
                          <span className="font-bold text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded border border-emerald-500/20">
                            Score: {q.score}/100
                          </span>
                        </div>

                        <div>
                          <div className="text-[10px] uppercase font-bold text-slate-400">Interviewer Question:</div>
                          <div className="text-slate-200 mt-0.5 leading-relaxed">{q.question}</div>
                        </div>

                        <div className="p-2.5 rounded-lg bg-surface-900/80 border border-surface-700/40">
                          <div className="text-[10px] uppercase font-bold text-cyan-400">Candidate Answer:</div>
                          <div className="text-slate-300 mt-0.5 leading-relaxed">{q.candidateAnswer || 'No answer provided.'}</div>
                        </div>

                        {q.feedback && (
                          <div className="p-2.5 rounded-lg bg-amber-500/5 border border-amber-500/20 text-slate-300">
                            <span className="text-[10px] uppercase font-bold text-amber-400 block mb-0.5">AI Feedback:</span>
                            <span>{q.feedback}</span>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            <div className="pt-4 border-t border-surface-800 mt-6">
              <button
                onClick={() => setSelectedSessionId(null)}
                className="w-full py-2 bg-surface-800 hover:bg-surface-700 text-slate-300 rounded-lg font-medium text-xs transition"
              >
                Close Inspection
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
