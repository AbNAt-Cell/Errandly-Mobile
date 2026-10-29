'use client';
import { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Eye, EyeOff, Loader2 } from 'lucide-react';
import toast from 'react-hot-toast';
import { useAuthStore } from '@/store/authStore';
import Logo from '@/components/shared/Logo';
import { ThemeToggle } from '@/components/shared/ThemeToggle';
import GoogleSignInButton from '@/components/shared/GoogleSignInButton';

const schema = z.object({
  login: z.string().min(1, 'Email or phone required'),
  password: z.string().min(1, 'Password required'),
});

type FormData = z.infer<typeof schema>;

export default function LoginPage() {
  const [showPassword, setShowPassword] = useState(false);
  const { login, isAuthenticated, roles, _hasHydrated } = useAuthStore();
  const router = useRouter();

  useEffect(() => {
    // If user is already authenticated in localStorage or store, redirect directly
    if (typeof window !== 'undefined') {
      try {
        const raw = localStorage.getItem('errand-auth');
        const token = localStorage.getItem('errand_token');
        if (raw) {
          const parsed = JSON.parse(raw);
          const state = parsed?.state;
          if (state?.isAuthenticated && (state?.token || token)) {
            const userRoles: string[] = state.roles || [];
            if (userRoles.includes('super_admin') || userRoles.includes('admin') || userRoles.includes('verification_officer')) {
              router.replace('/admin/dashboard');
            } else if (userRoles.includes('runner')) {
              router.replace('/runner/dashboard');
            } else {
              router.replace('/customer/dashboard');
            }
            return;
          }
        }
      } catch {
        // ignore
      }
    }

    if (_hasHydrated && isAuthenticated) {
      if (roles.includes('super_admin') || roles.includes('admin') || roles.includes('verification_officer')) {
        router.replace('/admin/dashboard');
      } else if (roles.includes('runner')) {
        router.replace('/runner/dashboard');
      } else {
        router.replace('/customer/dashboard');
      }
    }
  }, [isAuthenticated, roles, _hasHydrated, router]);

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
    <div className="min-h-screen bg-slate-50 text-slate-900 dark:bg-[#0E0F13] dark:text-[#e3e2e7] flex items-center justify-center p-4 relative overflow-hidden transition-colors">
      {/* Top right theme toggle */}
      <div className="absolute top-4 right-4 z-20">
        <ThemeToggle />
      </div>

      {/* Background Ambient Glow */}
      <div className="absolute -z-10 w-[500px] h-[500px] bg-[#F97316]/10 blur-[120px] rounded-full top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 pointer-events-none" />

      <div className="w-full max-w-md relative z-10">
        <div className="text-center mb-8">
          <div className="mb-6 flex justify-center">
            <Logo iconSize="w-12 h-12" textSize="text-3xl" />
          </div>
          <h1 className="font-['Bricolage_Grotesque'] text-3xl font-extrabold text-slate-900 dark:text-white mb-2">
            Welcome back
          </h1>
          <p className="font-['Inter'] text-slate-600 dark:text-[#e0c0b1] text-sm">
            Sign in to your account
          </p>
        </div>

        <div className="bg-white dark:bg-[#17191F] rounded-2xl p-8 shadow-xl dark:shadow-2xl border border-slate-200 dark:border-white/10 transition-colors">
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-5">
            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-[#e0c0b1] mb-1.5 font-['Inter']">
                Email or Phone
              </label>
              <input
                {...register('login')}
                type="text"
                autoComplete="username"
                className="w-full px-4 py-3 bg-slate-50 dark:bg-[#121317] border border-slate-200 dark:border-white/10 text-slate-900 dark:text-white rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316] focus:border-transparent transition placeholder-slate-400 dark:placeholder-gray-500 font-['Inter']"
                placeholder="email@example.com or +234..."
              />
              {errors.login && <p className="text-red-500 text-xs mt-1">{errors.login.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-slate-700 dark:text-[#e0c0b1] mb-1.5 font-['Inter']">
                Password
              </label>
              <div className="relative">
                <input
                  {...register('password')}
                  type={showPassword ? 'text' : 'password'}
                  autoComplete="current-password"
                  className="w-full px-4 py-3 bg-slate-50 dark:bg-[#121317] border border-slate-200 dark:border-white/10 text-slate-900 dark:text-white rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316] focus:border-transparent transition pr-12 placeholder-slate-400 dark:placeholder-gray-500 font-['Inter']"
                  placeholder="Enter your password"
                />
                <button
                  type="button"
                  onClick={() => setShowPassword(!showPassword)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 dark:text-gray-400 dark:hover:text-white transition"
                >
                  {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                </button>
              </div>
              {errors.password && <p className="text-red-500 text-xs mt-1">{errors.password.message}</p>}
            </div>

            <div className="flex items-center justify-between text-sm">
              <label className="flex items-center gap-2 cursor-pointer">
                <input type="checkbox" className="rounded bg-slate-100 dark:bg-[#121317] border-slate-300 dark:border-white/20 accent-[#F97316]" />
                <span className="text-slate-600 dark:text-[#e0c0b1] text-xs">Remember me</span>
              </label>
              <Link href="/auth/forgot-password" className="text-[#F97316] hover:underline text-xs font-medium">
                Forgot password?
              </Link>
            </div>

            <button
              type="submit"
              disabled={isSubmitting}
              className="w-full bg-[#F97316] hover:bg-[#EA580C] text-[#121317] font-['Bricolage_Grotesque'] font-bold py-3.5 px-6 rounded-xl transition-all active:scale-95 hover:shadow-[0_0_20px_rgba(249,115,22,0.4)] flex items-center justify-center gap-2 disabled:opacity-70 disabled:cursor-not-allowed"
            >
              {isSubmitting ? <Loader2 className="w-5 h-5 animate-spin" /> : null}
              {isSubmitting ? 'Signing in...' : 'Sign In'}
            </button>
          </form>

          <GoogleSignInButton role="customer" />

          <div className="mt-6 text-center text-sm text-slate-600 dark:text-[#e0c0b1]">
            Don't have an account?{' '}
            <Link href="/auth/register" className="text-[#F97316] font-semibold hover:underline">
              Sign up
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
}
