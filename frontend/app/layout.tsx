import type { Metadata, Viewport } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import "./globals.css";

import { Providers } from "@/components/providers";

const geistSans = Geist({
  variable: "--font-geist-sans",
  subsets: ["latin"],
});

const geistMono = Geist_Mono({
  variable: "--font-geist-mono",
  subsets: ["latin"],
});

export const metadata: Metadata = {
  title: "VILLEON Gestão",
  description: "Gestão de catálogo, estoque e compras do VILLEON Restaurant.",
  manifest: "/manifest.webmanifest",
  icons: {
    icon: "/icons/icon-512.png",
    // Apple applies its own rounded-square mask on top of whatever image is
    // given and renders transparency as black, so this needs a full-bleed
    // opaque background — the same square used as the Android maskable icon
    // already satisfies that.
    apple: "/icons/icon-maskable-512.png",
  },
  // Pre-iOS 16.4 Safari ignores the manifest's display:standalone and needs
  // these meta tags instead to launch without browser chrome from the home
  // screen icon. Harmless on newer iOS/Android, which use the manifest.
  appleWebApp: {
    capable: true,
    statusBarStyle: "black-translucent",
    title: "VILLEON",
  },
};

export const viewport: Viewport = {
  themeColor: "#0b312e",
  width: "device-width",
  initialScale: 1,
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="pt-BR"
      className={`${geistSans.variable} ${geistMono.variable} h-full antialiased`}
    >
      <body className="min-h-full flex flex-col">
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
