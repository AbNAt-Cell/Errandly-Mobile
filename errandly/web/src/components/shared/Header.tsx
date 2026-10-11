import Link from 'next/link';
import { ThemeToggle } from './ThemeToggle';

export default function Header({ data }: { data: any }) {
  if (!data) return null;
  return (
    <nav className="fixed top-0 w-full z-50 bg-white/90 dark:bg-[#0E0F13]/90 backdrop-blur-md border-b border-gray-200 dark:border-white/10 transition-colors">
      <div className="max-w-[1280px] mx-auto flex justify-between items-center px-4 md:px-8 py-4">
        <Link href="/" className="flex items-center gap-2">
          {data.logo && <img src={data.logo} alt={data.logoAlt || 'Logo'} className="w-10 h-10 object-contain" />}
          <span className="font-['Bricolage_Grotesque'] text-[#F97316] text-2xl tracking-tight font-bold">{data.brandName}</span>
        </Link>
        <div className="hidden md:flex items-center gap-6">
          {data.links?.map((link: any, idx: number) => (
            <Link key={idx} className="font-['Inter'] text-gray-700 dark:text-[#e0c0b1] hover:text-[#F97316] transition-colors" href={link.href}>
              {link.label}
            </Link>
          ))}
          <Link className="font-['Inter'] text-gray-700 dark:text-[#e0c0b1] hover:text-[#F97316] transition-colors" href={data.loginHref || '/auth/login'}>
            {data.loginLabel || 'Login'}
          </Link>
          <ThemeToggle />
          <Link href={data.ctaHref || '/auth/register'} className="bg-[#F97316] text-[#121317] px-6 py-2.5 rounded-xl font-['Bricolage_Grotesque'] font-semibold hover:opacity-90 transition-all active:scale-95 shadow-sm">
            {data.ctaLabel || 'Get Started'}
          </Link>
        </div>
        <div className="flex md:hidden items-center gap-2">
          <ThemeToggle />
          <button className="text-gray-700 dark:text-[#e3e2e7] p-2">
            <span className="material-symbols-outlined">menu</span>
          </button>
        </div>
      </div>
    </nav>
  );
}
