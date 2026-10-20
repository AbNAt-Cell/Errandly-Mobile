import { getPageContent } from '@/lib/cms';
import Header from '@/components/shared/Header';
import Footer from '@/components/shared/Footer';
import Link from 'next/link';
import { Metadata } from 'next';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export async function generateMetadata(): Promise<Metadata> {
  const content = await getPageContent('careers');
  return {
    title: content.meta.title,
    description: content.meta.description,
  };
}

export default async function CareersPage() {
  const [content, homeContent] = await Promise.all([
    getPageContent('careers'),
    getPageContent('home'),
  ]);

  if (!content || !homeContent) return null;

  return (
    <>
      <Header data={homeContent.nav} />
      
      <main>
        {/* Hero Section */}
        <section className="relative min-h-[716px] flex items-center justify-center overflow-hidden bg-[#0E0F13] py-24">
          <div className="relative z-10 max-w-4xl mx-auto px-4 md:px-8 text-center space-y-8">
            <span className="inline-block font-['Bricolage_Grotesque'] text-xs font-bold uppercase tracking-wider text-[#F97316] border border-[#F97316]/30 px-4 py-1 rounded-full mb-6">
              {content.hero.badge.text}
            </span>
            <h1 className="font-['Bricolage_Grotesque'] text-[40px] md:text-[64px] font-extrabold text-white">
              {content.hero.heading}
            </h1>
            <p className="font-['Inter'] text-[18px] md:text-[20px] text-[#e0c0b1] max-w-2xl mx-auto">
              {content.hero.description}
            </p>
            <div className="mt-10 flex flex-col sm:flex-row items-center justify-center gap-4">
              <a className="w-full sm:w-auto bg-[#F97316] text-[#121317] px-8 py-4 rounded-xl font-['Bricolage_Grotesque'] font-bold hover:shadow-[0_0_20px_rgba(249,115,22,0.4)] transition-all text-center" href={content.hero.ctaPrimary.href}>
                {content.hero.ctaPrimary.label}
              </a>
              <a className="w-full sm:w-auto px-8 py-4 rounded-xl border-2 border-white/20 text-white font-['Bricolage_Grotesque'] font-bold hover:bg-white/10 transition-all text-center" href={content.hero.ctaSecondary.href}>
                {content.hero.ctaSecondary.label}
              </a>
            </div>
          </div>
        </section>

        {/* Why Join Us */}
        <section className="bg-[#FAFAF8] py-24 text-[#0E0F13]">
          <div className="max-w-[1280px] mx-auto px-4 md:px-8">
            <div className="mb-16 text-center">
              <h2 className="font-['Bricolage_Grotesque'] font-bold text-[40px] mb-4">{content.whyJoinUs.heading}</h2>
              <p className="font-['Inter'] text-[18px] text-gray-600 max-w-xl mx-auto">{content.whyJoinUs.description}</p>
            </div>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
              {content.whyJoinUs.items.map((item: any, idx: number) => (
                <div key={idx} className="bg-white p-8 rounded-2xl shadow-sm border border-gray-100 group hover:border-[#F97316]/50 transition-all">
                  <div className="w-12 h-12 bg-orange-50 flex items-center justify-center rounded-xl mb-6 group-hover:bg-[#F97316] transition-colors">
                    <span className="material-symbols-outlined text-[#F97316] group-hover:text-white" style={{ fontVariationSettings: "'FILL' 1" }}>{item.icon}</span>
                  </div>
                  <h3 className="font-['Bricolage_Grotesque'] font-bold text-2xl mb-3">{item.title}</h3>
                  <p className="text-gray-600 font-['Inter'] leading-relaxed">{item.description}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* Culture Section */}
        <section className="bg-[#0E0F13] py-24 overflow-hidden text-white" id="culture">
          <div className="max-w-[1280px] mx-auto px-4 md:px-8">
            <div className="flex flex-col md:flex-row items-center gap-16">
              <div className="w-full md:w-1/2">
                <h2 className="font-['Bricolage_Grotesque'] font-bold text-[40px] mb-12">{content.culture.heading}</h2>
                <div className="space-y-8">
                  {content.culture.values.map((val: any, idx: number) => (
                    <div key={idx} className="flex gap-6 group">
                      <div className="shrink-0 w-10 h-10 rounded-full bg-[#1f1f24] border border-[#F97316]/30 flex items-center justify-center text-[#F97316] font-['Bricolage_Grotesque'] font-bold text-lg group-hover:bg-[#F97316] group-hover:text-[#121317] transition-colors">
                        {idx + 1}
                      </div>
                      <div>
                        <h4 className="font-['Bricolage_Grotesque'] font-bold text-2xl mb-2">{val.title}</h4>
                        <p className="text-[#e0c0b1] font-['Inter'] leading-relaxed">{val.description}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
              <div className="w-full md:w-1/2 relative">
                <div className="relative z-10 rounded-[2rem] overflow-hidden shadow-2xl aspect-square border border-white/10">
                  <img className="w-full h-full object-cover" alt={content.culture.imageAlt} src={content.culture.image} />
                </div>
                <div className="absolute -bottom-6 -right-6 w-48 h-48 bg-[#F97316]/20 rounded-full blur-3xl -z-0"></div>
              </div>
            </div>
          </div>
        </section>

        {/* Open Roles */}
        <section className="bg-[#FAFAF8] py-24 text-[#0E0F13]" id="open-roles">
          <div className="max-w-[1280px] mx-auto px-4 md:px-8">
            <div className="mb-12 flex flex-col md:flex-row md:items-end justify-between gap-4">
              <div>
                <h2 className="font-['Bricolage_Grotesque'] font-bold text-[40px] mb-2">{content.openRoles.heading}</h2>
                <p className="text-gray-600 font-['Inter'] text-[18px]">{content.openRoles.description}</p>
              </div>
              <div className="flex items-center gap-2 text-[#F97316] font-['Bricolage_Grotesque'] font-bold text-sm tracking-wider uppercase">
                <span className="material-symbols-outlined">filter_list</span>
                FILTER BY DEPARTMENT
              </div>
            </div>
            <div className="space-y-4">
              {content.openRoles.roles.map((role: any, idx: number) => (
                <div key={idx} className="bg-white p-6 md:p-8 rounded-2xl border border-gray-200 flex flex-col md:flex-row md:items-center justify-between hover:border-[#F97316] transition-colors group cursor-pointer shadow-sm hover:shadow-md">
                  <div className="mb-6 md:mb-0">
                    <div className="flex items-center gap-3 mb-2">
                      <h3 className="font-['Bricolage_Grotesque'] font-bold text-2xl text-[#0E0F13]">{role.title}</h3>
                      <span className={`bg-${role.typeColor}-50 text-${role.typeColor}-600 px-3 py-1 rounded-full text-xs font-bold uppercase tracking-wider`}>
                        {role.type}
                      </span>
                    </div>
                    <div className="flex flex-wrap items-center gap-4 md:gap-6 text-gray-500 font-['Inter'] text-sm">
                      <span className="flex items-center gap-1.5"><span className="material-symbols-outlined text-[18px]">{role.locationIcon}</span> {role.location}</span>
                      <span className="flex items-center gap-1.5"><span className="material-symbols-outlined text-[18px]">{role.compensationIcon}</span> {role.compensation}</span>
                    </div>
                  </div>
                  <a className="inline-flex items-center justify-center gap-2 text-[#F97316] font-['Bricolage_Grotesque'] font-bold text-lg group-hover:gap-4 transition-all" href="#">
                    Apply Now <span className="material-symbols-outlined">arrow_forward</span>
                  </a>
                </div>
              ))}
            </div>

            {/* Spontaneous Application */}
            <div className="mt-16 bg-[#0E0F13] rounded-3xl p-8 md:p-16 text-center text-white relative overflow-hidden">
              <div className="relative z-10 max-w-2xl mx-auto space-y-8">
                <h3 className="font-['Bricolage_Grotesque'] font-bold text-[32px]">{content.openRoles.spontaneous.heading}</h3>
                <p className="font-['Inter'] text-[18px] text-[#e0c0b1] leading-relaxed">
                  {content.openRoles.spontaneous.description}
                </p>
                <button className="bg-[#F97316] text-[#121317] px-8 py-4 rounded-xl font-['Bricolage_Grotesque'] font-bold hover:bg-[#FF8C3A] transition-all shadow-[0_0_20px_rgba(249,115,22,0.2)]">
                  {content.openRoles.spontaneous.buttonLabel}
                </button>
              </div>
            </div>
          </div>
        </section>
      </main>

      <Footer data={homeContent.footer} />
    </>
  );
}
