import { Metadata } from "next";
import { ArticleJsonLd } from "@/components/JsonLd";
import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Gym Diet Plan Tracker — Track Your Training Diet with AI | Macromaxxing",
  description:
    "Track your gym diet plan with AI. Whether you're following a bodybuilding diet, powerlifting nutrition, or CrossFit macros, Macromaxxing tracks everything with photo scanning, voice logging, and smart workout adjustments.",
  keywords: [
    "gym diet plan app",
    "gym nutrition tracker",
    "bodybuilding diet tracker",
    "gym diet app",
    "fitness diet plan tracker",
    "gym meal tracker",
    "training diet app",
    "powerlifting nutrition app",
    "CrossFit nutrition tracker",
    "gym food tracker",
  ],
};

export default function GymDietPlanPage() {
  return (
    <>
      <ArticleJsonLd
        title="Gym Diet Plan Tracker — Track Your Training Diet with AI"
        description="Track your gym diet plan with AI photo scanning and voice logging. Smart workout macro adjustments."
        url="https://macromaxxing.app/gym-diet-plan"
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-green/20 via-dark to-brand-purple/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-green/20 text-brand-green text-sm font-semibold mb-6">
              GYM NUTRITION
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              Your Gym Diet,{" "}
              <span className="text-gradient">Tracked by AI</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-8">
              The gym is only half the battle. Macromaxxing is the nutrition
              app built for people who train — with smart workout macro
              adjustments, AI meal scanning, and a competitive community that
              keeps you locked in.
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-green hover:bg-brand-green/80 text-dark font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Track Your Gym Diet 
            </a>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Why Gym-Goers Need a Better Nutrition Tracker
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            Generic calorie counters don&apos;t understand training. They
            don&apos;t adjust your macros on leg day vs rest day. They
            don&apos;t know that you need more carbs before a heavy session and
            more protein after. Macromaxxing does.
          </p>
          <p className="text-gray-300 text-lg">
            Macromaxxing was built for people who train. It automatically
            adjusts your daily macros based on your workout type and intensity,
            so your nutrition always matches your training.
          </p>
        </section>

        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-5xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
              Built for Every Training Style
            </h2>
            <div className="grid md:grid-cols-3 gap-6">
              <FeatureCard
                icon="🏋️"
                title="Strength Training"
                description="Auto-adds protein and carbs on lifting days. Based on ISSN guidelines for resistance training nutrition."
                color="brand-purple"
              />
              <FeatureCard
                icon="🏃"
                title="Cardio & Endurance"
                description="Adjusts calories and carbs for cardio sessions. Whether it's running, cycling, or swimming — macros adapt."
                color="brand-green"
              />
              <FeatureCard
                icon="⚡"
                title="HIIT & CrossFit"
                description="High-intensity sessions burn serious calories. Macromaxxing accounts for the intensity and duration in your daily targets."
                color="brand-gold"
              />
              <FeatureCard
                icon="🧘"
                title="Yoga & Flexibility"
                description="Lower-impact sessions get appropriate adjustments. Not every day is a high-calorie training day."
                color="brand-teal"
              />
              <FeatureCard
                icon="😴"
                title="Rest Days"
                description="Rest day macros stay at your baseline. Recovery is part of the plan, and your nutrition should reflect it."
                color="brand-cyan"
              />
              <FeatureCard
                icon="🎤"
                title="Voice Workout Logging"
                description="Say 'upper body push, 60 minutes, heavy' and the AI logs your workout and adjusts your macros automatically."
                color="brand-orange"
              />
            </div>
          </div>
        </section>

        {/* Common Gym Diets */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-8">
            Popular Gym Diet Plans You Can Track
          </h2>
          <div className="space-y-6">
            {[
              {
                name: "Classic Bodybuilding",
                desc: "High protein, moderate carbs, moderate fat. The time-tested approach to building muscle and staying lean. Cycle between bulk and cut phases.",
                split: "40% Protein / 35% Carbs / 25% Fat",
              },
              {
                name: "Powerlifting Nutrition",
                desc: "Higher calories to fuel heavy lifts. Prioritize carbs for energy and protein for recovery. Fat is flexible based on preference.",
                split: "30% Protein / 45% Carbs / 25% Fat",
              },
              {
                name: "CrossFit / Zone Diet",
                desc: "Balanced macro split for varied training. Enough carbs for WODs, enough protein for muscle preservation, enough fat for hormones.",
                split: "30% Protein / 40% Carbs / 30% Fat",
              },
              {
                name: "Keto for Athletes",
                desc: "High fat, very low carb, moderate protein. Some athletes prefer keto for endurance and body composition. Macromaxxing tracks net carbs too.",
                split: "25% Protein / 5% Carbs / 70% Fat",
              },
            ].map((diet) => (
              <div
                key={diet.name}
                className="bg-white/5 border border-white/10 rounded-2xl p-6"
              >
                <h3 className="text-xl font-bold text-white mb-2">
                  {diet.name}
                </h3>
                <p className="text-gray-300 mb-3">{diet.desc}</p>
                <span className="inline-block px-3 py-1 rounded-full bg-brand-green/20 text-brand-green text-sm font-mono">
                  {diet.split}
                </span>
              </div>
            ))}
          </div>
        </section>

        {/* Accountability */}
        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-4xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold text-center mb-6">
              The Gym Community That Keeps You{" "}
              <span className="text-gradient-gold">Accountable</span>
            </h2>
            <p className="text-gray-300 text-lg text-center max-w-2xl mx-auto mb-12">
              Macromaxxing isn&apos;t just a tracker — it&apos;s a community
              of people who train. Build streaks, compete on leaderboards, and share
              your gym meals with people who get it.
            </p>
            <div className="grid md:grid-cols-3 gap-6">
              <div className="text-center p-6 bg-white/5 border border-white/10 rounded-2xl">
                <div className="text-4xl mb-3">🔥</div>
                <h3 className="font-bold mb-2">Training Streaks</h3>
                <p className="text-gray-400 text-sm">
                  Log meals and workouts daily to build streaks. Your streak
                  is your discipline badge.
                </p>
              </div>
              <div className="text-center p-6 bg-white/5 border border-white/10 rounded-2xl">
                <div className="text-4xl mb-3">🏆</div>
                <h3 className="font-bold mb-2">Leaderboard</h3>
                <p className="text-gray-400 text-sm">
                  Compete with other gym-goers for the top spot. Earn XP for
                  every action — the grind pays off.
                </p>
              </div>
              <div className="text-center p-6 bg-white/5 border border-white/10 rounded-2xl">
                <div className="text-4xl mb-3">👥</div>
                <h3 className="font-bold mb-2">Gym Feed</h3>
                <p className="text-gray-400 text-sm">
                  Share meals, PRs, and progress. Follow gym partners and hold
                  each other accountable.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* FAQ */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-8">
            Frequently Asked Questions
          </h2>
          <div className="space-y-6">
            {[
              {
                q: "What is the best nutrition tracker for the gym?",
                a: "Macromaxxing is the best nutrition tracker for gym-goers. It automatically adjusts your macros based on your workout type (strength, cardio, HIIT, rest), uses AI for instant food scanning, and includes streaks, leaderboards, and a social community for accountability.",
              },
              {
                q: "Should I eat more on training days?",
                a: "Yes. On training days, your body needs more calories (especially carbs for energy and protein for recovery). Macromaxxing automatically adjusts your daily macro targets when you log a workout, so you always eat the right amount for your activity level.",
              },
              {
                q: "How do I track gym nutrition without spending hours?",
                a: "Use Macromaxxing's AI photo scanning or voice logging. Take a photo of your meal or say what you ate — AI calculates macros instantly. Combined with saved meal templates for meal prep, most users spend less than 2 minutes per day tracking.",
              },
              {
                q: "Does Macromaxxing work for bodybuilding, powerlifting, and CrossFit?",
                a: "Yes. Macromaxxing supports any training style. It adjusts macros based on workout type and intensity, tracks all macros (calories, protein, carbs, fat), and lets you customize your macro split for your specific diet approach.",
              },
            ].map((faq) => (
              <div
                key={faq.q}
                className="bg-white/5 border border-white/10 rounded-2xl p-6"
              >
                <h3 className="text-lg font-bold text-white mb-2">{faq.q}</h3>
                <p className="text-gray-300">{faq.a}</p>
              </div>
            ))}
          </div>
        </section>

        <div id="download">
          <DownloadCTA
            headline="Fuel Your Training"
            subheadline="AI nutrition tracking with smart workout adjustments, streaks, and a gym community. Download now."
          />
        </div>
      </article>
    </>
  );
}
