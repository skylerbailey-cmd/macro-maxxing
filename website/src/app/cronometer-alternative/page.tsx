import { Metadata } from "next";
import { ArticleJsonLd, FAQPageJsonLd, BreadcrumbJsonLd } from "@/components/JsonLd";
import { ComparisonTable } from "@/components/ComparisonTable";
import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Best Cronometer Alternative 2026 — Macro Maxxing vs Cronometer",
  description:
    "Looking for a Cronometer alternative? Macro Maxxing offers AI photo scanning, voice logging, gamified streaks, and a social community — all free. No complex UI, no subscription required.",
  keywords: [
    "Cronometer alternative",
    "Cronometer replacement",
    "better than Cronometer",
    "apps like Cronometer",
    "Cronometer vs",
    "free Cronometer alternative",
    "simpler than Cronometer",
    "macro tracker like Cronometer",
    "Cronometer free alternative",
    "nutrition tracker alternative",
  ],
};

const faqs = [
  {
    question: "What is the best alternative to Cronometer?",
    answer: "Macro Maxxing is the best free alternative to Cronometer for macro tracking. It uses AI photo scanning and voice logging instead of manual entry, includes gamification (streaks, leaderboards, XP) for accountability, and has a social community — all at no cost.",
  },
  {
    question: "Is Macro Maxxing as accurate as Cronometer?",
    answer: "Macro Maxxing uses Claude AI cross-referenced with USDA FoodData Central for verified nutrition data. While Cronometer excels at micronutrient detail, Macro Maxxing provides highly accurate macro tracking for calories, protein, carbs, and fat.",
  },
  {
    question: "Does Macro Maxxing track micronutrients like Cronometer?",
    answer: "Macro Maxxing is focused on macronutrient tracking — calories, protein, carbs, and fat. If you need detailed micronutrient analysis (vitamins, minerals), Cronometer may be more suitable. But for most people focused on macros and body composition, Macro Maxxing is faster and easier to use.",
  },
  {
    question: "Is Macro Maxxing free?",
    answer: "Yes. Macro Maxxing is 100% free with no premium tier or subscription. All features including AI scanning, voice logging, streaks, leaderboards, and the social community are completely free. Cronometer charges $50/year for Gold features.",
  },
];

