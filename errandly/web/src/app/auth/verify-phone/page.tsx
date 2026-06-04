'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { authApi } from '@/lib/api';
import { useAuthStore } from '@/store/authStore';
import toast from 'react-hot-toast';

export default function VerifyPhonePage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const roleHint = searchParams.get('role');
  const { user, roles, isAuthenticated, refreshUser } = useAuthStore();
  const [phone, setPhone] = useState('');
  const [otp, setOtp] = useState('');
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    if (user?.phone) {
      setPhone(user.phone);
    }
  }, [user?.phone]);

  useEffect(() => {
    if (!isAuthenticated) {
      router.replace('/auth/login');
    }
  }, [isAuthenticated, router]);

  const dashboardHref =
    roles.includes('runner') || roleHint === 'runner'
      ? '/runner/dashboard'
      : '/customer/dashboard';

  const verify = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    try {
      await authApi.verifyPhone({ phone: phone || user?.phone, otp });
      await refreshUser();
      toast.success('Phone verified!');
      router.push(dashboardHref);
    } catch {
      toast.error('Invalid OTP');
    } finally {
      setLoading(false);
    }
  };

  const resend = async () => {
    try {
      await authApi.resendOtp();
      toast.success('OTP resent');
    } catch {
      toast.error('Could not resend OTP');
    }
  };

  return (
    <div className="min-h-screen bg-gray-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl p-8 w-full max-w-md border border-gray-100">
        <h1 className="text-2xl font-bold text-[#0A1628] mb-2">Verify phone</h1>
        <p className="text-gray-500 text-sm mb-6">Enter the code sent to your phone.</p>
        <form onSubmit={verify} className="space-y-4">
          <input
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            placeholder="+234…"
            className="w-full px-4 py-3 border border-gray-200 rounded-xl"
            readOnly={!!user?.phone}
          />
          <input
            value={otp}
            onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))}
            placeholder="6-digit OTP"
            maxLength={6}
            className="w-full px-4 py-3 border border-gray-200 rounded-xl text-center tracking-widest text-lg"
          />
          <button type="submit" disabled={loading || otp.length !== 6} className="w-full errandly-btn-primary disabled:opacity-50">
            {loading ? 'Verifying…' : 'Verify'}
          </button>
        </form>
        <button type="button" onClick={resend} className="w-full text-[#FF6B00] text-sm mt-4 font-medium">
          Resend OTP
        </button>
        <Link href={dashboardHref} className="block text-center text-gray-500 text-sm mt-4 hover:underline">
          Skip for now
        </Link>
      </div>
    </div>
  );
}
