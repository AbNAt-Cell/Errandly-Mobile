'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { customerApi } from '@/lib/api';
import Link from 'next/link';
import { ArrowLeft, Loader2, MapPin, Package, AlertTriangle, ShieldAlert } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import toast from 'react-hot-toast';
import { subscribeErrandChannel } from '@/lib/pusher';
import RatingModal from '@/components/shared/RatingModal';
import DisputeForm from '@/components/shared/DisputeForm';

const STATUS_LABELS: Record<string, string> = {
  pending_assignment: 'Finding Runner',
  accepted: 'Runner Assigned',
  runner_en_route: 'En Route',
  item_picked: 'Item Picked Up',
  in_progress: 'In Progress',
  awaiting_confirmation: 'Awaiting Confirmation',
  completed: 'Completed',
  cancelled: 'Cancelled',
  disputed: 'Disputed',
};

function Card({ children }: { children: React.ReactNode }) {
  return <div className="bg-white rounded-2xl border border-gray-100 p-4 mb-3">{children}</div>;
}

export default function CustomerErrandDetailPage() {
  const params = useParams();
  const router = useRouter();
  const queryClient = useQueryClient();
  const publicId = params.publicId as string;
  const [otp, setOtp] = useState('');
  const [cancelReason, setCancelReason] = useState('');
  const [showCancel, setShowCancel] = useState(false);
  const [showRating, setShowRating] = useState(false);
  const [showDispute, setShowDispute] = useState(false);

  const { data: errand, isLoading, error, refetch } = useQuery({
    queryKey: ['customer-errand', publicId],
    queryFn: () => customerApi.getErrand(publicId).then((r) => r.data?.data ?? r.data),
    enabled: !!publicId,
    refetchInterval: 15000,
  });

  const { data: tracking } = useQuery({
    queryKey: ['customer-tracking', publicId],
    queryFn: () => customerApi.trackErrand(publicId).then((r) => r.data?.data ?? r.data),
    enabled: !!publicId && !!errand?.runner_id,
    refetchInterval: 10000,
  });

  useEffect(() => {
    if (!errand?.id) return;
    const unsub = subscribeErrandChannel(errand.id, () => {
      refetch();
      queryClient.invalidateQueries({ queryKey: ['customer-tracking', publicId] });
    });
    return () => unsub?.();
  }, [errand?.id, publicId, queryClient, refetch]);

  useEffect(() => {
    if (errand?.status === 'completed') setShowRating(true);
  }, [errand?.status]);

  const confirmMutation = useMutation({
    mutationFn: () => customerApi.confirmCompletion(publicId, otp),
    onSuccess: () => {
      toast.success('Errand completed! Payment released to runner.');
      queryClient.invalidateQueries({ queryKey: ['customer-errand', publicId] });
      setOtp('');
      setShowRating(true);
    },
    onError: (e: { response?: { data?: { message?: string } } }) =>
      toast.error(e.response?.data?.message || 'Invalid OTP'),
  });

  const cancelMutation = useMutation({
    mutationFn: () => customerApi.cancelErrand(publicId, cancelReason),
    onSuccess: () => {
      toast.success('Errand cancelled.');
      router.push('/customer/errands');
    },
    onError: (e: { response?: { data?: { message?: string } } }) =>
      toast.error(e.response?.data?.message || 'Could not cancel errand'),
  });

  const panicMutation = useMutation({
    mutationFn: () => customerApi.panic(publicId, {}),
    onSuccess: () => {
      toast.success('Panic alert sent. Escrow frozen; admin notified.');
      refetch();
    },
    onError: (e: { response?: { data?: { message?: string } } }) =>
      toast.error(e.response?.data?.message || 'Could not send alert'),
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
      <div className="flex flex-col items-center py-24">
        <p className="text-gray-500">Errand not found.</p>
        <Link href="/customer/errands" className="text-[#FF6B00] mt-4 text-sm hover:underline">
          Back to errands
        </Link>
      </div>
    );
  }

  const activeStatuses = ['accepted', 'runner_en_route', 'item_picked', 'in_progress', 'awaiting_confirmation'];
  const canConfirm = errand.status === 'awaiting_confirmation';
  const canCancel = ['posted', 'pending_assignment', 'accepted', 'runner_en_route'].includes(errand.status);
  const canPanic = activeStatuses.includes(errand.status);
  const canDispute = ['completed', 'awaiting_confirmation', 'in_progress', 'disputed'].includes(errand.status);
  const runnerPos = tracking?.runner ?? tracking?.latest;

  return (
    <div className="p-4 pb-24 max-w-lg mx-auto">
      {showRating && <RatingModal publicId={publicId} onClose={() => setShowRating(false)} />}
      {showDispute && <DisputeForm publicId={publicId} onClose={() => setShowDispute(false)} onSubmitted={() => refetch()} />}

      <div className="flex items-center gap-3 mb-6">
        <Link href="/customer/errands" className="p-2 rounded-lg hover:bg-gray-100 transition">
          <ArrowLeft className="w-5 h-5 text-[#0A1628]" />
        </Link>
        <div className="flex-1 min-w-0">
          <h1 className="font-bold text-[#0A1628] truncate">{errand.title}</h1>
          <p className="text-sm text-gray-500">{STATUS_LABELS[errand.status] || errand.status}</p>
        </div>
      </div>

      <Card>
        <div className="flex items-start gap-3">
          <Package className="w-5 h-5 text-[#FF6B00] flex-shrink-0 mt-0.5" />
          <div>
            <p className="text-sm text-gray-500">Budget</p>
            <p className="font-bold text-[#FF6B00] text-lg">₦{errand.budget?.toLocaleString()}</p>
          </div>
        </div>
        <p className="text-xs text-gray-400 mt-3">
          Posted {formatDistanceToNow(new Date(errand.created_at), { addSuffix: true })}
        </p>
      </Card>

      {runnerPos?.latitude != null && (
        <Card>
          <p className="text-xs font-medium text-gray-500 uppercase mb-2">Live runner location</p>
          <p className="text-sm text-[#0A1628]">
            {Number(runnerPos.latitude).toFixed(5)}, {Number(runnerPos.longitude).toFixed(5)}
          </p>
          {runnerPos.logged_at && (
            <p className="text-xs text-gray-400 mt-1">
              Updated {formatDistanceToNow(new Date(runnerPos.logged_at), { addSuffix: true })}
            </p>
          )}
        </Card>
      )}

      <Card>
        <p className="text-xs font-medium text-gray-500 uppercase mb-2">Pickup</p>
        <p className="text-sm text-[#0A1628] flex gap-2">
          <MapPin className="w-4 h-4 text-[#FF6B00] flex-shrink-0" />
          {errand.pickup_address}
        </p>
        <p className="text-xs font-medium text-gray-500 uppercase mt-4 mb-2">Destination</p>
        <p className="text-sm text-[#0A1628] flex gap-2">
          <MapPin className="w-4 h-4 text-gray-400 flex-shrink-0" />
          {errand.destination_address}
        </p>
      </Card>

      {errand.runner && (
        <Card>
          <p className="text-xs font-medium text-gray-500 uppercase mb-2">Runner</p>
          <p className="font-medium text-[#0A1628]">
            {errand.runner.first_name} {errand.runner.last_name}
          </p>
          {errand.runner.phone && <p className="text-sm text-gray-500 mt-1">{errand.runner.phone}</p>}
          <Link href={`/customer/messages/${publicId}`} className="text-[#FF6B00] text-sm font-medium mt-2 inline-block">
            Open chat →
          </Link>
        </Card>
      )}

      {canConfirm && (
        <Card>
          <p className="font-medium text-[#0A1628] mb-2">Confirm delivery</p>
          <p className="text-sm text-gray-500 mb-3">Enter the 6-digit OTP sent to your phone.</p>
          <input
            type="text"
            inputMode="numeric"
            maxLength={6}
            value={otp}
            onChange={(e) => setOtp(e.target.value.replace(/\D/g, ''))}
            className="w-full border border-gray-200 rounded-xl px-4 py-3 text-center tracking-widest text-lg mb-3"
            placeholder="000000"
          />
          <button
            type="button"
            onClick={() => confirmMutation.mutate()}
            disabled={otp.length !== 6 || confirmMutation.isPending}
            className="errandly-btn-primary w-full disabled:opacity-50"
          >
            {confirmMutation.isPending ? 'Confirming…' : 'Confirm & release payment'}
          </button>
        </Card>
      )}

      {canPanic && (
        <Card>
          <button
            type="button"
            onClick={() => {
              if (window.confirm('Send emergency panic alert? This freezes escrow and alerts admins.')) {
                panicMutation.mutate();
              }
            }}
            disabled={panicMutation.isPending}
            className="w-full py-3 rounded-xl bg-red-600 text-white font-bold flex items-center justify-center gap-2 disabled:opacity-50"
          >
            <ShieldAlert className="w-5 h-5" />
            {panicMutation.isPending ? 'Sending…' : 'Panic button'}
          </button>
        </Card>
      )}

      {canDispute && (
        <Card>
          <button
            type="button"
            onClick={() => setShowDispute(true)}
            className="text-amber-700 text-sm font-medium flex items-center gap-2"
          >
            <AlertTriangle className="w-4 h-4" />
            Raise a dispute
          </button>
        </Card>
      )}

      {errand.status === 'completed' && (
        <Card>
          <button type="button" onClick={() => setShowRating(true)} className="text-[#FF6B00] text-sm font-medium">
            Rate runner
          </button>
        </Card>
      )}

      {canCancel && (
        <Card>
          {!showCancel ? (
            <button
              type="button"
              onClick={() => setShowCancel(true)}
              className="text-red-600 text-sm font-medium flex items-center gap-2"
            >
              <AlertTriangle className="w-4 h-4" />
              Cancel errand
            </button>
          ) : (
            <>
              <textarea
                value={cancelReason}
                onChange={(e) => setCancelReason(e.target.value)}
                placeholder="Reason for cancellation"
                className="w-full border border-gray-200 rounded-xl px-4 py-3 text-sm mb-3 min-h-[80px]"
              />
              <button
                type="button"
                onClick={() => cancelMutation.mutate()}
                disabled={!cancelReason.trim() || cancelMutation.isPending}
                className="w-full py-3 rounded-xl border border-red-200 text-red-600 font-medium disabled:opacity-50"
              >
                {cancelMutation.isPending ? 'Cancelling…' : 'Confirm cancellation'}
              </button>
            </>
          )}
        </Card>
      )}
    </div>
  );
}
