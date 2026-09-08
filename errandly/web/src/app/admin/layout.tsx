'use client';
import { useEffect, useState } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import {
  LayoutDashboard,
  Users,
  Zap,
  Shield,
  Package,
  Map,
  Wallet,
  AlertTriangle,
  BarChart2,
  Bell,
  Settings,
  LogOut,
  Package as Logo,
  Menu,
} from 'lucide-react';
import { useAuthStore } from '@/store/authStore';
import { ThemeToggle } from '@/components/shared/ThemeToggle';

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
  }, [isAuthenticated, roles, router]);

  const handleLogout = async () => {
    await logout();
    router.push('/auth/login');
  };

  return (
    <div className="min-h-screen bg-background flex">
      <aside
        className={`fixed inset-y-0 left-0 z-50 w-64 bg-shell text-shell-foreground flex flex-col transition-transform duration-300 ${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        } lg:translate-x-0`}
      >
        <div className="p-6 border-b border-white/10">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 bg-primary rounded-xl flex items-center justify-center">
              <Logo className="w-5 h-5 text-primary-foreground" />
            </div>
            <div>
              <p className="font-bold text-lg">DOOYN</p>
              <p className="text-xs text-gray-400">Admin Portal</p>
            </div>
          </div>
        </div>

        <nav className="flex-1 py-4 overflow-y-auto">
          {navItems.map((item) => {
            const isActive = pathname.startsWith(item.href);
            return (
              <Link key={item.href} href={item.href} onClick={() => setSidebarOpen(false)}>
                <div
                  className={`flex items-center gap-3 px-6 py-3 mx-2 rounded-xl transition-colors ${
                    isActive ? 'bg-primary text-primary-foreground' : 'text-gray-400 hover:text-white hover:bg-white/5'
                  }`}
                >
                  <item.icon className="w-5 h-5" />
                  <span className="text-sm font-medium">{item.label}</span>
                </div>
              </Link>
            );
          })}
        </nav>

        <div className="p-4 border-t border-white/10 space-y-3">
          <div className="px-2">
            <ThemeToggle compact={false} className="w-full !bg-white/5 !border-white/10 justify-between" />
          </div>
          <div className="flex items-center gap-3 px-2 mb-1">
            <div className="w-8 h-8 bg-primary rounded-full flex items-center justify-center text-sm font-bold text-primary-foreground">
              {user?.first_name?.[0]}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium truncate">{user?.full_name}</p>
              <p className="text-xs text-gray-400 truncate">{roles[0]?.replace(/_/g, ' ')}</p>
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

      {sidebarOpen && (
        <div className="fixed inset-0 bg-black/50 z-40 lg:hidden" onClick={() => setSidebarOpen(false)} />
      )}

      <div className="flex-1 lg:ml-64">
        <header className="app-header lg:hidden">
          <div className="page-gutter h-16 flex items-center justify-between">
            <button onClick={() => setSidebarOpen(true)} className="p-2 text-muted-foreground">
              <Menu className="w-6 h-6" />
            </button>
            <span className="font-bold text-foreground">DOOYN Admin</span>
            <ThemeToggle />
          </div>
        </header>

        <main>{children}</main>
      </div>
    </div>
  );
}
