'use client';

import Link from 'next/link';
import { useState } from 'react';
import { ThemeToggle } from '@/components/shared/ThemeToggle';

const LOGO =
  'https://lh3.googleusercontent.com/aida-public/AB6AXuCY1QC7wZ5LRgq205pIigfzIbxbQKjcqJWC1lLZ6yeDb5uxdCfy_3oeiiWiUz62UGtspELXAlAYdm56nY-Ge_Er2fdPRayKb4jxY7Tro8NGrdUq-8qIJe8Ppbl_PkbMEfcMN51zTGAfpQ86qFYWRxvQ1aXXd_-gd9uFQoKeBSlMFnNBAUySmzEczlQtyEvTYaxvZLhdtan1qVkjLJDvriFBuHEzNfGzoRXTnuC_XamZLJSrPkAkP9qav3ABeQNC93Fn2A';
const LOGO_FOOTER =
  'https://lh3.googleusercontent.com/aida-public/AB6AXuCoonkUZRybCfbqPL1d5kzqdg_wsae76sbBc3bllEsSuCih3IreQf1J7-edLeNd8_mqIxSdXc19Hvnmimhvrbk6ZnOznKmbu-qRWmP9CZFaM4bu34XCCwQudrCB3545LK29PkdMrazFWK9DEdGcWoBgM3lL8xb9HC3z95w0CJ70wBTaaXeMu7-tSfqbZT2sm3Noonvcy1tPe8rPdU_HYZsj1Vx1uXQ9JeVpxBrK-J7dMsjGfugfYO1keuPqz8HuUpi3-A';
const MAP_IMG =
  'https://lh3.googleusercontent.com/aida-public/AB6AXuA128bdhj5KFPtao1EOu9QH42F81ECdqDDXX83BcIplFfXBjW6GC3ZpcldXbnRCXd4mKvxi7trf-8jSAUtxev1yDQUJB9U85y8DlCi5BWefAUsGq4Odk2-LwpKYdHd_hqfnjhkB2ftxakxJQ26tHHUWWYKqko8P_hv6JCAH1MmfneUyh9jCdRKXqEnwJQtR8vLnBKaNj0Vu9g1bWY1pmYbBM0Lz0xhtqd4Dh9D1H_fJ-Sw1l8oHuHT1';
const RUNNER_IMG =
  'https://lh3.googleusercontent.com/aida-public/AB6AXuAL1suuD_26BIQydq8MNBCw9tBQxFIkym5aVDSpk2Qg1i4dUc4gMY01TQCWQvfHsfyWW_vr6-OcaLzDa5EJEItoz4aos7r0ziSbzNtvb7izf9ET5IHycEvsXHNgqR-YSGkh5FTUFTpWaLnhdORwPT1DpSQM1VALPZeBRh72gw2iOm5wizTDd3lOxdLH5j3BOqUTvGGWKMvaI9SXpDQ76bHKuq97MqoBIgAGgRnq5Mzw8O8KpLfZChWS';

const services = [
  {
    icon: 'gavel',
    title: 'Legal & Document Runs',
    tag: 'High Security',
    desc: 'Filing affidavits, certified true copies, court submissions, and land registry stamping at Ministry offices with tamper-evident tracking.',
    price: '₦2,500',
    cta: 'Book Task',
    darkIcon: false,
  },
  {
    icon: 'shopping_basket',
    title: 'Market & Grocery Runs',
    tag: 'Live Receipts',
    desc: 'Fresh food items, wholesale soup ingredients, and seafood purchased directly from Itam or Akpan Andem markets with photo proof.',
    price: '₦2,000',
    cta: 'Book Task',
    darkIcon: false,
  },
  {
    icon: 'hourglass_top',
    title: 'Bank & Line Standing',
    tag: 'Per Hour',
    desc: 'Have a runner hold your number or position at commercial banks, passport capture centers, or municipal utility payment halls.',
    price: '₦1,500',
    priceSuffix: '/hr',
    cta: 'Book Task',
    darkIcon: false,
  },
  {
    icon: 'local_shipping',
    title: 'Express Parcel Transit',
    tag: 'Within 45m',
    desc: 'Keys, laptops, business merchandise, or forgotten office essentials transferred across town instantly with zero intermediate sorting delays.',
    price: '₦1,500',
    cta: 'Book Task',
    darkIcon: false,
  },
  {
    icon: 'medication',
    title: 'Pharmacy & Care Runs',
    tag: 'Care Priority',
    desc: 'Sourcing specialized medicines from licensed dispensaries across Uyo, confirmed with doctor slips and delivered straight to doorsteps.',
    price: '₦1,800',
    cta: 'Book Task',
    darkIcon: false,
  },
  {
    icon: 'tune',
    title: 'Custom Tasks & Help',
    tag: 'You Define It',
    desc: 'Need a vehicle inspection checked, samples collected from a workshop, or physical venue verification? Define exact guidelines.',
    price: 'Custom',
    cta: 'Create Errand',
    darkIcon: true,
  },
];

