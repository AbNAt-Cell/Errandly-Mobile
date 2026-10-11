'use client';

import { useState } from 'react';
import Link from 'next/link';
import { authApi } from '@/lib/api';
import toast from 'react-hot-toast';
import Logo from '@/components/shared/Logo';
import { ThemeToggle } from '@/components/shared/ThemeToggle';

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
    <div className="min-h-screen bg-slate-50 text-slate-900 dark:bg-[#0E0F13] dark:text-[#e3e2e7] flex items-center justify-center p-4 relative overflow-hidden transition-colors">
      <div className="absolute top-4 right-4 z-20">
        <ThemeToggle />
      </div>

      <div className="absolute -z-10 w-[500px] h-[500px] bg-[#F97316]/10 blur-[120px] rounded-full top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none" />

      <div className="w-full max-w-md relative z-10">
        <div className="text-center mb-8">
          <div className="mb-6 flex justify-center">
            <Logo iconSize="w-12 h-12" textSize="text-3xl" />
          </div>
          <h1 className="font-['Bricolage_Grotesque'] text-3xl font-extrabold text-slate-900 dark:text-white mb-2">
            Forgot Password
          </h1>
          <p className="font-['Inter'] text-slate-600 dark:text-[#e0c0b1] text-sm">
            We will email you password reset instructions
          </p>
        </div>

        <div className="bg-white dark:bg-[#17191F] rounded-2xl p-8 shadow-xl dark:shadow-2xl border border-slate-200 dark:border-white/10 transition-colors">
          <form onSubmit={submit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-[#e0c0b1] mb-1.5 font-['Inter']">
                Email Address
              </label>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@example.com"
                className="w-full px-4 py-3 bg-slate-50 dark:bg-[#121317] border border-slate-200 dark:border-white/10 text-slate-900 dark:text-white rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316] font-['Inter'] placeholder-slate-400 dark:placeholder-gray-500"
              />
            </div>
            <button
              type="submit"
              disabled={loading}
              className="w-full bg-[#F97316] hover:bg-[#EA580C] text-[#121317] font-['Bricolage_Grotesque'] font-bold py-3.5 px-6 rounded-xl transition-all active:scale-95 hover:shadow-[0_0_20px_rgba(249,115,22,0.4)] disabled:opacity-50 mt-2"
            >
              {loading ? 'Sending…' : 'Send Reset Link'}
            </button>
          </form>
          <Link
            href="/auth/login"
            className="block text-center text-[#F97316] text-sm mt-6 hover:underline font-semibold"
          >
            Back to login
          </Link>
        </div>
      </div>
    </div>
  );
}
