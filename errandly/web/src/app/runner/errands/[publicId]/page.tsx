'use client';

import { useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { runnerApi } from '@/lib/api';
import Link from 'next/link';
import { ArrowLeft, Loader2, MapPin, MessageSquare, ShieldAlert } from 'lucide-react';
import toast from 'react-hot-toast';

function Card({ children }: { children: React.ReactNode }) {
  return <div className="bg-white rounded-2xl border border-gray-100 p-4 mb-3">{children}</div>;
}

export default function RunnerErrandDetailPage() {
  const params = useParams();
  const router = useRouter();
  const queryClient = useQueryClient();
  const publicId = params.publicId as string;
  const [pickupOtp, setPickupOtp] = useState('');
  const [proofUrl, setProofUrl] = useState('');
  const [proofNotes, setProofNotes] = useState('');
  const [cancelReason, setCancelReason] = useState('');
  const [showCancel, setShowCancel] = useState(false);

  const { data: errand, isLoading, error } = useQuery({
    queryKey: ['runner-errand', publicId],
    queryFn: () => runnerApi.getErrand(publicId).then((r) => r.data),
    enabled: !!publicId,
    refetchInterval: 15000,
  });

  const invalidate = () => {
    queryClient.invalidateQueries({ queryKey: ['runner-errand', publicId] });
    queryClient.invalidateQueries({ queryKey: ['runner-dashboard'] });
  };

  const arrivedMutation = useMutation({
    mutationFn: () => runnerApi.markArrived(publicId),
    onSuccess: () => {
      toast.success('Arrival confirmed. Pickup OTP sent to customer.');
      invalidate();
    },
    onError: (e: { response?: { data?: { message?: string } } }) =>
      toast.error(e.response?.data?.message || 'Failed'),
  });

  const otpMutation = useMutation({
    mutationFn: () => runnerApi.verifyPickupOtp(publicId, pickupOtp),
    onSuccess: () => {
      toast.success('Pickup verified.');
      setPickupOtp('');
      invalidate();
    },
    onError: (e: { response?: { data?: { message?: string } } }) =>
      toast.error(e.response?.data?.message || 'Invalid OTP'),
  });

  const startMutation = useMutation({
    mutationFn: () => runnerApi.startErrand(publicId),
    onSuccess: () => {
      toast.success('Errand started.');
      invalidate();
    },
    onError: (e: { response?: { data?: { message?: string } } }) =>
      toast.error(e.response?.data?.message || 'Failed'),
  });

  const panicMutation = useMutation({
    mutationFn: () => runnerApi.panic(publicId, {}),
    onSuccess: () => {
      toast.success('Panic alert sent.');
      invalidate();
    },
    onError: (e: { response?: { data?: { message?: string } } }) =>
      toast.error(e.response?.data?.message || 'Failed'),
  });

  const cancelMutation = useMutation({
    mutationFn: () => runnerApi.cancelErrand(publicId, cancelReason),
    onSuccess: () => {
      toast.success('Errand cancelled. Searching for another runner.');
      router.push('/runner/dashboard');
    },
    onError: (e: { response?: { data?: { message?: string } } }) =>
      toast.error(e.response?.data?.message || 'Failed'),
  });

  const proofMutation = useMutation({
    mutationFn: () =>
      runnerApi.submitProof(publicId, {
        type: 'photo',
        file_url: proofUrl,
        notes: proofNotes || undefined,
      }),
    onSuccess: () => {
      toast.success('Proof submitted. Waiting for customer confirmation.');
      invalidate();
    },
    onError: (e: { response?: { data?: { message?: string } } }) =>
      toast.error(e.response?.data?.message || 'Failed'),
  });

  if (isLoading) {
    return (
      <div className="flex justify-center py-24">
        <Loader2 className="w-8 h-8 animate-spin text-[#FF6B00]" />
      </div>
    );
  }

  if (error || !errand) {
    return (
      <div className="flex flex-col items-center py-24 p-4">
        <p className="text-gray-500">Errand not found.</p>
        <button type="button" onClick={() => router.push('/runner/dashboard')} className="text-[#FF6B00] mt-4 text-sm">
          Back to dashboard
        </button>
      </div>
    );
  }

  const status = errand.status;

  return (
    <div className="p-4 pb-24 max-w-lg mx-auto">
      <div className="flex items-center gap-3 mb-6">
        <Link href="/runner/dashboard" className="p-2 rounded-lg hover:bg-gray-100">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <div className="flex-1 min-w-0">
          <h1 className="font-bold text-[#0A1628] truncate">{errand.title}</h1>
          <p className="text-sm text-gray-500 capitalize">{status?.replace(/_/g, ' ')}</p>
        </div>
        <Link href={`/runner/messages/${publicId}`} className="p-2 text-[#FF6B00]">
          <MessageSquare className="w-5 h-5" />
        </Link>
      </div>

      <Card>
        <p className="text-2xl font-bold text-[#FF6B00]">₦{errand.runner_earnings?.toLocaleString()}</p>
        <p className="text-xs text-gray-500 mt-1">Your earnings</p>
      </Card>

      <Card>
        <p className="text-xs font-medium text-gray-500 uppercase mb-2">Customer</p>
        <p className="font-medium">
          {errand.customer?.first_name} {errand.customer?.last_name}
        </p>
        {errand.customer?.phone && <p className="text-sm text-gray-500 mt-1">{errand.customer.phone}</p>}
      </Card>

      <Card>
        <p className="text-xs font-medium text-gray-500 uppercase mb-2">Pickup</p>
        <p className="text-sm flex gap-2">
          <MapPin className="w-4 h-4 text-[#FF6B00] shrink-0" />
          {errand.pickup_address}
        </p>
        <p className="text-xs font-medium text-gray-500 uppercase mt-4 mb-2">Destination</p>
        <p className="text-sm flex gap-2">
          <MapPin className="w-4 h-4 text-gray-400 shrink-0" />
          {errand.destination_address}
        </p>
      </Card>

      {status === 'accepted' && (
        <Card>
          <button
            type="button"
            onClick={() => arrivedMutation.mutate()}
            disabled={arrivedMutation.isPending}
            className="w-full errandly-btn-primary"
          >
            {arrivedMutation.isPending ? 'Updating…' : "I've arrived at pickup"}
          </button>
        </Card>
      )}

      {status === 'runner_en_route' && (
        <Card>
          <p className="text-sm text-gray-600 mb-3">Enter pickup OTP from customer</p>
          <input
            type="text"
            inputMode="numeric"
            maxLength={6}
            value={pickupOtp}
            onChange={(e) => setPickupOtp(e.target.value.replace(/\D/g, ''))}
            className="w-full border border-gray-200 rounded-xl px-4 py-3 text-center tracking-widest mb-3"
            placeholder="000000"
          />
          <button
            type="button"
            onClick={() => otpMutation.mutate()}
            disabled={pickupOtp.length !== 6 || otpMutation.isPending}
            className="w-full errandly-btn-primary disabled:opacity-50"
          >
            Verify pickup
          </button>
        </Card>
      )}

      {status === 'item_picked' && (
        <Card>
          <button
            type="button"
            onClick={() => startMutation.mutate()}
            disabled={startMutation.isPending}
            className="w-full errandly-btn-primary"
          >
            Start errand
          </button>
        </Card>
      )}

      {status === 'in_progress' && (
        <Card>
          <p className="text-sm font-medium text-[#0A1628] mb-3">Submit delivery proof</p>
          <input
            value={proofUrl}
            onChange={(e) => setProofUrl(e.target.value)}
            placeholder="Photo URL (https://...)"
            className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm mb-3"
          />
          <textarea
            value={proofNotes}
            onChange={(e) => setProofNotes(e.target.value)}
            placeholder="Notes (optional)"
            rows={2}
            className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm mb-3 resize-none"
          />
          <button
            type="button"
            onClick={() => proofMutation.mutate()}
            disabled={!proofUrl.trim() || proofMutation.isPending}
            className="w-full errandly-btn-primary disabled:opacity-50"
          >
            Submit proof
          </button>
        </Card>
      )}

      {status === 'awaiting_confirmation' && (
        <Card>
          <p className="text-sm text-gray-600 text-center">
            Waiting for customer to confirm delivery with their OTP.
          </p>
        </Card>
      )}

      {['accepted', 'runner_en_route', 'item_picked', 'in_progress', 'awaiting_confirmation'].includes(status) && (
        <Card>
          <button
            type="button"
            onClick={() => {
              if (window.confirm('Send panic alert?')) panicMutation.mutate();
            }}
            disabled={panicMutation.isPending}
            className="w-full py-3 rounded-xl bg-red-600 text-white font-bold flex items-center justify-center gap-2 disabled:opacity-50"
          >
            <ShieldAlert className="w-5 h-5" />
            Panic button
          </button>
        </Card>
      )}

      {['accepted', 'runner_en_route', 'item_picked'].includes(status) && (
        <Card>
          {!showCancel ? (
            <button type="button" onClick={() => setShowCancel(true)} className="text-red-600 text-sm font-medium">
              Cancel errand (trust penalty applies)
            </button>
          ) : (
            <>
              <textarea
                value={cancelReason}
                onChange={(e) => setCancelReason(e.target.value)}
                placeholder="Reason"
                className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm mb-3 min-h-[72px]"
              />
              <button
                type="button"
                onClick={() => cancelMutation.mutate()}
                disabled={!cancelReason.trim() || cancelMutation.isPending}
                className="w-full py-3 rounded-xl border border-red-200 text-red-600 font-medium disabled:opacity-50"
              >
                Confirm cancel
              </button>
            </>
          )}
        </Card>
      )}
    </div>
  );
}
