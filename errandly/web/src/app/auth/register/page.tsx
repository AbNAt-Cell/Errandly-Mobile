'use client';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { Loader2, User, Zap } from 'lucide-react';
import toast from 'react-hot-toast';
import { authApi } from '@/lib/api';
import { useAuthStore } from '@/store/authStore';
import Logo from '@/components/shared/Logo';

const schema = z.object({
  first_name: z.string().min(2, 'First name must be at least 2 characters'),
  last_name: z.string().min(2, 'Last name must be at least 2 characters'),
  email: z.string().email('Valid email required'),
  phone: z.string().min(10, 'Valid phone number required'),
  password: z.string().min(8, 'Password must be at least 8 characters')
    .regex(/[A-Z]/, 'Must contain uppercase letter')
    .regex(/[0-9]/, 'Must contain a number'),
  password_confirmation: z.string(),
  referral_code: z.string().optional(),
}).refine((d) => d.password === d.password_confirmation, {
  message: 'Passwords do not match',
  path: ['password_confirmation'],
});

type FormData = z.infer<typeof schema>;

export default function RegisterPage() {
  const searchParams = useSearchParams();
  const defaultRole = searchParams.get('role') === 'runner' ? 'runner' : 'customer';
  const [userType, setUserType] = useState<'customer' | 'runner'>(defaultRole);
  const router = useRouter();
  const { establishSession } = useAuthStore();

  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const onSubmit = async (data: FormData) => {
    try {
      const apiCall = userType === 'customer'
        ? authApi.registerCustomer(data)
        : authApi.registerRunner(data);

      const response = await apiCall;
      const { user, token } = response.data;

      if (token && user) {
        establishSession({ user, token, roles: [userType] });
      }

      toast.success('Account created! Please verify your phone number.');
      router.push(`/auth/verify-phone?role=${userType}`);
    } catch (error: any) {
      const errs = error.response?.data?.errors;
      if (errs) {
        Object.values(errs).flat().forEach((msg: any) => toast.error(msg));
      } else {
        toast.error(error.response?.data?.message || 'Registration failed');
      }
    }
  };

  return (
    <div className="min-h-screen bg-[#0E0F13] text-[#e3e2e7] flex items-center justify-center p-4 relative overflow-hidden py-12">
      {/* Background Ambient Glow */}
      <div className="absolute -z-10 w-[500px] h-[500px] bg-[#F97316]/10 blur-[120px] rounded-full top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none" />

      <div className="w-full max-w-lg relative z-10">
        <div className="text-center mb-8">
          <div className="mb-6 flex justify-center">
            <Logo iconSize="w-12 h-12" textSize="text-3xl" />
          </div>
          <h1 className="font-['Bricolage_Grotesque'] text-3xl font-extrabold text-white mb-2">
            Create Account
          </h1>
          <p className="font-['Inter'] text-[#e0c0b1] text-sm">
            Join thousands on Errand
          </p>
        </div>

        {/* Role selector */}
        <div className="flex gap-3 mb-6">
          <button
            type="button"
            onClick={() => setUserType('customer')}
            className={`flex-1 flex items-center justify-center gap-2 py-3.5 rounded-xl font-['Bricolage_Grotesque'] font-bold text-sm transition-all ${
              userType === 'customer'
                ? 'bg-[#F97316] text-[#121317] shadow-lg shadow-[#F97316]/20'
                : 'bg-[#17191F] text-[#e0c0b1] border border-white/10 hover:border-white/20'
            }`}
          >
            <User className="w-5 h-5" />
            I need errands done
          </button>
          <button
            type="button"
            onClick={() => setUserType('runner')}
            className={`flex-1 flex items-center justify-center gap-2 py-3.5 rounded-xl font-['Bricolage_Grotesque'] font-bold text-sm transition-all ${
              userType === 'runner'
                ? 'bg-[#F97316] text-[#121317] shadow-lg shadow-[#F97316]/20'
                : 'bg-[#17191F] text-[#e0c0b1] border border-white/10 hover:border-white/20'
            }`}
          >
            <Zap className="w-5 h-5" />
            I want to be a Runner
          </button>
        </div>

        <div className="bg-[#17191F] rounded-2xl p-8 shadow-2xl border border-white/10">
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-[#e0c0b1] mb-1 font-['Inter']">First Name</label>
                <input
                  {...register('first_name')}
                  className="w-full px-4 py-3 bg-[#121317] border border-white/10 text-white rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316] focus:border-transparent transition placeholder-gray-500 font-['Inter']"
                  placeholder="Ada"
                />
                {errors.first_name && <p className="text-red-400 text-xs mt-1">{errors.first_name.message}</p>}
              </div>
              <div>
                <label className="block text-sm font-medium text-[#e0c0b1] mb-1 font-['Inter']">Last Name</label>
                <input
                  {...register('last_name')}
                  className="w-full px-4 py-3 bg-[#121317] border border-white/10 text-white rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316] focus:border-transparent transition placeholder-gray-500 font-['Inter']"
                  placeholder="Okafor"
                />
                {errors.last_name && <p className="text-red-400 text-xs mt-1">{errors.last_name.message}</p>}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-[#e0c0b1] mb-1 font-['Inter']">Email</label>
              <input
                {...register('email')}
                type="email"
                autoComplete="email"
                className="w-full px-4 py-3 bg-[#121317] border border-white/10 text-white rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316] focus:border-transparent transition placeholder-gray-500 font-['Inter']"
                placeholder="ada@example.com"
              />
              {errors.email && <p className="text-red-400 text-xs mt-1">{errors.email.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-[#e0c0b1] mb-1 font-['Inter']">Phone Number</label>
              <input
                {...register('phone')}
                type="tel"
                autoComplete="tel"
                className="w-full px-4 py-3 bg-[#121317] border border-white/10 text-white rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316] focus:border-transparent transition placeholder-gray-500 font-['Inter']"
                placeholder="+2348100000000"
              />
              {errors.phone && <p className="text-red-400 text-xs mt-1">{errors.phone.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-[#e0c0b1] mb-1 font-['Inter']">Password</label>
              <input
                {...register('password')}
                type="password"
                autoComplete="new-password"
                className="w-full px-4 py-3 bg-[#121317] border border-white/10 text-white rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316] focus:border-transparent transition placeholder-gray-500 font-['Inter']"
                placeholder="Min 8 chars, uppercase, number"
              />
              {errors.password && <p className="text-red-400 text-xs mt-1">{errors.password.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-[#e0c0b1] mb-1 font-['Inter']">Confirm Password</label>
              <input
                {...register('password_confirmation')}
                type="password"
                autoComplete="new-password"
                className="w-full px-4 py-3 bg-[#121317] border border-white/10 text-white rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316] focus:border-transparent transition placeholder-gray-500 font-['Inter']"
                placeholder="Repeat password"
              />
              {errors.password_confirmation && <p className="text-red-400 text-xs mt-1">{errors.password_confirmation.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-[#e0c0b1] mb-1 font-['Inter']">Referral Code (optional)</label>
              <input
                {...register('referral_code')}
                className="w-full px-4 py-3 bg-[#121317] border border-white/10 text-white rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316] focus:border-transparent transition placeholder-gray-500 font-['Inter']"
                placeholder="Enter referral code"
              />
            </div>

            {userType === 'runner' && (
              <div className="bg-[#F97316]/10 border border-[#F97316]/30 rounded-xl p-4 text-xs text-[#e0c0b1] leading-relaxed">
                As a runner, you will complete identity verification (KYC) before accepting errands. This includes government ID, selfie, and bank payout details.
              </div>
            )}

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full bg-[#F97316] hover:bg-[#EA580C] text-[#121317] font-['Bricolage_Grotesque'] font-bold py-3.5 px-6 rounded-xl transition-all active:scale-95 hover:shadow-[0_0_20px_rgba(249,115,22,0.4)] flex items-center justify-center gap-2 disabled:opacity-70 disabled:cursor-not-allowed mt-2"
            >
              {isSubmitting && <Loader2 className="w-5 h-5 animate-spin" />}
              {isSubmitting ? 'Creating account...' : `Create ${userType === 'customer' ? 'Customer' : 'Runner'} Account`}
            </button>
          </form>

          <p className="mt-4 text-xs text-gray-400 text-center">
            By registering, you agree to our{' '}
            <Link href="/terms" className="text-[#F97316] hover:underline">Terms of Service</Link> and{' '}
            <Link href="/privacy" className="text-[#F97316] hover:underline">Privacy Policy</Link>
          </p>

          <div className="mt-4 text-center text-sm text-[#e0c0b1]">
            Already have an account?{' '}
            <Link href="/auth/login" className="text-[#F97316] font-semibold hover:underline">Sign in</Link>
          </div>
        </div>
      </div>
    </div>
  );
}
