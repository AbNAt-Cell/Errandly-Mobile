'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { runnerApi, kycApi } from '@/lib/api';
import Link from 'next/link';
import { ArrowLeft, Loader2, Shield, CheckCircle } from 'lucide-react';
import toast from 'react-hot-toast';

const ID_TYPES = [
  { value: 'national_id', label: 'National ID (NIN)' },
  { value: 'drivers_license', label: "Driver's License" },
  { value: 'passport', label: 'Passport' },
  { value: 'voters_card', label: "Voter's Card" },
];

export default function RunnerKycPage() {
  const queryClient = useQueryClient();
  const [idType, setIdType] = useState('national_id');
  const [idNumber, setIdNumber] = useState('');
  const [ninNumber, setNinNumber] = useState('');
  const [bvnNumber, setBvnNumber] = useState('');
  const [idDocumentUrl, setIdDocumentUrl] = useState('');
  const [selfieUrl, setSelfieUrl] = useState('');

  const { data: verification, isLoading: vLoading } = useQuery({
    queryKey: ['runner-verification'],
    queryFn: () => runnerApi.verificationStatus().then((r) => r.data),
  });

  const { data: kyc, isLoading: kLoading } = useQuery({
    queryKey: ['kyc-status'],
    queryFn: () => kycApi.status().then((r) => r.data),
  });

  const submitMutation = useMutation({
    mutationFn: () =>
      runnerApi.submitKyc({
        id_type: idType,
        id_number: idNumber,
        nin_number: ninNumber,
        bvn_number: bvnNumber,
        id_document_url: idDocumentUrl,
        selfie_url: selfieUrl,
      }),
    onSuccess: () => {
      toast.success('Runner KYC submitted.');
      queryClient.invalidateQueries({ queryKey: ['runner-verification'] });
      queryClient.invalidateQueries({ queryKey: ['kyc-status'] });
    },
    onError: (e: { response?: { data?: { message?: string } } }) =>
      toast.error(e.response?.data?.message || 'Submission failed'),
  });

  const isLoading = vLoading || kLoading;
  const approved = verification?.verification_status === 'approved' || kyc?.kyc_status === 'approved';

  return (
    <div className="p-4 pb-24 max-w-lg mx-auto">
      <div className="flex items-center gap-3 mb-6">
        <Link href="/runner/profile" className="p-2 rounded-lg hover:bg-muted">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="font-bold text-xl text-foreground">Runner verification</h1>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-12">
          <Loader2 className="w-6 h-6 animate-spin text-[#FF6B00]" />
        </div>
      ) : approved ? (
        <div className="bg-green-50 border border-green-200 rounded-2xl p-6 text-center">
          <CheckCircle className="w-12 h-12 text-green-600 mx-auto mb-3" />
          <p className="font-semibold text-green-800">You can accept errands</p>
        </div>
      ) : (
        <>
          <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 mb-6 flex gap-3 text-sm text-amber-900">
            <Shield className="w-5 h-5 flex-shrink-0" />
            <p>Status: {verification?.verification_status ?? kyc?.kyc_status ?? 'pending'}. Submit NIN, BVN, and document URLs.</p>
          </div>
          <div className="space-y-4 bg-card rounded-2xl border border-border p-4">
            <select value={idType} onChange={(e) => setIdType(e.target.value)} className="w-full border border-input rounded-xl px-4 py-3 text-sm">
              {ID_TYPES.map((t) => (
                <option key={t.value} value={t.value}>
                  {t.label}
                </option>
              ))}
            </select>
            <input value={idNumber} onChange={(e) => setIdNumber(e.target.value)} placeholder="ID number" className="w-full border border-input rounded-xl px-4 py-3 text-sm" />
            <input value={ninNumber} onChange={(e) => setNinNumber(e.target.value)} placeholder="NIN" className="w-full border border-input rounded-xl px-4 py-3 text-sm" />
            <input value={bvnNumber} onChange={(e) => setBvnNumber(e.target.value)} placeholder="BVN" className="w-full border border-input rounded-xl px-4 py-3 text-sm" />
            <input value={idDocumentUrl} onChange={(e) => setIdDocumentUrl(e.target.value)} placeholder="ID document URL" className="w-full border border-input rounded-xl px-4 py-3 text-sm" />
            <input value={selfieUrl} onChange={(e) => setSelfieUrl(e.target.value)} placeholder="Selfie URL" className="w-full border border-input rounded-xl px-4 py-3 text-sm" />
            <button type="button" onClick={() => submitMutation.mutate()} disabled={submitMutation.isPending} className="w-full errandly-btn-primary disabled:opacity-50">
              {submitMutation.isPending ? 'Submitting…' : 'Submit runner KYC'}
            </button>
          </div>
        </>
      )}
    </div>
  );
}
