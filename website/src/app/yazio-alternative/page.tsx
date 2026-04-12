import { Metadata } from "next";
import { ArticleJsonLd, FAQPageJsonLd, BreadcrumbJsonLd } from "@/components/JsonLd";
import { ComparisonTable } from "@/components/ComparisonTable";
import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Best YAZIO Alternative 2026 — Macro Maxxing vs YAZIO",
  description:
    "Looking for an YAZIO alternative without aggressive upsells? Macro Maxxing offers AI photo scanning, voice logging, accurate macros, streaks, leaderboards, and community — Core features free, AI Pro at $9.99/mo — no aggressive upsells.",
  keywords: [
    "YAZIO alternative",
    "YAZIO replacement",
    "free YAZIO alternative",
    "better than YAZIO",
    "apps like YAZIO",
    "YAZIO vs",
    "YAZIO alternative",
    "YAZIO without subscription",
    "calorie tracker no ads",
    "fasting app alternative",
  ],
};

const faqs = [
  {
    question: "What is the best alternative to YAZIO?",
    answer: "Macro Maxxing is the best alternative to YAZIO. It offers accurate Claude AI photo scanning, voice meal logging, customizable fasting timers, gamified streaks, leaderboards, and a social community — with core features free and AI Pro at $9.99/month — no aggressive upsells or pop-ups like YAZIO.",
  },
  {
    question: "Is Macro Maxxing more accurate than YAZIO?",
    answer: "Yes. Macro Maxxing uses Claude AI (Haiku and Sonnet models) for accurate nutrition estimates. YAZIO users frequently report inaccurate food entries with wildly wrong calorie counts. Accuracy is a core priority for Macro Maxxing.",
  },
  {
    question: "Does Macro Maxxing have a fasting timer like YAZIO?",
    answer: "Yes. Macro Maxxing includes a fully customizable intermittent fasting timer supporting 16:8, 18:6, 20:4, OMAD, and any custom window. Unlike YAZIO's fasting feature which users report as inflexible, Macro Maxxing lets you set any schedule you want.",
  },
  {
    question: "Does Macro Maxxing have upsells?",
    answer: "Macro Maxxing is free to download with core tracking, fasting timer, streaks, leaderboards, and community included. AI-powered features (photo scanning, voice logging, meal planner, nutrition coach) are available through an optional AI Pro subscription at $9.99/month. There are no aggressive pop-ups or upsells — you upgrade on your terms.",
  },
];

