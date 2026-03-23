import { Metadata } from "next";
import { ArticleJsonLd } from "@/components/JsonLd";
import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Best Free Weight Loss App — AI Calorie & Macro Tracker | Macro Maxxing",
  description:
    "Lose weight with the easiest calorie and macro tracker. Macro Maxxing uses AI photo scanning, voice logging, and gamified streaks to help you stay in a deficit and reach your goal weight. Free with social accountability.",
  keywords: [
    "weight loss app",
    "free weight loss app",
    "best weight loss app",
    "calorie deficit app",
    "weight loss tracker",
    "diet app for weight loss",
    "fat loss app",
    "weight loss calorie counter",
    "lose weight app",
    "AI weight loss app",
  ],
};

export default function WeightLossAppPage() {
  return (
    <>
      <ArticleJsonLd
        title="Best Free Weight Loss App — AI Calorie & Macro Tracker"
        description="Lose weight with the easiest calorie and macro tracker. AI photo scanning, voice logging, and gamified accountability."
        url="https://macromaxxing.app/weight-loss-app"
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-orange/20 via-dark to-brand-gold/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-orange/20 text-brand-orange text-sm font-semibold mb-6">
              WEIGHT LOSS
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              The Weight Loss App That{" "}
              <span className="text-gradient-gold">Actually Works</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-8">
              Weight loss comes down to one thing: a consistent calorie deficit.
              Macro Maxxing makes tracking effortless with AI food scanning and
              keeps you consistent with streaks, leaderboards, and a community
              that holds you accountable.
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-orange hover:bg-brand-orange/80 text-dark font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Start Losing Weight — Free
            </a>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Why Tracking Calories Is the #1 Weight Loss Strategy
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            A meta-analysis published in the journal Obesity found that people
            who track their food intake lose <strong>twice as much weight</strong>{" "}
            as those who don&apos;t. The problem isn&apos;t knowledge — most people know
            they need a calorie deficit. The problem is consistency. Traditional
            tracking apps are too tedious, so people quit after a week or two.
          </p>
          <p className="text-gray-300 text-lg">
            Macro Maxxing solves this with AI-powered logging (photo or voice —
            no manual searching) and gamification that makes tracking feel
            rewarding instead of like homework.
          </p>
        </section>

        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-5xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
              How Macro Maxxing Helps You Lose Weight
            </h2>
            <div className="grid md:grid-cols-3 gap-6">
              <FeatureCard
                icon="📸"
                title="AI Calorie Scanning"
                description="Photo your meal — AI calculates calories and macros instantly. No manual entry, no barcode scanning, no food scale required."
                color="brand-orange"
              />
              <FeatureCard
                icon="🎯"
                title="Deficit Tracking"
                description="Set your calorie target based on your goal. Macro Maxxing tracks every meal against your target so you always know where you stand."
                color="brand-purple"
              />
              <FeatureCard
                icon="💪"
                title="Protein Protection"
                description="Lose fat, not muscle. Track protein to ensure you're eating enough to preserve lean mass during your deficit. Macro Maxxing puts protein front and center."
                color="brand-teal"
              />
              <FeatureCard
                icon="🔥"
                title="Daily Streaks"
                description="Build a streak by logging every day. Your streak is your commitment visualized. The longer it goes, the harder it is to break."
                color="brand-gold"
              />
              <FeatureCard
                icon="🏆"
                title="Leaderboard Motivation"
                description="Compete on weekly leaderboards by earning Aura XP. Friendly competition keeps you motivated when willpower fades."
                color="brand-green"
              />
              <FeatureCard
                icon="👥"
                title="Accountability Community"
                description="Share progress on the social feed. Follow friends on the same journey. When others are watching, you stay on track."
              />
            </div>
          </div>
        </section>

        {/* Weight Loss Without the Misery */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Weight Loss Without the Misery
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            Most weight loss apps feel like punishment. Endless database
            searches, guilt-tripping notifications, and boring spreadsheets.
            Macro Maxxing takes the opposite approach — it makes tracking fast
            (AI does the work), fun (streaks and XP), and social (community
            feed).
          </p>
          <div className="bg-white/5 border border-white/10 rounded-2xl p-6 md:p-8">
            <h3 className="text-xl font-bold mb-4">
              The Macro Maxxing Weight Loss Approach
            </h3>
            <div className="space-y-4">
              {[
                "Set a moderate calorie deficit (300-500 kcal below maintenance)",
                "Prioritize protein (1g per lb bodyweight) to preserve muscle",
                "Log every meal with AI photo scanning or voice — takes seconds",
                "Build a daily logging streak for consistency",
                "Use the community feed for accountability and motivation",
                "Earn Aura XP and climb the leaderboard as you stay consistent",
                "Adjust workout macros automatically when you train",
              ].map((step, i) => (
                <div key={i} className="flex gap-3 items-start">
                  <span className="flex-shrink-0 w-6 h-6 rounded-full bg-brand-orange/20 text-brand-orange flex items-center justify-center text-sm font-bold">
                    {i + 1}
                  </span>
                  <p className="text-gray-300">{step}</p>
                </div>
              ))}
            </div>
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
                  q: "What is the best free app for weight loss?",
                  a: "Macro Maxxing is a 100% free weight loss app that uses AI to track calories and macros from food photos or voice descriptions. It includes daily streaks, Aura XP leaderboards, and a social community for accountability — all features that help you maintain a consistent calorie deficit.",
                },
                {
                  q: "How do I lose weight with a calorie tracking app?",
                  a: "Set a daily calorie target 300-500 calories below your maintenance level. Log every meal using Macro Maxxing's AI photo scanner or voice logging. Prioritize protein (1g/lb bodyweight) to preserve muscle. Build a daily logging streak for consistency and use the social feed for accountability.",
                },
                {
                  q: "Do weight loss apps with gamification work better?",
                  a: "Yes. Research shows that gamified health apps have significantly higher retention rates. Macro Maxxing uses streaks, Aura XP, and leaderboards to make tracking feel like a game rather than a chore. Users who maintain streaks are more likely to sustain their calorie deficit long-term.",
                },
                {
                  q: "Can I track weight loss with Macro Maxxing for free?",
                  a: "Yes. Macro Maxxing is completely free with no premium tier or subscription. All features including AI food scanning, voice logging, workout tracking, streaks, leaderboards, and the social community are available at no cost.",
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
            headline="Start Your Weight Loss Journey Today"
            subheadline="AI calorie tracking, daily streaks, leaderboards, and a community to keep you accountable. 100% free."
          />
        </div>
      </article>
    </>
  );
}
