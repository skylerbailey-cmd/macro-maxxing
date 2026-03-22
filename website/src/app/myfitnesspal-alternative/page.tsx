import { Metadata } from "next";
import { ArticleJsonLd } from "@/components/JsonLd";
import ComparisonTable from "@/components/ComparisonTable";
import FeatureCard from "@/components/FeatureCard";
import DownloadCTA from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title:
    "Best MyFitnessPal Alternative 2026 — Macro Maxxing vs MyFitnessPal",
  description:
    "Looking for a MyFitnessPal alternative? Macro Maxxing is a free AI-powered macro tracker with photo scanning, voice logging, streaks, leaderboards, and a social community. No ads, no paywall.",
  keywords: [
    "MyFitnessPal alternative",
    "MyFitnessPal replacement",
    "better than MyFitnessPal",
    "apps like MyFitnessPal",
    "MyFitnessPal vs",
    "free MyFitnessPal alternative",
    "MyFitnessPal without ads",
    "macro tracker no ads",
    "MyFitnessPal free alternative",
    "switch from MyFitnessPal",
  ],
};

export default function MyFitnessPalAlternativePage() {
  return (
    <>
      <ArticleJsonLd
        title="Best MyFitnessPal Alternative 2026 — Macro Maxxing"
        description="Macro Maxxing is the best free MyFitnessPal alternative with AI food scanning, no ads, and gamified accountability."
        url="https://macromaxxing.com/myfitnesspal-alternative"
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
              The <span className="text-gradient">Free</span> MyFitnessPal
              Alternative You&apos;ve Been Waiting For
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-8">
              Tired of ads, paywalls, and manually searching through a bloated
              food database? Macro Maxxing replaces all of that with AI photo
              scanning, voice logging, and gamified tracking — completely free.
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-purple hover:bg-brand-purple/80 text-white font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Switch to Macro Maxxing — Free
            </a>
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
                { name: "100% free (all features)", macroMaxxing: true, others: "Freemium ($20/mo)" },
                { name: "Daily streaks", macroMaxxing: true, others: false },
                { name: "Leaderboards & XP", macroMaxxing: true, others: false },
                { name: "Social community feed", macroMaxxing: true, others: false },
                { name: "3-tier AI food recognition", macroMaxxing: true, others: false },
                { name: "Workout macro adjustments", macroMaxxing: true, others: "Premium only" },
                { name: "Saved meal templates", macroMaxxing: true, others: "Premium only" },
                { name: "Barcode scanning", macroMaxxing: "AI scanning instead", others: "Premium only" },
                { name: "Intermittent fasting timer", macroMaxxing: true, others: false },
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
              title="Free Over Freemium"
              description="Every feature in Macro Maxxing is free. No premium tier, no ads, no upsells. You get AI scanning, voice logging, streaks, and community — all at no cost."
              color="brand-orange"
            />
            <FeatureCard
              icon="✅"
              title="Accuracy Over Quantity"
              description="Instead of a massive user-submitted database with inconsistent data, Macro Maxxing uses 4 verified nutrition databases including USDA FoodData Central."
              color="brand-cyan"
            />
          </div>
        </section>

        {/* FAQ */}
        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-4xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold mb-8">
              Frequently Asked Questions
            </h2>
            <div className="space-y-6">
              {[
                {
                  q: "What is the best free alternative to MyFitnessPal?",
                  a: "Macro Maxxing is the best free alternative to MyFitnessPal. It offers AI photo food scanning, voice meal logging, daily streaks, leaderboards, and a social community feed — all completely free with no ads or premium tier. Unlike MyFitnessPal, you don't need to manually search databases or pay for advanced features.",
                },
                {
                  q: "Is Macro Maxxing better than MyFitnessPal?",
                  a: "Yes, for most users. Macro Maxxing uses AI to scan food photos and process voice descriptions instead of requiring manual database searches. It's 100% free (MyFitnessPal charges $20/month for premium), has no ads, and includes gamification features (streaks, leaderboards, XP) and a social community that MyFitnessPal lacks.",
                },
                {
                  q: "Can I switch from MyFitnessPal to Macro Maxxing?",
                  a: "Yes. Download Macro Maxxing for free and start logging immediately with AI photo scanning or voice input. There's no data migration needed — just start tracking with a faster, more modern app and build your streak from day one.",
                },
                {
                  q: "Does Macro Maxxing have a food database like MyFitnessPal?",
                  a: "Macro Maxxing uses a different approach. Instead of a user-submitted database (which often has inaccurate entries), it uses a 3-tier AI system that identifies food from photos and cross-references 4 verified nutrition databases including USDA FoodData Central for accurate macros.",
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
            headline="Make the Switch"
            subheadline="Everything MyFitnessPal charges for — and more — completely free. AI scanning, voice logging, streaks, and community."
          />
        </div>
      </article>
    </>
  );
}
