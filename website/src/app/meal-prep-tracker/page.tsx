import { Metadata } from "next";
import { ArticleJsonLd } from "@/components/JsonLd";
import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Meal Prep Tracker — Save & Reuse Meals with AI Macros | Macro Maxxing",
  description:
    "Track meal prep macros effortlessly. Scan your prepped meals once with AI, save them as templates, and log them all week with one tap. Free meal prep tracker with streaks and community.",
  keywords: [
    "meal prep tracker app",
    "meal prep macro tracker",
    "meal planning app",
    "meal prep calorie counter",
    "save meals app",
    "meal template tracker",
    "weekly meal prep app",
    "batch cooking tracker",
    "meal prep nutrition tracker",
    "food prep app",
  ],
};

export default function MealPrepTrackerPage() {
  return (
    <>
      <ArticleJsonLd
        title="Meal Prep Tracker — Save & Reuse Meals with AI Macros"
        description="Track meal prep macros effortlessly. Scan once, save as a template, log all week with one tap."
        url="https://macromaxxing.com/meal-prep-tracker"
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-cyan/20 via-dark to-brand-purple/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-cyan/20 text-brand-cyan text-sm font-semibold mb-6">
              MEAL PREP
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              Scan Once, Log{" "}
              <span className="text-gradient">All Week</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-8">
              Meal prep is the ultimate hack for consistent nutrition. Macro
              Maxxing lets you scan your prepped meals once with AI, save them
              as templates, and log them in seconds all week. Build streaks and
              share your preps with the community.
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-cyan hover:bg-brand-cyan/80 text-dark font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Start Prepping Smarter — Free
            </a>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Why Meal Prep + Macro Tracking Is a Cheat Code
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            Meal prep eliminates daily decision fatigue. When your meals are
            already cooked and portioned, you don&apos;t have to think about
            what to eat — you just eat. Combine that with macro tracking and
            you have complete control over your nutrition with minimal daily
            effort.
          </p>
          <p className="text-gray-300 text-lg">
            The problem? Most tracking apps make you re-enter the same meals
            every day. Macro Maxxing&apos;s Saved Meals feature lets you scan
            a meal once, save it as a template, and log it with a single tap
            for the rest of the week.
          </p>
        </section>

        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-5xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
              How Meal Prep Tracking Works
            </h2>
            <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
              {[
                {
                  step: "1",
                  title: "Prep Your Meals",
                  desc: "Cook and portion your meals for the week like you normally would.",
                  color: "brand-cyan",
                },
                {
                  step: "2",
                  title: "Scan with AI",
                  desc: "Take a photo of each prepped meal. AI identifies ingredients and calculates macros.",
                  color: "brand-purple",
                },
                {
                  step: "3",
                  title: "Save as Template",
                  desc: "Save the scanned meal as a template with a custom name. It's stored permanently.",
                  color: "brand-gold",
                },
                {
                  step: "4",
                  title: "One-Tap Logging",
                  desc: "All week, just tap the saved meal to log it. Full macros, zero effort.",
                  color: "brand-green",
                },
              ].map((item) => (
                <div
                  key={item.step}
                  className="bg-white/5 border border-white/10 rounded-2xl p-6 text-center"
                >
                  <div
                    className={`w-12 h-12 mx-auto rounded-full bg-${item.color}/20 flex items-center justify-center text-${item.color} font-black text-xl mb-4`}
                  >
                    {item.step}
                  </div>
                  <h3 className="text-lg font-bold mb-2">{item.title}</h3>
                  <p className="text-gray-400 text-sm">{item.desc}</p>
                </div>
              ))}
            </div>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-5xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
            Meal Prep Features
          </h2>
          <div className="grid md:grid-cols-3 gap-6">
            <FeatureCard
              icon="💾"
              title="Saved Meal Templates"
              description="Save any scanned or logged meal as a reusable template. Name it, categorize it, and log it any time with one tap."
              color="brand-cyan"
            />
            <FeatureCard
              icon="📸"
              title="AI Batch Scanning"
              description="Scan multiple meal prep containers in sequence. Each one gets its own macro breakdown and can be saved independently."
              color="brand-purple"
            />
            <FeatureCard
              icon="🔄"
              title="Quick Re-Log"
              description="Your recent and saved meals are always accessible. Log yesterday's lunch again in under 2 seconds."
              color="brand-gold"
            />
            <FeatureCard
              icon="🔥"
              title="Prep Day Streaks"
              description="Build streaks by logging consistently. Meal prep makes streaks easy because your meals are already planned and ready."
              color="brand-orange"
            />
            <FeatureCard
              icon="👥"
              title="Share Your Preps"
              description="Post your meal prep to the community feed. Inspire others with your meal ideas and see what other preppers are cooking."
              color="brand-green"
            />
            <FeatureCard
              icon="🏆"
              title="Earn XP Faster"
              description="Meal preppers earn Aura XP quickly because consistent logging is easy. Climb the leaderboard by prepping smart."
              color="brand-teal"
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
                  q: "What is the best meal prep tracking app?",
                  a: "Macro Maxxing is the best free meal prep tracking app. It lets you scan prepped meals with AI, save them as reusable templates, and log them all week with one tap. It also features streaks, leaderboards, and a social community for accountability.",
                },
                {
                  q: "Can I save meals in Macro Maxxing and reuse them?",
                  a: "Yes. Macro Maxxing has a Saved Meals feature that lets you save any meal (scanned or manually entered) as a reusable template. You can log saved meals with a single tap, making it perfect for meal prep where you eat the same meals multiple times per week.",
                },
                {
                  q: "How does AI meal prep scanning work?",
                  a: "Take a photo of your prepped meal container. Macro Maxxing's 3-tier AI system identifies the ingredients, estimates portions, and calculates macros using data from 4 nutrition databases. You can then save the result as a meal template for future use.",
                },
                {
                  q: "Is Macro Maxxing good for weekly meal prep?",
                  a: "Macro Maxxing is ideal for weekly meal prep. Scan your meals once on prep day, save them as templates, and log them instantly throughout the week. Combined with daily streaks and community sharing, it makes meal prep tracking effortless.",
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
            headline="Meal Prep Like a Pro"
            subheadline="Scan once, log all week. AI-powered meal prep tracking with streaks and community. Free forever."
          />
        </div>
      </article>
    </>
  );
}
