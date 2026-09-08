'use client';

import Link from 'next/link';
import { useEffect, useState } from 'react';
import { ThemeToggle } from '@/components/shared/ThemeToggle';

const LOGO =
  'https://lh3.googleusercontent.com/aida-public/AB6AXuDpZlvUFkATqVSgWd91hTVoO5QbLaacEob5yhM2K6IwwXpGdLENtfufBlL-dDwo6G5lH4QaAle9Kd4EalsUiK6vmswef_C6EOOxkcvg_Jq6MtXb9UjLFAFtwGmWmWLZKgkVbNo1va6Jb7zdrsShpxtRowQOAsJYdWALB608uln6dqKme79o4qj2VRXOQbbomUbjt_lSBIk7QOlDwHGKYV4AxBsSrSm6Hp3HnJIZyBYc3Q7_bdickN8fv17lohZyDtbvfg';
const LOGO_DRAWER =
  'https://lh3.googleusercontent.com/aida-public/AB6AXuBEXB-U0EBGEL33sM2Wb1MTw8q8CNvuyGOlL5ybBKtLD14ywjqhoN_R7JDy2oKg-zqr8U8kl4U_5S-Wi3mKeXkoc40lHaHnYkSqxcnmUeRlsc_qHfdPbRc';3oVGV4aMfS_HDEhnnxxs8shsQVutwKLyXVeb2SpTnOI-oylDTSFOsD3VZ9l7Xj775xmADGVJe7hRbawoPFrPlgQR3G75ICQUjGuFfZ_QsRXO1LhAHAO368rgL4x08N0ToZ-8kp7Aogaw';
const LOGO_FOOTER =
  'https://lh3.googleusercontent.com/aida-public/AB6AXuAYUwWx7HPNuR-yxJzzZ4KvBTIhyovJbId1dcZQBtg3rqAQHT6la5AsnC2pAMhs8OtRBk8wQFHStUST-6_3WnrHiH9eUie8xartW8EnPD7xoFUyhWhnvhtx1WrZcKU0DVTsqxGMGbSj5KHkzcU8labcmRUskzOnbzhWCCgCQBZoyB24eYadNVALzLB2QYWyDMPWWslkD6ckFxvS2trUFnIKYfY6xiz-Zsxfmz8T5Ic_jeZWIUV7bORYoTnh5XcXr0U86g';
const DISPATCH_IMG =
  'https://lh3.googleusercontent.com/aida-public/AB6AXuApjDaZRUeQILMCSTr9UAd_9PXodEbDgWLBf9lSNunx_LCTI7l5ajjiH5bgmC7e8F1jO6gzpSG8NS82ShBcgeXqyhWA7Y1ozI4mj8UgrDHxBWpF5dr8LqBuM5_MhgTfYGWHymIu8TmvyOHIyFGavDPp2eg7pEOSJgqoljXzp8-CVTg6jO-FNYVy4xbRKn47bSMUY_7i_6r4dMlL9qxhHmwqIbn8ECSbktLYb1bNsU16BjiUHOXSpU8Z';
const RUNNER_EMEM =
  'https://lh3.googleusercontent.com/aida-public/AB6AXuArClZ0hX7_XeQ6sifhMhPQ-Mif5M_xcv0LLzXbh0fzSSNYQ3QPGFn-50OuYJZAZElR0MRyCTWA3WgPUk3fhFKKn4LVra1t-ZS1RyxBZGIBjkYSQwpeR93G9yx2mZLrLpwmEA-fknPW2Gj44YRgypK4dx_8tw7pqvg_GZA6ZpbawfPsbnsW1PKE_bVU8y1k5Jk0aSbUJlijFY8WHg5RzEGrr_ih2lrXy_T1CxBV0Z5agaHrFjA0dX8C';
