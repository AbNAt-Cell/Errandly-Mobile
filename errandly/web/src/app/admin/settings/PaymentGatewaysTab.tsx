'use client';

import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminApi } from '@/lib/api';
import toast from 'react-hot-toast';
import {
  Settings as SettingsIcon,
  X,
  Copy,
  Check,
  Eye,
  EyeOff,
  Upload,
  Info,
  Loader2,
  ShieldCheck,
} from 'lucide-react';
import { GatewayIcon, PaystackIcon, BachIcon } from '@/components/payment/PaymentIcons';

export interface PaymentGatewayData {
  id: string;
  name: string;
  title: string;
  tagline: string;
  description: string;
  badge: string;
  enabled: boolean;
  status: boolean;
  mode: 'test' | 'live';
  logo_url: string;
  public_key: string;
  secret_key: string;
  webhook_secret?: string;
  webhook_url: string;
  supported_currencies: string[];
  is_configured: boolean;
}

export function PaymentGatewaysTab() {
  const queryClient = useQueryClient();
  const [modalGateway, setModalGateway] = useState<PaymentGatewayData | null>(null);
  const [formData, setFormData] = useState({
    title: '',
    enabled: true,
    mode: 'test' as 'test' | 'live',
    public_key: '',
    secret_key: '',
    webhook_secret: '',
    logo_url: '',
  });
  const [showSecret, setShowSecret] = useState(false);
  const [showWebhookSecret, setShowWebhookSecret] = useState(false);
  const [copiedField, setCopiedField] = useState<string | null>(null);
  const [uploadingLogo, setUploadingLogo] = useState(false);

  // Fetch all payment gateways
  const { data: response, isLoading } = useQuery({
    queryKey: ['admin-payment-gateways'],
    queryFn: () => adminApi.paymentGateways().then((res) => res.data),
  });

  const gateways: PaymentGatewayData[] = response?.data ?? [];

  // Toggle quick mutation
  const toggleMutation = useMutation({
    mutationFn: ({ id, enabled }: { id: string; enabled: boolean }) =>
      adminApi.togglePaymentGateway(id, enabled),
    onSuccess: (res, vars) => {
      toast.success(
        `${vars.id.charAt(0).toUpperCase() + vars.id.slice(1)} ${
          vars.enabled ? 'activated' : 'deactivated'
        }`
      );
      queryClient.invalidateQueries({ queryKey: ['admin-payment-gateways'] });
      queryClient.invalidateQueries({ queryKey: ['public-payment-gateways'] });
      queryClient.invalidateQueries({ queryKey: ['platform-config'] });
    },
    onError: (err: any) => {
      toast.error(err?.response?.data?.message || 'Failed to update gateway status');
    },
  });

  // Save full settings mutation
  const saveMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: any }) =>
      adminApi.updatePaymentGateway(id, data),
    onSuccess: (res, vars) => {
      toast.success('Gateway configuration saved successfully.');
      queryClient.invalidateQueries({ queryKey: ['admin-payment-gateways'] });
      queryClient.invalidateQueries({ queryKey: ['public-payment-gateways'] });
      queryClient.invalidateQueries({ queryKey: ['platform-config'] });
      setModalGateway(null);
    },
    onError: (err: any) => {
      toast.error(err?.response?.data?.message || 'Failed to save configuration');
    },
  });

  const handleToggle = (id: string, newEnabled: boolean) => {
    toggleMutation.mutate({ id, enabled: newEnabled });
  };

  const openSetupModal = (gw: PaymentGatewayData) => {
    setModalGateway(gw);
    setFormData({
      title: gw.title || gw.name,
      enabled: gw.enabled,
      mode: gw.mode || 'test',
      public_key: gw.public_key || '',
      secret_key: gw.secret_key || '',
      webhook_secret: gw.webhook_secret || '',
      logo_url: gw.logo_url || '',
    });
    setShowSecret(false);
    setShowWebhookSecret(false);
  };

  const handleCopy = (text: string, fieldName: string) => {
    if (!text) return;
    navigator.clipboard.writeText(text);
    setCopiedField(fieldName);
    toast.success(`${fieldName} copied to clipboard`);
    setTimeout(() => setCopiedField(null), 2000);
  };

  const handleLogoUpload = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (file.size > 2 * 1024 * 1024) {
      toast.error('Logo file size must be less than 2MB');
      return;
    }

    setUploadingLogo(true);
    try {
      const res = await adminApi.uploadLogo(file);
      const url = res.data?.url || res.data?.path;
      if (url) {
        setFormData((prev) => ({ ...prev, logo_url: url }));
        toast.success('Logo uploaded');
      }
    } catch (err: any) {
      toast.error(err?.response?.data?.message || 'Failed to upload logo');
    } finally {
      setUploadingLogo(false);
    }
  };

  const handleSaveModal = () => {
    if (!modalGateway) return;
    let pubKey = formData.public_key.trim();
    let secKey = formData.secret_key.trim();

    // Auto-detect and swap if public key and secret key were pasted inverted
    if (pubKey.startsWith('sk_') && secKey.startsWith('pk_')) {
      const temp = pubKey;
      pubKey = secKey;
      secKey = temp;
      toast('Public and Secret keys automatically corrected to match standard format.', { icon: 'ℹ️' });
    }

    saveMutation.mutate({
      id: modalGateway.id,
      data: {
        title: formData.title,
        enabled: formData.enabled,
        mode: formData.mode,
        public_key: pubKey,
        secret_key: secKey,
        webhook_secret: formData.webhook_secret.trim(),
        logo_url: formData.logo_url,
      },
    });
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-xl font-bold text-[#0E0F13]">Payment Processors</h2>
          <p className="text-gray-500 text-sm mt-0.5">
            Choose which payment processor shows in website and mobile apps by toggling on and off.
          </p>
        </div>
      </div>

      {isLoading ? (
        <div className="flex justify-center items-center py-12">
          <Loader2 className="w-7 h-7 animate-spin text-[#F97316]" />
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {gateways.map((gw) => (
            <div
              key={gw.id}
              className={`bg-white rounded-2xl border-2 p-4 sm:p-5 transition-all shadow-sm flex items-center justify-between ${
                gw.enabled ? 'border-gray-200' : 'border-gray-100 opacity-75 bg-gray-50/50'
              }`}
            >
              <div className="flex items-center gap-3.5 min-w-0">
                <div className="w-12 h-12 rounded-xl flex items-center justify-center p-2 bg-gray-50 border border-gray-100 shadow-sm shrink-0">
                  <GatewayIcon
                    gatewayId={gw.id}
                    logoUrl={gw.logo_url}
                    className="w-7 h-7 object-contain"
                  />
                </div>
                <div className="min-w-0">
                  <div className="flex items-center gap-2 flex-wrap">
                    <span className="font-bold text-sm sm:text-base text-[#0E0F13] truncate">
                      {gw.title || gw.name}
                    </span>
                    <span
                      className={`text-[10px] font-extrabold px-2 py-0.5 rounded-md border uppercase tracking-wider ${
                        gw.mode === 'live'
                          ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                          : 'bg-sky-50 text-sky-700 border-sky-200'
                      }`}
                    >
                      {gw.mode === 'live' ? 'Live' : 'Test'}
                    </span>
                    {gw.webhook_secret && (
                      <span className="text-[10px] font-bold px-2 py-0.5 rounded-md bg-emerald-50 text-emerald-700 border border-emerald-200 flex items-center gap-1">
                        <ShieldCheck className="w-3 h-3 text-emerald-600" />
                        whsec
                      </span>
                    )}
                  </div>
                  <p className="text-xs text-gray-500 mt-0.5 line-clamp-1">{gw.tagline}</p>
                </div>
              </div>

              <div className="flex items-center gap-3 shrink-0 ml-3">
                {/* Status Toggle Switch (Teal #0D9488 when ON, gray when OFF) */}
                <button
                  type="button"
                  title={gw.enabled ? 'Click to disable' : 'Click to enable'}
                  onClick={() => handleToggle(gw.id, !gw.enabled)}
                  disabled={toggleMutation.isPending}
                  className={`relative inline-flex h-7 w-12 items-center rounded-full transition-colors cursor-pointer focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-[#0D9488] ${
                    gw.enabled ? 'bg-[#0D9488]' : 'bg-gray-200'
                  }`}
                >
                  <span
                    className={`inline-block h-5 w-5 transform rounded-full bg-white shadow-md transition-transform duration-200 ease-in-out ${
                      gw.enabled ? 'translate-x-6' : 'translate-x-1'
                    }`}
                  />
                </button>

                {/* Orange Gear Settings Button */}
                <button
                  type="button"
                  title={`Configure ${gw.name} settings`}
                  onClick={() => openSetupModal(gw)}
                  className="w-9 h-9 rounded-xl bg-amber-50 hover:bg-amber-100 border border-amber-200 text-amber-600 flex items-center justify-center transition shadow-sm cursor-pointer"
                >
                  <SettingsIcon className="w-4 h-4 stroke-[2.2]" />
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Setup Modal */}
      {modalGateway && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4 sm:p-6 overflow-y-auto">
          <div className="bg-white rounded-3xl w-full max-w-lg shadow-2xl relative my-auto overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            {/* Modal Header */}
            <div className="flex items-center justify-between px-6 py-4 border-b border-gray-100 bg-gray-50/70">
              <h3 className="font-bold text-lg text-[#0E0F13]">
                Setup - {modalGateway.name}
              </h3>
              <button
                type="button"
                onClick={() => setModalGateway(null)}
                className="w-8 h-8 rounded-full bg-white hover:bg-gray-200 border border-gray-200 flex items-center justify-center text-gray-500 transition cursor-pointer"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-6 space-y-5 max-h-[80vh] overflow-y-auto">
              {/* Section 1: Gateway Name & Status Toggle Box */}
              <div className="bg-gray-50/80 rounded-2xl p-4 border border-gray-100 space-y-3">
                <div>
                  <h4 className="font-bold text-sm text-[#0E0F13]">{modalGateway.name}</h4>
                  <p className="text-xs text-gray-500 mt-0.5">
                    If you turn off, customers can't pay through this payment gateway.
                  </p>
                </div>

                <div className="bg-white rounded-xl p-3 border border-gray-200 flex items-center justify-between">
                  <span className="font-semibold text-sm text-[#0E0F13]">Status</span>
                  <button
                    type="button"
                    onClick={() => setFormData((p) => ({ ...p, enabled: !p.enabled }))}
                    className={`relative inline-flex h-7 w-12 items-center rounded-full transition-colors cursor-pointer ${
                      formData.enabled ? 'bg-[#0D9488]' : 'bg-gray-200'
                    }`}
                  >
                    <span
                      className={`inline-block h-5 w-5 transform rounded-full bg-white shadow-md transition-transform duration-200 ${
                        formData.enabled ? 'translate-x-6' : 'translate-x-1'
                      }`}
                    />
                  </button>
                </div>
              </div>

              {/* Section 2: Choose Logo */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-gray-700 flex items-center gap-1">
                  Choose Logo <span className="text-red-500">*</span>
                </label>
                <p className="text-[11px] text-gray-400">It will show in website & app.</p>

                <div className="relative border-2 border-dashed border-gray-200 hover:border-gray-300 rounded-2xl p-4 flex flex-col items-center justify-center bg-gray-50/50 transition">
                  <div className="w-36 h-14 rounded-xl bg-white border border-gray-100 shadow-sm flex items-center justify-center p-2 mb-2">
                    {formData.logo_url ? (
                      <img
                        src={formData.logo_url}
                        alt="Logo"
                        className="max-h-full max-w-full object-contain"
                      />
                    ) : (
                      <GatewayIcon
                        gatewayId={modalGateway.id}
                        logoUrl={modalGateway.logo_url}
                        className="w-10 h-10 object-contain"
                      />
                    )}
                  </div>
                  <p className="text-[10px] text-gray-400 text-center font-medium">
                    JPEG, JPG, PNG, GIF, WEBP. Less Than 2MB (3:1)
                  </p>
                  <label className="mt-2 text-xs font-bold text-[#F97316] hover:underline cursor-pointer flex items-center gap-1">
                    {uploadingLogo ? (
                      <Loader2 className="w-3.5 h-3.5 animate-spin" />
                    ) : (
                      <Upload className="w-3.5 h-3.5" />
                    )}
                    Upload Custom Logo
                    <input
                      type="file"
                      accept="image/*"
                      className="hidden"
                      onChange={handleLogoUpload}
                      disabled={uploadingLogo}
                    />
                  </label>
                </div>
              </div>

              {/* Section 3: Payment Gateway Title */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-gray-700">
                  Payment Gateway Title <span className="text-red-500">*</span>
                </label>
                <input
                  type="text"
                  value={formData.title}
                  onChange={(e) => setFormData((p) => ({ ...p, title: e.target.value }))}
                  className="w-full px-3.5 py-2.5 bg-white border border-gray-200 rounded-xl text-sm font-medium focus:outline-none focus:ring-2 focus:ring-[#F97316]"
                  placeholder="e.g. Paystack"
                />
              </div>

              {/* Section 4: Choose Use Type (Live / Test) */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-gray-700 flex items-center gap-1">
                  Choose Use Type <span className="text-red-500">*</span>
                  <Info className="w-3.5 h-3.5 text-gray-400" />
                </label>
                <div className="flex items-center gap-6 p-3 bg-white border border-gray-200 rounded-xl">
                  <label className="flex items-center gap-2 cursor-pointer text-sm font-medium text-gray-700">
                    <input
                      type="radio"
                      name="mode"
                      value="live"
                      checked={formData.mode === 'live'}
                      onChange={() => setFormData((p) => ({ ...p, mode: 'live' }))}
                      className="w-4 h-4 text-[#0D9488] focus:ring-[#0D9488]"
                    />
                    Live
                  </label>
                  <label className="flex items-center gap-2 cursor-pointer text-sm font-medium text-gray-700">
                    <input
                      type="radio"
                      name="mode"
                      value="test"
                      checked={formData.mode === 'test'}
                      onChange={() => setFormData((p) => ({ ...p, mode: 'test' }))}
                      className="w-4 h-4 text-[#0D9488] focus:ring-[#0D9488]"
                    />
                    Test
                  </label>
                </div>
              </div>

              {/* Section 5: Public Key */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-gray-700">
                  Public Key <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <input
                    type="text"
                    value={formData.public_key}
                    onChange={(e) => setFormData((p) => ({ ...p, public_key: e.target.value }))}
                    className="w-full pl-3.5 pr-10 py-2.5 bg-white border border-gray-200 rounded-xl text-sm font-mono focus:outline-none focus:ring-2 focus:ring-[#F97316]"
                    placeholder="pk_test_... or pk_live_..."
                  />
                  <button
                    type="button"
                    onClick={() => handleCopy(formData.public_key, 'Public Key')}
                    className="absolute right-2.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition"
                  >
                    {copiedField === 'Public Key' ? (
                      <Check className="w-4 h-4 text-emerald-600" />
                    ) : (
                      <Copy className="w-4 h-4" />
                    )}
                  </button>
                </div>
                {formData.public_key.trim().startsWith('sk_') && (
                  <p className="text-[11px] text-amber-600 font-medium">
                    ⚠️ Note: Public keys normally start with &quot;pk_&quot;. If swapped with secret key, system will auto-correct on save.
                  </p>
                )}
              </div>

              {/* Section 6: Secret Key */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-gray-700">
                  Secret Key <span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <input
                    type={showSecret ? 'text' : 'password'}
                    value={formData.secret_key}
                    onChange={(e) => setFormData((p) => ({ ...p, secret_key: e.target.value }))}
                    className="w-full pl-3.5 pr-18 py-2.5 bg-white border border-gray-200 rounded-xl text-sm font-mono focus:outline-none focus:ring-2 focus:ring-[#F97316]"
                    placeholder="sk_test_... or sk_live_..."
                  />
                  <div className="absolute right-2.5 top-1/2 -translate-y-1/2 flex items-center gap-1.5 text-gray-400">
                    <button
                      type="button"
                      onClick={() => setShowSecret(!showSecret)}
                      className="hover:text-gray-600 transition p-1"
                    >
                      {showSecret ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                    <button
                      type="button"
                      onClick={() => handleCopy(formData.secret_key, 'Secret Key')}
                      className="hover:text-gray-600 transition p-1"
                    >
                      {copiedField === 'Secret Key' ? (
                        <Check className="w-4 h-4 text-emerald-600" />
                      ) : (
                        <Copy className="w-4 h-4" />
                      )}
                    </button>
                  </div>
                </div>
                {formData.secret_key.trim().startsWith('pk_') && (
                  <p className="text-[11px] text-amber-600 font-medium">
                    ⚠️ Note: Secret keys normally start with &quot;sk_&quot;. If swapped with public key, system will auto-correct on save.
                  </p>
                )}
              </div>

              {/* Section 7: Webhook URL */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-gray-700 flex items-center gap-1">
                  Webhook URL
                  <span className="text-[10px] text-gray-400 font-normal">
                    (Paste in your {modalGateway.name} dashboard)
                  </span>
                </label>
                <div className="relative">
                  <input
                    type="text"
                    readOnly
                    value={modalGateway.webhook_url}
                    className="w-full pl-3.5 pr-10 py-2.5 bg-gray-50 border border-gray-200 rounded-xl text-xs font-mono text-gray-600 select-all"
                  />
                  <button
                    type="button"
                    onClick={() => handleCopy(modalGateway.webhook_url, 'Webhook URL')}
                    className="absolute right-2.5 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition"
                  >
                    {copiedField === 'Webhook URL' ? (
                      <Check className="w-4 h-4 text-emerald-600" />
                    ) : (
                      <Copy className="w-4 h-4" />
                    )}
                  </button>
                </div>
              </div>

              {/* Section 8: Webhook Signing Secret (whsec_...) */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-gray-700 flex items-center justify-between">
                  <span className="flex items-center gap-1">
                    Webhook Signing Secret
                    <span className="text-[10px] text-gray-400 font-normal">
                      (Paste whsec_... from {modalGateway.name} dashboard)
                    </span>
                  </span>
                  {formData.webhook_secret ? (
                    <span className="text-[10px] font-semibold text-emerald-600 flex items-center gap-1">
                      <ShieldCheck className="w-3.5 h-3.5" /> Configured
                    </span>
                  ) : (
                    <span className="text-[10px] font-medium text-amber-600">
                      Recommended
                    </span>
                  )}
                </label>
                <div className="relative">
                  <input
                    type={showWebhookSecret ? 'text' : 'password'}
                    value={formData.webhook_secret}
                    onChange={(e) => setFormData((p) => ({ ...p, webhook_secret: e.target.value }))}
                    className="w-full pl-3.5 pr-20 py-2.5 bg-white border border-gray-200 rounded-xl text-sm font-mono focus:outline-none focus:ring-2 focus:ring-[#F97316]"
                    placeholder="whsec_... (Signing secret from Bachs or Paystack)"
                  />
                  <div className="absolute right-2.5 top-1/2 -translate-y-1/2 flex items-center gap-1.5 text-gray-400">
                    <button
                      type="button"
                      onClick={() => setShowWebhookSecret(!showWebhookSecret)}
                      className="hover:text-gray-600 transition p-1"
                      title={showWebhookSecret ? 'Hide secret' : 'Show secret'}
                    >
                      {showWebhookSecret ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                    </button>
                    <button
                      type="button"
                      onClick={() => handleCopy(formData.webhook_secret, 'Webhook Secret')}
                      className="hover:text-gray-600 transition p-1"
                      title="Copy webhook secret"
                    >
                      {copiedField === 'Webhook Secret' ? (
                        <Check className="w-4 h-4 text-emerald-600" />
                      ) : (
                        <Copy className="w-4 h-4" />
                      )}
                    </button>
                  </div>
                </div>
                <p className="text-[11px] text-gray-500">
                  Used by Errandly to cryptographically verify HMAC SHA-256 signatures on incoming webhook notifications from {modalGateway.name}.
                </p>
              </div>
            </div>

            {/* Modal Footer */}
            <div className="flex items-center justify-end gap-3 px-6 py-4 border-t border-gray-100 bg-gray-50/50">
              <button
                type="button"
                onClick={() => setModalGateway(null)}
                className="px-4 py-2.5 rounded-xl border border-gray-200 text-gray-600 hover:bg-gray-100 text-sm font-semibold transition cursor-pointer"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={saveMutation.isPending}
                onClick={handleSaveModal}
                className="px-5 py-2.5 rounded-xl bg-[#F97316] hover:bg-orange-600 text-white text-sm font-bold flex items-center gap-2 transition shadow-md disabled:opacity-50 cursor-pointer"
              >
                {saveMutation.isPending && <Loader2 className="w-4 h-4 animate-spin" />}
                Save Changes
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
