import { Metadata } from "next";
import { ArticleJsonLd } from "@/components/JsonLd";
import { ComparisonTable } from "@/components/ComparisonTable";
import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Best Lifesum Alternative 2026 — Macro Maxxing vs Lifesum",
  description:
    "Looking for a Lifesum alternative with AI features and no paywall? Macro Maxxing offers AI photo scanning, voice logging, gamified streaks, leaderboards, and a social community — all free.",
  keywords: [
    "Lifesum alternative",
    "Lifesum replacement",
    "free Lifesum alternative",
    "better than Lifesum",
    "apps like Lifesum",
    "Lifesum vs",
    "Lifesum free alternative",
    "nutrition app like Lifesum",
    "Lifesum without subscription",
    "diet app alternative",
  ],
};

export default function LifesumAlternativePage() {
  return (
    <>
      <ArticleJsonLd
        title="Best Lifesum Alternative 2026 — Macro Maxxing"
        description="Macro Maxxing is the best free Lifesum alternative with AI features and gamified accountability."
        url="https://macromaxxing.com/lifesum-alternative"
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-cyan/20 via-dark to-brand-purple/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-cyan/20 text-brand-cyan text-sm font-semibold mb-6">
              VS LIFESUM
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              Beautiful Design +{" "}
              <span className="text-gradient">AI Power</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-8">
              Lifesum looks great but locks key features behind a paywall. Macro
              Maxxing matches the polish and adds AI photo scanning, voice
              logging, streaks, and a social community — all free.
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-cyan hover:bg-brand-cyan/80 text-dark font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Switch to Macro Maxxing — Free
            </a>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Why Users Switch from Lifesum
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            Lifesum is known for its attractive design and variety of diet
            plans. But several pain points drive users to look elsewhere:
          </p>
          <div className="space-y-4">
            {[
              {
                issue: "Aggressive Paywall ($50-$70/year)",
                desc: "Most useful features — macro tracking, meal plans, detailed nutrition — require Lifesum Premium. The free tier is extremely limited.",
              },
              {
                issue: "No AI Features",
                desc: "No photo food scanning, no voice logging. All meals are logged via manual search or barcode scanning. Feels outdated compared to AI-powered alternatives.",
              },
              {
                issue: "Limited Free Tier",
                desc: "Free users can only track calories with basic macro info. Custom macro goals, detailed breakdowns, and meal plans all require Premium.",
              },
              {
                issue: "No Gamification",
                desc: "No streaks, no leaderboards, no XP system. Tracking is functional but lacks any motivational mechanics to keep you engaged.",
              },
              {
                issue: "No Social Community",
                desc: "Lifesum is a solo experience. No social feed, no friend system, no community accountability features.",
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
              Macro Maxxing vs Lifesum
            </h2>
            <ComparisonTable
              features={[
                { name: "AI photo food scanning", macroMaxxing: true, others: false },
                { name: "Voice meal logging", macroMaxxing: true, others: false },
                { name: "100% free", macroMaxxing: true, others: "Freemium ($50-70/yr)" },
                { name: "Full macro tracking", macroMaxxing: true, others: "Premium only" },
                { name: "Daily streaks", macroMaxxing: true, others: false },
                { name: "Leaderboards & XP", macroMaxxing: true, others: false },
                { name: "Social community feed", macroMaxxing: true, others: false },
                { name: "Workout macro adjustments", macroMaxxing: true, others: false },
                { name: "Diet plan variety", macroMaxxing: "Custom macro targets", others: "Multiple plans (Premium)" },
                { name: "Intermittent fasting timer", macroMaxxing: true, others: "Premium only" },
              ]}
            />
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-5xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
            The Macro Maxxing Advantage
          </h2>
          <div className="grid md:grid-cols-3 gap-6">
            <FeatureCard
              icon="📸"
              title="AI-First Logging"
              description="Photo scanning and voice input replace manual database searching. Log any meal in seconds — homemade, restaurant, or packaged."
              color="brand-cyan"
            />
            <FeatureCard
              icon="🔥"
              title="Gamified Tracking"
              description="Daily streaks, Aura XP, and leaderboards make nutrition tracking feel like a game. You'll actually want to log every meal."
              color="brand-gold"
            />
            <FeatureCard
              icon="👥"
              title="Community Built In"
              description="Social feed for meal sharing, friend following, and streak celebrations. Real accountability from real people on the same journey."
              color="brand-green"
            />
            <FeatureCard
              icon="💰"
              title="Everything Free"
              description="No premium tier, no upsells. AI scanning, macros, streaks, community — all included. Lifesum charges $50-70/year for these basics."
              color="brand-purple"
            />
            <FeatureCard
              icon="🏋️"
              title="Training-Aware"
              description="Macros adjust automatically when you log workouts. Lifesum doesn't connect your training to your nutrition targets."
              color="brand-teal"
            />
            <FeatureCard
              icon="⏱️"
              title="Free Fasting Timer"
              description="Built-in intermittent fasting tracker included free. Lifesum charges for fasting features in their Premium plan."
              color="brand-orange"
            />
          </div>
        </section>

        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-4xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold mb-8">
              Frequently Asked Questions
            </h2>
            <div className="space-y-6">
              {[
                {
                  q: "What is the best free alternative to Lifesum?",
                  a: "Macro Maxxing is the best free alternative to Lifesum. It offers AI photo scanning, voice logging, full macro tracking, gamified streaks, leaderboards, and a social community — all completely free. Lifesum charges $50-70/year for Premium features.",
                },
                {
                  q: "Is Macro Maxxing better than Lifesum?",
                  a: "For anyone serious about their macros, yes. Macro Maxxing offers AI-powered food scanning and voice logging (which Lifesum doesn't have), gamified accountability with streaks and leaderboards, and a social community for motivation — all free. Lifesum has more diet plan variety but locks most features behind a paywall.",
                },
                {
                  q: "Does Macro Maxxing have diet plans like Lifesum?",
                  a: "Macro Maxxing uses a flexible approach: set your own macro targets based on your goals (weight loss, muscle gain, recomp, maintenance) and track against them with AI. Instead of rigid diet plans, you have full control over your nutrition targets with AI handling the logging work.",
                },
                {
                  q: "Can I track intermittent fasting for free with Macro Maxxing?",
                  a: "Yes. Macro Maxxing includes a free built-in intermittent fasting timer with support for all common protocols (16:8, 18:6, 20:4, OMAD, custom). Lifesum charges for fasting features in their Premium plan.",
                },
              ].map((faq) => (
                <div
                  key={faq.q}
                  className="bg-white/5 border border-white/10 rounded-2xl p-6"
                >
                  <h3 className="text-lg font-bold text-white mb-2">
                    {faq.q}
                  </h3>
                  <p className="text-gray-300">{faq.a}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        <div id="download">
          <DownloadCTA
            headline="Beautiful + Powerful + Free"
            subheadline="AI scanning, full macros, streaks, leaderboards, and community. Everything Lifesum Premium offers — at no cost."
          />
        </div>
      </article>
    </>
  );
}
