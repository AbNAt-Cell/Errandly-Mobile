'use client';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Home, Package, Wallet, MessageSquare, User, Bell, Sparkles, Loader2 } from 'lucide-react';
import { useAuthStore } from '@/store/authStore';
import Logo from '@/components/shared/Logo';
import { ThemeToggle } from '@/components/shared/ThemeToggle';

const navItems = [
  { href: '/customer/dashboard', icon: Home, label: 'Home' },
  { href: '/customer/errands', icon: Package, label: 'Errands' },
  { href: '/customer/wallet', icon: Wallet, label: 'Wallet' },
  { href: '/customer/assistant', icon: Sparkles, label: 'Assistant' },
  { href: '/customer/messages', icon: MessageSquare, label: 'Messages' },
  { href: '/customer/profile', icon: User, label: 'Profile' },
];

export default function CustomerLayout({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, roles, user, _hasHydrated } = useAuthStore();
  const router = useRouter();
  const pathname = usePathname();
  const [isReady, setIsReady] = useState(false);

  useEffect(() => {
    // 1. Direct inspection of localStorage for fast recovery during cold reloads or payment redirects
    if (typeof window !== 'undefined') {
      try {
        const rawAuth = localStorage.getItem('errand-auth');
        const token = localStorage.getItem('errand_token');
        if (rawAuth) {
          const parsed = JSON.parse(rawAuth);
          const state = parsed?.state;
          if (state?.isAuthenticated && state?.roles?.includes('customer') && (state?.token || token)) {
            if (!isAuthenticated) {
              useAuthStore.getState().establishSession({
                user: state.user,
                token: state.token || token,
                roles: state.roles,
              });
            }
            setIsReady(true);
            return;
          }
        }
      } catch {
        // ignore
      }
    }

    // 2. If store has finished hydrating
    if (_hasHydrated) {
      if (!isAuthenticated || !roles.includes('customer')) {
        router.push('/auth/login');
      } else {
        setIsReady(true);
      }
      return;
    }

    // 3. Grace period before enforcing login
    const timer = setTimeout(() => {
      const current = useAuthStore.getState();
      if (!current.isAuthenticated || !current.roles.includes('customer')) {
        router.push('/auth/login');
      } else {
        setIsReady(true);
      }
    }, 600);

    return () => clearTimeout(timer);
  }, [isAuthenticated, roles, _hasHydrated, router]);

  if (!isReady && !_hasHydrated) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#0E0F13]">
        <div className="flex flex-col items-center gap-4">
          <div className="w-16 h-16 rounded-2xl bg-[#17191F] border border-[#F97316]/30 flex items-center justify-center shadow-[0_0_30px_rgba(249,115,22,0.15)]">
            <img src="/logo.png" alt="Errand" className="w-10 h-10 object-contain" />
          </div>
          <Loader2 className="w-6 h-6 animate-spin text-[#F97316]" />
          <p className="text-xs text-gray-400 font-medium">Loading Errand...</p>
        </div>
      </div>
    );
  }

  const initial = user?.first_name ? user.first_name[0].toUpperCase() : 'C';

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 dark:bg-[#0E0F13] dark:text-[#e3e2e7] transition-colors">
      {/* Top bar */}
      <header className="bg-white/90 dark:bg-[#0E0F13]/90 backdrop-blur-md border-b border-slate-200 dark:border-white/10 sticky top-0 z-40 transition-colors">
        <div className="max-w-5xl mx-auto px-4 h-16 flex items-center justify-between">
          <Logo iconSize="w-8 h-8" textSize="text-xl" href="/customer/dashboard" />
          <div className="flex items-center gap-3">
            <ThemeToggle />
            <Link href="/customer/notifications" className="relative p-2 text-slate-600 dark:text-gray-300 hover:text-[#F97316] transition-colors">
              <Bell className="w-5 h-5" />
            </Link>
            <Link href="/customer/profile">
              <div className="w-8 h-8 bg-[#F97316] rounded-full flex items-center justify-center text-[#121317] text-sm font-bold shadow-sm">
                {initial}
              </div>
            </Link>
          </div>
        </div>
      </header>

      {/* Main content */}
      <main className="max-w-5xl mx-auto pb-20">
        {children}
      </main>

      {/* Bottom navigation */}
      <nav className="fixed bottom-0 left-0 right-0 bg-white/95 dark:bg-[#121317]/95 backdrop-blur-md border-t border-slate-200 dark:border-white/10 z-40 transition-colors">
        <div className="max-w-5xl mx-auto flex">
          {navItems.map((item) => {
            const isActive = pathname.startsWith(item.href);
            return (
              <Link key={item.href} href={item.href} className="flex-1">
                <div className={`flex flex-col items-center gap-1 py-3 transition-colors ${
                  isActive ? 'text-[#F97316]' : 'text-slate-500 hover:text-slate-900 dark:text-gray-400 dark:hover:text-white'
                }`}>
                  <item.icon className="w-5 h-5" />
                  <span className="text-xs font-medium">{item.label}</span>
                </div>
              </Link>
            );
          })}
        </div>
      </nav>
    </div>
  );
}
