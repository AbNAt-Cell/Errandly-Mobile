'use client';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminApi } from '@/lib/api';
import { useState } from 'react';
import { AlertTriangle, Eye, CheckCircle, Loader2 } from 'lucide-react';
import toast from 'react-hot-toast';

const STATUS_COLORS: Record<string, string> = {
  open: 'bg-red-100 text-red-700',
  under_review: 'bg-amber-100 text-amber-700',
  awaiting_evidence: 'bg-blue-100 text-blue-700',
  resolved: 'bg-green-100 text-green-700',
  closed: 'bg-gray-100 text-foreground',
};

export default function AdminDisputesPage() {
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [resolveModal, setResolveModal] = useState<number | null>(null);
  const [resolution, setResolution] = useState({ resolution_type: 'refund', resolution: '', refund_amount: '' });
  const queryClient = useQueryClient();

  const { data: disputes, isLoading } = useQuery({
    queryKey: ['admin-disputes'],
    queryFn: () => adminApi.disputes().then((r) => r.data),
  });

  const { data: detail } = useQuery({
    queryKey: ['admin-dispute-detail', selectedId],
    queryFn: () => adminApi.dispute(selectedId!).then((r) => r.data),
    enabled: !!selectedId,
  });

  const resolveMutation = useMutation({
    mutationFn: ({ id, data }: { id: number; data: any }) => adminApi.resolveDispute(id, data),
    onSuccess: () => {
      toast.success('Dispute resolved.');
      queryClient.invalidateQueries({ queryKey: ['admin-disputes'] });
      setResolveModal(null);
    },
    onError: (e: any) => toast.error(e.response?.data?.message || 'Failed'),
  });

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Dispute Management</h1>
          <p className="text-muted-foreground text-sm">Review and resolve disputes between customers and runners</p>
        </div>
      </div>

      <div className="bg-card rounded-2xl border border-border overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead className="bg-background border-b border-border">
              <tr>
                <th className="text-left px-6 py-4 font-semibold text-muted-foreground">ID</th>
                <th className="text-left px-6 py-4 font-semibold text-muted-foreground">Errand</th>
                <th className="text-left px-6 py-4 font-semibold text-muted-foreground">Raised By</th>
                <th className="text-left px-6 py-4 font-semibold text-muted-foreground">Type</th>
                <th className="text-left px-6 py-4 font-semibold text-muted-foreground">Status</th>
                <th className="text-left px-6 py-4 font-semibold text-muted-foreground">Budget</th>
                <th className="text-left px-6 py-4 font-semibold text-muted-foreground">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-50">
              {isLoading ? (
                <tr><td colSpan={7} className="text-center py-10"><Loader2 className="w-6 h-6 animate-spin text-[#FF6B00] mx-auto" /></td></tr>
              ) : disputes?.data?.map((dispute: any) => (
                <tr key={dispute.id} className="hover:bg-background transition">
                  <td className="px-6 py-4 font-mono text-xs text-muted-foreground">#{dispute.id}</td>
                  <td className="px-6 py-4">
                    <p className="font-medium text-foreground">{dispute.errand?.title}</p>
                    <p className="text-xs text-muted-foreground">Errand #{dispute.errand_id}</p>
                  </td>
                  <td className="px-6 py-4 text-foreground">{dispute.raised_by?.first_name} {dispute.raised_by?.last_name}</td>
                  <td className="px-6 py-4">
                    <span className="text-xs bg-gray-100 text-foreground px-2.5 py-1 rounded-full font-medium">
                      {dispute.type?.replace(/_/g, ' ')}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`text-xs px-2.5 py-1 rounded-full font-medium ${STATUS_COLORS[dispute.status] || 'bg-gray-100 text-foreground'}`}>
                      {dispute.status?.replace(/_/g, ' ')}
                    </span>
                  </td>
                  <td className="px-6 py-4 font-semibold text-foreground">₦{dispute.errand?.budget?.toLocaleString()}</td>
                  <td className="px-6 py-4">
                    <div className="flex gap-2">
                      <button onClick={() => setSelectedId(dispute.id)} className="p-1.5 text-blue-600 hover:bg-blue-50 rounded-lg transition">
                        <Eye className="w-4 h-4" />
                      </button>
                      {['open', 'under_review'].includes(dispute.status) && (
                        <button onClick={() => setResolveModal(dispute.id)} className="p-1.5 text-green-600 hover:bg-green-50 rounded-lg transition">
                          <CheckCircle className="w-4 h-4" />
                        </button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Resolve Modal */}
      {resolveModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-card rounded-2xl p-6 max-w-md w-full">
            <h3 className="font-bold text-foreground text-lg mb-4 flex items-center gap-2">
              <AlertTriangle className="w-5 h-5 text-amber-500" />
              Resolve Dispute #{resolveModal}
            </h3>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-foreground mb-1">Resolution Type</label>
                <select
                  value={resolution.resolution_type}
                  onChange={(e) => setResolution({ ...resolution, resolution_type: e.target.value })}
                  className="w-full px-4 py-3 border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary bg-card"
                >
                  <option value="refund">Full Refund to Customer</option>
                  <option value="release">Release to Runner</option>
                  <option value="partial_refund">Partial Refund</option>
                  <option value="no_action">No Action</option>
                </select>
              </div>

              {resolution.resolution_type === 'partial_refund' && (
                <div>
                  <label className="block text-sm font-medium text-foreground mb-1">Refund Amount (₦)</label>
                  <input
                    type="number"
                    value={resolution.refund_amount}
                    onChange={(e) => setResolution({ ...resolution, refund_amount: e.target.value })}
                    className="w-full px-4 py-3 border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary"
                  />
                </div>
              )}

              <div>
                <label className="block text-sm font-medium text-foreground mb-1">Resolution Notes</label>
                <textarea
                  value={resolution.resolution}
                  onChange={(e) => setResolution({ ...resolution, resolution: e.target.value })}
                  rows={3}
                  className="w-full px-4 py-3 border border-input rounded-xl resize-none focus:outline-none focus:ring-2 focus:ring-primary"
                  placeholder="Explain the resolution decision..."
                />
              </div>
            </div>

            <div className="flex gap-3 mt-5">
              <button onClick={() => setResolveModal(null)} className="flex-1 border border-input text-foreground font-semibold py-3 rounded-xl hover:bg-background transition">
                Cancel
              </button>
              <button
                onClick={() => resolveMutation.mutate({
                  id: resolveModal,
                  data: {
                    resolution_type: resolution.resolution_type,
                    resolution: resolution.resolution,
                    refund_amount: resolution.refund_amount ? parseInt(resolution.refund_amount) : undefined,
                  }
                })}
                disabled={resolveMutation.isPending || !resolution.resolution}
                className="flex-1 bg-green-600 hover:bg-green-700 text-white font-semibold py-3 rounded-xl transition flex items-center justify-center gap-2 disabled:opacity-70"
              >
                {resolveMutation.isPending && <Loader2 className="w-4 h-4 animate-spin" />}
                Resolve Dispute
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
