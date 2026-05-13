'use client';
import { useQuery } from '@tanstack/react-query';
import { adminApi } from '@/lib/api';
import { useState } from 'react';
import { AreaChart, Area, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, BarChart, Bar } from 'recharts';

export default function AdminReportsPage() {
  const [period, setPeriod] = useState('30days');

  const { data: revenue } = useQuery({
    queryKey: ['admin-report-revenue', period],
    queryFn: () => adminApi.reports.revenue({ period }).then((r) => r.data),
  });

  const { data: errandsReport } = useQuery({
    queryKey: ['admin-report-errands', period],
    queryFn: () => adminApi.reports.errands({ period }).then((r) => r.data),
  });

  const { data: usersReport } = useQuery({
    queryKey: ['admin-report-users', period],
    queryFn: () => adminApi.reports.users({ period }).then((r) => r.data),
  });

  return (
    <div className="p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-[#0A1628]">Reports & Analytics</h1>
          <p className="text-gray-500 text-sm">Platform performance and business insights</p>
        </div>
        <select value={period} onChange={(e) => setPeriod(e.target.value)} className="px-4 py-2.5 border border-gray-200 rounded-xl text-sm focus:outline-none bg-white">
          <option value="7days">Last 7 days</option>
          <option value="30days">Last 30 days</option>
          <option value="90days">Last 90 days</option>
          <option value="365days">Last year</option>
        </select>
      </div>

      {/* Revenue chart */}
      <div className="bg-white rounded-2xl p-6 border border-gray-100">
        <h3 className="font-bold text-[#0A1628] mb-1">Revenue Over Time</h3>
        <p className="text-sm text-gray-500 mb-4">Total platform revenue: <strong className="text-[#FF6B00]">₦{(revenue?.total ?? 0).toLocaleString()}</strong></p>
        <ResponsiveContainer width="100%" height={220}>
          <AreaChart data={revenue?.data ?? []}>
            <defs>
              <linearGradient id="rev" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor="#FF6B00" stopOpacity={0.3} />
                <stop offset="95%" stopColor="#FF6B00" stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
            <XAxis dataKey="date" tick={{ fontSize: 11 }} />
            <YAxis tick={{ fontSize: 11 }} tickFormatter={(v) => `₦${(v / 1000).toFixed(0)}k`} />
            <Tooltip formatter={(val: any) => [`₦${val.toLocaleString()}`, 'Revenue']} />
            <Area type="monotone" dataKey="revenue" stroke="#FF6B00" fill="url(#rev)" strokeWidth={2} />
          </AreaChart>
        </ResponsiveContainer>
      </div>

      <div className="grid md:grid-cols-2 gap-6">
        {/* Errand stats */}
        <div className="bg-white rounded-2xl p-6 border border-gray-100">
          <h3 className="font-bold text-[#0A1628] mb-4">Errand Metrics</h3>
          <div className="grid grid-cols-2 gap-4 mb-4">
            {[
              { label: 'Total', value: errandsReport?.total ?? 0 },
              { label: 'Completed', value: errandsReport?.completed ?? 0 },
              { label: 'Cancelled', value: errandsReport?.cancelled ?? 0 },
              { label: 'Completion Rate', value: `${errandsReport?.completion_rate ?? 0}%` },
            ].map((m) => (
              <div key={m.label} className="bg-gray-50 rounded-xl p-3">
                <p className="text-xs text-gray-500">{m.label}</p>
                <p className="text-lg font-bold text-[#0A1628]">{m.value}</p>
              </div>
            ))}
          </div>
          <ResponsiveContainer width="100%" height={160}>
            <BarChart data={errandsReport?.by_city ?? []}>
              <XAxis dataKey="pickup_city" tick={{ fontSize: 10 }} />
              <YAxis tick={{ fontSize: 10 }} />
              <Tooltip />
              <Bar dataKey="count" fill="#FF6B00" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* User growth */}
        <div className="bg-white rounded-2xl p-6 border border-gray-100">
          <h3 className="font-bold text-[#0A1628] mb-4">User Growth</h3>
          <div className="grid grid-cols-2 gap-4 mb-4">
            {[
              { label: 'Total Customers', value: usersReport?.total_customers ?? 0 },
              { label: 'Active Customers', value: usersReport?.active_customers ?? 0 },
              { label: 'Total Runners', value: usersReport?.total_runners ?? 0 },
              { label: 'Verified Runners', value: usersReport?.verified_runners ?? 0 },
            ].map((m) => (
              <div key={m.label} className="bg-gray-50 rounded-xl p-3">
                <p className="text-xs text-gray-500">{m.label}</p>
                <p className="text-lg font-bold text-[#0A1628]">{m.value}</p>
              </div>
            ))}
          </div>
          <ResponsiveContainer width="100%" height={160}>
            <AreaChart data={usersReport?.growth ?? []}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="date" tick={{ fontSize: 10 }} />
              <YAxis tick={{ fontSize: 10 }} />
              <Tooltip />
              <Area type="monotone" dataKey="total" stroke="#0A1628" fill="#0A162820" strokeWidth={2} />
            </AreaChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
}
