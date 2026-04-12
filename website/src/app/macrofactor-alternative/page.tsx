import { Metadata } from "next";
import { ArticleJsonLd, FAQPageJsonLd, BreadcrumbJsonLd } from "@/components/JsonLd";
import { ComparisonTable } from "@/components/ComparisonTable";
import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Best MacroFactor Alternative 2026 — Macro Maxxing vs MacroFactor",
  description:
    "Looking for an MacroFactor alternative? Macro Maxxing offers AI photo scanning, voice logging, gamified streaks, leaderboards, and a social community — core features free, AI Pro at $9.99/mo — less than MacroFactor's $12/month with more features.",
  keywords: [
    "MacroFactor alternative",
    "MacroFactor replacement",
    "free MacroFactor alternative",
    "better than MacroFactor",
    "apps like MacroFactor",
    "MacroFactor vs",
    "MacroFactor alternative",
    "cheap macro tracker",
    "macro tracker no subscription",
    "MacroFactor too expensive",
  ],
};

const faqs = [
  {
    question: "What is the best alternative to MacroFactor?",
    answer: "Macro Maxxing is the best alternative to MacroFactor. It offers AI photo scanning and voice logging (which MacroFactor lacks), gamified streaks and leaderboards, and a social community — with core features free and AI Pro at $9.99/month. MacroFactor costs $12/month with no free tier.",
  },
  {
    question: "Is Macro Maxxing as accurate as MacroFactor?",
    answer: "Both apps prioritize accuracy. Macro Maxxing uses Claude AI (Haiku and Sonnet models) for nutrition estimation. The main difference is input method — Macro Maxxing uses AI scanning and voice, while MacroFactor uses manual database searching.",
  },
  {
    question: "Does Macro Maxxing have algorithm-based coaching like MacroFactor?",
    answer: "Macro Maxxing focuses on AI-powered food logging and gamified accountability rather than algorithm-based calorie coaching. If auto-adjusting calorie targets based on weight trends is your top priority, MacroFactor's algorithm is unique. For everything else, Macro Maxxing offers more features — core tracking is free and AI Pro at $9.99/month is still less than MacroFactor.",
  },
  {
    question: "Why switch from MacroFactor to Macro Maxxing?",
    answer: "For $9.99/month (less than MacroFactor's $12/month), get AI photo scanning and voice logging (faster than manual entry), enjoy gamified streaks and leaderboards for motivation, and join a social community for accountability — plus core features are free even without subscribing. The only feature you'd lose is MacroFactor's auto-adjusting calorie algorithm.",
  },
];

