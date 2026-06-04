'use client';

import { useState } from 'react';
import Link from 'next/link';
import { authApi } from '@/lib/api';
import toast from 'react-hot-toast';

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);

  const submit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await authApi.forgotPassword({ email });
      toast.success('If that email exists, we sent reset instructions.');
    } catch {
      toast.error('Could not send reset email');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0A1628] to-[#1A2E4A] flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl p-8 w-full max-w-md shadow-2xl">
        <h1 className="text-2xl font-bold text-[#0A1628] mb-2">Forgot password</h1>
        <p className="text-gray-500 text-sm mb-6">We will email you a reset link.</p>
        <form onSubmit={submit} className="space-y-4">
          <input
            type="email"
            required
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="you@example.com"
            className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:ring-2 focus:ring-[#FF6B00] outline-none"
          />
          <button type="submit" disabled={loading} className="w-full errandly-btn-primary disabled:opacity-50">
            {loading ? 'Sending…' : 'Send reset link'}
          </button>
        </form>
        <Link href="/auth/login" className="block text-center text-[#FF6B00] text-sm mt-6 hover:underline">
          Back to login
        </Link>
      </div>
    </div>
  );
}
