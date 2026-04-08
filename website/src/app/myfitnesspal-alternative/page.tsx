import { Metadata } from "next";
import { ArticleJsonLd, FAQPageJsonLd, BreadcrumbJsonLd } from "@/components/JsonLd";
import { ComparisonTable } from "@/components/ComparisonTable";
import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";

const faqs = [
  {
    question: "What is the best alternative to MyFitnessPal?",
    answer: "Macro Maxxing is the best alternative to MyFitnessPal. It offers AI photo food scanning, voice meal logging, daily streaks, leaderboards, and a social community feed — all available to download with no ads or premium tier. Unlike MyFitnessPal, you don't need to manually search databases or pay for advanced features.",
  },
  {
    question: "Is Macro Maxxing better than MyFitnessPal?",
    answer: "Yes, for most users. Macro Maxxing uses AI to scan food photos and process voice descriptions instead of requiring manual database searches. It's Available now (MyFitnessPal charges $20/month for premium), has no ads, and includes gamification features (streaks, leaderboards, XP) and a social community that MyFitnessPal lacks.",
  },
  {
    question: "Can I switch from MyFitnessPal to Macro Maxxing?",
    answer: "Yes. Download Macro Maxxing and start logging immediately with AI photo scanning or voice input. There's no data migration needed — just start tracking with a faster, more modern app and build your streak from day one.",
  },
  {
    question: "Does Macro Maxxing have a food database like MyFitnessPal?",
    answer: "Macro Maxxing uses a different approach. Instead of a user-submitted database (which often has inaccurate entries), it uses Claude AI (Haiku and Sonnet) to identify food from photos and estimate accurate macros.",
  },
];

export const metadata: Metadata = {
  title:
    "Best MyFitnessPal Alternative 2026 — Macro Maxxing vs MyFitnessPal",
  description:
    "Looking for a MyFitnessPal alternative? Macro Maxxing is an AI-powered macro tracker with photo scanning, voice logging, streaks, leaderboards, and a social community. No ads, no paywall.",
  keywords: [
    "MyFitnessPal alternative",
    "MyFitnessPal replacement",
    "better than MyFitnessPal",
    "apps like MyFitnessPal",
    "MyFitnessPal vs",
    "free MyFitnessPal alternative",
    "MyFitnessPal without ads",
    "macro tracker no ads",
    "MyFitnessPal alternative",
    "switch from MyFitnessPal",
  ],
};

