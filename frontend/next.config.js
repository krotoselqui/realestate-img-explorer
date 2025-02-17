/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone',
  experimental: {
    optimizeCss: true
  },
  reactStrictMode: true,
  poweredByHeader: false,
}

module.exports = nextConfig