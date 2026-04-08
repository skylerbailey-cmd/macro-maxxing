import { Metadata } from "next";
import { ArticleJsonLd, FAQPageJsonLd, BreadcrumbJsonLd } from "@/components/JsonLd";
import { ComparisonTable } from "@/components/ComparisonTable";
import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Best Carbon Diet Coach Alternative 2026 — Macro Maxxing vs Carbon",
  description:
    "Looking for an Carbon Diet Coach alternative? Macro Maxxing offers AI photo scanning, voice logging, gamified streaks, leaderboards, and a social community — without the $10/month subscription.",
  keywords: [
    "Carbon Diet Coach alternative",
    "Carbon Diet Coach replacement",
    "free Carbon Diet Coach alternative",
    "better than Carbon Diet Coach",
    "apps like Carbon Diet Coach",
    "Carbon Diet Coach vs",
    "Carbon diet app alternative",
    "bodybuilding diet app free",
    "contest prep diet app",
    "AI diet coach alternative",
  ],
};

const faqs = [
  {
    question: "What is the best alternative to Carbon Diet Coach?",
    answer: "Macro Maxxing is the best alternative to Carbon Diet Coach. It offers AI photo scanning and voice logging (which Carbon lacks), gamified streaks and leaderboards, and a social community . Carbon costs $10/month with no free tier.",
  },
  {
    question: "Is Macro Maxxing good for bodybuilding like Carbon?",
    answer: "Yes. Macro Maxxing tracks all macros precisely, adjusts targets for workout days, and supports bulking, cutting, and recomp protocols. While Carbon's auto-adjusting coaching algorithm is unique, Macro Maxxing offers faster logging with AI and more accountability features.",
  },
  {
    question: "Does Macro Maxxing adjust macros automatically like Carbon?",
    answer: "Macro Maxxing automatically adjusts macros based on workout type and intensity. However, it doesn't have Carbon's algorithm that adjusts baseline calories weekly based on weight trends. If automatic weekly calorie adjustments are your top priority, Carbon excels there.",
  },
  {
    question: "Can I use Macro Maxxing for contest prep?",
    answer: "Yes. Macro Maxxing's precise AI-powered tracking is ideal for contest prep where accuracy matters most. Set your cutting macros, build a daily streak, and use the community for accountability through the entire prep. The gamified features help maintain discipline during difficult dieting phases.",
  },
];

