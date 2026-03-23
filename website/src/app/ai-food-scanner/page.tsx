import type { Metadata } from "next";
import { DownloadCTA } from "@/components/DownloadCTA";
import { ArticleJsonLd } from "@/components/JsonLd";

export const metadata: Metadata = {
  title: "AI Food Scanner — Snap a Photo, Get Instant Macros",
  description:
    "Macro Maxxing's AI food scanner uses 3-tier image recognition to identify food and estimate calories, protein, carbs, and fat from a single photo. Free app.",
  keywords: [
    "AI food scanner",
    "AI food recognition app",
    "food photo macro tracker",
    "snap photo calories",
    "AI nutrition scanner",
    "food image recognition app",
    "photo calorie counter",
    "AI meal scanner",
  ],
};

export default function AIFoodScanner() {
  return (
    <>
      <ArticleJsonLd
        title="AI Food Scanner — Snap a Photo, Get Instant Macros"
        description="How Macro Maxxing's 3-tier AI food recognition system identifies food from photos and estimates macros instantly."
        url="https://macromaxxing.app/ai-food-scanner"
      />

      <article className="pt-32 pb-12 px-4 sm:px-6">
        <div className="max-w-3xl mx-auto">
          <div className="bg-brand-gold/10 text-brand-gold text-xs font-semibold px-3 py-1 rounded-full inline-block mb-4">
            AI TECHNOLOGY
          </div>
          <h1 className="text-3xl sm:text-5xl font-black mb-6 leading-tight">
            AI Food Scanner:
            <br />
            <span className="text-gradient">Photo to Macros in Seconds</span>
          </h1>
          <p className="text-gray-400 text-lg leading-relaxed mb-12">
            Stop typing food names into a search bar. Just snap a photo of your
            meal and let AI identify every item on your plate — with full macro
            breakdowns for calories, protein, carbs, and fat.
          </p>

          <h2 className="text-2xl font-bold mb-4">How It Works: 3-Tier AI Recognition</h2>
          <p className="text-gray-400 leading-relaxed mb-8">
            Macro Maxxing uses a sophisticated 3-tier AI system that balances
            speed, accuracy, and cost. Most foods are recognized instantly on
            your device — complex meals fall through to more powerful cloud AI.
          </p>

          <div className="space-y-6 mb-12">
            <div className="bg-brand-card rounded-xl p-6 border border-white/5 relative overflow-hidden">
              <div className="absolute top-0 left-0 w-1 h-full bg-brand-green" />
              <div className="pl-4">
                <p className="text-brand-green text-xs font-semibold mb-1">TIER 1 — FASTEST</p>
                <h3 className="text-lg font-semibold text-white mb-2">
                  On-Device Vision AI + USDA Lookup
                </h3>
                <p className="text-gray-400 text-sm">
                  Uses Apple&apos;s Vision framework to classify food directly on
                  your device. Matches results against the USDA FoodData Central
                  database. Zero latency, no API costs, works offline.
                </p>
              </div>
            </div>

            <div className="bg-brand-card rounded-xl p-6 border border-white/5 relative overflow-hidden">
              <div className="absolute top-0 left-0 w-1 h-full bg-brand-purple" />
              <div className="pl-4">
                <p className="text-brand-purple text-xs font-semibold mb-1">TIER 2 — BALANCED</p>
                <h3 className="text-lg font-semibold text-white mb-2">
                  Claude Haiku + Multi-Database Cross-Reference
                </h3>
                <p className="text-gray-400 text-sm">
                  For complex or mixed plates, the photo is sent to Claude
                  Haiku — a fast, cost-effective AI model. Results are
                  cross-referenced with FatSecret and OpenFoodFacts for maximum
                  accuracy.
                </p>
              </div>
            </div>

            <div className="bg-brand-card rounded-xl p-6 border border-white/5 relative overflow-hidden">
              <div className="absolute top-0 left-0 w-1 h-full bg-brand-gold" />
              <div className="pl-4">
                <p className="text-brand-gold text-xs font-semibold mb-1">TIER 3 — MOST ACCURATE</p>
                <h3 className="text-lg font-semibold text-white mb-2">
                  Claude Sonnet Deep Analysis
                </h3>
                <p className="text-gray-400 text-sm">
                  For the most challenging foods — homemade recipes,
                  international cuisines, or highly mixed plates — Claude Sonnet
                  provides detailed analysis with portion estimation and
                  cooking method consideration.
                </p>
              </div>
            </div>
          </div>

          <h2 className="text-2xl font-bold mb-4">Why Photo Scanning Beats Manual Entry</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-12">
            {[
              { stat: "5x faster", desc: "than typing and searching a database" },
              { stat: "4 databases", desc: "USDA, FatSecret, OpenFoodFacts, AI" },
              { stat: "Mixed plates", desc: "AI identifies multiple items at once" },
              { stat: "Save & reuse", desc: "Save scanned meals as templates" },
            ].map((item, i) => (
              <div key={i} className="bg-brand-card rounded-xl p-5 border border-white/5 text-center">
                <p className="text-brand-purple font-bold text-xl mb-1">{item.stat}</p>
                <p className="text-gray-400 text-sm">{item.desc}</p>
              </div>
            ))}
          </div>

          <h2 className="text-2xl font-bold mb-4">Saved Meals for Quick Re-Logging</h2>
          <p className="text-gray-400 leading-relaxed mb-4">
            Eat the same breakfast every morning? Save it as a template. Next
            time, just tap your saved meal — banana, orange, protein shake,
            whatever it is — and it&apos;s logged in one tap with the thumbnail
            from your original photo.
          </p>
          <p className="text-gray-400 leading-relaxed mb-8">
            Your saved meals show the food name, calorie count, and portion
            count right on the chip, so you always know exactly what you&apos;re
            logging.
          </p>

          <h2 className="text-2xl font-bold mb-4">
            Works with Any Cuisine, Any Meal
          </h2>
          <p className="text-gray-400 leading-relaxed">
            Whether it&apos;s a classic rice and ground turkey plate, a complex
            curry, sushi, a smoothie bowl, or a loaded burrito — the AI handles
            it. The 3-tier system means even challenging foods get identified
            accurately.
          </p>
        </div>
      </article>

      <DownloadCTA
        headline="Ready to ditch manual food entry?"
        subheadline="Download Macro Maxxing and start scanning your meals with AI."
      />
    </>
  );
}
