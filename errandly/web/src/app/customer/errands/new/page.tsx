'use client';

import { useRef, useState } from 'react';
import { useForm, type FieldPath } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useRouter } from 'next/navigation';
import {
  ArrowLeft,
  MapPin,
  Loader2,
  AlertCircle,
  Sparkles,
  Camera,
  Wand2,
  ChevronRight,
} from 'lucide-react';
import toast from 'react-hot-toast';
import Link from 'next/link';
import { aiApi, customerApi } from '@/lib/api';
import { applyDraftToForm, type ErrandDraft } from '@/lib/errandDraft';
import CreateErrandAiChat from '@/components/customer/CreateErrandAiChat';

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
  const [aiMode, setAiMode] = useState<'quick' | 'chat'>('quick');
  const [nlText, setNlText] = useState('');
  const [aiLoading, setAiLoading] = useState(false);
  const [budgetLoading, setBudgetLoading] = useState(false);
  const [clarifyingQuestions, setClarifyingQuestions] = useState<string[]>([]);
  const [etaHint, setEtaHint] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const router = useRouter();

  const stepFields: FieldPath<FormData>[][] = [
    ['title', 'category', 'description'],
    ['pickup_address', 'destination_address'],
    ['budget', 'urgency'],
    [],
  ];

  const {
    register,
    handleSubmit,
    watch,
    setValue,
    getValues,
    trigger,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      urgency: 'standard',
      pickup_latitude: 5.0543,
      pickup_longitude: 7.9139,
      destination_latitude: 5.021,
      destination_longitude: 7.934,
      budget: 2500,
    },
  });

  const budget = watch('budget') || 0;
  const platformFee = Math.ceil(budget * 0.15);
  const total = budget + platformFee;

  const goToNextStep = async () => {
    const fields = stepFields[step];
    if (fields.length > 0) {
      const valid = await trigger(fields);
      if (!valid) {
        toast.error('Please complete the required fields on this step.');
        return;
      }
    }
    setStep(step + 1);
  };

  const handleDraftFromAi = (draft: ErrandDraft, questions?: string[]) => {
    applyDraftToForm(draft, setValue);
    setClarifyingQuestions(questions ?? draft.clarifying_questions ?? []);
  };

  const handleParseText = async () => {
    if (!nlText.trim()) {
      toast.error('Describe your errand in a sentence first.');
      return;
    }
    setAiLoading(true);
    setClarifyingQuestions([]);
    try {
      const { data } = await aiApi.parseErrandText(nlText.trim());
      const draft = data.draft as ErrandDraft;
      applyDraftToForm(draft, setValue);
      if (draft.clarifying_questions?.length) {
        setClarifyingQuestions(draft.clarifying_questions);
      }
      toast.success('Form filled from your description — review and edit below.');
    } catch (error: unknown) {
      const err = error as { response?: { data?: { message?: string } } };
      toast.error(err.response?.data?.message || 'Could not parse description.');
    } finally {
      setAiLoading(false);
    }
  };

  const handleParseImage = async (file: File) => {
    if (file.size > 8 * 1024 * 1024) {
      toast.error('Image must be under 8MB.');
      return;
    }
    setAiLoading(true);
    setClarifyingQuestions([]);
    try {
      const dataUrl = await new Promise<string>((resolve, reject) => {
        const reader = new FileReader();
        reader.onload = () => resolve(reader.result as string);
        reader.onerror = reject;
        reader.readAsDataURL(file);
      });
      const { data } = await aiApi.parseErrandImage(dataUrl);
      const draft = data.draft as ErrandDraft;
      applyDraftToForm(draft, setValue);
      if (draft.clarifying_questions?.length) {
        setClarifyingQuestions(draft.clarifying_questions);
      }
      toast.success('Form filled from your image — review and edit below.');
    } catch (error: unknown) {
      const err = error as { response?: { data?: { message?: string } } };
      toast.error(err.response?.data?.message || 'Could not read image.');
    } finally {
      setAiLoading(false);
    }
  };

  const handleSuggestBudget = async () => {
    const values = getValues();
    if (!values.category) {
      toast.error('Select a category first (go back to Task Info).');
      return;
    }
    setBudgetLoading(true);
    setEtaHint(null);
    try {
      const { data } = await aiApi.suggestBudget({
        category: values.category,
        pickup_latitude: values.pickup_latitude,
        pickup_longitude: values.pickup_longitude,
        destination_latitude: values.destination_latitude,
        destination_longitude: values.destination_longitude,
        urgency: values.urgency,
      });
      if (data.suggested_budget_kobo) {
        setValue('budget', data.suggested_budget_kobo);
      }
      if (data.suggested_eta_minutes) {
        setEtaHint(`Estimated time: ~${data.suggested_eta_minutes} minutes`);
      }
      toast.success(data.explanation || 'Budget suggestion applied.');
    } catch (error: unknown) {
      const err = error as { response?: { data?: { message?: string } } };
      toast.error(err.response?.data?.message || 'Could not suggest budget.');
    } finally {
      setBudgetLoading(false);
    }
  };

  const normalizeAddress = async (field: 'pickup' | 'destination') => {
    const key = field === 'pickup' ? 'pickup_address' : 'destination_address';
    const text = getValues(key);
    if (!text?.trim()) {
      toast.error('Enter an address to normalize.');
      return;
    }
    try {
      const { data } = await aiApi.normalizeAddress(text.trim(), 'Uyo');
      const candidate = data.candidates?.[0];
      if (!candidate) {
        toast.error('No matches found — try a more specific landmark.');
        return;
      }
      setValue(key, candidate.label);
      setValue(
        field === 'pickup' ? 'pickup_latitude' : 'destination_latitude',
        Number(candidate.latitude),
      );
      setValue(
        field === 'pickup' ? 'pickup_longitude' : 'destination_longitude',
        Number(candidate.longitude),
      );
      toast.success('Address updated — confirm on map in the app if needed.');
    } catch {
      toast.error('Could not normalize address.');
    }
  };

  const onSubmit = async (data: FormData) => {
    try {
      const response = await customerApi.createErrand(data);
      toast.success('Errand posted! Finding a runner for you...');
      router.push(`/customer/errands/${response.data.errand.public_id}`);
    } catch (error: unknown) {
      const err = error as { response?: { data?: { errors?: Record<string, string[]>; message?: string } } };
      const errs = err.response?.data?.errors;
      if (errs) {
        Object.values(errs).flat().forEach((msg) => toast.error(msg));
      } else {
        toast.error(err.response?.data?.message || 'Failed to post errand');
      }
    }
  };

  return (
    <div className="p-4 w-full">
      <div className="flex items-center gap-4 mb-6">
        <Link href="/customer/dashboard" className="p-2 hover:bg-muted rounded-xl transition">
          <ArrowLeft className="w-5 h-5 text-muted-foreground" />
        </Link>
        <div>
          <h1 className="text-xl font-bold text-foreground">Post New Errand</h1>
          <p className="text-xs text-muted-foreground">Talk, scan, type, or fill in manually</p>
        </div>
      </div>

      <div className="flex items-center gap-2 mb-8">
        {STEP_LABELS.map((label, idx) => (
          <div key={label} className="flex items-center gap-2 flex-1">
            <div
              className={`flex items-center justify-center w-8 h-8 rounded-full text-sm font-bold transition-colors ${
                idx <= step ? 'bg-[#FF6B00] text-white' : 'bg-gray-200 text-muted-foreground'
              }`}
            >
              {idx + 1}
            </div>
            <span
              className={`text-xs hidden md:block ${
                idx <= step ? 'text-[#FF6B00] font-medium' : 'text-gray-400'
              }`}
            >
              {label}
            </span>
            {idx < STEP_LABELS.length - 1 && (
              <div className={`flex-1 h-0.5 ${idx < step ? 'bg-[#FF6B00]' : 'bg-gray-200'}`} />
            )}
          </div>
        ))}
      </div>

      <form onSubmit={handleSubmit(onSubmit)}>
        {step === 0 && (
          <div className="space-y-5">
            <div className="space-y-3">
              <div className="flex gap-2 p-1 bg-gray-100 rounded-xl">
                <button
                  type="button"
                  onClick={() => setAiMode('quick')}
                  className={`flex-1 py-2 text-sm font-medium rounded-lg transition ${
                    aiMode === 'quick' ? 'bg-card text-[#FF6B00] shadow-sm' : 'text-muted-foreground'
                  }`}
                >
                  Quick fill
                </button>
                <button
                  type="button"
                  onClick={() => setAiMode('chat')}
                  className={`flex-1 py-2 text-sm font-medium rounded-lg transition ${
                    aiMode === 'chat' ? 'bg-card text-[#FF6B00] shadow-sm' : 'text-muted-foreground'
                  }`}
                >
                  Talk with AI
                </button>
              </div>

              {aiMode === 'chat' ? (
                <CreateErrandAiChat onDraft={handleDraftFromAi} />
              ) : (
            <div className="rounded-2xl border-2 border-[#FF6B00]/20 bg-gradient-to-br from-orange-50 to-white p-4 space-y-4">
              <div className="flex items-center gap-2 text-[#FF6B00]">
                <Sparkles className="w-5 h-5" />
                <span className="font-semibold text-foreground">Smart create</span>
              </div>

              <textarea
                value={nlText}
                onChange={(e) => setNlText(e.target.value)}
                rows={3}
                placeholder='e.g. "Buy Peak milk and bread from Shoprite and deliver to Ewet Housing, budget ₦2,500"'
                className="w-full px-4 py-3 border border-orange-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-primary/40 resize-none text-sm"
                disabled={aiLoading}
              />

              <div className="flex flex-wrap gap-2">
                <button
                  type="button"
                  onClick={handleParseText}
                  disabled={aiLoading}
                  className="flex-1 min-w-[140px] flex items-center justify-center gap-2 px-4 py-2.5 bg-[#FF6B00] text-white rounded-xl text-sm font-semibold disabled:opacity-60"
                >
                  {aiLoading ? (
                    <Loader2 className="w-4 h-4 animate-spin" />
                  ) : (
                    <Wand2 className="w-4 h-4" />
                  )}
                  Fill with AI
                </button>
                <button
                  type="button"
                  onClick={() => fileInputRef.current?.click()}
                  disabled={aiLoading}
                  className="flex items-center justify-center gap-2 px-4 py-2.5 border-2 border-[#FF6B00] text-[#FF6B00] rounded-xl text-sm font-semibold disabled:opacity-60"
                >
                  <Camera className="w-4 h-4" />
                  Scan list / photo
                </button>
                <input
                  ref={fileInputRef}
                  type="file"
                  accept="image/*"
                  className="hidden"
                  onChange={(e) => {
                    const file = e.target.files?.[0];
                    if (file) handleParseImage(file);
                    e.target.value = '';
                  }}
                />
              </div>

            </div>
              )}

            {clarifyingQuestions.length > 0 && (
              <div className="bg-amber-50 border border-amber-200 rounded-xl p-3 text-sm text-amber-900">
                <p className="font-medium mb-1">Please clarify:</p>
                <ul className="list-disc list-inside space-y-0.5">
                  {clarifyingQuestions.map((q) => (
                    <li key={q}>{q}</li>
                  ))}
                </ul>
              </div>
            )}
            </div>

            <div className="relative">
              <div className="absolute inset-0 flex items-center">
                <div className="w-full border-t border-input" />
              </div>
              <div className="relative flex justify-center text-xs uppercase">
                <span className="bg-background px-2 text-gray-400">or edit manually</span>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-foreground mb-1.5">Task Title</label>
              <input
                {...register('title')}
                className="w-full px-4 py-3 border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary"
                placeholder="e.g. Pick up my medicine from pharmacy"
              />
              {errors.title && <p className="text-red-500 text-xs mt-1">{errors.title.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-foreground mb-1.5">Category</label>
              <select
                {...register('category')}
                className="w-full px-4 py-3 border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary bg-card"
              >
                <option value="">Select category...</option>
                {CATEGORIES.map((cat) => (
                  <option key={cat.value} value={cat.value}>
                    {cat.label}
                  </option>
                ))}
              </select>
              {errors.category && <p className="text-red-500 text-xs mt-1">{errors.category.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-foreground mb-1.5">
                Instructions for runner
              </label>
              <p className="text-xs text-muted-foreground mb-1.5">
                Be specific — runners see this before accepting (what to buy, where to go, quantities).
              </p>
              <textarea
                {...register('description')}
                rows={4}
                className="w-full px-4 py-3 border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary resize-none"
                placeholder="e.g. Buy 2 tins Peak milk and 1 loaf of bread at Shoprite. Deliver to Ewet Housing gate. Call on arrival."
              />
              {errors.description && (
                <p className="text-red-500 text-xs mt-1">{errors.description.message}</p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-foreground mb-1.5">Urgency</label>
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
                      onClick={() => setValue('urgency', opt.value as FormData['urgency'])}
                      className={`p-3 rounded-xl border-2 cursor-pointer text-center transition ${
                        current === opt.value
                          ? 'border-[#FF6B00] bg-orange-50'
                          : 'border-input hover:border-gray-300'
                      }`}
                    >
                      <div className="text-lg mb-1">{opt.label}</div>
                      <div className="text-xs text-muted-foreground">{opt.desc}</div>
                    </div>
                  );
                })}
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-foreground mb-1.5">Item Details (optional)</label>
              <textarea
                {...register('item_details')}
                rows={2}
                className="w-full px-4 py-3 border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary resize-none"
                placeholder="List of items, quantities, brands..."
              />
            </div>
          </div>
        )}

        {step === 1 && (
          <div className="space-y-5">
            <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 text-sm text-blue-700 flex gap-2">
              <MapPin className="w-5 h-5 flex-shrink-0 mt-0.5" />
              <span>Use AI to normalize landmarks, then confirm addresses are correct.</span>
            </div>

            <div>
              <label className="block text-sm font-medium text-foreground mb-1.5">Pickup Address</label>
              <div className="flex gap-2">
                <input
                  {...register('pickup_address')}
                  className="flex-1 px-4 py-3 border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary"
                  placeholder="e.g. Shoprite, Uyo"
                />
                <button
                  type="button"
                  onClick={() => normalizeAddress('pickup')}
                  className="px-3 py-2 text-xs font-medium text-[#FF6B00] border border-[#FF6B00] rounded-xl whitespace-nowrap"
                >
                  AI fix
                </button>
              </div>
              {errors.pickup_address && (
                <p className="text-red-500 text-xs mt-1">{errors.pickup_address.message}</p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-foreground mb-1.5">Destination Address</label>
              <div className="flex gap-2">
                <input
                  {...register('destination_address')}
                  className="flex-1 px-4 py-3 border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary"
                  placeholder="e.g. Ewet Housing, Uyo"
                />
                <button
                  type="button"
                  onClick={() => normalizeAddress('destination')}
                  className="px-3 py-2 text-xs font-medium text-[#FF6B00] border border-[#FF6B00] rounded-xl whitespace-nowrap"
                >
                  AI fix
                </button>
              </div>
              {errors.destination_address && (
                <p className="text-red-500 text-xs mt-1">{errors.destination_address.message}</p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-foreground mb-1.5">Recipient Name (optional)</label>
              <input
                {...register('recipient_name')}
                className="w-full px-4 py-3 border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-foreground mb-1.5">Recipient Phone (optional)</label>
              <input
                {...register('recipient_phone')}
                className="w-full px-4 py-3 border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary"
                placeholder="+234..."
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-foreground mb-1.5">Special Instructions (optional)</label>
              <textarea
                {...register('special_instructions')}
                rows={3}
                className="w-full px-4 py-3 border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary resize-none"
              />
            </div>
          </div>
        )}

        {step === 2 && (
          <div className="space-y-5">
            <button
              type="button"
              onClick={handleSuggestBudget}
              disabled={budgetLoading}
              className="w-full flex items-center justify-center gap-2 py-3 border-2 border-dashed border-[#FF6B00]/50 rounded-xl text-[#FF6B00] font-medium text-sm hover:bg-orange-50 disabled:opacity-60"
            >
              {budgetLoading ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <Sparkles className="w-4 h-4" />
              )}
              Suggest budget & ETA with AI
            </button>
            {etaHint && <p className="text-sm text-muted-foreground text-center">{etaHint}</p>}

            <div>
              <label className="block text-sm font-medium text-foreground mb-1.5">Your Budget (₦)</label>
              <div className="relative">
                <span className="absolute left-4 top-1/2 -translate-y-1/2 text-muted-foreground font-semibold">₦</span>
                <input
                  {...register('budget', { valueAsNumber: true })}
                  type="number"
                  min={500}
                  className="w-full pl-8 pr-4 py-3 border border-input rounded-xl focus:outline-none focus:ring-2 focus:ring-primary text-lg font-bold"
                />
              </div>
              {errors.budget && <p className="text-red-500 text-xs mt-1">{errors.budget.message}</p>}
              <div className="flex gap-2 mt-3 flex-wrap">
                {[1000, 2000, 3500, 5000].map((amount) => (
                  <button
                    key={amount}
                    type="button"
                    onClick={() => setValue('budget', amount)}
                    className="px-3 py-1.5 border border-input rounded-lg text-sm hover:border-[#FF6B00] hover:text-[#FF6B00] transition"
                  >
                    ₦{amount.toLocaleString()}
                  </button>
                ))}
              </div>
            </div>

            <div className="bg-background rounded-xl p-4 space-y-3">
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">Runner payment</span>
                <span className="font-medium">₦{budget.toLocaleString()}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-muted-foreground">Platform fee (15%)</span>
                <span className="font-medium">₦{platformFee.toLocaleString()}</span>
              </div>
              <div className="border-t border-input pt-3 flex justify-between">
                <span className="font-semibold text-foreground">Total</span>
                <span className="font-bold text-[#FF6B00] text-lg">₦{total.toLocaleString()}</span>
              </div>
              <p className="text-xs text-muted-foreground">
                Payment is held in escrow until you confirm delivery with your OTP.
              </p>
            </div>
          </div>
        )}

        {step === 3 && (
          <div className="space-y-4">
            <div className="errandly-card">
              <h3 className="font-semibold text-foreground mb-4">Review Your Errand</h3>
              <div className="space-y-3 text-sm">
                <div className="flex justify-between gap-4">
                  <span className="text-muted-foreground shrink-0">Title</span>
                  <span className="font-medium text-right">{watch('title')}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Category</span>
                  <span className="font-medium">
                    {CATEGORIES.find((c) => c.value === watch('category'))?.label}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Pickup</span>
                  <span className="font-medium text-right max-w-[60%]">{watch('pickup_address')}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-muted-foreground">Destination</span>
                  <span className="font-medium text-right max-w-[60%]">{watch('destination_address')}</span>
                </div>
                <div className="border-t pt-3 flex justify-between">
                  <span className="font-semibold">Total</span>
                  <span className="font-bold text-[#FF6B00]">₦{total.toLocaleString()}</span>
                </div>
              </div>
            </div>
            <div className="bg-orange-50 border border-orange-200 rounded-xl p-4 text-sm text-orange-800 flex gap-2">
              <AlertCircle className="w-5 h-5 flex-shrink-0 mt-0.5" />
              <span>Review AI-filled fields before posting. You can go back to edit any step.</span>
            </div>
          </div>
        )}

        <div className="flex gap-3 mt-8">
          {step > 0 && (
            <button
              type="button"
              onClick={() => setStep(step - 1)}
              className="flex-1 px-6 py-3 border-2 border-input rounded-xl font-semibold text-foreground hover:border-gray-300 transition"
            >
              Back
            </button>
          )}
          {step < 3 ? (
            <button
              type="button"
              onClick={goToNextStep}
              className="flex-1 errandly-btn-primary flex items-center justify-center gap-1"
            >
              Continue
              <ChevronRight className="w-4 h-4" />
            </button>
          ) : (
            <button
              type="submit"
              disabled={isSubmitting}
              className="flex-1 errandly-btn-primary flex items-center justify-center gap-2 disabled:opacity-70"
            >
              {isSubmitting && <Loader2 className="w-5 h-5 animate-spin" />}
              {isSubmitting ? 'Posting...' : 'Post Errand & Hold Payment'}
            </button>
          )}
        </div>
      </form>
    </div>
  );
}
