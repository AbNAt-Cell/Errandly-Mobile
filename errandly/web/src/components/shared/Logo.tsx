import Link from 'next/link';

interface LogoProps {
  className?: string;
  iconSize?: string;
  textSize?: string;
  subtext?: string;
  href?: string;
}

export default function Logo({
  className = '',
  iconSize = 'w-9 h-9',
  textSize = 'text-2xl',
  subtext,
  href = '/',
}: LogoProps) {
  const content = (
    <div className={`inline-flex items-center gap-2.5 ${className}`}>
      <img
        src="/logo.png"
        alt="Errand Logo"
        className={`${iconSize} object-contain flex-shrink-0`}
      />
      <div className="flex flex-col">
        <span className={`font-['Bricolage_Grotesque'] text-[#F97316] ${textSize} tracking-tight font-bold leading-none`}>
          Errand
        </span>
        {subtext && (
          <span className="text-[11px] text-[#e0c0b1] tracking-wider uppercase font-medium mt-0.5">
            {subtext}
          </span>
        )}
      </div>
    </div>
  );

  if (!href) return content;
  return (
    <Link href={href} className="hover:opacity-90 transition-opacity">
      {content}
    </Link>
  );
}
