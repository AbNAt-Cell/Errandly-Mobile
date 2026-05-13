'use client';
import { useQuery } from '@tanstack/react-query';
import { customerApi } from '@/lib/api';
import { useState } from 'react';
import Link from 'next/link';
import { Plus, Package, Loader2 } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';

const STATUS_COLORS: Record<string, string> = {
  pending_assignment: 'bg-yellow-100 text-yellow-700',
  accepted: 'bg-amber-100 text-amber-700',
  runner_en_route: 'bg-purple-100 text-purple-700',
  in_progress: 'bg-indigo-100 text-indigo-700',
  awaiting_confirmation: 'bg-orange-100 text-orange-700',
  completed: 'bg-green-100 text-green-700',
  cancelled: 'bg-gray-100 text-gray-700',
  disputed: 'bg-red-100 text-red-700',
};

const STATUS_LABELS: Record<string, string> = {
  pending_assignment: 'Finding Runner',
  accepted: 'Runner Assigned',
  runner_en_route: 'En Route',
  in_progress: 'In Progress',
  awaiting_confirmation: 'Awaiting Confirmation',
  completed: 'Completed',
  cancelled: 'Cancelled',
  disputed: 'Disputed',
};

const CATEGORY_EMOJIS: Record<string, string> = {
  package_pickup: '📦', item_delivery: '🚗', grocery_purchase: '🛒',
  queue_standing: '🏃', document_submission: '📄', shopping_assistance: '🛍️',
  prescription_pickup: '💊', personal_assistance: '🤝', custom_errand: '✨',
};

const TABS = [
  { label: 'All', status: '' },
  { label: 'Active', status: 'pending_assignment,accepted,runner_en_route,in_progress,awaiting_confirmation' },
  { label: 'Completed', status: 'completed' },
  { label: 'Cancelled', status: 'cancelled,disputed' },
];

export default function CustomerErrandsPage() {
  const [activeTab, setActiveTab] = useState(0);

  const { data, isLoading } = useQuery({
    queryKey: ['customer-errands', activeTab],
    queryFn: () => customerApi.errands(TABS[activeTab].status ? { status: TABS[activeTab].status } : undefined).then((r) => r.data),
  });

  return (
    <div className="pb-20">
      <div className="bg-white border-b border-gray-100 sticky top-16 z-30">
        <div className="flex gap-1 px-4 py-2">
          {TABS.map((tab, idx) => (
            <button
              key={tab.label}
              onClick={() => setActiveTab(idx)}
              className={`flex-1 py-2 text-sm font-medium rounded-lg transition ${
                activeTab === idx ? 'bg-[#FF6B00] text-white' : 'text-gray-500 hover:text-[#FF6B00]'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>
      </div>

      <div className="p-4">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-bold text-[#0A1628]">{data?.total ?? 0} errands</h2>
          <Link href="/customer/errands/new" className="errandly-btn-primary text-sm py-2 flex items-center gap-1.5">
            <Plus className="w-4 h-4" />
            New Errand
          </Link>
        </div>

        {isLoading ? (
          <div className="flex justify-center py-12">
            <Loader2 className="w-8 h-8 animate-spin text-[#FF6B00]" />
          </div>
        ) : data?.data?.length === 0 ? (
          <div className="text-center py-16">
            <Package className="w-16 h-16 text-gray-200 mx-auto mb-4" />
            <p className="text-gray-500 font-medium">No errands yet</p>
            <p className="text-gray-400 text-sm mt-1">Post your first errand to get started</p>
            <Link href="/customer/errands/new" className="inline-block errandly-btn-primary mt-4">
              Post an Errand
            </Link>
          </div>
        ) : (
          <div className="space-y-3">
            {data?.data?.map((errand: any) => {
              const emoji = CATEGORY_EMOJIS[errand.category] ?? '✨';
              const statusColor = STATUS_COLORS[errand.status] || 'bg-gray-100 text-gray-700';
              const statusLabel = STATUS_LABELS[errand.status] || errand.status;

              return (
                <Link key={errand.id} href={`/customer/errands/${errand.id}`}>
                  <div className="bg-white rounded-2xl border border-gray-100 p-4 hover:border-[#FF6B00] transition">
                    <div className="flex items-start gap-3">
                      <div className="w-11 h-11 bg-orange-50 rounded-xl flex items-center justify-center flex-shrink-0 text-2xl">
                        {emoji}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="flex items-start justify-between gap-2">
                          <p className="font-semibold text-[#0A1628] truncate">{errand.title}</p>
                          <span className={`text-xs font-medium px-2.5 py-1 rounded-full flex-shrink-0 ${statusColor}`}>
                            {statusLabel}
                          </span>
                        </div>
                        <p className="text-sm text-gray-500 mt-1 truncate">{errand.pickup_address}</p>
                        <div className="flex items-center justify-between mt-2">
                          <p className="text-xs text-gray-400">{formatDistanceToNow(new Date(errand.created_at), { addSuffix: true })}</p>
                          <p className="font-bold text-[#FF6B00]">₦{errand.budget?.toLocaleString()}</p>
                        </div>
                      </div>
                    </div>
                  </div>
                </Link>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
