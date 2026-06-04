'use client';
import { useQuery } from '@tanstack/react-query';
import { adminApi } from '@/lib/api';
import { useState } from 'react';
import { Search, Loader2, Eye } from 'lucide-react';
import Link from 'next/link';

const STATUS_COLORS: Record<string, string> = {
  pending_assignment: 'bg-yellow-100 text-yellow-700',
  accepted: 'bg-amber-100 text-amber-700',
  runner_en_route: 'bg-purple-100 text-purple-700',
  in_progress: 'bg-indigo-100 text-indigo-700',
  awaiting_confirmation: 'bg-orange-100 text-orange-700',
  completed: 'bg-green-100 text-green-700',
  cancelled: 'bg-gray-100 text-gray-700',
  disputed: 'bg-red-100 text-red-700',
  refunded: 'bg-teal-100 text-teal-700',
};

export default function AdminErrandsPage() {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  const { data, isLoading } = useQuery({
    queryKey: ['admin-errands', search, statusFilter],
    queryFn: () => adminApi.errands({ search: search || undefined, status: statusFilter || undefined }).then((r) => r.data),
    staleTime: 10000,
  });

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-[#0A1628]">Errand Management</h1>
        <p className="text-gray-500 text-sm">Monitor and manage all errands on the platform</p>
      </div>

      <div className="flex flex-wrap gap-3 mb-6">
        <div className="relative flex-1 min-w-64">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search errands..."
            className="w-full pl-9 pr-4 py-2.5 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00] text-sm"
          />
        </div>
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none bg-white">
          <option value="">All Status</option>
          {Object.keys(STATUS_COLORS).map((s) => (
            <option key={s} value={s}>{s.replace(/_/g, ' ')}</option>
          ))}
        </select>
      </div>

      <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-100">
              <tr>
                {['ID', 'Title', 'Customer', 'Runner', 'Status', 'Budget', 'Created', 'Actions'].map((h) => (
                  <th key={h} className="text-left px-6 py-4 font-semibold text-gray-600">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {isLoading ? (
                <tr><td colSpan={8} className="text-center py-10"><Loader2 className="w-6 h-6 animate-spin text-[#FF6B00] mx-auto" /></td></tr>
              ) : data?.data?.map((errand: any) => (
                <tr key={errand.id} className="hover:bg-gray-50 transition">
                  <td className="px-6 py-4 font-mono text-xs text-gray-500 truncate max-w-[120px]" title={errand.public_id}>{errand.public_id?.slice(0, 8)}…</td>
                  <td className="px-6 py-4">
                    <p className="font-medium text-[#0A1628] max-w-xs truncate">{errand.title}</p>
                    <p className="text-xs text-gray-500">{errand.category?.replace(/_/g, ' ')}</p>
                  </td>
                  <td className="px-6 py-4 text-gray-700">{errand.customer?.first_name} {errand.customer?.last_name}</td>
                  <td className="px-6 py-4 text-gray-700">{errand.runner ? `${errand.runner.first_name} ${errand.runner.last_name}` : '—'}</td>
                  <td className="px-6 py-4">
                    <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${STATUS_COLORS[errand.status] || 'bg-gray-100 text-gray-700'}`}>
                      {errand.status?.replace(/_/g, ' ')}
                    </span>
                  </td>
                  <td className="px-6 py-4 font-semibold text-[#0A1628]">₦{errand.budget?.toLocaleString()}</td>
                  <td className="px-6 py-4 text-gray-500 text-xs">{new Date(errand.created_at).toLocaleDateString()}</td>
                  <td className="px-6 py-4">
                    <Link href={`/admin/errands/${errand.public_id}`} className="p-1.5 text-blue-600 hover:bg-blue-50 rounded-lg transition inline-block">
                      <Eye className="w-4 h-4" />
                    </Link>
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
