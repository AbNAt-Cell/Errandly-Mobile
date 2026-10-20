import Link from 'next/link';
import { getPageContent } from '@/lib/cms';
import Header from '@/components/shared/Header';
import Footer from '@/components/shared/Footer';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export default async function LandingPage() {
  const content = await getPageContent('home');
  if (!content) return <div>Failed to load content</div>;

  return (
    <>
      <Header data={content.nav} />

      {/* 2. Hero Section */}
      <section className="pt-32 pb-20 px-4 md:px-8 overflow-hidden bg-[#0E0F13]">
        <div className="max-w-[1280px] mx-auto grid grid-cols-1 md:grid-cols-[55%_45%] gap-12 items-center">
          {/* Left Content */}
          <div className="space-y-8">
            <div className="inline-flex items-center gap-2 bg-[#F97316] px-4 py-1 rounded-full">
              <span className="material-symbols-outlined text-[#121317] text-sm" style={{ fontVariationSettings: "'FILL' 1" }}>{content.hero.badge.icon}</span>
              <span className="font-['Bricolage_Grotesque'] font-bold text-[#121317] text-xs uppercase tracking-wider">{content.hero.badge.text}</span>
            </div>
            <h1 className="font-['Bricolage_Grotesque'] text-[36px] md:text-[56px] leading-[1.1] font-extrabold text-white">
              {content.hero.heading} <span className="text-[#F97316]">{content.hero.headingAccent}</span>
            </h1>
            <p className="font-['Inter'] text-[18px] text-[#e0c0b1] max-w-lg">
              {content.hero.description}
            </p>
            <div className="flex flex-wrap gap-4 pt-4">
              <Link href={content.hero.ctaPrimary.href} className="bg-[#F97316] text-[#121317] px-8 py-4 rounded-lg font-['Bricolage_Grotesque'] font-bold flex items-center gap-2 hover:shadow-[0_0_20px_rgba(249,115,22,0.4)] transition-all">
                {content.hero.ctaPrimary.label} <span className="material-symbols-outlined">{content.hero.ctaPrimary.icon}</span>
              </Link>
              <Link href={content.hero.ctaSecondary.href} className="border border-white/30 text-white px-8 py-4 rounded-lg font-['Bricolage_Grotesque'] font-bold hover:bg-white/10 transition-all">
                {content.hero.ctaSecondary.label}
              </Link>
            </div>
            {/* Trust Bar */}
            <div className="pt-8 border-t border-white/10 flex items-center gap-6">
              <div className="flex -space-x-3">
                {content.hero.trustAvatars.map((avatar: string, idx: number) => (
                  <div key={idx} className="w-10 h-10 rounded-full border-2 border-[#0E0F13] bg-[#343439] flex items-center justify-center overflow-hidden">
                    <img alt={`Trust Avatar ${idx}`} className="w-full h-full object-cover" src={avatar} />
                  </div>
                ))}
              </div>
              <p className="font-['Bricolage_Grotesque'] font-bold text-[#e0c0b1] text-[11px] uppercase tracking-widest">{content.hero.trustText}</p>
            </div>
          </div>
          {/* Right Content (Phone Mockup) */}
          <div className="relative flex justify-center items-center">
            <div className="float-animation relative w-full max-w-[320px] aspect-[9/18.5] bg-[#1f1f24] rounded-[40px] border-[8px] border-[#2A2A2A] shadow-2xl overflow-hidden">
              <div className="w-full h-full bg-[#0E0F13] relative overflow-hidden">
                <div className="absolute inset-0 opacity-40 grayscale" style={{ backgroundImage: `url('${content.hero.phoneImage}')`, backgroundSize: 'cover' }}></div>
                <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2">
                  <div className="w-12 h-12 bg-[#F97316] rounded-full flex items-center justify-center shadow-lg animate-pulse">
                    <span className="material-symbols-outlined text-[#121317]" style={{ fontVariationSettings: "'FILL' 1" }}>directions_bike</span>
                  </div>
                </div>
                <div className="absolute bottom-6 left-1/2 -translate-x-1/2 w-[85%] bg-[#1f1f24] rounded-xl p-4 border border-white/10">
                  <div className="flex items-center gap-3 mb-4">
                    <div className="w-10 h-10 rounded-full bg-[#F97316] flex items-center justify-center font-bold text-[#121317]">EA</div>
                    <div className="flex-1">
                      <p className="text-xs text-[#e0c0b1] font-medium">Emem is on the way</p>
                      <div className="flex items-center gap-2">
                        <span className="text-[10px] bg-[#F97316]/20 text-[#F97316] px-2 py-0.5 rounded-full font-bold">~8 min</span>
                      </div>
                    </div>
                  </div>
                  <div className="h-1.5 w-full bg-[#343439] rounded-full overflow-hidden">
                    <div className="h-full bg-[#F97316] w-[60%]"></div>
                  </div>
                </div>
              </div>
            </div>
            <div className="absolute -z-10 w-[400px] h-[400px] bg-[#F97316]/10 blur-[100px] rounded-full"></div>
          </div>
        </div>
      </section>

      {/* 3. Stats Row */}
      <section className="py-12 bg-[#0E0F13] border-y border-white/10">
        <div className="max-w-[1280px] mx-auto px-8">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 md:gap-0">
            {content.stats.map((stat: any, idx: number) => (
              <div key={idx} className={`flex flex-col items-center text-center ${idx < content.stats.length - 1 ? 'md:border-r border-white/10' : ''} px-4`}>
                <span className="font-['Bricolage_Grotesque'] text-[40px] font-bold text-[#F97316] mb-1">{stat.value}</span>
                <span className="font-['Bricolage_Grotesque'] font-bold text-[#e0c0b1] text-[11px] uppercase">{stat.label}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* 4. Services */}
      <section id="services" className="py-24 bg-[#FAFAF8] text-[#0E0F13]">
        <div className="max-w-[1280px] mx-auto px-4 md:px-8">
          <div className="text-center mb-16">
            <h2 className="font-['Bricolage_Grotesque'] font-bold text-[40px] mb-4">{content.services.heading}</h2>
            <p className="font-['Inter'] text-gray-600">{content.services.description}</p>
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {content.services.items.map((s: any) => (
              <div key={s.title} className="group bg-white p-6 rounded-xl border border-gray-200 hover:border-[#F97316] hover:-translate-y-1 transition-all cursor-pointer shadow-sm">
                <div className="w-12 h-12 bg-orange-50 rounded-lg flex items-center justify-center mb-4 text-[#F97316] group-hover:bg-[#F97316] group-hover:text-white transition-colors">
                  <span className="material-symbols-outlined">{s.icon}</span>
                </div>
                <h3 className="font-['Bricolage_Grotesque'] font-bold text-xl mb-2">{s.title}</h3>
                <p className="text-gray-500 text-sm leading-relaxed">{s.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* 5. How It Works */}
      <section id="how-it-works" className="py-24 bg-[#0E0F13] overflow-hidden">
        <div className="max-w-[1280px] mx-auto px-4 md:px-8">
          <h2 className="font-['Bricolage_Grotesque'] font-bold text-[40px] text-center text-white mb-20">{content.howItWorks.heading}</h2>
          <div className="relative">
            {/* SVG Path */}
            <svg className="hidden lg:block absolute top-1/2 left-0 w-full h-[300px] -translate-y-1/2 pointer-events-none z-0" fill="none" viewBox="0 0 1200 300">
              <path className="opacity-30" d="M50,50 C200,50 200,250 400,250 C600,250 600,50 800,50 C1000,50 1000,250 1150,250" stroke="#F97316" strokeDasharray="10 10" strokeWidth="2"></path>
            </svg>
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-x-8 gap-y-16 relative z-10">
              {content.howItWorks.steps.map((step: any, idx: number) => (
                <div key={idx} className={`flex flex-col items-center text-center group ${idx >= 3 ? 'lg:mt-8' : ''}`}>
                  {step.highlighted ? (
                    <div className="relative w-16 h-16 rounded-full bg-[#F97316] flex items-center justify-center font-['Bricolage_Grotesque'] font-bold text-[40px] text-[#121317] mb-6 glow-orange transition-transform group-hover:scale-110">
                      {step.number}
                      <div className="absolute -top-2 -right-2 bg-[#121317] border border-[#F97316] p-1 rounded-full">
                        <span className="material-symbols-outlined text-[14px] text-[#F97316]" style={{ fontVariationSettings: "'FILL' 1" }}>{step.icon}</span>
                      </div>
                    </div>
                  ) : step.isComplete ? (
                    <div className="w-16 h-16 rounded-full bg-[#1f1f24] border border-white/10 flex items-center justify-center mb-6 transition-transform group-hover:scale-110">
                      <span className="material-symbols-outlined text-3xl text-emerald-500">{step.icon}</span>
                    </div>
                  ) : (
                    <div className="w-16 h-16 rounded-full bg-[#1f1f24] border border-white/10 flex items-center justify-center font-['Bricolage_Grotesque'] font-bold text-[40px] text-[#F97316] mb-6 transition-transform group-hover:scale-110">
                      {step.number}
                    </div>
                  )}
                  {step.badge && (
                    <div className="mb-2">
                      <span className="font-['Bricolage_Grotesque'] font-bold text-[10px] bg-[#F97316]/20 text-[#F97316] px-2 py-0.5 rounded-full uppercase">{step.badge}</span>
                    </div>
                  )}
                  <h4 className="font-['Bricolage_Grotesque'] font-bold text-2xl text-white mb-2">{step.title}</h4>
                  <p className="text-[#e0c0b1] text-sm">{step.description}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* 6. Safety Section */}
      <section className="py-24 bg-[#FAFAF8] text-[#0E0F13]">
        <div className="max-w-[1280px] mx-auto px-4 md:px-8">
          <h2 className="font-['Bricolage_Grotesque'] font-bold text-[40px] text-center mb-16">{content.safety.heading} <span className="text-[#F97316]">{content.safety.headingAccent}</span></h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4 mb-16">
            {content.safety.features.map((feature: any, idx: number) => (
              <div key={idx} className="bg-white p-8 rounded-xl shadow-sm border border-gray-100">
                <span className="material-symbols-outlined text-[#F97316] mb-4 text-3xl">{feature.icon}</span>
                <h5 className="font-['Bricolage_Grotesque'] font-bold text-lg mb-3">{feature.title}</h5>
                <p className="text-gray-500 text-sm">{feature.description}</p>
              </div>
            ))}
          </div>
          <div className="bg-[#0E0F13] rounded-xl p-6 flex flex-wrap items-center justify-center gap-6">
            <span className="material-symbols-outlined text-[#F97316] text-3xl" style={{ fontVariationSettings: "'FILL' 1" }}>{content.safety.banner.icon}</span>
            <p className="text-white font-['Inter'] text-center">{content.safety.banner.text}</p>
            <Link className="text-[#F97316] font-['Bricolage_Grotesque'] font-bold underline underline-offset-4" href={content.safety.banner.linkHref}>{content.safety.banner.linkText}</Link>
          </div>
        </div>
      </section>

      {/* 7. Testimonials */}
      <section className="py-24 bg-[#0E0F13]">
        <div className="max-w-[1280px] mx-auto px-4 md:px-8">
          <h2 className="font-['Bricolage_Grotesque'] font-bold text-[40px] text-center text-white mb-16">{content.testimonials.heading}</h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
            {content.testimonials.items.map((t: any, idx: number) => (
              <div key={idx} className="bg-[#1f1f24] p-8 rounded-xl border border-white/10 flex flex-col justify-between">
                <div>
                  <div className="flex gap-1 text-[#F97316] mb-4">
                    {[...Array(5)].map((_, i) => (
                      <span key={i} className="material-symbols-outlined text-sm" style={{ fontVariationSettings: "'FILL' 1" }}>star</span>
                    ))}
                  </div>
                  <p className="font-['Inter'] text-[#e0c0b1] mb-6 italic">"{t.text}"</p>
                </div>
                <div>
                  <h6 className="font-['Bricolage_Grotesque'] font-bold text-lg text-white">{t.name}</h6>
                  <p className="font-['Bricolage_Grotesque'] font-bold text-[11px] text-[#a78b7d] uppercase">{t.role}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <Footer data={content.footer} />
    </>
  );
}
