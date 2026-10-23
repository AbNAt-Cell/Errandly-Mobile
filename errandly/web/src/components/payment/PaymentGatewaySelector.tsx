'use client';

import React from 'react';
import { CreditCard, Zap, Building2, ShieldCheck, CheckCircle2 } from 'lucide-react';

export type PaymentGatewayId = 'paystack' | 'bach';

export interface PaymentGatewaySelectorProps {
  selectedGateway: PaymentGatewayId;
  onChange: (gateway: PaymentGatewayId) => void;
  amount?: number;
  compact?: boolean;
}

export function PaymentGatewaySelector({
  selectedGateway,
  onChange,
  amount,
  compact = false,
}: PaymentGatewaySelectorProps) {
  const gateways = [
    {
      id: 'paystack' as const,
      name: 'Paystack',
      tagline: 'Cards, Bank Transfer & USSD',
      description: 'Accepts Visa, Mastercard, Verve, direct bank transfer, and USSD.',
      badge: 'POPULAR',
      badgeColor: 'bg-emerald-100 text-emerald-800 border-emerald-200',
      accentColor: 'from-orange-500/10 to-amber-500/5',
      borderColor: 'border-[#F97316]',
      ringColor: 'ring-[#F97316]/20',
      iconBg: 'bg-gradient-to-br from-[#0E0F13] to-[#F97316] text-white',
      methods: ['Debit / Credit Cards', 'Bank Transfer', 'USSD'],
      logoText: 'P',
    },
    {
      id: 'bach' as const,
      name: 'Bachs',
      tagline: 'Fast Checkout & Instant Transfer',
      description: 'Seamless checkout sessions and instant account-to-account payments.',
      badge: 'FAST & SECURE',
      badgeColor: 'bg-blue-100 text-blue-800 border-blue-200',
      accentColor: 'from-blue-500/10 to-indigo-500/5',
      borderColor: 'border-blue-600',
      ringColor: 'ring-blue-500/20',
      iconBg: 'bg-gradient-to-br from-blue-600 to-indigo-700 text-white',
      methods: ['Instant Transfer', 'Fast Checkout', 'Zero Friction'],
      logoText: 'B',
    },
  ];

  return (
    <div className="w-full space-y-3">
      <div className="flex items-center justify-between">
        <label className="text-xs font-bold uppercase tracking-wider text-gray-500">
          Select Payment Gateway
        </label>
        <span className="text-[11px] text-gray-400 flex items-center gap-1">
          <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
          PCI-DSS Compliant & Encrypted
        </span>
      </div>

      <div className={`grid ${compact ? 'grid-cols-2 gap-2.5' : 'grid-cols-1 sm:grid-cols-2 gap-3'}`}>
        {gateways.map((gw) => {
          const isSelected = selectedGateway === gw.id;

          return (
            <div
              key={gw.id}
              onClick={() => onChange(gw.id)}
              className={`relative rounded-2xl border-2 p-3.5 sm:p-4 cursor-pointer transition-all duration-200 flex flex-col justify-between ${
                isSelected
                  ? `${gw.borderColor} bg-gradient-to-br ${gw.accentColor} ring-4 ${gw.ringColor} shadow-md`
                  : 'border-gray-200 hover:border-gray-300 hover:shadow-sm bg-white'
              }`}
            >
              <div>
                {/* Header: Icon, Name & Selection badge */}
                <div className="flex items-start justify-between gap-2 mb-2">
                  <div className="flex items-center gap-2.5">
                    <div
                      className={`w-9 h-9 rounded-xl flex items-center justify-center font-bold text-sm shadow-sm ${gw.iconBg}`}
                    >
                      {gw.logoText}
                    </div>
                    <div>
                      <div className="flex items-center gap-1.5">
                        <span className="font-bold text-sm text-[#0E0F13]">{gw.name}</span>
                        <span
                          className={`text-[9px] font-extrabold px-1.5 py-0.5 rounded-full border ${gw.badgeColor}`}
                        >
                          {gw.badge}
                        </span>
                      </div>
                      <p className="text-[11px] font-medium text-gray-500">{gw.tagline}</p>
                    </div>
                  </div>

                  <div
                    className={`w-5 h-5 rounded-full border-2 flex items-center justify-center transition-colors shrink-0 mt-0.5 ${
                      isSelected
                        ? gw.id === 'bach'
                          ? 'border-blue-600 bg-blue-600 text-white'
                          : 'border-[#F97316] bg-[#F97316] text-white'
                        : 'border-gray-300'
                    }`}
                  >
                    {isSelected && <CheckCircle2 className="w-3.5 h-3.5 stroke-[3]" />}
                  </div>
                </div>

                {!compact && (
                  <p className="text-xs text-gray-600 mb-3 leading-relaxed">
                    {gw.description}
                  </p>
                )}
              </div>

              {/* Supported methods pills */}
              <div className="flex items-center gap-1.5 flex-wrap pt-2 border-t border-gray-100">
                {gw.methods.map((method) => (
                  <span
                    key={method}
                    className="text-[10px] bg-gray-100/80 text-gray-600 px-2 py-0.5 rounded-md font-medium"
                  >
                    {method}
                  </span>
                ))}
              </div>
            </div>
          );
        })}
      </div>

      {amount !== undefined && (
        <div className="text-[11px] text-gray-500 text-center pt-1">
          You will pay <strong className="text-[#0E0F13]">₦{amount.toLocaleString()}</strong> using{' '}
          <strong className="text-[#0E0F13]">
            {selectedGateway === 'bach' ? 'Bachs' : 'Paystack'}
          </strong>
        </div>
      )}
    </div>
  );
}
