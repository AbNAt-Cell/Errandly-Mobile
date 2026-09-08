'use client';
import { useQuery } from '@tanstack/react-query';
import { adminApi } from '@/lib/api';
import { Users, Package, AlertCircle, DollarSign, Shield, TrendingUp, Activity, MapPin, Loader2 } from 'lucide-react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar, PieChart, Pie, Cell } from 'recharts';

const COLORS = ['#FF6B00', '#0A1628', '#16A34A', '#D97706', '#DC2626'];

export default function AdminDashboard() {
  const { data: metrics, isLoading } = useQuery({
    queryKey: ['admin-dashboard'],
    queryFn: () => adminApi.dashboard().then((r) => r.data),
    refetchInterval: 30000,
  });

  const { data: chartData } = useQuery({
    queryKey: ['admin-metrics'],
    queryFn: () => adminApi.metrics({ period: '7days' }).then((r) => r.data),
  });

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <Loader2 className="w-8 h-8 animate-spin text-[#FF6B00]" />
      </div>
    );
  }

  const statCards = [
    { label: 'Total Users', value: metrics?.users?.total ?? 0, icon: Users, color: 'bg-blue-500', sub: `+${metrics?.users?.new_today ?? 0} today` },
    { label: 'Active Errands', value: metrics?.errands?.active ?? 0, icon: Activity, color: 'bg-[#FF6B00]', sub: `${metrics?.errands?.pending ?? 0} pending assignment` },
    { label: 'Online Runners', value: metrics?.runners?.online ?? 0, icon: MapPin, color: 'bg-green-500', sub: `${metrics?.runners?.verified ?? 0} verified` },
    { label: 'Open Disputes', value: metrics?.disputes?.open ?? 0, icon: AlertCircle, color: 'bg-red-500', sub: `${metrics?.disputes?.under_review ?? 0} under review` },
    { label: 'Pending KYC', value: metrics?.runners?.pending_kyc ?? 0, icon: Shield, color: 'bg-purple-500', sub: 'Awaiting review' },
    { label: "Today's Revenue", value: `₦${(metrics?.revenue?.today ?? 0).toLocaleString()}`, icon: DollarSign, color: 'bg-emerald-500', sub: `₦${(metrics?.revenue?.this_month ?? 0).toLocaleString()} this month` },
    { label: 'Completed Errands', value: metrics?.errands?.completed ?? 0, icon: TrendingUp, color: 'bg-indigo-500', sub: `${metrics?.errands?.today ?? 0} today` },
    { label: 'Active Panics', value: metrics?.incidents?.active_panics ?? 0, icon: AlertCircle, color: 'bg-rose-600', sub: 'Requires attention' },
  ];

  return (
    <div className="p-6 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-foreground">Operations Dashboard</h1>
        <p className="text-muted-foreground text-sm">Real-time platform overview</p>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        {statCards.map((card) => (
          <div key={card.label} className="bg-card rounded-2xl p-5 shadow-sm border border-border">
            <div className={`w-10 h-10 ${card.color} rounded-xl flex items-center justify-center mb-3`}>
              <card.icon className="w-5 h-5 text-white" />
            </div>
            <p className="text-2xl font-bold text-foreground">{card.value}</p>
            <p className="text-sm text-muted-foreground mt-1">{card.label}</p>
            <p className="text-xs text-gray-400 mt-1">{card.sub}</p>
          </div>
        ))}
      </div>

      {/* Charts */}
      <div className="grid md:grid-cols-2 gap-6">
        {/* Errand Volume */}
        <div className="bg-card rounded-2xl p-6 shadow-sm border border-border">
          <h3 className="font-bold text-foreground mb-4">Errand Volume (7 days)</h3>
          <ResponsiveContainer width="100%" height={200}>
            <AreaChart data={chartData?.errand_volume ?? []}>
              <defs>
                <linearGradient id="orangeGradient" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#FF6B00" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#FF6B00" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="date" tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip />
              <Area type="monotone" dataKey="total" stroke="#FF6B00" fill="url(#orangeGradient)" strokeWidth={2} />
              <Area type="monotone" dataKey="completed" stroke="#16A34A" fill="none" strokeWidth={2} />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Revenue */}
        <div className="bg-card rounded-2xl p-6 shadow-sm border border-border">
          <h3 className="font-bold text-foreground mb-4">Revenue (7 days)</h3>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={chartData?.revenue ?? []}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="date" tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip formatter={(val: any) => `₦${val.toLocaleString()}`} />
              <Bar dataKey="amount" fill="#FF6B00" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Category breakdown */}
        <div className="bg-card rounded-2xl p-6 shadow-sm border border-border">
          <h3 className="font-bold text-foreground mb-4">Errand Categories</h3>
          <ResponsiveContainer width="100%" height={200}>
            <PieChart>
              <Pie
                data={chartData?.category_breakdown ?? []}
                dataKey="count"
                nameKey="category"
                cx="50%"
                cy="50%"
                outerRadius={80}
                label={({ category, count }: any) => `${category?.replace(/_/g, ' ')}: ${count}`}
              >
                {(chartData?.category_breakdown ?? []).map((_: any, idx: number) => (
                  <Cell key={idx} fill={COLORS[idx % COLORS.length]} />
                ))}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>

        {/* Top locations */}
        <div className="bg-card rounded-2xl p-6 shadow-sm border border-border">
          <h3 className="font-bold text-foreground mb-4">Top Locations</h3>
          <div className="space-y-3">
            {(chartData?.top_locations ?? []).slice(0, 5).map((loc: any, idx: number) => (
              <div key={loc.pickup_city} className="flex items-center gap-3">
                <span className="w-6 h-6 bg-[#FF6B00]/10 text-[#FF6B00] rounded-full flex items-center justify-center text-xs font-bold">{idx + 1}</span>
                <div className="flex-1">
                  <div className="flex justify-between text-sm">
                    <span className="font-medium">{loc.pickup_city}</span>
                    <span className="text-muted-foreground">{loc.count} errands</span>
                  </div>
                  <div className="mt-1 h-1.5 bg-gray-100 rounded-full overflow-hidden">
                    <div className="h-full bg-[#FF6B00] rounded-full" style={{ width: `${(loc.count / (chartData?.top_locations?.[0]?.count || 1)) * 100}%` }} />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
