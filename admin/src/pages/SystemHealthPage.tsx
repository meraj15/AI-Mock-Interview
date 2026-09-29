import React, { useEffect, useState } from 'react';
import { api } from '../api/client';
import { useFilter } from '../context/FilterContext';
import {
  Activity,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  Server,
  Database,
  Bot,
  CreditCard,
  Mail,
  RefreshCw,
  Clock,
} from 'lucide-react';

export const SystemHealthPage: React.FC = () => {
  const { refreshKey } = useFilter();
  const [health, setHealth] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [pinging, setPinging] = useState(false);

  const fetchHealth = async () => {
    setLoading(true);
    try {
      const res = await api.get('/api/v1/admin/system-health');
      if (res.success) {
        setHealth(res.data);
      }
    } catch (err) {
      console.error('Failed to load system health:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchHealth();
  }, [refreshKey]);

  const handleRunDiagnostic = async () => {
    setPinging(true);
    await fetchHealth();
    setTimeout(() => setPinging(false), 500);
  };

  const formatUptime = (secs: number) => {
    const days = Math.floor(secs / (3600 * 24));
    const hours = Math.floor((secs % (3600 * 24)) / 3600);
    const minutes = Math.floor((secs % 3600) / 60);
    const s = secs % 60;
    return `${days}d ${hours}h ${minutes}m ${s}s`;
  };

  const getServiceIcon = (name: string) => {
    switch (name) {
      case 'API Server':
        return <Server className="w-5 h-5 text-indigo-400" />;
      case 'PostgreSQL Database':
        return <Database className="w-5 h-5 text-emerald-400" />;
      case 'Gemini AI':
        return <Bot className="w-5 h-5 text-brand-400" />;
      case 'Razorpay Gateway':
        return <CreditCard className="w-5 h-5 text-amber-400" />;
      case 'Email (SMTP)':
        return <Mail className="w-5 h-5 text-purple-400" />;
      default:
        return <Activity className="w-5 h-5 text-slate-400" />;
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'HEALTHY':
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
            <CheckCircle2 className="w-3.5 h-3.5" />
            Healthy
          </span>
        );
      case 'DEGRADED':
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-amber-500/10 text-amber-400 border border-amber-500/20">
            <AlertTriangle className="w-3.5 h-3.5" />
            Degraded
          </span>
        );
      case 'DOWN':
      default:
        return (
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-rose-500/10 text-rose-400 border border-rose-500/20">
            <XCircle className="w-3.5 h-3.5" />
            Down
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
            <Activity className="w-6 h-6 text-brand-400" />
            System Health & Infrastructure Diagnostics
          </h2>
          <p className="text-xs text-slate-400 mt-0.5">
            Real-time status check for API server, PostgreSQL database pool, Gemini AI provider, Razorpay gateway, and SMTP mailer.
          </p>
        </div>

        <button
          onClick={handleRunDiagnostic}
          disabled={pinging}
          className="flex items-center gap-2 px-3.5 py-1.5 rounded-lg bg-brand-600/20 hover:bg-brand-600/30 text-brand-300 border border-brand-500/30 text-xs font-semibold transition self-start sm:self-auto disabled:opacity-50"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${pinging ? 'animate-spin text-brand-400' : ''}`} />
          <span>Run Diagnostic Ping</span>
        </button>
      </div>

      {/* ── OVERALL STATUS HERO BANNER ────────────────────────────────────── */}
      <div
        className={`p-6 rounded-2xl border transition-all ${
          health?.overallStatus === 'HEALTHY'
            ? 'bg-emerald-500/5 border-emerald-500/30 shadow-lg shadow-emerald-500/5'
            : health?.overallStatus === 'DEGRADED'
            ? 'bg-amber-500/5 border-amber-500/30 shadow-lg shadow-amber-500/5'
            : 'bg-rose-500/5 border-rose-500/30 shadow-lg shadow-rose-500/5'
        }`}
      >
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <div
              className={`w-12 h-12 rounded-xl flex items-center justify-center ${
                health?.overallStatus === 'HEALTHY'
                  ? 'bg-emerald-500/20 text-emerald-400'
                  : health?.overallStatus === 'DEGRADED'
                  ? 'bg-amber-500/20 text-amber-400'
                  : 'bg-rose-500/20 text-rose-400'
              }`}
            >
              {health?.overallStatus === 'HEALTHY' ? (
                <CheckCircle2 className="w-7 h-7" />
              ) : health?.overallStatus === 'DEGRADED' ? (
                <AlertTriangle className="w-7 h-7" />
              ) : (
                <XCircle className="w-7 h-7" />
              )}
            </div>

            <div>
              <div className="flex items-center gap-3">
                <h3 className="text-lg font-bold text-white tracking-tight">
                  System Status: {health?.overallStatus || 'CHECKING...'}
                </h3>
                {health && getStatusBadge(health.overallStatus)}
              </div>
              <p className="text-xs text-slate-400 mt-1">
                {health?.overallStatus === 'HEALTHY'
                  ? 'All core services and integrated providers are operational with nominal latency.'
                  : 'One or more subsystem dependencies are experiencing latency or configuration alerts.'}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-6 pt-3 md:pt-0 border-t md:border-t-0 border-surface-800 text-xs">
            <div>
              <span className="text-slate-500 block uppercase text-[10px] font-medium tracking-wider">
                System Uptime
              </span>
              <span className="text-sm font-bold text-white font-mono mt-0.5 block">
                {health ? formatUptime(health.uptimeSecs) : '...'}
              </span>
            </div>

            <div>
              <span className="text-slate-500 block uppercase text-[10px] font-medium tracking-wider">
                Last Heartbeat
              </span>
              <span className="text-sm font-semibold text-slate-300 mt-0.5 block">
                {health?.timestamp ? new Date(health.timestamp).toLocaleTimeString() : '...'}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* ── SERVICES HEALTH GRID ──────────────────────────────────────────── */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {loading ? (
          <div className="col-span-3 py-16 text-center text-slate-500">
            <div className="flex items-center justify-center gap-2">
              <div className="w-5 h-5 border-2 border-brand-500 border-t-transparent rounded-full animate-spin" />
              <span>Pinging subsystems and providers...</span>
            </div>
          </div>
        ) : (
          health?.services?.map((svc: any) => (
            <div
              key={svc.service}
              className="p-5 rounded-xl bg-surface-900 border border-surface-800 flex flex-col justify-between space-y-4 hover:border-surface-700 transition"
            >
              <div>
                {/* Service Header */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2.5">
                    {getServiceIcon(svc.service)}
                    <h4 className="text-sm font-bold text-white">{svc.service}</h4>
                  </div>
                  {getStatusBadge(svc.status)}
                </div>

                {/* Latency Ping */}
                <div className="mt-3 flex items-center justify-between text-xs py-1.5 border-b border-surface-800">
                  <span className="text-slate-400">Response Latency:</span>
                  <span className="font-mono font-semibold text-emerald-400">{svc.latencyMs} ms</span>
                </div>

                {/* Details list */}
                <div className="mt-3 space-y-1.5 text-xs">
                  {svc.details &&
                    Object.entries(svc.details).map(([key, val]) => (
                      <div key={key} className="flex justify-between py-0.5">
                        <span className="text-slate-500 capitalize">
                          {key.replace(/([A-Z])/g, ' $1').toLowerCase()}:
                        </span>
                        <span className="text-slate-300 font-mono text-[11px] truncate max-w-[150px]">
                          {typeof val === 'boolean'
                            ? val
                              ? 'Enabled'
                              : 'Disabled'
                            : String(val)}
                        </span>
                      </div>
                    ))}
                </div>
              </div>

              {/* Footer */}
              <div className="pt-3 border-t border-surface-800/80 flex items-center justify-between text-[10px] text-slate-500">
                <span className="flex items-center gap-1">
                  <Clock className="w-3 h-3" />
                  Checked: {new Date(svc.lastChecked).toLocaleTimeString()}
                </span>
                <span className="font-medium text-slate-400">Continuous check</span>
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};
