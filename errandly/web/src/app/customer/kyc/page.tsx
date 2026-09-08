'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { kycApi } from '@/lib/api';
import Link from 'next/link';
import { ArrowLeft, Loader2, Shield, CheckCircle } from 'lucide-react';
import toast from 'react-hot-toast';

const ID_TYPES = [
  { value: 'national_id', label: 'National ID (NIN)' },
  { value: 'drivers_license', label: "Driver's License" },
  { value: 'passport', label: 'Passport' },
  { value: 'voters_card', label: "Voter's Card" },
];

export default function CustomerKycPage() {
  const queryClient = useQueryClient();
  const [idType, setIdType] = useState('national_id');
  const [idNumber, setIdNumber] = useState('');
  const [idDocumentUrl, setIdDocumentUrl] = useState('');
  const [selfieUrl, setSelfieUrl] = useState('');

  const { data, isLoading } = useQuery({
    queryKey: ['kyc-status'],
    queryFn: () => kycApi.status().then((r) => r.data),
  });

  const submitMutation = useMutation({
    mutationFn: () =>
      kycApi.submit({
        id_type: idType,
        id_number: idNumber,
        id_document_url: idDocumentUrl,
        selfie_url: selfieUrl,
      }),
    onSuccess: () => {
      toast.success('KYC submitted. We will review within 24 hours.');
      queryClient.invalidateQueries({ queryKey: ['kyc-status'] });
    },
    onError: (e: { response?: { data?: { message?: string } } }) => {
      toast.error(e.response?.data?.message || 'Submission failed');
    },
  });

  const status = data?.kyc_status ?? 'none';
  const approved = status === 'approved';

  return (
    <div className="p-4 pb-24 max-w-lg mx-auto">
      <div className="flex items-center gap-3 mb-6">
        <Link href="/customer/profile" className="p-2 rounded-lg hover:bg-muted">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="font-bold text-xl text-foreground">Identity Verification</h1>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-12">
          <Loader2 className="w-6 h-6 animate-spin text-[#FF6B00]" />
        </div>
      ) : approved ? (
        <div className="bg-green-50 border border-green-200 rounded-2xl p-6 text-center">
          <CheckCircle className="w-12 h-12 text-green-600 mx-auto mb-3" />
          <p className="font-semibold text-green-800">You are verified</p>
          <p className="text-sm text-green-700 mt-1">Your identity has been approved.</p>
        </div>
      ) : (
        <>
          <div className="bg-amber-50 border border-amber-200 rounded-xl p-4 mb-6 flex gap-3 text-sm text-amber-900">
            <Shield className="w-5 h-5 flex-shrink-0" />
            <p>
              Status: <strong>{status}</strong>. Upload document URLs (hosted image links) for review.
              {status === 'pending' && ' Your submission is under review.'}
            </p>
          </div>

          <div className="space-y-4 bg-card rounded-2xl border border-border p-4">
            <div>
              <label className="text-sm font-medium text-foreground">ID type</label>
              <select
                value={idType}
                onChange={(e) => setIdType(e.target.value)}
                className="mt-1 w-full border border-input rounded-xl px-4 py-3 bg-card text-sm"
              >
                {ID_TYPES.map((t) => (
                  <option key={t.value} value={t.value}>
                    {t.label}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="text-sm font-medium text-foreground">ID number</label>
              <input
                value={idNumber}
                onChange={(e) => setIdNumber(e.target.value)}
                className="mt-1 w-full border border-input rounded-xl px-4 py-3 text-sm"
              />
            </div>
            <div>
              <label className="text-sm font-medium text-foreground">ID document URL</label>
              <input
                value={idDocumentUrl}
                onChange={(e) => setIdDocumentUrl(e.target.value)}
                placeholder="https://..."
                className="mt-1 w-full border border-input rounded-xl px-4 py-3 text-sm"
              />
            </div>
            <div>
              <label className="text-sm font-medium text-foreground">Selfie URL</label>
              <input
                value={selfieUrl}
                onChange={(e) => setSelfieUrl(e.target.value)}
                placeholder="https://..."
                className="mt-1 w-full border border-input rounded-xl px-4 py-3 text-sm"
              />
            </div>
            <button
              type="button"
              onClick={() => submitMutation.mutate()}
              disabled={submitMutation.isPending || status === 'pending'}
              className="w-full errandly-btn-primary disabled:opacity-50"
            >
              {submitMutation.isPending ? 'Submitting…' : 'Submit for review'}
            </button>
          </div>
        </>
      )}
    </div>
  );
}
