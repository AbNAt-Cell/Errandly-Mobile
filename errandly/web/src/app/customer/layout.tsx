'use client';
import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Home, Package, Wallet, MessageSquare, User, Bell, Sparkles } from 'lucide-react';
import { useAuthStore } from '@/store/authStore';
import Logo from '@/components/shared/Logo';

const navItems = [
  { href: '/customer/dashboard', icon: Home, label: 'Home' },
  { href: '/customer/errands', icon: Package, label: 'Errands' },
  { href: '/customer/wallet', icon: Wallet, label: 'Wallet' },
  { href: '/customer/assistant', icon: Sparkles, label: 'Assistant' },
  { href: '/customer/messages', icon: MessageSquare, label: 'Messages' },
  { href: '/customer/profile', icon: User, label: 'Profile' },
];

export default function CustomerLayout({ children }: { children: React.ReactNode }) {
  const { isAuthenticated, roles, user } = useAuthStore();
  const router = useRouter();
  const pathname = usePathname();

  useEffect(() => {
    if (!isAuthenticated) {
      router.push('/auth/login');
    } else if (!roles.includes('customer')) {
      router.push('/auth/login');
    }
  }, [isAuthenticated, roles]);

  const initial = user?.first_name ? user.first_name[0].toUpperCase() : 'C';

  return (
    <div className="min-h-screen bg-[#0E0F13] text-[#e3e2e7]">
      {/* Top bar */}
      <header className="bg-[#0E0F13]/90 backdrop-blur-md border-b border-white/10 sticky top-0 z-40">
        <div className="max-w-5xl mx-auto px-4 h-16 flex items-center justify-between">
          <Logo iconSize="w-8 h-8" textSize="text-xl" href="/customer/dashboard" />
          <div className="flex items-center gap-3">
            <Link href="/customer/notifications" className="relative p-2 text-gray-300 hover:text-[#F97316] transition-colors">
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
      <nav className="fixed bottom-0 left-0 right-0 bg-[#121317]/95 backdrop-blur-md border-t border-white/10 z-40">
        <div className="max-w-5xl mx-auto flex">
          {navItems.map((item) => {
            const isActive = pathname.startsWith(item.href);
            return (
              <Link key={item.href} href={item.href} className="flex-1">
                <div className={`flex flex-col items-center gap-1 py-3 transition-colors ${
                  isActive ? 'text-[#F97316]' : 'text-gray-400 hover:text-white'
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
