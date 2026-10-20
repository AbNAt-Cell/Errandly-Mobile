import { getPageContent } from '@/lib/cms';
import Header from '@/components/shared/Header';
import Footer from '@/components/shared/Footer';
import { Metadata } from 'next';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export async function generateMetadata(): Promise<Metadata> {
  const content = await getPageContent('privacy');
  return {
    title: content.meta.title,
    description: content.meta.description,
  };
}

export default async function PrivacyPage() {
  const [content, homeContent] = await Promise.all([
    getPageContent('privacy'),
    getPageContent('home'),
  ]);

  if (!content || !homeContent) return null;

  return (
    <>
      <Header data={homeContent.nav} />

      {/* Hero Section */}
      <section className="pt-32 pb-20 px-4 md:px-8 bg-[#0E0F13] text-center border-b border-white/10">
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

      {/* Main Content */}
      <section className="py-24 bg-[#FAFAF8] text-[#0E0F13]">
        <div className="max-w-[800px] mx-auto px-4 md:px-8 space-y-16">
          {content.sections.map((section: any, idx: number) => (
            <div key={idx} className="bg-white p-8 md:p-12 rounded-3xl shadow-sm border border-gray-100">
              <div className="flex flex-col md:flex-row md:items-center gap-4 mb-8 pb-8 border-b border-gray-100">
                <div className="w-12 h-12 bg-orange-50 rounded-xl flex items-center justify-center text-[#F97316] shrink-0">
                  <span className="material-symbols-outlined">{section.icon}</span>
                </div>
                <h2 className="font-['Bricolage_Grotesque'] font-bold text-2xl md:text-3xl text-[#0E0F13]">{section.title}</h2>
              </div>
              
              <div className="space-y-8">
                {section.content.map((item: any, iIdx: number) => (
                  <div key={iIdx}>
                    {item.subtitle && (
                      <h3 className="font-['Bricolage_Grotesque'] font-bold text-xl text-[#0E0F13] mb-3">{item.subtitle}</h3>
                    )}
                    <p className="text-gray-600 font-['Inter'] leading-relaxed text-[16px]">
                      {item.text}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </div>
      </section>

      <Footer data={homeContent.footer} />
    </>
  );
}
