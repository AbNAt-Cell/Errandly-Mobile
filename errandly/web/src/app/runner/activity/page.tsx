'use client';

import { useQuery } from '@tanstack/react-query';
import { runnerApi } from '@/lib/api';
import Link from 'next/link';
import { Loader2, Package } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';

const STATUS_COLORS: Record<string, string> = {
  accepted: 'bg-amber-100 text-amber-700',
  runner_en_route: 'bg-purple-100 text-purple-700',
  item_picked: 'bg-indigo-100 text-indigo-700',
  in_progress: 'bg-blue-100 text-blue-700',
  awaiting_confirmation: 'bg-orange-100 text-orange-700',
  completed: 'bg-green-100 text-green-700',
  cancelled: 'bg-gray-100 text-gray-700',
};

export default function RunnerActivityPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['runner-my-errands'],
    queryFn: () => runnerApi.myErrands({ per_page: 30 }).then((r) => r.data),
  });

  const errands = data?.data ?? [];

  return (
    <div className="p-4 pb-24">
      <h1 className="font-bold text-xl text-[#0A1628] mb-4">Activity</h1>

      {isLoading ? (
        <div className="flex justify-center py-12">
          <Loader2 className="w-6 h-6 animate-spin text-[#FF6B00]" />
        </div>
      ) : errands.length === 0 ? (
        <div className="text-center py-16">
          <Package className="w-16 h-16 text-gray-200 mx-auto mb-4" />
          <p className="text-gray-500">No errands yet</p>
          <p className="text-gray-400 text-sm mt-1">Accepted errands will show here</p>
        </div>
      ) : (
        <div className="space-y-3">
          {errands.map((errand: {
            public_id: string;
            title: string;
            status: string;
            budget?: number;
            created_at: string;
          }) => (
            <Link key={errand.public_id} href={`/runner/errands/${errand.public_id}`}>
              <div className="bg-white rounded-2xl border border-gray-100 p-4 hover:border-[#FF6B00] transition">
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0">
                    <p className="font-semibold text-[#0A1628] truncate">{errand.title}</p>
                    <p className="text-xs text-gray-400 mt-1">
                      {formatDistanceToNow(new Date(errand.created_at), { addSuffix: true })}
                    </p>
                  </div>
                  <span
                    className={`text-xs font-medium px-2.5 py-1 rounded-full shrink-0 ${
                      STATUS_COLORS[errand.status] || 'bg-gray-100 text-gray-700'
                    }`}
                  >
                    {errand.status?.replace(/_/g, ' ')}
                  </span>
                </div>
                <p className="text-[#FF6B00] font-bold mt-2">₦{errand.budget?.toLocaleString()}</p>
              </div>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
