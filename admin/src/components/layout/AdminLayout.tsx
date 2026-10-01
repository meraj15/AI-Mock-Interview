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
  Smartphone,
  RefreshCw,
  LogOut,
  Calendar,
  Clock,
  ChevronRight,
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
  { label: 'App Updates', path: '/app-updates', icon: Smartphone },
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
    <div className="flex h-screen w-screen overflow-hidden bg-surface-950 text-slate-100 font-sans antialiased">
      {/* ── SIDEBAR ────────────────────────────────────────────────────────── */}
      <aside className="w-64 flex-shrink-0 flex flex-col bg-surface-900/95 border-r border-white/[0.06] select-none backdrop-blur-md">
        {/* Brand with Official App Logo */}
        <div className="h-16 flex items-center px-4 border-b border-white/[0.06] gap-3">
          <div className="relative flex-shrink-0">
            <div className="absolute -inset-1 bg-gradient-to-tr from-brand-600 to-indigo-500 rounded-xl blur-sm opacity-50" />
            <img
              src="/app-logo.png"
              alt="AI Mock Interview Logo"
              className="relative w-9 h-9 rounded-xl object-cover ring-1 ring-white/20 shadow-md shadow-brand-500/20"
            />
            <span
              className="absolute -bottom-0.5 -right-0.5 w-2.5 h-2.5 bg-emerald-500 border-2 border-surface-900 rounded-full"
              title="Online"
            />
          </div>

          <div className="leading-tight overflow-hidden">
            <span className="font-bold text-sm tracking-tight text-white block truncate">
              AI Mock Interview
            </span>
            <div className="flex items-center gap-1.5 mt-0.5">
              <span className="text-[9px] uppercase font-bold tracking-wider text-brand-400 bg-brand-500/10 px-1.5 py-0.2 rounded border border-brand-500/20">
                Admin Center
              </span>
              <span className="text-[9px] text-slate-500 font-mono">v1.0</span>
            </div>
          </div>
        </div>

        {/* Navigation items */}
        <nav className="flex-1 overflow-y-auto px-3 py-3 space-y-1">
          <div className="px-3 pt-2 pb-1 text-[10px] font-bold uppercase tracking-wider text-slate-500">
            Menu Navigation
          </div>
          {NAV_ITEMS.map((item) => {
            const Icon = item.icon;
            const isActive = location.pathname === item.path;
            return (
              <NavLink
                key={item.path}
                to={item.path}
                className={`group flex items-center justify-between px-3 py-2 rounded-xl text-xs font-medium transition-all ${
                  isActive
                    ? 'bg-gradient-to-r from-brand-600/20 to-indigo-600/10 text-white border border-brand-500/30 font-semibold shadow-sm shadow-brand-500/10'
                    : 'text-slate-400 hover:text-slate-100 hover:bg-white/[0.04]'
                }`}
              >
                <div className="flex items-center gap-2.5">
                  <Icon
                    className={`w-4 h-4 transition-colors ${
                      isActive ? 'text-brand-400' : 'text-slate-400 group-hover:text-slate-200'
                    }`}
                  />
                  <span>{item.label}</span>
                </div>
                {isActive && (
                  <span className="w-1.5 h-1.5 rounded-full bg-brand-400 shadow-sm shadow-brand-400" />
                )}
              </NavLink>
            );
          })}
        </nav>

        {/* Admin Profile Footer */}
        <div className="p-3 border-t border-white/[0.06] bg-surface-900/60">
          <div className="flex items-center justify-between p-2 rounded-xl bg-surface-950/70 border border-white/[0.06] hover:border-white/[0.1] transition">
            <div className="flex items-center gap-2.5 overflow-hidden">
              <div className="w-8 h-8 rounded-lg bg-gradient-to-tr from-brand-600 to-indigo-600 border border-white/10 flex items-center justify-center text-xs font-bold text-white flex-shrink-0 shadow-sm">
                {adminUser?.email?.[0]?.toUpperCase() || 'A'}
              </div>
              <div className="truncate">
                <div className="text-xs font-semibold text-slate-100 truncate">
                  {adminUser?.fullName || adminUser?.email?.split('@')[0]}
                </div>
                <div className="text-[10px] text-emerald-400 font-semibold tracking-wide flex items-center gap-1">
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
                  ADMIN
                </div>
              </div>
            </div>
            <button
              onClick={logout}
              title="Sign out of control center"
              className="p-1.5 text-slate-400 hover:text-rose-400 hover:bg-rose-500/10 rounded-lg transition"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>
        </div>
      </aside>

      {/* ── MAIN CONTENT AREA ──────────────────────────────────────────────── */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* Top Header */}
        <header className="h-16 flex-shrink-0 bg-surface-900/80 backdrop-blur-xl border-b border-white/[0.06] flex items-center justify-between px-6 z-10">
          {/* Breadcrumb / Title */}
          <div className="flex items-center gap-2.5">
            <span className="text-xs text-slate-400 font-medium">Control Center</span>
            <ChevronRight className="w-3.5 h-3.5 text-slate-600" />
            <h1 className="text-sm font-bold text-white tracking-tight">{getPageTitle()}</h1>
          </div>

          {/* Controls: Live Status, Date Filter, Auto Refresh, Manual Refresh */}
          <div className="flex items-center gap-2.5 text-xs">
            {/* Live Environment Pill */}
            <div className="hidden md:flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-[11px] font-semibold">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
              <span>System Live</span>
            </div>

            {/* Global Date Filter */}
            <div className="flex items-center gap-1.5 bg-surface-800/80 px-2.5 py-1.5 rounded-lg border border-white/[0.08] hover:border-white/[0.15] transition">
              <Calendar className="w-3.5 h-3.5 text-slate-400" />
              <select
                value={dateRange}
                onChange={(e) => setDateRange(e.target.value as DateRangeOption)}
                className="bg-transparent text-slate-200 focus:outline-none cursor-pointer font-medium text-xs"
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
            <div className="flex items-center gap-1.5 bg-surface-800/80 px-2.5 py-1.5 rounded-lg border border-white/[0.08] hover:border-white/[0.15] transition">
              <Clock className="w-3.5 h-3.5 text-slate-400" />
              <span className="text-slate-400 text-[11px]">Auto:</span>
              <select
                value={autoRefresh}
                onChange={(e) => setAutoRefresh(Number(e.target.value))}
                className="bg-transparent text-slate-200 focus:outline-none cursor-pointer font-medium text-xs"
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
              className="flex items-center gap-1.5 bg-brand-600/20 hover:bg-brand-600/30 text-brand-300 border border-brand-500/30 px-3 py-1.5 rounded-lg font-medium transition active:scale-95 disabled:opacity-50 cursor-pointer shadow-sm shadow-brand-500/10"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${isRefreshing ? 'animate-spin text-brand-400' : ''}`} />
              <span>Refresh</span>
            </button>

            <span className="text-[11px] text-slate-500 font-mono hidden lg:inline ml-1">
              {lastRefreshedAt.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' })}
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