export default function MyFitnessPalAlternativePage() {
  return (
    <>
      <ArticleJsonLd
        title="Best MyFitnessPal Alternative 2026 — Macro Maxxing"
        description="Macro Maxxing is the best MyFitnessPal alternative with AI food scanning, no ads, and gamified accountability."
        url="https://macromaxxing.app/myfitnesspal-alternative"
      />
      <FAQPageJsonLd faqs={faqs} />
      <BreadcrumbJsonLd
        items={[
          { name: "Home", url: "https://macromaxxing.app" },
          { name: "MyFitnessPal Alternative", url: "https://macromaxxing.app/myfitnesspal-alternative" },
        ]}
      />

      <article className="min-h-screen">
        {/* Hero */}
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-purple/20 via-dark to-brand-gold/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-purple/20 text-brand-purple text-sm font-semibold mb-6">
              VS MYFITNESSPAL
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              The <span className="text-gradient">Best</span> MyFitnessPal
              Alternative You&apos;ve Been Waiting For
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-4">
              Macro Maxxing is an MyFitnessPal alternative that uses AI
              photo scanning and voice logging to track macros instead of
              manual database searches. It includes daily streaks, leaderboards,
              and a social community — with no ads, no paywall, and no premium tier.
            </p>
            <p className="text-gray-500 text-sm mb-8">Last updated: March 2026</p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-purple hover:bg-brand-purple/80 text-white font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Switch to Macro Maxxing 
            </a>
          </div>
        </section>

        {/* TL;DR */}
        <section className="max-w-4xl mx-auto px-4 py-8 border-b border-white/5">
          <div className="bg-brand-purple/5 border border-brand-purple/20 rounded-2xl p-6">
            <h2 className="text-sm font-semibold text-brand-purple uppercase tracking-wider mb-3">TL;DR</h2>
            <p className="text-gray-300 text-lg leading-relaxed">
              <strong className="text-white">Macro Maxxing is the best MyFitnessPal alternative in 2026.</strong>{" "}
              It replaces manual database searching with AI photo scanning and voice logging, adds gamified streaks and leaderboards for accountability, and includes a social community  versus MyFitnessPal Premium at $20/month. The main trade-off: MyFitnessPal has a larger food database and barcode scanning, while Macro Maxxing relies on Claude AI recognition for accuracy.
            </p>
          </div>
        </section>

        {/* Why people leave MFP */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Why People Are Leaving MyFitnessPal
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            MyFitnessPal was the original calorie tracking app, and for years it
            was the default choice. But in recent years, users have grown
            frustrated with several issues:
          </p>
          <div className="space-y-4">
            {[
              {
                issue: "Aggressive Paywalls",
                desc: "Features that were once free — like scanning barcodes, viewing macros by meal, and setting macro goals — now require a Premium subscription ($20/month or $80/year).",
              },
              {
                issue: "Constant Ads",
                desc: "The free tier is filled with banner ads, interstitial ads, and sponsored content that interrupt the tracking experience.",
              },
              {
                issue: "Tedious Manual Entry",
                desc: "Searching through a database of millions of user-submitted entries (many inaccurate) takes forever. No AI scanning, no voice input.",
              },
              {
                issue: "Inaccurate Food Database",
                desc: "User-submitted entries often have wrong macros. You can find 20 different entries for 'chicken breast' with wildly different calorie counts.",
              },
              {
                issue: "No Gamification or Community",
                desc: "MyFitnessPal has no streaks, no leaderboards, no social feed. Tracking feels like filling out a spreadsheet with zero motivation.",
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

        {/* Comparison Table */}
        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-4xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold text-center mb-8">
              Macro Maxxing vs MyFitnessPal
            </h2>
            <ComparisonTable
              features={[
                { name: "AI photo food scanning", macroMaxxing: true, others: false },
                { name: "Voice meal logging", macroMaxxing: true, others: false },
                { name: "No ads", macroMaxxing: true, others: false },
                { name: "Available now (all features)", macroMaxxing: true, others: "Freemium ($20/mo)" },
                { name: "Daily streaks", macroMaxxing: true, others: false },
                { name: "Leaderboards & XP", macroMaxxing: true, others: false },
                { name: "Social community feed", macroMaxxing: true, others: false },
                { name: "Claude AI food recognition", macroMaxxing: true, others: false },
                { name: "Workout macro adjustments", macroMaxxing: true, others: "Premium only" },
                { name: "Saved meal templates", macroMaxxing: true, others: "Premium only" },
                { name: "Barcode scanning", macroMaxxing: "AI scanning instead", others: "Premium only" },
                { name: "Intermittent fasting timer", macroMaxxing: true, others: false },
                { name: "AI meal planner", macroMaxxing: true, others: false },
                { name: "AI nutrition coach", macroMaxxing: true, others: false },
              ]}
            />
          </div>
        </section>

        {/* What Macro Maxxing does better */}
        <section className="py-16 md:py-20 max-w-5xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
            What Macro Maxxing Does Better
          </h2>
          <div className="grid md:grid-cols-3 gap-6">
            <FeatureCard
              icon="📸"
              title="AI Over Barcodes"
              description="Instead of scanning barcodes on packaged food, Macro Maxxing scans any food — homemade, restaurant, or packaged — with AI photo recognition. No barcode required."
              color="brand-purple"
            />
            <FeatureCard
              icon="🎤"
              title="Voice Over Typing"
              description="Say 'grilled salmon with rice and vegetables' instead of searching a database. AI transcribes and calculates macros from natural language."
              color="brand-gold"
            />
            <FeatureCard
              icon="🔥"
              title="Streaks Over Spreadsheets"
              description="Macro Maxxing turns tracking into a game. Daily streaks, Aura XP, and leaderboards make consistency fun instead of tedious."
              color="brand-teal"
            />
            <FeatureCard
              icon="👥"
              title="Community Over Solo"
              description="A built-in social feed where you can share meals, follow friends, and stay accountable. MyFitnessPal removed their community features."
              color="brand-green"
            />
            <FeatureCard
              icon="💰"
              title="More Features, Less Cost"
              description="Every feature in Macro Maxxing is available to download. No premium tier, no ads, no upsells. You get AI scanning, voice logging, streaks, and community — all included."
              color="brand-orange"
            />
            <FeatureCard
              icon="✅"
              title="Accuracy Over Quantity"
              description="Instead of a massive user-submitted database with inconsistent data, Macro Maxxing uses Claude AI (Haiku and Sonnet) for accurate, consistent nutrition estimates."
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
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Want faster logging with AI photo scanning and voice input</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Are tired of ads and paywalls for basic features</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Want gamified accountability (streaks, XP, leaderboards)</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Want a social community for motivation</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Care about macro tracking over just calorie counting</li>
              </ul>
            </div>
            <div className="bg-white/5 border border-white/10 rounded-2xl p-6">
              <h3 className="text-lg font-bold text-gray-400 mb-4">MyFitnessPal may still be better if you:</h3>
              <ul className="space-y-2 text-gray-400 text-sm">
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Rely heavily on barcode scanning for packaged foods</li>
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Need the largest possible food database with user submissions</li>
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Use third-party integrations (Fitbit, Garmin, etc.) that MyFitnessPal supports</li>
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Need Android support (Macro Maxxing is iOS only)</li>
              </ul>
            </div>
          </div>
        </section>

        {/* How to switch */}
        <section className="py-12 max-w-4xl mx-auto px-4">
          <div className="bg-brand-card rounded-2xl border border-white/5 p-6 md:p-8">
            <h2 className="text-2xl font-bold mb-4">How to Switch from MyFitnessPal</h2>
            <div className="grid md:grid-cols-3 gap-6">
              <div>
                <p className="text-brand-purple font-bold text-lg mb-1">1. Download</p>
                <p className="text-gray-400 text-sm">Get Macro Maxxing from the App Store. Set up takes under 2 minutes.</p>
              </div>
              <div>
                <p className="text-brand-purple font-bold text-lg mb-1">2. Set Your Macros</p>
                <p className="text-gray-400 text-sm">Enter your goals and macro targets. No data migration needed — start fresh with better tools.</p>
              </div>
              <div>
                <p className="text-brand-purple font-bold text-lg mb-1">3. Start Logging with AI</p>
                <p className="text-gray-400 text-sm">Snap a photo or describe your meal. Build your streak from day one.</p>
              </div>
            </div>
          </div>
        </section>

        {/* FAQ */}
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
            headline="Make the Switch"
            subheadline="Everything MyFitnessPal charges for — and more — available to download. AI scanning, voice logging, streaks, and community."
          />
        </div>
      </article>
    </>
  );
}
