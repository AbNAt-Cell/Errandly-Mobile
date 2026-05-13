import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    extend: {
      colors: {
        primary: '#FF6B00',
        'primary-dark': '#CC5500',
        'primary-light': '#FF8C3A',
        'primary-faded': '#FFF0E6',
        navy: '#0A1628',
        'navy-light': '#1A2E4A',
      },
      borderRadius: {
        xl: '12px',
        '2xl': '16px',
        '3xl': '24px',
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [],
};

export default config;
