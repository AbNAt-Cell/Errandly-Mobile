'use client';

import { useState } from 'react';
import { ratingApi } from '@/lib/api';
import toast from 'react-hot-toast';

type Props = {
  publicId: string;
  onClose: () => void;
  onSubmitted?: () => void;
};

export default function RatingModal({ publicId, onClose, onSubmitted }: Props) {
  const [score, setScore] = useState(5);
  const [comment, setComment] = useState('');
  const [loading, setLoading] = useState(false);

  const submit = async () => {
    setLoading(true);
    try {
      await ratingApi.submit({
        public_id: publicId,
        overall_rating: score,
        communication: score,
        comment: comment || undefined,
      });
      toast.success('Thanks for your rating!');
      onSubmitted?.();
      onClose();
    } catch (e: unknown) {
      const msg = (e as { response?: { data?: { message?: string } } })?.response?.data?.message;
      toast.error(msg || 'Could not submit rating');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="fixed inset-0 bg-black/50 z-50 flex items-end sm:items-center justify-center p-4">
      <div className="bg-card rounded-2xl w-full max-w-md p-6">
        <h3 className="font-bold text-lg text-foreground mb-2">Rate this errand</h3>
        <p className="text-sm text-muted-foreground mb-4">How was your experience?</p>
        <div className="flex gap-2 mb-4">
          {[1, 2, 3, 4, 5].map((n) => (
            <button
              key={n}
              type="button"
              onClick={() => setScore(n)}
              className={`flex-1 py-3 rounded-xl font-bold ${score >= n ? 'bg-[#FF6B00] text-white' : 'bg-gray-100 text-gray-400'}`}
            >
              {n}
            </button>
          ))}
        </div>
        <textarea
          value={comment}
          onChange={(e) => setComment(e.target.value)}
          placeholder="Optional comment"
          rows={3}
          className="w-full border border-input rounded-xl px-4 py-3 text-sm mb-4 resize-none"
        />
        <div className="flex gap-3">
          <button type="button" onClick={onClose} className="flex-1 py-3 rounded-xl border border-input text-foreground font-medium">
            Skip
          </button>
          <button type="button" onClick={submit} disabled={loading} className="flex-1 errandly-btn-primary disabled:opacity-50">
            {loading ? 'Submitting…' : 'Submit'}
          </button>
        </div>
      </div>
    </div>
  );
}
