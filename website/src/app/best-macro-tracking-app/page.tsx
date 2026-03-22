import type { Metadata } from "next";
import { ComparisonTable } from "@/components/ComparisonTable";
import { DownloadCTA } from "@/components/DownloadCTA";
import { ArticleJsonLd } from "@/components/JsonLd";

export const metadata: Metadata = {
  title: "Best Macro Tracking App in 2026 — AI-Powered",
  description:
    "Looking for the best macro tracking app? Macro Maxxing uses AI photo scanning, voice logging, and smart workout adjustments to make tracking effortless. Free download.",
  keywords: [
    "best macro tracking app",
    "macro tracker app",
    "best app for tracking macros",
    "macro counting app",
    "iifym app",
    "flexible dieting app",
    "best nutrition app",
  ],
};

const comparisonFeatures = [
  { name: "AI photo food scanning", macroMaxxing: true, others: false },
  { name: "Voice meal logging", macroMaxxing: true, others: false },
  { name: "Auto macro adjustments for workouts", macroMaxxing: true, others: false },
  { name: "Intermittent fasting timer", macroMaxxing: true, others: "Some" },
  { name: "Multiple nutrition databases", macroMaxxing: "4 databases", others: "1-2" },
  { name: "Social leaderboards & streaks", macroMaxxing: true, others: "Limited" },
  { name: "Saved meal templates", macroMaxxing: true, others: true },
  { name: "Free to use", macroMaxxing: true, others: "Freemium" },
  { name: "Dark mode", macroMaxxing: "Always", others: "Some" },
];

export default function BestMacroTrackingApp() {
  return (
    <>
      <ArticleJsonLd
        title="Best Macro Tracking App in 2026"
        description="Compare the best macro tracking apps and see why Macro Maxxing leads with AI-powered food scanning, voice logging, and smart workout adjustments."
        url="https://macromaxxing.com/best-macro-tracking-app"
      />

      <article className="pt-32 pb-12 px-4 sm:px-6">
        <div className="max-w-3xl mx-auto">
          <div className="bg-brand-purple/10 text-brand-purple text-xs font-semibold px-3 py-1 rounded-full inline-block mb-4">
            APP COMPARISON
          </div>
          <h1 className="text-3xl sm:text-5xl font-black mb-6 leading-tight">
            The Best Macro Tracking App in 2026
          </h1>
          <p className="text-gray-400 text-lg leading-relaxed mb-8">
            If you&apos;re serious about hitting your macros, you need an app that
            does more than just let you search a food database. You need
            something that makes tracking <strong className="text-white">fast, accurate, and automatic</strong>.
          </p>

          <h2 className="text-2xl font-bold mb-4 mt-12">
            Why Most Macro Trackers Fall Short
          </h2>
          <p className="text-gray-400 leading-relaxed mb-4">
            Traditional macro trackers like MyFitnessPal and Cronometer rely on
            manual text search and barcode scanning. They work, but they&apos;re
            slow. You spend more time typing &ldquo;grilled chicken breast 6oz&rdquo; than
            actually eating.
          </p>
          <p className="text-gray-400 leading-relaxed mb-8">
            Macro Maxxing takes a fundamentally different approach.{" "}
            <strong className="text-white">
              Snap a photo or describe your meal with your voice
            </strong>
            , and AI handles the rest — identifying foods, estimating portions,
            and pulling nutrition data from four databases (USDA, FatSecret,
            OpenFoodFacts, and our own AI models).
          </p>

          <h2 className="text-2xl font-bold mb-4 mt-12">
            What Makes Macro Maxxing the Best
          </h2>

          <div className="space-y-6 mb-12">
            <div className="bg-brand-card rounded-xl p-6 border border-white/5">
              <h3 className="text-lg font-semibold text-brand-purple mb-2">
                📸 AI Photo Scanning
              </h3>
              <p className="text-gray-400 text-sm">
                Take a picture of your plate. Our 3-tier AI system (local Vision
                AI → Claude Haiku → Claude Sonnet) identifies every food item
                and estimates macros. No typing required.
              </p>
            </div>
            <div className="bg-brand-card rounded-xl p-6 border border-white/5">
              <h3 className="text-lg font-semibold text-brand-gold mb-2">
                🎙️ Voice Logging
              </h3>
              <p className="text-gray-400 text-sm">
                Say &ldquo;ground turkey with rice and mixed vegetables&rdquo; and
                AI generates the full macro breakdown. Perfect for logging
                on the go or when your hands are full after a workout.
              </p>
            </div>
            <div className="bg-brand-card rounded-xl p-6 border border-white/5">
              <h3 className="text-lg font-semibold text-brand-teal mb-2">
                🏋️ Smart Workout Adjustments
              </h3>
              <p className="text-gray-400 text-sm">
                Log a strength training session and your daily macro targets
                automatically adjust based on ISSN & ACSM guidelines. No
                guesswork about how much extra to eat on training days.
              </p>
            </div>
          </div>

          <h2 className="text-2xl font-bold mb-6 mt-12">
            How Macro Maxxing Compares
          </h2>
          <div className="bg-brand-card rounded-xl border border-white/5 p-6 mb-12">
            <ComparisonTable features={comparisonFeatures} />
          </div>

          <h2 className="text-2xl font-bold mb-4 mt-12">
            Built for Athletes Who Are Built Different
          </h2>
          <p className="text-gray-400 leading-relaxed mb-4">
            Macro Maxxing isn&apos;t for casual dieters looking to &ldquo;eat a bit
            healthier.&rdquo; It&apos;s for athletes, bodybuilders, and fitness
            enthusiasts who take their nutrition seriously and want the fastest,
            most accurate tracking possible.
          </p>
          <p className="text-gray-400 leading-relaxed mb-4">
            With built-in streaks, leaderboards, an Aura XP system, and a
            social feed, it also keeps you accountable and motivated in ways
            other apps simply don&apos;t.
          </p>
        </div>
      </article>

      <DownloadCTA
        headline="Ready to switch to a smarter macro tracker?"
        subheadline="Download Macro Maxxing free and see the difference AI makes."
      />
    </>
  );
}
