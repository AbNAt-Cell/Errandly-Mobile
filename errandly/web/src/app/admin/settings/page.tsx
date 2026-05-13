'use client';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminApi } from '@/lib/api';
import { useState } from 'react';
import toast from 'react-hot-toast';
import { Save, Loader2 } from 'lucide-react';

export default function AdminSettingsPage() {
  const queryClient = useQueryClient();
  const [changes, setChanges] = useState<Record<string, string>>({});

  const { data: settings } = useQuery({
    queryKey: ['admin-settings'],
    queryFn: () => adminApi.settings().then((r) => r.data),
  });

  const updateMutation = useMutation({
    mutationFn: (data: any) => adminApi.updateSettings(data),
    onSuccess: () => {
      toast.success('Settings saved.');
      queryClient.invalidateQueries({ queryKey: ['admin-settings'] });
      setChanges({});
    },
    onError: (e: any) => toast.error(e.response?.data?.message || 'Failed to save'),
  });

  const handleChange = (key: string, value: string) => {
    setChanges((prev) => ({ ...prev, [key]: value }));
  };

  const handleSave = () => {
    if (Object.keys(changes).length === 0) return;
    updateMutation.mutate(changes);
  };

  const settingGroups = [
    { group: 'finance', label: 'Finance', keys: ['platform_commission_rate', 'min_errand_amount', 'min_withdrawal_amount', 'withdrawal_processing_days', 'currency'] },
    { group: 'matching', label: 'Runner Matching', keys: ['max_runner_search_radius_km', 'errand_acceptance_timeout_minutes'] },
    { group: 'general', label: 'General', keys: ['platform_name', 'support_email', 'support_phone'] },
    { group: 'kyc', label: 'KYC', keys: ['kyc_required_for_errand'] },
  ];

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[#0A1628]">Platform Settings</h1>
          <p className="text-gray-500 text-sm">Configure platform-wide settings</p>
        </div>
        <button
          onClick={handleSave}
          disabled={Object.keys(changes).length === 0 || updateMutation.isPending}
          className="errandly-btn-primary flex items-center gap-2 disabled:opacity-50"
        >
          {updateMutation.isPending ? <Loader2 className="w-4 h-4 animate-spin" /> : <Save className="w-4 h-4" />}
          Save Changes
        </button>
      </div>

      {settingGroups.map((group) => (
        <div key={group.group} className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
          <div className="px-6 py-4 bg-gray-50 border-b border-gray-100">
            <h3 className="font-bold text-[#0A1628]">{group.label}</h3>
          </div>
          <div className="p-6 space-y-4">
            {group.keys.map((key) => {
              const setting = settings?.[key];
              if (!setting) return null;
              const value = changes[key] ?? setting.value;

              return (
                <div key={key} className="flex items-center gap-6">
                  <div className="w-64">
                    <p className="font-medium text-[#0A1628] text-sm">{key.replace(/_/g, ' ').replace(/\b\w/g, (l) => l.toUpperCase())}</p>
                    {setting.description && <p className="text-xs text-gray-500 mt-0.5">{setting.description}</p>}
                  </div>
                  <div className="flex-1">
                    {setting.type === 'boolean' ? (
                      <select
                        value={value}
                        onChange={(e) => handleChange(key, e.target.value)}
                        className="px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#FF6B00] bg-white"
                      >
                        <option value="true">Enabled</option>
                        <option value="false">Disabled</option>
                      </select>
                    ) : (
                      <input
                        value={value}
                        onChange={(e) => handleChange(key, e.target.value)}
                        type={setting.type === 'integer' || setting.type === 'float' ? 'number' : 'text'}
                        step={setting.type === 'float' ? '0.01' : undefined}
                        className="px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#FF6B00] w-full max-w-xs"
                      />
                    )}
                  </div>
                  {changes[key] !== undefined && (
                    <span className="text-xs text-amber-600 font-medium">Modified</span>
                  )}
                </div>
              );
            })}
          </div>
        </div>
      ))}
    </div>
  );
}
