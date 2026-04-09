import type { Metadata } from "next";
import Link from "next/link";
import { BreadcrumbJsonLd } from "@/components/JsonLd";

export const metadata: Metadata = {
  title: "Help & Guides — Learn How to Use Macro Maxxing",
  description:
    "Step-by-step guides and tutorials for getting the most out of Macro Maxxing. Learn how to make posts, log meals, track workouts, and more.",
  keywords: [
    "macro maxxing help",
    "macro maxxing tutorial",
    "how to use macro maxxing",
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
            Everything you need to get the most out of Macro Maxxing. Browse our
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
