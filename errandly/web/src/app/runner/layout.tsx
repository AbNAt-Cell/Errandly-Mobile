'use client';
import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Home, Package, DollarSign, MessageSquare, User, Bell, Package as LogoIcon } from 'lucide-react';
import { useAuthStore } from '@/store/authStore';

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
  }, [isAuthenticated, roles]);

  return (
    <div className="min-h-screen bg-gray-50">
      <header className="bg-[#0A1628] text-white sticky top-0 z-40">
        <div className="max-w-2xl mx-auto px-4 h-16 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 bg-[#FF6B00] rounded-lg flex items-center justify-center">
              <LogoIcon className="w-5 h-5 text-white" />
            </div>
            <span className="font-bold">Errandly Runner</span>
          </div>
          <div className="flex items-center gap-3">
            <Link href="/runner/notifications" className="relative p-2 text-gray-300 hover:text-white transition">
              <Bell className="w-6 h-6" />
            </Link>
          </div>
        </div>
      </header>

      <main className="max-w-2xl mx-auto pb-20">
        {children}
      </main>

      <nav className="fixed bottom-0 left-0 right-0 bg-[#0A1628] z-40">
        <div className="max-w-2xl mx-auto flex">
          {navItems.map((item) => {
            const isActive = pathname.startsWith(item.href);
            return (
              <Link key={item.href} href={item.href} className="flex-1">
                <div className={`flex flex-col items-center gap-1 py-3 transition-colors ${isActive ? 'text-[#FF6B00]' : 'text-gray-400'}`}>
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
