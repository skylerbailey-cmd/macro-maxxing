import { Metadata } from "next";
import { ArticleJsonLd } from "@/components/JsonLd";
import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Muscle Building Nutrition Tracker — Bulk & Build Lean Muscle | Macro Maxxing",
  description:
    "Track your bulking macros with AI precision. Macro Maxxing helps you hit your calorie surplus and protein goals for muscle growth with photo scanning, voice logging, streaks, and a community of lifters.",
  keywords: [
    "muscle building nutrition app",
    "bulking macro tracker",
    "bodybuilding nutrition app",
    "muscle gain diet tracker",
    "lean bulk app",
    "bodybuilding calorie tracker",
    "mass gaining app",
    "gym nutrition tracker",
    "muscle building diet app",
    "bulking calorie counter",
  ],
};

export default function MuscleBuildingNutritionPage() {
  return (
    <>
      <ArticleJsonLd
        title="Muscle Building Nutrition Tracker — Bulk & Build Lean Muscle"
        description="Track your bulking macros with AI precision. Hit your calorie surplus and protein goals for muscle growth."
        url="https://macromaxxing.app/muscle-building-nutrition"
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-purple/20 via-dark to-brand-teal/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-purple/20 text-brand-purple text-sm font-semibold mb-6">
              MUSCLE BUILDING
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              Build Muscle with{" "}
              <span className="text-gradient">Precision Nutrition</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-8">
              You can&apos;t out-train a bad diet. Macro Maxxing tracks your
              bulking calories and protein with AI precision — just snap a photo
              or say what you ate. Build streaks, earn XP, and compete with
              other lifters on the leaderboard.
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-purple hover:bg-brand-purple/80 text-white font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Start Building — Free
            </a>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Nutrition Is 80% of Muscle Building
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            Training provides the stimulus, but nutrition provides the raw
            materials. Without adequate calories and protein, you won&apos;t grow —
            period. A calorie surplus of 200-400 kcal combined with 1-1.2g
            protein per pound of bodyweight is the sweet spot for lean muscle
            gain.
          </p>
          <p className="text-gray-300 text-lg">
            Macro Maxxing makes tracking your bulk effortless. AI scans your
            food photos and uses Claude AI (Haiku and Sonnet) to give you
            accurate macros. Smart workout adjustments ensure your daily targets
            account for training days vs rest days.
          </p>
        </section>

        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-5xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
              Features for Lifters
            </h2>
            <div className="grid md:grid-cols-3 gap-6">
              <FeatureCard
                icon="📸"
                title="AI Meal Scanning"
                description="Photo your meal — AI calculates protein, carbs, fat, and total calories. Works with meal prep, restaurants, and homemade food."
                color="brand-purple"
              />
              <FeatureCard
                icon="🏋️"
                title="Workout Macro Adjustments"
                description="Log a strength session and your daily macros adjust automatically. More carbs and protein on training days, maintenance on rest days."
                color="brand-teal"
              />
              <FeatureCard
                icon="🎤"
                title="Voice Logging"
                description="Post-workout, just say 'protein shake, two scoops, with a banana and oats' — AI logs everything while you recover."
                color="brand-gold"
              />
              <FeatureCard
                icon="🔥"
                title="Bulking Streaks"
                description="Build a streak by hitting your calorie surplus every day. Consistency is everything in a bulk — streaks keep you disciplined."
                color="brand-orange"
              />
              <FeatureCard
                icon="🏆"
                title="Lifter Leaderboard"
                description="Compete with other lifters on the leaderboard. Earn Aura XP for hitting protein targets, logging workouts, and maintaining streaks."
                color="brand-green"
              />
              <FeatureCard
                icon="👥"
                title="Gym Community"
                description="Share meals and progress on the social feed. Follow other lifters, swap recipes, and hold each other accountable during your bulk."
              />
            </div>
          </div>
        </section>

        {/* Bulking Protocols */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-8">
            Bulking Protocols You Can Track
          </h2>
          <div className="space-y-6">
            {[
              {
                name: "Lean Bulk",
                surplus: "+200-300 kcal",
                protein: "1g/lb",
                desc: "Slow, controlled surplus that minimizes fat gain. Ideal for experienced lifters who want to stay relatively lean while adding muscle.",
              },
              {
                name: "Standard Bulk",
                surplus: "+400-500 kcal",
                protein: "1g/lb",
                desc: "Moderate surplus for optimal muscle growth. The most common approach that balances muscle gain with manageable fat gain.",
              },
              {
                name: "Aggressive Bulk",
                surplus: "+600-800 kcal",
                protein: "1-1.2g/lb",
                desc: "Larger surplus for beginners or hardgainers who struggle to eat enough. Maximize muscle growth at the cost of some extra fat gain.",
              },
              {
                name: "Body Recomposition",
                surplus: "Maintenance",
                protein: "1.2g/lb",
                desc: "Eat at maintenance while training hard. Build muscle and lose fat simultaneously. Best for intermediate lifters or those returning from a break.",
              },
            ].map((protocol) => (
              <div
                key={protocol.name}
                className="bg-white/5 border border-white/10 rounded-2xl p-6"
              >
                <div className="flex flex-wrap gap-3 mb-3">
                  <h3 className="text-xl font-bold text-white">
                    {protocol.name}
                  </h3>
                  <span className="px-3 py-1 rounded-full bg-brand-purple/20 text-brand-purple text-sm font-mono">
                    {protocol.surplus}
                  </span>
                  <span className="px-3 py-1 rounded-full bg-brand-teal/20 text-brand-teal text-sm font-mono">
                    {protocol.protein} protein
                  </span>
                </div>
                <p className="text-gray-300">{protocol.desc}</p>
              </div>
            ))}
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
                  q: "What is the best nutrition app for building muscle?",
                  a: "Macro Maxxing is the best free nutrition app for building muscle. It uses AI photo scanning to track calories and protein effortlessly, automatically adjusts macros on training days, and keeps you consistent with daily streaks, Aura XP leaderboards, and a social community of lifters.",
                },
                {
                  q: "How many calories should I eat to build muscle?",
                  a: "To build muscle, eat 200-500 calories above your maintenance level (TDEE). A lean bulk uses a smaller surplus (+200-300) to minimize fat gain, while a standard bulk uses +400-500 for faster muscle growth. Macro Maxxing helps you track your surplus precisely with AI food scanning.",
                },
                {
                  q: "How much protein do I need to build muscle?",
                  a: "Research consistently shows 0.8-1.2 grams of protein per pound of bodyweight is optimal for muscle growth. Macro Maxxing puts protein tracking front and center and makes it easy to hit your daily target with AI-powered logging.",
                },
                {
                  q: "Does Macro Maxxing adjust macros for workout days?",
                  a: "Yes. When you log a workout in Macro Maxxing, your daily macro targets automatically adjust based on the type and intensity of your session. Strength training adds extra protein and carbs, while rest days use your baseline targets.",
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
            headline="Fuel Your Gains"
            subheadline="AI nutrition tracking built for lifters. Streaks, leaderboards, and a community of dedicated trackers. Free forever."
          />
        </div>
      </article>
    </>
  );
}
