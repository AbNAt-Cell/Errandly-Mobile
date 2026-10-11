'use client';

import { FormEvent, Suspense, useEffect, useMemo, useState } from 'react';
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

const STEPS: Step[] = ['intent', 'name', 'contact', 'security', 'referral', 'confirm'];

export default function RegisterPage() {
  const searchParams = useSearchParams();
  const defaultRole = searchParams.get('role') === 'runner' ? 'runner' : 'customer';
  const [userType, setUserType] = useState<'customer' | 'runner'>(defaultRole);
  const router = useRouter();
  const searchParams = useSearchParams();
  const { establishSession } = useAuthStore();

  const [step, setStep] = useState<Step>('intent');
  const [role, setRole] = useState<Role>('customer');
  const [firstName, setFirstName] = useState('');
  const [lastName, setLastName] = useState('');
  const [email, setEmail] = useState('');
  const [phone, setPhone] = useState('');
  const [password, setPassword] = useState('');
  const [passwordConfirmation, setPasswordConfirmation] = useState('');
  const [referralCode, setReferralCode] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [fieldError, setFieldError] = useState('');

  useEffect(() => {
    const preset = searchParams.get('role');
    if (preset === 'runner' || preset === 'customer') {
      setRole(preset);
    }
  }, [searchParams]);

  const stepIndex = STEPS.indexOf(step);
  const progress = stepIndex + 1;

  const prompt = useMemo(() => {
    switch (step) {
      case 'intent':
        return 'First things first — what brings you to DOOYN today?';
      case 'name':
        return role === 'runner'
          ? 'Awesome. Runners keep Uyo moving. What should we call you?'
          : 'Perfect. We’ll help you get things done. What should we call you?';
      case 'contact':
        return `Nice to meet you, ${firstName.trim() || 'friend'}. How can we reach you?`;
      case 'security':
        return 'Let’s lock your account down. Choose a strong password.';
      case 'referral':
        return 'Almost there. Got a referral code from a friend? Totally optional.';
      case 'confirm':
        return 'Here’s what I’ve got — ready to create your account?';
      default:
        return '';
    }
  }, [step, role, firstName]);

  const go = (next: Step) => {
    setFieldError('');
    setStep(next);
  };

  const back = () => {
    setFieldError('');
    if (stepIndex > 0) setStep(STEPS[stepIndex - 1]);
  };

  const submitName = (e: FormEvent) => {
    e.preventDefault();
    if (firstName.trim().length < 2 || lastName.trim().length < 2) {
      setFieldError('Please enter your first and last name (at least 2 characters each).');
      return;
    }
    go('contact');
  };

  const submitContact = (e: FormEvent) => {
    e.preventDefault();
    const em = email.trim();
    const ph = phone.trim();
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(em)) {
      setFieldError('Enter a valid email address.');
      return;
    }
    if (ph.length < 10 || ph.length > 20) {
      setFieldError('Enter a valid phone number (include country code if you can).');
      return;
    }
    go('security');
  };

  const submitSecurity = (e: FormEvent) => {
    e.preventDefault();
    if (password.length < 8 || !/[A-Z]/.test(password) || !/[0-9]/.test(password)) {
      setFieldError('Password needs 8+ characters, one uppercase letter, and one number.');
      return;
    }
    if (password !== passwordConfirmation) {
      setFieldError('Those passwords do not match.');
      return;
    }
    go('referral');
  };

  const createAccount = async () => {
    setSubmitting(true);
    setFieldError('');
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
        Object.values(errs)
          .flat()
          .forEach((msg) => toast.error(String(msg)));
        setFieldError(Object.values(errs).flat()[0] || 'Registration failed');
      } else {
        const message = err.response?.data?.message || 'Registration failed';
        toast.error(message);
        setFieldError(message);
      }
    } finally {
      setSubmitting(false);
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

      <div className="bg-card border border-border rounded-2xl p-6 shadow-sm">
        {step === 'intent' && (
          <div className="space-y-3">
            <button
              type="button"
              onClick={() => {
                setRole('customer');
                go('name');
              }}
              className={`w-full text-left p-4 rounded-xl border transition-all flex items-start gap-3 ${
                role === 'customer' ? 'border-primary bg-accent' : 'border-border hover:border-primary/40'
              }`}
            >
              <div className="w-10 h-10 rounded-full bg-primary/15 text-primary flex items-center justify-center shrink-0">
                <User className="w-5 h-5" />
              </div>
              <div>
                <p className="font-display font-semibold">I need errands done</p>
                <p className="text-sm text-muted-foreground mt-0.5">Post tasks and track vetted runners nearby.</p>
              </div>
            </button>
            <button
              type="button"
              onClick={() => {
                setRole('runner');
                go('name');
              }}
              className={`w-full text-left p-4 rounded-xl border transition-all flex items-start gap-3 ${
                role === 'runner' ? 'border-primary bg-accent' : 'border-border hover:border-primary/40'
              }`}
            >
              <div className="w-10 h-10 rounded-full bg-primary/15 text-primary flex items-center justify-center shrink-0">
                <Zap className="w-5 h-5" />
              </div>
              <div>
                <p className="font-display font-semibold">I want to be a Runner</p>
                <p className="text-sm text-muted-foreground mt-0.5">Earn by completing errands across Uyo.</p>
              </div>
            </button>
          </div>
        )}

        {step === 'name' && (
          <form onSubmit={submitName} className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label htmlFor="first-name" className="block text-sm font-medium mb-1.5">
                  First name
                </label>
                <input
                  id="first-name"
                  autoFocus
                  autoComplete="given-name"
                  value={firstName}
                  onChange={(e) => setFirstName(e.target.value)}
                  className="w-full px-4 py-3 border border-input bg-background rounded-xl focus:outline-none focus:ring-2 focus:ring-primary"
                  placeholder="Ada"
                  maxLength={50}
                />
              </div>
              <div>
                <label htmlFor="last-name" className="block text-sm font-medium mb-1.5">
                  Last name
                </label>
                <input
                  id="last-name"
                  autoComplete="family-name"
                  value={lastName}
                  onChange={(e) => setLastName(e.target.value)}
                  className="w-full px-4 py-3 border border-input bg-background rounded-xl focus:outline-none focus:ring-2 focus:ring-primary"
                  placeholder="Okafor"
                  maxLength={50}
                />
              </div>
            </div>
            {fieldError && <p className="text-red-500 text-xs">{fieldError}</p>}
            <div className="flex gap-3">
              <button type="button" onClick={back} className="px-4 py-3 rounded-xl border border-border text-sm font-medium hover:bg-muted inline-flex items-center gap-1">
                <ArrowLeft className="w-4 h-4" /> Back
              </button>
              <button type="submit" className="flex-1 errandly-btn-primary inline-flex items-center justify-center gap-2">
                Continue <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          </form>
        )}

        {step === 'contact' && (
          <form onSubmit={submitContact} className="space-y-4">
            <div>
              <label htmlFor="email" className="block text-sm font-medium mb-1.5">
                Email
              </label>
              <input
                id="email"
                autoFocus
                type="email"
                autoComplete="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full px-4 py-3 border border-input bg-background rounded-xl focus:outline-none focus:ring-2 focus:ring-primary"
                placeholder="ada@example.com"
                maxLength={120}
              />
            </div>
            <div>
              <label htmlFor="phone" className="block text-sm font-medium mb-1.5">
                Phone
              </label>
              <input
                id="phone"
                autoComplete="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                className="w-full px-4 py-3 border border-input bg-background rounded-xl focus:outline-none focus:ring-2 focus:ring-primary"
                placeholder="+2348100000000"
                maxLength={20}
              />
            </div>
            {fieldError && <p className="text-red-500 text-xs">{fieldError}</p>}
            <div className="flex gap-3">
              <button type="button" onClick={back} className="px-4 py-3 rounded-xl border border-border text-sm font-medium hover:bg-muted inline-flex items-center gap-1">
                <ArrowLeft className="w-4 h-4" /> Back
              </button>
              <button type="submit" className="flex-1 errandly-btn-primary inline-flex items-center justify-center gap-2">
                Continue <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          </form>
        )}

        {step === 'security' && (
          <form onSubmit={submitSecurity} className="space-y-4">
            <div>
              <label htmlFor="password" className="block text-sm font-medium mb-1.5">
                Password
              </label>
              <div className="relative">
                <input
                  id="password"
                  autoFocus
                  type={showPassword ? 'text' : 'password'}
                  autoComplete="new-password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full px-4 py-3 border border-input bg-background rounded-xl focus:outline-none focus:ring-2 focus:ring-primary pr-12"
                  placeholder="Min 8 chars, uppercase, number"
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
            </div>
            <div>
              <label htmlFor="password2" className="block text-sm font-medium mb-1.5">
                Confirm password
              </label>
              <input
                id="password2"
                type={showPassword ? 'text' : 'password'}
                autoComplete="new-password"
                value={passwordConfirmation}
                onChange={(e) => setPasswordConfirmation(e.target.value)}
                className="w-full px-4 py-3 border border-input bg-background rounded-xl focus:outline-none focus:ring-2 focus:ring-primary"
                placeholder="Repeat password"
                maxLength={128}
              />
            </div>
            {fieldError && <p className="text-red-500 text-xs">{fieldError}</p>}
            <div className="flex gap-3">
              <button type="button" onClick={back} className="px-4 py-3 rounded-xl border border-border text-sm font-medium hover:bg-muted inline-flex items-center gap-1">
                <ArrowLeft className="w-4 h-4" /> Back
              </button>
              <button type="submit" className="flex-1 errandly-btn-primary inline-flex items-center justify-center gap-2">
                Continue <ArrowRight className="w-4 h-4" />
              </button>
            </div>
          </form>
        )}

        {step === 'referral' && (
          <form
            onSubmit={(e) => {
              e.preventDefault();
              go('confirm');
            }}
            className="space-y-4"
          >
            <div>
              <label htmlFor="referral" className="block text-sm font-medium mb-1.5">
                Referral code <span className="text-muted-foreground font-normal">(optional)</span>
              </label>
              <input
                id="referral"
                autoFocus
                value={referralCode}
                onChange={(e) => setReferralCode(e.target.value)}
                className="w-full px-4 py-3 border border-input bg-background rounded-xl focus:outline-none focus:ring-2 focus:ring-primary"
                placeholder="Enter code if you have one"
                maxLength={40}
              />
            </div>
            <div className="flex gap-3">
              <button type="button" onClick={back} className="px-4 py-3 rounded-xl border border-border text-sm font-medium hover:bg-muted inline-flex items-center gap-1">
                <ArrowLeft className="w-4 h-4" /> Back
              </button>
              <button type="submit" className="flex-1 errandly-btn-primary inline-flex items-center justify-center gap-2">
                Review details <ArrowRight className="w-4 h-4" />
              </button>
            </div>
            <button type="button" onClick={() => go('confirm')} className="w-full text-sm text-muted-foreground hover:text-primary">
              Skip for now
            </button>
          </form>
        )}

        {step === 'confirm' && (
          <div className="space-y-5">
            <dl className="space-y-3 text-sm">
              <div className="flex justify-between gap-4 border-b border-border pb-2">
                <dt className="text-muted-foreground">Joining as</dt>
                <dd className="font-medium capitalize">{role}</dd>
              </div>
              <div className="flex justify-between gap-4 border-b border-border pb-2">
                <dt className="text-muted-foreground">Name</dt>
                <dd className="font-medium">
                  {firstName.trim()} {lastName.trim()}
                </dd>
              </div>
              <div className="flex justify-between gap-4 border-b border-border pb-2">
                <dt className="text-muted-foreground">Email</dt>
                <dd className="font-medium break-all">{email.trim()}</dd>
              </div>
              <div className="flex justify-between gap-4 border-b border-border pb-2">
                <dt className="text-muted-foreground">Phone</dt>
                <dd className="font-medium">{phone.trim()}</dd>
              </div>
              {referralCode.trim() && (
                <div className="flex justify-between gap-4 border-b border-border pb-2">
                  <dt className="text-muted-foreground">Referral</dt>
                  <dd className="font-medium">{referralCode.trim()}</dd>
                </div>
              )}
            </dl>

            {role === 'runner' && (
              <p className="text-xs text-amber-700 dark:text-amber-300 bg-amber-50 dark:bg-amber-950/40 border border-amber-200 dark:border-amber-800 rounded-xl p-3">
                Runners complete KYC (ID, selfie, bank details) before accepting errands.
              </p>
            )}

            <p className="text-xs text-muted-foreground text-center">
              By continuing you agree to DOOYN&apos; terms of use and privacy practices.
            </p>

            {fieldError && <p className="text-red-500 text-xs text-center">{fieldError}</p>}

            <div className="flex gap-3">
              <button type="button" onClick={back} className="px-4 py-3 rounded-xl border border-border text-sm font-medium hover:bg-muted inline-flex items-center gap-1">
                <ArrowLeft className="w-4 h-4" /> Back
              </button>
              <button
                type="button"
                onClick={createAccount}
                disabled={submitting}
                className="flex-1 errandly-btn-primary inline-flex items-center justify-center gap-2 disabled:opacity-70"
              >
                {submitting ? <Loader2 className="w-5 h-5 animate-spin" /> : null}
                {submitting ? 'Creating account…' : 'Create my account'}
              </button>
            </div>
          </div>
        )}
      </div>

      {step !== 'intent' && (
        <p className="mt-6 text-center text-sm text-muted-foreground">
          Already have an account?{' '}
          <Link href="/auth/login" className="text-primary font-semibold hover:underline">
            Sign in
          </Link>
        </p>
      )}
    </div>
  );
}

export default function RegisterPage() {
  return (
    <div className="min-h-screen bg-background text-foreground flex flex-col">
      <header className="flex items-center justify-between page-gutter py-4 border-b border-border">
        <Link href="/" className="inline-flex items-center gap-2">
          <div className="w-9 h-9 bg-primary rounded-lg flex items-center justify-center">
            <Zap className="w-5 h-5 text-primary-foreground fill-primary-foreground" />
          </div>
          <span className="font-headline font-semibold text-lg text-primary">DOOYN</span>
        </Link>
        <div className="flex items-center gap-3">
          <ThemeToggle />
          <Link href="/auth/login" className="text-sm font-medium text-muted-foreground hover:text-primary">
            Sign in
          </Link>
        </div>
      </header>

      <main className="flex-1 flex items-center justify-center page-gutter py-10">
        <Suspense
          fallback={
            <div className="w-full max-w-lg flex justify-center py-20">
              <Loader2 className="w-6 h-6 animate-spin text-primary" />
            </div>
          }
        >
          <RegisterJourney />
        </Suspense>
      </main>
    </div>
  );
}
