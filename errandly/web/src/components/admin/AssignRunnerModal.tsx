'use client';

import { useState, useMemo } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminApi } from '@/lib/api';
import toast from 'react-hot-toast';
import {
  X,
  Search,
  UserCheck,
  ShieldCheck,
  Loader2,
  CheckCircle2,
  AlertCircle,
  MapPin,
  Car,
  Bike,
  Footprints,
  Sparkles,
} from 'lucide-react';

interface AssignRunnerModalProps {
  errand: any;
  isOpen: boolean;
  onClose: () => void;
  onAssigned?: (updatedErrand: any) => void;
}

export default function AssignRunnerModal({
  errand,
  isOpen,
  onClose,
  onAssigned,
}: AssignRunnerModalProps) {
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState('');
  const [filterType, setFilterType] = useState<'all' | 'online' | 'verified'>('all');
  const [selectedRunnerId, setSelectedRunnerId] = useState<number | null>(null);
  const [reason, setReason] = useState('Admin dispatch assignment');

  // Fetch active/available runners
  const { data: runnersData, isLoading: isLoadingRunners } = useQuery({
    queryKey: ['admin-available-runners'],
    queryFn: () => adminApi.runners({ status: 'active', per_page: 50 }).then((r) => r.data),
    enabled: isOpen,
    staleTime: 15000,
  });

  const runners: any[] = useMemo(() => {
    return runnersData?.data || [];
  }, [runnersData]);

  // Filter runners by search and pills
  const filteredRunners = useMemo(() => {
    return runners.filter((runner: any) => {
      const profile = runner.runner_profile || runner.runnerProfile;
      const fullName = `${runner.first_name || ''} ${runner.last_name || ''}`.toLowerCase();
      const phone = (runner.phone || '').toLowerCase();
      const city = (profile?.service_city || '').toLowerCase();
      const query = searchTerm.toLowerCase().trim();

      const matchesSearch =
        !query ||
        fullName.includes(query) ||
        phone.includes(query) ||
        city.includes(query);

      if (!matchesSearch) return false;

      if (filterType === 'online') {
        return !!profile?.is_online;
      }
      if (filterType === 'verified') {
        return (
          profile?.verification_status === 'approved' ||
          profile?.is_verified === true
        );
      }

      return true;
    });
  }, [runners, searchTerm, filterType]);

  const selectedRunner = useMemo(() => {
    return runners.find((r: any) => r.id === selectedRunnerId);
  }, [runners, selectedRunnerId]);

  const assignMutation = useMutation({
    mutationFn: async () => {
      if (!selectedRunnerId) throw new Error('Please select a runner.');
      const res = await adminApi.assignErrand(errand.public_id, {
        runner_id: selectedRunnerId,
        reason: reason.trim() || 'Admin dispatch assignment',
      });
      return res.data;
    },
    onSuccess: (data) => {
      const runnerName = selectedRunner
        ? `${selectedRunner.first_name} ${selectedRunner.last_name}`
        : 'Runner';
      toast.success(`${runnerName} has been assigned to errand.`);
      queryClient.invalidateQueries({ queryKey: ['admin-errands'] });
      queryClient.invalidateQueries({ queryKey: ['admin-errand', errand.public_id] });
      if (onAssigned) {
        onAssigned(data.errand || data);
      }
      onClose();
    },
    onError: (err: any) => {
      const msg = err.response?.data?.message || err.message || 'Failed to assign runner.';
      toast.error(msg);
    },
  });

  if (!isOpen || !errand) return null;

  const isAlreadyAssigned = !!errand.runner || !!errand.runner_id;

  const renderTransportIcon = (type?: string) => {
    switch (type) {
      case 'car':
        return <Car className="w-3.5 h-3.5" />;
      case 'bicycle':
      case 'motorcycle':
        return <Bike className="w-3.5 h-3.5" />;
      default:
        return <Footprints className="w-3.5 h-3.5" />;
    }
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm animate-fade-in">
      <div className="bg-white rounded-2xl max-w-2xl w-full shadow-2xl border border-gray-100 flex flex-col max-h-[90vh] overflow-hidden">
        {/* Modal Header */}
        <div className="px-6 py-4 border-b border-gray-100 flex items-center justify-between bg-gray-50/50">
          <div>
            <div className="flex items-center gap-2">
              <span className="p-1.5 bg-[#F97316]/10 text-[#F97316] rounded-lg">
                <UserCheck className="w-5 h-5" />
              </span>
              <h2 className="text-lg font-bold text-[#0E0F13]">
                {isAlreadyAssigned ? 'Reassign Runner' : 'Assign Runner to Order'}
              </h2>
            </div>
            <p className="text-xs text-gray-500 mt-1">
              Select an active runner to dispatch this pending errand.
            </p>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 text-gray-400 hover:text-gray-700 hover:bg-gray-100 rounded-lg transition"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Errand Quick Summary Card */}
        <div className="p-4 mx-6 mt-4 rounded-xl bg-orange-50/50 border border-orange-100/70 text-xs">
          <div className="flex items-start justify-between gap-2">
            <div>
              <p className="font-semibold text-gray-900 text-sm">{errand.title}</p>
              <p className="text-gray-500 font-mono text-[11px] mt-0.5">{errand.public_id}</p>
            </div>
            <div className="text-right">
              <span className="font-bold text-sm text-[#F97316]">
                ₦{Number(errand.budget || 0).toLocaleString()}
              </span>
              <p className="text-[11px] text-gray-500 capitalize">{errand.category?.replace(/_/g, ' ')}</p>
            </div>
          </div>

          <div className="mt-2.5 pt-2 border-t border-orange-100 flex flex-col sm:flex-row gap-2 sm:gap-4 text-gray-600">
            <div className="flex items-center gap-1.5 truncate">
              <MapPin className="w-3.5 h-3.5 text-[#F97316] shrink-0" />
              <span className="text-gray-400">From:</span>
              <span className="truncate max-w-[200px]" title={errand.pickup_address}>
                {errand.pickup_address || 'Not specified'}
              </span>
            </div>
            <div className="flex items-center gap-1.5 truncate">
              <MapPin className="w-3.5 h-3.5 text-green-600 shrink-0" />
              <span className="text-gray-400">To:</span>
              <span className="truncate max-w-[200px]" title={errand.destination_address}>
                {errand.destination_address || 'Not specified'}
              </span>
            </div>
          </div>

          {errand.runner && (
            <div className="mt-2 text-[11px] text-amber-700 bg-amber-50 px-2 py-1 rounded inline-block">
              Currently assigned to: <strong>{errand.runner.first_name} {errand.runner.last_name}</strong>
            </div>
          )}
        </div>

        {/* Search & Filter Bar */}
        <div className="p-6 pb-2 space-y-3">
          <div className="relative">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search runner by name, phone, or service city..."
              className="w-full pl-10 pr-4 py-2 text-sm border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316]"
            />
          </div>

          <div className="flex gap-2 text-xs">
            <button
              type="button"
              onClick={() => setFilterType('all')}
              className={`px-3 py-1.5 rounded-lg font-medium transition ${
                filterType === 'all'
                  ? 'bg-[#0E0F13] text-white'
                  : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
              }`}
            >
              All Active ({runners.length})
            </button>
            <button
              type="button"
              onClick={() => setFilterType('online')}
              className={`px-3 py-1.5 rounded-lg font-medium transition flex items-center gap-1.5 ${
                filterType === 'online'
                  ? 'bg-green-600 text-white'
                  : 'bg-green-50 text-green-700 hover:bg-green-100'
              }`}
            >
              <span className="w-2 h-2 rounded-full bg-green-400 animate-pulse" />
              Online Only
            </button>
            <button
              type="button"
              onClick={() => setFilterType('verified')}
              className={`px-3 py-1.5 rounded-lg font-medium transition flex items-center gap-1.5 ${
                filterType === 'verified'
                  ? 'bg-blue-600 text-white'
                  : 'bg-blue-50 text-blue-700 hover:bg-blue-100'
              }`}
            >
              <ShieldCheck className="w-3.5 h-3.5" />
              Verified Only
            </button>
          </div>
        </div>

        {/* Runners List Body */}
        <div className="px-6 py-2 overflow-y-auto flex-1 min-h-[220px] max-h-[340px] space-y-2">
          {isLoadingRunners ? (
            <div className="flex flex-col items-center justify-center py-12 text-gray-400">
              <Loader2 className="w-8 h-8 animate-spin text-[#F97316] mb-2" />
              <p className="text-xs">Loading available runners...</p>
            </div>
          ) : filteredRunners.length === 0 ? (
            <div className="text-center py-12 text-gray-400 bg-gray-50/50 rounded-xl border border-dashed border-gray-200">
              <AlertCircle className="w-8 h-8 mx-auto text-gray-300 mb-2" />
              <p className="text-sm font-medium text-gray-600">No runners match your criteria</p>
              <p className="text-xs mt-1 text-gray-400">Try adjusting your search or filters.</p>
            </div>
          ) : (
            filteredRunners.map((runner: any) => {
              const profile = runner.runner_profile || runner.runnerProfile;
              const isSelected = selectedRunnerId === runner.id;
              const isCurrentRunner = errand.runner?.id === runner.id || errand.runner_id === runner.id;
              const isOnline = !!profile?.is_online;
              const isVerified =
                profile?.verification_status === 'approved' || profile?.is_verified === true;

              return (
                <div
                  key={runner.id}
                  onClick={() => setSelectedRunnerId(runner.id)}
                  className={`p-3.5 rounded-xl border transition cursor-pointer flex items-center justify-between gap-3 ${
                    isSelected
                      ? 'border-[#F97316] bg-orange-50/40 ring-1 ring-[#F97316]'
                      : 'border-gray-200 hover:border-gray-300 hover:bg-gray-50/50'
                  }`}
                >
                  <div className="flex items-center gap-3 min-w-0">
                    {/* Selection radio */}
                    <div
                      className={`w-4 h-4 rounded-full border flex items-center justify-center shrink-0 ${
                        isSelected
                          ? 'border-[#F97316] bg-[#F97316]'
                          : 'border-gray-300 bg-white'
                      }`}
                    >
                      {isSelected && <div className="w-1.5 h-1.5 bg-white rounded-full" />}
                    </div>

                    {/* Avatar with status indicator */}
                    <div className="relative shrink-0">
                      <div className="w-9 h-9 rounded-full bg-[#0E0F13] text-white flex items-center justify-center font-bold text-xs uppercase">
                        {runner.first_name?.[0] || 'R'}
                        {runner.last_name?.[0] || ''}
                      </div>
                      <span
                        title={isOnline ? 'Online' : 'Offline'}
                        className={`absolute -bottom-0.5 -right-0.5 w-3 h-3 rounded-full border-2 border-white ${
                          isOnline ? 'bg-green-500' : 'bg-gray-300'
                        }`}
                      />
                    </div>

                    {/* Runner info */}
                    <div className="min-w-0">
                      <div className="flex items-center gap-1.5">
                        <p className="font-semibold text-sm text-[#0E0F13] truncate">
                          {runner.first_name} {runner.last_name}
                        </p>
                        {isCurrentRunner && (
                          <span className="text-[10px] bg-gray-200 text-gray-700 px-1.5 py-0.2 rounded font-medium">
                            Current
                          </span>
                        )}
                        {isVerified && (
                          <span title="Verified Runner">
                            <ShieldCheck className="w-3.5 h-3.5 text-blue-500 shrink-0" />
                          </span>
                        )}
                      </div>
                      <p className="text-xs text-gray-500 truncate">{runner.phone || runner.email}</p>
                    </div>
                  </div>

                  {/* Attributes & badges */}
                  <div className="flex items-center gap-2 shrink-0">
                    {/* Transport */}
                    {profile?.transport_type && (
                      <span className="inline-flex items-center gap-1 text-[11px] bg-gray-100 text-gray-700 px-2 py-0.5 rounded capitalize">
                        {renderTransportIcon(profile.transport_type)}
                        {profile.transport_type}
                      </span>
                    )}

                    {/* Trust Score */}
                    {typeof profile?.trust_score === 'number' && (
                      <span className="text-[11px] font-semibold bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded">
                        {Math.round(profile.trust_score)}% Trust
                      </span>
                    )}

                    {/* Rating if available */}
                    {profile?.average_rating > 0 && (
                      <span className="text-[11px] text-amber-600 font-medium">
                        ★ {Number(profile.average_rating).toFixed(1)}
                      </span>
                    )}
                  </div>
                </div>
              );
            })
          )}
        </div>

        {/* Reason / Admin note */}
        <div className="px-6 pt-3 pb-2">
          <label className="block text-xs font-medium text-gray-700 mb-1">
            Dispatch Note / Reason (Optional)
          </label>
          <input
            type="text"
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="e.g. Assigned manually by admin, VIP order, nearest active runner..."
            className="w-full px-3 py-1.5 text-xs border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#F97316]"
          />
        </div>

        {/* Modal Footer */}
        <div className="px-6 py-4 border-t border-gray-100 flex items-center justify-between bg-gray-50/50">
          <div className="text-xs text-gray-500">
            {selectedRunner ? (
              <span>
                Selected: <strong>{selectedRunner.first_name} {selectedRunner.last_name}</strong>
              </span>
            ) : (
              <span>Select a runner to assign</span>
            )}
          </div>

          <div className="flex items-center gap-3">
            <button
              type="button"
              onClick={onClose}
              disabled={assignMutation.isPending}
              className="px-4 py-2 text-sm font-medium text-gray-600 hover:text-gray-900 transition"
            >
              Cancel
            </button>
            <button
              type="button"
              onClick={() => assignMutation.mutate()}
              disabled={!selectedRunnerId || assignMutation.isPending}
              className="px-5 py-2 text-sm font-medium bg-[#F97316] text-white rounded-xl hover:bg-[#ea580c] transition disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2 shadow-sm"
            >
              {assignMutation.isPending ? (
                <>
                  <Loader2 className="w-4 h-4 animate-spin" />
                  Assigning...
                </>
              ) : (
                <>
                  <UserCheck className="w-4 h-4" />
                  {isAlreadyAssigned ? 'Confirm Reassignment' : 'Assign Runner'}
                </>
              )}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}
