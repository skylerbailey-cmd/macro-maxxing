import { Metadata } from "next";
import { ArticleJsonLd, FAQPageJsonLd, BreadcrumbJsonLd } from "@/components/JsonLd";
import { ComparisonTable } from "@/components/ComparisonTable";
import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Best Lifesum Alternative 2026 — Macro Maxxing vs Lifesum",
  description:
    "Looking for a Lifesum alternative with AI features and no paywall? Macro Maxxing offers AI photo scanning, voice logging, gamified streaks, leaderboards, and a social community — all included.",
  keywords: [
    "Lifesum alternative",
    "Lifesum replacement",
    "free Lifesum alternative",
    "better than Lifesum",
    "apps like Lifesum",
    "Lifesum vs",
    "Lifesum alternative",
    "nutrition app like Lifesum",
    "Lifesum without subscription",
    "diet app alternative",
  ],
};

const faqs = [
  {
    question: "What is the best alternative to Lifesum?",
    answer: "Macro Maxxing is the best alternative to Lifesum. It offers AI photo scanning, voice logging, full macro tracking, gamified streaks, leaderboards, and a social community — all available to download. Lifesum charges $50-70/year for Premium features.",
  },
  {
    question: "Is Macro Maxxing better than Lifesum?",
    answer: "For anyone serious about their macros, yes. Macro Maxxing offers AI-powered food scanning and voice logging (which Lifesum doesn't have), gamified accountability with streaks and leaderboards, and a social community for motivation — all included. Lifesum has more diet plan variety but locks most features behind a paywall.",
  },
  {
    question: "Does Macro Maxxing have diet plans like Lifesum?",
    answer: "Macro Maxxing uses a flexible approach: set your own macro targets based on your goals (weight loss, muscle gain, recomp, maintenance) and track against them with AI. Instead of rigid diet plans, you have full control over your nutrition targets with AI handling the logging work.",
  },
  {
    question: "Can I track intermittent fasting with Macro Maxxing?",
    answer: "Yes. Macro Maxxing includes an built-in intermittent fasting timer with support for all common protocols (16:8, 18:6, 20:4, OMAD, custom). Lifesum charges for fasting features in their Premium plan.",
  },
];

export default function LifesumAlternativePage() {
  return (
    <>
      <ArticleJsonLd
        title="Best Lifesum Alternative 2026 — Macro Maxxing"
        description="Macro Maxxing is the best Lifesum alternative with AI features and gamified accountability."
        url="https://macromaxxing.app/lifesum-alternative"
      />
      <FAQPageJsonLd faqs={faqs} />
      <BreadcrumbJsonLd
        items={[
          { name: "Home", url: "https://macromaxxing.app" },
          { name: "Lifesum Alternative", url: "https://macromaxxing.app/lifesum-alternative" },
        ]}
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
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-4">
              Macro Maxxing is an Lifesum alternative that adds AI photo
              scanning and voice logging to accurate macro tracking — features
              Lifesum doesn&apos;t offer at any price. It includes gamified streaks,
              leaderboards, and a social community, all at a fraction of Lifesum
              Premium at $50-70/year.
            </p>
            <p className="text-gray-500 text-sm mb-8">Last updated: March 2026</p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-cyan hover:bg-brand-cyan/80 text-dark font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Switch to Macro Maxxing 
            </a>
          </div>
        </section>

        {/* TL;DR */}
        <section className="max-w-4xl mx-auto px-4 py-8 border-b border-white/5">
          <div className="bg-brand-cyan/5 border border-brand-cyan/20 rounded-2xl p-6">
            <h2 className="text-sm font-semibold text-brand-cyan uppercase tracking-wider mb-3">TL;DR</h2>
            <p className="text-gray-300 text-lg leading-relaxed">
              <strong className="text-white">Macro Maxxing is the best Lifesum alternative with AI features Lifesum doesn&apos;t offer.</strong>{" "}
              It provides photo scanning, voice logging, gamified streaks, and a social community at a fraction of the cost versus Lifesum Premium at $50-70/year. The trade-off: Lifesum offers curated diet plans (keto, clean eating, etc.) and a polished visual design that some users prefer for guided nutrition.
            </p>
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
                { name: "Available now", macroMaxxing: true, others: "Freemium ($50-70/yr)" },
                { name: "Full macro tracking", macroMaxxing: true, others: "Premium only" },
                { name: "Daily streaks", macroMaxxing: true, others: false },
                { name: "Leaderboards & XP", macroMaxxing: true, others: false },
                { name: "Social community feed", macroMaxxing: true, others: false },
                { name: "Workout macro adjustments", macroMaxxing: true, others: false },
                { name: "Diet plan variety", macroMaxxing: "Custom macro targets", others: "Multiple plans (Premium)" },
                { name: "Intermittent fasting timer", macroMaxxing: true, others: "Premium only" },
                { name: "AI meal planner", macroMaxxing: true, others: "Recipe library" },
                { name: "AI nutrition coach", macroMaxxing: true, others: "Life Score insights" },
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
              title="Everything Included"
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

        {/* Who should switch */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-8">
            Who Should Switch — and Who Shouldn&apos;t
          </h2>
          <div className="grid md:grid-cols-2 gap-6">
            <div className="bg-brand-green/5 border border-brand-green/20 rounded-2xl p-6">
              <h3 className="text-lg font-bold text-brand-green mb-4">Switch to Macro Maxxing if you:</h3>
              <ul className="space-y-2 text-gray-300 text-sm">
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Want AI photo scanning and voice logging for faster tracking</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Don&apos;t want to pay $50-70/year for basic macro tracking</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Want gamified accountability (streaks, XP, leaderboards)</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Want a social community instead of tracking alone</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Set your own macro targets rather than following preset plans</li>
              </ul>
            </div>
            <div className="bg-white/5 border border-white/10 rounded-2xl p-6">
              <h3 className="text-lg font-bold text-gray-400 mb-4">Lifesum may still be better if you:</h3>
              <ul className="space-y-2 text-gray-400 text-sm">
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Want curated diet plans (keto, Mediterranean, clean eating)</li>
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Prefer a guided nutrition approach over self-directed tracking</li>
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Use health app integrations that Lifesum supports</li>
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Need Android support (Macro Maxxing is iOS only)</li>
              </ul>
            </div>
          </div>
        </section>

        {/* How to switch */}
        <section className="py-12 max-w-4xl mx-auto px-4">
          <div className="bg-brand-card rounded-2xl border border-white/5 p-6 md:p-8">
            <h2 className="text-2xl font-bold mb-4">How to Switch from Lifesum</h2>
            <div className="grid md:grid-cols-3 gap-6">
              <div>
                <p className="text-brand-cyan font-bold text-lg mb-1">1. Download</p>
                <p className="text-gray-400 text-sm">Get Macro Maxxing from the App Store. No subscription needed.</p>
              </div>
              <div>
                <p className="text-brand-cyan font-bold text-lg mb-1">2. Set Your Macros</p>
                <p className="text-gray-400 text-sm">Enter your calorie and macro goals. Full control over your targets from day one.</p>
              </div>
              <div>
                <p className="text-brand-cyan font-bold text-lg mb-1">3. Cancel Premium</p>
                <p className="text-gray-400 text-sm">Save $50-70/year. Start logging with AI and building your streak.</p>
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
            headline="Beautiful + Powerful + Free"
            subheadline="AI scanning, full macros, streaks, leaderboards, and community. Everything Lifesum Premium offers — included."
          />
        </div>
      </article>
    </>
  );
}
