import type { Metadata } from "next";
import "./globals.css";
import { Header } from "@/components/Header";
import { Footer } from "@/components/Footer";
import { OrganizationJsonLd } from "@/components/JsonLd";

export const metadata: Metadata = {
  title: {
    default: "Macro Maxxing — AI-Powered Macro Tracker & Nutrition App",
    template: "%s | Macro Maxxing",
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
  authors: [{ name: "Macro Maxxing" }],
  openGraph: {
    type: "website",
    locale: "en_US",
    siteName: "Macro Maxxing",
    title: "Macro Maxxing — AI-Powered Macro Tracker & Nutrition App",
    description:
      "Track macros with AI photo analysis, voice logging, and smart workout adjustments. Built different.",
  },
  twitter: {
    card: "summary_large_image",
    title: "Macro Maxxing — AI-Powered Macro Tracker & Nutrition App",
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
        <OrganizationJsonLd />
        <Header />
        <main>{children}</main>
        <Footer />
      </body>
    </html>
  );
}