export default function CronometerAlternativePage() {
  return (
    <>
      <ArticleJsonLd
        title="Best Cronometer Alternative 2026 — Macro Maxxing"
        description="Macro Maxxing is the best free Cronometer alternative with AI scanning and simpler tracking."
        url="https://macromaxxing.app/cronometer-alternative"
      />
      <FAQPageJsonLd faqs={faqs} />
      <BreadcrumbJsonLd
        items={[
          { name: "Home", url: "https://macromaxxing.app" },
          { name: "Cronometer Alternative", url: "https://macromaxxing.app/cronometer-alternative" },
        ]}
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-teal/20 via-dark to-brand-purple/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-teal/20 text-brand-teal text-sm font-semibold mb-6">
              VS CRONOMETER
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              All the Accuracy,{" "}
              <span className="text-gradient">None of the Complexity</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-4">
              Macro Maxxing is a free Cronometer alternative that provides
              accurate macro tracking with AI photo scanning and voice logging,
              without Cronometer's complex interface or $50/year Gold
              subscription. It adds gamified streaks, leaderboards, and a
              social community for accountability.
            </p>
            <p className="text-gray-500 text-sm mb-8">Last updated: March 2026</p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-teal hover:bg-brand-teal/80 text-dark font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Try Macro Maxxing — Free
            </a>
          </div>
        </section>

        {/* TL;DR */}
        <section className="max-w-4xl mx-auto px-4 py-8 border-b border-white/5">
          <div className="bg-brand-teal/5 border border-brand-teal/20 rounded-2xl p-6">
            <h2 className="text-sm font-semibold text-brand-teal uppercase tracking-wider mb-3">TL;DR</h2>
            <p className="text-gray-300 text-lg leading-relaxed">
              <strong className="text-white">Macro Maxxing is the best free Cronometer alternative for users who want accurate macro tracking without the complexity.</strong>{" "}
              It replaces manual entry with AI photo scanning and voice logging, adds gamified streaks and a social community, and costs $0 versus Cronometer Gold at $50/year. The trade-off: Cronometer has detailed micronutrient tracking that Macro Maxxing doesn&apos;t offer — if you need vitamin and mineral data, Cronometer is still the better choice.
            </p>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Why People Look for Cronometer Alternatives
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            Cronometer is respected for its accurate, science-backed nutrition
            data and detailed micronutrient tracking. But many users find it
            difficult to use daily:
          </p>
          <div className="space-y-4">
            {[
              {
                issue: "Complex, Cluttered Interface",
                desc: "Cronometer shows so much data that the interface feels overwhelming. For users who just want to track macros and protein, it's overkill.",
              },
              {
                issue: "Slow Manual Entry",
                desc: "Every meal requires searching and manually selecting items from the database. No photo scanning, no voice input. This makes logging time-consuming.",
              },
              {
                issue: "Premium Paywall ($50/year)",
                desc: "Key features like custom macro targets, meal planning, and no ads require Cronometer Gold at $50/year or $8/month.",
              },
              {
                issue: "No Gamification or Social Features",
                desc: "Cronometer is purely a data tool. No streaks, no leaderboards, no community. There's nothing to keep you motivated beyond the numbers.",
              },
              {
                issue: "Steep Learning Curve",
                desc: "New users often feel lost navigating the detailed views, charts, and micronutrient panels. It's built for nutrition nerds, not everyday people.",
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
              Macro Maxxing vs Cronometer
            </h2>
            <ComparisonTable
              features={[
                { name: "AI photo food scanning", macroMaxxing: true, others: false },
                { name: "Voice meal logging", macroMaxxing: true, others: false },
                { name: "Simple, focused interface", macroMaxxing: true, others: false },
                { name: "100% free", macroMaxxing: true, others: "Freemium ($50/yr)" },
                { name: "Daily streaks", macroMaxxing: true, others: false },
                { name: "Leaderboards & XP", macroMaxxing: true, others: false },
                { name: "Social community feed", macroMaxxing: true, others: false },
                { name: "Workout macro adjustments", macroMaxxing: true, others: false },
                { name: "Detailed micronutrients", macroMaxxing: "Macro-focused", others: true },
                { name: "Verified nutrition data", macroMaxxing: true, others: true },
              ]}
            />
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-5xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
            What Makes Macro Maxxing Better for Daily Use
          </h2>
          <div className="grid md:grid-cols-3 gap-6">
            <FeatureCard
              icon="⚡"
              title="Log in Seconds"
              description="Photo scan or voice input instead of manual database searching. Most meals are logged in under 10 seconds."
              color="brand-teal"
            />
            <FeatureCard
              icon="🎯"
              title="Macro-Focused"
              description="See calories, protein, carbs, and fat front and center. No micronutrient overload — just the numbers that matter most for your goals."
              color="brand-purple"
            />
            <FeatureCard
              icon="🔥"
              title="Gamified Consistency"
              description="Streaks, Aura XP, and leaderboards turn tracking into a game. Cronometer shows you data — Macro Maxxing keeps you coming back."
              color="brand-gold"
            />
            <FeatureCard
              icon="👥"
              title="Social Community"
              description="Share meals, follow friends, and compete on leaderboards. Cronometer is solo; Macro Maxxing is social."
              color="brand-green"
            />
            <FeatureCard
              icon="💰"
              title="Completely Free"
              description="No Gold subscription needed. Every feature including AI scanning, streaks, and community is free."
              color="brand-orange"
            />
            <FeatureCard
              icon="🏋️"
              title="Training-Aware"
              description="Log workouts and your macro targets adjust automatically. Cronometer doesn't account for training days."
              color="brand-cyan"
            />
          </div>
        </section>

        {/* Who should switch */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-8">
            Who Should Switch — and Who Shouldn&apos;t
          </h2>
          <div className="grid md:grid-cols-2 gap-6">
            <div className="bg-brand-green/5 border border-brand-green/20 rounded-2xl p-6">
              <h3 className="text-lg font-bold text-brand-green mb-4">Switch to Macro Maxxing if you:</h3>
              <ul className="space-y-2 text-gray-300 text-sm">
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Primarily track macros (calories, protein, carbs, fat)</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Find Cronometer&apos;s interface overwhelming or slow</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Want faster logging with AI photos and voice</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Want gamification and social features for motivation</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Don&apos;t want to pay for Gold features</li>
              </ul>
            </div>
            <div className="bg-white/5 border border-white/10 rounded-2xl p-6">
              <h3 className="text-lg font-bold text-gray-400 mb-4">Cronometer may still be better if you:</h3>
              <ul className="space-y-2 text-gray-400 text-sm">
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Need detailed micronutrient tracking (vitamins, minerals)</li>
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Follow a specific medical diet requiring micronutrient monitoring</li>
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Prefer data-dense interfaces with deep analytics</li>
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Need Android support (Macro Maxxing is iOS only)</li>
              </ul>
            </div>
          </div>
        </section>

        {/* How to switch */}
        <section className="py-12 max-w-4xl mx-auto px-4">
          <div className="bg-brand-card rounded-2xl border border-white/5 p-6 md:p-8">
            <h2 className="text-2xl font-bold mb-4">How to Switch from Cronometer</h2>
            <div className="grid md:grid-cols-3 gap-6">
              <div>
                <p className="text-brand-teal font-bold text-lg mb-1">1. Download</p>
                <p className="text-gray-400 text-sm">Get Macro Maxxing free from the App Store. No account migration needed.</p>
              </div>
              <div>
                <p className="text-brand-teal font-bold text-lg mb-1">2. Set Macro Targets</p>
                <p className="text-gray-400 text-sm">Transfer your calorie and macro goals. Focus on the numbers that drive results.</p>
              </div>
              <div>
                <p className="text-brand-teal font-bold text-lg mb-1">3. Log with AI</p>
                <p className="text-gray-400 text-sm">Snap photos instead of searching databases. Experience how fast tracking can be.</p>
              </div>
            </div>
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
            headline="Simpler, Faster, Free"
            subheadline="All the macro accuracy you need without the complexity. AI scanning, streaks, and community included."
          />
        </div>
      </article>
    </>
  );
}
