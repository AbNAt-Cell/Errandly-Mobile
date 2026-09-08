'use client';

import { FormEvent, useMemo, useState } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { ArrowLeft, ArrowRight, Eye, EyeOff, Loader2, Zap } from 'lucide-react';
import toast from 'react-hot-toast';
import { useAuthStore } from '@/store/authStore';
import { ThemeToggle } from '@/components/shared/ThemeToggle';

type Step = 'welcome' | 'identity' | 'password';

function routeAfterLogin(roles: string[]) {
  if (roles.some((r) => ['super_admin', 'admin', 'verification_officer'].includes(r))) {
    return '/admin/dashboard';
  }
  if (roles.includes('runner')) return '/runner/dashboard';
  return '/customer/dashboard';
}

export default function LoginPage() {
  const router = useRouter();
  const { login } = useAuthStore();

  const [step, setStep] = useState<Step>('welcome');
  const [loginId, setLoginId] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [fieldError, setFieldError] = useState('');

  const progress = useMemo(() => {
    if (step === 'welcome') return 1;
    if (step === 'identity') return 2;
    return 3;
  }, [step]);

  const goIdentity = () => {
    setFieldError('');
    setStep('identity');
  };

  const goPassword = (e?: FormEvent) => {
    e?.preventDefault();
    const value = loginId.trim();
    if (!value) {
      setFieldError('Please enter your email or phone number.');
      return;
    }
    if (value.length > 120) {
      setFieldError('That looks a bit long — try your email or phone.');
      return;
    }
    setFieldError('');
    setStep('password');
  };

  const submitLogin = async (e: FormEvent) => {
    e.preventDefault();
    if (!password) {
      setFieldError('Enter your password to continue.');
      return;
    }
    setFieldError('');
    setSubmitting(true);
    try {
      await login({ login: loginId.trim(), password });
      toast.success('Welcome back!');
      const roles = useAuthStore.getState().roles;
      router.push(routeAfterLogin(roles));
    } catch (error: unknown) {
      const message =
        (error as { response?: { data?: { message?: string } } })?.response?.data?.message ||
        'Those details did not match. Try again.';
      toast.error(message);
      setFieldError(message);
    } finally {
      setSubmitting(false);
    }
  };

  return (
    <div className="min-h-screen bg-background text-foreground flex flex-col">
      <header className="flex items-center justify-between page-gutter py-4 border-b border-border">
        <Link href="/" className="inline-flex items-center gap-2">
          <div className="w-9 h-9 bg-primary rounded-lg flex items-center justify-center">
            <Zap className="w-5 h-5 text-primary-foreground fill-primary-foreground" />
          </div>
            <span className="font-headline text-lg font-semibold text-primary">DOOYN</span>
        </Link>
        <div className="flex items-center gap-3">
          <ThemeToggle />
          <Link href="/auth/register" className="text-sm font-medium text-muted-foreground hover:text-primary">
            Create account
          </Link>
        </div>
      </header>

      <main className="flex-1 flex items-center justify-center page-gutter py-10">
        <div className="w-full max-w-lg">
          <div className="flex items-center gap-2 mb-8" aria-label={`Step ${progress} of 3`}>
            {[1, 2, 3].map((n) => (
              <div
                key={n}
                className={`h-1.5 flex-1 rounded-full transition-colors ${n <= progress ? 'bg-primary' : 'bg-muted'}`}
              />
            ))}
          </div>

          <div className="space-y-4 mb-8 min-h-[120px]">
            <div className="flex gap-3">
              <div className="w-9 h-9 rounded-full bg-primary/15 text-primary flex items-center justify-center shrink-0 font-display font-bold text-sm">
                D
              </div>
              <div className="bg-card border border-border rounded-2xl rounded-tl-md px-4 py-3 shadow-sm max-w-[90%]">
                {step === 'welcome' && (
                  <p className="text-sm leading-relaxed">
                    Hey — welcome back to DOOYN. Ready to pick up where you left off in Uyo?
                  </p>
                )}
                {step === 'identity' && (
                  <p className="text-sm leading-relaxed">
                    Great. What email or phone number do you use with DOOYN?
                  </p>
                )}
                {step === 'password' && (
                  <p className="text-sm leading-relaxed">
                    Nice to see you{loginId.includes('@') ? '' : ''}. Enter your password to get in securely.
                  </p>
                )}
              </div>
            </div>

            {step === 'password' && loginId.trim() && (
              <div className="flex gap-3 justify-end">
                <div className="bg-primary text-primary-foreground rounded-2xl rounded-tr-md px-4 py-3 max-w-[85%] text-sm">
                  {loginId.trim()}
                </div>
              </div>
            )}
          </div>

          <div className="bg-card border border-border rounded-2xl p-6 shadow-sm">
            {step === 'welcome' && (
              <div className="space-y-4">
                <button
                  type="button"
                  onClick={goIdentity}
                  className="w-full errandly-btn-primary inline-flex items-center justify-center gap-2"
                >
                  Yes, sign me in <ArrowRight className="w-4 h-4" />
                </button>
                <p className="text-center text-sm text-muted-foreground">
                  New here?{' '}
                  <Link href="/auth/register" className="text-primary font-semibold hover:underline">
                    Start your journey
                  </Link>
                </p>
              </div>
            )}

            {step === 'identity' && (
              <form onSubmit={goPassword} className="space-y-4">
                <div>
                  <label htmlFor="login-id" className="block text-sm font-medium mb-1.5">
                    Email or phone
                  </label>
                  <input
                    id="login-id"
                    autoFocus
                    autoComplete="username"
                    value={loginId}
                    onChange={(e) => setLoginId(e.target.value)}
                    className="w-full px-4 py-3 border border-input bg-background rounded-xl focus:outline-none focus:ring-2 focus:ring-primary"
                    placeholder="you@email.com or +234…"
                    maxLength={120}
                  />
                  {fieldError && <p className="text-red-500 text-xs mt-1.5">{fieldError}</p>}
                </div>
                <div className="flex gap-3">
                  <button
                    type="button"
                    onClick={() => {
                      setFieldError('');
                      setStep('welcome');
                    }}
                    className="px-4 py-3 rounded-xl border border-border text-sm font-medium hover:bg-muted inline-flex items-center gap-1"
                  >
                    <ArrowLeft className="w-4 h-4" /> Back
                  </button>
                  <button type="submit" className="flex-1 errandly-btn-primary inline-flex items-center justify-center gap-2">
                    Continue <ArrowRight className="w-4 h-4" />
                  </button>
                </div>
              </form>
            )}

            {step === 'password' && (
              <form onSubmit={submitLogin} className="space-y-4">
                <div>
                  <label htmlFor="login-password" className="block text-sm font-medium mb-1.5">
                    Password
                  </label>
                  <div className="relative">
                    <input
                      id="login-password"
                      autoFocus
                      autoComplete="current-password"
                      type={showPassword ? 'text' : 'password'}
                      value={password}
                      onChange={(e) => setPassword(e.target.value)}
                      className="w-full px-4 py-3 border border-input bg-background rounded-xl focus:outline-none focus:ring-2 focus:ring-primary pr-12"
                      placeholder="Your password"
                      maxLength={128}
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword((v) => !v)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
                      aria-label={showPassword ? 'Hide password' : 'Show password'}
                    >
                      {showPassword ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
                    </button>
                  </div>
                  {fieldError && <p className="text-red-500 text-xs mt-1.5">{fieldError}</p>}
                </div>
                <div className="flex justify-between text-sm">
                  <button
                    type="button"
                    onClick={() => {
                      setFieldError('');
                      setPassword('');
                      setStep('identity');
                    }}
                    className="text-muted-foreground hover:text-foreground inline-flex items-center gap-1"
                  >
                    <ArrowLeft className="w-4 h-4" /> Change email/phone
                  </button>
                  <Link href="/auth/forgot-password" className="text-primary hover:underline">
                    Forgot password?
                  </Link>
                </div>
                <button
                  type="submit"
                  disabled={submitting}
                  className="w-full errandly-btn-primary inline-flex items-center justify-center gap-2 disabled:opacity-70"
                >
                  {submitting ? <Loader2 className="w-5 h-5 animate-spin" /> : null}
                  {submitting ? 'Signing you in…' : 'Sign in'}
                </button>
              </form>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}
