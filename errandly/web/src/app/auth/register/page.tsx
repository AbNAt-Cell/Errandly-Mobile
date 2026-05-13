'use client';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Package, Loader2, User, Zap } from 'lucide-react';
import toast from 'react-hot-toast';
import { authApi } from '@/lib/api';
import { useAuthStore } from '@/store/authStore';

const schema = z.object({
  first_name: z.string().min(2, 'First name required'),
  last_name: z.string().min(2, 'Last name required'),
  email: z.string().email('Valid email required'),
  phone: z.string().min(10, 'Valid phone required'),
  password: z.string().min(8, 'Min 8 characters').regex(/[A-Z]/, 'Must contain uppercase').regex(/[0-9]/, 'Must contain number'),
  password_confirmation: z.string(),
  referral_code: z.string().optional(),
}).refine((d) => d.password === d.password_confirmation, {
  message: 'Passwords do not match',
  path: ['password_confirmation'],
});

type FormData = z.infer<typeof schema>;

export default function RegisterPage() {
  const [userType, setUserType] = useState<'customer' | 'runner'>('customer');
  const router = useRouter();
  const { setUser } = useAuthStore();

  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const onSubmit = async (data: FormData) => {
    try {
      const fn = userType === 'customer' ? authApi.registerCustomer : authApi.registerRunner;

      const payload = userType === 'runner'
        ? { ...data, city: 'Uyo', state: 'Akwa Ibom', transport_type: 'foot' }
        : data;

      const response = await fn(payload);
      const { token, user } = response.data;

      localStorage.setItem('errandly_token', token);
      setUser(user);

      toast.success('Account created! Please verify your phone number.');

      router.push(userType === 'customer' ? '/customer/verify' : '/runner/verify');
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
    <div className="min-h-screen bg-gradient-to-br from-[#0A1628] to-[#1A2E4A] flex items-center justify-center p-4">
      <div className="w-full max-w-lg">
        <div className="text-center mb-8">
          <Link href="/" className="inline-flex items-center gap-2 mb-6">
            <div className="w-10 h-10 bg-[#FF6B00] rounded-xl flex items-center justify-center">
              <Package className="w-6 h-6 text-white" />
            </div>
            <span className="text-2xl font-bold text-white">Errandly</span>
          </Link>
          <h1 className="text-3xl font-bold text-white mb-2">Create Account</h1>
          <p className="text-gray-400">Join thousands on Errandly</p>
        </div>

        {/* Role selector */}
        <div className="flex gap-3 mb-6">
          <button
            onClick={() => setUserType('customer')}
            className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-xl font-semibold transition-all ${
              userType === 'customer'
                ? 'bg-[#FF6B00] text-white'
                : 'bg-white/10 text-white border border-white/20 hover:bg-white/20'
            }`}
          >
            <User className="w-5 h-5" />
            I need errands done
          </button>
          <button
            onClick={() => setUserType('runner')}
            className={`flex-1 flex items-center justify-center gap-2 py-3 rounded-xl font-semibold transition-all ${
              userType === 'runner'
                ? 'bg-[#FF6B00] text-white'
                : 'bg-white/10 text-white border border-white/20 hover:bg-white/20'
            }`}
          >
            <Zap className="w-5 h-5" />
            I want to be a Runner
          </button>
        </div>

        <div className="bg-white rounded-2xl p-8 shadow-2xl">
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div className="grid grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">First Name</label>
                <input {...register('first_name')} className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00]" placeholder="Ada" />
                {errors.first_name && <p className="text-red-500 text-xs mt-1">{errors.first_name.message}</p>}
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Last Name</label>
                <input {...register('last_name')} className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00]" placeholder="Okafor" />
                {errors.last_name && <p className="text-red-500 text-xs mt-1">{errors.last_name.message}</p>}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Email</label>
              <input {...register('email')} type="email" className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00]" placeholder="ada@example.com" />
              {errors.email && <p className="text-red-500 text-xs mt-1">{errors.email.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Phone Number</label>
              <input {...register('phone')} className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00]" placeholder="+2348100000000" />
              {errors.phone && <p className="text-red-500 text-xs mt-1">{errors.phone.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
              <input {...register('password')} type="password" className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00]" placeholder="Min 8 chars, uppercase, number" />
              {errors.password && <p className="text-red-500 text-xs mt-1">{errors.password.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Confirm Password</label>
              <input {...register('password_confirmation')} type="password" className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00]" placeholder="Repeat password" />
              {errors.password_confirmation && <p className="text-red-500 text-xs mt-1">{errors.password_confirmation.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Referral Code (optional)</label>
              <input {...register('referral_code')} className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00]" placeholder="Enter referral code" />
            </div>

            {userType === 'runner' && (
              <div className="bg-orange-50 border border-orange-200 rounded-xl p-4 text-sm text-orange-800">
                As a runner, you will need to complete identity verification (KYC) before accepting errands. This includes government ID, selfie, and bank account details.
              </div>
            )}

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full errandly-btn-primary flex items-center justify-center gap-2 disabled:opacity-70"
            >
              {isSubmitting && <Loader2 className="w-5 h-5 animate-spin" />}
              {isSubmitting ? 'Creating account...' : `Create ${userType === 'customer' ? 'Customer' : 'Runner'} Account`}
            </button>
          </form>

          <p className="mt-4 text-xs text-gray-500 text-center">
            By registering, you agree to our{' '}
            <Link href="/terms" className="text-[#FF6B00]">Terms of Service</Link> and{' '}
            <Link href="/privacy" className="text-[#FF6B00]">Privacy Policy</Link>
          </p>

          <div className="mt-4 text-center text-sm text-gray-600">
            Already have an account?{' '}
            <Link href="/auth/login" className="text-[#FF6B00] font-semibold hover:underline">Sign in</Link>
          </div>
        </div>
      </div>
    </div>
  );
}
