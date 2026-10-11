'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { authApi } from '@/lib/api';
import { useAuthStore } from '@/store/authStore';
import toast from 'react-hot-toast';
import Logo from '@/components/shared/Logo';

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
    <div className="min-h-screen bg-[#0E0F13] text-[#e3e2e7] flex items-center justify-center p-4 relative overflow-hidden">
      <div className="absolute -z-10 w-[500px] h-[500px] bg-[#F97316]/10 blur-[120px] rounded-full top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none" />

      <div className="w-full max-w-md relative z-10">
        <div className="text-center mb-8">
          <div className="mb-6 flex justify-center">
            <Logo iconSize="w-12 h-12" textSize="text-3xl" />
          </div>
          <h1 className="font-['Bricolage_Grotesque'] text-3xl font-extrabold text-white mb-2">
            Verify Phone
          </h1>
          <p className="font-['Inter'] text-[#e0c0b1] text-sm">
            Enter the 6-digit verification code sent to your phone
          </p>
        </div>

        <div className="bg-[#17191F] rounded-2xl p-8 shadow-2xl border border-white/10">
          <form onSubmit={verify} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-[#e0c0b1] mb-1 font-['Inter']">
                Phone Number
              </label>
              <input
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="+234…"
                className="w-full px-4 py-3 bg-[#121317] border border-white/10 text-white rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316] font-['Inter']"
                readOnly={!!user?.phone}
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-[#e0c0b1] mb-1 font-['Inter']">
                6-Digit OTP
              </label>
              <input
                value={otp}
                onChange={(e) => setOtp(e.target.value.replace(/\D/g, '').slice(0, 6))}
                placeholder="••••••"
                maxLength={6}
                className="w-full px-4 py-3 bg-[#121317] border border-white/10 text-white rounded-xl text-center tracking-widest text-2xl font-bold focus:outline-none focus:ring-2 focus:ring-[#F97316]"
              />
            </div>
            <button
              type="submit"
              disabled={loading || otp.length !== 6}
              className="w-full bg-[#F97316] hover:bg-[#EA580C] text-[#121317] font-['Bricolage_Grotesque'] font-bold py-3.5 px-6 rounded-xl transition-all active:scale-95 hover:shadow-[0_0_20px_rgba(249,115,22,0.4)] disabled:opacity-50 disabled:cursor-not-allowed mt-2"
            >
              {loading ? 'Verifying…' : 'Verify Phone'}
            </button>
          </form>

          <button
            type="button"
            onClick={resend}
            className="w-full text-[#F97316] hover:underline text-sm mt-4 font-semibold text-center block"
          >
            Resend OTP
          </button>
          <Link
            href={dashboardHref}
            className="block text-center text-gray-400 text-xs mt-3 hover:text-white transition-colors"
          >
            Skip for now
          </Link>
        </div>
      </div>
    </div>
  );
}
