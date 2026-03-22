import { Metadata } from "next";
import { ArticleJsonLd } from "@/components/JsonLd";
import FeatureCard from "@/components/FeatureCard";
import DownloadCTA from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Accountability Partner App for Diet & Fitness | Macro Maxxing",
  description:
    "Find accountability for your diet and fitness goals. Macro Maxxing combines AI macro tracking with streaks, leaderboards, and a social community that acts as your built-in accountability partner. Free.",
  keywords: [
    "accountability partner app",
    "diet accountability app",
    "fitness accountability app",
    "accountability tracker",
    "habit streak app",
    "diet buddy app",
    "fitness partner app",
    "accountability for weight loss",
    "social accountability app",
    "habit tracker with friends",
  ],
};

export default function AccountabilityPartnerPage() {
  return (
    <>
      <ArticleJsonLd
        title="Accountability Partner App for Diet & Fitness"
        description="Find accountability for your diet and fitness goals with streaks, leaderboards, and a social community."
        url="https://macromaxxing.com/accountability-partner-app"
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-rose/20 via-dark to-brand-gold/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-rose/20 text-brand-rose text-sm font-semibold mb-6">
              ACCOUNTABILITY
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              Your Diet Accountability Partner{" "}
              <span className="text-gradient">Lives in Your Phone</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-8">
              You don&apos;t need willpower. You need accountability. Macro
              Maxxing combines AI macro tracking with daily streaks, public
              leaderboards, and a social community — creating a built-in
              accountability system that keeps you consistent.
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-rose hover:bg-brand-rose/80 text-white font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Get Accountable — Free
            </a>
          </div>
        </section>

        {/* The Accountability Problem */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Why Willpower Alone Doesn&apos;t Work
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            A study from the American Society of Training and Development found
            that you have a <strong>65% chance</strong> of completing a goal if
            you commit to someone else. That number jumps to{" "}
            <strong>95%</strong> if you have a specific accountability
            appointment with a partner.
          </p>
          <p className="text-gray-300 text-lg mb-6">
            The problem is that finding a reliable accountability partner is
            hard. Schedules don&apos;t align, motivation levels differ, and
            life gets in the way.
          </p>
          <p className="text-gray-300 text-lg">
            Macro Maxxing solves this by building accountability directly into
            your nutrition tracker. Streaks create self-accountability.
            Leaderboards create competitive accountability. The social feed
            creates community accountability. You&apos;re never dieting alone.
          </p>
        </section>

        {/* 3 Layers of Accountability */}
        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-5xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
              3 Layers of Accountability
            </h2>
            <div className="grid md:grid-cols-3 gap-8">
              <div className="bg-white/5 border border-white/10 rounded-2xl p-8 text-center">
                <div className="text-5xl mb-4">🔥</div>
                <h3 className="text-2xl font-bold mb-3 text-brand-gold">
                  Self
                </h3>
                <p className="text-gray-300 text-lg mb-4">Daily Streaks</p>
                <p className="text-gray-400">
                  Your streak is your personal commitment visualized. Every day
                  you log, the number grows. Every day you skip, it resets.
                  Simple, powerful, and deeply motivating once you&apos;ve built
                  momentum.
                </p>
              </div>
              <div className="bg-white/5 border border-white/10 rounded-2xl p-8 text-center">
                <div className="text-5xl mb-4">🏆</div>
                <h3 className="text-2xl font-bold mb-3 text-brand-purple">
                  Competitive
                </h3>
                <p className="text-gray-300 text-lg mb-4">Leaderboards</p>
                <p className="text-gray-400">
                  See how you stack up against other users. Weekly and all-time
                  leaderboards ranked by Aura XP. When you see someone ahead
                  of you, you&apos;re motivated to close the gap.
                </p>
              </div>
              <div className="bg-white/5 border border-white/10 rounded-2xl p-8 text-center">
                <div className="text-5xl mb-4">👥</div>
                <h3 className="text-2xl font-bold mb-3 text-brand-green">
                  Social
                </h3>
                <p className="text-gray-300 text-lg mb-4">Community Feed</p>
                <p className="text-gray-400">
                  Follow friends and fellow fitness enthusiasts. Share meals
                  and milestones. When your community is watching, you stay
                  accountable because you don&apos;t want to let them (or
                  yourself) down.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* Features */}
        <section className="py-16 md:py-20 max-w-5xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
            Accountability Features
          </h2>
          <div className="grid md:grid-cols-3 gap-6">
            <FeatureCard
              icon="📱"
              title="Social Feed"
              description="A real-time feed of meals, milestones, and streak celebrations from people you follow. Stay inspired and hold each other accountable."
              color="brand-green"
            />
            <FeatureCard
              icon="🔔"
              title="Streak Reminders"
              description="Get a gentle nudge if you haven't logged today. Your streak is at stake — one notification can save a 30-day streak."
              color="brand-gold"
            />
            <FeatureCard
              icon="🎉"
              title="Milestone Posts"
              description="Hit a streak milestone? It automatically appears on the feed. Your community celebrates with you, reinforcing the habit."
              color="brand-purple"
            />
            <FeatureCard
              icon="📊"
              title="Public Profiles"
              description="Your streak, XP, and rank are visible to followers. This public commitment creates social pressure to stay consistent."
              color="brand-teal"
            />
            <FeatureCard
              icon="🤝"
              title="Follow Friends"
              description="Follow gym partners, friends, or fitness creators. See their progress and let them see yours. Mutual accountability is the strongest kind."
              color="brand-rose"
            />
            <FeatureCard
              icon="⚡"
              title="Aura XP Tracking"
              description="Every logged meal, every target hit, every streak day earns you XP. Your total XP is your discipline score — visible to everyone."
              color="brand-orange"
            />
          </div>
        </section>

        {/* Why it works */}
        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-4xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold mb-6">
              Why Gamified Accountability Works
            </h2>
            <p className="text-gray-300 text-lg mb-6">
              Gamification taps into the same psychological triggers that make
              video games addictive — progress visualization, achievement
              systems, social status, and loss aversion. When applied to
              nutrition tracking:
            </p>
            <div className="space-y-4">
              {[
                "Streaks create loss aversion — you don't want to lose your progress",
                "XP creates a sense of progress and achievement with every action",
                "Leaderboards create healthy competition that drives consistency",
                "The social feed creates social proof — seeing others succeed motivates you",
                "Public commitments increase follow-through by up to 95%",
              ].map((point, i) => (
                <div key={i} className="flex gap-3 items-start">
                  <span className="text-brand-rose mt-1">●</span>
                  <p className="text-gray-300">{point}</p>
                </div>
              ))}
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
                q: "What is the best accountability app for dieting?",
                a: "Macro Maxxing is the best free accountability app for dieting. It combines AI-powered macro tracking with three layers of accountability: daily streaks (self-accountability), leaderboards (competitive accountability), and a social community feed (social accountability). All features are free.",
              },
              {
                q: "How do accountability partners help with weight loss?",
                a: "Research shows that having accountability increases goal completion rates from 10% (going solo) to 95% (regular accountability). Macro Maxxing builds accountability into the app through public streaks, leaderboards, and a social feed — so you always have accountability without needing to coordinate with another person.",
              },
              {
                q: "Can I use Macro Maxxing with friends for accountability?",
                a: "Yes. Follow your friends in Macro Maxxing to see their meals, streaks, and leaderboard positions. They can see yours too. This creates mutual accountability that keeps both of you on track with your nutrition goals.",
              },
              {
                q: "Do streaks and leaderboards really help with diet consistency?",
                a: "Yes. Gamification mechanics like streaks and leaderboards leverage psychological principles (loss aversion, social comparison, achievement motivation) that significantly improve consistency. Users who maintain streaks in fitness apps show dramatically higher long-term retention.",
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
            headline="Get the Accountability You Need"
            subheadline="Streaks, leaderboards, and a social community built into your macro tracker. Never diet alone again. Free."
          />
        </div>
      </article>
    </>
  );
}