const RUNNER_BLESSING =
  'https://lh3.googleusercontent.com/aida-public/AB6AXuCwm4UhNcH6xgKTSq3PtEXO93KCKhv79cd1xWk07AWKJFU3FNP5Hn5aL7V-GPfWRnw_U1gBtTQ6GeUvAyNAtvhx0X-IDUI_yOQz97z31Jw7hGCisz486b3gs4l4_iC57BdwzEK_Wnrh63b5joM2g69X1VT1eurR28bkj7K_xeGnfm906MHuRGCfCnkJ1pf9rBEG-pXnbpJFyrRDBsHcfFL43I2UheWEzpylqrYPjWgsMQR6sCPxrVNi';

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

const mobileServices = [
  {
    icon: 'description',
    title: 'Document Runs',
    desc: 'High Court, ministries, notarization',
    price: 'From ₦2,500',
    tag: 'FAST',
    tagClass: 'bg-[#ffedd5] text-[#f97316]',
    iconWrap: 'bg-[#ffedd5] text-[#f97316]',
  },
  {
    icon: 'shopping_bag',
    title: 'Market Shopping',
    desc: 'Itam Market, groceries, bargaining',
    price: 'From ₦3,000',
    tag: 'FRESH',
    tagClass: 'bg-[#dcfce7] text-[#15803d]',
    iconWrap: 'bg-[#dcfce7] text-[#16a34a]',
  },
  {
    icon: 'hourglass_top',
    title: 'Queue Standing',
    desc: 'Bank verification, passport, power office',
    price: 'From ₦2,000/hr',
    tag: null,
    tagClass: '',
    iconWrap: 'bg-[#ffedd5] text-[#f97316]',
  },
  {
    icon: 'package_2',
    title: 'Parcel Delivery',
    desc: 'Intra-city dispatch, express routing',
    price: 'From ₦1,500',
    tag: 'LIVE GPS',
    tagClass: 'bg-[#ffedd5] text-[#f97316]',
    iconWrap: 'bg-[#ffedd5] text-[#f97316]',
  },
  {
    icon: 'local_pharmacy',
    title: 'Urgent Pharmacy',
    desc: 'Emergency prescription pickups',
    price: 'From ₦2,000',
    tag: 'PRIORITY',
    tagClass: 'bg-[#ffdad6] text-[#93000a]',
    iconWrap: 'bg-[#ffdad6]/50 text-[#ba1a1a]',
  },
  {
    icon: 'tune',
    title: 'Custom Errands',
    desc: 'Specify bespoke steps and checkpoints',
    price: 'From ₦2,000',
    tag: null,
    tagClass: '',
    iconWrap: 'bg-[#f4f3ef] text-[#0e0f13]',
  },
];

const howSteps = [
  {
    n: '1',
    title: 'Post Task in 60s',
    desc: 'Set your location, instructions, and errand budget.',
    wrap: 'bg-[#ffedd5] text-[#f97316]',
  },
  {
    n: '2',
    title: 'Pay into Escrow',
    desc: 'Your cash is locked safely in vault. The runner cannot touch it yet.',
    wrap: 'bg-[#0e0f13] text-white',
  },
  {
    n: '3',
    title: 'Runner Dispatched',
    desc: 'Track runner real-time on GPS map with live photo checkpoints.',
    wrap: 'bg-[#ffedd5] text-[#f97316]',
  },
  {
    n: '4',
    title: 'Secret OTP Handover',
    desc: 'Share your 4-digit code ONLY when satisfied to release the funds.',
    wrap: 'bg-[#dcfce7] text-[#15803d]',
    badge: 'FINAL',
  },
];