const steps = [
  {
    n: '01',
    icon: 'post_add',
    iconClass: 'bg-[#f97316] text-white shadow-[0_4px_10px_rgba(249,115,22,0.3)]',
    title: 'Post Your Task',
    desc: 'Specify your exact pickup, drop-off location, execution instructions, and item budget in minutes.',
    foot: 'Instant smart matching',
    footIcon: 'bolt',
    footClass: 'text-[#f97316]',
  },
  {
    n: '02',
    icon: 'lock',
    iconClass: 'bg-[#0e0f13] text-white',
    title: 'Escrow Vault Lock',
    desc: 'Task fees and shopping budgets are funded into a licensed escrow buffer. Runners know funds are guaranteed.',
    foot: 'Zero advance risk to you',
    footIcon: 'shield',
    footClass: 'text-[#10b981]',
  },
  {
    n: '03',
    icon: 'route',
    iconClass: 'bg-[#ffedd5] text-[#f97316] border border-[#fed7aa]',
    title: 'Live Execution',
    desc: 'Follow your verified runner via live GPS pin, in-app messaging, and photo proof-of-purchase in real-time.',
    foot: 'Dynamic GPS telemetry',
    footIcon: 'near_me',
    footClass: 'text-[#f97316]',
  },
  {
    n: '04',
    icon: 'pin',
    iconClass: 'bg-[#10b981] text-white shadow-[0_4px_10px_rgba(16,185,129,0.3)]',
    title: '4-Digit OTP Release',
    desc: 'When your items arrive and you are satisfied, provide your 4-digit code. The system instantly pays out the runner.',
    foot: 'You stay in complete control',
    footIcon: 'verified',
    footClass: 'text-[#10b981]',
  },
];

const trustPillars = [
  {
    icon: 'badge',
    iconClass: 'text-[#f97316]',
    title: '3-Tier Runner KYC',
    desc: 'We verify National Identity Numbers (NIN), physical residential utility bills, and two verified local community guarantors.',
  },
  {
    icon: 'account_balance',
    iconClass: 'text-[#10b981]',
    title: 'Protected Escrow',
    desc: 'Funds are held in secure partner institutional accounts. Runners never receive payment until you validate work quality.',
  },
  {
    icon: 'receipt_long',
    iconClass: 'text-[#f97316]',
    title: 'Transparent Receipts',
    desc: 'Every market transaction requires live photo receipts and digital itemization before purchase approval.',
  },
  {
    icon: 'support_agent',
    iconClass: 'text-[#0e0f13]',
    title: 'Rapid Local Dispute Team',
    desc: 'Local dispatch managers on ground in Uyo are available 7 days a week for immediate dispute handling and rerouting.',
  },
];

const testimonials = [
  {
    initials: 'EA',
    name: 'Barr. Emmanuel Akpan',
    role: 'Legal Practitioner, Shelter Afrique',
    text: '“I had a client contract that urgently needed an endorsement at the High Court on Wellington Bassey Way while I was stuck in Lagos. A verified runner took care of the queue and dispatch within 2 hours. The OTP release gives absolute peace of mind.”',
  },
  {
    initials: 'IU',
    name: 'Idara Udofia',
    role: 'Founder, Nwanne Edibles Uyo',
    text: '“Shopping for soup ingredients at Itam Market on Saturdays used to swallow my entire morning. Now I just drop my list on DOOYN. The runner sends photos of the fresh crayfish and beef before buying. Escrow keeps it completely honest.”',
  },
  {
    initials: 'KO',
    name: 'Kufre Okon',
    role: 'Software Engineer, Ewet Housing',
    text: '“Bank lines in Uyo for BVN link updates can take half a day. My DOOYN runner held my spot in the queue at Zenith Bank, called me when I was 3 tickets away, and I just stepped in. That alone is worth 10x the fee.”',
  },
];

function Icon({ name, className = '', fill = false }: { name: string; className?: string; fill?: boolean }) {
  return (
    <span
      className={`material-symbols-outlined ${className}`}
      style={fill ? { fontVariationSettings: "'FILL' 1" } : undefined}
    >
      {name}
    </span>
  );
}

