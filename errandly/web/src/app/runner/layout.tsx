'use client';
import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Home, Package, DollarSign, MessageSquare, User, Bell } from 'lucide-react';
import { useAuthStore } from '@/store/authStore';
import Logo from '@/components/shared/Logo';

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
    <div className="min-h-screen bg-[#0E0F13] text-[#e3e2e7]">
      <header className="bg-[#0E0F13]/90 backdrop-blur-md text-white border-b border-white/10 sticky top-0 z-40">
        <div className="max-w-2xl mx-auto px-4 h-16 flex items-center justify-between">
          <Logo iconSize="w-8 h-8" textSize="text-xl" subtext="Runner" href="/runner/dashboard" />
          <div className="flex items-center gap-3">
            <Link href="/runner/notifications" className="relative p-2 text-gray-300 hover:text-[#F97316] transition-colors">
              <Bell className="w-5 h-5" />
            </Link>
          </div>
        </div>
      </header>

      <main className="max-w-2xl mx-auto pb-20">
        {children}
      </main>

      <nav className="fixed bottom-0 left-0 right-0 bg-[#121317]/95 backdrop-blur-md border-t border-white/10 z-40">
        <div className="max-w-2xl mx-auto flex">
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
