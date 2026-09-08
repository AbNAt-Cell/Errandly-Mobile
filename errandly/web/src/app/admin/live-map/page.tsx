'use client';
import { useQuery } from '@tanstack/react-query';
import { adminApi } from '@/lib/api';
import dynamic from 'next/dynamic';
import { Activity, AlertTriangle, MapPin, Users } from 'lucide-react';

const LiveMapComponent = dynamic(() => import('@/components/admin/LiveMap'), { ssr: false });

export default function AdminLiveMapPage() {
  const { data, isLoading, refetch } = useQuery({
    queryKey: ['admin-live-map'],
    queryFn: () => adminApi.liveMap().then((r) => r.data),
    refetchInterval: 15000,
  });

  return (
    <div className="p-6 space-y-4">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-foreground">Live Monitoring</h1>
          <p className="text-muted-foreground text-sm">Real-time runner locations and active errands</p>
        </div>
        <div className="flex items-center gap-2 text-sm text-muted-foreground">
          <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
          Auto-refreshes every 15s
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-4 gap-4">
        <div className="bg-card rounded-2xl p-4 border border-border flex items-center gap-3">
          <div className="w-10 h-10 bg-green-100 rounded-xl flex items-center justify-center">
            <Users className="w-5 h-5 text-green-600" />
          </div>
          <div>
            <p className="text-xl font-bold text-foreground">{data?.runners?.length ?? 0}</p>
            <p className="text-xs text-muted-foreground">Online Runners</p>
          </div>
        </div>
        <div className="bg-card rounded-2xl p-4 border border-border flex items-center gap-3">
          <div className="w-10 h-10 bg-[#FF6B00]/10 rounded-xl flex items-center justify-center">
            <Activity className="w-5 h-5 text-[#FF6B00]" />
          </div>
          <div>
            <p className="text-xl font-bold text-foreground">{data?.active_errands?.length ?? 0}</p>
            <p className="text-xs text-muted-foreground">Active Errands</p>
          </div>
        </div>
        <div className="bg-card rounded-2xl p-4 border border-border flex items-center gap-3">
          <div className="w-10 h-10 bg-red-100 rounded-xl flex items-center justify-center">
            <AlertTriangle className="w-5 h-5 text-red-600" />
          </div>
          <div>
            <p className="text-xl font-bold text-foreground">{data?.active_panics?.length ?? 0}</p>
            <p className="text-xs text-muted-foreground">Active Panics</p>
          </div>
        </div>
        <div className="bg-card rounded-2xl p-4 border border-border flex items-center gap-3">
          <div className="w-10 h-10 bg-blue-100 rounded-xl flex items-center justify-center">
            <MapPin className="w-5 h-5 text-blue-600" />
          </div>
          <div>
            <p className="text-xl font-bold text-foreground">5</p>
            <p className="text-xs text-muted-foreground">Service Areas</p>
          </div>
        </div>
      </div>

      {/* Map */}
      <div className="bg-card rounded-2xl border border-border overflow-hidden" style={{ height: '600px' }}>
        <LiveMapComponent runners={data?.runners ?? []} errands={data?.active_errands ?? []} panics={data?.active_panics ?? []} />
      </div>

      {/* Active panics alert */}
      {(data?.active_panics?.length ?? 0) > 0 && (
        <div className="bg-red-50 border border-red-200 rounded-2xl p-4">
          <div className="flex items-center gap-2 mb-3">
            <AlertTriangle className="w-5 h-5 text-red-600" />
            <h3 className="font-bold text-red-700">{data?.active_panics?.length} Active Panic Alert(s)</h3>
          </div>
          <div className="space-y-2">
            {data?.active_panics?.map((panic: any) => (
              <div key={panic.id} className="bg-card rounded-xl p-3 border border-red-200 flex items-center justify-between">
                <div>
                  <p className="font-semibold text-red-700">{panic.errand?.title}</p>
                  <p className="text-sm text-muted-foreground">Triggered by: {panic.triggered_by?.first_name} {panic.triggered_by?.last_name}</p>
                </div>
                <button className="px-4 py-2 bg-red-600 text-white text-sm font-semibold rounded-xl hover:bg-red-700 transition">
                  Respond
                </button>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
