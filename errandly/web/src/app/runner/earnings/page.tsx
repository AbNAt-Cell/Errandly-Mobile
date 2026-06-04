'use client';
import { useQuery, useMutation } from '@tanstack/react-query';
import { runnerApi, walletApi } from '@/lib/api';
import { useState } from 'react';
import { TrendingUp, DollarSign, ArrowUpRight, Loader2, Wallet, Building2 } from 'lucide-react';
import toast from 'react-hot-toast';
import { formatDistanceToNow } from 'date-fns';

export default function RunnerEarningsPage() {
  const [showWithdraw, setShowWithdraw] = useState(false);
  const [amount, setAmount] = useState(5000);
  const [bankName, setBankName] = useState('');
  const [accountNumber, setAccountNumber] = useState('');
  const [accountName, setAccountName] = useState('');

  const { data: earnings, isLoading } = useQuery({
    queryKey: ['runner-earnings'],
    queryFn: () => runnerApi.earnings().then((r) => r.data),
  });

  const { data: transactions } = useQuery({
    queryKey: ['wallet-transactions'],
    queryFn: () => walletApi.transactions().then((r) => r.data),
  });

  const withdrawMutation = useMutation({
    mutationFn: (amt: number) => runnerApi.withdraw(amt),
    onSuccess: () => {
      toast.success('Withdrawal requested. Processing within 24 hours.');
      setShowWithdraw(false);
    },
    onError: (e: any) => toast.error(e.response?.data?.message || 'Failed'),
  });

  const bankMutation = useMutation({
    mutationFn: () =>
      runnerApi.updateBankAccount({
        bank_name: bankName,
        account_number: accountNumber,
        account_name: accountName,
      }),
    onSuccess: () => toast.success('Bank account saved'),
    onError: (e: any) => toast.error(e.response?.data?.message || 'Failed to save bank details'),
  });

  const summaryCards = [
    { label: 'Today', value: earnings?.today ?? 0, icon: TrendingUp, color: 'text-green-600 bg-green-100' },
    { label: 'This Week', value: earnings?.this_week ?? 0, icon: TrendingUp, color: 'text-blue-600 bg-blue-100' },
    { label: 'This Month', value: earnings?.this_month ?? 0, icon: DollarSign, color: 'text-purple-600 bg-purple-100' },
    { label: 'All Time', value: earnings?.total ?? 0, icon: Wallet, color: 'text-[#FF6B00] bg-orange-100' },
  ];

  return (
    <div className="p-4 pb-20 space-y-5">
      {/* Balance card */}
      <div className="bg-gradient-to-br from-[#0A1628] to-[#FF6B00] rounded-2xl p-6 text-white">
        <p className="text-orange-200 text-sm">Available Balance</p>
        {isLoading ? <div className="h-10 bg-white/20 rounded-xl animate-pulse w-40 mt-1" /> : (
          <p className="text-4xl font-black mt-1">₦{(earnings?.wallet_balance ?? 0).toLocaleString()}</p>
        )}
        <p className="text-orange-200 text-sm mt-1">₦{(earnings?.pending_withdrawal ?? 0).toLocaleString()} pending withdrawal</p>
        <button
          onClick={() => setShowWithdraw(true)}
          className="mt-4 bg-white text-[#FF6B00] font-bold px-6 py-2.5 rounded-xl hover:bg-orange-50 transition flex items-center gap-2"
        >
          <ArrowUpRight className="w-4 h-4" />
          Withdraw to Bank
        </button>
      </div>

      <div className="bg-white rounded-2xl border border-gray-100 p-5 space-y-3">
        <div className="flex items-center gap-2">
          <Building2 className="w-5 h-5 text-[#FF6B00]" />
          <h3 className="font-bold text-[#0A1628]">Payout bank account</h3>
        </div>
        <p className="text-xs text-gray-500">Required before withdrawals are processed.</p>
        <input
          value={bankName}
          onChange={(e) => setBankName(e.target.value)}
          placeholder="Bank name"
          className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00]"
        />
        <input
          value={accountNumber}
          onChange={(e) => setAccountNumber(e.target.value)}
          placeholder="Account number"
          className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00]"
        />
        <input
          value={accountName}
          onChange={(e) => setAccountName(e.target.value)}
          placeholder="Account name"
          className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00]"
        />
        <button
          onClick={() => bankMutation.mutate()}
          disabled={bankMutation.isPending || !bankName || !accountNumber || !accountName}
          className="w-full errandly-btn-primary flex items-center justify-center gap-2 disabled:opacity-70"
        >
          {bankMutation.isPending && <Loader2 className="w-4 h-4 animate-spin" />}
          Save bank account
        </button>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-2 gap-3">
        {summaryCards.map((card) => (
          <div key={card.label} className="bg-white rounded-2xl border border-gray-100 p-4 flex items-center gap-3">
            <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${card.color}`}>
              <card.icon className="w-5 h-5" />
            </div>
            <div>
              <p className="text-xs text-gray-500">{card.label}</p>
              <p className="font-bold text-[#0A1628] text-base">₦{(card.value as number).toLocaleString()}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Transactions */}
      <div>
        <h3 className="font-bold text-[#0A1628] mb-3">Recent Transactions</h3>
        <div className="space-y-2">
          {transactions?.data?.slice(0, 20).map((tx: any) => {
            const isCredit = tx.direction === 'credit';
            return (
              <div key={tx.id} className="bg-white rounded-xl border border-gray-100 p-4 flex items-center gap-3">
                <div className={`w-9 h-9 rounded-full flex items-center justify-center ${isCredit ? 'bg-green-100' : 'bg-red-100'}`}>
                  {isCredit ? <TrendingUp className="w-4 h-4 text-green-600" /> : <ArrowUpRight className="w-4 h-4 text-red-600" />}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-[#0A1628] truncate">{tx.description}</p>
                  <p className="text-xs text-gray-400">{formatDistanceToNow(new Date(tx.created_at), { addSuffix: true })}</p>
                </div>
                <p className={`font-bold text-sm ${isCredit ? 'text-green-600' : 'text-red-600'}`}>
                  {isCredit ? '+' : '-'}₦{tx.amount?.toLocaleString()}
                </p>
              </div>
            );
          })}
        </div>
      </div>

      {/* Withdraw modal */}
      {showWithdraw && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-end">
          <div className="bg-white rounded-t-3xl w-full p-6">
            <h3 className="font-bold text-xl text-[#0A1628] mb-2">Withdraw Earnings</h3>
            <p className="text-gray-500 text-sm mb-4">Funds processed within 24 hours to your bank account.</p>

            <div className="grid grid-cols-3 gap-3 mb-4">
              {[2000, 5000, 10000, 20000, 30000, 50000].map((a) => (
                <button key={a} onClick={() => setAmount(a)} className={`py-3 rounded-xl font-semibold text-sm transition ${amount === a ? 'bg-[#FF6B00] text-white' : 'bg-gray-100 text-gray-700'}`}>
                  ₦{a.toLocaleString()}
                </button>
              ))}
            </div>

            <input type="number" value={amount} onChange={(e) => setAmount(parseInt(e.target.value) || 0)} className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00] mb-4 text-lg font-bold" placeholder="Custom amount" />

            <div className="flex gap-3">
              <button onClick={() => setShowWithdraw(false)} className="flex-1 border border-gray-200 text-gray-700 font-semibold py-3 rounded-xl">Cancel</button>
              <button
                onClick={() => withdrawMutation.mutate(amount)}
                disabled={withdrawMutation.isPending || amount < 1000}
                className="flex-1 errandly-btn-primary flex items-center justify-center gap-2 disabled:opacity-70"
              >
                {withdrawMutation.isPending && <Loader2 className="w-4 h-4 animate-spin" />}
                Withdraw ₦{amount.toLocaleString()}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
