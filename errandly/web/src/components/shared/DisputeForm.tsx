'use client';

import { useState } from 'react';
import { disputeApi } from '@/lib/api';
import toast from 'react-hot-toast';

const TYPES = [
  { value: 'item_not_delivered', label: 'Item not delivered' },
  { value: 'item_damaged', label: 'Item damaged' },
  { value: 'wrong_task_execution', label: 'Wrong execution' },
  { value: 'harassment', label: 'Harassment' },
  { value: 'fraudulent_completion', label: 'Fraudulent completion' },
  { value: 'missing_payment', label: 'Missing payment' },
  { value: 'other', label: 'Other' },
];

type Props = {
  publicId: string;
  onClose: () => void;
  onSubmitted?: () => void;
};

export default function DisputeForm({ publicId, onClose, onSubmitted }: Props) {
  const [type, setType] = useState('item_not_delivered');
  const [description, setDescription] = useState('');
  const [loading, setLoading] = useState(false);

  const submit = async () => {
    if (!description.trim()) {
      toast.error('Please describe the issue');
      return;
    }
    setLoading(true);
    try {
      await disputeApi.create({ public_id: publicId, type, description });
      toast.success('Dispute submitted. Our team will review it.');
      onSubmitted?.();
      onClose();
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { message?: string } } })?.response?.data?.message;
      toast.error(msg || 'Could not open dispute');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-end sm:items-center justify-center p-4">
      <div className="bg-card rounded-2xl w-full max-w-md p-6 max-h-[90vh] overflow-y-auto">
        <h3 className="font-bold text-lg text-foreground mb-4">Raise a dispute</h3>
        <label className="block text-sm font-medium text-foreground mb-1">Type</label>
        <select
          value={type}
          onChange={(e) => setType(e.target.value)}
          className="w-full border border-input rounded-xl px-4 py-3 mb-4 text-sm"
        >
          {TYPES.map((t) => (
            <option key={t.value} value={t.value}>
              {t.label}
            </option>
          ))}
        </select>
        <label className="block text-sm font-medium text-foreground mb-1">Description</label>
        <textarea
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          rows={4}
          className="w-full border border-input rounded-xl px-4 py-3 text-sm mb-4 resize-none"
          placeholder="Explain what went wrong…"
        />
        <div className="flex gap-3">
          <button type="button" onClick={onClose} className="flex-1 py-3 rounded-xl border border-input text-foreground font-medium">
            Cancel
          </button>
          <button type="button" onClick={submit} disabled={loading} className="flex-1 py-3 rounded-xl bg-red-600 text-white font-medium disabled:opacity-50">
            {loading ? 'Submitting…' : 'Submit dispute'}
          </button>
        </div>
      </div>
    </div>
  );
}
