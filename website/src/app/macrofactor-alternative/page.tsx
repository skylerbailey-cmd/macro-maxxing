import { Metadata } from "next";
import { ArticleJsonLd } from "@/components/JsonLd";
import { ComparisonTable } from "@/components/ComparisonTable";
import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Best MacroFactor Alternative 2026 — Macro Maxxing vs MacroFactor",
  description:
    "Looking for a free MacroFactor alternative? Macro Maxxing offers AI photo scanning, voice logging, gamified streaks, leaderboards, and a social community — all free. No $12/month subscription.",
  keywords: [
    "MacroFactor alternative",
    "MacroFactor replacement",
    "free MacroFactor alternative",
    "better than MacroFactor",
    "apps like MacroFactor",
    "MacroFactor vs",
    "MacroFactor free alternative",
    "cheap macro tracker",
    "macro tracker no subscription",
    "MacroFactor too expensive",
  ],
};

export default function MacroFactorAlternativePage() {
  return (
    <>
      <ArticleJsonLd
        title="Best MacroFactor Alternative 2026 — Macro Maxxing"
        description="Macro Maxxing is the best free MacroFactor alternative with AI scanning and gamified accountability."
        url="https://macromaxxing.com/macrofactor-alternative"
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-gold/20 via-dark to-brand-teal/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-gold/20 text-brand-gold text-sm font-semibold mb-6">
              VS MACROFACTOR
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              Smart Macro Tracking,{" "}
              <span className="text-gradient-gold">Zero Cost</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-8">
              MacroFactor is a great app — but at $12/month, it&apos;s expensive.
              Macro Maxxing gives you AI-powered macro tracking, voice logging,
              streaks, leaderboards, and a social community for $0.
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-gold hover:bg-brand-gold/80 text-dark font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Track Macros Free
            </a>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            MacroFactor: Great App, Big Price Tag
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            MacroFactor, developed by Stronger By Science, is well-regarded for
            its algorithm-driven coaching and evidence-based approach. But
            several factors push users to look for alternatives:
          </p>
          <div className="space-y-4">
            {[
              {
                issue: "Expensive Subscription ($12/month)",
                desc: "At $144/year, MacroFactor is one of the most expensive macro trackers. There's no free tier — you can't use it without paying.",
              },
              {
                issue: "No AI Photo Scanning",
                desc: "Despite being a premium app, MacroFactor doesn't offer AI food photo scanning. Every meal requires manual entry via database search.",
              },
              {
                issue: "No Voice Logging",
                desc: "No voice input option. All logging is manual text-based searching, which is slower than AI alternatives.",
              },
              {
                issue: "No Social or Community Features",
                desc: "MacroFactor is entirely a solo experience. No social feed, no streaks visible to others, no community accountability.",
              },
              {
                issue: "No Gamification",
                desc: "No streaks, no XP, no leaderboards. It's a data-driven tool without any fun or motivational mechanics to keep you engaged.",
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
              Macro Maxxing vs MacroFactor
            </h2>
            <ComparisonTable
              features={[
                { name: "AI photo food scanning", macroMaxxing: true, others: false },
                { name: "Voice meal logging", macroMaxxing: true, others: false },
                { name: "Price", macroMaxxing: "Free", others: "$12/month" },
                { name: "Daily streaks", macroMaxxing: true, others: false },
                { name: "Leaderboards & XP", macroMaxxing: true, others: false },
                { name: "Social community feed", macroMaxxing: true, others: false },
                { name: "Workout macro adjustments", macroMaxxing: true, others: true },
                { name: "Algorithm-based coaching", macroMaxxing: false, others: true },
                { name: "Verified nutrition databases", macroMaxxing: "4 databases", others: "Nutritionix" },
                { name: "Intermittent fasting timer", macroMaxxing: true, others: false },
                { name: "Saved meal templates", macroMaxxing: true, others: true },
              ]}
            />
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-5xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
            Why Choose Macro Maxxing Over MacroFactor
          </h2>
          <div className="grid md:grid-cols-3 gap-6">
            <FeatureCard
              icon="💰"
              title="$0 vs $144/year"
              description="Macro Maxxing is completely free. No trial period, no subscription. Save $144/year and get features MacroFactor doesn't even offer."
              color="brand-gold"
            />
            <FeatureCard
              icon="📸"
              title="AI Food Scanning"
              description="Snap a photo instead of searching databases. 3-tier AI with 4 nutrition databases. MacroFactor has no photo scanning at all."
              color="brand-purple"
            />
            <FeatureCard
              icon="🎤"
              title="Voice Logging"
              description="Describe your meal in natural language. AI handles the rest. Perfect for post-workout logging when you're exhausted."
              color="brand-teal"
            />
            <FeatureCard
              icon="🔥"
              title="Gamified Accountability"
              description="Streaks, Aura XP, and leaderboards make tracking a game. MacroFactor is data-only — great for analysis, but boring for daily use."
              color="brand-orange"
            />
            <FeatureCard
              icon="👥"
              title="Social Community"
              description="Follow friends, share meals, compete on leaderboards. MacroFactor is a solo experience with no social features."
              color="brand-green"
            />
            <FeatureCard
              icon="⏱️"
              title="Fasting Timer"
              description="Built-in intermittent fasting tracker. MacroFactor doesn't offer fasting tracking."
              color="brand-cyan"
            />
          </div>
        </section>

        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-4xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold mb-6">
              When MacroFactor Might Be Better
            </h2>
            <p className="text-gray-300 text-lg mb-6">
              To be fair, MacroFactor has one standout feature: its
              algorithm-driven coaching system that adjusts your calorie targets
              based on your actual weight trends. If you want a fully automated
              coach that adjusts your targets week-by-week based on scale data,
              MacroFactor excels at this.
            </p>
            <p className="text-gray-300 text-lg">
              However, if you prefer AI-powered food logging, gamified
              accountability, social community features, and not paying
              $12/month — Macro Maxxing is the clear choice.
            </p>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-8">
            Frequently Asked Questions
          </h2>
          <div className="space-y-6">
            {[
              {
                q: "What is the best free alternative to MacroFactor?",
                a: "Macro Maxxing is the best free alternative to MacroFactor. It offers AI photo scanning and voice logging (which MacroFactor lacks), gamified streaks and leaderboards, and a social community — all for free. MacroFactor costs $12/month with no free tier.",
              },
              {
                q: "Is Macro Maxxing as accurate as MacroFactor?",
                a: "Both apps use verified nutrition databases. Macro Maxxing cross-references 4 databases including USDA FoodData Central. The main difference is input method — Macro Maxxing uses AI scanning and voice, while MacroFactor uses manual database searching.",
              },
              {
                q: "Does Macro Maxxing have algorithm-based coaching like MacroFactor?",
                a: "Macro Maxxing focuses on AI-powered food logging and gamified accountability rather than algorithm-based calorie coaching. If auto-adjusting calorie targets based on weight trends is your top priority, MacroFactor's algorithm is unique. For everything else, Macro Maxxing offers more features at no cost.",
              },
              {
                q: "Why switch from MacroFactor to Macro Maxxing?",
                a: "Save $144/year, get AI photo scanning and voice logging (faster than manual entry), enjoy gamified streaks and leaderboards for motivation, and join a social community for accountability. The only feature you'd lose is MacroFactor's auto-adjusting calorie algorithm.",
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
        </section>

        <div id="download">
          <DownloadCTA
            headline="Save $144/Year"
            subheadline="Everything MacroFactor offers (plus AI scanning, voice, streaks, and community) — completely free."
          />
        </div>
      </article>
    </>
  );
}
