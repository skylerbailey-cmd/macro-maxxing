import { Metadata } from "next";
import { ArticleJsonLd, FAQPageJsonLd, BreadcrumbJsonLd } from "@/components/JsonLd";
import { ComparisonTable } from "@/components/ComparisonTable";
import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Best FatSecret Alternative 2026 — Macro Maxxing vs FatSecret",
  description:
    "Looking for a modern FatSecret alternative? Macro Maxxing offers AI photo scanning, voice logging, gamified streaks, leaderboards, and a social community — like FatSecret but with modern AI features.",
  keywords: [
    "FatSecret alternative",
    "FatSecret replacement",
    "better than FatSecret",
    "apps like FatSecret",
    "FatSecret vs",
    "free FatSecret alternative",
    "modern calorie tracker",
    "FatSecret upgrade",
    "free macro tracker",
    "calorie counter with AI",
  ],
};

const faqs = [
  {
    question: "What is the best alternative to FatSecret?",
    answer: "Macro Maxxing is the best alternative to FatSecret. Both are free, but Macro Maxxing offers Claude AI photo scanning, voice logging, AI-powered nutrition estimates, gamified streaks and leaderboards, and a modern social community. It's everything FatSecret should have evolved into.",
  },
  {
    question: "How does Macro Maxxing's pricing compare to FatSecret?",
    answer: "Yes. Macro Maxxing is Available now, just like FatSecret. The difference is that Macro Maxxing includes modern AI features (photo scanning, voice logging), gamification (streaks, XP, leaderboards), and a social community — all included.",
  },
  {
    question: "Is Macro Maxxing more accurate than FatSecret?",
    answer: "Yes. Macro Maxxing uses Claude AI (Haiku and Sonnet models) for accurate nutrition estimates. FatSecret's database has no clear verification system, so you can't be sure entries are accurate.",
  },
  {
    question: "Does Macro Maxxing have a community like FatSecret?",
    answer: "Macro Maxxing has a modern social feed where users share meals, celebrate streaks, and follow friends — far more engaging than FatSecret's basic forum format. Combined with leaderboards and Aura XP, it creates real accountability.",
  },
];

