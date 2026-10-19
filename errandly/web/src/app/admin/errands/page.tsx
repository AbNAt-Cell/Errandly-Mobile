'use client';
import { useQuery } from '@tanstack/react-query';
import { adminApi } from '@/lib/api';
import { useState } from 'react';
import { Search, Loader2, Eye, UserPlus, RefreshCw, UserCheck, AlertCircle } from 'lucide-react';
import Link from 'next/link';
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

export default function AdminErrandsPage() {
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [unassignedOnly, setUnassignedOnly] = useState(false);
  const [assignModalErrand, setAssignModalErrand] = useState<any | null>(null);

  const { data, isLoading, refetch } = useQuery({
    queryKey: ['admin-errands', search, statusFilter, unassignedOnly],
    queryFn: () =>
      adminApi
        .errands({
          search: search || undefined,
          status: statusFilter || undefined,
          unassigned: unassignedOnly ? 'true' : undefined,
        })
        .then((r) => r.data),
    staleTime: 10000,
  });

  const errands = data?.data || [];

  return (
    <div className="p-6">
      <div className="mb-6 flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-[#0E0F13]">Errand Management</h1>
          <p className="text-gray-500 text-sm">Monitor, assign, and manage all errands across the platform</p>
        </div>
      </div>

      {/* Quick Filter Tabs */}
      <div className="flex flex-wrap items-center gap-2 mb-4">
        <button
          onClick={() => {
            setUnassignedOnly(false);
            setStatusFilter('');
          }}
          className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold transition ${
            !unassignedOnly && !statusFilter
              ? 'bg-[#0E0F13] text-white shadow-sm'
              : 'bg-white text-gray-600 hover:bg-gray-100 border border-gray-200'
          }`}
        >
          All Errands
        </button>

        <button
          onClick={() => {
            setUnassignedOnly(true);
            setStatusFilter('');
          }}
          className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold transition flex items-center gap-1.5 ${
            unassignedOnly
              ? 'bg-[#F97316] text-white shadow-sm'
              : 'bg-orange-50 text-[#F97316] hover:bg-orange-100 border border-orange-200'
          }`}
        >
          <span className="w-2 h-2 rounded-full bg-current animate-pulse" />
          Pending Assignment / Unassigned
        </button>

        <button
          onClick={() => {
            setUnassignedOnly(false);
            setStatusFilter('in_progress');
          }}
          className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold transition ${
            statusFilter === 'in_progress'
              ? 'bg-[#0E0F13] text-white shadow-sm'
              : 'bg-white text-gray-600 hover:bg-gray-100 border border-gray-200'
          }`}
        >
          In Progress
        </button>

        <button
          onClick={() => {
            setUnassignedOnly(false);
            setStatusFilter('completed');
          }}
          className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold transition ${
            statusFilter === 'completed'
              ? 'bg-[#0E0F13] text-white shadow-sm'
              : 'bg-white text-gray-600 hover:bg-gray-100 border border-gray-200'
          }`}
        >
          Completed
        </button>

        <button
          onClick={() => {
            setUnassignedOnly(false);
            setStatusFilter('disputed');
          }}
          className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold transition ${
            statusFilter === 'disputed'
              ? 'bg-red-600 text-white shadow-sm'
              : 'bg-white text-gray-600 hover:bg-gray-100 border border-gray-200'
          }`}
        >
          Disputed
        </button>
      </div>

      {/* Search and Secondary Filter */}
      <div className="flex flex-wrap gap-3 mb-6">
        <div className="relative flex-1 min-w-64">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by errand title or UUID..."
            className="w-full pl-9 pr-4 py-2.5 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316] text-sm bg-white"
          />
        </div>
        <select
          value={statusFilter}
          onChange={(e) => {
            setUnassignedOnly(false);
            setStatusFilter(e.target.value);
          }}
          className="px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none bg-white font-medium text-gray-700"
        >
          <option value="">All Statuses</option>
          {Object.keys(STATUS_COLORS).map((s) => (
            <option key={s} value={s}>
              {s.replace(/_/g, ' ')}
            </option>
          ))}
        </select>
      </div>

      {/* Errands Table */}
      <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-100">
              <tr>
                {['ID', 'Title', 'Customer', 'Runner', 'Status', 'Budget', 'Created', 'Actions'].map((h) => (
                  <th key={h} className="text-left px-6 py-4 font-semibold text-gray-600">
                    {h}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {isLoading ? (
                <tr>
                  <td colSpan={8} className="text-center py-12">
                    <Loader2 className="w-7 h-7 animate-spin text-[#F97316] mx-auto" />
                    <p className="text-xs text-gray-400 mt-2">Loading errands...</p>
                  </td>
                </tr>
              ) : errands.length === 0 ? (
                <tr>
                  <td colSpan={8} className="text-center py-12 text-gray-400">
                    <AlertCircle className="w-8 h-8 text-gray-300 mx-auto mb-2" />
                    <p className="font-medium text-gray-600">No errands found</p>
                    <p className="text-xs text-gray-400 mt-1">Try clearing your filters or search keywords.</p>
                  </td>
                </tr>
              ) : (
                errands.map((errand: any) => {
                  const isUnassigned = !errand.runner && !errand.runner_id;
                  const canAssign =
                    isUnassigned ||
                    ['posted', 'pending_assignment', 'accepted'].includes(errand.status);

                  return (
                    <tr key={errand.id} className="hover:bg-gray-50/70 transition">
                      <td
                        className="px-6 py-4 font-mono text-xs text-gray-500 truncate max-w-[110px]"
                        title={errand.public_id}
                      >
                        {errand.public_id?.slice(0, 8)}…
                      </td>
                      <td className="px-6 py-4">
                        <p className="font-semibold text-[#0E0F13] max-w-xs truncate">{errand.title}</p>
                        <p className="text-xs text-gray-500 capitalize">{errand.category?.replace(/_/g, ' ')}</p>
                      </td>
                      <td className="px-6 py-4 text-gray-700">
                        {errand.customer ? (
                          <span className="font-medium">
                            {errand.customer.first_name} {errand.customer.last_name}
                          </span>
                        ) : (
                          <span className="text-gray-400">—</span>
                        )}
                      </td>
                      <td className="px-6 py-4">
                        {errand.runner ? (
                          <div className="flex items-center gap-2">
                            <span className="font-medium text-gray-800">
                              {errand.runner.first_name} {errand.runner.last_name}
                            </span>
                            <button
                              onClick={() => setAssignModalErrand(errand)}
                              title="Reassign to another runner"
                              className="p-1 text-gray-400 hover:text-[#F97316] hover:bg-orange-50 rounded transition"
                            >
                              <RefreshCw className="w-3.5 h-3.5" />
                            </button>
                          </div>
                        ) : (
                          <button
                            onClick={() => setAssignModalErrand(errand)}
                            className="inline-flex items-center gap-1.5 px-2.5 py-1 text-xs font-semibold bg-orange-50 text-[#F97316] border border-orange-200/80 rounded-lg hover:bg-[#F97316] hover:text-white transition shadow-sm"
                          >
                            <UserPlus className="w-3 h-3" />
                            Assign
                          </button>
                        )}
                      </td>
                      <td className="px-6 py-4">
                        <span
                          className={`text-xs px-2.5 py-1 rounded-full font-medium ${
                            STATUS_COLORS[errand.status] || 'bg-gray-100 text-gray-700'
                          }`}
                        >
                          {errand.status?.replace(/_/g, ' ')}
                        </span>
                      </td>
                      <td className="px-6 py-4 font-bold text-[#0E0F13]">
                        ₦{Number(errand.budget || 0).toLocaleString()}
                      </td>
                      <td className="px-6 py-4 text-gray-500 text-xs">
                        {new Date(errand.created_at).toLocaleDateString()}
                      </td>
                      <td className="px-6 py-4">
                        <div className="flex items-center gap-2">
                          {canAssign && (
                            <button
                              onClick={() => setAssignModalErrand(errand)}
                              title={isUnassigned ? 'Assign runner' : 'Reassign runner'}
                              className={`p-1.5 rounded-lg transition ${
                                isUnassigned
                                  ? 'bg-[#F97316] text-white hover:bg-[#ea580c]'
                                  : 'text-gray-500 hover:text-[#F97316] hover:bg-orange-50'
                              }`}
                            >
                              <UserCheck className="w-4 h-4" />
                            </button>
                          )}
                          <Link
                            href={`/admin/errands/${errand.public_id}`}
                            className="p-1.5 text-blue-600 hover:bg-blue-50 rounded-lg transition inline-block"
                            title="View errand details"
                          >
                            <Eye className="w-4 h-4" />
                          </Link>
                        </div>
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Assign Runner Modal */}
      {assignModalErrand && (
        <AssignRunnerModal
          errand={assignModalErrand}
          isOpen={!!assignModalErrand}
          onClose={() => setAssignModalErrand(null)}
          onAssigned={() => refetch()}
        />
      )}
    </div>
  );
}
