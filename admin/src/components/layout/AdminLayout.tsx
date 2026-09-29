import React, { useState } from 'react';
import { NavLink, Outlet, useLocation } from 'react-router-dom';
import {
  LayoutDashboard,
  Users,
  Mic,
  CreditCard,
  Banknote,
  Bot,
  BarChart3,
  FileText,
  Layers,
  Activity,
  ShieldAlert,
  Settings,
  RefreshCw,
  LogOut,
  Calendar,
  Clock,
  Sparkles,
} from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import { useFilter, type DateRangeOption } from '../../context/FilterContext';

const NAV_ITEMS = [
  { label: 'Dashboard', path: '/', icon: LayoutDashboard },
  { label: 'Users', path: '/users', icon: Users },
  { label: 'Interviews', path: '/interviews', icon: Mic },
  { label: 'Subscriptions', path: '/subscriptions', icon: CreditCard },
  { label: 'Payments', path: '/payments', icon: Banknote },
  { label: 'AI Usage & Cost', path: '/ai-usage', icon: Bot },
  { label: 'Analytics', path: '/analytics', icon: BarChart3 },
  { label: 'Resumes', path: '/resumes', icon: FileText },
  { label: 'Plans', path: '/plans', icon: Layers },
  { label: 'System Health', path: '/system-health', icon: Activity },
  { label: 'Audit Logs', path: '/audit-logs', icon: ShieldAlert },
  { label: 'Settings', path: '/settings', icon: Settings },
];

