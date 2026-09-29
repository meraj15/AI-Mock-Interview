import React, { useEffect, useState } from 'react';
import { api } from '../api/client';
import { useFilter } from '../context/FilterContext';
import {
  Settings,
  Save,
  CheckCircle2,
  AlertCircle,
  Sliders,
  Bot,
  IndianRupee,
  ShieldAlert,
  Mic,
  X,
} from 'lucide-react';

export const SettingsPage: React.FC = () => {
  const { refreshKey } = useFilter();
  const [settings, setSettings] = useState<any>({
    freeInterviewLimit: 2,
    proInterviewLimit: 30,
    freeResumeScanLimit: 1,
    proResumeScanLimit: 5,
    voiceEntitlementEnabled: true,
    liveTimeoutMs: 12000,
    aiPricingInputPerMillionPaise: 1275,
    aiPricingOutputPerMillionPaise: 5100,
    geminiModel: 'gemini-3.8-flash',
  });
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Audit Confirmation Modal
  const [confirmModalOpen, setConfirmModalOpen] = useState(false);
  const [reason, setReason] = useState('');

  const fetchSettings = async () => {
    setLoading(true);
    try {
      const res = await api.get('/api/v1/admin/settings');
      if (res.success) {
        setSettings(res.data);
      }
    } catch (err) {
      console.error('Failed to load settings:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSettings();
  }, [refreshKey]);

  const handleOpenConfirm = (e: React.FormEvent) => {
    e.preventDefault();
    setReason('');
    setConfirmModalOpen(true);
  };

  const handleExecuteSave = async () => {
    if (!reason.trim()) {
      setErrorMessage('Please provide an audit reason for changing system settings.');
      return;
    }

    setSaving(true);
    setSuccessMessage(null);
    setErrorMessage(null);

    try {
      const res = await api.put('/api/v1/admin/settings', {
        ...settings,
        reason,
      });

      if (res.success) {
        setSuccessMessage('System settings and quotas saved and audited successfully.');
        setConfirmModalOpen(false);
        setSettings(res.settings);
        setTimeout(() => setSuccessMessage(null), 4000);
      }
    } catch (err: any) {
      setErrorMessage(err.message || 'Failed to update system settings');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6 max-w-5xl">
      {/* ── HEADER ────────────────────────────────────────────────────────── */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-white tracking-tight flex items-center gap-2">
            <Settings className="w-6 h-6 text-brand-400" />
            System & Operational Settings
          </h2>
          <p className="text-xs text-slate-400 mt-0.5">
            Configure candidate quota thresholds, voice entitlements, Gemini model parameters, and AI telemetry pricing constants.
          </p>
        </div>
      </div>

      {successMessage && (
        <div className="p-3.5 rounded-xl bg-emerald-500/10 border border-emerald-500/30 text-emerald-300 text-xs flex items-center gap-2 animate-fadeIn">
          <CheckCircle2 className="w-4 h-4 flex-shrink-0" />
          <span>{successMessage}</span>
        </div>
      )}

      {errorMessage && (
        <div className="p-3.5 rounded-xl bg-rose-500/10 border border-rose-500/30 text-rose-300 text-xs flex items-center gap-2 animate-fadeIn">
          <AlertCircle className="w-4 h-4 flex-shrink-0" />
          <span>{errorMessage}</span>
        </div>
      )}

      {loading ? (
        <div className="py-16 text-center text-slate-500">
          <div className="flex items-center justify-center gap-2">
            <div className="w-5 h-5 border-2 border-brand-500 border-t-transparent rounded-full animate-spin" />
            <span>Loading operational configuration...</span>
          </div>
        </div>
      ) : (
        <form onSubmit={handleOpenConfirm} className="space-y-6">
          {/* ── SECTION 1: CANDIDATE QUOTAS ──────────────────────────────── */}
          <div className="p-6 rounded-xl bg-surface-900 border border-surface-800 space-y-4">
            <div className="flex items-center gap-2 pb-3 border-b border-surface-800">
              <Sliders className="w-5 h-5 text-brand-400" />
              <h3 className="text-sm font-bold text-white">
                Candidate Feature & Quota Limits
              </h3>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-5 text-xs">
              <div>
                <label className="text-slate-300 font-medium block mb-1">
                  Free Candidate Interview Limit
                </label>
                <input
                  type="number"
                  min={0}
                  max={100}
                  value={settings.freeInterviewLimit}
                  onChange={(e) =>
                    setSettings({ ...settings, freeInterviewLimit: Number(e.target.value) })
                  }
                  className="w-full bg-surface-950 border border-surface-700 rounded-lg px-3 py-2 text-slate-200 focus:outline-none focus:border-brand-500"
                />
                <span className="text-[11px] text-slate-500 mt-1 block">
                  Lifetime quota granted to free candidates on registration.
                </span>
              </div>

              <div>
                <label className="text-slate-300 font-medium block mb-1">
                  Pro Candidate Interview Limit
                </label>
                <input
                  type="number"
                  min={1}
                  max={500}
                  value={settings.proInterviewLimit}
                  onChange={(e) =>
                    setSettings({ ...settings, proInterviewLimit: Number(e.target.value) })
                  }
                  className="w-full bg-surface-950 border border-surface-700 rounded-lg px-3 py-2 text-slate-200 focus:outline-none focus:border-brand-500"
                />
                <span className="text-[11px] text-slate-500 mt-1 block">
                  Monthly interview quota granted to Pro subscribers.
                </span>
              </div>

              <div>
                <label className="text-slate-300 font-medium block mb-1">
                  Free Candidate Resume Scans
                </label>
                <input
                  type="number"
                  min={0}
                  max={50}
                  value={settings.freeResumeScanLimit}
                  onChange={(e) =>
                    setSettings({ ...settings, freeResumeScanLimit: Number(e.target.value) })
                  }
                  className="w-full bg-surface-950 border border-surface-700 rounded-lg px-3 py-2 text-slate-200 focus:outline-none focus:border-brand-500"
                />
                <span className="text-[11px] text-slate-500 mt-1 block">
                  Number of PDF resume parser analyses for free users.
                </span>
              </div>

              <div>
                <label className="text-slate-300 font-medium block mb-1">
                  Pro Candidate Resume Scans
                </label>
                <input
                  type="number"
                  min={1}
                  max={200}
                  value={settings.proResumeScanLimit}
                  onChange={(e) =>
                    setSettings({ ...settings, proResumeScanLimit: Number(e.target.value) })
                  }
                  className="w-full bg-surface-950 border border-surface-700 rounded-lg px-3 py-2 text-slate-200 focus:outline-none focus:border-brand-500"
                />
                <span className="text-[11px] text-slate-500 mt-1 block">
                  Monthly resume uploads available on active Pro tier.
                </span>
              </div>

              <div className="col-span-1 md:col-span-2 pt-2">
                <div className="flex items-center justify-between p-3 rounded-lg bg-surface-950 border border-surface-800">
                  <div className="flex items-center gap-2">
                    <Mic className="w-4 h-4 text-brand-400" />
                    <div>
                      <span className="text-xs font-semibold text-white block">
                        Voice Interview Entitlement Global Switch
                      </span>
                      <span className="text-[11px] text-slate-400">
                        When disabled, voice audio recording and speech-to-text fallback to text mode across all sessions.
                      </span>
                    </div>
                  </div>

                  <button
                    type="button"
                    onClick={() =>
                      setSettings({
                        ...settings,
                        voiceEntitlementEnabled: !settings.voiceEntitlementEnabled,
                      })
                    }
                    className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                      settings.voiceEntitlementEnabled ? 'bg-brand-600' : 'bg-surface-700'
                    }`}
                  >
                    <span
                      className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                        settings.voiceEntitlementEnabled ? 'translate-x-6' : 'translate-x-1'
                      }`}
                    />
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* ── SECTION 2: AI & INFERENCE PARAMETERS ──────────────────────── */}
          <div className="p-6 rounded-xl bg-surface-900 border border-surface-800 space-y-4">
            <div className="flex items-center gap-2 pb-3 border-b border-surface-800">
              <Bot className="w-5 h-5 text-indigo-400" />
              <h3 className="text-sm font-bold text-white">
                AI Engine & Inference Timing
              </h3>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-5 text-xs">
              <div>
                <label className="text-slate-300 font-medium block mb-1">
                  Primary Gemini AI Model
                </label>
                <select
                  value={settings.geminiModel}
                  onChange={(e) => setSettings({ ...settings, geminiModel: e.target.value })}
                  className="w-full bg-surface-950 border border-surface-700 rounded-lg px-3 py-2 text-slate-200 focus:outline-none focus:border-brand-500"
                >
                  <option value="gemini-3.8-flash">gemini-3.8-flash (Recommended Default)</option>
                  <option value="gemini-3.5-flash-lite">gemini-3.5-flash-lite (Ultra Fast / Low Cost)</option>
                  <option value="gemini-1.5-pro">gemini-1.5-pro (High Reasoning)</option>
                </select>
                <span className="text-[11px] text-slate-500 mt-1 block">
                  Model assigned for question synthesis and grading evaluations.
                </span>
              </div>

              <div>
                <label className="text-slate-300 font-medium block mb-1">
                  Live Request Timeout (ms)
                </label>
                <input
                  type="number"
                  min={3000}
                  max={60000}
                  step={1000}
                  value={settings.liveTimeoutMs}
                  onChange={(e) =>
                    setSettings({ ...settings, liveTimeoutMs: Number(e.target.value) })
                  }
                  className="w-full bg-surface-950 border border-surface-700 rounded-lg px-3 py-2 text-slate-200 focus:outline-none focus:border-brand-500"
                />
                <span className="text-[11px] text-slate-500 mt-1 block">
                  Circuit breaker timeout threshold before fallback model triggers.
                </span>
              </div>
            </div>
          </div>

          {/* ── SECTION 3: AI UNIT COST CONSTANTS ─────────────────────────── */}
          <div className="p-6 rounded-xl bg-surface-900 border border-surface-800 space-y-4">
            <div className="flex items-center gap-2 pb-3 border-b border-surface-800">
              <IndianRupee className="w-5 h-5 text-emerald-400" />
              <h3 className="text-sm font-bold text-white">
                Estimated AI Unit Economics (INR Pricing Constants)
              </h3>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-5 text-xs">
              <div>
                <label className="text-slate-300 font-medium block mb-1">
                  Input Tokens Rate (Paise per 1M tokens)
                </label>
                <div className="relative">
                  <input
                    type="number"
                    min={0}
                    value={settings.aiPricingInputPerMillionPaise}
                    onChange={(e) =>
                      setSettings({
                        ...settings,
                        aiPricingInputPerMillionPaise: Number(e.target.value),
                      })
                    }
                    className="w-full bg-surface-950 border border-surface-700 rounded-lg px-3 py-2 text-slate-200 focus:outline-none focus:border-brand-500 font-mono"
                  />
                  <span className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 text-[11px]">
                    = ₹{(settings.aiPricingInputPerMillionPaise / 100).toFixed(2)} / 1M
                  </span>
                </div>
                <span className="text-[11px] text-slate-500 mt-1 block">
                  Used by Dashboard to compute gross contribution margins.
                </span>
              </div>

              <div>
                <label className="text-slate-300 font-medium block mb-1">
                  Output Tokens Rate (Paise per 1M tokens)
                </label>
                <div className="relative">
                  <input
                    type="number"
                    min={0}
                    value={settings.aiPricingOutputPerMillionPaise}
                    onChange={(e) =>
                      setSettings({
                        ...settings,
                        aiPricingOutputPerMillionPaise: Number(e.target.value),
                      })
                    }
                    className="w-full bg-surface-950 border border-surface-700 rounded-lg px-3 py-2 text-slate-200 focus:outline-none focus:border-brand-500 font-mono"
                  />
                  <span className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 text-[11px]">
                    = ₹{(settings.aiPricingOutputPerMillionPaise / 100).toFixed(2)} / 1M
                  </span>
                </div>
                <span className="text-[11px] text-slate-500 mt-1 block">
                  Generated token cost multiplier in INR.
                </span>
              </div>
            </div>
          </div>

          {/* Form Submit Button */}
          <div className="flex justify-end pt-2">
            <button
              type="submit"
              className="flex items-center gap-2 px-6 py-2.5 rounded-lg bg-brand-600 hover:bg-brand-500 text-white font-semibold text-xs transition shadow-lg shadow-brand-500/20 active:scale-95"
            >
              <Save className="w-4 h-4" />
              <span>Save System Settings</span>
            </button>
          </div>
        </form>
      )}

      {/* ── AUDIT CONFIRMATION MODAL ────────────────────────────────────── */}
      {confirmModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-surface-900 border border-surface-700 rounded-xl max-w-md w-full p-6 space-y-4 shadow-2xl">
            <div className="flex items-center justify-between border-b border-surface-800 pb-3">
              <div className="flex items-center gap-2">
                <ShieldAlert className="w-5 h-5 text-amber-400" />
                <h3 className="text-sm font-semibold text-white">
                  Confirm System Configuration Change
                </h3>
              </div>
              <button
                onClick={() => setConfirmModalOpen(false)}
                className="text-slate-400 hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <p className="text-xs text-slate-300">
              Modifying operational settings affects candidate entitlements and AI telemetry rates in real time. Please provide a formal reason for this modification for the immutable audit trail.
            </p>

            <div>
              <label className="text-slate-300 font-medium text-xs block mb-1">
                Audit Reason <span className="text-rose-400">*</span>
              </label>
              <textarea
                rows={3}
                required
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                placeholder="e.g., Increased free interview limit to 3 for campus hiring drive..."
                className="w-full bg-surface-950 border border-surface-700 rounded-lg p-3 text-xs text-slate-200 focus:outline-none focus:border-brand-500"
              />
            </div>

            <div className="flex justify-end gap-2 pt-2 border-t border-surface-800">
              <button
                type="button"
                onClick={() => setConfirmModalOpen(false)}
                className="px-4 py-2 rounded-lg bg-surface-800 hover:bg-surface-700 text-xs text-slate-300 font-medium transition"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleExecuteSave}
                disabled={saving || !reason.trim()}
                className="flex items-center gap-1.5 px-5 py-2 rounded-lg bg-brand-600 hover:bg-brand-500 text-xs text-white font-semibold transition disabled:opacity-50"
              >
                {saving ? (
                  <div className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                ) : (
                  <Save className="w-3.5 h-3.5" />
                )}
                <span>Confirm & Apply</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