export default function YazioAlternativePage() {
  return (
    <>
      <ArticleJsonLd
        title="Best YAZIO Alternative 2026 — Macro Maxxing"
        description="Macro Maxxing is the best YAZIO alternative with accurate AI scanning, no upsells, and gamified accountability."
        url="https://macromaxxing.app/yazio-alternative"
      />
      <FAQPageJsonLd faqs={faqs} />
      <BreadcrumbJsonLd
        items={[
          { name: "Home", url: "https://macromaxxing.app" },
          { name: "YAZIO Alternative", url: "https://macromaxxing.app/yazio-alternative" },
        ]}
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
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-4">
              Macro Maxxing is an YAZIO alternative that provides accurate
              AI-powered macro tracking without the aggressive upsells, pop-ups,
              or inaccurate food data that YAZIO users report. It includes
              gamified streaks, leaderboards, and a social community — with core features free and an optional AI Pro subscription at $9.99/month — no aggressive upsells.
            </p>
            <p className="text-gray-500 text-sm mb-8">Last updated: March 2026</p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-mint hover:bg-brand-mint/80 text-dark font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Switch to Macro Maxxing 
            </a>
          </div>
        </section>

        {/* TL;DR */}
        <section className="max-w-4xl mx-auto px-4 py-8 border-b border-white/5">
          <div className="bg-brand-mint/5 border border-brand-mint/20 rounded-2xl p-6">
            <h2 className="text-sm font-semibold text-brand-mint uppercase tracking-wider mb-3">TL;DR</h2>
            <p className="text-gray-300 text-lg leading-relaxed">
              <strong className="text-white">Macro Maxxing is the best YAZIO alternative with accurate data and zero upsells.</strong>{" "}
              It provides Claude AI photo scanning, voice logging, a customizable fasting timer, and gamified accountability — with core features free and AI Pro at $9.99/month — no ads or pop-ups. The trade-off: YAZIO has a larger international food database (especially for European foods) and offers structured meal plans, which some users prefer for guided nutrition.
            </p>
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
                { name: "Claude AI photo scanning", macroMaxxing: true, others: "Basic AI" },
                { name: "Voice meal logging", macroMaxxing: true, others: false },
                { name: "Price", macroMaxxing: "Free / $9.99/mo AI Pro", others: "Aggressive freemium" },
                { name: "No ads or pop-ups", macroMaxxing: true, others: false },
                { name: "Accurate nutrition data", macroMaxxing: "Claude AI", others: "User-reported issues" },
                { name: "Daily streaks", macroMaxxing: true, others: "Streak baiting for Pro" },
                { name: "Leaderboards & XP", macroMaxxing: true, others: false },
                { name: "Social community feed", macroMaxxing: true, others: false },
                { name: "Workout macro adjustments", macroMaxxing: true, others: false },
                { name: "Customizable fasting timer", macroMaxxing: true, others: "Limited" },
                { name: "AI meal planner", macroMaxxing: "AI Pro ($9.99/mo)", others: "Recipe suggestions (PRO)" },
                { name: "AI nutrition coach", macroMaxxing: "AI Pro ($9.99/mo)", others: false },
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
              description="Claude AI (Haiku and Sonnet) provides accurate nutrition estimates. No wildly wrong calorie counts — just accurate macros."
              color="brand-mint"
            />
            <FeatureCard
              icon="🚫"
              title="Zero Pop-Ups"
              description="No aggressive upsells or pop-ups after every meal. Core features are free, and AI Pro is an optional $9.99/month upgrade — on your terms, not theirs."
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

        {/* Who should switch */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-8">
            Who Should Switch — and Who Shouldn&apos;t
          </h2>
          <div className="grid md:grid-cols-2 gap-6">
            <div className="bg-brand-green/5 border border-brand-green/20 rounded-2xl p-6">
              <h3 className="text-lg font-bold text-brand-green mb-4">Switch to Macro Maxxing if you:</h3>
              <ul className="space-y-2 text-gray-300 text-sm">
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Are frustrated by YAZIO&apos;s constant subscription pop-ups</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Have experienced inaccurate food data in YAZIO</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Want AI photo scanning and voice logging</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Want real gamification (not streak-baiting for premium)</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Want a customizable fasting timer that actually works</li>
              </ul>
            </div>
            <div className="bg-white/5 border border-white/10 rounded-2xl p-6">
              <h3 className="text-lg font-bold text-gray-400 mb-4">YAZIO may still be better if you:</h3>
              <ul className="space-y-2 text-gray-400 text-sm">
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Need a large European food database</li>
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Want structured meal plans and recipes</li>
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Prefer a guided nutrition program over self-directed tracking</li>
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Need Android support (Macro Maxxing is iOS only)</li>
              </ul>
            </div>
          </div>
        </section>

        {/* How to switch */}
        <section className="py-12 max-w-4xl mx-auto px-4">
          <div className="bg-brand-card rounded-2xl border border-white/5 p-6 md:p-8">
            <h2 className="text-2xl font-bold mb-4">How to Switch from YAZIO</h2>
            <div className="grid md:grid-cols-3 gap-6">
              <div>
                <p className="text-brand-mint font-bold text-lg mb-1">1. Download</p>
                <p className="text-gray-400 text-sm">Get Macro Maxxing free from the App Store. Core features included immediately.</p>
              </div>
              <div>
                <p className="text-brand-mint font-bold text-lg mb-1">2. Set Goals</p>
                <p className="text-gray-400 text-sm">Enter your macro targets and fasting schedule. Full control from the start.</p>
              </div>
              <div>
                <p className="text-brand-mint font-bold text-lg mb-1">3. Enjoy the Silence</p>
                <p className="text-gray-400 text-sm">No pop-ups. No upsells. Just fast, accurate tracking with AI.</p>
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
            headline="Tracking Without the Annoyance"
            subheadline="Core tracking free, AI Pro at $9.99/mo. Accurate AI scanning, real gamification, and zero aggressive upsells."
          />
        </div>
      </article>
    </>
  );
}
