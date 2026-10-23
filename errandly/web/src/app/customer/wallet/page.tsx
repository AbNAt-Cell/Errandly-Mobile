'use client';
import { useQuery } from '@tanstack/react-query';
import { walletApi, customerApi } from '@/lib/api';
import { Plus, ArrowUpRight, ArrowDownLeft, Lock, Loader2, X, CreditCard, Zap, ShieldCheck } from 'lucide-react';
import { useState, useEffect } from 'react';
import toast from 'react-hot-toast';
import { formatDistanceToNow } from 'date-fns';
import { PaymentGatewaySelector, PaymentGatewayId } from '@/components/payment/PaymentGatewaySelector';
import { openBachsCheckout } from '@/lib/bach';

const TYPE_LABELS: Record<string, string> = {
  funding: 'Wallet Funded',
  errand_payment: 'Errand Payment',
  earnings: 'Earnings',
  refund: 'Refund',
  withdrawal: 'Withdrawal',
  commission: 'Commission',
  bonus: 'Bonus',
};

export default function CustomerWalletPage() {
  const [showFund, setShowFund] = useState(false);
  const [fundAmount, setFundAmount] = useState(5000);
  const [selectedGateway, setSelectedGateway] = useState<PaymentGatewayId>('paystack');
  const [verifyRef, setVerifyRef] = useState('');
  const [showVerify, setShowVerify] = useState(false);
  const [funding, setFunding] = useState(false);

  const { data: wallet, isLoading, refetch: refetchWallet } = useQuery({
    queryKey: ['wallet'],
    queryFn: () => walletApi.get().then((r) => r.data),
  });

  const { data: transactions, refetch: refetchTransactions } = useQuery({
    queryKey: ['wallet-transactions'],
    queryFn: () => walletApi.transactions().then((r) => r.data),
  });

  useEffect(() => {
    if (typeof window !== 'undefined') {
      const params = new URLSearchParams(window.location.search);
      const isSuccess = params.get('payment') === 'success';
      const reference = params.get('reference') || params.get('trxref') || params.get('checkout_id');
      const gateway = (params.get('gateway') || (reference?.includes('BACH') ? 'bach' : 'paystack')) as PaymentGatewayId;

      if (isSuccess || reference) {
        if (reference && !isSuccess) {
          customerApi.verifyPayment({ reference, gateway })
            .catch(() => {})
            .finally(() => {
              refetchWallet();
              refetchTransactions();
            });
        }
        toast.success(`Payment verified via ${gateway === 'bach' ? 'Bachs' : 'Paystack'}! Wallet funded.`);
        refetchWallet();
        refetchTransactions();
        window.history.replaceState({}, '', window.location.pathname);
      }
    }
  }, [refetchWallet, refetchTransactions]);

  return (
    <div className="pb-20 max-w-4xl mx-auto">
      {/* Balance header */}
      <div className="bg-gradient-to-br from-[#0E0F13] to-[#F97316] px-6 py-8 text-white rounded-b-3xl sm:rounded-3xl sm:mt-4 shadow-lg">
        <p className="text-orange-200 text-sm mb-1">Available Balance</p>
        {isLoading ? (
          <div className="h-10 bg-white/20 rounded-xl animate-pulse w-40" />
        ) : (
          <p className="text-4xl font-black">₦{(wallet?.balance ?? 0).toLocaleString()}</p>
        )}
        <div className="flex gap-4 mt-3 text-sm text-orange-200">
          <span className="flex items-center gap-1"><Lock className="w-3.5 h-3.5" /> ₦{(wallet?.escrow_balance ?? 0).toLocaleString()} in escrow</span>
        </div>

        <div className="flex flex-wrap items-center gap-3 mt-5">
          <button
            onClick={() => setShowFund(true)}
            className="bg-white text-[#F97316] font-bold px-6 py-2.5 rounded-xl hover:bg-orange-50 transition flex items-center gap-2 shadow-sm"
          >
            <Plus className="w-4 h-4" />
            Fund Wallet
          </button>
          <span className="text-xs text-orange-100/90 bg-black/20 px-3 py-1.5 rounded-lg border border-white/10 flex items-center gap-1.5">
            <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" />
            Supports Paystack & Bachs Pay
          </span>
        </div>
      </div>

      {/* Summary cards */}
      <div className="grid grid-cols-3 gap-3 p-4">
        {[
          { label: 'Total Funded', value: wallet?.total_funded ?? 0, color: 'text-blue-600', bg: 'bg-blue-50' },
          { label: 'Total Spent', value: (wallet?.total_funded ?? 0) - (wallet?.balance ?? 0), color: 'text-[#F97316]', bg: 'bg-orange-50' },
          { label: 'In Escrow', value: wallet?.escrow_balance ?? 0, color: 'text-amber-600', bg: 'bg-amber-50' },
        ].map((s) => (
          <div key={s.label} className={`rounded-2xl p-3.5 ${s.bg} border border-black/5`}>
            <p className="text-xs text-gray-500 mb-1 font-medium">{s.label}</p>
            <p className={`font-bold text-sm sm:text-base ${s.color}`}>₦{s.value.toLocaleString()}</p>
          </div>
        ))}
      </div>

      {/* Payment Processors Info Strip */}
      <div className="mx-4 mb-4 p-4 rounded-2xl bg-white border border-gray-100 shadow-sm flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h4 className="text-sm font-bold text-[#0E0F13] flex items-center gap-2">
            Payment Processors
            <span className="text-[10px] bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded-full">Active</span>
          </h4>
          <p className="text-xs text-gray-500 mt-0.5">Fund your wallet or checkout with cards, USSD, or instant bank transfer.</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => {
              setSelectedGateway('paystack');
              setShowFund(true);
            }}
            className="px-3.5 py-1.5 rounded-xl bg-orange-50 hover:bg-orange-100 border border-orange-200 text-[#F97316] text-xs font-bold flex items-center gap-1.5 transition"
          >
            <CreditCard className="w-3.5 h-3.5" /> Paystack
          </button>
          <button
            type="button"
            onClick={() => {
              setSelectedGateway('bach');
              setShowFund(true);
            }}
            className="px-3.5 py-1.5 rounded-xl bg-blue-50 hover:bg-blue-100 border border-blue-200 text-blue-600 text-xs font-bold flex items-center gap-1.5 transition"
          >
            <Zap className="w-3.5 h-3.5" /> Bachs Pay
          </button>
        </div>
      </div>

      {/* Transactions */}
      <div className="px-4">
        <h3 className="font-bold text-[#0E0F13] mb-3">Transaction History</h3>
        {!transactions ? (
          <div className="flex justify-center py-8"><Loader2 className="w-6 h-6 animate-spin text-[#F97316]" /></div>
        ) : transactions.data?.length === 0 ? (
          <p className="text-center text-gray-500 py-8">No transactions yet</p>
        ) : (
          <div className="space-y-2">
            {transactions.data?.map((tx: any) => {
              const isCredit = tx.direction === 'credit';
              return (
                <div key={tx.id} className="bg-white rounded-2xl border border-gray-100 p-4 flex items-center gap-3">
                  <div className={`w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0 ${isCredit ? 'bg-green-100' : 'bg-red-100'}`}>
                    {isCredit ? <ArrowDownLeft className="w-5 h-5 text-green-600" /> : <ArrowUpRight className="w-5 h-5 text-red-600" />}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-[#0E0F13] text-sm truncate">{TYPE_LABELS[tx.type] ?? tx.type}</p>
                    <p className="text-xs text-gray-500 mt-0.5 truncate">{tx.description}</p>
                    <p className="text-xs text-gray-400">{formatDistanceToNow(new Date(tx.created_at), { addSuffix: true })}</p>
                  </div>
                  <div className="text-right flex-shrink-0">
                    <p className={`font-bold ${isCredit ? 'text-green-600' : 'text-red-600'}`}>
                      {isCredit ? '+' : '-'}₦{tx.amount?.toLocaleString()}
                    </p>
                    <p className="text-xs text-gray-400">Bal: ₦{tx.balance_after?.toLocaleString()}</p>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Fund modal */}
      {showFund && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4 sm:p-6 overflow-y-auto">
          <div className="bg-white rounded-3xl w-full max-w-lg p-6 sm:p-8 shadow-2xl relative my-auto">
            <div className="flex items-center justify-between mb-2">
              <h3 className="font-bold text-xl text-[#0E0F13]">Fund Wallet</h3>
              <button
                onClick={() => setShowFund(false)}
                className="w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 flex items-center justify-center text-gray-600 transition"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
            <p className="text-gray-500 text-sm mb-5">Select your preferred payment processor and enter an amount.</p>

            {/* Payment Processor Selector (Paystack vs Bachs) */}
            <div className="mb-5">
              <PaymentGatewaySelector
                selectedGateway={selectedGateway}
                onChange={setSelectedGateway}
                amount={fundAmount}
              />
            </div>

            <label className="text-xs font-bold uppercase tracking-wider text-gray-500 block mb-2">
              Select or Enter Amount
            </label>
            <div className="grid grid-cols-3 gap-2.5 mb-3">
              {[1000, 2000, 5000, 10000, 20000, 50000].map((amount) => (
                <button
                  key={amount}
                  type="button"
                  onClick={() => setFundAmount(amount)}
                  className={`py-2.5 rounded-xl font-bold text-xs sm:text-sm transition ${
                    fundAmount === amount
                      ? selectedGateway === 'bach'
                        ? 'bg-blue-600 text-white shadow-sm'
                        : 'bg-[#F97316] text-white shadow-sm'
                      : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                  }`}
                >
                  ₦{amount.toLocaleString()}
                </button>
              ))}
            </div>

            <div className="relative mb-6">
              <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 font-bold text-base">₦</span>
              <input
                type="number"
                value={fundAmount || ''}
                onChange={(e) => setFundAmount(parseInt(e.target.value) || 0)}
                className="w-full pl-8 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316] text-lg font-bold"
                placeholder="Or enter custom amount"
              />
            </div>

            <div className="flex gap-3">
              <button
                type="button"
                onClick={() => setShowFund(false)}
                className="flex-1 border border-gray-200 text-gray-700 font-semibold py-3.5 rounded-xl hover:bg-gray-50 transition text-sm"
              >
                Cancel
              </button>
              <button
                disabled={funding || fundAmount < 100}
                onClick={async () => {
                  setFunding(true);
                  try {
                    const res = await customerApi.initPayment({ amount: fundAmount, gateway: selectedGateway });
                    const data = res.data?.data ?? res.data;
                    const url = data.authorization_url ?? data.checkout_url ?? data.payment_url;
                    const reference = data.reference;

                    if (selectedGateway === 'bach' && url) {
                      setShowFund(false);
                      setVerifyRef(reference || data.checkout_id || '');
                      openBachsCheckout({
                        checkoutUrl: url,
                        checkoutId: data.checkout_id,
                        onSuccess: () => {
                          toast.success('Bachs payment confirmed! Updating wallet...');
                          refetchWallet();
                          refetchTransactions();
                        },
                        onClose: () => {
                          refetchWallet();
                          refetchTransactions();
                        },
                      });
                    } else if (url) {
                      window.open(url, '_blank');
                      setVerifyRef(reference || '');
                      setShowFund(false);
                      setShowVerify(true);
                      toast.success(`Complete payment via ${selectedGateway === 'bach' ? 'Bachs' : 'Paystack'} in the new tab, then verify below.`);
                    } else if (reference) {
                      setVerifyRef(reference);
                      setShowFund(false);
                      setShowVerify(true);
                      toast('Enter payment reference to credit wallet after paying.');
                    } else {
                      toast.error('Could not start payment. Check payment gateway configuration.');
                    }
                  } catch (e: unknown) {
                    const msg = (e as { response?: { data?: { message?: string } } })?.response?.data?.message;
                    toast.error(msg || 'Payment initialization failed');
                  } finally {
                    setFunding(false);
                  }
                }}
                className={`flex-[1.5] font-bold py-3.5 rounded-xl text-white transition disabled:opacity-50 text-sm flex items-center justify-center gap-2 shadow-md ${
                  selectedGateway === 'bach'
                    ? 'bg-blue-600 hover:bg-blue-700'
                    : 'bg-[#F97316] hover:bg-orange-600'
                }`}
              >
                {funding ? (
                  <>
                    <Loader2 className="w-4 h-4 animate-spin" />
                    Starting…
                  </>
                ) : (
                  <>
                    {selectedGateway === 'bach' ? <Zap className="w-4 h-4" /> : <CreditCard className="w-4 h-4" />}
                    Proceed with {selectedGateway === 'bach' ? 'Bachs' : 'Paystack'} (₦{fundAmount.toLocaleString()})
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}

      {showVerify && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4 sm:p-6 overflow-y-auto">
          <div className="bg-white rounded-3xl w-full max-w-md p-6 sm:p-8 shadow-2xl relative my-auto">
            <div className="flex items-center justify-between mb-2">
              <h3 className="font-bold text-xl text-[#0E0F13]">Verify Payment</h3>
              <button
                onClick={() => setShowVerify(false)}
                className="w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 flex items-center justify-center text-gray-600 transition"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
            <p className="text-sm text-gray-500 mb-4">Paste your payment reference to credit your wallet.</p>
            
            <div className="mb-4">
              <PaymentGatewaySelector
                selectedGateway={selectedGateway}
                onChange={setSelectedGateway}
                compact
              />
            </div>

            <input
              value={verifyRef}
              onChange={(e) => setVerifyRef(e.target.value)}
              className="w-full border border-gray-200 rounded-xl px-4 py-3 mb-5 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-[#F97316]"
              placeholder="Payment reference (e.g. FUND_...)"
            />
            <div className="flex gap-3">
              <button onClick={() => setShowVerify(false)} className="flex-1 border border-gray-200 py-3 rounded-xl font-medium text-sm hover:bg-gray-50 transition">
                Close
              </button>
              <button
                onClick={async () => {
                  try {
                    await customerApi.verifyPayment({ reference: verifyRef, gateway: selectedGateway });
                    toast.success('Wallet funded successfully!');
                    setShowVerify(false);
                    refetchWallet();
                    refetchTransactions();
                  } catch (e: unknown) {
                    const msg = (e as { response?: { data?: { message?: string } } })?.response?.data?.message;
                    toast.error(msg || 'Verification failed');
                  }
                }}
                className="flex-1 errand-btn-primary py-3 rounded-xl text-sm font-bold"
              >
                Verify & Credit
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
