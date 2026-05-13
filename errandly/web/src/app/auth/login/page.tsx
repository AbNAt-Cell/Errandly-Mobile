'use client';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Package, Eye, EyeOff, Loader2 } from 'lucide-react';
import toast from 'react-hot-toast';
import { useAuthStore } from '@/store/authStore';

const schema = z.object({
  login: z.string().min(1, 'Email or phone required'),
  password: z.string().min(1, 'Password required'),
});

type FormData = z.infer<typeof schema>;

export default function LoginPage() {
  const [showPassword, setShowPassword] = useState(false);
  const { login, roles } = useAuthStore();
  const router = useRouter();

  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const onSubmit = async (data: FormData) => {
    try {
      await login(data);
      toast.success('Welcome back!');

      const currentRoles = useAuthStore.getState().roles;
      if (currentRoles.includes('super_admin') || currentRoles.includes('admin') || currentRoles.includes('verification_officer')) {
        router.push('/admin/dashboard');
      } else if (currentRoles.includes('runner')) {
        router.push('/runner/dashboard');
      } else {
        router.push('/customer/dashboard');
      }
    } catch (error: any) {
      toast.error(error.response?.data?.message || 'Invalid credentials');
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-[#0A1628] to-[#1A2E4A] flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <Link href="/" className="inline-flex items-center gap-2 mb-6">
            <div className="w-10 h-10 bg-[#FF6B00] rounded-xl flex items-center justify-center">
              <Package className="w-6 h-6 text-white" />
            </div>
            <span className="text-2xl font-bold text-white">Errandly</span>
          </Link>
          <h1 className="text-3xl font-bold text-white mb-2">Welcome back</h1>
          <p className="text-gray-400">Sign in to your account</p>
        </div>

        <div className="bg-white rounded-2xl p-8 shadow-2xl">
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Email or Phone</label>
              <input
                {...register('login')}
                className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00] focus:border-transparent transition"
                placeholder="email@example.com or +234..."
              />
              {errors.login && <p className="text-red-500 text-xs mt-1">{errors.login.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Password</label>
              <div className="relative">
                <input
                  {...register('password')}
                  type={showPassword ? 'text' : 'password'}
                  className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00] focus:border-transparent transition pr-12"
                  placeholder="Enter your password"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
                >
                  {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                </button>
              </div>
              {errors.password && <p className="text-red-500 text-xs mt-1">{errors.password.message}</p>}
            </div>

            <div className="flex items-center justify-between text-sm">
              <label className="flex items-center gap-2 cursor-pointer">
                <input type="checkbox" className="rounded" />
                <span className="text-gray-600">Remember me</span>
              </label>
              <Link href="/auth/forgot-password" className="text-[#FF6B00] hover:underline">Forgot password?</Link>
            </div>

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full errandly-btn-primary flex items-center justify-center gap-2 disabled:opacity-70 disabled:cursor-not-allowed"
            >
              {isSubmitting ? <Loader2 className="w-5 h-5 animate-spin" /> : null}
              {isSubmitting ? 'Signing in...' : 'Sign In'}
            </button>
          </form>

          <div className="mt-6 text-center text-sm text-gray-600">
            Don't have an account?{' '}
            <Link href="/auth/register" className="text-[#FF6B00] font-semibold hover:underline">Sign up</Link>
          </div>
        </div>
      </div>
    </div>
  );
}
