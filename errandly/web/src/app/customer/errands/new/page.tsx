'use client';
import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useRouter } from 'next/navigation';
import { ArrowLeft, MapPin, Clock, DollarSign, Camera, Loader2, AlertCircle } from 'lucide-react';
import toast from 'react-hot-toast';
import Link from 'next/link';
import { customerApi } from '@/lib/api';

const CATEGORIES = [
  { value: 'package_pickup', label: '📦 Package Pickup' },
  { value: 'item_delivery', label: '🚗 Item Delivery' },
  { value: 'grocery_purchase', label: '🛒 Grocery Purchase' },
  { value: 'queue_standing', label: '🏃 Queue Standing' },
  { value: 'document_submission', label: '📄 Document Submission' },
  { value: 'document_collection', label: '📁 Document Collection' },
  { value: 'shopping_assistance', label: '🛍️ Shopping Assistance' },
  { value: 'prescription_pickup', label: '💊 Prescription Pickup' },
  { value: 'personal_assistance', label: '🤝 Personal Assistance' },
  { value: 'custom_errand', label: '✨ Custom Errand' },
];

const schema = z.object({
  title: z.string().min(5, 'Title must be at least 5 characters'),
  category: z.string().min(1, 'Select a category'),
  description: z.string().min(20, 'Describe your errand in detail (min 20 chars)'),
  urgency: z.enum(['standard', 'urgent', 'scheduled']),
  pickup_address: z.string().min(5, 'Pickup address required'),
  pickup_latitude: z.number(),
  pickup_longitude: z.number(),
  destination_address: z.string().min(5, 'Destination required'),
  destination_latitude: z.number(),
  destination_longitude: z.number(),
  recipient_name: z.string().optional(),
  recipient_phone: z.string().optional(),
  item_details: z.string().optional(),
  special_instructions: z.string().optional(),
  budget: z.number().min(500, 'Minimum budget is ₦500'),
});

type FormData = z.infer<typeof schema>;

const STEP_LABELS = ['Task Info', 'Locations', 'Budget & Schedule', 'Review'];

