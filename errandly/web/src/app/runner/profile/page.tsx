'use client';

import { useQuery } from '@tanstack/react-query';
import { authApi, runnerApi } from '@/lib/api';
import { useAuthStore } from '@/store/authStore';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import {
  DollarSign,
  Bell,
  HelpCircle,
  LogOut,
  ChevronRight,
  Star,
} from 'lucide-react';
import toast from 'react-hot-toast';

export default function RunnerProfilePage() {
  const { user, logout } = useAuthStore();
  const router = useRouter();

  const { data } = useQuery({
    queryKey: ['me'],
    queryFn: () => authApi.me().then((r) => r.data),
  });

  const { data: trust } = useQuery({
    queryKey: ['runner-trust'],
    queryFn: () => runnerApi.trustScore().then((r) => r.data),
  });

  const me = data?.user ?? user;

  const handleLogout = async () => {
    await logout();
    toast.success('Logged out.');
    router.push('/auth/login');
  };

  const menuItems = [
    { icon: Star, label: 'KYC & verification', href: '/runner/kyc' },
    { icon: DollarSign, label: 'Earnings & withdrawals', href: '/runner/earnings' },
    { icon: Bell, label: 'Notifications', href: '/runner/notifications' },
    { icon: HelpCircle, label: 'Help & support', href: 'mailto:support@errandly.com', external: true },
  ];

  return (
    <div className="pb-20">
      <div className="bg-[#0A1628] px-6 pt-8 pb-16">
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 bg-[#FF6B00] rounded-full flex items-center justify-center text-white text-2xl font-bold">
            {me?.first_name?.[0]}
            {me?.last_name?.[0]}
          </div>
          <div>
            <h2 className="text-white text-xl font-bold">{me?.full_name}</h2>
            <p className="text-gray-400 text-sm">{me?.email}</p>
            <div className="flex items-center gap-1 mt-2 text-amber-400 text-sm">
              <Star className="w-4 h-4 fill-current" />
              Trust score: {trust?.score ?? me?.runner_profile?.trust_score ?? '—'}/100
            </div>
          </div>
        </div>
      </div>

      <div className="px-4 -mt-6">
        <div className="bg-white rounded-2xl border border-gray-100 overflow-hidden">
          {menuItems.map((item, idx) => {
            const inner = (
              <div
                className={`flex items-center justify-between px-4 py-3.5 hover:bg-gray-50 ${
                  idx > 0 ? 'border-t border-gray-50' : ''
                }`}
              >
                <div className="flex items-center gap-3">
                  <div className="w-8 h-8 bg-gray-100 rounded-lg flex items-center justify-center">
                    <item.icon className="w-4 h-4 text-gray-600" />
                  </div>
                  <span className="text-sm font-medium text-[#0A1628]">{item.label}</span>
                </div>
                <ChevronRight className="w-4 h-4 text-gray-400" />
              </div>
            );

            if (item.external) {
              return (
                <a key={item.label} href={item.href}>
                  {inner}
                </a>
              );
            }
            return (
              <Link key={item.label} href={item.href}>
                {inner}
              </Link>
            );
          })}
        </div>

        <button
          type="button"
          onClick={handleLogout}
          className="w-full mt-4 bg-white rounded-2xl border border-gray-100 p-4 flex items-center gap-3 text-red-600 hover:bg-red-50"
        >
          <LogOut className="w-5 h-5" />
          <span className="font-medium">Sign Out</span>
        </button>
      </div>
    </div>
  );
}
