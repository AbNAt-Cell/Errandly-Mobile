'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { customerApi } from '@/lib/api';
import Link from 'next/link';
import { ArrowLeft, Loader2, MapPin, Plus, Trash2 } from 'lucide-react';
import toast from 'react-hot-toast';

export default function CustomerAddressesPage() {
  const queryClient = useQueryClient();
  const [showForm, setShowForm] = useState(false);
  const [label, setLabel] = useState('');
  const [address, setAddress] = useState('');

  const { data: addresses, isLoading } = useQuery({
    queryKey: ['saved-addresses'],
    queryFn: () => customerApi.savedAddresses().then((r) => r.data),
  });

  const addMutation = useMutation({
    mutationFn: () =>
      customerApi.addAddress({
        label,
        address,
        city: 'Uyo',
        is_default: !addresses?.length,
      }),
    onSuccess: () => {
      toast.success('Address saved.');
      setLabel('');
      setAddress('');
      setShowForm(false);
      queryClient.invalidateQueries({ queryKey: ['saved-addresses'] });
    },
    onError: (e: { response?: { data?: { message?: string } } }) => {
      toast.error(e.response?.data?.message || 'Could not save address');
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: number) => customerApi.deleteAddress(id),
    onSuccess: () => {
      toast.success('Address removed.');
      queryClient.invalidateQueries({ queryKey: ['saved-addresses'] });
    },
  });

  return (
    <div className="p-4 pb-24 max-w-lg mx-auto">
      <div className="flex items-center gap-3 mb-6">
        <Link href="/customer/profile" className="p-2 rounded-lg hover:bg-muted">
          <ArrowLeft className="w-5 h-5" />
        </Link>
        <h1 className="font-bold text-xl text-foreground">Saved Addresses</h1>
      </div>

      {isLoading ? (
        <div className="flex justify-center py-12">
          <Loader2 className="w-6 h-6 animate-spin text-[#FF6B00]" />
        </div>
      ) : (
        <div className="space-y-3">
          {(addresses ?? []).map((a: { id: number; label: string; address: string; is_default?: boolean }) => (
            <div key={a.id} className="bg-card rounded-2xl border border-border p-4 flex items-start gap-3">
              <MapPin className="w-5 h-5 text-[#FF6B00] flex-shrink-0 mt-0.5" />
              <div className="flex-1 min-w-0">
                <p className="font-semibold text-foreground">
                  {a.label}
                  {a.is_default && (
                    <span className="ml-2 text-xs bg-orange-100 text-[#FF6B00] px-2 py-0.5 rounded-full">Default</span>
                  )}
                </p>
                <p className="text-sm text-muted-foreground mt-1">{a.address}</p>
              </div>
              <button
                type="button"
                onClick={() => deleteMutation.mutate(a.id)}
                className="p-2 text-red-500 hover:bg-red-50 rounded-lg"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          ))}
        </div>
      )}

      {showForm ? (
        <div className="mt-4 bg-card rounded-2xl border border-border p-4 space-y-3">
          <input
            value={label}
            onChange={(e) => setLabel(e.target.value)}
            placeholder="Label (e.g. Home)"
            className="w-full border border-input rounded-xl px-4 py-3 text-sm"
          />
          <input
            value={address}
            onChange={(e) => setAddress(e.target.value)}
            placeholder="Full address"
            className="w-full border border-input rounded-xl px-4 py-3 text-sm"
          />
          <div className="flex gap-2">
            <button
              type="button"
              onClick={() => addMutation.mutate()}
              disabled={!label.trim() || !address.trim() || addMutation.isPending}
              className="flex-1 errandly-btn-primary text-sm py-2.5"
            >
              Save
            </button>
            <button type="button" onClick={() => setShowForm(false)} className="px-4 py-2.5 border rounded-xl text-sm">
              Cancel
            </button>
          </div>
        </div>
      ) : (
        <button
          type="button"
          onClick={() => setShowForm(true)}
          className="mt-4 w-full flex items-center justify-center gap-2 py-3 border-2 border-dashed border-[#FF6B00]/40 rounded-xl text-[#FF6B00] font-medium"
        >
          <Plus className="w-5 h-5" />
          Add address
        </button>
      )}
    </div>
  );
}
