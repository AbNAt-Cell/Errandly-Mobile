'use client';

import { useParams } from 'next/navigation';
import { useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { adminApi } from '@/lib/api';
import { ArrowLeft, Loader2, MapPin } from 'lucide-react';

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

export default function AdminErrandDetailPage() {
  const params = useParams();
  const publicId = params.publicId as string;

  const { data: errand, isLoading, error } = useQuery({
    queryKey: ['admin-errand', publicId],
    queryFn: () => adminApi.getErrand(publicId).then((r) => r.data),
    enabled: !!publicId,
  });

  if (isLoading) {
    return (
      <div className="p-6 flex justify-center py-20">
        <Loader2 className="w-8 h-8 animate-spin text-[#FF6B00]" />
      </div>
    );
  }

  if (error || !errand) {
    return (
      <div className="p-6">
        <Link href="/admin/errands" className="text-[#FF6B00] text-sm font-medium hover:underline">
          ← Back to errands
        </Link>
        <p className="mt-6 text-gray-500">Errand not found.</p>
      </div>
    );
  }

  return (
    <div className="p-6 max-w-3xl">
      <Link href="/admin/errands" className="inline-flex items-center gap-2 text-gray-600 hover:text-[#0A1628] mb-6">
        <ArrowLeft className="w-4 h-4" />
        Errands
      </Link>

      <div className="flex flex-wrap items-start justify-between gap-4 mb-6">
        <div>
          <h1 className="text-2xl font-bold text-[#0A1628]">{errand.title}</h1>
          <p className="text-gray-500 text-sm font-mono mt-1">{errand.public_id}</p>
        </div>
        <span className={`text-xs px-3 py-1.5 rounded-full font-medium ${STATUS_COLORS[errand.status] || 'bg-gray-100 text-gray-700'}`}>
          {errand.status?.replace(/_/g, ' ')}
        </span>
      </div>

      <div className="bg-white rounded-2xl border border-gray-100 p-6 space-y-4 text-sm">
        <div className="grid grid-cols-2 gap-4">
          <div>
            <p className="text-gray-500">Customer</p>
            <p className="font-medium">
              {errand.customer?.first_name} {errand.customer?.last_name}
            </p>
          </div>
          <div>
            <p className="text-gray-500">Runner</p>
            <p className="font-medium">
              {errand.runner
                ? `${errand.runner.first_name} ${errand.runner.last_name}`
                : '—'}
            </p>
          </div>
          <div>
            <p className="text-gray-500">Category</p>
            <p className="font-medium">{errand.category?.replace(/_/g, ' ')}</p>
          </div>
          <div>
            <p className="text-gray-500">Budget</p>
            <p className="font-medium">₦{errand.budget?.toLocaleString()}</p>
          </div>
        </div>

        <div>
          <p className="text-gray-500 mb-1">Description</p>
          <p className="text-[#0A1628] whitespace-pre-wrap">{errand.description || '—'}</p>
        </div>

        <div className="flex gap-2 text-gray-700">
          <MapPin className="w-4 h-4 text-[#FF6B00] flex-shrink-0 mt-0.5" />
          <div>
            <p><span className="text-gray-500">Pickup:</span> {errand.pickup_address}</p>
            <p className="mt-1"><span className="text-gray-500">Destination:</span> {errand.destination_address}</p>
          </div>
        </div>

        <p className="text-xs text-gray-400">
          Created {new Date(errand.created_at).toLocaleString()}
        </p>
      </div>
    </div>
  );
}
