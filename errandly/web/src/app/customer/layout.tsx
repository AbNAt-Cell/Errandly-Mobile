'use client';
import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Home, Package, Wallet, MessageSquare, User, Package as LogoIcon, Bell } from 'lucide-react';
import { useAuthStore } from '@/store/authStore';

const navItems = [
  { href: '/customer/dashboard', icon: Home, label: 'Home' },
  { href: '/customer/errands', icon: Package, label: 'Errands' },
  { href: '/customer/wallet', icon: Wallet, label: 'Wallet' },
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
  }, [isAuthenticated, roles]);

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Top bar */}
      <header className="bg-white border-b border-gray-100 sticky top-0 z-40">
        <div className="max-w-5xl mx-auto px-4 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-[#FF6B00] rounded-lg flex items-center justify-center">
              <LogoIcon className="w-5 h-5 text-white" />
            </div>
            <span className="font-bold text-[#0A1628]">Errandly</span>
          </div>
          <div className="flex items-center gap-3">
            <Link href="/customer/notifications" className="relative p-2 text-gray-600 hover:text-[#FF6B00] transition-colors">
              <Bell className="w-6 h-6" />
            </Link>
            <Link href="/customer/profile">
              <div className="w-8 h-8 bg-[#FF6B00] rounded-full flex items-center justify-center text-white text-sm font-bold">
                C
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
      <nav className="fixed bottom-0 left-0 right-0 bg-white border-t border-gray-100 z-40">
        <div className="max-w-5xl mx-auto flex">
          {navItems.map((item) => {
            const isActive = pathname.startsWith(item.href);
            return (
              <Link key={item.href} href={item.href} className="flex-1">
                <div className={`flex flex-col items-center gap-1 py-3 transition-colors ${
                  isActive ? 'text-[#FF6B00]' : 'text-gray-400'
                }`}>
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
