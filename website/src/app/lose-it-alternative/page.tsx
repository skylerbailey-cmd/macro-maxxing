import { Metadata } from "next";
import { ArticleJsonLd } from "@/components/JsonLd";
import { ComparisonTable } from "@/components/ComparisonTable";
import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Best Lose It! Alternative 2026 — Macro Maxxing vs Lose It",
  description:
    "Looking for a Lose It! alternative with better macro tracking? Macro Maxxing offers AI photo scanning, voice logging, detailed macros, streaks, leaderboards, and community — all free.",
  keywords: [
    "Lose It alternative",
    "Lose It app alternative",
    "better than Lose It",
    "apps like Lose It",
    "Lose It vs",
    "free Lose It alternative",
    "Lose It replacement",
    "macro tracker better than Lose It",
    "weight loss app alternative",
    "calorie counter alternative",
  ],
};

export default function LoseItAlternativePage() {
  return (
    <>
      <ArticleJsonLd
        title="Best Lose It! Alternative 2026 — Macro Maxxing"
        description="Macro Maxxing is the best free Lose It! alternative with AI scanning, detailed macros, and gamified accountability."
        url="https://macromaxxing.com/lose-it-alternative"
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-orange/20 via-dark to-brand-green/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-orange/20 text-brand-orange text-sm font-semibold mb-6">
              VS LOSE IT!
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              More Than Just{" "}
              <span className="text-gradient-gold">Counting Calories</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-8">
              Lose It! is a solid calorie counter, but if you care about macros,
              AI-powered tracking, and accountability — Macro Maxxing is the
              upgrade. Full macro tracking, AI scanning, streaks, and community.
              Free.
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-orange hover:bg-brand-orange/80 text-dark font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Upgrade Your Tracking — Free
            </a>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Where Lose It! Falls Short
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            Lose It! is popular for its clean design and simple calorie tracking.
            But for athletes and serious fitness enthusiasts, it lacks key
            features:
          </p>
          <div className="space-y-4">
            {[
              {
                issue: "Calorie-Centric, Not Macro-Centric",
                desc: "Lose It! focuses primarily on calories. Detailed macro breakdowns (protein, carbs, fat) are limited in the free version and not as prominently displayed.",
              },
              {
                issue: "Premium Paywall ($40/year)",
                desc: "Macro goals, meal planning, and advanced insights require Lose It! Premium. The free tier covers basic calorie counting only.",
              },
              {
                issue: "No AI Photo Scanning",
                desc: "Lose It! has a basic food recognition feature, but it's limited. No 3-tier AI system, no multi-database cross-referencing.",
              },
              {
                issue: "No Voice Logging",
                desc: "Every meal must be typed or scanned via barcode. No hands-free voice logging option.",
              },
              {
                issue: "No Gamification or Community",
                desc: "Lose It! has basic challenges but no daily streaks, no XP system, no leaderboards, and no social feed for accountability.",
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
              Macro Maxxing vs Lose It!
            </h2>
            <ComparisonTable
              features={[
                { name: "AI photo food scanning", macroMaxxing: true, others: "Basic" },
                { name: "Voice meal logging", macroMaxxing: true, others: false },
                { name: "Full macro tracking (P/C/F)", macroMaxxing: true, others: "Premium only" },
                { name: "100% free", macroMaxxing: true, others: "Freemium ($40/yr)" },
                { name: "Daily streaks", macroMaxxing: true, others: false },
                { name: "Leaderboards & XP", macroMaxxing: true, others: false },
                { name: "Social community feed", macroMaxxing: true, others: false },
                { name: "Workout macro adjustments", macroMaxxing: true, others: false },
                { name: "Intermittent fasting timer", macroMaxxing: true, others: false },
                { name: "Saved meal templates", macroMaxxing: true, others: "Premium only" },
              ]}
            />
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-5xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
            Why Athletes Choose Macro Maxxing Over Lose It!
          </h2>
          <div className="grid md:grid-cols-3 gap-6">
            <FeatureCard
              icon="🥩"
              title="Protein-First"
              description="Macro Maxxing displays protein prominently because it's the most important macro for body composition. Lose It! buries macros behind the calorie number."
              color="brand-orange"
            />
            <FeatureCard
              icon="📸"
              title="Real AI Scanning"
              description="A 3-tier AI system that identifies any food from a photo and cross-references 4 databases. Not basic image recognition — real nutritional analysis."
              color="brand-purple"
            />
            <FeatureCard
              icon="🔥"
              title="Streak Motivation"
              description="Daily streaks keep you tracking consistently. Combined with Aura XP and leaderboards, Macro Maxxing makes consistency a game."
              color="brand-gold"
            />
            <FeatureCard
              icon="🏋️"
              title="Training Integration"
              description="Log workouts and your macros adjust automatically. Lose It! treats every day the same regardless of activity."
              color="brand-teal"
            />
            <FeatureCard
              icon="👥"
              title="Real Community"
              description="A social feed with meal sharing, streak celebrations, and mutual accountability. Not just basic challenges."
              color="brand-green"
            />
            <FeatureCard
              icon="🗣️"
              title="Voice Logging"
              description="Describe your meal naturally and AI handles the rest. Perfect for logging meals when you're busy or post-workout."
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
              {[
                {
                  q: "What is the best alternative to Lose It?",
                  a: "Macro Maxxing is the best free alternative to Lose It! for athletes and fitness enthusiasts. It offers detailed macro tracking (not just calories), AI photo scanning, voice logging, daily streaks, leaderboards, and a social community — all completely free.",
                },
                {
                  q: "Is Macro Maxxing better than Lose It for weight loss?",
                  a: "Yes. While Lose It! focuses on calorie counting, Macro Maxxing tracks full macros (protein, carbs, fat) which leads to better body composition results. It also includes gamified streaks and social accountability that significantly improve consistency — the #1 factor in weight loss success.",
                },
                {
                  q: "Does Macro Maxxing track macros better than Lose It?",
                  a: "Yes. Macro Maxxing is built as a macro tracker first. Protein, carbs, and fat are displayed prominently alongside calories. AI photo scanning provides accurate macro breakdowns from 4 nutrition databases. In Lose It!, detailed macros require the Premium subscription.",
                },
                {
                  q: "Is Macro Maxxing completely free?",
                  a: "Yes. Every feature in Macro Maxxing is free — AI scanning, voice logging, macro tracking, streaks, leaderboards, and the social community. There is no premium tier. Lose It! charges $40/year for premium features.",
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
            headline="Go Beyond Calorie Counting"
            subheadline="Full macro tracking, AI scanning, voice logging, and gamified accountability. Free forever."
          />
        </div>
      </article>
    </>
  );
}
