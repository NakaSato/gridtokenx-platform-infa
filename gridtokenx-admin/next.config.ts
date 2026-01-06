/** @type {import('next').NextConfig} */
const nextConfig = {
  // API Gateway URL for server-side requests
  env: {
    NEXT_PUBLIC_API_URL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3001',
  },
  // Allow images from external sources
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'gridtokenx.com',
      },
    ],
  },
};

export default nextConfig;
