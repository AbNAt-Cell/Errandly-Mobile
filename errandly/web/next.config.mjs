/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  reactStrictMode: true,
  images: {
    domains: [
      'localhost',
      'errandly.ng',
      'errandly.com.ng',
      'errandly.vocettt.com.ng',
      'errandly-web-yob65x-3fabb8-169-58-145-66.sslip.io',
    ],
  },
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'https://errandly-web-yob65x-3fabb8-169-58-145-66.sslip.io/api',
    NEXT_PUBLIC_PUSHER_KEY: process.env.NEXT_PUBLIC_PUSHER_KEY || '',
    NEXT_PUBLIC_PUSHER_CLUSTER: process.env.NEXT_PUBLIC_PUSHER_CLUSTER || 'mt1',
  },
};

export default nextConfig;