export default function CarbonDietCoachAlternativePage() {
  return (
    <>
      <ArticleJsonLd
        title="Best Carbon Diet Coach Alternative 2026 — Macro Maxxing"
        description="Macro Maxxing is the best Carbon Diet Coach alternative with AI scanning and gamified tracking."
        url="https://macromaxxing.app/carbon-diet-coach-alternative"
      />
      <FAQPageJsonLd faqs={faqs} />
      <BreadcrumbJsonLd
        items={[
          { name: "Home", url: "https://macromaxxing.app" },
          { name: "Carbon Diet Coach Alternative", url: "https://macromaxxing.app/carbon-diet-coach-alternative" },
        ]}
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-rose/20 via-dark to-brand-purple/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-rose/20 text-brand-rose text-sm font-semibold mb-6">
              VS CARBON DIET COACH
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              AI Macro Tracking for{" "}
              <span className="text-gradient">Serious Trackers</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-4">
              Macro Maxxing is an Carbon Diet Coach alternative that provides
              AI photo scanning and voice logging — features Carbon doesn&apos;t offer
              despite its $10/month price tag. It includes gamified streaks,
              leaderboards, and a social community, and works for any fitness
              goal beyond just bodybuilding.
            </p>
            <p className="text-gray-500 text-sm mb-8">Last updated: March 2026</p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-rose hover:bg-brand-rose/80 text-white font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Level Up Your Tracking 
            </a>
          </div>
        </section>

        {/* TL;DR */}
        <section className="max-w-4xl mx-auto px-4 py-8 border-b border-white/5">
          <div className="bg-brand-rose/5 border border-brand-rose/20 rounded-2xl p-6">
            <h2 className="text-sm font-semibold text-brand-rose uppercase tracking-wider mb-3">TL;DR</h2>
            <p className="text-gray-300 text-lg leading-relaxed">
              <strong className="text-white">Macro Maxxing is the best Carbon Diet Coach alternative for serious trackers who want AI-powered logging.</strong>{" "}
              It offers photo scanning, voice input, gamified streaks, and a competitive community at a fraction of the cost versus Carbon&apos;s $10/month. The trade-off: Carbon has Layne Norton&apos;s auto-adjusting coaching algorithm that adapts your calories weekly based on weight data — if fully automated contest prep coaching is your priority, Carbon is purpose-built for that.
            </p>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Carbon Diet Coach: Built for Bodybuilders, Priced for Pros
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            Carbon Diet Coach, created by Layne Norton, is a well-designed
            coaching app that adjusts macros based on your progress. It&apos;s
            popular in the bodybuilding and physique community. However, it has
            notable limitations:
          </p>
          <div className="space-y-4">
            {[
              {
                issue: "Paid Subscription ($10/month)",
                desc: "No free tier. You need to pay $10/month ($120/year) to use Carbon at all. This is steep for a macro tracker without AI features.",
              },
              {
                issue: "No AI Photo Scanning",
                desc: "Despite calling itself an 'AI diet coach,' Carbon doesn't offer AI food photo recognition. All meal logging is manual database searching.",
              },
              {
                issue: "No Voice Logging",
                desc: "Every food entry requires typing and searching. No hands-free voice input option.",
              },
              {
                issue: "Bodybuilding-Focused Only",
                desc: "Carbon is designed specifically for physique competitors. The interface and coaching are tailored for bodybuilding, which may not suit general fitness enthusiasts.",
              },
              {
                issue: "No Social or Gamification Features",
                desc: "No streaks, no leaderboards, no community feed. It's a solo coaching tool without any social accountability mechanics.",
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
              Macro Maxxing vs Carbon Diet Coach
            </h2>
            <ComparisonTable
              features={[
                { name: "AI photo food scanning", macroMaxxing: true, others: false },
                { name: "Voice meal logging", macroMaxxing: true, others: false },
                { name: "Price", macroMaxxing: "Download", others: "$10/month" },
                { name: "Daily streaks", macroMaxxing: true, others: false },
                { name: "Leaderboards & XP", macroMaxxing: true, others: false },
                { name: "Social community feed", macroMaxxing: true, others: false },
                { name: "Workout macro adjustments", macroMaxxing: true, others: true },
                { name: "Auto macro adjustments", macroMaxxing: false, others: true },
                { name: "Works for all fitness goals", macroMaxxing: true, others: "Bodybuilding focus" },
                { name: "Intermittent fasting timer", macroMaxxing: true, others: false },
                { name: "AI meal planner", macroMaxxing: true, others: false },
                { name: "AI nutrition coach", macroMaxxing: true, others: "Weekly algorithmic adjustments" },
                { name: "Saved meal templates", macroMaxxing: true, others: true },
              ]}
            />
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-5xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
            Why People Switch to Macro Maxxing
          </h2>
          <div className="grid md:grid-cols-3 gap-6">
            <FeatureCard
              icon="📸"
              title="AI Photo Scanning"
              description="Snap a photo and Claude AI identifies your food and estimates macros instantly. Carbon requires manual searching for every single item."
              color="brand-rose"
            />
            <FeatureCard
              icon="💰"
              title="Better Value"
              description="Macro Maxxing is Available now. Carbon charges $10/month with no free tier at all."
              color="brand-gold"
            />
            <FeatureCard
              icon="🔥"
              title="Streaks & XP"
              description="Gamified tracking with daily streaks, Aura XP, and leaderboards. Carbon is a coaching tool without any motivational mechanics."
              color="brand-orange"
            />
            <FeatureCard
              icon="👥"
              title="Competitive Community"
              description="Social feed, friend following, and leaderboard competition. Carbon is a solo experience."
              color="brand-green"
            />
            <FeatureCard
              icon="🎤"
              title="Voice Input"
              description="Describe meals by voice for instant AI macro calculation. Perfect for post-workout when typing is the last thing you want to do."
              color="brand-purple"
            />
            <FeatureCard
              icon="🎯"
              title="For Everyone"
              description="Weight loss, muscle gain, recomp, maintenance, looksmaxxing — Macro Maxxing works for any goal, not just bodybuilding."
              color="brand-teal"
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
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Don&apos;t want to pay $10/month ($120/year)</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Want gamified accountability with streaks, XP, and leaderboards</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Want a community for motivation, not just solo coaching</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Have goals beyond bodybuilding (weight loss, recomp, general fitness)</li>
              </ul>
            </div>
            <div className="bg-white/5 border border-white/10 rounded-2xl p-6">
              <h3 className="text-lg font-bold text-gray-400 mb-4">Carbon may still be better if you:</h3>
              <ul className="space-y-2 text-gray-400 text-sm">
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Want fully automated weekly calorie adjustments from Layne Norton&apos;s algorithm</li>
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Are preparing for a bodybuilding or physique competition</li>
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Prefer algorithm-driven coaching over self-directed tracking</li>
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Need Android support (Macro Maxxing is iOS only)</li>
              </ul>
            </div>
          </div>
        </section>

        {/* How to switch */}
        <section className="py-12 max-w-4xl mx-auto px-4">
          <div className="bg-brand-card rounded-2xl border border-white/5 p-6 md:p-8">
            <h2 className="text-2xl font-bold mb-4">How to Switch from Carbon Diet Coach</h2>
            <div className="grid md:grid-cols-3 gap-6">
              <div>
                <p className="text-brand-rose font-bold text-lg mb-1">1. Download</p>
                <p className="text-gray-400 text-sm">Get Macro Maxxing from the App Store. No subscription needed.</p>
              </div>
              <div>
                <p className="text-brand-rose font-bold text-lg mb-1">2. Transfer Targets</p>
                <p className="text-gray-400 text-sm">Enter your current calorie and macro targets from Carbon.</p>
              </div>
              <div>
                <p className="text-brand-rose font-bold text-lg mb-1">3. Better Value</p>
                <p className="text-gray-400 text-sm">Cancel Carbon, start logging with AI, and build your streak.</p>
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
            headline="Built for Serious Trackers"
            subheadline="AI scanning, voice logging, streaks, leaderboards, and community. All the tools you need ."
          />
        </div>
      </article>
    </>
  );
}
