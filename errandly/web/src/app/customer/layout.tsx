'use client';
import { useEffect } from 'react';
import { useRouter, usePathname } from 'next/navigation';
import Link from 'next/link';
import { Home, Package, Wallet, MessageSquare, User, Package as LogoIcon, Bell, Sparkles } from 'lucide-react';
import { useAuthStore } from '@/store/authStore';
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
  const { isAuthenticated, roles } = useAuthStore();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (!isAuthenticated) {
      router.push('/auth/login');
    } else if (!roles.includes('customer')) {
      router.push('/auth/login');
    }
  }, [isAuthenticated, roles, router]);

  return (
    <div className="app-page">
      <header className="app-header">
        <div className="page-container h-16 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-primary rounded-lg flex items-center justify-center">
              <LogoIcon className="w-5 h-5 text-primary-foreground" />
            </div>
            <span className="font-bold text-foreground">DOOYN</span>
          </div>
          <div className="flex items-center gap-2">
            <ThemeToggle />
            <Link href="/customer/notifications" className="relative p-2 text-muted-foreground hover:text-primary transition-colors">
              <Bell className="w-6 h-6" />
            </Link>
            <Link href="/customer/profile">
              <div className="w-8 h-8 bg-primary rounded-full flex items-center justify-center text-primary-foreground text-sm font-bold">
                C
              </div>
            </Link>
          </div>
        </div>
      </header>

      <main className="page-container pb-20">{children}</main>

      <nav className="fixed bottom-0 left-0 right-0 bg-card border-t border-border z-40">
        <div className="page-container flex">
          {navItems.map((item) => {
            const isActive = pathname.startsWith(item.href);
            return (
              <Link key={item.href} href={item.href} className="flex-1">
                <div
                  className={`flex flex-col items-center gap-1 py-3 transition-colors ${
                    isActive ? 'text-primary' : 'text-muted-foreground'
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
