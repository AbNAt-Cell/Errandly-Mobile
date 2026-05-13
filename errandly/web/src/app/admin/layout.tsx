'use client';
import { useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import {
  LayoutDashboard, Users, Zap, Shield, Package, Map, Wallet, CreditCard,
  AlertTriangle, BarChart2, Bell, Settings, LogOut, ChevronDown, Package as Logo, Menu, X
} from 'lucide-react';
import { useAuthStore } from '@/store/authStore';

const navItems = [
  { href: '/admin/dashboard', icon: LayoutDashboard, label: 'Dashboard' },
  { href: '/admin/users', icon: Users, label: 'Users' },
  { href: '/admin/runners', icon: Zap, label: 'Runners' },
  { href: '/admin/kyc', icon: Shield, label: 'KYC Review' },
  { href: '/admin/errands', icon: Package, label: 'Errands' },
  { href: '/admin/live-map', icon: Map, label: 'Live Monitoring' },
  { href: '/admin/finance', icon: Wallet, label: 'Finance' },
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
    <div className="min-h-screen bg-gray-50 flex">
      {/* Sidebar */}
      <aside className={`fixed inset-y-0 left-0 z-50 w-64 bg-[#0A1628] text-white flex flex-col transition-transform duration-300 ${sidebarOpen ? 'translate-x-0' : '-translate-x-full'} lg:translate-x-0`}>
        <div className="p-6 border-b border-white/10">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 bg-[#FF6B00] rounded-xl flex items-center justify-center">
              <Logo className="w-5 h-5 text-white" />
            </div>
            <div>
              <p className="font-bold text-lg">Errandly</p>
              <p className="text-xs text-gray-400">Admin Portal</p>
            </div>
          </div>
        </div>

        <nav className="flex-1 py-4 overflow-y-auto">
          {navItems.map((item) => {
            const isActive = pathname.startsWith(item.href);
            return (
              <Link key={item.href} href={item.href} onClick={() => setSidebarOpen(false)}>
                <div className={`flex items-center gap-3 px-6 py-3 mx-2 rounded-xl transition-colors ${isActive ? 'bg-[#FF6B00] text-white' : 'text-gray-400 hover:text-white hover:bg-white/5'}`}>
                  <item.icon className="w-5 h-5" />
                  <span className="text-sm font-medium">{item.label}</span>
                </div>
              </Link>
            );
          })}
        </nav>

        <div className="p-4 border-t border-white/10">
          <div className="flex items-center gap-3 px-2 mb-3">
            <div className="w-8 h-8 bg-[#FF6B00] rounded-full flex items-center justify-center text-sm font-bold">
              {user?.first_name?.[0]}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium truncate">{user?.full_name}</p>
              <p className="text-xs text-gray-400 truncate">{roles[0]?.replace(/_/g, ' ')}</p>
            </div>
          </div>
          <button onClick={handleLogout} className="w-full flex items-center gap-2 px-4 py-2.5 text-gray-400 hover:text-white hover:bg-white/5 rounded-xl transition text-sm">
            <LogOut className="w-4 h-4" />
            Sign out
          </button>
        </div>
      </aside>

      {/* Overlay */}
      {sidebarOpen && (
        <div className="fixed inset-0 bg-black/50 z-40 lg:hidden" onClick={() => setSidebarOpen(false)} />
      )}

      {/* Main */}
      <div className="flex-1 lg:ml-64">
        {/* Top bar (mobile) */}
        <header className="bg-white border-b border-gray-100 lg:hidden sticky top-0 z-30">
          <div className="px-4 h-16 flex items-center justify-between">
            <button onClick={() => setSidebarOpen(true)} className="p-2 text-gray-600">
              <Menu className="w-6 h-6" />
            </button>
            <span className="font-bold text-[#0A1628]">Errandly Admin</span>
            <div className="w-8" />
          </div>
        </header>

        <main>{children}</main>
      </div>
    </div>
  );
}
