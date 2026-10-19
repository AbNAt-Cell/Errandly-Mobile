'use client';
import { useState, useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import {
  LayoutDashboard, Users, Zap, Shield, Package, Map, Wallet, CreditCard,
  AlertTriangle, BarChart2, Bell, Settings, LogOut, Menu
} from 'lucide-react';
import { useAuthStore } from '@/store/authStore';
import Logo from '@/components/shared/Logo';
import { ThemeToggle } from '@/components/shared/ThemeToggle';

import { subscribeAdminChannel } from '@/lib/pusher';
import { soundService } from '@/lib/sound';
import toast from 'react-hot-toast';
import { useQueryClient } from '@tanstack/react-query';

const navItems = [
  { href: '/admin/dashboard', icon: LayoutDashboard, label: 'Overview' },
  { href: '/admin/errands', icon: Package, label: 'Errands' },
  { href: '/admin/users', icon: Users, label: 'Users' },
  { href: '/admin/runners', icon: Zap, label: 'Runners' },
  { href: '/admin/kyc', icon: Shield, label: 'KYC Verification' },
  { href: '/admin/live-map', icon: Map, label: 'Live Map' },
  { href: '/admin/finance', icon: Wallet, label: 'Finance & Payouts' },
  { href: '/admin/disputes', icon: AlertTriangle, label: 'Disputes' },
  { href: '/admin/reports', icon: BarChart2, label: 'Reports' },
  { href: '/admin/notifications', icon: Bell, label: 'Notifications' },
  { href: '/admin/settings', icon: Settings, label: 'Settings' },
];

export default function AdminLayout({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, roles, user, logout, _hasHydrated } = useAuthStore();
  const router = useRouter();
  const pathname = usePathname();
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [isReady, setIsReady] = useState(false);
  const queryClient = useQueryClient();

  useEffect(() => {
    // 1. Direct inspection of localStorage
    if (typeof window !== 'undefined') {
      try {
        const rawAuth = localStorage.getItem('errand-auth');
        const token = localStorage.getItem('errand_token');
        if (rawAuth) {
          const parsed = JSON.parse(rawAuth);
          const state = parsed?.state;
          const isAdmin = state?.roles?.some((r: string) => ['admin', 'super_admin', 'verification_officer'].includes(r));
          if (state?.isAuthenticated && isAdmin && (state?.token || token)) {
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

    if (_hasHydrated) {
      if (!isAuthenticated || !roles.some((r) => ['admin', 'super_admin', 'verification_officer'].includes(r))) {
        router.push('/auth/login');
      } else {
        setIsReady(true);
      }
      return;
    }

    const timer = setTimeout(() => {
      const current = useAuthStore.getState();
      if (!current.isAuthenticated || !current.roles.some((r) => ['admin', 'super_admin', 'verification_officer'].includes(r))) {
        router.push('/auth/login');
      } else {
        setIsReady(true);
      }
    }, 600);

    return () => clearTimeout(timer);
  }, [isAuthenticated, roles, _hasHydrated, router]);

  // Subscribe to real-time admin events (new orders, panic alerts) with audio chimes
  useEffect(() => {
    if (!isAuthenticated) return;
    const unsub = subscribeAdminChannel((event, data: any) => {
      if (event === 'ErrandCreated') {
        soundService.playAdminOrderAlert();
        toast.custom(
          (t) => (
            <div
              className={`${
                t.visible ? 'animate-enter' : 'animate-leave'
              } max-w-md w-full bg-white dark:bg-[#1A1C23] shadow-2xl rounded-2xl pointer-events-auto flex ring-1 ring-black/5 dark:ring-white/10 p-4 border-l-4 border-[#F97316]`}
            >
              <div className="flex-1 w-0">
                <div className="flex items-start">
                  <div className="flex-shrink-0 pt-0.5 text-xl">🛒</div>
                  <div className="ml-3 flex-1">
                    <p className="text-sm font-bold text-gray-900 dark:text-white">
                      New Order Placed!
                    </p>
                    <p className="mt-1 text-xs text-gray-600 dark:text-gray-300">
                      {data?.title || 'New errand'} • ₦{Number(data?.budget || 0).toLocaleString()}
                    </p>
                    {data?.customer?.name && (
                      <p className="text-[11px] text-gray-400 mt-0.5">By {data.customer.name}</p>
                    )}
                  </div>
                </div>
              </div>
            </div>
          ),
          { duration: 6000 }
        );
        queryClient.invalidateQueries({ queryKey: ['admin-errands'] });
        queryClient.invalidateQueries({ queryKey: ['admin-dashboard'] });
      } else if (event === 'PanicTriggered') {
        soundService.playRunnerAlert();
        toast.error('🚨 EMERGENCY: Panic button triggered on an errand!', { duration: 10000 });
        queryClient.invalidateQueries({ queryKey: ['admin-errands'] });
      }
    });

    return () => unsub?.();
  }, [isAuthenticated, queryClient]);

  const handleLogout = async () => {
    await logout();
    router.push('/auth/login');
  };

  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 dark:bg-[#0E0F13] dark:text-[#e3e2e7] flex transition-colors">
      {/* Sidebar */}
      <aside className={`fixed inset-y-0 left-0 z-50 w-64 bg-white dark:bg-[#121317] border-r border-slate-200 dark:border-white/10 text-slate-900 dark:text-white flex flex-col transition-all duration-300 ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'} lg:translate-x-0`}>
        <div className="p-6 border-b border-slate-200 dark:border-white/10">
          <Logo iconSize="w-9 h-9" textSize="text-xl" subtext="Admin Portal" href="/admin/dashboard" />
        </div>

        <nav className="flex-1 py-4 overflow-y-auto space-y-1">
          {navItems.map((item) => {
            const isActive = pathname.startsWith(item.href);
            return (
              <Link key={item.href} href={item.href} onClick={() => setSidebarOpen(false)}>
                <div className={`flex items-center gap-3 px-5 py-3 mx-2 rounded-xl transition-all ${
                  isActive
                    ? 'bg-[#F97316] text-[#121317] font-bold shadow-md shadow-[#F97316]/20'
                    : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100 dark:text-gray-400 dark:hover:text-white dark:hover:bg-white/5 font-medium'
                }`}>
                  <item.icon className="w-5 h-5" />
                  <span className="text-sm">{item.label}</span>
                </div>
              </Link>
            );
          })}
        </nav>

        <div className="p-4 border-t border-slate-200 dark:border-white/10 space-y-3">
          <div className="flex items-center justify-between px-2">
            <span className="text-xs font-medium text-slate-500 dark:text-gray-400">Theme</span>
            <ThemeToggle compact={true} />
          </div>
          <div className="flex items-center gap-3 px-2 pt-1 border-t border-slate-100 dark:border-white/5">
            <div className="w-8 h-8 bg-[#F97316] text-[#121317] rounded-full flex items-center justify-center text-sm font-bold shadow-sm">
              {user?.first_name?.[0] || 'A'}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium truncate text-slate-900 dark:text-white">{user?.full_name}</p>
              <p className="text-xs text-slate-500 dark:text-[#e0c0b1] truncate capitalize">{roles[0]?.replace(/_/g, ' ')}</p>
            </div>
          </div>
          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-2 px-4 py-2.5 text-slate-600 hover:text-red-600 hover:bg-red-50 dark:text-gray-400 dark:hover:text-white dark:hover:bg-white/5 rounded-xl transition text-sm"
          >
            <LogOut className="w-4 h-4" />
            Sign out
          </button>
        </div>
      </aside>

      {/* Overlay */}
      {sidebarOpen && (
        <div className="fixed inset-0 bg-black/60 z-40 lg:hidden" onClick={() => setSidebarOpen(false)} />
      )}

      {/* Main */}
      <div className="flex-1 lg:ml-64">
        {/* Top bar (mobile) */}
        <header className="bg-white dark:bg-[#0E0F13] border-b border-slate-200 dark:border-white/10 lg:hidden sticky top-0 z-30 transition-colors">
          <div className="px-4 h-16 flex items-center justify-between">
            <button onClick={() => setSidebarOpen(true)} className="p-2 text-slate-600 dark:text-gray-300 hover:text-slate-900 dark:hover:text-white">
              <Menu className="w-6 h-6" />
            </button>
            <Logo iconSize="w-7 h-7" textSize="text-lg" subtext="Admin" href="/admin/dashboard" />
            <ThemeToggle compact={true} />
          </div>
        </header>

        <main className="min-h-screen bg-slate-50 dark:bg-[#0E0F13] transition-colors">{children}</main>
      </div>
    </div>
  );
}
