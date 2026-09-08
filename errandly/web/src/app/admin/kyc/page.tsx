'use client';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { adminApi } from '@/lib/api';
import { useState } from 'react';
import { Shield, CheckCircle, XCircle, RefreshCw, Eye, Loader2 } from 'lucide-react';
import toast from 'react-hot-toast';

export default function AdminKycPage() {
  const [selectedKyc, setSelectedKyc] = useState<any>(null);
  const [actionModal, setActionModal] = useState<{ type: 'approve' | 'reject' | 'resubmit'; id: number } | null>(null);
  const [reason, setReason] = useState('');
  const queryClient = useQueryClient();

  const { data: kycs, isLoading } = useQuery({
    queryKey: ['admin-kyc-pending'],
    queryFn: () => adminApi.kycPending().then((r) => r.data),
  });

  const { data: kycDetail } = useQuery({
    queryKey: ['admin-kyc-detail', selectedKyc],
    queryFn: () => adminApi.kycGet(selectedKyc).then((r) => r.data),
    enabled: !!selectedKyc,
  });

  const approveMutation = useMutation({
    mutationFn: ({ id, notes }: { id: number; notes?: string }) => adminApi.kycApprove(id, { notes }),
    onSuccess: () => {
      toast.success('KYC Approved. User has been notified.');
      queryClient.invalidateQueries({ queryKey: ['admin-kyc-pending'] });
      setActionModal(null);
      setSelectedKyc(null);
    },
  });

  const rejectMutation = useMutation({
    mutationFn: ({ id, reason }: { id: number; reason: string }) => adminApi.kycReject(id, { reason }),
    onSuccess: () => {
      toast.success('KYC Rejected. User has been notified.');
      queryClient.invalidateQueries({ queryKey: ['admin-kyc-pending'] });
      setActionModal(null);
      setSelectedKyc(null);
    },
  });

  const resubmitMutation = useMutation({
    mutationFn: ({ id, reason }: { id: number; reason: string }) => adminApi.kycResubmit(id, { reason }),
    onSuccess: () => {
      toast.success('Resubmission requested.');
      queryClient.invalidateQueries({ queryKey: ['admin-kyc-pending'] });
      setActionModal(null);
      setSelectedKyc(null);
    },
  });

  const handleAction = () => {
    if (!actionModal) return;
    if (actionModal.type === 'approve') {
      approveMutation.mutate({ id: actionModal.id, notes: reason });
    } else if (actionModal.type === 'reject') {
      if (!reason) { toast.error('Reason required'); return; }
      rejectMutation.mutate({ id: actionModal.id, reason });
    } else {
      if (!reason) { toast.error('Reason required'); return; }
      resubmitMutation.mutate({ id: actionModal.id, reason });
    }
  };

  return (
    <div className="p-6">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-foreground">KYC Review</h1>
          <p className="text-muted-foreground text-sm">Review and approve identity verification submissions</p>
        </div>
        <div className="flex items-center gap-2 bg-amber-100 text-amber-700 px-4 py-2 rounded-xl text-sm font-medium">
          <Shield className="w-4 h-4" />
          {kycs?.data?.length ?? 0} pending
        </div>
      </div>

      <div className="grid lg:grid-cols-2 gap-6">
        {/* List */}
        <div className="space-y-3">
          {isLoading ? (
            <div className="flex items-center justify-center h-32"><Loader2 className="w-6 h-6 animate-spin text-[#FF6B00]" /></div>
          ) : kycs?.data?.length === 0 ? (
            <div className="bg-card rounded-2xl p-10 text-center border border-border">
              <Shield className="w-12 h-12 text-green-400 mx-auto mb-3" />
              <p className="text-muted-foreground">All KYC submissions reviewed</p>
            </div>
          ) : kycs?.data?.map((kyc: any) => (
            <div
              key={kyc.id}
              onClick={() => setSelectedKyc(kyc.id)}
              className={`bg-card rounded-2xl p-5 border cursor-pointer transition hover:border-[#FF6B00] ${selectedKyc === kyc.id ? 'border-[#FF6B00] shadow-md' : 'border-border'}`}
            >
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-[#FF6B00] rounded-full flex items-center justify-center text-white font-bold text-sm">
                    {kyc.user?.first_name?.[0]}{kyc.user?.last_name?.[0]}
                  </div>
                  <div>
                    <p className="font-semibold text-foreground">{kyc.user?.first_name} {kyc.user?.last_name}</p>
                    <p className="text-sm text-muted-foreground">{kyc.user?.email}</p>
                  </div>
                </div>
                <div className="text-right">
                  <span className="text-xs px-2.5 py-1 bg-yellow-100 text-yellow-700 rounded-full font-medium">
                    {kyc.type === 'runner' ? '🏃 Runner' : '👤 Customer'}
                  </span>
                  <p className="text-xs text-gray-400 mt-1">{kyc.id_type?.replace(/_/g, ' ')}</p>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Detail panel */}
        {kycDetail && (
          <div className="bg-card rounded-2xl border border-border p-6">
            <div className="flex items-center justify-between mb-6">
              <h3 className="font-bold text-foreground">KYC Details</h3>
              <div className="flex gap-2">
                <button
                  onClick={() => setActionModal({ type: 'resubmit', id: kycDetail.id })}
                  className="p-2 text-amber-600 hover:bg-amber-50 rounded-lg transition"
                  title="Request resubmission"
                >
                  <RefreshCw className="w-5 h-5" />
                </button>
                <button
                  onClick={() => setActionModal({ type: 'reject', id: kycDetail.id })}
                  className="p-2 text-red-600 hover:bg-red-50 rounded-lg transition"
                  title="Reject"
                >
                  <XCircle className="w-5 h-5" />
                </button>
                <button
                  onClick={() => setActionModal({ type: 'approve', id: kycDetail.id })}
                  className="p-2 text-green-600 hover:bg-green-50 rounded-lg transition"
                  title="Approve"
                >
                  <CheckCircle className="w-5 h-5" />
                </button>
              </div>
            </div>

            <div className="space-y-4">
              <div>
                <p className="text-xs text-muted-foreground mb-1">User</p>
                <p className="font-semibold">{kycDetail.user?.first_name} {kycDetail.user?.last_name}</p>
                <p className="text-sm text-muted-foreground">{kycDetail.user?.email} · {kycDetail.user?.phone}</p>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <p className="text-xs text-muted-foreground mb-1">ID Type</p>
                  <p className="text-sm font-medium">{kycDetail.id_type?.replace(/_/g, ' ')}</p>
                </div>
                <div>
                  <p className="text-xs text-muted-foreground mb-1">ID Number</p>
                  <p className="text-sm font-medium">{kycDetail.id_number}</p>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                {kycDetail.id_document_url && (
                  <a href={kycDetail.id_document_url} target="_blank" rel="noreferrer" className="block">
                    <div className="border border-input rounded-xl overflow-hidden">
                      <img src={kycDetail.id_document_url} alt="ID Document" className="w-full h-32 object-cover" />
                      <div className="px-2 py-1.5 text-xs text-center text-muted-foreground">ID Document</div>
                    </div>
                  </a>
                )}
                {kycDetail.selfie_url && (
                  <a href={kycDetail.selfie_url} target="_blank" rel="noreferrer" className="block">
                    <div className="border border-input rounded-xl overflow-hidden">
                      <img src={kycDetail.selfie_url} alt="Selfie" className="w-full h-32 object-cover" />
                      <div className="px-2 py-1.5 text-xs text-center text-muted-foreground">Selfie</div>
                    </div>
                  </a>
                )}
              </div>

              <div className="flex gap-3 mt-6">
                <button
                  onClick={() => setActionModal({ type: 'approve', id: kycDetail.id })}
                  className="flex-1 bg-green-600 hover:bg-green-700 text-white font-semibold py-3 rounded-xl transition flex items-center justify-center gap-2"
                >
                  <CheckCircle className="w-5 h-5" />
                  Approve KYC
                </button>
                <button
                  onClick={() => setActionModal({ type: 'reject', id: kycDetail.id })}
                  className="flex-1 bg-red-600 hover:bg-red-700 text-white font-semibold py-3 rounded-xl transition flex items-center justify-center gap-2"
                >
                  <XCircle className="w-5 h-5" />
                  Reject
                </button>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Action Modal */}
      {actionModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-card rounded-2xl p-6 max-w-md w-full">
            <h3 className="font-bold text-foreground text-lg mb-2">
              {actionModal.type === 'approve' ? 'Approve KYC' : actionModal.type === 'reject' ? 'Reject KYC' : 'Request Resubmission'}
            </h3>
            <p className="text-muted-foreground text-sm mb-4">
              {actionModal.type === 'approve'
                ? 'The user will be notified and their account will be activated.'
                : 'Provide a reason that will be shown to the user.'}
            </p>
            <textarea
              value={reason}
              onChange={(e) => setReason(e.target.value)}
              className="w-full px-4 py-3 border border-input rounded-xl resize-none focus:outline-none focus:ring-2 focus:ring-primary"
              rows={3}
              placeholder={actionModal.type === 'approve' ? 'Optional notes...' : 'Reason (required)'}
            />
            <div className="flex gap-3 mt-4">
              <button onClick={() => { setActionModal(null); setReason(''); }} className="flex-1 border border-input text-foreground font-semibold py-3 rounded-xl hover:bg-background transition">
                Cancel
              </button>
              <button
                onClick={handleAction}
                disabled={approveMutation.isPending || rejectMutation.isPending || resubmitMutation.isPending}
                className={`flex-1 font-semibold py-3 rounded-xl text-white transition flex items-center justify-center gap-2 ${
                  actionModal.type === 'approve' ? 'bg-green-600 hover:bg-green-700' :
                  actionModal.type === 'reject' ? 'bg-red-600 hover:bg-red-700' : 'bg-amber-600 hover:bg-amber-700'
                }`}
              >
                {(approveMutation.isPending || rejectMutation.isPending || resubmitMutation.isPending) && <Loader2 className="w-4 h-4 animate-spin" />}
                Confirm
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
