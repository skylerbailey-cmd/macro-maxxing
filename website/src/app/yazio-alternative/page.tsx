import { Metadata } from "next";
import { ArticleJsonLd } from "@/components/JsonLd";
import ComparisonTable from "@/components/ComparisonTable";
import FeatureCard from "@/components/FeatureCard";
import DownloadCTA from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Best YAZIO Alternative 2026 — Macro Maxxing vs YAZIO",
  description:
    "Looking for a free YAZIO alternative without aggressive upsells? Macro Maxxing offers AI photo scanning, voice logging, accurate macros, streaks, leaderboards, and community — 100% free with no ads.",
  keywords: [
    "YAZIO alternative",
    "YAZIO replacement",
    "free YAZIO alternative",
    "better than YAZIO",
    "apps like YAZIO",
    "YAZIO vs",
    "YAZIO free alternative",
    "YAZIO without subscription",
    "calorie tracker no ads",
    "fasting app alternative",
  ],
};

export default function YazioAlternativePage() {
  return (
    <>
      <ArticleJsonLd
        title="Best YAZIO Alternative 2026 — Macro Maxxing"
        description="Macro Maxxing is the best free YAZIO alternative with accurate AI scanning, no upsells, and gamified accountability."
        url="https://macromaxxing.com/yazio-alternative"
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-mint/20 via-dark to-brand-gold/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-mint/20 text-brand-mint text-sm font-semibold mb-6">
              VS YAZIO
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              Accurate AI Tracking,{" "}
              <span className="text-gradient">Zero Upsells</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-8">
              YAZIO bombards you with pop-ups, upsells, and inaccurate food
              data. Macro Maxxing gives you precise AI macro tracking, real
              gamification, and a social community — completely free with no
              annoying prompts.
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-mint hover:bg-brand-mint/80 text-dark font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Switch to Macro Maxxing — Free
            </a>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Why Users Are Frustrated with YAZIO
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            YAZIO has a large user base, especially in Europe, but recent
            reviews reveal growing frustration:
          </p>
          <div className="space-y-4">
            {[
              {
                issue: "Aggressive Upselling",
                desc: "The free version is barely functional. Users describe constant subscription prompts, 3-4 pop-ups after every logged meal, and 'Duolingo-level streak baiting' pushing you to pay.",
              },
              {
                issue: "Inaccurate Food Database",
                desc: "Scanned items frequently show wildly wrong calorie counts. Users report foods being off by 50-100+ calories — a dealbreaker for accurate tracking.",
              },
              {
                issue: "AI That Doesn't Learn",
                desc: "YAZIO's AI features don't learn from your habits. It guesses wrong on repeated entries (e.g., always selecting the wrong type of milk) despite logging the same items daily.",
              },
              {
                issue: "Inflexible Fasting Timer",
                desc: "Despite advertising customizable fasting, users report that schedules can't actually be modified for non-standard protocols.",
              },
              {
                issue: "Subscription Cancellation Issues",
                desc: "Multiple user reports of charges continuing after cancellation. Difficult to get refunds or reach customer support.",
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
              Macro Maxxing vs YAZIO
            </h2>
            <ComparisonTable
              features={[
                { name: "3-tier AI photo scanning", macroMaxxing: true, others: "Basic AI" },
                { name: "Voice meal logging", macroMaxxing: true, others: false },
                { name: "100% free (no upsells)", macroMaxxing: true, others: "Aggressive freemium" },
                { name: "No ads or pop-ups", macroMaxxing: true, others: false },
                { name: "Accurate nutrition data", macroMaxxing: "4 verified databases", others: "User-reported issues" },
                { name: "Daily streaks", macroMaxxing: true, others: "Streak baiting for Pro" },
                { name: "Leaderboards & XP", macroMaxxing: true, others: false },
                { name: "Social community feed", macroMaxxing: true, others: false },
                { name: "Workout macro adjustments", macroMaxxing: true, others: false },
                { name: "Customizable fasting timer", macroMaxxing: true, others: "Limited" },
              ]}
            />
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-5xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
            What Macro Maxxing Does Better
          </h2>
          <div className="grid md:grid-cols-3 gap-6">
            <FeatureCard
              icon="🎯"
              title="Accurate AI"
              description="3-tier AI system cross-referencing 4 verified databases including USDA. No wildly wrong calorie counts — just accurate macros."
              color="brand-mint"
            />
            <FeatureCard
              icon="🚫"
              title="Zero Pop-Ups"
              description="No upsells, no subscription prompts, no animations after every meal. Just clean, fast tracking. Every feature is free."
              color="brand-purple"
            />
            <FeatureCard
              icon="🔥"
              title="Real Gamification"
              description="Streaks that reward consistency without manipulating you into paying. Aura XP and leaderboards make tracking genuinely fun."
              color="brand-gold"
            />
            <FeatureCard
              icon="🎤"
              title="Voice Logging"
              description="Say what you ate and AI calculates macros. YAZIO has no voice input at all."
              color="brand-teal"
            />
            <FeatureCard
              icon="⏱️"
              title="Flexible Fasting"
              description="Fully customizable fasting timer supporting 16:8, 18:6, 20:4, OMAD, and custom windows. Actually works the way you want it to."
              color="brand-orange"
            />
            <FeatureCard
              icon="👥"
              title="Community"
              description="Social feed for sharing meals and holding each other accountable. YAZIO is a solo experience."
              color="brand-green"
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
                  q: "What is the best free alternative to YAZIO?",
                  a: "Macro Maxxing is the best free alternative to YAZIO. It offers accurate 3-tier AI photo scanning, voice meal logging, customizable fasting timers, gamified streaks, leaderboards, and a social community — all 100% free with no pop-ups, ads, or subscription upsells.",
                },
                {
                  q: "Is Macro Maxxing more accurate than YAZIO?",
                  a: "Yes. Macro Maxxing uses a 3-tier AI system that cross-references 4 verified nutrition databases including USDA FoodData Central. YAZIO users frequently report inaccurate food entries with wildly wrong calorie counts. Accuracy is a core priority for Macro Maxxing.",
                },
                {
                  q: "Does Macro Maxxing have a fasting timer like YAZIO?",
                  a: "Yes. Macro Maxxing includes a fully customizable intermittent fasting timer supporting 16:8, 18:6, 20:4, OMAD, and any custom window. Unlike YAZIO's fasting feature which users report as inflexible, Macro Maxxing lets you set any schedule you want — for free.",
                },
                {
                  q: "Is Macro Maxxing really free with no upsells?",
                  a: "Yes. Every feature in Macro Maxxing is free — AI scanning, voice logging, fasting timer, streaks, leaderboards, and social community. There is no premium tier, no ads, and no pop-ups asking you to subscribe. It's the anti-YAZIO experience.",
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
            headline="Tracking Without the Annoyance"
            subheadline="Accurate AI scanning, real gamification, and zero pop-ups. The YAZIO experience you actually wanted. Free."
          />
        </div>
      </article>
    </>
  );
}
