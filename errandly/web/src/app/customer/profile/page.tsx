'use client';
import { useQuery } from '@tanstack/react-query';
import { authApi } from '@/lib/api';
import { useAuthStore } from '@/store/authStore';
import { Shield, Star, CreditCard, MapPin, Bell, Lock, HelpCircle, LogOut, ChevronRight } from 'lucide-react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import toast from 'react-hot-toast';

export default function CustomerProfilePage() {
  const { user, logout } = useAuthStore();
  const router = useRouter();

  const { data } = useQuery({
    queryKey: ['me'],
    queryFn: () => authApi.me().then((r) => r.data),
  });

  const me = data?.user ?? user;

  const handleLogout = async () => {
    await logout();
    toast.success('Logged out.');
    router.push('/auth/login');
  };

  const menuGroups = [
    {
      label: 'Account',
      items: [
        { icon: Shield, label: 'Identity Verification', href: '/customer/kyc', badge: me?.kyc_status === 'approved' ? 'Verified' : me?.kyc_status === 'pending' ? 'Needed' : undefined, badgeColor: me?.kyc_status === 'approved' ? 'green' : 'amber' },
        { icon: MapPin, label: 'Saved Addresses', href: '/customer/addresses' },
        { icon: CreditCard, label: 'Payment Methods', href: '/customer/wallet' },
      ],
    },
    {
      label: 'Preferences',
      items: [
        { icon: Bell, label: 'Notifications', href: '/customer/notifications' },
        { icon: Lock, label: 'Security', href: '/customer/security' },
      ],
    },
    {
      label: 'Support',
      items: [
        { icon: HelpCircle, label: 'Help & Support', href: '/customer/support' },
      ],
    },
  ];

  return (
    <div className="pb-20">
      {/* Profile header */}
      <div className="bg-[#0E0F13] px-6 pt-8 pb-16">
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 bg-[#F97316] rounded-full flex items-center justify-center text-white text-2xl font-bold">
            {me?.first_name?.[0]}{me?.last_name?.[0]}
          </div>
          <div>
            <h2 className="text-white text-xl font-bold">{me?.full_name}</h2>
            <p className="text-gray-400 text-sm">{me?.email}</p>
            <div className="flex items-center gap-2 mt-1">
              {me?.kyc_status === 'approved' && (
                <span className="inline-flex items-center gap-1 bg-green-500/20 text-green-400 text-xs px-2.5 py-0.5 rounded-full">
                  <Shield className="w-3 h-3" /> Verified
                </span>
              )}
              {me?.kyc_status !== 'approved' && (
                <span className="inline-flex items-center gap-1 bg-amber-500/20 text-amber-400 text-xs px-2.5 py-0.5 rounded-full">
                  <Shield className="w-3 h-3" /> {me?.kyc_status}
                </span>
              )}
            </div>
          </div>
        </div>

        {/* Stats */}
        <div className="flex gap-4 mt-6">
          {[
            { label: 'Referral Code', value: me?.referral_code ?? '—' },
            { label: 'City', value: me?.city ?? '—' },
          ].map((stat) => (
            <div key={stat.label} className="flex-1 bg-white/10 rounded-xl px-4 py-3">
              <p className="text-gray-400 text-xs">{stat.label}</p>
              <p className="text-white font-semibold mt-0.5">{stat.value}</p>
            </div>
          ))}
        </div>
      </div>

      <div className="px-4 -mt-6 space-y-4">
        {menuGroups.map((group) => (
          <div key={group.label} className="bg-white dark:bg-[#17191F] rounded-2xl shadow-sm border border-gray-100 dark:border-white/10 overflow-hidden">
            <div className="px-4 py-2.5 bg-gray-50 dark:bg-white/5 border-b border-gray-100 dark:border-white/10">
              <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide">{group.label}</p>
            </div>
            {group.items.map((item, idx) => (
              <Link key={item.label} href={item.href}>
                <div className={`group flex items-center justify-between px-4 py-3.5 border-l-4 border-l-transparent hover:border-l-[#F97316] hover:bg-orange-50/40 dark:hover:bg-[#1E2028] transition-all duration-200 ${idx > 0 ? 'border-t border-gray-100 dark:border-white/5' : ''}`}>
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 bg-gray-100 dark:bg-white/5 group-hover:bg-orange-500/10 rounded-lg flex items-center justify-center transition-colors">
                      <item.icon className="w-4 h-4 text-gray-600 dark:text-gray-300 group-hover:text-[#F97316] transition-colors" />
                    </div>
                    <span className="text-sm font-medium text-[#0E0F13] dark:text-white group-hover:text-[#F97316] transition-colors">{item.label}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    {item.badge && (
                      <span className={`text-xs px-2 py-0.5 rounded-full font-medium ${item.badgeColor === 'green' ? 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400' : 'bg-amber-100 text-amber-700 dark:bg-amber-500/20 dark:text-amber-400'}`}>
                        {item.badge}
                      </span>
                    )}
                    <ChevronRight className="w-4 h-4 text-gray-400 group-hover:text-[#F97316] group-hover:translate-x-0.5 transition-all" />
                  </div>
                </div>
              </Link>
            ))}
          </div>
        ))}

        <button
          onClick={handleLogout}
          className="w-full bg-white dark:bg-[#17191F] rounded-2xl border border-gray-100 dark:border-white/10 p-4 flex items-center gap-3 text-red-600 dark:text-red-400 border-l-4 border-l-transparent hover:border-l-red-500 hover:bg-red-50/50 dark:hover:bg-red-500/10 transition-all duration-200"
        >
          <LogOut className="w-5 h-5" />
          <span className="font-medium">Sign Out</span>
        </button>

        <p className="text-center text-gray-400 text-xs pb-4">Errand v1.0.0 · support@errand.com</p>
      </div>
    </div>
  );
}
