import React, { useEffect, useState } from 'react';
import { api } from '../api/client';
import { useFilter } from '../context/FilterContext';
import {
  Layers,
  Crown,
  CheckCircle2,
  XCircle,
  Edit,
  Save,
  X,
  AlertCircle,
  Users,
} from 'lucide-react';

export const PlansPage: React.FC = () => {
  const { refreshKey } = useFilter();
  const [plans, setPlans] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  // Edit Modal State
  const [editingPlan, setEditingPlan] = useState<any>(null);
  const [description, setDescription] = useState('');
  const [isActive, setIsActive] = useState(true);
  const [reason, setReason] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const fetchPlans = async () => {
    setLoading(true);
    try {
      const res = await api.get('/api/v1/admin/plans');
      if (res.success) {
        setPlans(res.data);
      }
    } catch (err) {
      console.error('Failed to load plans:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchPlans();
  }, [refreshKey]);

  const handleOpenEdit = (plan: any) => {
    setEditingPlan(plan);
    setDescription(plan.description || '');
    setIsActive(plan.isActive);
    setReason('');
    setError(null);
  };

  const handleSavePlan = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!reason.trim()) {
      setError('Please provide an audit log reason for this plan modification.');
      return;
    }

    setSaving(true);
    setError(null);
    try {
      const res = await api.put(`/api/v1/admin/plans/${editingPlan.id}`, {
        description,
        isActive,
        reason,
      });

      if (res.success) {
        setEditingPlan(null);
        fetchPlans();
      }
    } catch (err: any) {
      setError(err.message || 'Failed to update plan');
    } finally {
      setSaving(false);
    }
  };

  const displayedPlans = plans.filter((plan) => {
    if (plan.code === 'PREMIUM_MONTHLY' && plans.some((p) => p.code === 'PRO_MONTHLY')) return false;
    if (plan.code === 'PREMIUM_YEARLY' && plans.some((p) => p.code === 'PRO_YEARLY')) return false;
    return true;
  });

  return (
    <div className="space-y-6">
      {/* ── HEADER ────────────────────────────────────────────────────────── */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-white tracking-tight flex items-center gap-2">
            <Layers className="w-6 h-6 text-brand-400" />
            Subscription Plans Management
          </h2>
          <p className="text-xs text-slate-400 mt-0.5">
            Configure candidate subscription plans, view active subscriber counts, and toggle plan availability safely.
          </p>
        </div>
      </div>

      {/* ── PLANS GRID ────────────────────────────────────────────────────── */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {loading ? (
          <div className="col-span-3 py-16 text-center text-slate-500">
            <div className="flex items-center justify-center gap-2">
              <div className="w-5 h-5 border-2 border-brand-500 border-t-transparent rounded-full animate-spin" />
              <span>Loading subscription plans...</span>
            </div>
          </div>
        ) : displayedPlans.length === 0 ? (
          <div className="col-span-3 py-16 text-center text-slate-500">
            No plans configured in database.
          </div>
        ) : (
          displayedPlans.map((plan) => {
            const isPro = plan.tier === 'PRO';
            return (
              <div
                key={plan.id}
                className={`relative rounded-xl p-6 bg-surface-900 border transition flex flex-col justify-between ${
                  isPro
                    ? 'border-brand-500/40 shadow-lg shadow-brand-500/5'
                    : 'border-surface-800'
                }`}
              >
                {/* Plan Header */}
                <div>
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      {isPro ? (
                        <Crown className="w-5 h-5 text-amber-400" />
                      ) : (
                        <Layers className="w-5 h-5 text-slate-400" />
                      )}
                      <h3 className="text-base font-bold text-white">{plan.name}</h3>
                    </div>

                    <span
                      className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-semibold ${
                        plan.isActive
                          ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                          : 'bg-rose-500/10 text-rose-400 border border-rose-500/20'
                      }`}
                    >
                      {plan.isActive ? <CheckCircle2 className="w-3 h-3" /> : <XCircle className="w-3 h-3" />}
                      {plan.isActive ? 'Active' : 'Archived'}
                    </span>
                  </div>

                  {/* Pricing Display */}
                  <div className="mt-4 flex items-baseline gap-1">
                    <span className="text-3xl font-extrabold text-white">
                      ₹{plan.priceRupees.toLocaleString('en-IN')}
                    </span>
                    <span className="text-xs text-slate-400">
                      / {plan.billingInterval ? plan.billingInterval.toLowerCase() : 'one-time'}
                    </span>
                  </div>

                  <p className="mt-3 text-xs text-slate-300 min-h-[3rem] leading-relaxed">
                    {plan.description || 'No description provided.'}
                  </p>

                  {/* Plan Details & Badges */}
                  <div className="mt-4 pt-4 border-t border-surface-800 space-y-2 text-xs">
                    <div className="flex justify-between py-1 border-b border-surface-800/40">
                      <span className="text-slate-400">Code / SKU:</span>
                      <span className="font-mono text-slate-200">{plan.code}</span>
                    </div>
                    <div className="flex justify-between py-1 border-b border-surface-800/40">
                      <span className="text-slate-400">Tier:</span>
                      <span className="font-semibold text-brand-300">{plan.tier}</span>
                    </div>
                    <div className="flex justify-between py-1 border-b border-surface-800/40">
                      <span className="text-slate-400">Razorpay Plan ID:</span>
                      <span className="font-mono text-slate-400 text-[11px] truncate max-w-[140px]">
                        {plan.razorpayPlanId || 'Free / Local'}
                      </span>
                    </div>
                    <div className="flex justify-between py-1">
                      <span className="text-slate-400">Active Subscribers:</span>
                      <span className="font-bold text-emerald-400 flex items-center gap-1">
                        <Users className="w-3.5 h-3.5" />
                        {plan.subscriberCount || 0} candidates
                      </span>
                    </div>
                  </div>
                </div>

                {/* Card Action Button */}
                <div className="mt-6 pt-4 border-t border-surface-800">
                  <button
                    onClick={() => handleOpenEdit(plan)}
                    className="w-full flex items-center justify-center gap-2 px-4 py-2 rounded-lg bg-surface-800 hover:bg-surface-700 text-xs font-semibold text-slate-200 border border-surface-700 transition"
                  >
                    <Edit className="w-3.5 h-3.5 text-brand-400" />
                    <span>Edit Plan Description & Status</span>
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* ── EDIT PLAN MODAL ──────────────────────────────────────────────── */}
      {editingPlan && (
        <div className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-surface-900 border border-surface-700 rounded-xl max-w-md w-full p-6 space-y-5 shadow-2xl">
            <div className="flex items-center justify-between border-b border-surface-800 pb-3">
              <div className="flex items-center gap-2">
                <Edit className="w-4 h-4 text-brand-400" />
                <h3 className="text-sm font-semibold text-white">
                  Edit Plan: {editingPlan.name}
                </h3>
              </div>
              <button
                onClick={() => setEditingPlan(null)}
                className="text-slate-400 hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            {error && (
              <div className="p-3 rounded-lg bg-rose-500/10 border border-rose-500/30 text-rose-300 text-xs flex items-center gap-2">
                <AlertCircle className="w-4 h-4 flex-shrink-0" />
                <span>{error}</span>
              </div>
            )}

            <form onSubmit={handleSavePlan} className="space-y-4 text-xs">
              <div>
                <label className="text-slate-300 font-medium block mb-1">
                  Plan Description
                </label>
                <textarea
                  rows={3}
                  value={description}
                  onChange={(e) => setDescription(e.target.value)}
                  className="w-full bg-surface-950 border border-surface-700 rounded-lg p-3 text-slate-200 focus:outline-none focus:border-brand-500"
                  placeholder="Enter marketing or feature description..."
                />
              </div>

              <div>
                <label className="text-slate-300 font-medium block mb-2">
                  Plan Availability
                </label>
                <div className="flex items-center gap-3">
                  <button
                    type="button"
                    onClick={() => setIsActive(!isActive)}
                    className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                      isActive ? 'bg-emerald-500' : 'bg-surface-700'
                    }`}
                  >
                    <span
                      className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                        isActive ? 'translate-x-6' : 'translate-x-1'
                      }`}
                    />
                  </button>
                  <span className="text-slate-300 font-medium">
                    {isActive ? 'Active (Available for checkout)' : 'Archived (Hidden from new users)'}
                  </span>
                </div>
              </div>

              <div>
                <label className="text-slate-300 font-medium block mb-1">
                  Audit Log Reason <span className="text-rose-400">*</span>
                </label>
                <input
                  type="text"
                  required
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                  placeholder="e.g. Updated feature description for spring promotion"
                  className="w-full bg-surface-950 border border-surface-700 rounded-lg px-3 py-2 text-slate-200 focus:outline-none focus:border-brand-500"
                />
              </div>

              <div className="pt-3 flex justify-end gap-2 border-t border-surface-800">
                <button
                  type="button"
                  onClick={() => setEditingPlan(null)}
                  className="px-4 py-2 rounded-lg bg-surface-800 hover:bg-surface-700 text-slate-300 font-medium transition"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={saving}
                  className="flex items-center gap-1.5 px-4 py-2 rounded-lg bg-brand-600 hover:bg-brand-500 text-white font-semibold transition disabled:opacity-50"
                >
                  {saving ? (
                    <div className="w-3.5 h-3.5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                  ) : (
                    <Save className="w-3.5 h-3.5" />
                  )}
                  <span>Save Plan</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
