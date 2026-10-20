import { getPageContent } from '@/lib/cms';
import Header from '@/components/shared/Header';
import Footer from '@/components/shared/Footer';
import Link from 'next/link';
import { Metadata } from 'next';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export async function generateMetadata(): Promise<Metadata> {
  const content = await getPageContent('about');
  return {
    title: content.meta.title,
    description: content.meta.description,
  };
}

export default async function AboutPage() {
  const [content, homeContent] = await Promise.all([
    getPageContent('about'),
    getPageContent('home'),
  ]);

  if (!content || !homeContent) return null;

  return (
    <>
      <Header data={homeContent.nav} />

      {/* Hero Section */}
      <section className="pt-32 pb-20 px-4 md:px-8 bg-[#0E0F13] text-center">
        <div className="max-w-4xl mx-auto space-y-8">
          <div className="inline-flex items-center gap-2 bg-[#2A2A2A] px-4 py-1 rounded-full border border-white/10">
            <span className="material-symbols-outlined text-[#F97316] text-sm" style={{ fontVariationSettings: "'FILL' 1" }}>{content.hero.badge.icon}</span>
            <span className="font-['Bricolage_Grotesque'] font-bold text-white text-xs uppercase tracking-wider">{content.hero.badge.text}</span>
          </div>
          <h1 className="font-['Bricolage_Grotesque'] text-[40px] md:text-[64px] leading-[1.1] font-extrabold text-white">
            {content.hero.heading}
          </h1>
          <p className="font-['Inter'] text-[18px] md:text-[20px] text-[#e0c0b1] max-w-2xl mx-auto leading-relaxed">
            {content.hero.description}
          </p>
        </div>
      </section>

      {/* Mission Section */}
      <section className="py-24 bg-[#FAFAF8] text-[#0E0F13]">
        <div className="max-w-[1280px] mx-auto px-4 md:px-8">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-16 items-center">
            <div className="space-y-6">
              <h2 className="font-['Bricolage_Grotesque'] font-bold text-[40px]">{content.mission.heading}</h2>
              <p className="font-['Inter'] text-[18px] text-gray-600 leading-relaxed">
                {content.mission.description}
              </p>
            </div>
            <div className="relative rounded-[2rem] overflow-hidden aspect-video shadow-2xl border border-gray-200">
              <img src={content.mission.image} alt={content.mission.imageAlt} className="w-full h-full object-cover" />
            </div>
          </div>
        </div>
      </section>

      {/* Stats row */}
      <section className="py-16 bg-[#F97316]">
        <div className="max-w-[1280px] mx-auto px-8">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-8 md:gap-0">
            {content.stats.items.map((stat: any, idx: number) => (
              <div key={idx} className={`flex flex-col items-center text-center ${idx < content.stats.items.length - 1 ? 'md:border-r border-[#121317]/10' : ''} px-4`}>
                <span className="material-symbols-outlined text-[#121317] text-3xl mb-4" style={{ fontVariationSettings: "'FILL' 1" }}>{stat.icon}</span>
                <span className="font-['Bricolage_Grotesque'] text-[40px] font-bold text-[#121317] mb-1">{stat.value}</span>
                <span className="font-['Bricolage_Grotesque'] font-bold text-white text-[11px] uppercase">{stat.label}</span>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Values Section */}
      <section className="py-24 bg-[#0E0F13] text-white">
        <div className="max-w-[1280px] mx-auto px-4 md:px-8">
          <div className="text-center mb-16 max-w-2xl mx-auto">
            <h2 className="font-['Bricolage_Grotesque'] font-bold text-[40px] mb-4">{content.values.heading}</h2>
            <p className="font-['Inter'] text-[#e0c0b1]">{content.values.description}</p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {content.values.items.map((val: any, idx: number) => (
              <div key={idx} className="bg-[#1f1f24] p-8 rounded-2xl border border-white/10 hover:border-[#F97316]/50 transition-colors">
                <div className="w-12 h-12 rounded-xl bg-[#F97316]/10 flex items-center justify-center text-[#F97316] mb-6">
                  <span className="material-symbols-outlined text-2xl">{val.icon}</span>
                </div>
                <h3 className="font-['Bricolage_Grotesque'] font-bold text-2xl mb-3">{val.title}</h3>
                <p className="text-[#e0c0b1] leading-relaxed">{val.description}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="py-24 bg-[#FAFAF8] text-center px-4">
        <div className="max-w-2xl mx-auto space-y-8">
          <h2 className="font-['Bricolage_Grotesque'] font-bold text-[40px] text-[#0E0F13]">{content.cta.heading}</h2>
          <p className="font-['Inter'] text-gray-600 text-[18px]">{content.cta.description}</p>
          <div className="flex flex-wrap justify-center gap-4">
            <Link href={content.cta.primaryButton.href} className="bg-[#F97316] text-[#121317] px-8 py-4 rounded-xl font-['Bricolage_Grotesque'] font-bold hover:opacity-90 transition-all active:scale-95 shadow-sm">
              {content.cta.primaryButton.label}
            </Link>
            <Link href={content.cta.secondaryButton.href} className="bg-white border-2 border-gray-200 text-[#0E0F13] px-8 py-4 rounded-xl font-['Bricolage_Grotesque'] font-bold hover:border-[#F97316] hover:text-[#F97316] transition-all">
              {content.cta.secondaryButton.label}
            </Link>
          </div>
        </div>
      </section>

      <Footer data={homeContent.footer} />
    </>
  );
}
