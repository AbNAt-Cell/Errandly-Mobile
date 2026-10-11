'use client';

import { useEffect, useState } from 'react';
import { useTheme } from 'next-themes';
import { Moon, Sun, Monitor } from 'lucide-react';

type ThemeToggleProps = {
  className?: string;
  /** Compact icon-only control for tight headers */
  compact?: boolean;
};

const order = ['light', 'dark', 'system'] as const;

export function ThemeToggle({ className = '', compact = true }: ThemeToggleProps) {
  const { theme, setTheme, resolvedTheme } = useTheme();
  const [mounted, setMounted] = useState(false);

  useEffect(() => {
    setMounted(true);
  }, []);

  if (!mounted) {
    return (
      <button
        type="button"
        aria-label="Toggle theme"
        className={`inline-flex items-center justify-center h-9 w-9 rounded-xl border border-white/10 dark:border-white/10 border-gray-200 bg-white/5 dark:bg-white/5 bg-gray-100 p-2 text-gray-500 dark:text-gray-400 ${className}`}
      >
        <Sun className="h-4 w-4 opacity-40" />
      </button>
    );
  }

  const current = (theme as (typeof order)[number]) || 'system';
  const isDark = resolvedTheme === 'dark';

  const toggle = () => {
    setTheme(isDark ? 'light' : 'dark');
  };

  if (compact) {
    return (
      <button
        type="button"
        onClick={toggle}
        aria-label={`Switch to ${isDark ? 'light' : 'dark'} mode`}
        title={`Current: ${isDark ? 'Dark' : 'Light'} mode (click to toggle)`}
        className={`inline-flex items-center justify-center h-9 w-9 rounded-xl border transition-all duration-200 
          dark:bg-white/5 dark:border-white/10 dark:text-gray-300 dark:hover:text-[#F97316] dark:hover:border-[#F97316]/40 dark:hover:bg-[#F97316]/10
          bg-gray-100 border-gray-200 text-gray-700 hover:text-[#F97316] hover:border-[#F97316]/40 hover:bg-orange-50
          ${className}`}
      >
        {isDark ? (
          <Sun className="h-4 w-4 text-amber-400 transition-transform hover:rotate-45" />
        ) : (
          <Moon className="h-4 w-4 text-gray-700 transition-transform hover:-rotate-12" />
        )}
      </button>
    );
  }

  return (
    <div className={`inline-flex items-center gap-1 rounded-xl border p-1 
      dark:bg-[#17191F] dark:border-white/10 bg-gray-100 border-gray-200 ${className}`}>
      {order.map((value) => {
        const ActiveIcon = value === 'light' ? Sun : value === 'dark' ? Moon : Monitor;
        const active = current === value;
        return (
          <button
            key={value}
            type="button"
            onClick={() => setTheme(value)}
            aria-label={`Use ${value} theme`}
            className={`inline-flex items-center gap-1.5 rounded-lg px-2.5 py-1 text-xs font-medium transition-all ${
              active
                ? 'bg-[#F97316] text-[#121317] font-semibold shadow-sm'
                : 'dark:text-gray-400 dark:hover:text-white text-gray-600 hover:text-gray-900'
            }`}
          >
            <ActiveIcon className="h-3.5 w-3.5" />
            <span className="capitalize">{value}</span>
          </button>
        );
      })}
    </div>
  );
}