export default function FatSecretAlternativePage() {
  return (
    <>
      <ArticleJsonLd
        title="Best FatSecret Alternative 2026 — Macro Maxxing"
        description="Macro Maxxing is the best modern alternative to FatSecret with AI scanning and gamified accountability."
        url="https://macromaxxing.app/fatsecret-alternative"
      />
      <FAQPageJsonLd faqs={faqs} />
      <BreadcrumbJsonLd
        items={[
          { name: "Home", url: "https://macromaxxing.app" },
          { name: "FatSecret Alternative", url: "https://macromaxxing.app/fatsecret-alternative" },
        ]}
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-purple/20 via-dark to-brand-orange/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-purple/20 text-brand-purple text-sm font-semibold mb-6">
              VS FATSECRET
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              Modern Tracking,{" "}
              <span className="text-gradient">Modernized</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-4">
              Macro Maxxing is a modern FatSecret alternative that adds AI
              photo scanning, voice logging, and AI-powered nutrition estimates to
              the tracking experience. It includes gamified streaks,
              leaderboards, and a social community — the evolution FatSecret
              never made.
            </p>
            <p className="text-gray-500 text-sm mb-8">Last updated: March 2026</p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-purple hover:bg-brand-purple/80 text-white font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Upgrade Now
            </a>
          </div>
        </section>

        {/* TL;DR */}
        <section className="max-w-4xl mx-auto px-4 py-8 border-b border-white/5">
          <div className="bg-brand-purple/5 border border-brand-purple/20 rounded-2xl p-6">
            <h2 className="text-sm font-semibold text-brand-purple uppercase tracking-wider mb-3">TL;DR</h2>
            <p className="text-gray-300 text-lg leading-relaxed">
              <strong className="text-white">Macro Maxxing is the best modern alternative to FatSecret — both offer tracking, but Macro Maxxing is a generation ahead.</strong>{" "}
              It adds AI photo scanning, voice logging, Claude AI-powered nutrition data, gamified streaks, and a social community to the tracking experience. The trade-off: FatSecret has a larger food database built over 17+ years and supports more platforms (web, Android), while Macro Maxxing is iOS-only with AI-powered accuracy.
            </p>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            FatSecret: Free but Outdated
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            FatSecret has been around since 2007 and has always been free, which
            earned it a loyal following. But the app hasn&apos;t kept up with
            modern nutrition tracking technology:
          </p>
          <div className="space-y-4">
            {[
              {
                issue: "Severely Outdated Interface",
                desc: "The UI feels like it hasn't been updated in years. Navigation is clunky, workflows are confusing, and the design lacks modern polish.",
              },
              {
                issue: "No AI Features",
                desc: "No photo food scanning, no voice logging, no AI-powered anything. Just a basic manual food diary from the pre-AI era.",
              },
              {
                issue: "App Freezes During Searches",
                desc: "Users report the app frequently freezing during food searches, causing data loss and requiring a full restart to continue logging.",
              },
              {
                issue: "Unverified Database Accuracy",
                desc: "No indication of whether food entries are verified or user-submitted. You can't tell if the macros you're logging are accurate.",
              },
              {
                issue: "Poor UX Workflows",
                desc: "Recent foods are context-locked, barcode failures require backing all the way out, and the app sends weight-loss notifications even to users with weight gain goals.",
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
              Macro Maxxing vs FatSecret
            </h2>
            <ComparisonTable
              features={[
                { name: "AI photo food scanning", macroMaxxing: true, others: false },
                { name: "Voice meal logging", macroMaxxing: true, others: false },
                { name: "Available now", macroMaxxing: true, others: true },
                { name: "Modern, polished UI", macroMaxxing: true, others: false },
                { name: "Verified nutrition data", macroMaxxing: "Claude AI", others: "Unverified" },
                { name: "Daily streaks", macroMaxxing: true, others: false },
                { name: "Leaderboards & XP", macroMaxxing: true, others: false },
                { name: "Social community feed", macroMaxxing: true, others: "Basic forums" },
                { name: "Workout macro adjustments", macroMaxxing: true, others: false },
                { name: "Intermittent fasting timer", macroMaxxing: true, others: false },
                { name: "App reliability", macroMaxxing: true, others: "Frequent freezes" },
              ]}
            />
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-5xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
            Same Price, Next Generation
          </h2>
          <div className="grid md:grid-cols-3 gap-6">
            <FeatureCard
              icon="📸"
              title="AI Photo Scanning"
              description="Snap a photo and get instant macros powered by Claude AI. FatSecret has no photo scanning — every entry is manual."
              color="brand-purple"
            />
            <FeatureCard
              icon="🎤"
              title="Voice Input"
              description="Describe your meal out loud and AI logs it. FatSecret requires typing every single food item."
              color="brand-gold"
            />
            <FeatureCard
              icon="✨"
              title="Modern Design"
              description="Clean, fast, modern interface built with the latest technology. Not a 2007-era food diary."
              color="brand-teal"
            />
            <FeatureCard
              icon="🔥"
              title="Gamified Streaks"
              description="Build daily logging streaks, earn Aura XP, and compete on leaderboards. FatSecret has no motivational features."
              color="brand-orange"
            />
            <FeatureCard
              icon="👥"
              title="Real Community"
              description="A social feed with meal sharing and accountability — not basic forums from 2007. Follow friends and compete together."
              color="brand-green"
            />
            <FeatureCard
              icon="✅"
              title="Verified Data"
              description="Claude AI (Haiku and Sonnet) provides accurate nutrition estimates. No guessing whether entries are accurate."
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
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Want a modern app with AI photo scanning and voice logging</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Are frustrated by FatSecret&apos;s outdated interface and crashes</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Want verified nutrition data you can trust</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Want gamification and social features for motivation</li>
                <li className="flex items-start gap-2"><span className="text-brand-green mt-0.5">✓</span>Use iOS and want a premium tracking experience</li>
              </ul>
            </div>
            <div className="bg-white/5 border border-white/10 rounded-2xl p-6">
              <h3 className="text-lg font-bold text-gray-400 mb-4">FatSecret may still be better if you:</h3>
              <ul className="space-y-2 text-gray-400 text-sm">
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Need Android or web access (Macro Maxxing is iOS only)</li>
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Rely on FatSecret&apos;s large, established food database</li>
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Use FatSecret&apos;s recipe builder and meal planning features</li>
                <li className="flex items-start gap-2"><span className="text-gray-500 mt-0.5">•</span>Prefer forum-style community discussions</li>
              </ul>
            </div>
          </div>
        </section>

        {/* How to switch */}
        <section className="py-12 max-w-4xl mx-auto px-4">
          <div className="bg-brand-card rounded-2xl border border-white/5 p-6 md:p-8">
            <h2 className="text-2xl font-bold mb-4">How to Switch from FatSecret</h2>
            <div className="grid md:grid-cols-3 gap-6">
              <div>
                <p className="text-brand-purple font-bold text-lg mb-1">1. Download</p>
                <p className="text-gray-400 text-sm">Get Macro Maxxing from the App Store. Modern tracking, same ease.</p>
              </div>
              <div>
                <p className="text-brand-purple font-bold text-lg mb-1">2. Set Targets</p>
                <p className="text-gray-400 text-sm">Enter your calorie and macro goals. Same data, better tools.</p>
              </div>
              <div>
                <p className="text-brand-purple font-bold text-lg mb-1">3. Experience AI</p>
                <p className="text-gray-400 text-sm">Snap a photo instead of typing. See what modern tracking feels like.</p>
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
            headline="Modern Tracking, Upgraded"
            subheadline="Everything FatSecret does, plus AI scanning, voice logging, streaks, and community. Available now."
          />
        </div>
      </article>
    </>
  );
}