export default function CreateErrandPage() {
  const [step, setStep] = useState(0);
  const router = useRouter();

  const { register, handleSubmit, watch, setValue, getValues, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      urgency: 'standard',
      pickup_latitude: 5.0543,
      pickup_longitude: 7.9139,
      destination_latitude: 5.0543,
      destination_longitude: 7.9139,
      budget: 2000,
    },
  });

  const budget = watch('budget') || 0;
  const platformFee = Math.ceil(budget * 0.15);
  const total = budget + platformFee;

  const onSubmit = async (data: FormData) => {
    try {
      const response = await customerApi.createErrand(data);
      toast.success('Errand posted! Finding a runner for you...');
      router.push(`/customer/errands/${response.data.errand.id}`);
    } catch (error: any) {
      const errs = error.response?.data?.errors;
      if (errs) {
        Object.values(errs).flat().forEach((msg: any) => toast.error(msg));
      } else {
        toast.error(error.response?.data?.message || 'Failed to post errand');
      }
    }
  };

  return (
    <div className="p-4 max-w-2xl mx-auto">
      <div className="flex items-center gap-4 mb-6">
        <Link href="/customer/dashboard" className="p-2 hover:bg-gray-100 rounded-xl transition">
          <ArrowLeft className="w-5 h-5 text-gray-600" />
        </Link>
        <h1 className="text-xl font-bold text-[#0A1628]">Post New Errand</h1>
      </div>

      {/* Progress Steps */}
      <div className="flex items-center gap-2 mb-8">
        {STEP_LABELS.map((label, idx) => (
          <div key={label} className="flex items-center gap-2 flex-1">
            <div className={`flex items-center justify-center w-8 h-8 rounded-full text-sm font-bold transition-colors ${
              idx <= step ? 'bg-[#FF6B00] text-white' : 'bg-gray-200 text-gray-500'
            }`}>
              {idx + 1}
            </div>
            <span className={`text-xs hidden md:block ${idx <= step ? 'text-[#FF6B00] font-medium' : 'text-gray-400'}`}>{label}</span>
            {idx < STEP_LABELS.length - 1 && <div className={`flex-1 h-0.5 ${idx < step ? 'bg-[#FF6B00]' : 'bg-gray-200'}`} />}
          </div>
        ))}
      </div>

      <form onSubmit={handleSubmit(onSubmit)}>
        {/* Step 0: Task Info */}
        {step === 0 && (
          <div className="space-y-5">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Task Title</label>
              <input
                {...register('title')}
                className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00]"
                placeholder="e.g. Pick up my medicine from pharmacy"
              />
              {errors.title && <p className="text-red-500 text-xs mt-1">{errors.title.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Category</label>
              <select {...register('category')} className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00] bg-white">
                <option value="">Select category...</option>
                {CATEGORIES.map((cat) => (
                  <option key={cat.value} value={cat.value}>{cat.label}</option>
                ))}
              </select>
              {errors.category && <p className="text-red-500 text-xs mt-1">{errors.category.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Description</label>
              <textarea
                {...register('description')}
                rows={4}
                className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00] resize-none"
                placeholder="Describe exactly what you need done, any special notes, item quantities..."
              />
              {errors.description && <p className="text-red-500 text-xs mt-1">{errors.description.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Urgency</label>
              <div className="grid grid-cols-3 gap-3">
                {[
                  { value: 'standard', label: '🕐 Standard', desc: 'Within hours' },
                  { value: 'urgent', label: '⚡ Urgent', desc: 'ASAP' },
                  { value: 'scheduled', label: '📅 Scheduled', desc: 'Set time' },
                ].map((opt) => {
                  const current = watch('urgency');
                  return (
                    <div
                      key={opt.value}
                      onClick={() => setValue('urgency', opt.value as any)}
                      className={`p-3 rounded-xl border-2 cursor-pointer text-center transition ${
                        current === opt.value ? 'border-[#FF6B00] bg-orange-50' : 'border-gray-200 hover:border-gray-300'
                      }`}
                    >
                      <div className="text-lg mb-1">{opt.label}</div>
                      <div className="text-xs text-gray-500">{opt.desc}</div>
                    </div>
                  );
                })}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Item Details (optional)</label>
              <textarea
                {...register('item_details')}
                rows={2}
                className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00] resize-none"
                placeholder="List of items, quantities, brands, etc."
              />
            </div>
          </div>
        )}

        {/* Step 1: Locations */}
        {step === 1 && (
          <div className="space-y-5">
            <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 text-sm text-blue-700 flex gap-2">
              <MapPin className="w-5 h-5 flex-shrink-0 mt-0.5" />
              <span>Enter exact addresses. In the mobile app, you can pin locations on the map.</span>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Pickup Address</label>
              <input
                {...register('pickup_address')}
                className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00]"
                placeholder="e.g. 12 Udo Udoma Avenue, Uyo, Akwa Ibom"
              />
              {errors.pickup_address && <p className="text-red-500 text-xs mt-1">{errors.pickup_address.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Destination Address</label>
              <input
                {...register('destination_address')}
                className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00]"
                placeholder="e.g. 5 Oron Road, Uyo, Akwa Ibom"
              />
              {errors.destination_address && <p className="text-red-500 text-xs mt-1">{errors.destination_address.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Recipient Name (optional)</label>
              <input
                {...register('recipient_name')}
                className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00]"
                placeholder="Who will receive the delivery?"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Recipient Phone (optional)</label>
              <input
                {...register('recipient_phone')}
                className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00]"
                placeholder="+234..."
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Special Instructions (optional)</label>
              <textarea
                {...register('special_instructions')}
                rows={3}
                className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00] resize-none"
                placeholder="Any special instructions for the runner..."
              />
            </div>
          </div>
        )}

        {/* Step 2: Budget */}
        {step === 2 && (
          <div className="space-y-5">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Your Budget (₦)</label>
              <div className="relative">
                <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 font-semibold">₦</span>
                <input
                  {...register('budget', { valueAsNumber: true })}
                  type="number"
                  min="500"
                  className="w-full pl-8 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#FF6B00] text-lg font-bold"
                />
              </div>
              {errors.budget && <p className="text-red-500 text-xs mt-1">{errors.budget.message}</p>}

              {/* Suggested amounts */}
              <div className="flex gap-2 mt-3">
                {[1000, 2000, 3500, 5000].map((amount) => (
                  <button
                    key={amount}
                    type="button"
                    onClick={() => setValue('budget', amount)}
                    className="px-3 py-1.5 border border-gray-200 rounded-lg text-sm hover:border-[#FF6B00] hover:text-[#FF6B00] transition"
                  >
                    ₦{amount.toLocaleString()}
                  </button>
                ))}
              </div>
            </div>

            {/* Payment breakdown */}
            <div className="bg-gray-50 rounded-xl p-4 space-y-3">
              <div className="flex justify-between text-sm">
                <span className="text-gray-600">Runner payment</span>
                <span className="font-medium">₦{budget.toLocaleString()}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-600">Platform fee (15%)</span>
                <span className="font-medium">₦{platformFee.toLocaleString()}</span>
              </div>
              <div className="border-t border-gray-200 pt-3 flex justify-between">
                <span className="font-semibold text-[#0A1628]">Total</span>
                <span className="font-bold text-[#FF6B00] text-lg">₦{total.toLocaleString()}</span>
              </div>
              <p className="text-xs text-gray-500">Payment is held securely in escrow and released only after you confirm completion.</p>
            </div>
          </div>
        )}

        {/* Step 3: Review */}
        {step === 3 && (
          <div className="space-y-4">
            <div className="errandly-card">
              <h3 className="font-semibold text-[#0A1628] mb-4">Review Your Errand</h3>
              <div className="space-y-3 text-sm">
                <div className="flex justify-between">
                  <span className="text-gray-500">Title</span>
                  <span className="font-medium text-right max-w-xs">{watch('title')}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Category</span>
                  <span className="font-medium">{CATEGORIES.find((c) => c.value === watch('category'))?.label}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Urgency</span>
                  <span className="font-medium capitalize">{watch('urgency')}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Pickup</span>
                  <span className="font-medium text-right max-w-xs">{watch('pickup_address')}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Destination</span>
                  <span className="font-medium text-right max-w-xs">{watch('destination_address')}</span>
                </div>
                <div className="border-t pt-3 flex justify-between">
                  <span className="font-semibold">Total Payment</span>
                  <span className="font-bold text-[#FF6B00]">₦{total.toLocaleString()}</span>
                </div>
              </div>
            </div>

            <div className="bg-orange-50 border border-orange-200 rounded-xl p-4 text-sm text-orange-800 flex gap-2">
              <AlertCircle className="w-5 h-5 flex-shrink-0 mt-0.5" />
              <span>₦{total.toLocaleString()} will be held in escrow and only released when you confirm the errand is complete.</span>
            </div>
          </div>
        )}

        {/* Navigation */}
        <div className="flex gap-3 mt-8">
          {step > 0 && (
            <button type="button" onClick={() => setStep(step - 1)} className="flex-1 px-6 py-3 border-2 border-gray-200 rounded-xl font-semibold text-gray-700 hover:border-gray-300 transition">
              Back
            </button>
          )}
          {step < 3 ? (
            <button type="button" onClick={() => setStep(step + 1)} className="flex-1 errandly-btn-primary">
              Continue
            </button>
          ) : (
            <button type="submit" disabled={isSubmitting} className="flex-1 errandly-btn-primary flex items-center justify-center gap-2 disabled:opacity-70">
              {isSubmitting && <Loader2 className="w-5 h-5 animate-spin" />}
              {isSubmitting ? 'Posting...' : 'Post Errand & Hold Payment'}
            </button>
          )}
        </div>
      </form>
    </div>
  );
}
