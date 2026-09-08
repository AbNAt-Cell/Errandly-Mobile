'use client';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminApi } from '@/lib/api';
import { useState } from 'react';
import { Search, CheckCircle, Ban, Loader2 } from 'lucide-react';
import toast from 'react-hot-toast';

export default function AdminRunnersPage() {
  const [search, setSearch] = useState('');
  const [verificationFilter, setVerificationFilter] = useState('');
  const queryClient = useQueryClient();

  const { data, isLoading } = useQuery({
    queryKey: ['admin-runners', search, verificationFilter],
    queryFn: () => adminApi.runners({ search: search || undefined, verification: verificationFilter || undefined }).then((r) => r.data),
    staleTime: 10000,
  });

  const approveMutation = useMutation({
    mutationFn: (id: number) => adminApi.approveRunner(id),
    onSuccess: () => { toast.success('Runner approved.'); queryClient.invalidateQueries({ queryKey: ['admin-runners'] }); },
  });

  const VERIFICATION_COLORS: Record<string, string> = {
    approved: 'bg-green-100 text-green-700',
    submitted: 'bg-blue-100 text-blue-700',
    pending: 'bg-gray-100 text-foreground',
    rejected: 'bg-red-100 text-red-700',
  };

  return (
    <div className="p-6">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-foreground">Runner Management</h1>
        <p className="text-muted-foreground text-sm">Manage verified runners on the platform</p>
      </div>

      <div className="flex flex-wrap gap-3 mb-6">
        <div className="relative flex-1 min-w-64">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
          <input value={search} onChange={(e) => setSearch(e.target.value)} placeholder="Search runners..." className="w-full pl-9 pr-4 py-2.5 border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary text-sm" />
        </div>
        <select value={verificationFilter} onChange={(e) => setVerificationFilter(e.target.value)} className="px-4 py-2.5 border border-input rounded-xl text-sm focus:outline-none bg-card">
          <option value="">All Verification</option>
          <option value="approved">Approved</option>
          <option value="submitted">Submitted</option>
          <option value="pending">Pending</option>
          <option value="rejected">Rejected</option>
        </select>
      </div>

      <div className="bg-card rounded-2xl border border-border overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-background border-b border-border">
              <tr>
                {['Runner', 'Phone', 'Transport', 'Trust Score', 'Verification', 'Status', 'Online', 'Actions'].map((h) => (
                  <th key={h} className="text-left px-6 py-4 font-semibold text-muted-foreground">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {isLoading ? (
                <tr><td colSpan={8} className="text-center py-10"><Loader2 className="w-6 h-6 animate-spin text-[#FF6B00] mx-auto" /></td></tr>
              ) : data?.data?.map((runner: any) => (
                <tr key={runner.id} className="hover:bg-background transition">
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-3">
                      <div className="w-8 h-8 bg-[#0A1628] rounded-full flex items-center justify-center text-white text-xs font-bold">
                        {runner.first_name?.[0]}{runner.last_name?.[0]}
                      </div>
                      <div>
                        <p className="font-semibold text-foreground">{runner.first_name} {runner.last_name}</p>
                        <p className="text-xs text-muted-foreground">{runner.email}</p>
                      </div>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-foreground">{runner.phone}</td>
                  <td className="px-6 py-4 capitalize text-foreground">{runner.runner_profile?.transport_type}</td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <div className="w-16 h-1.5 bg-gray-100 rounded-full overflow-hidden">
                        <div className="h-full bg-[#FF6B00] rounded-full" style={{ width: `${runner.runner_profile?.trust_score ?? 0}%` }} />
                      </div>
                      <span className="text-xs font-medium">{runner.runner_profile?.trust_score?.toFixed(0)}</span>
                    </div>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${VERIFICATION_COLORS[runner.runner_profile?.verification_status] || 'bg-gray-100 text-foreground'}`}>
                      {runner.runner_profile?.verification_status}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${runner.status === 'active' ? 'bg-green-100 text-green-700' : 'bg-amber-100 text-amber-700'}`}>
                      {runner.status}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className={`w-2.5 h-2.5 rounded-full ${runner.runner_profile?.is_online ? 'bg-green-500' : 'bg-gray-300'}`} />
                  </td>
                  <td className="px-6 py-4">
                    {runner.runner_profile?.verification_status === 'submitted' && (
                      <button onClick={() => approveMutation.mutate(runner.id)} disabled={approveMutation.isPending} className="p-1.5 text-green-600 hover:bg-green-50 rounded-lg transition">
                        <CheckCircle className="w-4 h-4" />
                      </button>
                    )}
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
