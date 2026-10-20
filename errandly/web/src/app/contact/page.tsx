import { getPageContent } from '@/lib/cms';
import Header from '@/components/shared/Header';
import Footer from '@/components/shared/Footer';
import { Metadata } from 'next';

export const dynamic = 'force-dynamic';
export const revalidate = 0;

export async function generateMetadata(): Promise<Metadata> {
  const content = await getPageContent('contact');
  return {
    title: content.meta.title,
    description: content.meta.description,
  };
}

export default async function ContactPage() {
  const [content, homeContent] = await Promise.all([
    getPageContent('contact'),
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

      {/* Main Content */}
      <section className="py-24 bg-[#FAFAF8] text-[#0E0F13]">
        <div className="max-w-[1280px] mx-auto px-4 md:px-8">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-16">
            
            {/* Left: Contact Info & FAQ */}
            <div className="space-y-16">
              <div>
                <h2 className="font-['Bricolage_Grotesque'] font-bold text-[32px] mb-8">{content.contactInfo.heading}</h2>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                  {content.contactInfo.items.map((item: any, idx: number) => (
                    <div key={idx} className="space-y-4">
                      <div className="w-12 h-12 bg-orange-50 rounded-xl flex items-center justify-center text-[#F97316]">
                        <span className="material-symbols-outlined">{item.icon}</span>
                      </div>
                      <h3 className="font-['Bricolage_Grotesque'] font-bold text-xl">{item.title}</h3>
                      <div className="space-y-1">
                        {item.details.map((detail: string, dIdx: number) => (
                          <p key={dIdx} className="text-gray-600 font-['Inter']">{detail}</p>
                        ))}
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              <div className="pt-8 border-t border-gray-200">
                <h2 className="font-['Bricolage_Grotesque'] font-bold text-[32px] mb-8">{content.faq.heading}</h2>
                <div className="space-y-6">
                  {content.faq.items.map((faq: any, idx: number) => (
                    <div key={idx} className="bg-white p-6 rounded-2xl border border-gray-200 shadow-sm">
                      <h4 className="font-['Bricolage_Grotesque'] font-bold text-lg mb-2 text-[#0E0F13]">{faq.question}</h4>
                      <p className="text-gray-600 font-['Inter'] leading-relaxed">{faq.answer}</p>
                    </div>
                  ))}
                </div>
              </div>
            </div>

            {/* Right: Contact Form */}
            <div>
              <div className="bg-white p-8 md:p-12 rounded-[2rem] shadow-xl border border-gray-100 sticky top-32">
                <div className="mb-8">
                  <h2 className="font-['Bricolage_Grotesque'] font-bold text-[32px] mb-2">{content.form.heading}</h2>
                  <p className="text-gray-600 font-['Inter']">{content.form.description}</p>
                </div>

                <form className="space-y-6">
                  {content.form.fields.map((field: any, idx: number) => (
                    <div key={idx}>
                      <label className="block font-['Inter'] text-sm font-medium text-gray-700 mb-2">
                        {field.label} {field.required && <span className="text-[#F97316]">*</span>}
                      </label>
                      {field.type === 'textarea' ? (
                        <textarea 
                          rows={4}
                          placeholder={field.placeholder}
                          required={field.required}
                          className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-[#F97316] focus:ring-2 focus:ring-[#F97316]/20 transition-all outline-none font-['Inter'] text-[#0E0F13] resize-none"
                        ></textarea>
                      ) : field.type === 'select' ? (
                        <select 
                          required={field.required}
                          className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-[#F97316] focus:ring-2 focus:ring-[#F97316]/20 transition-all outline-none font-['Inter'] text-[#0E0F13] bg-white"
                        >
                          {field.options.map((opt: string, oIdx: number) => (
                            <option key={oIdx} value={opt}>{opt}</option>
                          ))}
                        </select>
                      ) : (
                        <input 
                          type={field.type}
                          placeholder={field.placeholder}
                          required={field.required}
                          className="w-full px-4 py-3 rounded-xl border border-gray-200 focus:border-[#F97316] focus:ring-2 focus:ring-[#F97316]/20 transition-all outline-none font-['Inter'] text-[#0E0F13]"
                        />
                      )}
                    </div>
                  ))}

                  <button type="submit" className="w-full bg-[#0E0F13] text-white px-8 py-4 rounded-xl font-['Bricolage_Grotesque'] font-bold hover:bg-[#F97316] transition-all flex items-center justify-center gap-2">
                    {content.form.submitLabel} <span className="material-symbols-outlined text-[20px]">{content.form.submitIcon}</span>
                  </button>
                </form>
              </div>
            </div>

          </div>
        </div>
      </section>

      <Footer data={homeContent.footer} />
    </>
  );
}
