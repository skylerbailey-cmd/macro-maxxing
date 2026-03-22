import type { Metadata } from "next";
import { ComparisonTable } from "@/components/ComparisonTable";
import { DownloadCTA } from "@/components/DownloadCTA";
import { ArticleJsonLd } from "@/components/JsonLd";

export const metadata: Metadata = {
  title: "Free Calorie Counter App with AI — No Barcode Needed",
  description:
    "Count calories with AI photo scanning and voice logging. No barcode scanning required. Track calories, protein, carbs, and fat effortlessly with Macro Maxxing.",
  keywords: [
    "calorie counter app",
    "free calorie counter",
    "calorie tracker app",
    "best calorie counting app",
    "calorie counter no barcode",
    "AI calorie counter",
    "easy calorie tracker",
    "food calorie app",
  ],
};

const comparisonFeatures = [
  { name: "AI photo calorie scanning", macroMaxxing: true, others: false },
  { name: "Voice calorie logging", macroMaxxing: true, others: false },
  { name: "Barcode scanning", macroMaxxing: false, others: true },
  { name: "Homemade meal support", macroMaxxing: "AI estimates", others: "Manual recipe entry" },
  { name: "Full macro breakdown", macroMaxxing: true, others: true },
  { name: "Workout calorie adjustments", macroMaxxing: "Automatic", others: "Manual" },
  { name: "Free", macroMaxxing: true, others: "Freemium" },
];

export default function CalorieCounterApp() {
  return (
    <>
      <ArticleJsonLd
        title="Free Calorie Counter App with AI"
        description="Count calories with AI photo scanning and voice logging. No barcode scanning required."
        url="https://macromaxxing.com/calorie-counter-app"
      />

      <article className="pt-32 pb-12 px-4 sm:px-6">
        <div className="max-w-3xl mx-auto">
          <div className="bg-brand-orange/10 text-brand-orange text-xs font-semibold px-3 py-1 rounded-full inline-block mb-4">
            CALORIE TRACKING
          </div>
          <h1 className="text-3xl sm:text-5xl font-black mb-6 leading-tight">
            The Calorie Counter That
            <br />
            <span className="text-gradient-gold">Doesn&apos;t Need a Barcode</span>
          </h1>
          <p className="text-gray-400 text-lg leading-relaxed mb-12">
            Most calorie counters were built for packaged food. But what about
            the meals you actually cook? The plate your friend made? The
            restaurant dish with no nutrition label? Macro Maxxing counts
            calories from photos and voice — no barcode required.
          </p>

          <h2 className="text-2xl font-bold mb-4">
            Why Barcode Scanning Isn&apos;t Enough
          </h2>
          <p className="text-gray-400 leading-relaxed mb-4">
            Barcode scanners work great for packaged food. But research shows
            that most of what we eat doesn&apos;t come with a barcode — home-cooked
            meals, restaurant dishes, meals from friends or family, bulk-prepped
            food.
          </p>
          <p className="text-gray-400 leading-relaxed mb-8">
            That&apos;s where AI comes in. Macro Maxxing lets you{" "}
            <strong className="text-white">take a photo of any meal</strong> —
            packaged or not — and instantly get a calorie and macro estimate.
          </p>

          <h2 className="text-2xl font-bold mb-4">3 Ways to Count Calories</h2>
          <div className="space-y-4 mb-12">
            <div className="bg-brand-card rounded-xl p-5 border border-white/5 flex items-start gap-4">
              <span className="text-3xl">📸</span>
              <div>
                <h3 className="font-semibold text-white mb-1">Photo Scan</h3>
                <p className="text-gray-400 text-sm">
                  Snap a photo of your plate. AI identifies the foods and
                  estimates calories from portion sizes. Works on mixed plates,
                  restaurant meals, and home-cooked food.
                </p>
              </div>
            </div>
            <div className="bg-brand-card rounded-xl p-5 border border-white/5 flex items-start gap-4">
              <span className="text-3xl">🎙️</span>
              <div>
                <h3 className="font-semibold text-white mb-1">Voice Input</h3>
                <p className="text-gray-400 text-sm">
                  Say what you ate naturally: &ldquo;Two eggs, toast with butter,
                  and a glass of orange juice.&rdquo; AI parses your description
                  and generates the calorie count.
                </p>
              </div>
            </div>
            <div className="bg-brand-card rounded-xl p-5 border border-white/5 flex items-start gap-4">
              <span className="text-3xl">⌨️</span>
              <div>
                <h3 className="font-semibold text-white mb-1">Manual Entry</h3>
                <p className="text-gray-400 text-sm">
                  Search our database of foods from USDA, FatSecret, and
                  OpenFoodFacts. Or enter custom macros directly.
                </p>
              </div>
            </div>
          </div>

          <h2 className="text-2xl font-bold mb-6">
            Macro Maxxing vs. Traditional Calorie Counters
          </h2>
          <div className="bg-brand-card rounded-xl border border-white/5 p-6 mb-12">
            <ComparisonTable features={comparisonFeatures} />
          </div>

          <h2 className="text-2xl font-bold mb-4">
            More Than Just Calories
          </h2>
          <p className="text-gray-400 leading-relaxed mb-4">
            Calories matter, but macros matter more. Macro Maxxing tracks all
            four: <span className="text-brand-orange">calories</span>,{" "}
            <span className="text-brand-cyan">protein</span>,{" "}
            <span className="text-brand-mint">carbs</span>, and{" "}
            <span className="text-brand-rose">fat</span>. Plus, it
            automatically adjusts your daily targets when you log a workout.
          </p>
          <p className="text-gray-400 leading-relaxed">
            Add in streaks, leaderboards, and a social feed, and you&apos;ve got
            the most motivating calorie counter you&apos;ve ever used.
          </p>
        </div>
      </article>

      <DownloadCTA
        headline="Counting calories shouldn't be a chore."
        subheadline="Download Macro Maxxing and let AI handle the math."
      />
    </>
  );
}
