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
  const { isAuthenticated, roles, user, logout } = useAuthStore();
  const router = useRouter();
  const pathname = usePathname();
  const [sidebarOpen, setSidebarOpen] = useState(false);

  useEffect(() => {
    if (!isAuthenticated) {
      router.push('/auth/login');
    } else if (!roles.some((r) => ['admin', 'super_admin', 'verification_officer'].includes(r))) {
      router.push('/auth/login');
    }
  }, [isAuthenticated, roles]);

  const handleLogout = async () => {
    await logout();
    router.push('/auth/login');
  };

  return (
    <div className="min-h-screen bg-[#0E0F13] text-[#e3e2e7] flex">
      {/* Sidebar */}
      <aside className={`fixed inset-y-0 left-0 z-50 w-64 bg-[#121317] border-r border-white/10 text-white flex flex-col transition-transform duration-300 ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'} lg:translate-x-0`}>
        <div className="p-6 border-b border-white/10">
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
                    : 'text-gray-400 hover:text-white hover:bg-white/5 font-medium'
                }`}>
                  <item.icon className="w-5 h-5" />
                  <span className="text-sm">{item.label}</span>
                </div>
              </Link>
            );
          })}
        </nav>

        <div className="p-4 border-t border-white/10">
          <div className="flex items-center gap-3 px-2 mb-3">
            <div className="w-8 h-8 bg-[#F97316] text-[#121317] rounded-full flex items-center justify-center text-sm font-bold shadow-sm">
              {user?.first_name?.[0] || 'A'}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium truncate text-white">{user?.full_name}</p>
              <p className="text-xs text-[#e0c0b1] truncate capitalize">{roles[0]?.replace(/_/g, ' ')}</p>
            </div>
          </div>
          <button
            onClick={handleLogout}
            className="w-full flex items-center gap-2 px-4 py-2.5 text-gray-400 hover:text-white hover:bg-white/5 rounded-xl transition text-sm"
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
        <header className="bg-[#0E0F13] border-b border-white/10 lg:hidden sticky top-0 z-30">
          <div className="px-4 h-16 flex items-center justify-between">
            <button onClick={() => setSidebarOpen(true)} className="p-2 text-gray-300 hover:text-white">
              <Menu className="w-6 h-6" />
            </button>
            <Logo iconSize="w-7 h-7" textSize="text-lg" subtext="Admin" href="/admin/dashboard" />
            <div className="w-8" />
          </div>
        </header>

        <main className="min-h-screen bg-[#0E0F13]">{children}</main>
      </div>
    </div>
  );
}
