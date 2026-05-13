'use client';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminApi } from '@/lib/api';
import { useState } from 'react';
import { Search, Shield, Ban, RefreshCw, Loader2, CheckCircle } from 'lucide-react';
import toast from 'react-hot-toast';

const STATUS_COLORS: Record<string, string> = {
  active: 'bg-green-100 text-green-700',
  suspended: 'bg-amber-100 text-amber-700',
  blacklisted: 'bg-red-100 text-red-700',
  pending: 'bg-gray-100 text-gray-700',
};

const KYC_COLORS: Record<string, string> = {
  approved: 'bg-green-100 text-green-700',
  submitted: 'bg-blue-100 text-blue-700',
  rejected: 'bg-red-100 text-red-700',
  pending: 'bg-gray-100 text-gray-700',
};

export default function AdminUsersPage() {
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [actionModal, setActionModal] = useState<{ type: string; userId: number; name: string } | null>(null);
  const [reason, setReason] = useState('');
  const queryClient = useQueryClient();

  const { data: users, isLoading } = useQuery({
    queryKey: ['admin-users', search, roleFilter, statusFilter],
    queryFn: () => adminApi.users({ search: search || undefined, role: roleFilter || undefined, status: statusFilter || undefined }).then((r) => r.data),
    staleTime: 10000,
  });

  const suspendMutation = useMutation({
    mutationFn: ({ id, reason }: { id: number; reason: string }) => adminApi.suspendUser(id, { reason }),
    onSuccess: () => { toast.success('User suspended.'); queryClient.invalidateQueries({ queryKey: ['admin-users'] }); setActionModal(null); },
    onError: (e: any) => toast.error(e.response?.data?.message || 'Failed'),
  });

  const restoreMutation = useMutation({
    mutationFn: (id: number) => adminApi.restoreUser(id),
    onSuccess: () => { toast.success('User restored.'); queryClient.invalidateQueries({ queryKey: ['admin-users'] }); setActionModal(null); },
  });

  const blacklistMutation = useMutation({
    mutationFn: ({ id, reason }: { id: number; reason: string }) => adminApi.blacklistUser(id, { reason }),
    onSuccess: () => { toast.success('User blacklisted.'); queryClient.invalidateQueries({ queryKey: ['admin-users'] }); setActionModal(null); },
  });

  const handleAction = () => {
    if (!actionModal) return;
    if (actionModal.type === 'suspend') suspendMutation.mutate({ id: actionModal.userId, reason });
    if (actionModal.type === 'restore') restoreMutation.mutate(actionModal.userId);
    if (actionModal.type === 'blacklist') blacklistMutation.mutate({ id: actionModal.userId, reason });
  };

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-[#0A1628]">User Management</h1>
        <p className="text-gray-500 text-sm">Manage all customers and runners</p>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3 mb-6">
        <div className="relative flex-1 min-w-64">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search by name, email, or phone..."
            className="w-full pl-9 pr-4 py-2.5 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00] text-sm"
          />
        </div>
        <select value={roleFilter} onChange={(e) => setRoleFilter(e.target.value)} className="px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#FF6B00] bg-white">
          <option value="">All Roles</option>
          <option value="customer">Customers</option>
          <option value="runner">Runners</option>
          <option value="admin">Admins</option>
        </select>
        <select value={statusFilter} onChange={(e) => setStatusFilter(e.target.value)} className="px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-[#FF6B00] bg-white">
          <option value="">All Status</option>
          <option value="active">Active</option>
          <option value="suspended">Suspended</option>
          <option value="pending">Pending</option>
          <option value="blacklisted">Blacklisted</option>
        </select>
      </div>

      {/* Table */}
      <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-gray-50 border-b border-gray-100">
              <tr>
                <th className="text-left px-6 py-4 font-semibold text-gray-600">User</th>
                <th className="text-left px-6 py-4 font-semibold text-gray-600">Contact</th>
                <th className="text-left px-6 py-4 font-semibold text-gray-600">Status</th>
                <th className="text-left px-6 py-4 font-semibold text-gray-600">KYC</th>
                <th className="text-left px-6 py-4 font-semibold text-gray-600">Wallet</th>
                <th className="text-left px-6 py-4 font-semibold text-gray-600">Joined</th>
                <th className="text-left px-6 py-4 font-semibold text-gray-600">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {isLoading ? (
                <tr><td colSpan={7} className="text-center py-10"><Loader2 className="w-6 h-6 animate-spin text-[#FF6B00] mx-auto" /></td></tr>
              ) : users?.data?.map((user: any) => (
                <tr key={user.id} className="hover:bg-gray-50 transition">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 bg-[#FF6B00] rounded-full flex items-center justify-center text-white text-xs font-bold">
                        {user.first_name?.[0]}{user.last_name?.[0]}
                      </div>
                      <div>
                        <p className="font-semibold text-[#0A1628]">{user.first_name} {user.last_name}</p>
                        <p className="text-xs text-gray-500">{user.city}, {user.state}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <p className="text-gray-700">{user.email}</p>
                    <p className="text-xs text-gray-500">{user.phone}</p>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${STATUS_COLORS[user.status] || 'bg-gray-100 text-gray-700'}`}>
                      {user.status}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${KYC_COLORS[user.kyc_status] || 'bg-gray-100 text-gray-700'}`}>
                      {user.kyc_status}
                    </span>
                  </td>
                  <td className="px-6 py-4 font-medium text-[#0A1628]">
                    ₦{user.wallet?.balance?.toLocaleString() ?? '0'}
                  </td>
                  <td className="px-6 py-4 text-gray-500 text-xs">
                    {new Date(user.created_at).toLocaleDateString()}
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex gap-2">
                      {user.status === 'active' && (
                        <button
                          onClick={() => { setActionModal({ type: 'suspend', userId: user.id, name: `${user.first_name} ${user.last_name}` }); setReason(''); }}
                          className="p-1.5 text-amber-600 hover:bg-amber-50 rounded-lg transition"
                          title="Suspend"
                        >
                          <Ban className="w-4 h-4" />
                        </button>
                      )}
                      {(user.status === 'suspended' || user.status === 'blacklisted') && (
                        <button
                          onClick={() => { setActionModal({ type: 'restore', userId: user.id, name: `${user.first_name} ${user.last_name}` }); }}
                          className="p-1.5 text-green-600 hover:bg-green-50 rounded-lg transition"
                          title="Restore"
                        >
                          <RefreshCw className="w-4 h-4" />
                        </button>
                      )}
                      {user.status !== 'blacklisted' && (
                        <button
                          onClick={() => { setActionModal({ type: 'blacklist', userId: user.id, name: `${user.first_name} ${user.last_name}` }); setReason(''); }}
                          className="p-1.5 text-red-600 hover:bg-red-50 rounded-lg transition"
                          title="Blacklist"
                        >
                          <Shield className="w-4 h-4" />
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        {/* Pagination */}
        {users?.meta && (
          <div className="px-6 py-4 border-t border-gray-100 flex items-center justify-between text-sm text-gray-500">
            <span>Showing {users.from}–{users.to} of {users.total}</span>
            <div className="flex gap-2">
              {users.current_page > 1 && <button className="px-3 py-1 border border-gray-200 rounded-lg hover:bg-gray-50">Previous</button>}
              {users.current_page < users.last_page && <button className="px-3 py-1 border border-gray-200 rounded-lg hover:bg-gray-50">Next</button>}
            </div>
          </div>
        )}
      </div>

      {/* Action Modal */}
      {actionModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl p-6 max-w-md w-full">
            <h3 className="font-bold text-[#0A1628] text-lg mb-2 capitalize">{actionModal.type} User</h3>
            <p className="text-gray-500 text-sm mb-4">User: <strong>{actionModal.name}</strong></p>
            {actionModal.type !== 'restore' && (
              <textarea
                value={reason}
                onChange={(e) => setReason(e.target.value)}
                rows={3}
                placeholder="Reason (required)..."
                className="w-full px-4 py-3 border border-gray-200 rounded-xl resize-none focus:outline-none focus:ring-2 focus:ring-[#FF6B00] mb-4"
              />
            )}
            <div className="flex gap-3">
              <button onClick={() => setActionModal(null)} className="flex-1 border border-gray-200 text-gray-700 font-semibold py-3 rounded-xl hover:bg-gray-50 transition">Cancel</button>
              <button
                onClick={handleAction}
                disabled={suspendMutation.isPending || restoreMutation.isPending || blacklistMutation.isPending}
                className={`flex-1 font-semibold py-3 rounded-xl text-white transition flex items-center justify-center gap-2 disabled:opacity-70 ${
                  actionModal.type === 'restore' ? 'bg-green-600 hover:bg-green-700' :
                  actionModal.type === 'blacklist' ? 'bg-red-600 hover:bg-red-700' : 'bg-amber-600 hover:bg-amber-700'
                }`}
              >
                {(suspendMutation.isPending || restoreMutation.isPending || blacklistMutation.isPending) && <Loader2 className="w-4 h-4 animate-spin" />}
                Confirm
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
