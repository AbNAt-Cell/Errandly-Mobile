'use client';

import { useParams } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import { useState } from 'react';
import Link from 'next/link';
import { adminApi } from '@/lib/api';
import {
  ArrowLeft,
  Loader2,
  MapPin,
  UserCheck,
  UserPlus,
  RefreshCw,
  Clock,
  Phone,
  Mail,
  ShieldCheck,
  AlertCircle,
  FileText,
  DollarSign,
} from 'lucide-react';
import AssignRunnerModal from '@/components/admin/AssignRunnerModal';

const STATUS_COLORS: Record<string, string> = {
  pending_assignment: 'bg-yellow-100 text-yellow-800 border border-yellow-200',
  posted: 'bg-yellow-100 text-yellow-800 border border-yellow-200',
  accepted: 'bg-amber-100 text-amber-700',
  runner_en_route: 'bg-purple-100 text-purple-700',
  in_progress: 'bg-indigo-100 text-indigo-700',
  awaiting_confirmation: 'bg-orange-100 text-orange-700',
  completed: 'bg-green-100 text-green-700',
  cancelled: 'bg-gray-100 text-gray-700',
  disputed: 'bg-red-100 text-red-700',
  refunded: 'bg-teal-100 text-teal-700',
};

export default function AdminErrandDetailPage() {
  const params = useParams();
  const publicId = params.publicId as string;
  const [isAssignModalOpen, setIsAssignModalOpen] = useState(false);

  const {
    data: errand,
    isLoading,
    error,
    refetch,
  } = useQuery({
    queryKey: ['admin-errand', publicId],
    queryFn: () => adminApi.getErrand(publicId).then((r) => r.data),
    enabled: !!publicId,
  });

  if (isLoading) {
    return (
      <div className="p-6 flex flex-col items-center justify-center py-24 text-gray-400">
        <Loader2 className="w-8 h-8 animate-spin text-[#F97316] mb-2" />
        <p className="text-sm">Loading errand details...</p>
      </div>
    );
  }

  if (error || !errand) {
    return (
      <div className="p-6 max-w-4xl mx-auto">
        <Link href="/admin/errands" className="text-[#F97316] text-sm font-medium hover:underline inline-flex items-center gap-1.5 mb-6">
          <ArrowLeft className="w-4 h-4" /> Back to errands
        </Link>
        <div className="bg-red-50 border border-red-200 rounded-2xl p-6 text-center text-red-700">
          <AlertCircle className="w-8 h-8 mx-auto mb-2 text-red-500" />
          <h2 className="font-bold text-lg">Errand Not Found</h2>
          <p className="text-sm text-red-600 mt-1">The requested errand does not exist or has been removed.</p>
        </div>
      </div>
    );
  }

  const isAssigned = !!errand.runner || !!errand.runner_id;
  const runnerProfile = errand.runner?.runner_profile || errand.runner?.runnerProfile;

  return (
    <div className="p-6 max-w-5xl mx-auto space-y-6">
      {/* Top Navigation & Actions Bar */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <Link
          href="/admin/errands"
          className="inline-flex items-center gap-2 text-sm font-medium text-gray-600 hover:text-[#0E0F13] transition"
        >
          <ArrowLeft className="w-4 h-4" />
          Back to Errands
        </Link>

        <div className="flex items-center gap-3">
          <button
            onClick={() => setIsAssignModalOpen(true)}
            className="inline-flex items-center gap-2 px-4 py-2 text-sm font-semibold bg-[#F97316] text-white rounded-xl hover:bg-[#ea580c] transition shadow-sm"
          >
            {isAssigned ? (
              <>
                <RefreshCw className="w-4 h-4" />
                Reassign Runner
              </>
            ) : (
              <>
                <UserPlus className="w-4 h-4" />
                Assign Runner
              </>
            )}
          </button>
        </div>
      </div>

      {/* Header Info */}
      <div className="bg-white rounded-2xl border border-gray-100 p-6 shadow-sm flex flex-wrap items-start justify-between gap-4">
        <div>
          <div className="flex items-center gap-3 flex-wrap">
            <h1 className="text-2xl font-bold text-[#0E0F13]">{errand.title}</h1>
            <span
              className={`text-xs px-3 py-1 rounded-full font-medium ${
                STATUS_COLORS[errand.status] || 'bg-gray-100 text-gray-700'
              }`}
            >
              {errand.status?.replace(/_/g, ' ')}
            </span>
            <span className="text-xs px-2.5 py-0.5 rounded-full font-medium bg-gray-100 text-gray-700 capitalize">
              {errand.urgency || 'standard'} priority
            </span>
          </div>
          <p className="text-gray-400 text-xs font-mono mt-1">UUID: {errand.public_id}</p>
        </div>

        <div className="text-right">
          <p className="text-xs text-gray-400 uppercase font-semibold">Total Budget</p>
          <p className="text-2xl font-bold text-[#F97316]">
            ₦{Number(errand.budget || 0).toLocaleString()}
          </p>
          {errand.runner_earnings && (
            <p className="text-xs text-gray-500">
              Runner payout: ₦{Number(errand.runner_earnings).toLocaleString()}
            </p>
          )}
        </div>
      </div>

      {/* Main Grid: Details + Runner Info */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column: Errand Details (2 Cols) */}
        <div className="lg:col-span-2 space-y-6">
          {/* Description & Locations */}
          <div className="bg-white rounded-2xl border border-gray-100 p-6 space-y-5 shadow-sm">
            <div>
              <h2 className="text-sm font-bold text-gray-900 mb-2">Description</h2>
              <p className="text-gray-700 text-sm leading-relaxed whitespace-pre-wrap">
                {errand.description || 'No description provided.'}
              </p>
            </div>

            {errand.special_instructions && (
              <div className="p-3.5 bg-yellow-50 border border-yellow-200/80 rounded-xl text-xs text-yellow-900">
                <p className="font-semibold mb-1">Special Instructions:</p>
                <p>{errand.special_instructions}</p>
              </div>
            )}

            <hr className="border-gray-100" />

            {/* Route / Addresses */}
            <div className="space-y-4">
              <h2 className="text-sm font-bold text-gray-900">Locations</h2>
              <div className="flex items-start gap-3 text-sm">
                <MapPin className="w-5 h-5 text-[#F97316] shrink-0 mt-0.5" />
                <div>
                  <p className="text-xs font-semibold text-gray-500">Pickup Location</p>
                  <p className="font-medium text-gray-900">{errand.pickup_address || 'Not specified'}</p>
                  {errand.pickup_city && <p className="text-xs text-gray-400">{errand.pickup_city}</p>}
                </div>
              </div>

              <div className="flex items-start gap-3 text-sm">
                <MapPin className="w-5 h-5 text-green-600 shrink-0 mt-0.5" />
                <div>
                  <p className="text-xs font-semibold text-gray-500">Destination Location</p>
                  <p className="font-medium text-gray-900">{errand.destination_address || 'Not specified'}</p>
                  {errand.destination_city && (
                    <p className="text-xs text-gray-400">{errand.destination_city}</p>
                  )}
                  {errand.recipient_name && (
                    <p className="text-xs text-gray-600 mt-1">
                      Recipient: <strong>{errand.recipient_name}</strong> {errand.recipient_phone && `(${errand.recipient_phone})`}
                    </p>
                  )}
                </div>
              </div>
            </div>
          </div>

          {/* Status History / Timeline */}
          <div className="bg-white rounded-2xl border border-gray-100 p-6 shadow-sm">
            <h2 className="text-sm font-bold text-gray-900 mb-4 flex items-center gap-2">
              <Clock className="w-4 h-4 text-gray-500" />
              Status & Assignment History
            </h2>

            {errand.status_history?.length > 0 || errand.statusHistory?.length > 0 ? (
              <div className="space-y-3 relative pl-4 border-l-2 border-gray-200">
                {(errand.status_history || errand.statusHistory || []).map((history: any, idx: number) => (
                  <div key={idx} className="relative text-xs">
                    <span className="absolute -left-[21px] top-1 w-2.5 h-2.5 rounded-full bg-[#F97316]" />
                    <div className="flex items-center gap-2">
                      <span className="font-semibold text-gray-800 capitalize">
                        {history.to_status?.replace(/_/g, ' ')}
                      </span>
                      <span className="text-gray-400">
                        {new Date(history.created_at).toLocaleString()}
                      </span>
                    </div>
                    {history.reason && (
                      <p className="text-gray-600 mt-0.5">Reason: {history.reason}</p>
                    )}
                    {history.changed_by && (
                      <p className="text-gray-400 text-[11px]">
                        Changed by: {history.changed_by.first_name} {history.changed_by.last_name}
                      </p>
                    )}
                  </div>
                ))}
              </div>
            ) : (
              <p className="text-xs text-gray-400">No status transitions recorded yet.</p>
            )}
          </div>
        </div>

        {/* Right Column: Customer & Runner Cards (1 Col) */}
        <div className="space-y-6">
          {/* Runner Card */}
          <div className="bg-white rounded-2xl border border-gray-100 p-6 shadow-sm">
            <div className="flex items-center justify-between mb-4">
              <h2 className="text-sm font-bold text-gray-900 flex items-center gap-2">
                <UserCheck className="w-4 h-4 text-[#F97316]" />
                Assigned Runner
              </h2>
              {isAssigned && (
                <button
                  onClick={() => setIsAssignModalOpen(true)}
                  className="text-xs font-semibold text-[#F97316] hover:underline"
                >
                  Change
                </button>
              )}
            </div>

            {isAssigned && errand.runner ? (
              <div className="space-y-4 text-sm">
                <div className="flex items-center gap-3">
                  <div className="w-12 h-12 rounded-full bg-[#0E0F13] text-white flex items-center justify-center font-bold text-sm">
                    {errand.runner.first_name?.[0]}
                    {errand.runner.last_name?.[0]}
                  </div>
                  <div>
                    <p className="font-bold text-[#0E0F13]">
                      {errand.runner.first_name} {errand.runner.last_name}
                    </p>
                    {runnerProfile?.transport_type && (
                      <p className="text-xs text-gray-500 capitalize">
                        Transport: {runnerProfile.transport_type}
                      </p>
                    )}
                  </div>
                </div>

                <div className="space-y-2 pt-2 border-t border-gray-100 text-xs">
                  {errand.runner.phone && (
                    <div className="flex items-center gap-2 text-gray-600">
                      <Phone className="w-3.5 h-3.5 text-gray-400" />
                      <span>{errand.runner.phone}</span>
                    </div>
                  )}
                  {errand.runner.email && (
                    <div className="flex items-center gap-2 text-gray-600">
                      <Mail className="w-3.5 h-3.5 text-gray-400" />
                      <span className="truncate">{errand.runner.email}</span>
                    </div>
                  )}
                  {runnerProfile?.trust_score !== undefined && (
                    <div className="flex items-center gap-2 text-gray-600">
                      <ShieldCheck className="w-3.5 h-3.5 text-emerald-500" />
                      <span>Trust Score: {Math.round(runnerProfile.trust_score)}%</span>
                    </div>
                  )}
                </div>

                <button
                  onClick={() => setIsAssignModalOpen(true)}
                  className="w-full mt-2 py-2 text-xs font-semibold bg-gray-50 hover:bg-gray-100 text-gray-700 rounded-xl transition flex items-center justify-center gap-1.5 border border-gray-200"
                >
                  <RefreshCw className="w-3.5 h-3.5" />
                  Reassign to Different Runner
                </button>
              </div>
            ) : (
              <div className="text-center py-6 px-4 rounded-xl border border-dashed border-orange-200 bg-orange-50/40">
                <AlertCircle className="w-8 h-8 text-[#F97316] mx-auto mb-2" />
                <p className="text-sm font-bold text-gray-900">No Runner Assigned</p>
                <p className="text-xs text-gray-500 mt-1 mb-4">
                  This errand is currently pending runner dispatch.
                </p>
                <button
                  onClick={() => setIsAssignModalOpen(true)}
                  className="w-full py-2.5 px-4 text-xs font-semibold bg-[#F97316] text-white rounded-xl hover:bg-[#ea580c] transition shadow-sm flex items-center justify-center gap-1.5"
                >
                  <UserPlus className="w-4 h-4" />
                  Assign Runner Now
                </button>
              </div>
            )}
          </div>

          {/* Customer Card */}
          <div className="bg-white rounded-2xl border border-gray-100 p-6 shadow-sm">
            <h2 className="text-sm font-bold text-gray-900 mb-4">Customer Details</h2>
            {errand.customer ? (
              <div className="space-y-3 text-sm">
                <p className="font-bold text-[#0E0F13]">
                  {errand.customer.first_name} {errand.customer.last_name}
                </p>
                {errand.customer.phone && (
                  <div className="flex items-center gap-2 text-xs text-gray-600">
                    <Phone className="w-3.5 h-3.5 text-gray-400" />
                    <span>{errand.customer.phone}</span>
                  </div>
                )}
                {errand.customer.email && (
                  <div className="flex items-center gap-2 text-xs text-gray-600">
                    <Mail className="w-3.5 h-3.5 text-gray-400" />
                    <span className="truncate">{errand.customer.email}</span>
                  </div>
                )}
              </div>
            ) : (
              <p className="text-xs text-gray-400">Customer details unavailable.</p>
            )}
          </div>
        </div>
      </div>

      {/* Assign Runner Modal */}
      {isAssignModalOpen && (
        <AssignRunnerModal
          errand={errand}
          isOpen={isAssignModalOpen}
          onClose={() => setIsAssignModalOpen(false)}
          onAssigned={() => refetch()}
        />
      )}
    </div>
  );
}
