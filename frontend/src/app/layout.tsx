import './globals.css'
import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Real Estate Image Explorer',
  description: 'Explore real estate images',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="ja">
      <body>{children}</body>
    </html>
  )
}
