import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  reactStrictMode: true,
  images: {
    domains: ['localhost', 'errandly.com'],
  },
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api',
    NEXT_PUBLIC_PUSHER_KEY: process.env.NEXT_PUBLIC_PUSHER_KEY || '',
    NEXT_PUBLIC_PUSHER_CLUSTER: process.env.NEXT_PUBLIC_PUSHER_CLUSTER || 'mt1',
  },
};

export default nextConfig;
