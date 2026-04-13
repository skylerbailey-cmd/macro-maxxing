import type { Metadata } from "next";
import Link from "next/link";
import { BreadcrumbJsonLd } from "@/components/JsonLd";

export const metadata: Metadata = {
  title: "Help & Guides — Learn How to Use Macromaxxing",
  description:
    "Step-by-step guides and tutorials for getting the most out of Macromaxxing. Learn how to make posts, log meals, track workouts, and more.",
  keywords: [
    "macromaxxing help",
    "macromaxxing tutorial",
    "how to use macromaxxing",
    "macro tracking guide",
    "fitness app help",
  ],
};

const guides = [
  {
    href: "/help/how-to-make-a-post",
    title: "How to Make a Post",
    description:
      "Learn how to create posts, choose labels, share your fuel log, and show off your goal progress on the feed.",
    tag: "COMMUNITY",
    tagColor: "text-brand-purple",
  },
  {
    href: "/help/how-to-log-a-workout",
    title: "How to Log a Workout",
    description:
      "Log workouts manually or with your voice using AI. Get automatic macro goal adjustments and earn aura points.",
    tag: "WORKOUT TRACKING",
    tagColor: "text-brand-teal",
  },
  {
    href: "/help/how-to-log-a-meal",
    title: "How to Log a Meal",
    description:
      "Log meals with AI photo scanning, voice, or manual entry. Get instant macro breakdowns, meal scores, and portion size adjustments.",
    tag: "FOOD LOGGING",
    tagColor: "text-brand-orange",
  },
  {
    href: "/help/how-to-find-people",
    title: "How to Find People",
    description:
      "Search for users by name or username, follow their progress, and build your fitness community.",
    tag: "COMMUNITY",
    tagColor: "text-brand-green",
  },
  {
    href: "/help/settings",
    title: "Settings & Account",
    description:
      "Configure your profile, nutrition goals, privacy, fasting tracker, notifications, and manage your data.",
    tag: "ACCOUNT",
    tagColor: "text-brand-cyan",
  },
  {
    href: "/help/how-to-delete-account",
    title: "How to Delete Your Account",
    description:
      "Permanently delete your account and all associated data. Covers what gets deleted, data export, subscription cancellation, and regulatory compliance (GDPR, CCPA, and more).",
    tag: "PRIVACY & DATA",
    tagColor: "text-red-400",
  },
];

export default function HelpPage() {
  return (
    <>
      <BreadcrumbJsonLd
        items={[
          { name: "Home", url: "https://macromaxxing.app" },
          { name: "Help", url: "https://macromaxxing.app/help" },
        ]}
      />

      <section className="pt-32 pb-20 px-4 sm:px-6">
        <div className="max-w-3xl mx-auto">
          <div className="bg-brand-teal/10 text-brand-teal text-xs font-semibold px-3 py-1 rounded-full inline-block mb-4">
            HELP CENTER
          </div>
          <h1 className="text-3xl sm:text-5xl font-black mb-6 leading-tight">
            Help &amp; Guides
          </h1>
          <p className="text-gray-300 text-lg leading-relaxed mb-12">
            Everything you need to get the most out of Macromaxxing. Browse our
            step-by-step guides below.
          </p>

          <div className="space-y-4">
            {guides.map((guide) => (
              <Link
                key={guide.href}
                href={guide.href}
                className="block bg-brand-card rounded-xl p-6 border border-white/5 hover:border-brand-purple/30 transition group"
              >
                <p className={`text-xs font-semibold mb-1 ${guide.tagColor}`}>
                  {guide.tag}
                </p>
                <h2 className="text-lg font-bold text-white group-hover:text-brand-purple transition mb-2">
                  {guide.title}
                </h2>
                <p className="text-gray-400 text-sm">{guide.description}</p>
              </Link>
            ))}
          </div>
        </div>
      </section>
    </>
  );
}
