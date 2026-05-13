'use client';
import { useQuery } from '@tanstack/react-query';
import { walletApi } from '@/lib/api';
import { Plus, ArrowUpRight, ArrowDownLeft, Lock, Loader2 } from 'lucide-react';
import { useState } from 'react';
import toast from 'react-hot-toast';
import { formatDistanceToNow } from 'date-fns';

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

  const { data: wallet, isLoading } = useQuery({
    queryKey: ['wallet'],
    queryFn: () => walletApi.get().then((r) => r.data),
  });

  const { data: transactions } = useQuery({
    queryKey: ['wallet-transactions'],
    queryFn: () => walletApi.transactions().then((r) => r.data),
  });

  return (
    <div className="pb-20">
      {/* Balance header */}
      <div className="bg-gradient-to-br from-[#0A1628] to-[#FF6B00] px-6 py-8 text-white">
        <p className="text-orange-200 text-sm mb-1">Available Balance</p>
        {isLoading ? (
          <div className="h-10 bg-white/20 rounded-xl animate-pulse w-40" />
        ) : (
          <p className="text-4xl font-black">₦{(wallet?.balance ?? 0).toLocaleString()}</p>
        )}
        <div className="flex gap-4 mt-3 text-sm text-orange-200">
          <span className="flex items-center gap-1"><Lock className="w-3.5 h-3.5" /> ₦{(wallet?.escrow_balance ?? 0).toLocaleString()} in escrow</span>
        </div>

        <button
          onClick={() => setShowFund(true)}
          className="mt-4 bg-white text-[#FF6B00] font-bold px-6 py-2.5 rounded-xl hover:bg-orange-50 transition flex items-center gap-2"
        >
          <Plus className="w-4 h-4" />
          Fund Wallet
        </button>
      </div>

      {/* Summary cards */}
      <div className="grid grid-cols-3 gap-3 p-4">
        {[
          { label: 'Total Funded', value: wallet?.total_funded ?? 0, color: 'text-blue-600', bg: 'bg-blue-50' },
          { label: 'Total Spent', value: (wallet?.total_funded ?? 0) - (wallet?.balance ?? 0), color: 'text-[#FF6B00]', bg: 'bg-orange-50' },
          { label: 'In Escrow', value: wallet?.escrow_balance ?? 0, color: 'text-amber-600', bg: 'bg-amber-50' },
        ].map((s) => (
          <div key={s.label} className={`rounded-2xl p-3 ${s.bg}`}>
            <p className="text-xs text-gray-500 mb-1">{s.label}</p>
            <p className={`font-bold text-sm ${s.color}`}>₦{s.value.toLocaleString()}</p>
          </div>
        ))}
      </div>

      {/* Transactions */}
      <div className="px-4">
        <h3 className="font-bold text-[#0A1628] mb-3">Transaction History</h3>
        {!transactions ? (
          <div className="flex justify-center py-8"><Loader2 className="w-6 h-6 animate-spin text-[#FF6B00]" /></div>
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
                    <p className="font-medium text-[#0A1628] text-sm truncate">{TYPE_LABELS[tx.type] ?? tx.type}</p>
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
        <div className="fixed inset-0 bg-black/50 z-50 flex items-end">
          <div className="bg-white rounded-t-3xl w-full p-6">
            <h3 className="font-bold text-xl text-[#0A1628] mb-4">Fund Wallet</h3>
            <p className="text-gray-500 text-sm mb-4">Choose an amount to add to your wallet</p>

            <div className="grid grid-cols-3 gap-3 mb-4">
              {[1000, 2000, 5000, 10000, 20000, 50000].map((amount) => (
                <button
                  key={amount}
                  onClick={() => setFundAmount(amount)}
                  className={`py-3 rounded-xl font-semibold text-sm transition ${
                    fundAmount === amount ? 'bg-[#FF6B00] text-white' : 'bg-gray-100 text-gray-700 hover:bg-orange-50 hover:text-[#FF6B00]'
                  }`}
                >
                  ₦{amount.toLocaleString()}
                </button>
              ))}
            </div>

            <input
              type="number"
              value={fundAmount}
              onChange={(e) => setFundAmount(parseInt(e.target.value) || 0)}
              className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00] mb-4 text-lg font-bold"
              placeholder="Custom amount"
            />

            <div className="flex gap-3">
              <button onClick={() => setShowFund(false)} className="flex-1 border border-gray-200 text-gray-700 font-semibold py-3 rounded-xl hover:bg-gray-50 transition">
                Cancel
              </button>
              <button
                onClick={() => {
                  toast.success(`Redirecting to payment for ₦${fundAmount.toLocaleString()}...`);
                  setShowFund(false);
                }}
                className="flex-1 errandly-btn-primary"
              >
                Pay ₦{fundAmount.toLocaleString()}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
