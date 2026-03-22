import { Metadata } from "next";
import { ArticleJsonLd } from "@/components/JsonLd";
import ComparisonTable from "@/components/ComparisonTable";
import FeatureCard from "@/components/FeatureCard";
import DownloadCTA from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Best FatSecret Alternative 2026 — Macro Maxxing vs FatSecret",
  description:
    "Looking for a modern FatSecret alternative? Macro Maxxing offers AI photo scanning, voice logging, gamified streaks, leaderboards, and a social community — free like FatSecret but with modern AI features.",
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

export default function FatSecretAlternativePage() {
  return (
    <>
      <ArticleJsonLd
        title="Best FatSecret Alternative 2026 — Macro Maxxing"
        description="Macro Maxxing is the best modern alternative to FatSecret with AI scanning and gamified accountability."
        url="https://macromaxxing.com/fatsecret-alternative"
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-purple/20 via-dark to-brand-orange/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-purple/20 text-brand-purple text-sm font-semibold mb-6">
              VS FATSECRET
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              Free Tracking,{" "}
              <span className="text-gradient">Modernized</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-8">
              FatSecret is free — but it feels like 2010. Macro Maxxing is also
              free, but with AI photo scanning, voice logging, gamified streaks,
              leaderboards, and a real community. Same price, next generation.
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-purple hover:bg-brand-purple/80 text-white font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Upgrade for Free
            </a>
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
                { name: "100% free", macroMaxxing: true, others: true },
                { name: "Modern, polished UI", macroMaxxing: true, others: false },
                { name: "Verified nutrition data", macroMaxxing: "4 databases", others: "Unverified" },
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
              description="Snap a photo and get instant macros from 4 verified databases. FatSecret has no photo scanning — every entry is manual."
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
              description="AI cross-references 4 nutrition databases including USDA. No guessing whether entries are accurate."
              color="brand-cyan"
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
                  q: "What is the best alternative to FatSecret?",
                  a: "Macro Maxxing is the best alternative to FatSecret. Both are free, but Macro Maxxing offers AI photo scanning, voice logging, verified nutrition data from 4 databases, gamified streaks and leaderboards, and a modern social community. It's everything FatSecret should have evolved into.",
                },
                {
                  q: "Is Macro Maxxing free like FatSecret?",
                  a: "Yes. Macro Maxxing is 100% free, just like FatSecret. The difference is that Macro Maxxing includes modern AI features (photo scanning, voice logging), gamification (streaks, XP, leaderboards), and a social community — all at no cost.",
                },
                {
                  q: "Is Macro Maxxing more accurate than FatSecret?",
                  a: "Yes. Macro Maxxing uses a 3-tier AI system that cross-references 4 verified nutrition databases including USDA FoodData Central. FatSecret's database has no clear verification system, so you can't be sure entries are accurate.",
                },
                {
                  q: "Does Macro Maxxing have a community like FatSecret?",
                  a: "Macro Maxxing has a modern social feed where users share meals, celebrate streaks, and follow friends — far more engaging than FatSecret's basic forum format. Combined with leaderboards and Aura XP, it creates real accountability.",
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
            headline="Free Tracking, Upgraded"
            subheadline="Everything FatSecret does, plus AI scanning, voice logging, streaks, and community. Still free."
          />
        </div>
      </article>
    </>
  );
}
