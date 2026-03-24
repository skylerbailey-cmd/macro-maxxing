import { Metadata } from "next";
import { ArticleJsonLd, FAQPageJsonLd, BreadcrumbJsonLd } from "@/components/JsonLd";
import { ComparisonTable } from "@/components/ComparisonTable";
import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Best Noom Alternative 2026 — Macro Maxxing vs Noom",
  description:
    "Looking for a free Noom alternative? Macro Maxxing provides AI macro tracking, gamified streaks, leaderboards, and social accountability — without the $60/month price tag. Track macros, not colors.",
  keywords: [
    "Noom alternative",
    "Noom replacement",
    "free Noom alternative",
    "better than Noom",
    "apps like Noom",
    "Noom vs",
    "cheaper than Noom",
    "Noom too expensive",
    "weight loss app without subscription",
    "Noom free alternative",
  ],
};

const faqs = [
  {
    question: "What is the best free alternative to Noom?",
    answer: "Macro Maxxing is the best free alternative to Noom. It offers AI-powered macro tracking (not just color-coded foods), gamified streaks and leaderboards, and a social community for accountability — all completely free. Noom costs $40-60/month.",
  },
  {
    question: "Is Macro Maxxing better than Noom for weight loss?",
    answer: "For most people, yes. Macro Maxxing provides precise calorie and macro tracking (which drives weight loss results) with AI scanning and gamified accountability. Noom's color system oversimplifies nutrition, and its coaching is largely automated. Macro Maxxing gives you better tracking tools and community accountability for free.",
  },
  {
    question: "Does Macro Maxxing have coaching like Noom?",
    answer: "Macro Maxxing takes a different approach. Instead of scripted coaching, it uses gamified accountability (streaks, XP, leaderboards) and a real social community where users share meals and hold each other accountable. Research shows that social accountability is more effective than generic coaching for long-term habit change.",
  },
  {
    question: "Why is Macro Maxxing free when Noom costs $60/month?",
    answer: "Macro Maxxing is designed to be accessible to everyone. It doesn't have paid coaching staff or lengthy psychology curriculums to fund. Instead, it uses AI for food logging and builds accountability through streaks, leaderboards, and community — all of which can be delivered at no cost to users.",
  },
];

