import type { Metadata } from "next";
import "./globals.css";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { OrganizationJsonLd } from "@/components/JsonLd";
import { CookieConsentProvider } from "@/components/CookieConsentProvider";
import { CookieBanner } from "@/components/CookieBanner";

export const metadata: Metadata = {
  icons: {
    icon: "/icon.svg",
    apple: "/icon.svg",
  },
  title: {
    default: "Macromaxxing — AI-Powered Macro Tracker & Nutrition App",
    template: "%s | Macromaxxing",
  },
  description:
    "Track macros with AI photo analysis, voice logging, and smart workout adjustments. The most advanced macro tracking app for people serious about their nutrition.",
  keywords: [
    "macro tracker",
    "macro tracking app",
    "AI food scanner",
    "calorie counter",
    "intermittent fasting tracker",
    "workout tracker",
    "nutrition app",
    "food photo analysis",
    "voice food logging",
    "fitness app",
    "protein tracker",
  ],
  authors: [{ name: "Macromaxxing" }],
  openGraph: {
    type: "website",
    locale: "en_US",
    siteName: "Macromaxxing",
    title: "Macromaxxing — AI-Powered Macro Tracker & Nutrition App",
    description:
      "Track macros with AI photo analysis, voice logging, and smart workout adjustments. Built different.",
  },
  twitter: {
    card: "summary_large_image",
    title: "Macromaxxing — AI-Powered Macro Tracker & Nutrition App",
    description:
      "Track macros with AI photo analysis, voice logging, and smart workout adjustments. Built different.",
  },
  robots: {
    index: true,
    follow: true,
    googleBot: { index: true, follow: true },
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en">
      <body className="font-sans antialiased">
        <CookieConsentProvider>
          <OrganizationJsonLd />
          <Header />
          <main>{children}</main>
          <Footer />
          <CookieBanner />
        </CookieConsentProvider>
      </body>
    </html>
  );
}
