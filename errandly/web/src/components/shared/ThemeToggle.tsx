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

  useEffect(() => setMounted(true), []);

  if (!mounted) {
    return (
      <button
        type="button"
        aria-label="Toggle theme"
        className={`inline-flex items-center justify-center rounded-lg border border-border bg-card p-2 text-muted-foreground ${className}`}
      >
        <Sun className="h-4 w-4 opacity-40" />
      </button>
    );
  }

  const current = (theme as (typeof order)[number]) || 'system';
  const next = order[(order.indexOf(current) + 1) % order.length];

  const Icon = current === 'dark' || (current === 'system' && resolvedTheme === 'dark') ? Moon : current === 'light' ? Sun : Monitor;

  const cycle = () => setTheme(next);

  if (compact) {
    return (
      <button
        type="button"
        onClick={cycle}
        aria-label={`Theme: ${current}. Click for ${next}`}
        title={`Theme: ${current}`}
        className={`inline-flex items-center justify-center rounded-lg border border-border bg-card p-2 text-foreground hover:border-primary hover:text-primary transition-colors ${className}`}
      >
        <Icon className="h-4 w-4" />
      </button>
    );
  }

  return (
    <div className={`inline-flex items-center gap-1 rounded-lg border border-border bg-card p-1 ${className}`}>
      {order.map((value) => {
        const ActiveIcon = value === 'light' ? Sun : value === 'dark' ? Moon : Monitor;
        const active = current === value;
        return (
          <button
            key={value}
            type="button"
            onClick={() => setTheme(value)}
            aria-label={`Use ${value} theme`}
            className={`inline-flex items-center gap-1.5 rounded-md px-2.5 py-1.5 text-xs font-medium transition-colors ${
              active ? 'bg-primary text-primary-foreground' : 'text-muted-foreground hover:text-foreground'
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