export function LandingDesktop() {
  const [taskInput, setTaskInput] = useState('');
  const [btnLabel, setBtnLabel] = useState('Estimate Errand Fee');
  const [showEstimate, setShowEstimate] = useState(false);
  const [placeholder, setPlaceholder] = useState(
    'e.g. Pick up affidavit at High Court, buy groceries at Itam Market'
  );

  const estimateTask = () => {
    if (!taskInput.trim()) {
      setPlaceholder('Please type a quick errand description first!');
      return;
    }
    setBtnLabel('Calculating...');
    window.setTimeout(() => {
      setBtnLabel('Recalculate Fee');
      setShowEstimate(true);
    }, 350);
  };

  return (
    <div className="hidden lg:block bg-[#fafaf8] font-sans text-[#0e0f13] antialiased min-h-screen">
      {/* Header */}
      <header className="fixed top-0 left-0 right-0 z-50 bg-white/95 backdrop-blur-xl border-b border-[#e6e6de] shadow-[0_1px_8px_rgba(14,15,19,0.03)]">
        <div className="h-20 page-container flex items-center justify-between gap-6">
          <div className="flex items-center gap-8">
            <Link href="/" className="flex items-center gap-2.5 group">
              <img
                alt="DOOYN Logo"
                className="h-9 w-9 object-contain group-hover:scale-105 transition-transform"
                src={LOGO}
              />
              <span className="font-headline text-[22px] font-extrabold tracking-tight text-[#0e0f13]">DOOYN</span>
            </Link>
            <nav className="hidden lg:flex items-center gap-6 font-label">
              <a href="#how-it-works" className="text-[#52535a] text-label-md hover:text-[#0e0f13] transition-colors">
                How it Works
              </a>
              <a href="#services" className="text-[#52535a] text-label-md hover:text-[#0e0f13] transition-colors">
                Services
              </a>
              <a href="#trust-and-safety" className="text-[#52535a] text-label-md hover:text-[#0e0f13] transition-colors">
                Trust &amp; Safety
              </a>
              <Link href="/auth/register?role=runner" className="text-[#52535a] text-label-md hover:text-[#0e0f13] transition-colors">
                For Runners
              </Link>
              <a href="#faqs" className="text-[#52535a] text-label-md hover:text-[#0e0f13] transition-colors">
                FAQs
              </a>
            </nav>
          </div>
          <div className="flex items-center gap-2">
            <ThemeToggle className="!border-[#e6e6de] !bg-white" />
            <Link
              href="/auth/login"
              className="hidden sm:inline-flex items-center justify-center h-11 px-4 rounded-xl bg-white text-[#0e0f13] text-label-md font-label border border-[#e6e6de] hover:bg-[#f4f4f0] transition-all"
            >
              Log In
            </Link>
            <Link
              href="/auth/register"
              className="inline-flex items-center justify-center h-11 px-6 rounded-xl bg-[#f97316] text-white text-label-md font-poppins font-semibold shadow-[0_4px_14px_rgba(249,115,22,0.35)] hover:bg-[#ea580c] transition-all active:scale-[0.98]"
            >
              Post a Task
            </Link>
            <Link
              href="/auth/login"
              className="w-9 h-9 rounded-full bg-[#ffedd5] border border-[#fed7aa] flex items-center justify-center"
              aria-label="Account"
            >
              <Icon name="person" className="text-[#f97316] text-[18px]" />
            </Link>
          </div>
        </div>
      </header>

      <main className="w-full pt-20 bg-[#fafaf8] min-h-screen">
        <div className="flex flex-col w-full">
          {/* Hero */}
          <div className="relative w-full overflow-hidden pb-12">
            <div className="absolute -top-32 -left-20 w-[550px] h-[550px] rounded-full bg-[#f97316]/10 blur-[130px] pointer-events-none" />
            <div className="absolute top-80 right-0 w-[600px] h-[600px] rounded-full bg-[#ffedd5] blur-[140px] pointer-events-none opacity-80" />

            <div className="page-container pt-8">
              <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
                <div className="lg:col-span-7 flex flex-col gap-4">
                  <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-[#ffedd5] border border-[#fed7aa] w-fit shadow-sm font-poppins">
                    <Icon name="location_on" className="text-[#f97316] text-[18px]" />
                    <span className="text-label-md text-[#9a3412] font-semibold">
                      Launching in Uyo &amp; Akwa Ibom — Expanding Nationwide
                    </span>
                    <span className="inline-block w-2 h-2 rounded-full bg-[#10b981] animate-pulse" />
                  </div>

                  <h1 className="font-headline text-[36px] md:text-[42px] leading-[1.15] md:leading-[48px] tracking-tight text-[#0e0f13] font-extrabold">
                    Whatever you need done, <span className="text-[#f97316]">DOOYN</span> connects you with verified
                    local runners.
                  </h1>

                  <p className="text-body-lg text-[#52535a] max-w-2xl leading-relaxed">
                    From urgent document pickups and fresh market procurement to standing in congested bank queues.
                    Tracked live in real time, guarded by automated escrow, and disbursed only after your OTP handover
                    confirmation.
                  </p>

                  <div className="mt-2 p-2.5 rounded-2xl bg-white border border-[#e6e6de] shadow-lg flex flex-col md:flex-row gap-2 items-stretch">
                    <div className="flex-1 flex items-center gap-2 px-3 py-2 rounded-xl bg-[#f4f4f0]">
                      <Icon name="assignment" className="text-[#52535a] text-[20px]" />
                      <input
                        className="w-full bg-transparent border-none outline-none text-body-md text-[#0e0f13] placeholder:text-[#8c7164]"
                        value={taskInput}
                        onChange={(e) => setTaskInput(e.target.value)}
                        placeholder={placeholder}
                        type="text"
                      />
                    </div>
                    <div className="w-full md:w-56 flex items-center gap-2 px-3 py-2 rounded-xl bg-[#f4f4f0]">
                      <Icon name="my_location" className="text-[#f97316] text-[20px]" />
                      <select className="w-full bg-transparent border-none outline-none text-label-md text-[#0e0f13] cursor-pointer">
                        <option value="uyo_urban">Uyo Urban (Ring Rd / Plaza)</option>
                        <option value="itam_market">Itam Market Hub</option>
                        <option value="orron_road">Oron Road Corridor</option>
                        <option value="ewet_housing">Ewet Housing Estate</option>
                        <option value="shelter_afrique">Shelter Afrique</option>
                      </select>
                    </div>
                    <button
                      type="button"
                      onClick={estimateTask}
                      className="h-12 px-6 rounded-xl bg-[#f97316] hover:bg-[#ea580c] active:scale-[0.98] transition-all text-white text-label-md flex items-center justify-center gap-2 shadow-[0_4px_12px_rgba(249,115,22,0.3)] shrink-0"
                    >
                      <Icon name="calculate" className="text-[18px]" />
                      <span>{btnLabel}</span>
                    </button>
                  </div>

                  {showEstimate && (
                    <div className="p-3 rounded-xl bg-[#ffedd5] border border-[#fed7aa] flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
                      <div className="flex items-center gap-2">
                        <Icon name="check_circle" className="text-[#10b981] text-[20px]" />
                        <span className="text-label-md text-[#9a3412]">
                          Estimated Base Runner Fee:{' '}
                          <strong className="text-[#0e0f13] font-bold font-headline text-lg">₦1,850</strong> (Escrow
                          Protected)
                        </span>
                      </div>
                      <Link
                        href="/auth/register"
                        className="text-label-md text-[#f97316] font-bold hover:underline flex items-center gap-1"
                      >
                        Confirm &amp; Post <Icon name="arrow_forward" className="text-[16px]" />
                      </Link>
                    </div>
                  )}

                  <div className="flex flex-wrap items-center gap-4 pt-2 text-[#52535a] text-label-sm">
                    <div className="flex items-center gap-1">
                      <Icon name="security" className="text-[#10b981] text-[18px]" fill />
                      <span>100% Locked Escrow</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Icon name="badge" className="text-[#f97316] text-[18px]" fill />
                      <span>NIN &amp; Physical Address Verified</span>
                    </div>
                    <div className="flex items-center gap-1">
                      <Icon name="pin" className="text-[#0e0f13] text-[18px]" fill />
                      <span>One-Time Delivery PIN</span>
                    </div>
                  </div>
                </div>

                {/* Live mockup */}
                <div className="lg:col-span-5 relative flex justify-center">
                  <div className="absolute -inset-2 bg-gradient-to-tr from-[#ffedd5] via-[#f97316]/20 to-transparent rounded-3xl blur-2xl opacity-70" />
                  <div className="relative w-full max-w-sm rounded-3xl bg-white border border-[#e6e6de] shadow-2xl p-4 flex flex-col gap-3">
                    <div className="flex items-center justify-between pb-2 border-b border-[#eeeee8]">
                      <div className="flex items-center gap-2">
                        <span className="w-2.5 h-2.5 rounded-full bg-[#10b981] animate-ping" />
                        <span className="text-label-sm uppercase tracking-wider text-[#0e0f13] font-bold">
                          Live Errand Stream
                        </span>
                      </div>
                      <span className="px-2 py-0.5 rounded-full bg-[#ffedd5] text-[#9a3412] text-label-sm font-bold">
                        UYO-TASK #2409
                      </span>
                    </div>

                    <div className="rounded-2xl bg-[#f4f4f0] overflow-hidden relative border border-[#e6e6de]">
                      <div
                        className="w-full h-44 bg-cover bg-center"
                        style={{ backgroundImage: `url('${MAP_IMG}')` }}
                      />
                      <div className="absolute bottom-2 left-2 right-2 p-2 rounded-xl bg-white/95 backdrop-blur shadow-sm border border-[#e6e6de] flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <div className="w-8 h-8 rounded-lg bg-[#ffedd5] flex items-center justify-center text-[#f97316]">
                            <Icon name="two_wheeler" className="text-[20px]" />
                          </div>
                          <div className="flex flex-col">
                            <span className="text-label-sm text-[#0e0f13] font-bold">Runner Bassey E.</span>
                            <span className="text-[11px] text-[#52535a]">Honda Ace 125 • 4 min away</span>
                          </div>
                        </div>
                        <span className="px-2 py-1 rounded-full bg-[#dcfce7] text-[#166534] text-[11px] font-bold">
                          En Route
                        </span>
                      </div>
                    </div>

                    <div className="p-2 rounded-xl bg-[#f4f4f0] flex items-center justify-between border border-[#eeeee8]">
                      <div className="flex flex-col items-center gap-1">
                        <span className="w-5 h-5 rounded-full bg-[#10b981] text-white flex items-center justify-center text-[11px] font-bold">
                          ✓
                        </span>
                        <span className="text-[10px] text-[#0e0f13] font-semibold">Locked</span>
                      </div>
                      <div className="flex-1 h-0.5 bg-[#10b981] rounded-full mx-1" />
                      <div className="flex flex-col items-center gap-1">
                        <span className="w-5 h-5 rounded-full bg-[#10b981] text-white flex items-center justify-center text-[11px] font-bold">
                          ✓
                        </span>
                        <span className="text-[10px] text-[#0e0f13] font-semibold">Purchased</span>
                      </div>
                      <div className="flex-1 h-0.5 bg-[#f97316] rounded-full mx-1" />
                      <div className="flex flex-col items-center gap-1">
                        <span className="w-5 h-5 rounded-full bg-[#f97316] text-white flex items-center justify-center text-[11px] font-bold animate-bounce">
                          3
                        </span>
                        <span className="text-[10px] text-[#f97316] font-bold">Delivery</span>
                      </div>
                      <div className="flex-1 h-0.5 bg-[#ddddd4] rounded-full mx-1" />
                      <div className="flex flex-col items-center gap-1">
                        <span className="w-5 h-5 rounded-full bg-[#ddddd4] text-[#52535a] flex items-center justify-center text-[11px]">
                          4
                        </span>
                        <span className="text-[10px] text-[#8c7164]">Payout</span>
                      </div>
                    </div>

                    <div className="p-3 rounded-xl bg-[#ffedd5] border border-[#fed7aa] flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <Icon name="lock" className="text-[#f97316] text-[22px]" />
                        <div>
                          <div className="text-label-sm text-[#0e0f13] font-bold">Escrow Vault Secured</div>
                          <div className="text-[11px] text-[#52535a]">Disbursed on Handover OTP</div>
                        </div>
                      </div>
                      <span className="font-headline text-currency-display text-[#f97316] font-bold">₦4,500</span>
                    </div>

                    <div className="p-3 rounded-xl bg-[#f4f4f0] border border-[#eeeee8] flex flex-col gap-1">
                      <div className="flex items-center justify-between">
                        <span className="text-label-sm text-[#52535a] uppercase tracking-wider font-semibold">
                          Handoff Secret Code
                        </span>
                        <span className="text-label-sm text-[#f97316] font-bold">Share upon arrival</span>
                      </div>
                      <div className="flex justify-between gap-2 pt-1">
                        {['7', '4', '9', '2'].map((d) => (
                          <span
                            key={d}
                            className="flex-1 text-center font-bold font-headline text-headline-md bg-white border border-[#e6e6de] rounded-lg py-1 shadow-sm text-[#0e0f13]"
                          >
                            {d}
                          </span>
                        ))}
                      </div>
                    </div>

                    <button
                      type="button"
                      className="w-full h-11 rounded-xl bg-[#0e0f13] hover:bg-[#1a1b20] transition-colors text-white text-label-md flex items-center justify-center gap-2"
                    >
                      <Icon name="verified_user" className="text-[18px] text-[#10b981]" />
                      <span>Confirm Package Reception</span>
                    </button>
                  </div>
                </div>
              </div>

              {/* Stats */}
              <div className="mt-12 grid grid-cols-2 md:grid-cols-4 gap-4 p-6 rounded-2xl bg-white border border-[#e6e6de] shadow-sm">
                <div className="flex flex-col gap-0.5">
                  <div className="font-headline text-display-lg text-[#f97316] font-extrabold">4,850+</div>
                  <div className="text-label-md text-[#0e0f13] font-bold">Tasks Successfully Completed</div>
                  <div className="text-[12px] text-[#52535a]">Across Uyo metropolis and environs</div>
                </div>
                <div className="flex flex-col gap-0.5">
                  <div className="font-headline text-display-lg text-[#10b981] font-extrabold">100%</div>
                  <div className="text-label-md text-[#0e0f13] font-bold">Escrow Funds Protected</div>
                  <div className="text-[12px] text-[#52535a]">Zero loss guarantee for buyers &amp; sellers</div>
                </div>
                <div className="flex flex-col gap-0.5">
                  <div className="font-headline text-display-lg text-[#0e0f13] font-extrabold">12 min</div>
                  <div className="text-label-md text-[#0e0f13] font-bold">Avg Runner Match Time</div>
                  <div className="text-[12px] text-[#52535a]">Hyper-local dispatch algorithms</div>
                </div>
                <div className="flex flex-col gap-0.5">
                  <div className="font-headline text-display-lg text-[#f97316] font-extrabold flex items-center gap-1">
                    4.9 <Icon name="star" className="text-[30px] text-amber-500" fill />
                  </div>
                  <div className="text-label-md text-[#0e0f13] font-bold">Runner Satisfaction Score</div>
                  <div className="text-[12px] text-[#52535a]">Based on 3,400+ verified ratings</div>
                </div>
              </div>
            </div>
          </div>

          {/* Services */}
          <section id="services" className="w-full bg-[#f4f4f0] py-12 border-y border-[#e6e6de]">
            <div className="page-container">
              <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 mb-8">
                <div className="flex flex-col gap-2">
                  <span className="text-label-sm uppercase tracking-wider text-[#f97316] font-bold">
                    Reliable City Logistics &amp; Personal Errands
                  </span>
                  <h2 className="font-headline text-display-lg text-[#0e0f13] font-bold">
                    What would you like handled today?
                  </h2>
                  <p className="text-body-lg text-[#52535a] max-w-xl">
                    Choose from high-frequency everyday errand services fulfilled by trained, KYC-cleared neighborhood
                    runners.
                  </p>
                </div>
                <a
                  href="#services"
                  className="inline-flex items-center gap-2 px-4 py-2.5 rounded-xl bg-white text-[#0e0f13] text-label-md border border-[#e6e6de] shadow-sm hover:bg-[#eeeee8] transition-colors"
                >
                  <span>View All Errand Categories</span>
                  <Icon name="arrow_forward" className="text-[18px]" />
                </a>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                {services.map((s) => (
                  <div
                    key={s.title}
                    className="p-6 rounded-2xl bg-white border border-[#e6e6de] shadow-sm flex flex-col justify-between hover:shadow-lg transition-all group"
                  >
                    <div className="flex flex-col gap-3">
                      <div
                        className={`w-12 h-12 rounded-xl flex items-center justify-center group-hover:scale-105 transition-transform ${
                          s.darkIcon ? 'bg-[#0e0f13] text-white' : 'bg-[#ffedd5] text-[#f97316]'
                        }`}
                      >
                        <Icon name={s.icon} className="text-[28px]" />
                      </div>
                      <div className="flex items-center justify-between gap-2">
                        <h3 className="font-headline text-headline-md text-[#0e0f13]">{s.title}</h3>
                        <span className="px-2 py-0.5 rounded-full bg-[#ffedd5] text-[#9a3412] text-label-sm font-semibold whitespace-nowrap">
                          {s.tag}
                        </span>
                      </div>
                      <p className="text-body-md text-[#52535a]">{s.desc}</p>
                    </div>
                    <div className="mt-6 pt-4 border-t border-[#eeeee8] flex items-center justify-between">
                      <div className="flex flex-col">
                        <span className="text-label-sm text-[#52535a]">Starting from</span>
                        <span
                          className={`font-headline text-currency-display font-bold ${
                            s.darkIcon ? 'text-[#0e0f13]' : 'text-[#f97316]'
                          }`}
                        >
                          {s.price}
                          {s.priceSuffix && (
                            <span className="text-label-sm text-[#52535a] font-normal">{s.priceSuffix}</span>
                          )}
                        </span>
                      </div>
                      <Link
                        href="/auth/register"
                        className="h-10 px-4 rounded-xl bg-[#f97316] hover:bg-[#ea580c] text-white text-label-md flex items-center gap-1 transition-all shadow-sm"
                      >
                        {s.cta}
                      </Link>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </section>

          {/* How it works */}
          <section id="how-it-works" className="w-full py-12 bg-[#fafaf8]">
            <div className="page-container">
              <div className="text-center w-full flex flex-col items-center gap-2 mb-12">
                <span className="px-3 py-1 rounded-full bg-[#ffedd5] text-[#9a3412] border border-[#fed7aa] text-label-sm font-bold">
                  The 4-Step Escrow Protocol
                </span>
                <h2 className="font-headline text-display-lg text-[#0e0f13] font-extrabold">
                  Never pay before proof of work.
                </h2>
                <p className="text-body-lg text-[#52535a]">
                  DOOYN replaces trust anxiety with automated smart escrow locks. Your money stays shielded in reserve
                  until your runner proves task completion.
                </p>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 relative">
                {steps.map((step) => (
                  <div
                    key={step.n}
                    className="p-6 rounded-2xl bg-white border border-[#e6e6de] shadow-sm flex flex-col gap-4 relative overflow-hidden"
                  >
                    <span className="font-headline text-display-lg font-black text-[#eeeee8] absolute right-4 top-2 select-none">
                      {step.n}
                    </span>
                    <div
                      className={`w-12 h-12 rounded-xl flex items-center justify-center z-10 ${step.iconClass}`}
                    >
                      <Icon name={step.icon} className="text-[24px]" />
                    </div>
                    <div className="flex flex-col gap-1 z-10">
                      <h3 className="font-headline text-headline-md text-[#0e0f13]">{step.title}</h3>
                      <p className="text-body-md text-[#52535a]">{step.desc}</p>
                    </div>
                    <div className={`mt-auto pt-2 flex items-center gap-1 text-label-sm font-semibold ${step.footClass}`}>
                      <span>{step.foot}</span>
                      <Icon name={step.footIcon} className="text-[16px]" />
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </section>

          {/* Trust & Safety */}
          <section id="trust-and-safety" className="w-full bg-white border-y border-[#e6e6de]">
            <div className="w-full overflow-hidden grid grid-cols-1 lg:grid-cols-12">
              <div className="lg:col-span-5 relative min-h-[380px] bg-[#0e0f13]">
                <div
                  className="absolute inset-0 bg-cover bg-center"
                  style={{ backgroundImage: `url('${RUNNER_IMG}')` }}
                />
                <div className="absolute inset-0 bg-gradient-to-t from-[#0e0f13]/85 via-transparent to-transparent" />
                <div className="absolute bottom-6 left-0 right-0 p-4 mx-0 bg-white/95 backdrop-blur shadow-lg border-y border-[#e6e6de] flex items-center gap-4">
                  <div className="w-12 h-12 rounded-xl bg-[#ffedd5] text-[#f97316] flex items-center justify-center shrink-0 border border-[#fed7aa] ml-0">
                    <Icon name="verified_user" className="text-[24px]" />
                  </div>
                  <div className="flex flex-col">
                    <span className="text-label-md text-[#0e0f13] font-bold">100% Identity-Audited Runners</span>
                    <span className="text-body-md text-[#52535a]">
                      Government NIN validation, guarantor verification, and in-person depot onboarding.
                    </span>
                  </div>
                </div>
              </div>

              <div className="lg:col-span-7 p-8 lg:p-12 flex flex-col justify-between gap-6 bg-[#f4f4f0]">
                <div className="flex flex-col gap-2">
                  <span className="text-label-sm uppercase tracking-wider text-[#f97316] font-bold">
                    Guaranteed Zero Advance Risk
                  </span>
                  <h2 className="font-headline text-display-lg text-[#0e0f13] font-extrabold">
                    Safe by design. Verified in the real world.
                  </h2>
                  <p className="text-body-lg text-[#52535a]">
                    Unlike open social media errand dispatch or unregulated roadside riders, every DOOYN execution is
                    bound by strict legal covenants and biometric verification.
                  </p>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  {trustPillars.map((p) => (
                    <div
                      key={p.title}
                      className="p-4 rounded-xl bg-[#fafaf8] border border-[#eeeee8] flex flex-col gap-2"
                    >
                      <div className={`flex items-center gap-2 ${p.iconClass}`}>
                        <Icon name={p.icon} className="text-[22px]" />
                        <h4 className="text-[#0e0f13] font-bold text-sm">{p.title}</h4>
                      </div>
                      <p className="text-body-md text-[#52535a]">{p.desc}</p>
                    </div>
                  ))}
                </div>
                <div className="flex items-center gap-4 pt-2">
                  <a
                    href="#trust-and-safety"
                    className="text-label-md text-[#f97316] font-bold hover:underline flex items-center gap-1"
                  >
                    Read Our Full Safety Charter <Icon name="open_in_new" className="text-[16px]" />
                  </a>
                </div>
              </div>
            </div>
          </section>

          {/* Testimonials */}
          <section className="w-full py-12 bg-[#fafaf8]">
            <div className="page-container">
              <div className="flex flex-col md:flex-row md:items-end justify-between gap-4 mb-8">
                <div className="flex flex-col gap-2">
                  <span className="text-label-sm uppercase tracking-wider text-[#f97316] font-bold">
                    Community Word of Mouth
                  </span>
                  <h2 className="font-headline text-display-lg text-[#0e0f13] font-extrabold">
                    Loved by busy professionals and founders across Uyo.
                  </h2>
                </div>
                <div className="flex items-center gap-1 text-[#10b981] text-label-md font-bold">
                  <Icon name="verified" className="text-[20px]" fill />
                  <span>100% Verified Order Reviews</span>
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                {testimonials.map((t) => (
                  <div
                    key={t.name}
                    className="p-6 rounded-2xl bg-white border border-[#e6e6de] shadow-sm flex flex-col justify-between gap-4"
                  >
                    <div className="flex flex-col gap-3">
                      <div className="flex text-amber-500">
                        {Array.from({ length: 5 }).map((_, i) => (
                          <Icon key={i} name="star" className="text-[20px]" fill />
                        ))}
                      </div>
                      <p className="text-body-md text-[#0e0f13] leading-relaxed">{t.text}</p>
                    </div>
                    <div className="flex items-center gap-3 pt-2 border-t border-[#eeeee8]">
                      <div className="w-10 h-10 rounded-full bg-[#ffedd5] border border-[#fed7aa] flex items-center justify-center font-bold text-[#f97316]">
                        {t.initials}
                      </div>
                      <div className="flex flex-col">
                        <span className="text-label-md text-[#0e0f13] font-bold">{t.name}</span>
                        <span className="text-[12px] text-[#52535a]">{t.role}</span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </section>

          {/* CTA */}
          <section className="w-full bg-gradient-to-r from-[#ea580c] via-[#f97316] to-[#fb923c] text-white overflow-hidden relative">
            <div className="absolute -right-20 -bottom-20 w-96 h-96 rounded-full bg-white/10 blur-3xl pointer-events-none" />
            <div className="absolute -left-20 -top-20 w-80 h-80 rounded-full bg-[#ffedd5]/20 blur-3xl pointer-events-none" />
            <div className="relative z-10 page-container py-8 lg:py-12 grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
              <div className="lg:col-span-8 flex flex-col gap-3">
                <span className="px-3 py-1 rounded-full bg-black/20 backdrop-blur text-white text-label-sm w-fit font-poppins font-bold border border-white/20">
                  Join the Fastest Growing Errand Network
                </span>
                <h2 className="font-headline text-display-lg font-extrabold text-white leading-tight">
                  Reclaim your day. Hand off your errands to trusted local hands.
                </h2>
                <p className="text-body-lg text-orange-50 max-w-2xl leading-relaxed">
                  Post your first task in under 90 seconds or register as an accredited DOOYN runner to turn your street
                  mobility into daily instant earnings.
                </p>
              </div>
              <div className="lg:col-span-4 flex flex-col sm:flex-row lg:flex-col gap-3 justify-end">
                <Link
                  href="/auth/register"
                  className="h-12 px-6 rounded-xl bg-white text-[#0e0f13] hover:bg-[#f4f4f0] active:scale-[0.98] transition-all text-label-md flex items-center justify-center gap-2 shadow-lg font-poppins font-bold"
                >
                  <Icon name="add_task" className="text-[20px] text-[#f97316]" />
                  <span>Post Your First Task</span>
                </Link>
                <Link
                  href="/auth/register?role=runner"
                  className="h-12 px-6 rounded-xl bg-[#0e0f13] hover:bg-[#1a1b20] text-white active:scale-[0.98] transition-all text-label-md flex items-center justify-center gap-2 shadow-md border border-white/10 font-poppins font-bold"
                >
                  <Icon name="two_wheeler" className="text-[20px] text-[#f97316]" />
                  <span>Earn as a DOOYN Runner</span>
                </Link>
              </div>
            </div>
          </section>
        </div>
      </main>

      {/* Footer */}
      <footer id="faqs" className="w-full bg-[#0e0f13] text-white border-t border-[#1a1b20]">
        <div className="page-container pt-12 pb-8">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-8 mb-12">
            <div className="lg:col-span-1 flex flex-col gap-3">
              <div className="flex items-center gap-2.5">
                <img alt="DOOYN Logo" className="h-8 w-8 object-contain" src={LOGO_FOOTER} />
                <span className="font-headline text-headline-md font-bold tracking-tight text-white">DOOYN</span>
                <span className="inline-flex items-center px-2 py-0.5 rounded-full bg-[#f97316] text-white text-[10px] font-poppins font-bold">
                  LIVE
                </span>
              </div>
              <p className="text-body-md text-neutral-400">
                The hyper-local, secure peer-to-peer task execution network with escrow-backed guarantees and verified
                physical runners.
              </p>
              <div className="flex items-center gap-2 pt-2">
                <Icon name="verified" className="text-[#10b981] text-[18px]" />
                <span className="text-label-sm text-neutral-200 font-bold">Verified KYC Network</span>
              </div>
            </div>

            <div className="flex flex-col gap-3">
              <h3 className="text-label-md uppercase tracking-wider text-neutral-200 font-bold">Product</h3>
              <div className="flex flex-col gap-2">
                <a href="#how-it-works" className="text-body-md text-neutral-400 hover:text-white transition-colors">
                  How it Works
                </a>
                <a href="#services" className="text-body-md text-neutral-400 hover:text-white transition-colors">
                  Services
                </a>
                <a href="#how-it-works" className="text-body-md text-neutral-400 hover:text-white transition-colors">
                  Pricing &amp; Escrow
                </a>
                <Link
                  href="/auth/register?role=runner"
                  className="text-body-md text-neutral-400 hover:text-white transition-colors"
                >
                  For Runners
                </Link>
              </div>
            </div>

            <div className="flex flex-col gap-3">
              <h3 className="text-label-md uppercase tracking-wider text-neutral-200 font-bold">Safety</h3>
              <div className="flex flex-col gap-2">
                <a href="#trust-and-safety" className="text-body-md text-neutral-400 hover:text-white transition-colors">
                  Trust &amp; Safety
                </a>
                <a href="#trust-and-safety" className="text-body-md text-neutral-400 hover:text-white transition-colors">
                  KYC Verification
                </a>
                <a href="#how-it-works" className="text-body-md text-neutral-400 hover:text-white transition-colors">
                  Escrow Protection
                </a>
                <a href="#trust-and-safety" className="text-body-md text-neutral-400 hover:text-white transition-colors">
                  Dispute Resolution
                </a>
              </div>
            </div>

            <div className="flex flex-col gap-3">
              <h3 className="text-label-md uppercase tracking-wider text-neutral-200 font-bold">Company</h3>
              <div className="flex flex-col gap-2">
                <a href="#trust-and-safety" className="text-body-md text-neutral-400 hover:text-white transition-colors">
                  About DOOYN
                </a>
                <a href="mailto:support@dooyn.com" className="text-body-md text-neutral-400 hover:text-white transition-colors">
                  Contact Us
                </a>
              </div>
            </div>

            <div className="flex flex-col gap-3">
              <h3 className="text-label-md uppercase tracking-wider text-neutral-200 font-bold">Legal</h3>
              <div className="flex flex-col gap-2">
                <span className="text-body-md text-neutral-500">Terms of Service</span>
                <span className="text-body-md text-neutral-500">Privacy Policy</span>
                <span className="text-body-md text-neutral-500">Community Standards</span>
              </div>
            </div>
          </div>

          <div className="bg-neutral-900/80 border border-neutral-800 rounded-xl p-4 flex flex-col md:flex-row md:items-center justify-between gap-3 mb-8">
            <div className="flex items-center gap-2">
              <Icon name="near_me" className="text-[#f97316] text-[20px]" />
              <div className="flex flex-col sm:flex-row sm:items-center gap-x-2">
                <span className="text-label-md text-white font-bold">Localized Launch:</span>
                <span className="text-body-md text-neutral-400">
                  Actively servicing tasks across Uyo Urban, Akwa Ibom &amp; nationwide Nigeria dispatch nodes.
                </span>
              </div>
            </div>
            <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-neutral-800 border border-neutral-700">
              <span className="w-2 h-2 rounded-full bg-[#10b981]" />
              <span className="text-label-sm text-neutral-300">Operations Active</span>
            </div>
          </div>

          <div className="flex flex-col md:flex-row items-center justify-between gap-4 text-neutral-500 text-body-md border-t border-neutral-800 pt-6">
            <div>© {new Date().getFullYear()} DOOYN Inc. All rights reserved.</div>
            <div className="flex items-center gap-6">
              <span className="hover:text-white transition-colors cursor-default">Privacy</span>
              <span className="hover:text-white transition-colors cursor-default">Terms</span>
              <a href="mailto:support@dooyn.com" className="hover:text-white transition-colors">
                Support
              </a>
            </div>
          </div>
        </div>
      </footer>
    </div>
  );
}
