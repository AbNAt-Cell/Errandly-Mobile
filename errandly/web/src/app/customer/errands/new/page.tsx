'use client';

import { useEffect, useRef, useState } from 'react';
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
  CreditCard,
  Wallet,
  ShieldCheck,
  CheckCircle2,
  Mic,
  MicOff,
  Zap,
} from 'lucide-react';
import toast from 'react-hot-toast';
import Link from 'next/link';
import { aiApi, customerApi, walletApi, configApi } from '@/lib/api';
import { applyDraftToForm, type ErrandDraft } from '@/lib/errandDraft';
import { compressImageToDataUrl, UniversalAudioRecorder } from '@/lib/mediaUtils';
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
  budget: z.number().min(1, 'Budget is required'),
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
  const [walletBalance, setWalletBalance] = useState<number | null>(null);
  const [minErrandAmount, setMinErrandAmount] = useState<number>(500);
  const [platformCommissionRate, setPlatformCommissionRate] = useState<number>(0.15);
  const [paymentMethod, setPaymentMethod] = useState<'paystack' | 'bach' | 'wallet'>('paystack');
  const [isRedirecting, setIsRedirecting] = useState(false);
  const [quickRecording, setQuickRecording] = useState(false);
  const quickRecorderRef = useRef<UniversalAudioRecorder | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const router = useRouter();

  useEffect(() => {
    return () => {
      quickRecorderRef.current?.cancel();
    };
  }, []);

  useEffect(() => {
    configApi.get()
      .then((res) => {
        const min = res.data?.data?.min_errand_amount ?? res.data?.min_errand_amount;
        if (typeof min === 'number' && min > 0) {
          setMinErrandAmount(min);
        }
        const rate = res.data?.data?.platform_commission_rate ?? res.data?.platform_commission_rate;
        if (typeof rate === 'number' && rate > 0) {
          setPlatformCommissionRate(rate);
        }
      })
      .catch(() => {});
  }, []);

  useEffect(() => {
    walletApi.get()
      .then((res) => {
        const bal = res.data?.data?.balance ?? res.data?.balance;
        if (typeof bal === 'number') {
          setWalletBalance(bal);
        }
      })
      .catch(() => {});
  }, []);

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
  const platformFee = Math.ceil(budget * (platformCommissionRate || 0.15));
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
    if (step === 2) {
      const currentBudget = getValues('budget');
      if (!currentBudget || currentBudget < minErrandAmount) {
        toast.error(`Minimum budget is ₦${minErrandAmount.toLocaleString()}`);
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
    setAiLoading(true);
    setClarifyingQuestions([]);
    try {
      const dataUrl = await compressImageToDataUrl(file);
      const { data } = await aiApi.parseErrandImage(dataUrl);
      const draft = data.draft as ErrandDraft;
      applyDraftToForm(draft, setValue);
      if (draft.clarifying_questions?.length) {
        setClarifyingQuestions(draft.clarifying_questions);
      }
      toast.success('Form filled from your photo — review and edit below.');
    } catch (error: unknown) {
      const err = error as { response?: { data?: { message?: string } } };
      toast.error(err.response?.data?.message || 'Could not read image.');
    } finally {
      setAiLoading(false);
    }
  };

  const handleToggleQuickVoice = async () => {
    if (quickRecording) {
      if (!quickRecorderRef.current) return;
      setQuickRecording(false);
      setAiLoading(true);
      try {
        const audioDataUrl = await quickRecorderRef.current.stop();
        const { data } = await aiApi.parseErrandAudio(audioDataUrl);
        const draft = data.draft as ErrandDraft;
        applyDraftToForm(draft, setValue);
        if (draft.clarifying_questions?.length) {
          setClarifyingQuestions(draft.clarifying_questions);
        }
        toast.success('Form filled from voice note — review and edit below.');
      } catch (error: unknown) {
        const err = error as { response?: { data?: { message?: string } } };
        toast.error(err.response?.data?.message || 'Could not parse voice recording.');
      } finally {
        setAiLoading(false);
        quickRecorderRef.current = null;
      }
    } else {
      try {
        const recorder = new UniversalAudioRecorder();
        quickRecorderRef.current = recorder;
        await recorder.start();
        setQuickRecording(true);
        toast('Recording voice note… tap again when done speaking.', { icon: '🎤' });
      } catch (err: unknown) {
        setQuickRecording(false);
        const msg = err instanceof Error ? err.message : 'Could not access microphone.';
        toast.error(msg);
      }
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
    if (data.budget < minErrandAmount) {
      toast.error(`Minimum budget is ₦${minErrandAmount.toLocaleString()}`);
      return;
    }
    if (paymentMethod === 'wallet' && walletBalance !== null && walletBalance < total) {
      toast.error(`Insufficient wallet balance. Please select Paystack or Bachs, or fund your wallet.`);
      return;
    }
    try {
      setIsRedirecting(paymentMethod === 'paystack' || paymentMethod === 'bach');
      const payload = {
        ...data,
        payment_method: paymentMethod,
        frontend_url: typeof window !== 'undefined' ? window.location.origin : undefined,
      };

      const response = await customerApi.createErrand(payload);

      if ((paymentMethod === 'paystack' || paymentMethod === 'bach') && (response.data.payment?.authorization_url || response.data.payment?.checkout_url)) {
        const url = response.data.payment.authorization_url || response.data.payment.checkout_url;
        toast.success(`Redirecting to ${paymentMethod === 'bach' ? 'Bachs' : 'Paystack'} Checkout...`);
        window.location.href = url;
        return;
      }

      toast.success('Errand posted and funded from wallet! Finding a runner for you...');
      router.push(`/customer/errands/${response.data.errand.public_id}`);
    } catch (error: unknown) {
      setIsRedirecting(false);
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
    <div className="p-4 max-w-2xl mx-auto">
      <div className="flex items-center gap-4 mb-6">
        <Link href="/customer/dashboard" className="p-2 hover:bg-gray-100 rounded-xl transition">
          <ArrowLeft className="w-5 h-5 text-gray-600" />
        </Link>
        <div>
          <h1 className="text-xl font-bold text-[#0E0F13]">Post New Errand</h1>
          <p className="text-xs text-gray-500">Talk, scan, type, or fill in manually</p>
        </div>
      </div>

      <div className="flex items-center gap-2 mb-8">
        {STEP_LABELS.map((label, idx) => (
          <div key={label} className="flex items-center gap-2 flex-1">
            <div
              className={`flex items-center justify-center w-8 h-8 rounded-full text-sm font-bold transition-colors ${
                idx <= step ? 'bg-[#F97316] text-white' : 'bg-gray-200 text-gray-500'
              }`}
            >
              {idx + 1}
            </div>
            <span
              className={`text-xs hidden md:block ${
                idx <= step ? 'text-[#F97316] font-medium' : 'text-gray-400'
              }`}
            >
              {label}
            </span>
            {idx < STEP_LABELS.length - 1 && (
              <div className={`flex-1 h-0.5 ${idx < step ? 'bg-[#F97316]' : 'bg-gray-200'}`} />
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
                    aiMode === 'quick' ? 'bg-white text-[#F97316] shadow-sm' : 'text-gray-600'
                  }`}
                >
                  Quick fill
                </button>
                <button
                  type="button"
                  onClick={() => setAiMode('chat')}
                  className={`flex-1 py-2 text-sm font-medium rounded-lg transition ${
                    aiMode === 'chat' ? 'bg-white text-[#F97316] shadow-sm' : 'text-gray-600'
                  }`}
                >
                  Talk with AI
                </button>
              </div>

              {aiMode === 'chat' ? (
                <CreateErrandAiChat onDraft={handleDraftFromAi} />
              ) : (
            <div className="rounded-2xl border-2 border-[#F97316]/20 bg-gradient-to-br from-orange-50 to-white p-4 space-y-4">
              <div className="flex items-center gap-2 text-[#F97316]">
                <Sparkles className="w-5 h-5" />
                <span className="font-semibold text-[#0E0F13]">Smart create</span>
              </div>

              <textarea
                value={nlText}
                onChange={(e) => setNlText(e.target.value)}
                rows={3}
                placeholder='e.g. "Buy Peak milk and bread from Shoprite and deliver to Ewet Housing, budget ₦2,500"'
                className="w-full px-4 py-3 border border-orange-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316]/40 resize-none text-sm"
                disabled={aiLoading}
              />

              <div className="flex flex-wrap gap-2">
                <button
                  type="button"
                  onClick={handleParseText}
                  disabled={aiLoading || quickRecording}
                  className="flex-1 min-w-[130px] flex items-center justify-center gap-2 px-4 py-2.5 bg-[#F97316] text-white rounded-xl text-sm font-semibold disabled:opacity-60 hover:bg-orange-600 transition"
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
                  disabled={aiLoading || quickRecording}
                  className="flex items-center justify-center gap-2 px-4 py-2.5 border-2 border-[#F97316] text-[#F97316] rounded-xl text-sm font-semibold disabled:opacity-60 hover:bg-orange-50 transition"
                >
                  <Camera className="w-4 h-4" />
                  Scan list / photo
                </button>
                <button
                  type="button"
                  onClick={handleToggleQuickVoice}
                  disabled={aiLoading}
                  className={`flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold transition ${
                    quickRecording
                      ? 'bg-red-500 text-white animate-pulse shadow-md'
                      : 'border-2 border-orange-300 text-orange-700 hover:bg-orange-50'
                  }`}
                  title={quickRecording ? 'Stop & fill form' : 'Record voice note'}
                >
                  {quickRecording ? <MicOff className="w-4 h-4" /> : <Mic className="w-4 h-4" />}
                  {quickRecording ? 'Stop & Fill' : 'Voice note'}
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
                <div className="w-full border-t border-gray-200" />
              </div>
              <div className="relative flex justify-center text-xs uppercase">
                <span className="bg-gray-50 px-2 text-gray-400">or edit manually</span>
              </div>
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Task Title</label>
              <input
                {...register('title')}
                className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316]"
                placeholder="e.g. Pick up my medicine from pharmacy"
              />
              {errors.title && <p className="text-red-500 text-xs mt-1">{errors.title.message}</p>}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Category</label>
              <select
                {...register('category')}
                className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316] bg-white"
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
              <label className="block text-sm font-medium text-gray-700 mb-1.5">
                Instructions for runner
              </label>
              <p className="text-xs text-gray-500 mb-1.5">
                Be specific — runners see this before accepting (what to buy, where to go, quantities).
              </p>
              <textarea
                {...register('description')}
                rows={4}
                className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316] resize-none"
                placeholder="e.g. Buy 2 tins Peak milk and 1 loaf of bread at Shoprite. Deliver to Ewet Housing gate. Call on arrival."
              />
              {errors.description && (
                <p className="text-red-500 text-xs mt-1">{errors.description.message}</p>
              )}
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
                      onClick={() => setValue('urgency', opt.value as FormData['urgency'])}
                      className={`p-3 rounded-xl border-2 cursor-pointer text-center transition ${
                        current === opt.value
                          ? 'border-[#F97316] bg-orange-50'
                          : 'border-gray-200 hover:border-gray-300'
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
                className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316] resize-none"
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
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Pickup Address</label>
              <div className="flex gap-2">
                <input
                  {...register('pickup_address')}
                  className="flex-1 px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316]"
                  placeholder="e.g. Shoprite, Uyo"
                />
                <button
                  type="button"
                  onClick={() => normalizeAddress('pickup')}
                  className="px-3 py-2 text-xs font-medium text-[#F97316] border border-[#F97316] rounded-xl whitespace-nowrap"
                >
                  AI fix
                </button>
              </div>
              {errors.pickup_address && (
                <p className="text-red-500 text-xs mt-1">{errors.pickup_address.message}</p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Destination Address</label>
              <div className="flex gap-2">
                <input
                  {...register('destination_address')}
                  className="flex-1 px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316]"
                  placeholder="e.g. Ewet Housing, Uyo"
                />
                <button
                  type="button"
                  onClick={() => normalizeAddress('destination')}
                  className="px-3 py-2 text-xs font-medium text-[#F97316] border border-[#F97316] rounded-xl whitespace-nowrap"
                >
                  AI fix
                </button>
              </div>
              {errors.destination_address && (
                <p className="text-red-500 text-xs mt-1">{errors.destination_address.message}</p>
              )}
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Recipient Name (optional)</label>
              <input
                {...register('recipient_name')}
                className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316]"
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Recipient Phone (optional)</label>
              <input
                {...register('recipient_phone')}
                className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316]"
                placeholder="+234..."
              />
            </div>

            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1.5">Special Instructions (optional)</label>
              <textarea
                {...register('special_instructions')}
                rows={3}
                className="w-full px-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316] resize-none"
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
              className="w-full flex items-center justify-center gap-2 py-3 border-2 border-dashed border-[#F97316]/50 rounded-xl text-[#F97316] font-medium text-sm hover:bg-orange-50 disabled:opacity-60"
            >
              {budgetLoading ? (
                <Loader2 className="w-4 h-4 animate-spin" />
              ) : (
                <Sparkles className="w-4 h-4" />
              )}
              Suggest budget & ETA with AI
            </button>
            {etaHint && <p className="text-sm text-gray-600 text-center">{etaHint}</p>}

            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label className="text-sm font-medium text-gray-700">Your Budget (₦)</label>
                <span className="text-xs text-gray-500 font-medium">
                  Platform Min: ₦{minErrandAmount.toLocaleString()}
                </span>
              </div>
              <div className="relative">
                <span className="absolute left-4 top-1/2 -translate-y-1/2 text-gray-500 font-semibold">₦</span>
                <input
                  {...register('budget', { valueAsNumber: true })}
                  type="number"
                  min={minErrandAmount}
                  className="w-full pl-8 pr-4 py-3 border border-gray-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#F97316] text-lg font-bold"
                />
              </div>
              {errors.budget && <p className="text-red-500 text-xs mt-1">{errors.budget.message}</p>}
              <div className="flex gap-2 mt-3 flex-wrap">
                {[
                  minErrandAmount,
                  Math.max(minErrandAmount, 2000),
                  Math.max(minErrandAmount * 2, 3500),
                  Math.max(minErrandAmount * 3, 5000),
                ]
                  .filter((val, idx, arr) => arr.indexOf(val) === idx)
                  .map((amount) => (
                    <button
                      key={amount}
                      type="button"
                      onClick={() => setValue('budget', amount)}
                      className="px-3 py-1.5 border border-gray-200 rounded-lg text-sm hover:border-[#F97316] hover:text-[#F97316] transition"
                    >
                      ₦{amount.toLocaleString()}
                    </button>
                  ))}
              </div>
            </div>

            <div className="bg-gray-50 rounded-xl p-4 space-y-3">
              <div className="flex justify-between text-sm">
                <span className="text-gray-600">Runner payment</span>
                <span className="font-medium">₦{budget.toLocaleString()}</span>
              </div>
              <div className="flex justify-between text-sm">
                <span className="text-gray-600">Platform fee ({((platformCommissionRate || 0.15) * 100).toFixed(0)}%)</span>
                <span className="font-medium">₦{platformFee.toLocaleString()}</span>
              </div>
              <div className="border-t border-gray-200 pt-3 flex justify-between">
                <span className="font-semibold text-[#0E0F13]">Total</span>
                <span className="font-bold text-[#F97316] text-lg">₦{total.toLocaleString()}</span>
              </div>
              <p className="text-xs text-gray-500">
                Payment is held in escrow until you confirm delivery with your OTP.
              </p>
            </div>

            {/* Step 2 Payment Processor Preview & Selection */}
            <div className="mt-4 pt-3 border-t border-gray-100">
              <div className="flex items-center justify-between mb-2">
                <label className="text-xs font-bold uppercase tracking-wider text-gray-500">
                  Select Payment Processor
                </label>
                <span className="text-[11px] text-gray-400 flex items-center gap-1">
                  <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
                  Escrow Protected
                </span>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5">
                <button
                  type="button"
                  onClick={() => setPaymentMethod('paystack')}
                  className={`p-3 rounded-xl border-2 text-left transition flex items-center justify-between ${
                    paymentMethod === 'paystack'
                      ? 'border-[#F97316] bg-orange-50/60 ring-2 ring-[#F97316]/20'
                      : 'border-gray-200 hover:border-gray-300 bg-white'
                  }`}
                >
                  <div className="flex items-center gap-2">
                    <div className="p-1.5 bg-orange-100 text-[#F97316] rounded-lg">
                      <CreditCard className="w-4 h-4" />
                    </div>
                    <div>
                      <p className="text-xs font-bold text-[#0E0F13]">Paystack</p>
                      <p className="text-[10px] text-gray-500">Cards & USSD</p>
                    </div>
                  </div>
                  {paymentMethod === 'paystack' && <div className="w-2.5 h-2.5 rounded-full bg-[#F97316]" />}
                </button>

                <button
                  type="button"
                  onClick={() => setPaymentMethod('bach')}
                  className={`p-3 rounded-xl border-2 text-left transition flex items-center justify-between ${
                    paymentMethod === 'bach'
                      ? 'border-blue-600 bg-blue-50/60 ring-2 ring-blue-500/20'
                      : 'border-gray-200 hover:border-gray-300 bg-white'
                  }`}
                >
                  <div className="flex items-center gap-2">
                    <div className="p-1.5 bg-blue-100 text-blue-600 rounded-lg">
                      <Zap className="w-4 h-4" />
                    </div>
                    <div>
                      <p className="text-xs font-bold text-[#0E0F13]">Bachs Pay</p>
                      <p className="text-[10px] text-gray-500">Fast Checkout</p>
                    </div>
                  </div>
                  {paymentMethod === 'bach' && <div className="w-2.5 h-2.5 rounded-full bg-blue-600" />}
                </button>

                <button
                  type="button"
                  disabled={walletBalance !== null && walletBalance < total}
                  onClick={() => setPaymentMethod('wallet')}
                  className={`p-3 rounded-xl border-2 text-left transition flex items-center justify-between ${
                    walletBalance !== null && walletBalance < total
                      ? 'border-gray-200 bg-gray-50 opacity-60 cursor-not-allowed'
                      : paymentMethod === 'wallet'
                      ? 'border-[#F97316] bg-orange-50/60 ring-2 ring-[#F97316]/20'
                      : 'border-gray-200 hover:border-gray-300 bg-white'
                  }`}
                >
                  <div className="flex items-center gap-2">
                    <div className="p-1.5 bg-emerald-100 text-emerald-600 rounded-lg">
                      <Wallet className="w-4 h-4" />
                    </div>
                    <div>
                      <p className="text-xs font-bold text-[#0E0F13]">Wallet</p>
                      <p className="text-[10px] text-gray-500">₦{(walletBalance ?? 0).toLocaleString()}</p>
                    </div>
                  </div>
                  {paymentMethod === 'wallet' && <div className="w-2.5 h-2.5 rounded-full bg-[#F97316]" />}
                </button>
              </div>
            </div>
          </div>
        )}

        {step === 3 && (
          <div className="space-y-4">
            <div className="errand-card">
              <h3 className="font-semibold text-[#0E0F13] mb-4">Review Your Errand</h3>
              <div className="space-y-3 text-sm">
                <div className="flex justify-between gap-4">
                  <span className="text-gray-500 shrink-0">Title</span>
                  <span className="font-medium text-right">{watch('title')}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Category</span>
                  <span className="font-medium">
                    {CATEGORIES.find((c) => c.value === watch('category'))?.label}
                  </span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Pickup</span>
                  <span className="font-medium text-right max-w-[60%]">{watch('pickup_address')}</span>
                </div>
                <div className="flex justify-between">
                  <span className="text-gray-500">Destination</span>
                  <span className="font-medium text-right max-w-[60%]">{watch('destination_address')}</span>
                </div>
                <div className="border-t pt-3 flex justify-between">
                  <span className="font-semibold">Total</span>
                  <span className="font-bold text-[#F97316]">₦{total.toLocaleString()}</span>
                </div>
              </div>
            </div>

            {/* Direct Pay Now via Paystack Card Checkout Selection */}
            <div className="errand-card">
              <div className="flex items-center justify-between mb-2">
                <h3 className="font-semibold text-[#0E0F13]">Payment Method</h3>
                <span className="text-xs bg-emerald-50 text-emerald-700 font-medium px-2.5 py-1 rounded-full flex items-center gap-1 border border-emerald-200">
                  <ShieldCheck className="w-3.5 h-3.5" />
                  Held safely in escrow
                </span>
              </div>
              <p className="text-xs text-gray-500 mb-4">
                Choose how to fund this errand. Runner only receives payout once you share your delivery OTP.
              </p>

              <div className="space-y-3">
                {/* Paystack Card Checkout Option */}
                <div
                  onClick={() => setPaymentMethod('paystack')}
                  className={`p-4 rounded-xl border-2 cursor-pointer transition flex items-start gap-3.5 ${
                    paymentMethod === 'paystack'
                      ? 'border-[#F97316] bg-orange-50/60 ring-2 ring-[#F97316]/20'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  <div className="p-2.5 bg-orange-100 text-[#F97316] rounded-xl shrink-0 mt-0.5">
                    <CreditCard className="w-5 h-5" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-2">
                      <span className="font-semibold text-sm text-[#0E0F13]">
                        Pay Now via Paystack
                      </span>
                      <span className="text-[10px] bg-orange-500 text-white font-bold px-2 py-0.5 rounded-full uppercase tracking-wider">
                        Cards / USSD
                      </span>
                    </div>
                    <p className="text-xs text-gray-500 mt-1">
                      Direct checkout with Debit/Credit Card, Bank Transfer, or USSD via Paystack (No pre-funding needed)
                    </p>
                  </div>
                  <div className="w-5 h-5 rounded-full border-2 border-[#F97316] flex items-center justify-center shrink-0 mt-1">
                    {paymentMethod === 'paystack' && <div className="w-2.5 h-2.5 rounded-full bg-[#F97316]" />}
                  </div>
                </div>

                {/* Bachs Checkout Option */}
                <div
                  onClick={() => setPaymentMethod('bach')}
                  className={`p-4 rounded-xl border-2 cursor-pointer transition flex items-start gap-3.5 ${
                    paymentMethod === 'bach'
                      ? 'border-blue-600 bg-blue-50/60 ring-2 ring-blue-500/20'
                      : 'border-gray-200 hover:border-gray-300'
                  }`}
                >
                  <div className="p-2.5 bg-blue-100 text-blue-600 rounded-xl shrink-0 mt-0.5">
                    <Zap className="w-5 h-5" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-2">
                      <span className="font-semibold text-sm text-[#0E0F13]">
                        Pay Now via Bachs
                      </span>
                      <span className="text-[10px] bg-blue-600 text-white font-bold px-2 py-0.5 rounded-full uppercase tracking-wider">
                        Fast Transfer
                      </span>
                    </div>
                    <p className="text-xs text-gray-500 mt-1">
                      Fast, modern checkout session with Instant Bank Transfer via Bachs
                    </p>
                  </div>
                  <div className="w-5 h-5 rounded-full border-2 border-blue-600 flex items-center justify-center shrink-0 mt-1">
                    {paymentMethod === 'bach' && <div className="w-2.5 h-2.5 rounded-full bg-blue-600" />}
                  </div>
                </div>

                {/* Wallet Payment Option */}
                <div
                  onClick={() => {
                    if (walletBalance !== null && walletBalance < total) {
                      toast.error(`Insufficient wallet balance (₦${walletBalance.toLocaleString()}). Use Paystack or Bachs instead.`);
                      return;
                    }
                    setPaymentMethod('wallet');
                  }}
                  className={`p-4 rounded-xl border-2 transition flex items-start gap-3.5 ${
                    walletBalance !== null && walletBalance < total
                      ? 'border-gray-200 bg-gray-50 opacity-80 cursor-not-allowed'
                      : paymentMethod === 'wallet'
                      ? 'border-[#F97316] bg-orange-50/60 ring-2 ring-[#F97316]/20 cursor-pointer'
                      : 'border-gray-200 hover:border-gray-300 cursor-pointer'
                  }`}
                >
                  <div className="p-2.5 bg-gray-100 text-gray-700 rounded-xl shrink-0 mt-0.5">
                    <Wallet className="w-5 h-5" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-2">
                      <span className="font-semibold text-sm text-[#0E0F13] dark:text-white">Pay from Errand Wallet</span>
                      <span className="text-xs font-semibold text-gray-800 dark:text-gray-300">
                        {walletBalance !== null ? `₦${walletBalance.toLocaleString()}` : 'Checking balance...'}
                      </span>
                    </div>
                    {walletBalance !== null && walletBalance < total ? (
                      <p className="text-xs text-red-500 mt-1">
                        Insufficient balance (Short by ₦{(total - walletBalance).toLocaleString()}). Please use Paystack or Bachs.
                      </p>
                    ) : (
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                        Deducted instantly from your pre-funded Errand wallet balance
                      </p>
                    )}
                  </div>
                  <div className="w-5 h-5 rounded-full border-2 border-gray-300 flex items-center justify-center shrink-0 mt-1">
                    {paymentMethod === 'wallet' && <div className="w-2.5 h-2.5 rounded-full bg-[#F97316]" />}
                  </div>
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
              className="flex-1 px-6 py-3 border-2 border-gray-200 rounded-xl font-semibold text-gray-700 hover:border-gray-300 transition"
            >
              Back
            </button>
          )}
          {step < 3 ? (
            <button
              type="button"
              onClick={goToNextStep}
              className="flex-1 errand-btn-primary flex items-center justify-center gap-1"
            >
              Continue
              <ChevronRight className="w-4 h-4" />
            </button>
          ) : (
            <button
              type="submit"
              disabled={isSubmitting || isRedirecting}
              className={`flex-1 font-bold py-3 px-6 rounded-xl text-white flex items-center justify-center gap-2 disabled:opacity-70 text-base transition ${
                paymentMethod === 'bach'
                  ? 'bg-blue-600 hover:bg-blue-700'
                  : 'bg-[#F97316] hover:bg-orange-600'
              }`}
            >
              {(isSubmitting || isRedirecting) && <Loader2 className="w-5 h-5 animate-spin" />}
              {isRedirecting
                ? `Opening ${paymentMethod === 'bach' ? 'Bachs' : 'Paystack'} Checkout...`
                : isSubmitting
                ? 'Processing...'
                : paymentMethod === 'bach'
                ? `Proceed to Bachs Checkout (₦${total.toLocaleString()})`
                : paymentMethod === 'paystack'
                ? `Proceed to Paystack Checkout (₦${total.toLocaleString()})`
                : `Post & Pay ₦${total.toLocaleString()} from Wallet`}
            </button>
          )}
        </div>
      </form>
    </div>
  );
}
