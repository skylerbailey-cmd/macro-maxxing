import type { Metadata } from "next";
import { DownloadCTA } from "@/components/DownloadCTA";
import { ArticleJsonLd, BreadcrumbJsonLd } from "@/components/JsonLd";

export const metadata: Metadata = {
  title: "AI Food Scanner — Snap a Photo, Get Instant Macros",
  description:
    "Macro Maxxing's AI food scanner uses Claude Haiku and Sonnet to identify food and estimate calories, protein, carbs, and fat from a single photo. Available on iOS.",
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
        description="How Macro Maxxing's AI food recognition powered by Claude Haiku and Sonnet identifies food from photos and estimates macros instantly."
        url="https://macromaxxing.app/ai-food-scanner"
      />
      <BreadcrumbJsonLd
        items={[
          { name: "Home", url: "https://macromaxxing.app" },
          { name: "AI Food Scanner", url: "https://macromaxxing.app/ai-food-scanner" },
        ]}
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
          <p className="text-gray-300 text-lg leading-relaxed mb-4">
            An AI food scanner is a mobile app feature that uses artificial
            intelligence to identify food items from a photo and estimate their
            nutritional content including calories, protein, carbs, and fat.
            Macro Maxxing&apos;s AI food scanner is powered by Claude AI (Haiku
            and Sonnet models) to analyze your food and estimate accurate
            macro data.
          </p>
          <p className="text-gray-500 text-sm mb-12">Last updated: March 2026</p>

          <h2 className="text-2xl font-bold mb-4">How It Works: AI-Powered Recognition</h2>
          <p className="text-gray-400 leading-relaxed mb-8">
            Macro Maxxing uses Claude AI models exclusively for food recognition,
            powered by Anthropic. Simple foods are handled by fast Claude Haiku —
            complex meals get the full power of Claude Sonnet.
          </p>

          <div className="space-y-6 mb-12">
            <div className="bg-brand-card rounded-xl p-6 border border-white/5 relative overflow-hidden">
              <div className="absolute top-0 left-0 w-1 h-full bg-brand-green" />
              <div className="pl-4">
                <p className="text-brand-green text-xs font-semibold mb-1">FAST &amp; EFFICIENT</p>
                <h3 className="text-lg font-semibold text-white mb-2">
                  Claude Haiku — Quick Scan
                </h3>
                <p className="text-gray-400 text-sm">
                  Simple, single-ingredient foods are handled by Claude Haiku —
                  Anthropic&apos;s fastest model. Get accurate macros in under a second.
                </p>
              </div>
            </div>

            <div className="bg-brand-card rounded-xl p-6 border border-white/5 relative overflow-hidden">
              <div className="absolute top-0 left-0 w-1 h-full bg-brand-purple" />
              <div className="pl-4">
                <p className="text-brand-purple text-xs font-semibold mb-1">CLAUDE HAIKU — BALANCED</p>
                <h3 className="text-lg font-semibold text-white mb-2">
                  Claude Haiku AI Recognition
                </h3>
                <p className="text-gray-400 text-sm">
                  For complex or mixed plates, the photo is sent to Claude
                  Haiku — a fast, cost-effective AI model by Anthropic that
                  identifies foods and estimates macros with high accuracy.
                </p>
              </div>
            </div>

            <div className="bg-brand-card rounded-xl p-6 border border-white/5 relative overflow-hidden">
              <div className="absolute top-0 left-0 w-1 h-full bg-brand-gold" />
              <div className="pl-4">
                <p className="text-brand-gold text-xs font-semibold mb-1">CLAUDE SONNET — MOST ACCURATE</p>
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
              { stat: "Haiku + Sonnet", desc: "Dual-model AI analysis" },
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
            it. Claude AI means even challenging foods get identified
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
