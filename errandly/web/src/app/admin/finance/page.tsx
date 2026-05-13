'use client';
import { useQuery } from '@tanstack/react-query';
import { adminApi } from '@/lib/api';
import { DollarSign, Lock, TrendingUp, Clock, Loader2 } from 'lucide-react';

export default function AdminFinancePage() {
  const { data: overview, isLoading } = useQuery({
    queryKey: ['admin-finance'],
    queryFn: () => adminApi.finance().then((r) => r.data),
  });

  const { data: escrow } = useQuery({
    queryKey: ['admin-escrow'],
    queryFn: () => adminApi.escrow().then((r) => r.data),
  });

  const cards = [
    { label: 'Platform Revenue', value: `₦${(overview?.platform_revenue ?? 0).toLocaleString()}`, icon: TrendingUp, color: 'bg-green-500' },
    { label: 'In Escrow', value: `₦${(overview?.escrow_total ?? 0).toLocaleString()}`, icon: Lock, color: 'bg-amber-500' },
    { label: 'Frozen Funds', value: `₦${(overview?.frozen_total ?? 0).toLocaleString()}`, icon: Lock, color: 'bg-red-500' },
    { label: 'Released to Runners', value: `₦${(overview?.total_released_to_runners ?? 0).toLocaleString()}`, icon: DollarSign, color: 'bg-blue-500' },
    { label: 'Pending Withdrawals', value: `₦${(overview?.pending_withdrawals ?? 0).toLocaleString()}`, icon: Clock, color: 'bg-purple-500' },
  ];

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-[#0A1628]">Finance Overview</h1>
        <p className="text-gray-500 text-sm">Platform revenue, escrow, and withdrawal management</p>
      </div>

      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-5 gap-4">
        {cards.map((card) => (
          <div key={card.label} className="bg-white rounded-2xl p-5 shadow-sm border border-gray-100">
            <div className={`w-10 h-10 ${card.color} rounded-xl flex items-center justify-center mb-3`}>
              <card.icon className="w-5 h-5 text-white" />
            </div>
            {isLoading ? <div className="h-8 bg-gray-100 rounded animate-pulse mb-1" /> : <p className="text-xl font-bold text-[#0A1628]">{card.value}</p>}
            <p className="text-xs text-gray-500 mt-1">{card.label}</p>
          </div>
        ))}
      </div>

      {/* Escrow table */}
      <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-100">
          <h3 className="font-bold text-[#0A1628]">Recent Escrow Transactions</h3>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-100">
              <tr>
                {['Errand', 'Customer', 'Runner', 'Total', 'Runner Amt', 'Platform Fee', 'Status'].map((h) => (
                  <th key={h} className="text-left px-6 py-3 font-semibold text-gray-600">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {escrow?.data?.slice(0, 15).map((tx: any) => (
                <tr key={tx.id} className="hover:bg-gray-50 transition">
                  <td className="px-6 py-3 text-[#0A1628] font-medium">{tx.errand?.title?.substring(0, 30)}...</td>
                  <td className="px-6 py-3 text-gray-600">{tx.customer?.first_name}</td>
                  <td className="px-6 py-3 text-gray-600">{tx.runner?.first_name ?? '—'}</td>
                  <td className="px-6 py-3 font-semibold">₦{tx.total_amount?.toLocaleString()}</td>
                  <td className="px-6 py-3 text-green-600 font-medium">₦{tx.runner_amount?.toLocaleString()}</td>
                  <td className="px-6 py-3 text-[#FF6B00] font-medium">₦{tx.platform_fee?.toLocaleString()}</td>
                  <td className="px-6 py-3">
                    <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${
                      tx.status === 'released' ? 'bg-green-100 text-green-700' :
                      tx.status === 'in_escrow' ? 'bg-amber-100 text-amber-700' :
                      tx.status === 'frozen' ? 'bg-red-100 text-red-700' : 'bg-gray-100 text-gray-700'
                    }`}>
                      {tx.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
