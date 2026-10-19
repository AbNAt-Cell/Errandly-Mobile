'use client';

import { useEffect, useState } from 'react';
import { useParams, useRouter, useSearchParams } from 'next/navigation';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { customerApi, walletApi } from '@/lib/api';
import Link from 'next/link';
import { ArrowLeft, Loader2, MapPin, Package, AlertTriangle, ShieldAlert, CreditCard, Wallet, ShieldCheck } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import toast from 'react-hot-toast';
import { subscribeErrandChannel } from '@/lib/pusher';
import RatingModal from '@/components/shared/RatingModal';
import DisputeForm from '@/components/shared/DisputeForm';

const STATUS_LABELS: Record<string, string> = {
  posted: 'Payment Pending',
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
  const searchParams = useSearchParams();
  const queryClient = useQueryClient();
  const publicId = params.publicId as string;
  const paymentQuery = searchParams.get('payment');
  const referenceQuery = searchParams.get('reference');

  const [otp, setOtp] = useState('');
  const [cancelReason, setCancelReason] = useState('');
  const [showCancel, setShowCancel] = useState(false);
  const [showRating, setShowRating] = useState(false);
  const [showDispute, setShowDispute] = useState(false);
  const [payingNow, setPayingNow] = useState(false);
  const [payingWithWallet, setPayingWithWallet] = useState(false);
  const [selectedPaymentMethod, setSelectedPaymentMethod] = useState<'wallet' | 'paystack'>('wallet');

  const { data: walletData, refetch: refetchWallet } = useQuery({
    queryKey: ['customer-wallet'],
    queryFn: () => walletApi.get().then((r) => r.data?.data ?? r.data),
  });
  const walletBalance = typeof walletData?.balance === 'number' ? walletData.balance : null;

  useEffect(() => {
    if (paymentQuery === 'success' && publicId) {
      customerApi.verifyErrandPayment(publicId, referenceQuery || undefined)
        .then(() => {
          toast.success('Payment confirmed! Your errand is now active.');
          queryClient.invalidateQueries({ queryKey: ['customer-errand', publicId] });
        })
        .catch(() => {
          queryClient.invalidateQueries({ queryKey: ['customer-errand', publicId] });
        })
        .finally(() => {
          if (typeof window !== 'undefined') {
            window.history.replaceState({}, '', window.location.pathname);
          }
        });
    }
  }, [paymentQuery, referenceQuery, publicId, queryClient]);

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
        <Loader2 className="w-8 h-8 animate-spin text-[#F97316]" />
      </div>
    );
  }

  if (error || !errand) {
    return (
      <div className="flex flex-col items-center py-24">
        <p className="text-gray-500">Errand not found.</p>
        <Link href="/customer/errands" className="text-[#F97316] mt-4 text-sm hover:underline">
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
          <ArrowLeft className="w-5 h-5 text-[#0E0F13]" />
        </Link>
        <div className="flex-1 min-w-0">
          <h1 className="font-bold text-[#0E0F13] truncate">{errand.title}</h1>
          <p className="text-sm text-gray-500">{STATUS_LABELS[errand.status] || errand.status}</p>
        </div>
      </div>

      {(errand.payment_status === 'pending' || errand.status === 'posted') && (() => {
        const totalAmount = (errand.budget || 0) + (errand.platform_fee || 0);
        const hasWalletBalance = walletBalance !== null && walletBalance >= totalAmount;

        const handleWalletPayment = async () => {
          setPayingWithWallet(true);
          try {
            await customerApi.initializeErrandPayment(publicId, { payment_method: 'wallet' });
            toast.success('Errand funded from wallet! Finding a runner for you...');
            refetch();
            refetchWallet();
          } catch (e: any) {
            toast.error(e.response?.data?.message || 'Could not pay from wallet');
          } finally {
            setPayingWithWallet(false);
          }
        };

        const handlePaystackPayment = async () => {
          setPayingNow(true);
          try {
            const origin = typeof window !== 'undefined' ? window.location.origin : undefined;
            const { data } = await customerApi.initializeErrandPayment(publicId, {
              payment_method: 'paystack',
              frontend_url: origin,
            });
            if (data.payment?.authorization_url) {
              toast.success('Opening Paystack checkout...');
              window.location.href = data.payment.authorization_url;
            }
          } catch (e: any) {
            toast.error(e.response?.data?.message || 'Could not start payment');
            setPayingNow(false);
          }
        };

        return (
          <div className="bg-gradient-to-br from-orange-50 via-white to-amber-50 border-2 border-orange-200 rounded-2xl p-5 mb-5 shadow-sm space-y-4">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="p-2 bg-orange-100 text-[#F97316] rounded-xl">
                  <CreditCard className="w-5 h-5" />
                </div>
                <div>
                  <h4 className="font-bold text-sm text-[#0E0F13]">Payment Required</h4>
                  <p className="text-xs text-gray-500">Fund escrow to dispatch this errand to runners</p>
                </div>
              </div>
              <span className="text-xs bg-emerald-50 text-emerald-700 font-semibold px-2.5 py-1 rounded-full flex items-center gap-1 border border-emerald-200">
                <ShieldCheck className="w-3.5 h-3.5" />
                Escrow Protected
              </span>
            </div>

            <div className="bg-white/80 rounded-xl p-3 border border-gray-100 flex items-center justify-between text-sm">
              <span className="text-gray-600">Total Due (Runner + Platform Fee)</span>
              <span className="text-lg font-bold text-[#F97316]">₦{totalAmount.toLocaleString()}</span>
            </div>

            <div className="space-y-2.5">
              {/* Wallet Option */}
              <div
                onClick={() => {
                  if (!hasWalletBalance) {
                    toast.error(`Insufficient wallet balance. Top up or select Paystack.`);
                    return;
                  }
                  setSelectedPaymentMethod('wallet');
                }}
                className={`p-3.5 rounded-xl border-2 transition flex items-start gap-3 ${
                  !hasWalletBalance
                    ? 'border-gray-200 bg-gray-50/70 opacity-80 cursor-not-allowed'
                    : selectedPaymentMethod === 'wallet'
                    ? 'border-[#F97316] bg-orange-50/60 ring-2 ring-[#F97316]/20 cursor-pointer'
                    : 'border-gray-200 hover:border-gray-300 cursor-pointer bg-white'
                }`}
              >
                <div className="p-2 bg-gray-100 text-gray-700 rounded-lg shrink-0 mt-0.5">
                  <Wallet className="w-4 h-4" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <span className="font-semibold text-xs text-[#0E0F13] dark:text-white">Pay from Errand Wallet</span>
                    <span className="text-xs font-semibold text-gray-700 dark:text-gray-300">
                      {walletBalance !== null ? `₦${walletBalance.toLocaleString()}` : 'Checking...'}
                    </span>
                  </div>
                  {walletBalance !== null && !hasWalletBalance ? (
                    <p className="text-[11px] text-red-500 mt-0.5">
                      Short by ₦{(totalAmount - walletBalance).toLocaleString()}. Use Paystack or{' '}
                      <Link href="/customer/wallet" className="underline font-semibold">
                        fund wallet
                      </Link>
                      .
                    </p>
                  ) : (
                    <p className="text-[11px] text-gray-500 mt-0.5">
                      Instant escrow funding — no external checkout needed
                    </p>
                  )}
                </div>
                <div className="w-4 h-4 rounded-full border-2 border-gray-300 flex items-center justify-center shrink-0 mt-1">
                  {selectedPaymentMethod === 'wallet' && hasWalletBalance && (
                    <div className="w-2 h-2 rounded-full bg-[#F97316]" />
                  )}
                </div>
              </div>

              {/* Paystack Option */}
              <div
                onClick={() => setSelectedPaymentMethod('paystack')}
                className={`p-3.5 rounded-xl border-2 cursor-pointer transition flex items-start gap-3 ${
                  selectedPaymentMethod === 'paystack'
                    ? 'border-[#F97316] bg-orange-50/60 ring-2 ring-[#F97316]/20'
                    : 'border-gray-200 hover:border-gray-300 bg-white'
                }`}
              >
                <div className="p-2 bg-orange-100 text-[#F97316] rounded-lg shrink-0 mt-0.5">
                  <CreditCard className="w-4 h-4" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between">
                    <span className="font-semibold text-xs text-[#0E0F13]">Pay via Paystack</span>
                    <span className="text-[10px] bg-orange-500 text-white font-bold px-1.5 py-0.5 rounded uppercase">
                      Card / Transfer / USSD
                    </span>
                  </div>
                  <p className="text-[11px] text-gray-500 mt-0.5">
                    Pay securely using card, bank transfer, or USSD code
                  </p>
                </div>
                <div className="w-4 h-4 rounded-full border-2 border-[#F97316] flex items-center justify-center shrink-0 mt-1">
                  {selectedPaymentMethod === 'paystack' && <div className="w-2 h-2 rounded-full bg-[#F97316]" />}
                </div>
              </div>
            </div>

            <div className="pt-1">
              {selectedPaymentMethod === 'wallet' && hasWalletBalance ? (
                <button
                  type="button"
                  disabled={payingWithWallet}
                  onClick={handleWalletPayment}
                  className="w-full py-2.5 bg-[#F97316] text-white rounded-xl text-xs font-semibold hover:bg-orange-600 transition flex items-center justify-center gap-1.5 disabled:opacity-70"
                >
                  {payingWithWallet && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                  Pay ₦{totalAmount.toLocaleString()} from Wallet
                </button>
              ) : (
                <button
                  type="button"
                  disabled={payingNow}
                  onClick={handlePaystackPayment}
                  className="w-full py-2.5 bg-[#F97316] text-white rounded-xl text-xs font-semibold hover:bg-orange-600 transition flex items-center justify-center gap-1.5 disabled:opacity-70"
                >
                  {payingNow && <Loader2 className="w-3.5 h-3.5 animate-spin" />}
                  Proceed to Paystack Checkout (₦{totalAmount.toLocaleString()})
                </button>
              )}
            </div>
          </div>
        );
      })()}

      <Card>
        <div className="flex items-start gap-3">
          <Package className="w-5 h-5 text-[#F97316] flex-shrink-0 mt-0.5" />
          <div>
            <p className="text-sm text-gray-500">Budget</p>
            <p className="font-bold text-[#F97316] text-lg">₦{errand.budget?.toLocaleString()}</p>
          </div>
        </div>
        <p className="text-xs text-gray-400 mt-3">
          Posted {formatDistanceToNow(new Date(errand.created_at), { addSuffix: true })}
        </p>
      </Card>

      {runnerPos?.latitude != null && (
        <Card>
          <p className="text-xs font-medium text-gray-500 uppercase mb-2">Live runner location</p>
          <p className="text-sm text-[#0E0F13]">
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
        <p className="text-sm text-[#0E0F13] flex gap-2">
          <MapPin className="w-4 h-4 text-[#F97316] flex-shrink-0" />
          {errand.pickup_address}
        </p>
        <p className="text-xs font-medium text-gray-500 uppercase mt-4 mb-2">Destination</p>
        <p className="text-sm text-[#0E0F13] flex gap-2">
          <MapPin className="w-4 h-4 text-gray-400 flex-shrink-0" />
          {errand.destination_address}
        </p>
      </Card>

      {errand.runner && (
        <Card>
          <p className="text-xs font-medium text-gray-500 uppercase mb-2">Runner</p>
          <p className="font-medium text-[#0E0F13]">
            {errand.runner.first_name} {errand.runner.last_name}
          </p>
          {errand.runner.phone && <p className="text-sm text-gray-500 mt-1">{errand.runner.phone}</p>}
          <Link href={`/customer/messages/${publicId}`} className="text-[#F97316] text-sm font-medium mt-2 inline-block">
            Open chat →
          </Link>
        </Card>
      )}

      {canConfirm && (
        <Card>
          <p className="font-medium text-[#0E0F13] mb-2">Confirm delivery</p>
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
            className="errand-btn-primary w-full disabled:opacity-50"
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
          <button type="button" onClick={() => setShowRating(true)} className="text-[#F97316] text-sm font-medium">
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