export default function MacroFactorAlternativePage() {
  return (
    <>
      <ArticleJsonLd
        title="Best MacroFactor Alternative 2026 — Macro Maxxing"
        description="Macro Maxxing is the best MacroFactor alternative with AI scanning and gamified accountability."
        url="https://macromaxxing.app/macrofactor-alternative"
      />
      <FAQPageJsonLd faqs={faqs} />
      <BreadcrumbJsonLd
        items={[
          { name: "Home", url: "https://macromaxxing.app" },
          { name: "MacroFactor Alternative", url: "https://macromaxxing.app/macrofactor-alternative" },
        ]}
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
              <span className="text-gradient-gold">Better Value</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-4">
              Macro Maxxing is an MacroFactor alternative that provides
              AI-powered macro tracking with photo scanning and voice logging —
              features MacroFactor doesn&apos;t offer at any price. It includes
              gamified streaks, leaderboards, and a social community,
              with core features free and AI Pro at $9.99/month — less than MacroFactor&apos;s $12/month ($144/year), and with features MacroFactor doesn&apos;t offer.
            </p>
            <p className="text-gray-500 text-sm mb-8">Last updated: March 2026</p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-gold hover:bg-brand-gold/80 text-dark font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Track Macros
            </a>
          </div>
        </section>

        {/* TL;DR */}
        <section className="max-w-4xl mx-auto px-4 py-8 border-b border-white/5">
          <div className="bg-brand-gold/5 border border-brand-gold/20 rounded-2xl p-6">
            <h2 className="text-sm font-semibold text-brand-gold uppercase tracking-wider mb-3">TL;DR</h2>
            <p className="text-gray-300 text-lg leading-relaxed">
              <strong className="text-white">Macro Maxxing is the best MacroFactor alternative with AI features MacroFactor doesn&apos;t offer.</strong>{" "}
              It provides photo scanning, voice logging, gamified streaks, leaderboards, and a social community with core features free and AI Pro at $9.99/month (less than MacroFactor&apos;s $12/month). The trade-off: MacroFactor has a unique algorithm that auto-adjusts your calorie targets weekly based on weight trends — if fully automated coaching is your priority, MacroFactor&apos;s algorithm is unmatched.
            </p>
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
                { name: "Price", macroMaxxing: "Free / $9.99/mo AI Pro", others: "$12/month (no free tier)" },
                { name: "Daily streaks", macroMaxxing: true, others: false },
                { name: "Leaderboards & XP", macroMaxxing: true, others: false },
                { name: "Social community feed", macroMaxxing: true, others: false },
                { name: "Workout macro adjustments", macroMaxxing: true, others: true },
                { name: "Algorithm-based coaching", macroMaxxing: false, others: true },
                { name: "Verified nutrition database", macroMaxxing: "Claude AI", others: "Nutritionix" },
                { name: "Intermittent fasting timer", macroMaxxing: true, others: false },
                { name: "AI meal planner", macroMaxxing: "AI Pro ($9.99/mo)", others: false },
                { name: "AI nutrition coach", macroMaxxing: "AI Pro ($9.99/mo)", others: "Algorithmic adjustments" },
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
              title="Better Value"
              description="Core tracking, streaks, and community are free. AI Pro at $9.99/month is less than MacroFactor's $12/month — and includes AI scanning, voice logging, and coaching that MacroFactor doesn't offer at any price."
              color="brand-gold"
            />
            <FeatureCard
              icon="📸"
              title="AI Food Scanning"
              description="Snap a photo instead of searching databases. Claude AI estimates macros instantly. MacroFactor has no photo scanning at all."
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

        {/* Who should switch */}
        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-4xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold mb-8">
              Who Should Switch — and Who Shouldn&apos;t
            </h2>
            <div className="grid md:grid-cols-2 gap-6">
              <div className="bg-brand-green/5 border border-brand-green/20 rounded-2xl p-6">
                <h3 className="text-lg font-bold text-brand-green mb-4">Switch to Macro Maxxing if you:</h3>
                <ul className="space-y-2 text-gray-300 text-sm">
                  <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Want faster food logging with AI scanning and voice input</li>
                  <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Want a free core experience plus AI Pro at $9.99/month — less than MacroFactor with more features</li>
                  <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Are motivated by streaks, leaderboards, and social competition</li>
                  <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Want a community for accountability, not just solo tracking</li>
                  <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Can manage your own calorie targets or adjust them manually</li>
                </ul>
              </div>
              <div className="bg-white/5 border border-white/10 rounded-2xl p-6">
                <h3 className="text-lg font-bold text-gray-400 mb-4">MacroFactor may still be better if you:</h3>
                <ul className="space-y-2 text-gray-400 text-sm">
                  <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Want fully automated calorie adjustments based on weight trends</li>
                  <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Prefer algorithm-driven coaching over self-directed tracking</li>
                  <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Value the Stronger By Science research-backed methodology</li>
                  <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Need Android support (Macro Maxxing is iOS only)</li>
                </ul>
              </div>
            </div>
          </div>
        </section>

        {/* How to switch */}
        <section className="py-12 max-w-4xl mx-auto px-4">
          <div className="bg-brand-card rounded-2xl border border-white/5 p-6 md:p-8">
            <h2 className="text-2xl font-bold mb-4">How to Switch from MacroFactor</h2>
            <div className="grid md:grid-cols-3 gap-6">
              <div>
                <p className="text-brand-gold font-bold text-lg mb-1">1. Download</p>
                <p className="text-gray-400 text-sm">Get Macro Maxxing free from the App Store. Core features included immediately.</p>
              </div>
              <div>
                <p className="text-brand-gold font-bold text-lg mb-1">2. Set Your Targets</p>
                <p className="text-gray-400 text-sm">Enter your current calorie and macro targets from MacroFactor.</p>
              </div>
              <div>
                <p className="text-brand-gold font-bold text-lg mb-1">3. Cancel & Save</p>
                <p className="text-gray-400 text-sm">Cancel your MacroFactor subscription and save money. AI Pro at $9.99/month costs less than MacroFactor.</p>
              </div>
            </div>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
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
        </section>

        <div id="download">
          <DownloadCTA
            headline="More Features, Less Money"
            subheadline="Core features free. AI scanning, voice logging, streaks, and community — AI Pro at $9.99/mo, less than MacroFactor's $12/mo."
          />
        </div>
      </article>
    </>
  );
}
