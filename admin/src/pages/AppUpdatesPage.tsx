import React, { useEffect, useState } from 'react';
import { api } from '../api/client';
import { useFilter } from '../context/FilterContext';
import {
  Smartphone,
  Plus,
  RefreshCw,
  CheckCircle2,
  AlertTriangle,
  ExternalLink,
  X,
} from 'lucide-react';

interface AppUpdate {
  id: string;
  platform: 'ANDROID' | 'IOS' | 'BOTH';
  latestVersion: string;
  minimumVersion: string;
  forceUpdate: boolean;
  title: string;
  message: string;
  whatsNew: string[];
  androidStoreUrl?: string | null;
  iosStoreUrl?: string | null;
  status: 'DRAFT' | 'PUBLISHED' | 'DISABLED';
  publishedAt?: string | null;
  releaseDate?: string | null;
  createdBy?: string | null;
  createdAt: string;
  updatedAt: string;
}

export const AppUpdatesPage: React.FC = () => {
  const { refreshKey } = useFilter();
  const [updates, setUpdates] = useState<AppUpdate[]>([]);
  const [loading, setLoading] = useState(true);
  const [filterPlatform, setFilterPlatform] = useState<string>('ALL');
  const [filterStatus, setFilterStatus] = useState<string>('ALL');

  // Modal States
  const [isCreateModalOpen, setIsCreateModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [isViewModalOpen, setIsViewModalOpen] = useState(false);
  const [selectedUpdate, setSelectedUpdate] = useState<AppUpdate | null>(null);

  // Form Fields
  const [formData, setFormData] = useState({
    platform: 'BOTH' as 'ANDROID' | 'IOS' | 'BOTH',
    latestVersion: '',
    minimumVersion: '',
    forceUpdate: false,
    title: '',
    message: '',
    whatsNewText: '',
    androidStoreUrl: '',
    iosStoreUrl: '',
  });

  const [formError, setFormError] = useState<string | null>(null);
  const [submitting, setSubmitting] = useState(false);
  const [actionLoading, setActionLoading] = useState<string | null>(null);

  // Fetch updates list
  const fetchUpdates = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams();
      if (filterPlatform !== 'ALL') params.append('platform', filterPlatform);
      if (filterStatus !== 'ALL') params.append('status', filterStatus);

      const res = await api.get(`/api/v1/admin/app-updates?${params.toString()}`);
      if (res.success && res.updates) {
        setUpdates(res.updates);
      }
    } catch (err) {
      console.error('Failed to load app updates:', err);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUpdates();
  }, [refreshKey, filterPlatform, filterStatus]);

  // Active configurations for Android and iOS
  const activeAndroidUpdate = updates.find(
    (u) => u.status === 'PUBLISHED' && (u.platform === 'ANDROID' || u.platform === 'BOTH')
  );
  const activeIosUpdate = updates.find(
    (u) => u.status === 'PUBLISHED' && (u.platform === 'IOS' || u.platform === 'BOTH')
  );

  // Open Create Modal
  const handleOpenCreate = () => {
    setFormData({
      platform: 'BOTH',
      latestVersion: '',
      minimumVersion: '',
      forceUpdate: false,
      title: 'New Update Available',
      message: 'A new version of AI Mock Interview is available with improved performance and new features.',
      whatsNewText: 'Faster AI interviews\nBetter voice experience\nImproved follow-up questions\nBug fixes',
      androidStoreUrl: 'https://play.google.com/store/apps/details?id=com.interviewcoach.app',
      iosStoreUrl: 'https://apps.apple.com/app/ai-mock-interview/id123456789',
    });
    setFormError(null);
    setIsCreateModalOpen(true);
  };

  // Open Edit Modal
  const handleOpenEdit = (update: AppUpdate) => {
    setSelectedUpdate(update);
    setFormData({
      platform: update.platform,
      latestVersion: update.latestVersion,
      minimumVersion: update.minimumVersion,
      forceUpdate: update.forceUpdate,
      title: update.title,
      message: update.message,
      whatsNewText: update.whatsNew ? update.whatsNew.join('\n') : '',
      androidStoreUrl: update.androidStoreUrl || '',
      iosStoreUrl: update.iosStoreUrl || '',
    });
    setFormError(null);
    setIsEditModalOpen(true);
  };

  // Open View Modal
  const handleOpenView = (update: AppUpdate) => {
    setSelectedUpdate(update);
    setIsViewModalOpen(true);
  };

  // Handle Create Submit
  const handleCreateSubmit = async (publishNow = false) => {
    setFormError(null);
    setSubmitting(true);

    try {
      const payload = {
        platform: formData.platform,
        latestVersion: formData.latestVersion.trim(),
        minimumVersion: formData.minimumVersion.trim(),
        forceUpdate: formData.forceUpdate,
        title: formData.title.trim(),
        message: formData.message.trim(),
        whatsNew: formData.whatsNewText.split('\n').map((l) => l.trim()).filter((l) => l.length > 0),
        androidStoreUrl: formData.androidStoreUrl.trim() || undefined,
        iosStoreUrl: formData.iosStoreUrl.trim() || undefined,
        publishNow,
      };

      const res = await api.post('/api/v1/admin/app-updates', payload);
      if (res.success) {
        setIsCreateModalOpen(false);
        fetchUpdates();
      }
    } catch (err: any) {
      setFormError(err.message || 'Failed to create app update');
    } finally {
      setSubmitting(false);
    }
  };

  // Handle Edit Submit
  const handleEditSubmit = async () => {
    if (!selectedUpdate) return;
    setFormError(null);
    setSubmitting(true);

    try {
      const payload = {
        platform: formData.platform,
        latestVersion: formData.latestVersion.trim(),
        minimumVersion: formData.minimumVersion.trim(),
        forceUpdate: formData.forceUpdate,
        title: formData.title.trim(),
        message: formData.message.trim(),
        whatsNew: formData.whatsNewText.split('\n').map((l) => l.trim()).filter((l) => l.length > 0),
        androidStoreUrl: formData.androidStoreUrl.trim() || undefined,
        iosStoreUrl: formData.iosStoreUrl.trim() || undefined,
      };

      const res = await api.put(`/api/v1/admin/app-updates/${selectedUpdate.id}`, payload);
      if (res.success) {
        setIsEditModalOpen(false);
        fetchUpdates();
      }
    } catch (err: any) {
      setFormError(err.message || 'Failed to update app update');
    } finally {
      setSubmitting(false);
    }
  };

  // Publish Update
  const handlePublish = async (id: string) => {
    if (!window.confirm('Are you sure you want to publish this update? This will deactivate any currently active configuration for this platform.')) {
      return;
    }

    setActionLoading(id);
    try {
      const res = await api.post(`/api/v1/admin/app-updates/${id}/publish`);
      if (res.success) {
        fetchUpdates();
      }
    } catch (err: any) {
      alert(`Error publishing update: ${err.message}`);
    } finally {
      setActionLoading(null);
    }
  };

  // Disable Update
  const handleDisable = async (id: string) => {
    if (!window.confirm('Are you sure you want to disable this published update? Mobile apps will no longer prompt users for this update.')) {
      return;
    }

    setActionLoading(id);
    try {
      const res = await api.post(`/api/v1/admin/app-updates/${id}/disable`);
      if (res.success) {
        fetchUpdates();
      }
    } catch (err: any) {
      alert(`Error disabling update: ${err.message}`);
    } finally {
      setActionLoading(null);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'PUBLISHED':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
            LIVE
          </span>
        );
      case 'DRAFT':
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-amber-500/10 text-amber-400 border border-amber-500/20">
            DRAFT
          </span>
        );
      case 'DISABLED':
      default:
        return (
          <span className="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-semibold bg-slate-500/10 text-slate-400 border border-slate-500/20">
            DISABLED
          </span>
        );
    }
  };

  const getPlatformBadge = (platform: string) => {
    switch (platform) {
      case 'ANDROID':
        return (
          <span className="px-2 py-0.5 rounded text-[11px] font-medium bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
            Android
          </span>
        );
      case 'IOS':
        return (
          <span className="px-2 py-0.5 rounded text-[11px] font-medium bg-sky-500/10 text-sky-400 border border-sky-500/20">
            iOS
          </span>
        );
      case 'BOTH':
      default:
        return (
          <span className="px-2 py-0.5 rounded text-[11px] font-medium bg-purple-500/10 text-purple-400 border border-purple-500/20">
            Android & iOS
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
            <Smartphone className="w-6 h-6 text-brand-400" />
            APP UPDATES
          </h2>
          <p className="text-xs text-slate-400 mt-0.5">
            Configure mobile app update versions, force update policies, and official store URLs for Android and iOS.
          </p>
        </div>

        <button
          onClick={handleOpenCreate}
          className="inline-flex items-center gap-2 px-4 py-2 bg-brand-600 hover:bg-brand-500 text-white text-xs font-semibold rounded-xl shadow-lg shadow-brand-500/20 transition-colors"
        >
          <Plus className="w-4 h-4" />
          Create Update
        </button>
      </div>

      {/* ── LIVE CONFIGURATION CARDS (Android & iOS) ───────────────────────── */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Android Live Card */}
        <div className="bg-surface-900/60 border border-white/[0.08] rounded-2xl p-4 backdrop-blur-sm relative overflow-hidden">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-400 font-bold text-xs">
                A
              </div>
              <div>
                <h3 className="text-sm font-semibold text-white">Android Configuration</h3>
                <span className="text-[11px] text-slate-400">Google Play Store Distribution</span>
              </div>
            </div>
            {activeAndroidUpdate ? (
              <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                ACTIVE (v{activeAndroidUpdate.latestVersion})
              </span>
            ) : (
              <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-slate-500/10 text-slate-400 border border-slate-500/20">
                NO ACTIVE CONFIG
              </span>
            )}
          </div>

          {activeAndroidUpdate ? (
            <div className="mt-3 pt-3 border-t border-white/[0.06] grid grid-cols-3 gap-2 text-xs">
              <div>
                <span className="text-slate-500 block text-[10px] uppercase font-bold">Latest Ver</span>
                <span className="text-white font-mono font-semibold">v{activeAndroidUpdate.latestVersion}</span>
              </div>
              <div>
                <span className="text-slate-500 block text-[10px] uppercase font-bold">Min Supported</span>
                <span className="text-white font-mono">v{activeAndroidUpdate.minimumVersion}</span>
              </div>
              <div>
                <span className="text-slate-500 block text-[10px] uppercase font-bold">Force Update</span>
                <span className={activeAndroidUpdate.forceUpdate ? 'text-rose-400 font-bold' : 'text-slate-300'}>
                  {activeAndroidUpdate.forceUpdate ? 'Enforced' : 'Optional'}
                </span>
              </div>
            </div>
          ) : (
            <p className="mt-3 pt-3 border-t border-white/[0.06] text-xs text-slate-500">
              No live Android update currently published. App will allow all installed versions.
            </p>
          )}
        </div>

        {/* iOS Live Card */}
        <div className="bg-surface-900/60 border border-white/[0.08] rounded-2xl p-4 backdrop-blur-sm relative overflow-hidden">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2.5">
              <div className="w-8 h-8 rounded-xl bg-sky-500/10 border border-sky-500/20 flex items-center justify-center text-sky-400 font-bold text-xs">
                iOS
              </div>
              <div>
                <h3 className="text-sm font-semibold text-white">iOS Configuration</h3>
                <span className="text-[11px] text-slate-400">Apple App Store Distribution</span>
              </div>
            </div>
            {activeIosUpdate ? (
              <span className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[11px] font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
                ACTIVE (v{activeIosUpdate.latestVersion})
              </span>
            ) : (
              <span className="px-2 py-0.5 rounded-full text-[11px] font-semibold bg-slate-500/10 text-slate-400 border border-slate-500/20">
                NO ACTIVE CONFIG
              </span>
            )}
          </div>

          {activeIosUpdate ? (
            <div className="mt-3 pt-3 border-t border-white/[0.06] grid grid-cols-3 gap-2 text-xs">
              <div>
                <span className="text-slate-500 block text-[10px] uppercase font-bold">Latest Ver</span>
                <span className="text-white font-mono font-semibold">v{activeIosUpdate.latestVersion}</span>
              </div>
              <div>
                <span className="text-slate-500 block text-[10px] uppercase font-bold">Min Supported</span>
                <span className="text-white font-mono">v{activeIosUpdate.minimumVersion}</span>
              </div>
              <div>
                <span className="text-slate-500 block text-[10px] uppercase font-bold">Force Update</span>
                <span className={activeIosUpdate.forceUpdate ? 'text-rose-400 font-bold' : 'text-slate-300'}>
                  {activeIosUpdate.forceUpdate ? 'Enforced' : 'Optional'}
                </span>
              </div>
            </div>
          ) : (
            <p className="mt-3 pt-3 border-t border-white/[0.06] text-xs text-slate-500">
              No live iOS update currently published. App will allow all installed versions.
            </p>
          )}
        </div>
      </div>

      {/* ── FILTER CONTROLS ───────────────────────────────────────────────── */}
      <div className="flex flex-wrap items-center justify-between gap-3 bg-surface-900/40 p-3 rounded-2xl border border-white/[0.06]">
        <div className="flex items-center gap-3">
          <div className="flex items-center gap-2">
            <span className="text-xs text-slate-400 font-medium">Platform:</span>
            <select
              value={filterPlatform}
              onChange={(e) => setFilterPlatform(e.target.value)}
              className="bg-surface-950 border border-white/10 text-xs text-slate-200 rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-brand-500"
            >
              <option value="ALL">All Platforms</option>
              <option value="ANDROID">Android</option>
              <option value="IOS">iOS</option>
              <option value="BOTH">Both</option>
            </select>
          </div>

          <div className="flex items-center gap-2">
            <span className="text-xs text-slate-400 font-medium">Status:</span>
            <select
              value={filterStatus}
              onChange={(e) => setFilterStatus(e.target.value)}
              className="bg-surface-950 border border-white/10 text-xs text-slate-200 rounded-lg px-2.5 py-1.5 focus:outline-none focus:border-brand-500"
            >
              <option value="ALL">All Statuses</option>
              <option value="PUBLISHED">Published (LIVE)</option>
              <option value="DRAFT">Draft</option>
              <option value="DISABLED">Disabled</option>
            </select>
          </div>
        </div>

        <button
          onClick={fetchUpdates}
          className="p-1.5 text-slate-400 hover:text-white rounded-lg hover:bg-white/5 transition-colors"
          title="Refresh List"
        >
          <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
        </button>
      </div>

      {/* ── UPDATE HISTORY TABLE ─────────────────────────────────────────── */}
      <div className="bg-surface-900/60 border border-white/[0.08] rounded-2xl overflow-hidden backdrop-blur-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs border-collapse">
            <thead>
              <tr className="border-b border-white/[0.06] bg-white/[0.02] text-slate-400 uppercase text-[10px] font-bold tracking-wider">
                <th className="py-3 px-4">Version</th>
                <th className="py-3 px-4">Platform</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4">Force</th>
                <th className="py-3 px-4">Published Date</th>
                <th className="py-3 px-4">Created Date</th>
                <th className="py-3 px-4 text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-white/[0.04]">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-500">
                    <RefreshCw className="w-5 h-5 animate-spin mx-auto mb-2 text-brand-400" />
                    Loading app updates history...
                  </td>
                </tr>
              ) : updates.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-500">
                    No app updates found matching filters.
                  </td>
                </tr>
              ) : (
                updates.map((update) => (
                  <tr key={update.id} className="hover:bg-white/[0.02] transition-colors">
                    <td className="py-3 px-4">
                      <div className="font-semibold text-white font-mono text-xs flex items-center gap-1.5">
                        v{update.latestVersion}
                        {update.minimumVersion !== update.latestVersion && (
                          <span className="text-[10px] font-normal text-slate-400">
                            (min v{update.minimumVersion})
                          </span>
                        )}
                      </div>
                      <div className="text-[11px] text-slate-400 truncate max-w-[200px]" title={update.title}>
                        {update.title}
                      </div>
                    </td>
                    <td className="py-3 px-4">{getPlatformBadge(update.platform)}</td>
                    <td className="py-3 px-4">{getStatusBadge(update.status)}</td>
                    <td className="py-3 px-4">
                      {update.forceUpdate ? (
                        <span className="text-rose-400 font-bold">Yes</span>
                      ) : (
                        <span className="text-slate-400">No</span>
                      )}
                    </td>
                    <td className="py-3 px-4 text-slate-300">
                      {update.publishedAt
                        ? new Date(update.publishedAt).toLocaleDateString('en-US', {
                            month: 'short',
                            day: 'numeric',
                            year: 'numeric',
                          })
                        : '—'}
                    </td>
                    <td className="py-3 px-4 text-slate-400">
                      {new Date(update.createdAt).toLocaleDateString('en-US', {
                        month: 'short',
                        day: 'numeric',
                      })}
                    </td>
                    <td className="py-3 px-4 text-right">
                      <div className="flex items-center justify-end gap-1.5">
                        <button
                          onClick={() => handleOpenView(update)}
                          className="px-2 py-1 rounded bg-white/5 hover:bg-white/10 text-slate-300 hover:text-white transition-colors"
                          title="View Details"
                        >
                          View
                        </button>

                        <button
                          onClick={() => handleOpenEdit(update)}
                          className="px-2 py-1 rounded bg-white/5 hover:bg-white/10 text-brand-300 hover:text-brand-200 transition-colors"
                          title="Edit"
                        >
                          Edit
                        </button>

                        {update.status === 'PUBLISHED' ? (
                          <button
                            onClick={() => handleDisable(update.id)}
                            disabled={actionLoading === update.id}
                            className="px-2 py-1 rounded bg-rose-500/10 hover:bg-rose-500/20 text-rose-400 border border-rose-500/20 transition-colors"
                            title="Disable"
                          >
                            Disable
                          </button>
                        ) : (
                          <button
                            onClick={() => handlePublish(update.id)}
                            disabled={actionLoading === update.id}
                            className="px-2 py-1 rounded bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 transition-colors"
                            title="Publish"
                          >
                            Publish
                          </button>
                        )}
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* ── CREATE UPDATE MODAL ───────────────────────────────────────────── */}
      {isCreateModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-surface-900 border border-white/10 rounded-2xl w-full max-w-xl max-h-[90vh] overflow-y-auto shadow-2xl p-6 text-slate-100">
            <div className="flex items-center justify-between pb-4 border-b border-white/[0.08]">
              <div>
                <h3 className="text-base font-bold text-white">Create App Update</h3>
                <p className="text-xs text-slate-400 mt-0.5">Configure target platform and version constraints</p>
              </div>
              <button
                onClick={() => setIsCreateModalOpen(false)}
                className="p-1 text-slate-400 hover:text-white rounded-lg hover:bg-white/5"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {formError && (
              <div className="mt-4 p-3 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-300 text-xs flex items-center gap-2">
                <AlertTriangle className="w-4 h-4 flex-shrink-0" />
                <span>{formError}</span>
              </div>
            )}

            <div className="mt-4 space-y-4 text-xs">
              {/* Target Platform */}
              <div>
                <label className="block text-slate-300 font-semibold mb-1.5">Target Platform *</label>
                <div className="grid grid-cols-3 gap-2">
                  {(['BOTH', 'ANDROID', 'IOS'] as const).map((plat) => (
                    <button
                      key={plat}
                      type="button"
                      onClick={() => setFormData({ ...formData, platform: plat })}
                      className={`py-2 px-3 rounded-xl border text-center font-medium transition-all ${
                        formData.platform === plat
                          ? 'bg-brand-500/20 border-brand-500 text-brand-300 shadow-sm'
                          : 'bg-surface-950 border-white/10 text-slate-400 hover:text-white'
                      }`}
                    >
                      {plat === 'BOTH' ? 'Both (Android & iOS)' : plat === 'ANDROID' ? 'Android Only' : 'iOS Only'}
                    </button>
                  ))}
                </div>
              </div>

              {/* Versions Row */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-300 font-semibold mb-1">Latest Version *</label>
                  <input
                    type="text"
                    placeholder="e.g. 1.5.0"
                    value={formData.latestVersion}
                    onChange={(e) => setFormData({ ...formData, latestVersion: e.target.value })}
                    className="w-full bg-surface-950 border border-white/10 rounded-xl px-3 py-2 text-white font-mono focus:outline-none focus:border-brand-500"
                  />
                  <span className="text-[10px] text-slate-500 mt-0.5 block">Follows semantic versioning (X.Y.Z)</span>
                </div>

                <div>
                  <label className="block text-slate-300 font-semibold mb-1">Minimum Supported Version *</label>
                  <input
                    type="text"
                    placeholder="e.g. 1.4.0"
                    value={formData.minimumVersion}
                    onChange={(e) => setFormData({ ...formData, minimumVersion: e.target.value })}
                    className="w-full bg-surface-950 border border-white/10 rounded-xl px-3 py-2 text-white font-mono focus:outline-none focus:border-brand-500"
                  />
                  <span className="text-[10px] text-slate-500 mt-0.5 block">Versions below this will be forced to update</span>
                </div>
              </div>

              {/* Force Update Toggle */}
              <div className="bg-surface-950 p-3 rounded-xl border border-white/10 flex items-center justify-between">
                <div>
                  <span className="text-white font-semibold block">Enforce Force Update</span>
                  <span className="text-[11px] text-slate-400">
                    If checked, users on older versions cannot dismiss the update screen.
                  </span>
                </div>
                <input
                  type="checkbox"
                  checked={formData.forceUpdate}
                  onChange={(e) => setFormData({ ...formData, forceUpdate: e.target.checked })}
                  className="w-4 h-4 rounded text-brand-500 focus:ring-brand-400 bg-surface-900 border-white/20"
                />
              </div>

              {/* Title & Message */}
              <div>
                <label className="block text-slate-300 font-semibold mb-1">Update Title *</label>
                <input
                  type="text"
                  placeholder="e.g. New Update Available or Update Required"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  className="w-full bg-surface-950 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-brand-500"
                />
              </div>

              <div>
                <label className="block text-slate-300 font-semibold mb-1">Update Message *</label>
                <textarea
                  rows={2}
                  placeholder="A new version of AI Mock Interview is required to continue."
                  value={formData.message}
                  onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                  className="w-full bg-surface-950 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-brand-500 resize-none"
                />
              </div>

              {/* What's New */}
              <div>
                <label className="block text-slate-300 font-semibold mb-1">What's New (One item per line)</label>
                <textarea
                  rows={3}
                  placeholder="Faster AI interviews&#10;Better voice experience&#10;Improved follow-up questions&#10;Bug fixes"
                  value={formData.whatsNewText}
                  onChange={(e) => setFormData({ ...formData, whatsNewText: e.target.value })}
                  className="w-full bg-surface-950 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-brand-500 font-sans"
                />
              </div>

              {/* Store URLs */}
              {(formData.platform === 'ANDROID' || formData.platform === 'BOTH') && (
                <div>
                  <label className="block text-slate-300 font-semibold mb-1">Google Play Store URL *</label>
                  <input
                    type="url"
                    placeholder="https://play.google.com/store/apps/details?id=com.interviewcoach.app"
                    value={formData.androidStoreUrl}
                    onChange={(e) => setFormData({ ...formData, androidStoreUrl: e.target.value })}
                    className="w-full bg-surface-950 border border-white/10 rounded-xl px-3 py-2 text-white font-mono focus:outline-none focus:border-brand-500"
                  />
                </div>
              )}

              {(formData.platform === 'IOS' || formData.platform === 'BOTH') && (
                <div>
                  <label className="block text-slate-300 font-semibold mb-1">Apple App Store URL *</label>
                  <input
                    type="url"
                    placeholder="https://apps.apple.com/app/ai-mock-interview/id123456789"
                    value={formData.iosStoreUrl}
                    onChange={(e) => setFormData({ ...formData, iosStoreUrl: e.target.value })}
                    className="w-full bg-surface-950 border border-white/10 rounded-xl px-3 py-2 text-white font-mono focus:outline-none focus:border-brand-500"
                  />
                </div>
              )}
            </div>

            {/* Actions */}
            <div className="mt-6 pt-4 border-t border-white/[0.08] flex items-center justify-end gap-3">
              <button
                type="button"
                onClick={() => setIsCreateModalOpen(false)}
                className="px-4 py-2 rounded-xl bg-white/5 hover:bg-white/10 text-slate-300 text-xs font-semibold"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={submitting}
                onClick={() => handleCreateSubmit(false)}
                className="px-4 py-2 rounded-xl bg-surface-800 hover:bg-surface-700 text-slate-200 border border-white/10 text-xs font-semibold transition-colors"
              >
                Save Draft
              </button>
              <button
                type="button"
                disabled={submitting}
                onClick={() => handleCreateSubmit(true)}
                className="px-4 py-2 rounded-xl bg-brand-600 hover:bg-brand-500 text-white text-xs font-semibold shadow-lg shadow-brand-500/20 transition-colors"
              >
                Publish Now
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── EDIT UPDATE MODAL ─────────────────────────────────────────────── */}
      {isEditModalOpen && selectedUpdate && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-surface-900 border border-white/10 rounded-2xl w-full max-w-xl max-h-[90vh] overflow-y-auto shadow-2xl p-6 text-slate-100">
            <div className="flex items-center justify-between pb-4 border-b border-white/[0.08]">
              <div>
                <h3 className="text-base font-bold text-white">Edit App Update v{selectedUpdate.latestVersion}</h3>
                <span className="text-xs text-slate-400">Status: {selectedUpdate.status}</span>
              </div>
              <button
                onClick={() => setIsEditModalOpen(false)}
                className="p-1 text-slate-400 hover:text-white rounded-lg hover:bg-white/5"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {formError && (
              <div className="mt-4 p-3 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-300 text-xs flex items-center gap-2">
                <AlertTriangle className="w-4 h-4 flex-shrink-0" />
                <span>{formError}</span>
              </div>
            )}

            <div className="mt-4 space-y-4 text-xs">
              {/* Platform */}
              <div>
                <label className="block text-slate-300 font-semibold mb-1.5">Target Platform</label>
                <div className="grid grid-cols-3 gap-2">
                  {(['BOTH', 'ANDROID', 'IOS'] as const).map((plat) => (
                    <button
                      key={plat}
                      type="button"
                      onClick={() => setFormData({ ...formData, platform: plat })}
                      className={`py-2 px-3 rounded-xl border text-center font-medium transition-all ${
                        formData.platform === plat
                          ? 'bg-brand-500/20 border-brand-500 text-brand-300'
                          : 'bg-surface-950 border-white/10 text-slate-400'
                      }`}
                    >
                      {plat}
                    </button>
                  ))}
                </div>
              </div>

              {/* Versions */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-300 font-semibold mb-1">Latest Version</label>
                  <input
                    type="text"
                    value={formData.latestVersion}
                    onChange={(e) => setFormData({ ...formData, latestVersion: e.target.value })}
                    className="w-full bg-surface-950 border border-white/10 rounded-xl px-3 py-2 text-white font-mono focus:outline-none focus:border-brand-500"
                  />
                </div>
                <div>
                  <label className="block text-slate-300 font-semibold mb-1">Minimum Supported Version</label>
                  <input
                    type="text"
                    value={formData.minimumVersion}
                    onChange={(e) => setFormData({ ...formData, minimumVersion: e.target.value })}
                    className="w-full bg-surface-950 border border-white/10 rounded-xl px-3 py-2 text-white font-mono focus:outline-none focus:border-brand-500"
                  />
                </div>
              </div>

              {/* Force Update */}
              <div className="bg-surface-950 p-3 rounded-xl border border-white/10 flex items-center justify-between">
                <div>
                  <span className="text-white font-semibold block">Force Update</span>
                  <span className="text-[11px] text-slate-400">Blocks app interaction until updated</span>
                </div>
                <input
                  type="checkbox"
                  checked={formData.forceUpdate}
                  onChange={(e) => setFormData({ ...formData, forceUpdate: e.target.checked })}
                  className="w-4 h-4 rounded text-brand-500"
                />
              </div>

              {/* Title & Message */}
              <div>
                <label className="block text-slate-300 font-semibold mb-1">Title</label>
                <input
                  type="text"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  className="w-full bg-surface-950 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-brand-500"
                />
              </div>

              <div>
                <label className="block text-slate-300 font-semibold mb-1">Message</label>
                <textarea
                  rows={2}
                  value={formData.message}
                  onChange={(e) => setFormData({ ...formData, message: e.target.value })}
                  className="w-full bg-surface-950 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-brand-500 resize-none"
                />
              </div>

              {/* What's New */}
              <div>
                <label className="block text-slate-300 font-semibold mb-1">What's New</label>
                <textarea
                  rows={3}
                  value={formData.whatsNewText}
                  onChange={(e) => setFormData({ ...formData, whatsNewText: e.target.value })}
                  className="w-full bg-surface-950 border border-white/10 rounded-xl px-3 py-2 text-white focus:outline-none focus:border-brand-500"
                />
              </div>

              {/* Store URLs */}
              <div>
                <label className="block text-slate-300 font-semibold mb-1">Google Play Store URL</label>
                <input
                  type="url"
                  value={formData.androidStoreUrl}
                  onChange={(e) => setFormData({ ...formData, androidStoreUrl: e.target.value })}
                  className="w-full bg-surface-950 border border-white/10 rounded-xl px-3 py-2 text-white font-mono focus:outline-none focus:border-brand-500"
                />
              </div>

              <div>
                <label className="block text-slate-300 font-semibold mb-1">Apple App Store URL</label>
                <input
                  type="url"
                  value={formData.iosStoreUrl}
                  onChange={(e) => setFormData({ ...formData, iosStoreUrl: e.target.value })}
                  className="w-full bg-surface-950 border border-white/10 rounded-xl px-3 py-2 text-white font-mono focus:outline-none focus:border-brand-500"
                />
              </div>
            </div>

            <div className="mt-6 pt-4 border-t border-white/[0.08] flex items-center justify-end gap-3">
              <button
                type="button"
                onClick={() => setIsEditModalOpen(false)}
                className="px-4 py-2 rounded-xl bg-white/5 hover:bg-white/10 text-slate-300 text-xs font-semibold"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={submitting}
                onClick={handleEditSubmit}
                className="px-4 py-2 rounded-xl bg-brand-600 hover:bg-brand-500 text-white text-xs font-semibold shadow-lg shadow-brand-500/20 transition-colors"
              >
                Save Changes
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ── VIEW UPDATE MODAL ─────────────────────────────────────────────── */}
      {isViewModalOpen && selectedUpdate && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/70 backdrop-blur-sm animate-in fade-in duration-200">
          <div className="bg-surface-900 border border-white/10 rounded-2xl w-full max-w-lg shadow-2xl p-6 text-slate-100 space-y-4 text-xs">
            <div className="flex items-center justify-between pb-3 border-b border-white/[0.08]">
              <div>
                <div className="flex items-center gap-2">
                  <h3 className="text-base font-bold text-white font-mono">v{selectedUpdate.latestVersion}</h3>
                  {getStatusBadge(selectedUpdate.status)}
                  {getPlatformBadge(selectedUpdate.platform)}
                </div>
                <span className="text-[11px] text-slate-400">Created: {new Date(selectedUpdate.createdAt).toLocaleString()}</span>
              </div>
              <button
                onClick={() => setIsViewModalOpen(false)}
                className="p-1 text-slate-400 hover:text-white rounded-lg hover:bg-white/5"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-3">
              <div className="grid grid-cols-2 gap-3 bg-surface-950 p-3 rounded-xl border border-white/[0.06]">
                <div>
                  <span className="text-slate-500 uppercase text-[10px] font-bold block">Min Supported Version</span>
                  <span className="text-white font-mono font-semibold">v{selectedUpdate.minimumVersion}</span>
                </div>
                <div>
                  <span className="text-slate-500 uppercase text-[10px] font-bold block">Force Update</span>
                  <span className={selectedUpdate.forceUpdate ? 'text-rose-400 font-bold' : 'text-slate-300'}>
                    {selectedUpdate.forceUpdate ? 'Yes (Enforced)' : 'No (Optional)'}
                  </span>
                </div>
              </div>

              <div>
                <span className="text-slate-400 font-semibold block mb-0.5">Title</span>
                <p className="text-white font-medium bg-surface-950 p-2.5 rounded-xl border border-white/[0.06]">
                  {selectedUpdate.title}
                </p>
              </div>

              <div>
                <span className="text-slate-400 font-semibold block mb-0.5">Message</span>
                <p className="text-slate-300 bg-surface-950 p-2.5 rounded-xl border border-white/[0.06]">
                  {selectedUpdate.message}
                </p>
              </div>

              {selectedUpdate.whatsNew && selectedUpdate.whatsNew.length > 0 && (
                <div>
                  <span className="text-slate-400 font-semibold block mb-1">What's New:</span>
                  <ul className="space-y-1 bg-surface-950 p-3 rounded-xl border border-white/[0.06]">
                    {selectedUpdate.whatsNew.map((item, idx) => (
                      <li key={idx} className="flex items-center gap-2 text-slate-200">
                        <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400 flex-shrink-0" />
                        <span>{item}</span>
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {selectedUpdate.androidStoreUrl && (
                <div>
                  <span className="text-slate-400 font-semibold block mb-0.5">Play Store URL</span>
                  <a
                    href={selectedUpdate.androidStoreUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="text-brand-400 hover:underline flex items-center gap-1 font-mono text-[11px] truncate"
                  >
                    {selectedUpdate.androidStoreUrl}
                    <ExternalLink className="w-3 h-3 flex-shrink-0" />
                  </a>
                </div>
              )}

              {selectedUpdate.iosStoreUrl && (
                <div>
                  <span className="text-slate-400 font-semibold block mb-0.5">App Store URL</span>
                  <a
                    href={selectedUpdate.iosStoreUrl}
                    target="_blank"
                    rel="noreferrer"
                    className="text-sky-400 hover:underline flex items-center gap-1 font-mono text-[11px] truncate"
                  >
                    {selectedUpdate.iosStoreUrl}
                    <ExternalLink className="w-3 h-3 flex-shrink-0" />
                  </a>
                </div>
              )}
            </div>

            <div className="pt-3 border-t border-white/[0.08] flex items-center justify-end">
              <button
                type="button"
                onClick={() => setIsViewModalOpen(false)}
                className="px-4 py-2 rounded-xl bg-white/5 hover:bg-white/10 text-slate-300 text-xs font-semibold"
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
