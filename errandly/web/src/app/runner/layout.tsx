'use client';
import { useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import { Home, Package, DollarSign, MessageSquare, User, Bell, Package as LogoIcon } from 'lucide-react';
import { useAuthStore } from '@/store/authStore';
import { ThemeToggle } from '@/components/shared/ThemeToggle';

const navItems = [
  { href: '/runner/dashboard', icon: Home, label: 'Tasks' },
  { href: '/runner/earnings', icon: DollarSign, label: 'Earnings' },
  { href: '/runner/messages', icon: MessageSquare, label: 'Messages' },
  { href: '/runner/activity', icon: Package, label: 'Activity' },
  { href: '/runner/profile', icon: User, label: 'Profile' },
];

export default function RunnerLayout({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, roles } = useAuthStore();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (!isAuthenticated) {
      router.push('/auth/login');
    } else if (!roles.includes('runner')) {
      router.push('/auth/login');
    }
  }, [isAuthenticated, roles, router]);

  return (
    <div className="app-page">
      <header className="bg-shell text-shell-foreground sticky top-0 z-40 border-b border-white/10">
        <div className="page-container h-16 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
              <LogoIcon className="w-5 h-5 text-primary-foreground" />
            </div>
            <span className="font-bold">DOOYN Runner</span>
          </div>
          <div className="flex items-center gap-2">
            <ThemeToggle className="!bg-white/10 !border-white/15 !text-white hover:!border-primary" />
            <Link href="/runner/notifications" className="relative p-2 text-gray-300 hover:text-white transition">
              <Bell className="w-6 h-6" />
            </Link>
          </div>
        </div>
      </header>

      <main className="page-container pb-20">{children}</main>

      <nav className="fixed bottom-0 left-0 right-0 bg-shell border-t border-white/10 z-40">
        <div className="page-container flex">
          {navItems.map((item) => {
            const isActive = pathname.startsWith(item.href);
            return (
              <Link key={item.href} href={item.href} className="flex-1">
                <div
                  className={`flex flex-col items-center gap-1 py-3 transition-colors ${
                    isActive ? 'text-primary' : 'text-gray-400'
                  }`}
                >
                  <item.icon className="w-5 h-5" />
                  <span className="text-xs">{item.label}</span>
                </div>
              </Link>
            );
          })}
        </div>
      </nav>
    </div>
  );
}
