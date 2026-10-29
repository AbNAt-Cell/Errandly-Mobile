'use client';
import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { Loader2 } from 'lucide-react';
import toast from 'react-hot-toast';
import { useAuthStore } from '@/store/authStore';

declare global {
  interface Window {
    google?: any;
  }
}

interface GoogleSignInButtonProps {
  role?: 'customer' | 'runner';
  label?: string;
  className?: string;
}

export default function GoogleSignInButton({
  role = 'customer',
  label = 'Continue with Google',
  className = '',
}: GoogleSignInButtonProps) {
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const { googleLogin } = useAuthStore();

  useEffect(() => {
    // Inject Google Identity Services script if not already present
    if (typeof window !== 'undefined' && !document.getElementById('google-gsi-script')) {
      const script = document.createElement('script');
      script.id = 'google-gsi-script';
      script.src = 'https://accounts.google.com/gsi/client';
      script.async = true;
      script.defer = true;
      document.body.appendChild(script);
    }
  }, []);

  const handleGoogleSignIn = () => {
    setLoading(true);

    const clientId = process.env.NEXT_PUBLIC_GOOGLE_CLIENT_ID || '479810604809-apps.googleusercontent.com';

    if (window.google?.accounts?.id) {
      window.google.accounts.id.initialize({
        client_id: clientId,
        callback: async (response: any) => {
          try {
            if (response.credential) {
              const res = await googleLogin(response.credential, role);
              toast.success('Signed in with Google!');

              const userRoles = res?.roles || [role];
              const requiresPhone = res?.requires_phone_verification || !res?.user?.phone || !res?.user?.phone_verified_at;

              if (requiresPhone) {
                router.push(`/auth/verify-phone?role=${role}`);
              } else if (userRoles.includes('runner')) {
                router.push('/runner/dashboard');
              } else if (userRoles.includes('admin') || userRoles.includes('super_admin')) {
                router.push('/admin/dashboard');
              } else {
                router.push('/customer/dashboard');
              }
            } else {
              toast.error('Google Sign-In failed to return credentials.');
            }
          } catch (err: any) {
            toast.error(err.response?.data?.message || 'Google authentication failed.');
          } finally {
            setLoading(false);
          }
        },
      });

      window.google.accounts.id.prompt((notification: any) => {
        if (notification.isNotDisplayed() || notification.isSkippedMoment()) {
          setLoading(false);
        }
      });
    } else {
      setLoading(false);
      toast.error('Google Sign-In is initializing. Please try again in a moment.');
    }
  };

  return (
    <div className={`w-full ${className}`}>
      <div className="relative my-5">
        <div className="absolute inset-0 flex items-center">
          <div className="w-full border-t border-slate-200 dark:border-white/10" />
        </div>
        <div className="relative flex justify-center text-xs uppercase">
          <span className="bg-white dark:bg-[#17191F] px-3 text-slate-500 dark:text-gray-400 font-medium">
            Or continue with
          </span>
        </div>
      </div>

      <button
        type="button"
        onClick={handleGoogleSignIn}
        disabled={loading}
        className="w-full bg-slate-50 hover:bg-slate-100 dark:bg-[#121317] dark:hover:bg-[#1a1c23] border border-slate-200 dark:border-white/10 text-slate-800 dark:text-white font-medium py-3 px-4 rounded-xl transition flex items-center justify-center gap-3 active:scale-95 disabled:opacity-60 shadow-sm"
      >
        {loading ? (
          <Loader2 className="w-5 h-5 animate-spin text-slate-500" />
        ) : (
          <svg className="w-5 h-5 flex-shrink-0" viewBox="0 0 48 48">
            <path fill="#FFC107" d="M43.611,20.083H42V20H24v8h11.303c-1.649,4.657-6.08,8-11.303,8c-6.627,0-12-5.373-12-12c0-6.627,5.373-12,12-12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C12.955,4,4,12.955,4,24c0,11.045,8.955,20,20,20c11.045,0,20-8.955,20-20C44,22.659,43.862,21.35,43.611,20.083z"/>
            <path fill="#FF3D00" d="M6.306,14.691l6.571,4.819C14.655,15.108,18.961,12,24,12c3.059,0,5.842,1.154,7.961,3.039l5.657-5.657C34.046,6.053,29.268,4,24,4C16.318,4,9.656,8.337,6.306,14.691z"/>
            <path fill="#4CAF50" d="M24,44c5.166,0,9.86-1.977,13.409-5.192l-6.19-5.238C29.211,35.091,26.715,36,24,36c-5.202,0-9.619-3.317-11.283-7.946l-6.522,5.025C9.505,39.556,16.227,44,24,44z"/>
            <path fill="#1976D2" d="M43.611,20.083H42V20H24v8h11.303c-0.792,2.237-2.231,4.166-4.087,5.571c0.001-0.001,0.002-0.001,0.003-0.002l6.19,5.238C36.971,39.205,44,34,44,24C44,22.659,43.862,21.35,43.611,20.083z"/>
          </svg>
        )}
        <span className="text-sm font-semibold">{label}</span>
      </button>
    </div>
  );
}