export default function NoomAlternativePage() {
  return (
    <>
      <ArticleJsonLd
        title="Best Noom Alternative 2026 — Macro Maxxing"
        description="Macro Maxxing is the best free Noom alternative with AI macro tracking, gamified accountability, and social community."
        url="https://macromaxxing.app/noom-alternative"
      />
      <FAQPageJsonLd faqs={faqs} />
      <BreadcrumbJsonLd
        items={[
          { name: "Home", url: "https://macromaxxing.app" },
          { name: "Noom Alternative", url: "https://macromaxxing.app/noom-alternative" },
        ]}
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-green/20 via-dark to-brand-gold/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-green/20 text-brand-green text-sm font-semibold mb-6">
              VS NOOM
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              Real Macro Tracking, Not{" "}
              <span className="text-gradient">Color Coding</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-4">
              Macro Maxxing is a free Noom alternative that provides precise
              AI-powered macro tracking instead of Noom's simplified color-coded
              food system. It includes photo scanning, voice logging, daily
              streaks, leaderboards, and a social community — at $0 versus
              Noom's $40-60/month subscription.
            </p>
            <p className="text-gray-500 text-sm mb-8">Last updated: March 2026</p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-green hover:bg-brand-green/80 text-dark font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Track Real Macros — Free
            </a>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Why People Are Looking Beyond Noom
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            Noom markets itself as a psychology-based weight loss program. While
            the behavioral approach has merit, many users are frustrated by
            several key issues:
          </p>
          <div className="space-y-4">
            {[
              {
                issue: "Extremely Expensive ($40-$60/month)",
                desc: "Noom is one of the most expensive nutrition apps. Plans range from $40-$60/month depending on the subscription length. That's $480-$720/year for a food tracker with coaching.",
              },
              {
                issue: "Simplified Color System, Not Real Macros",
                desc: "Noom categorizes foods as green, yellow, or red instead of showing detailed macro breakdowns. For anyone tracking protein, carbs, and fat, this is insufficient.",
              },
              {
                issue: "Generic Coaching",
                desc: "The 'personal coaching' is largely automated responses. Many users report that coaches use scripted replies and don't provide personalized nutrition guidance.",
              },
              {
                issue: "No AI Food Scanning",
                desc: "Despite the premium price, Noom doesn't offer AI photo scanning or voice logging. All food logging is manual.",
              },
              {
                issue: "Focused on Weight Loss Only",
                desc: "Noom is designed for weight loss. If your goal is muscle building, body recomp, or general macro tracking, Noom isn't built for you.",
              },
            ].map((item) => (
              <div
                key={item.issue}
                className="bg-white/5 border border-white/10 rounded-2xl p-5"
              >
                <h3 className="font-bold text-white mb-1">{item.issue}</h3>
                <p className="text-gray-400 text-sm">{item.desc}</p>
              </div>
            ))}
          </div>
        </section>

        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-4xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold text-center mb-8">
              Macro Maxxing vs Noom
            </h2>
            <ComparisonTable
              features={[
                { name: "Price", macroMaxxing: "Free", others: "$40-60/month" },
                { name: "AI photo food scanning", macroMaxxing: true, others: false },
                { name: "Voice meal logging", macroMaxxing: true, others: false },
                { name: "Full macro tracking (P/C/F)", macroMaxxing: true, others: "Color system only" },
                { name: "Daily streaks", macroMaxxing: true, others: false },
                { name: "Leaderboards & XP", macroMaxxing: true, others: false },
                { name: "Social community feed", macroMaxxing: true, others: "Coaching groups" },
                { name: "Workout macro adjustments", macroMaxxing: true, others: false },
                { name: "Works for all goals", macroMaxxing: true, others: "Weight loss only" },
                { name: "Psychology lessons", macroMaxxing: false, others: true },
              ]}
            />
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-5xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
            What Macro Maxxing Offers Instead
          </h2>
          <div className="grid md:grid-cols-3 gap-6">
            <FeatureCard
              icon="🎯"
              title="Real Macros, Not Colors"
              description="Track actual protein, carbs, fat, and calories — the numbers that matter for body composition. Not a simplified red/yellow/green color system."
              color="brand-green"
            />
            <FeatureCard
              icon="📸"
              title="AI Does the Work"
              description="Snap a photo or describe your meal by voice. AI calculates macros instantly. No manual searching through databases."
              color="brand-purple"
            />
            <FeatureCard
              icon="💰"
              title="$0 vs $720/year"
              description="Save up to $720/year. Every feature in Macro Maxxing is free — AI scanning, streaks, leaderboards, community. No subscription ever."
              color="brand-gold"
            />
            <FeatureCard
              icon="🔥"
              title="Gamified Motivation"
              description="Noom uses psychology lessons. Macro Maxxing uses psychology through game mechanics — streaks, XP, and leaderboards that actually change behavior."
              color="brand-orange"
            />
            <FeatureCard
              icon="👥"
              title="Real Community"
              description="A social feed where real users share meals and celebrate streaks. Not scripted coaching groups — authentic peer accountability."
              color="brand-teal"
            />
            <FeatureCard
              icon="💪"
              title="For Any Goal"
              description="Weight loss, muscle gain, body recomp, or maintenance. Macro Maxxing works for any fitness goal, not just weight loss."
              color="brand-cyan"
            />
          </div>
        </section>

        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-4xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold mb-8">
              Frequently Asked Questions
            </h2>
            <div className="space-y-6">
              {faqs.map((faq) => (
                <div
                  key={faq.question}
                  className="bg-white/5 border border-white/10 rounded-2xl p-6"
                >
                  <h3 className="text-lg font-bold text-white mb-2">
                    {faq.question}
                  </h3>
                  <p className="text-gray-300">{faq.answer}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        <div id="download">
          <DownloadCTA
            headline="Stop Paying $60/Month"
            subheadline="Better tracking, real macros, gamified accountability, and social community. All free, forever."
          />
        </div>
      </article>
    </>
  );
}