export const AdminLayout: React.FC = () => {
  const { adminUser, logout } = useAuth();
  const {
    dateRange,
    setDateRange,
    autoRefresh,
    setAutoRefresh,
    triggerRefresh,
    lastRefreshedAt,
  } = useFilter();
  const [isRefreshing, setIsRefreshing] = useState(false);
  const location = useLocation();

  const handleManualRefresh = () => {
    setIsRefreshing(true);
    triggerRefresh();
    setTimeout(() => setIsRefreshing(false), 600);
  };

  const getPageTitle = () => {
    const item = NAV_ITEMS.find((n) => n.path === location.pathname);
    return item ? item.label : 'Control Center';
  };

  return (
    <div className="flex h-screen w-screen overflow-hidden bg-surface-950 text-slate-100 font-sans">
      {/* ── SIDEBAR ────────────────────────────────────────────────────────── */}
      <aside className="w-64 flex-shrink-0 flex flex-col bg-surface-900 border-r border-surface-800 select-none">
        {/* Brand */}
        <div className="h-16 flex items-center px-5 border-b border-surface-800 gap-3">
          <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-brand-600 to-indigo-500 flex items-center justify-center shadow-lg shadow-brand-500/20">
            <Sparkles className="w-5 h-5 text-white" />
          </div>
          <div className="leading-tight">
            <span className="font-bold text-sm tracking-wide bg-gradient-to-r from-white to-slate-300 bg-clip-text text-transparent">
              AI Mock Interview
            </span>
            <div className="text-[10px] uppercase font-semibold tracking-wider text-brand-400">
              Admin Control Center
            </div>
          </div>
        </div>

        {/* Navigation items */}
        <nav className="flex-1 overflow-y-auto px-3 py-4 space-y-1">
          {NAV_ITEMS.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;
            return (
              <NavLink
                key={item.path}
                to={item.path}
                className={`flex items-center gap-3 px-3.5 py-2.5 rounded-lg text-xs font-medium transition-all ${
                  isActive
                    ? 'bg-brand-600/15 text-brand-400 border border-brand-500/30 font-semibold shadow-sm shadow-brand-500/10'
                    : 'text-slate-400 hover:text-slate-200 hover:bg-surface-800/60'
                }`}
              >
                <Icon className={`w-4 h-4 ${isActive ? 'text-brand-400' : 'text-slate-400'}`} />
                <span>{item.label}</span>
              </NavLink>
            );
          })}
        </nav>

        {/* Admin User Footer */}
        <div className="p-3 border-t border-surface-800 bg-surface-900/80">
          <div className="flex items-center justify-between p-2 rounded-lg bg-surface-800/50 border border-surface-700/50">
            <div className="flex items-center gap-2.5 overflow-hidden">
              <div className="w-7 h-7 rounded-full bg-brand-500/20 border border-brand-500/40 flex items-center justify-center text-xs font-semibold text-brand-300 flex-shrink-0">
                {adminUser?.email?.[0]?.toUpperCase() || 'A'}
              </div>
              <div className="truncate">
                <div className="text-xs font-medium text-slate-200 truncate">
                  {adminUser?.fullName || adminUser?.email?.split('@')[0]}
                </div>
                <div className="text-[10px] text-emerald-400 font-medium">ADMINISTRATOR</div>
              </div>
            </div>
            <button
              onClick={logout}
              title="Logout"
              className="p-1.5 text-slate-400 hover:text-rose-400 hover:bg-surface-700/50 rounded-md transition"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        </div>
      </aside>

      {/* ── MAIN CONTENT AREA ──────────────────────────────────────────────── */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* Top Header */}
        <header className="h-16 flex-shrink-0 bg-surface-900/60 backdrop-blur border-b border-surface-800 flex items-center justify-between px-6 z-10">
          <div className="flex items-center gap-3">
            <h1 className="text-base font-semibold text-white tracking-wide">{getPageTitle()}</h1>
          </div>

          {/* Controls: Date Filter, Auto Refresh, Manual Refresh */}
          <div className="flex items-center gap-3 text-xs">
            {/* Global Date Filter */}
            <div className="flex items-center gap-2 bg-surface-800/80 px-2.5 py-1.5 rounded-lg border border-surface-700/60">
              <Calendar className="w-3.5 h-3.5 text-slate-400" />
              <select
                value={dateRange}
                onChange={(e) => setDateRange(e.target.value as DateRangeOption)}
                className="bg-transparent text-slate-200 focus:outline-none cursor-pointer font-medium"
              >
                <option value="today" className="bg-surface-900 text-slate-200">Today</option>
                <option value="7d" className="bg-surface-900 text-slate-200">Last 7 Days</option>
                <option value="30d" className="bg-surface-900 text-slate-200">Last 30 Days</option>
                <option value="90d" className="bg-surface-900 text-slate-200">Last 90 Days</option>
                <option value="this_month" className="bg-surface-900 text-slate-200">This Month</option>
                <option value="last_month" className="bg-surface-900 text-slate-200">Previous Month</option>
              </select>
            </div>

            {/* Auto-Refresh Toggle */}
            <div className="flex items-center gap-1.5 bg-surface-800/80 px-2.5 py-1.5 rounded-lg border border-surface-700/60">
              <Clock className="w-3.5 h-3.5 text-slate-400" />
              <span className="text-slate-400">Auto:</span>
              <select
                value={autoRefresh}
                onChange={(e) => setAutoRefresh(Number(e.target.value))}
                className="bg-transparent text-slate-200 focus:outline-none cursor-pointer font-medium"
              >
                <option value={0} className="bg-surface-900 text-slate-200">Off</option>
                <option value={30} className="bg-surface-900 text-slate-200">30s</option>
                <option value={60} className="bg-surface-900 text-slate-200">60s</option>
              </select>
            </div>

            {/* Manual Refresh Button */}
            <button
              onClick={handleManualRefresh}
              disabled={isRefreshing}
              className="flex items-center gap-1.5 bg-brand-600/20 hover:bg-brand-600/30 text-brand-300 border border-brand-500/30 px-3 py-1.5 rounded-lg font-medium transition active:scale-95 disabled:opacity-50"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${isRefreshing ? 'animate-spin text-brand-400' : ''}`} />
              <span>Refresh</span>
            </button>

            <span className="text-[11px] text-slate-500 hidden sm:inline">
              Updated {lastRefreshedAt.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
            </span>
          </div>
        </header>

        {/* Page Content Body */}
        <main className="flex-1 overflow-y-auto p-6 bg-surface-950">
          <Outlet />
        </main>
      </div>
    </div>
  );
};