export function LandingMobile() {
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [search, setSearch] = useState('');

  useEffect(() => {
    document.body.style.overflow = drawerOpen ? 'hidden' : '';
    return () => {
      document.body.style.overflow = '';
    };
  }, [drawerOpen]);

  const closeDrawer = () => setDrawerOpen(false);

  return (
    <div className="lg:hidden bg-[#fafaf8] text-[#0e0f13] min-h-screen flex flex-col font-sans antialiased selection:bg-[#f97316]/20">
      {/* Header */}
      <header className="fixed top-0 left-0 right-0 z-50 bg-[#fafaf8]/90 backdrop-blur-xl border-b border-[#0e0f13]/5">
        <div className="h-16 page-container flex items-center justify-between gap-2">
          <div className="flex items-center gap-1">
            <button
              type="button"
              aria-label="Open Menu"
              onClick={() => setDrawerOpen(true)}
              className="w-12 h-12 flex items-center justify-center rounded-xl text-[#0e0f13] hover:bg-[#f4f3ef] transition-colors"
            >
              <Icon name="menu" className="text-[24px]" />
            </button>
            <Link href="/" className="flex items-center gap-2">
              <img alt="DOOYN" className="h-8 w-8 object-contain rounded-lg" src={LOGO} />
              <span className="font-headline text-headline-md tracking-tight text-[#0e0f13] font-bold">DOOYN</span>
            </Link>
          </div>
          <div className="flex items-center gap-2">
            <ThemeToggle className="!h-9 !w-9 !p-0" />
            <Link
              href="/auth/register"
              className="min-h-[44px] px-4 py-2 bg-[#f97316] hover:bg-[#ea580c] text-white text-label-md rounded-xl inline-flex items-center justify-center shadow-sm active:scale-[0.98] transition-all font-bold"
            >
              Post a Task
            </Link>
            <Link
              href="/auth/login"
              className="w-8 h-8 rounded-full bg-[#0e0f13] flex items-center justify-center"
              aria-label="Account"
            >
              <Icon name="person" className="text-white text-[18px]" />
            </Link>
          </div>
        </div>
      </header>

      {/* Nav drawer */}
      <div
        className={`fixed inset-0 z-50 transition-opacity duration-300 ${
          drawerOpen ? 'pointer-events-auto opacity-100' : 'pointer-events-none opacity-0'
        }`}
        aria-hidden={!drawerOpen}
      >
        <button
          type="button"
          className="absolute inset-0 bg-[#0e0f13]/40 backdrop-blur-sm"
          aria-label="Close menu backdrop"
          onClick={closeDrawer}
        />
        <div
          className={`absolute top-0 left-0 bottom-0 w-4/5 max-w-xs bg-[#fafaf8] shadow-2xl flex flex-col transition-transform duration-300 ease-out ${
            drawerOpen ? 'translate-x-0' : '-translate-x-full'
          }`}
        >
          <div className="h-16 page-container flex items-center justify-between border-b border-[#0e0f13]/5">
            <div className="flex items-center gap-2">
              <img alt="DOOYN" className="h-7 w-7 object-contain rounded-md" src={LOGO_DRAWER} />
              <span className="font-headline text-headline-md font-bold text-[#0e0f13]">DOOYN</span>
            </div>
            <button
              type="button"
              aria-label="Close Menu"
              onClick={closeDrawer}
              className="w-12 h-12 flex items-center justify-center rounded-xl text-[#584237] hover:bg-[#f4f3ef] transition-colors"
            >
              <Icon name="close" className="text-[24px]" />
            </button>
          </div>
          <nav className="flex-1 page-container py-4 flex flex-col gap-1 overflow-y-auto">
            {[
              { href: '#how-it-works-m', icon: 'route', label: 'How it Works' },
              { href: '#services-m', icon: 'category', label: 'Services' },
              { href: '#safety-m', icon: 'verified_user', label: 'Safety' },
              { href: '/auth/register?role=runner', icon: 'electric_moped', label: 'For Runners' },
            ].map((item) => (
              <Link
                key={item.label}
                href={item.href}
                onClick={closeDrawer}
                className="min-h-[48px] px-4 rounded-xl flex items-center gap-3 text-[#584237] hover:text-[#0e0f13] hover:bg-[#ffedd5]/50 transition-colors"
              >
                <Icon name={item.icon} className="text-[20px]" />
                <span className="text-[15px] font-semibold">{item.label}</span>
              </Link>
            ))}
            <div className="h-px bg-[#0e0f13]/5 my-1" />
            <Link
              href="/auth/login"
              onClick={closeDrawer}
              className="min-h-[48px] px-4 rounded-xl flex items-center gap-3 text-[#584237] hover:text-[#0e0f13] hover:bg-[#ffedd5]/50 transition-colors"
            >
              <Icon name="login" className="text-[20px]" />
              <span className="text-[15px] font-semibold">Login</span>
            </Link>
          </nav>
          <div className="mx-3 mb-3 p-3 bg-[#ffedd5]/60 border border-[#fed7aa] rounded-2xl">
            <div className="flex items-center gap-1 mb-1">
              <Icon name="verified" className="text-[#f97316] text-[18px]" />
              <span className="text-label-sm text-[#f97316] font-bold">DOOYN ESCROW GUARANTEE</span>
            </div>
            <p className="text-body-md text-[#0e0f13]/80">
              Funds stay protected until task verification OTP is submitted.
            </p>
          </div>
        </div>
      </div>

      <main className="flex-1 flex flex-col relative w-full pt-16 pb-24 bg-[#fafaf8]">
        {/* Hero */}
        <section className="relative page-container pt-4 pb-6 overflow-hidden">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#ffedd5] border border-[#fed7aa] text-[#f97316] text-label-sm shadow-sm mb-3">
            <span className="inline-block w-2 h-2 rounded-full bg-[#f97316] animate-pulse" />
            <span className="font-semibold text-[#0e0f13]">Live in Uyo — Expanding Nationwide</span>
          </div>

          <div className="flex flex-col gap-2 mb-4">
            <h1 className="font-headline text-[32px] leading-[38px] tracking-tight text-[#0e0f13] font-extrabold">
              Get things done with <span className="text-[#f97316]">verified local runners.</span>
            </h1>
            <p className="text-body-md text-[#0e0f13]/70 leading-relaxed">
              Document runs, market shopping, queue standing, and parcels. Fast, reliable, and 100% escrow guaranteed.
            </p>
          </div>

          <div className="relative bg-white p-2 rounded-2xl shadow-md border border-[#0e0f13]/5 mb-4">
            <form
              className="flex items-center gap-2"
              onSubmit={(e) => {
                e.preventDefault();
                window.location.href = '/auth/register';
              }}
            >
              <Icon name="search" className="text-[#f97316] pl-2" />
              <input
                className="w-full bg-transparent text-[#0e0f13] text-body-md focus:outline-none placeholder:text-[#8c7164] py-2"
                placeholder="What do you need handled in Uyo?"
                type="text"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
              />
              <Link
                href="/auth/register"
                className="shrink-0 bg-[#f97316] hover:bg-[#ea580c] text-white px-4 py-2 rounded-xl text-label-md shadow-sm active:scale-95 transition-all flex items-center gap-1 font-bold"
              >
                <span>Find Runner</span>
                <Icon name="arrow_forward" className="text-[16px]" />
              </Link>
            </form>
          </div>

          <div className="flex items-center gap-2 mb-6">
            <Link
              href="/auth/register"
              className="flex-1 min-h-12 bg-[#f97316] hover:bg-[#ea580c] text-white rounded-xl text-label-md flex items-center justify-center gap-2 shadow-md active:scale-[0.98] transition-all font-bold"
            >
              <Icon name="add_task" className="text-[20px]" />
              <span>Post a Task</span>
            </Link>
            <Link
              href="/auth/register?role=runner"
              className="flex-1 min-h-12 bg-white hover:bg-[#f4f3ef] text-[#0e0f13] border border-[#0e0f13]/10 rounded-xl text-label-md flex items-center justify-center gap-2 shadow-sm active:scale-[0.98] transition-all font-semibold"
            >
              <Icon name="electric_moped" className="text-[20px] text-[#f97316]" />
              <span>Become a Runner</span>
            </Link>
          </div>

          <div className="relative w-full rounded-2xl overflow-hidden shadow-md">
            <div
              className="bg-cover bg-center w-full h-48 flex flex-col justify-end p-4 relative"
              style={{ backgroundImage: `url('${DISPATCH_IMG}')` }}
            >
              <div className="absolute inset-0 bg-gradient-to-t from-[#0e0f13]/90 via-[#0e0f13]/40 to-transparent" />
              <div className="relative z-10 flex items-center justify-between text-white gap-3">
                <div>
                  <p className="text-label-sm uppercase tracking-wider text-[#ffedd5] font-bold">Live Dispatch</p>
                  <p className="font-headline text-[18px] leading-6 font-bold text-white">
                    14 Runners ready near Shelter Afrique
                  </p>
                </div>
                <span className="px-2 py-1 rounded-full bg-[#f97316] text-white text-label-sm font-bold flex items-center gap-1 shadow-sm shrink-0">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#ffedd5] animate-ping" /> 4m avg pickup
                </span>
              </div>
            </div>
          </div>
        </section>

        {/* Trust strip */}
        <section className="bg-white border-y border-[#0e0f13]/5 py-3 page-container mb-6 shadow-sm">
          <div className="flex items-center justify-between overflow-x-auto gap-4 py-1 no-scrollbar">
            {[
              { icon: 'verified_user', label: 'Escrow Protected', fill: true },
              { icon: 'badge', label: '100% KYC Verified', fill: true },
              { icon: 'near_me', label: 'Live GPS Tracking', fill: false },
              { icon: 'star', label: '4.9★ Average', fill: true },
            ].map((t, i) => (
              <div key={t.label} className="flex items-center gap-4 shrink-0">
                {i > 0 && <div className="w-1 h-1 rounded-full bg-[#fed7aa] shrink-0" />}
                <div className="flex items-center gap-1 shrink-0">
                  <Icon name={t.icon} className="text-[#f97316] text-[20px]" fill={t.fill} />
                  <span className="text-label-md text-[#0e0f13] font-bold whitespace-nowrap">{t.label}</span>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Popular errands */}
        <section id="services-m" className="page-container mb-8">
          <div className="flex items-center justify-between mb-3">
            <div>
              <h2 className="font-headline text-headline-md text-[#0e0f13] font-bold">Popular Errands</h2>
              <p className="text-body-md text-[#584237]">Tap to book directly in seconds</p>
            </div>
            <a href="#services-m" className="text-label-md text-[#f97316] flex items-center gap-0.5 font-bold">
              <span>View all</span>
              <Icon name="chevron_right" className="text-[16px]" />
            </a>
          </div>
          <div className="grid grid-cols-2 gap-2">
            {mobileServices.map((s) => (
              <Link
                key={s.title}
                href="/auth/register"
                className="bg-white p-3 rounded-2xl shadow-sm border border-[#0e0f13]/5 hover:shadow-md transition-shadow flex flex-col justify-between"
              >
                <div className="flex items-start justify-between mb-3">
                  <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${s.iconWrap}`}>
                    <Icon name={s.icon} className="text-[24px]" />
                  </div>
                  {s.tag && (
                    <span className={`px-1 py-0.5 rounded text-[10px] font-bold ${s.tagClass}`}>{s.tag}</span>
                  )}
                </div>
                <div>
                  <h3 className="font-headline text-[16px] text-[#0e0f13] font-bold">{s.title}</h3>
                  <p className="text-body-md text-[#584237] text-[12px] mb-2">{s.desc}</p>
                  <div className="font-headline text-[24px] leading-7 tracking-tight text-[#f97316] font-bold">
                    {s.price}
                  </div>
                </div>
              </Link>
            ))}
          </div>
        </section>

        {/* How it works */}
        <section id="how-it-works-m" className="page-container mb-8">
          <div className="bg-white border border-[#0e0f13]/5 p-4 rounded-2xl shadow-sm flex flex-col gap-4">
            <div>
              <span className="text-label-sm uppercase tracking-wider text-[#f97316] font-bold">Zero Risk Mechanics</span>
              <h2 className="font-headline text-headline-md text-[#0e0f13] font-bold">How DOOYN Works</h2>
              <p className="text-body-md text-[#584237]">Clear physical-to-digital execution with zero ambiguities.</p>
            </div>
            <div className="flex flex-col gap-3">
              {howSteps.map((step) => (
                <div
                  key={step.n}
                  className="flex items-start gap-3 bg-[#fafaf8] p-3 rounded-xl border border-[#0e0f13]/5"
                >
                  <div
                    className={`w-10 h-10 rounded-xl flex items-center justify-center font-bold text-[16px] shrink-0 font-headline ${step.wrap}`}
                  >
                    {step.n}
                  </div>
                  <div className="flex-1">
                    <div className="flex items-center gap-2">
                      <h3 className="font-headline text-[16px] text-[#0e0f13] font-bold">{step.title}</h3>
                      {step.badge && (
                        <span className="bg-[#dcfce7] text-[#15803d] px-1 py-0.5 rounded text-[10px] font-bold">
                          {step.badge}
                        </span>
                      )}
                    </div>
                    <p className="text-body-md text-[#584237]">{step.desc}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Runners + testimonial */}
        <section className="page-container mb-8">
          <div className="flex items-center justify-between mb-3">
            <div>
              <h2 className="font-headline text-headline-md text-[#0e0f13] font-bold">Top Verified Runners</h2>
              <p className="text-body-md text-[#584237]">Active today across Uyo metropolis</p>
            </div>
            <span className="flex items-center gap-1 text-[#f97316] text-label-md font-bold">
              <span className="w-2 h-2 rounded-full bg-[#f97316]" /> 98 online
            </span>
          </div>

          <div className="flex flex-col gap-3">
            {[
              {
                img: RUNNER_EMEM,
                name: 'Emem Udo',
                zone: 'Shelter Afrique & Oron Rd zone',
                rating: '4.98',
                tasks: '420+ tasks',
                metaIcon: 'speed',
                meta: '18 min avg completion',
              },
              {
                img: RUNNER_BLESSING,
                name: 'Blessing Bassey',
                zone: 'Itam, Ikot Ekpene Rd, Plaza',
                rating: '5.0',
                tasks: '312 tasks',
                metaIcon: 'local_shipping',
                meta: 'Specialist: Market bargaining',
              },
            ].map((r) => (
              <div
                key={r.name}
                className="bg-white p-4 rounded-2xl shadow-sm border border-[#0e0f13]/5 flex flex-col gap-3"
              >
                <div className="flex items-center justify-between gap-2">
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="relative shrink-0">
                      <img
                        className="w-12 h-12 rounded-full object-cover shadow-sm ring-2 ring-[#f97316]/20"
                        alt={r.name}
                        src={r.img}
                      />
                      <span className="absolute bottom-0 right-0 w-3.5 h-3.5 rounded-full bg-[#16a34a] flex items-center justify-center">
                        <Icon name="check" className="text-[10px] text-white" />
                      </span>
                    </div>
                    <div className="min-w-0">
                      <div className="flex items-center gap-1 flex-wrap">
                        <h3 className="font-headline text-[16px] text-[#0e0f13] font-bold">{r.name}</h3>
                        <span className="px-1 py-0.5 rounded-full bg-[#dcfce7] text-[#15803d] text-[10px] font-bold">
                          KYC VERIFIED
                        </span>
                      </div>
                      <p className="text-body-md text-[#584237] text-[12px] truncate">{r.zone}</p>
                    </div>
                  </div>
                  <div className="text-right shrink-0">
                    <div className="flex items-center gap-0.5 text-[#f97316] justify-end">
                      <Icon name="star" className="text-[18px]" fill />
                      <span className="text-label-md font-bold text-[#0e0f13]">{r.rating}</span>
                    </div>
                    <span className="text-label-sm text-[#584237]">{r.tasks}</span>
                  </div>
                </div>
                <div className="bg-[#fafaf8] p-2 rounded-xl flex items-center justify-between text-[#584237] text-label-sm border border-[#0e0f13]/5">
                  <span className="flex items-center gap-1">
                    <Icon name={r.metaIcon} className="text-[16px] text-[#f97316]" /> {r.meta}
                  </span>
                  <span className="font-bold text-[#f97316]">Ready now</span>
                </div>
              </div>
            ))}
          </div>

          <div className="mt-4 bg-white border border-[#0e0f13]/5 p-4 rounded-2xl shadow-sm">
            <div className="flex items-center gap-2 mb-2">
              <div className="flex text-[#f97316]">
                {Array.from({ length: 5 }).map((_, i) => (
                  <Icon key={i} name="star" className="text-[18px]" fill />
                ))}
              </div>
              <span className="text-label-sm text-[#584237]">2 hours ago</span>
            </div>
            <p className="text-body-md text-[#0e0f13] italic mb-3">
              &ldquo;I was stuck in back-to-back boardroom meetings in Ewet Housing. DOOYN dispatched a runner who stood
              in line at the Corporate Affairs registry and hand-delivered my stamped documents before noon. Escrow OTP
              gave me full peace of mind.&rdquo;
            </p>
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-full bg-[#0e0f13] text-white flex items-center justify-center font-bold text-[12px]">
                KA
              </div>
              <div>
                <p className="text-label-md text-[#0e0f13] font-bold">Kufre Archibong</p>
                <p className="text-label-sm text-[#584237]">Founder, Apex Dynamics (Uyo)</p>
              </div>
            </div>
          </div>
        </section>

        {/* Escrow */}
        <section id="safety-m" className="page-container mb-8">
          <div className="bg-[#ffedd5]/60 border border-[#fed7aa] p-4 rounded-2xl shadow-sm flex items-start gap-3">
            <div className="w-12 h-12 rounded-xl bg-[#f97316] text-white flex items-center justify-center shrink-0 shadow-sm">
              <Icon name="lock" className="text-[28px]" fill />
            </div>
            <div>
              <h3 className="font-headline text-headline-md text-[#0e0f13] font-bold mb-1">Escrow Guarantee</h3>
              <p className="text-body-md text-[#0e0f13]/80 leading-relaxed">
                Your money never leaves escrow until you verify the errand and share your secret 4-digit OTP directly
                with the runner. No surprises. No unfulfilled runs.
              </p>
            </div>
          </div>
        </section>

        {/* CTA */}
        <section className="page-container mb-8">
          <div className="bg-[#0e0f13] text-white p-6 rounded-2xl shadow-xl flex flex-col gap-4 relative overflow-hidden">
            <div className="absolute -right-8 -bottom-8 w-44 h-44 rounded-full bg-[#f97316]/20 blur-2xl pointer-events-none" />
            <div className="relative z-10 flex flex-col gap-2">
              <span className="text-label-sm uppercase tracking-widest text-[#fed7aa] font-bold">Ready in 60 Seconds</span>
              <h2 className="font-headline text-[32px] leading-[38px] font-extrabold text-white">
                Ready to take errands off your plate?
              </h2>
              <p className="text-body-md text-white/80 leading-relaxed">
                Post your task today and get matched with top-rated Uyo runners within 3 minutes.
              </p>
            </div>
            <div className="relative z-10 flex flex-col gap-2">
              <Link
                href="/auth/register"
                className="min-h-12 w-full bg-[#f97316] text-white hover:bg-[#ea580c] text-label-md rounded-xl flex items-center justify-center gap-2 shadow-md active:scale-[0.98] transition-transform font-bold"
              >
                <span>Post a Task Now</span>
                <Icon name="arrow_forward" className="text-[18px]" />
              </Link>
              <a
                href="#how-it-works-m"
                className="h-10 w-full text-[#ffedd5] hover:text-white text-label-md rounded-xl flex items-center justify-center gap-1 transition-colors"
              >
                <span>See detailed safety checklist</span>
                <Icon name="chevron_right" className="text-[16px]" />
              </a>
            </div>
          </div>
        </section>

        {/* Footer */}
        <footer className="w-full bg-[#0e0f13] text-white page-container pt-8 pb-10 mt-auto">
          <div className="flex flex-col gap-6">
            <div className="flex items-center justify-between pb-3 border-b border-white/10">
              <div className="flex items-center gap-2">
                <img alt="DOOYN" className="h-7 w-7 object-contain rounded-md" src={LOGO_FOOTER} />
                <span className="font-headline text-headline-md font-bold text-white tracking-tight">DOOYN</span>
              </div>
              <span className="text-label-sm text-[#fed7aa]">Uyo, Akwa Ibom</span>
            </div>

            <div className="flex items-center gap-2 bg-white/5 border border-white/10 p-3 rounded-xl">
              <Icon name="shield" className="text-[#f97316] text-[22px]" />
              <div className="flex flex-col">
                <span className="text-label-md text-white font-bold">100% Escrow Protected</span>
                <span className="text-body-md text-white/70">Instant digital sign-off and verified runners only.</span>
              </div>
            </div>

            <div className="flex flex-wrap gap-x-6 gap-y-2 text-label-md text-white/70">
              <a href="#how-it-works-m" className="hover:text-[#f97316] transition-colors">
                How it Works
              </a>
              <a href="#services-m" className="hover:text-[#f97316] transition-colors">
                Services
              </a>
              <a href="#safety-m" className="hover:text-[#f97316] transition-colors">
                Safety &amp; Escrow
              </a>
              <Link href="/auth/register?role=runner" className="hover:text-[#f97316] transition-colors">
                Become a Runner
              </Link>
              <Link href="/auth/login" className="hover:text-[#f97316] transition-colors">
                Client Login
              </Link>
            </div>

            <div className="flex flex-col gap-2">
              <span className="text-label-sm text-white/50 uppercase tracking-wider">Download DOOYN App</span>
              <div className="flex items-center gap-2">
                <div className="min-h-[44px] flex items-center gap-2 px-4 py-2 bg-white/10 border border-white/10 rounded-xl text-white">
                  <Icon name="phone_iphone" className="text-[20px]" />
                  <div className="flex flex-col text-left">
                    <span className="text-[9px] leading-3 uppercase text-white/60">Available on</span>
                    <span className="text-label-md leading-4 font-bold">App Store</span>
                  </div>
                </div>
                <div className="min-h-[44px] flex items-center gap-2 px-4 py-2 bg-white/10 border border-white/10 rounded-xl text-white">
                  <Icon name="play_arrow" className="text-[20px]" />
                  <div className="flex flex-col text-left">
                    <span className="text-[9px] leading-3 uppercase text-white/60">Get it on</span>
                    <span className="text-label-md leading-4 font-bold">Google Play</span>
                  </div>
                </div>
              </div>
            </div>

            <div className="text-body-md text-white/50 pt-2 border-t border-white/10">
              © 2026 DOOYN Technologies Inc. Verified Urban Gig Infrastructure.
            </div>
          </div>
        </footer>
      </main>

      {/* Bottom nav */}
      <nav className="fixed bottom-0 left-0 right-0 z-50 bg-[#fafaf8]/95 backdrop-blur-xl border-t border-[#0e0f13]/5 pb-[env(safe-area-inset-bottom,0px)]">
        <div className="flex justify-around items-center h-16 px-2">
          <a
            href="#"
            className="flex flex-col items-center justify-center min-w-[56px] min-h-12 transition-colors text-[#f97316] font-bold"
            aria-current="page"
          >
            <Icon name="explore" className="text-[22px]" />
            <span className="text-label-sm">Explore</span>
          </a>
          <a
            href="#services-m"
            className="flex flex-col items-center justify-center min-w-[56px] min-h-12 text-[#0e0f13]/60 hover:text-[#f97316] transition-colors"
          >
            <Icon name="grid_view" className="text-[22px]" />
            <span className="text-label-sm">Services</span>
          </a>
          <Link
            href="/auth/register"
            className="flex flex-col items-center justify-center min-w-[56px] min-h-12 text-[#0e0f13]/60 hover:text-[#f97316] transition-colors"
          >
            <Icon name="add_circle" className="text-[22px]" />
            <span className="text-label-sm">Post Task</span>
          </Link>
          <a
            href="#safety-m"
            className="flex flex-col items-center justify-center min-w-[56px] min-h-12 text-[#0e0f13]/60 hover:text-[#f97316] transition-colors"
          >
            <Icon name="shield" className="text-[22px]" />
            <span className="text-label-sm">Safety</span>
          </a>
          <Link
            href="/auth/login"
            className="flex flex-col items-center justify-center min-w-[56px] min-h-12 text-[#0e0f13]/60 hover:text-[#f97316] transition-colors"
          >
            <Icon name="account_circle" className="text-[22px]" />
            <span className="text-label-sm">Account</span>
          </Link>
        </div>
      </nav>
    </div>
  );
}
