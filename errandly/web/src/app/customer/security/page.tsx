'use client';

import { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { authApi } from '@/lib/api';
import Link from 'next/link';
import { ArrowLeft, Lock } from 'lucide-react';
import toast from 'react-hot-toast';

export default function CustomerSecurityPage() {
  const [currentPassword, setCurrentPassword] = useState('');
  const [password, setPassword] = useState('');
  const [passwordConfirmation, setPasswordConfirmation] = useState('');

  const mutation = useMutation({
    mutationFn: () =>
      authApi.changePassword({
        current_password: currentPassword,
        password,
        password_confirmation: passwordConfirmation,
      }),
    onSuccess: () => {
      toast.success('Password updated.');
      setCurrentPassword('');
      setPassword('');
      setPasswordConfirmation('');
    },
    onError: (e: { response?: { data?: { message?: string } } }) => {
      toast.error(e.response?.data?.message || 'Could not update password');
    },
  });

  return (
    <div className="p-4 pb-24 max-w-lg mx-auto">
      <div className="flex items-center gap-3 mb-6">
        <Link href="/customer/profile" className="p-2 rounded-lg hover:bg-muted">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="font-bold text-xl text-foreground">Security</h1>
      </div>

      <div className="bg-card rounded-2xl border border-border p-4 space-y-4">
        <p className="flex items-center gap-2 text-muted-foreground text-sm mb-2">
          <Lock className="w-4 h-4" />
          Change password
        </p>
        <input
          type="password"
          value={currentPassword}
          onChange={(e) => setCurrentPassword(e.target.value)}
          placeholder="Current password"
          className="w-full border border-input rounded-xl px-4 py-3 text-sm"
        />
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          placeholder="New password"
          className="w-full border border-input rounded-xl px-4 py-3 text-sm"
        />
        <input
          type="password"
          value={passwordConfirmation}
          onChange={(e) => setPasswordConfirmation(e.target.value)}
          placeholder="Confirm new password"
          className="w-full border border-input rounded-xl px-4 py-3 text-sm"
        />
        <button
          type="button"
          onClick={() => mutation.mutate()}
          disabled={mutation.isPending}
          className="w-full errandly-btn-primary disabled:opacity-50"
        >
          {mutation.isPending ? 'Updating…' : 'Update password'}
        </button>
      </div>
    </div>
  );
}
