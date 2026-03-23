import { Metadata } from "next";
import { ArticleJsonLd } from "@/components/JsonLd";
import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title:
    "Streaks, Leaderboards & Gamified Macro Tracking | Macro Maxxing",
  description:
    "Turn nutrition tracking into a game. Macro Maxxing features daily streaks, Aura XP points, leaderboards, and a social feed that keeps you accountable and motivated every single day.",
  keywords: [
    "gamified macro tracker",
    "nutrition streaks app",
    "fitness leaderboard app",
    "gamified calorie counter",
    "streak tracker app",
    "fitness gamification",
    "XP fitness app",
    "accountability app for diet",
    "macro tracker with streaks",
    "competitive fitness app",
  ],
};

export default function StreaksAndGamificationPage() {
  return (
    <>
      <ArticleJsonLd
        title="Streaks, Leaderboards & Gamified Macro Tracking"
        description="Turn nutrition tracking into a game with daily streaks, Aura XP, and competitive leaderboards."
        url="https://macromaxxing.app/streaks-and-gamification"
      />

      <article className="min-h-screen">
        {/* Hero */}
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-gold/20 via-dark to-brand-purple/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-gold/20 text-brand-gold text-sm font-semibold mb-6">
              GAMIFICATION
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              Tracking Macros Should Feel Like a{" "}
              <span className="text-gradient-gold">Game</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-8">
              Most nutrition apps are boring spreadsheets. Macro Maxxing turns
              tracking into a game with daily streaks, Aura XP, leaderboards,
              and a social community — so you actually stick with it.
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-gold hover:bg-brand-gold/80 text-dark font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Start Playing — Free
            </a>
          </div>
        </section>

        {/* The Problem */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Why Most People Quit Tracking After 2 Weeks
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            Research shows that 90% of people who start tracking calories quit
            within the first month. The reason? Traditional tracking apps feel
            like a chore. Searching databases, weighing food, and entering
            numbers manually is tedious and unrewarding.
          </p>
          <p className="text-gray-300 text-lg mb-6">
            Macro Maxxing solves this with two key innovations:{" "}
            <strong>AI-powered logging</strong> that eliminates the tedious
            data entry, and <strong>gamification</strong> that makes tracking
            genuinely fun and addictive — in a good way.
          </p>
        </section>

        {/* How Gamification Works */}
        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-5xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold text-center mb-4">
              How the <span className="text-gradient-gold">Game</span> Works
            </h2>
            <p className="text-gray-400 text-center max-w-2xl mx-auto mb-12">
              Every action earns you Aura XP. Your XP determines your rank on
              the leaderboard. Your streak proves your consistency.
            </p>
            <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
              <FeatureCard
                icon="🔥"
                title="Daily Streaks"
                description="Log at least one meal every day to keep your streak alive. Your streak count is displayed on your profile and the community feed for everyone to see."
                color="brand-gold"
              />
              <FeatureCard
                icon="✨"
                title="Aura XP"
                description="Earn XP for every meal logged (+10), protein target hit (+25), workout logged (+15), and streak milestone (+50 at 7 days, +100 at 30 days)."
                color="brand-purple"
              />
              <FeatureCard
                icon="🏆"
                title="Leaderboards"
                description="Weekly and all-time leaderboards rank users by Aura XP. See where you stand against the community and compete to climb the ranks."
                color="brand-teal"
              />
              <FeatureCard
                icon="🎯"
                title="Target Bonuses"
                description="Hit your daily calorie or protein target and earn bonus XP. Consistently hitting targets is the fastest way to level up on the leaderboard."
                color="brand-green"
              />
            </div>
          </div>
        </section>

        {/* XP Breakdown */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-8">
            Aura XP Breakdown
          </h2>
          <div className="bg-white/5 border border-white/10 rounded-2xl overflow-hidden">
            <table className="w-full">
              <thead>
                <tr className="border-b border-white/10 bg-white/5">
                  <th className="text-left p-4 font-semibold">Action</th>
                  <th className="text-right p-4 font-semibold">XP Earned</th>
                </tr>
              </thead>
              <tbody>
                {[
                  { action: "Log a meal (photo or voice)", xp: "+10 XP" },
                  { action: "Hit daily protein target", xp: "+25 XP" },
                  { action: "Hit daily calorie target", xp: "+20 XP" },
                  { action: "Log a workout", xp: "+15 XP" },
                  { action: "7-day streak milestone", xp: "+50 XP" },
                  { action: "30-day streak milestone", xp: "+100 XP" },
                  { action: "100-day streak milestone", xp: "+500 XP" },
                  { action: "Share a meal to the feed", xp: "+5 XP" },
                ].map((row) => (
                  <tr
                    key={row.action}
                    className="border-b border-white/5 hover:bg-white/5"
                  >
                    <td className="p-4 text-gray-300">{row.action}</td>
                    <td className="p-4 text-right font-mono text-brand-gold">
                      {row.xp}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>

        {/* Streaks Deep Dive */}
        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-4xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold mb-6">
              Streaks: The Ultimate Accountability Tool
            </h2>
            <p className="text-gray-300 text-lg mb-8">
              A streak is the simplest and most powerful motivator. Once you have
              a 14-day streak going, you&apos;ll think twice before skipping a
              day. Macro Maxxing displays your streak prominently so it serves
              as a constant reminder of your commitment.
            </p>
            <div className="grid md:grid-cols-3 gap-6">
              <div className="text-center p-6 bg-white/5 border border-white/10 rounded-2xl">
                <div className="text-5xl font-black text-brand-gold mb-2">
                  7
                </div>
                <p className="text-gray-300">
                  Week Warrior — you&apos;ve built the habit
                </p>
              </div>
              <div className="text-center p-6 bg-white/5 border border-white/10 rounded-2xl">
                <div className="text-5xl font-black text-brand-purple mb-2">
                  30
                </div>
                <p className="text-gray-300">
                  Monthly Master — discipline is locked in
                </p>
              </div>
              <div className="text-center p-6 bg-white/5 border border-white/10 rounded-2xl">
                <div className="text-5xl font-black text-brand-teal mb-2">
                  100
                </div>
                <p className="text-gray-300">
                  Century Club — you&apos;re built different
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* Social Accountability */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Social Accountability Makes It Stick
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            The community feed in Macro Maxxing isn&apos;t just for show — it&apos;s
            an accountability engine. When other people can see your streak, your
            XP, and your meals, you&apos;re far more likely to stay consistent.
            Studies show that public commitment increases follow-through by over
            65%.
          </p>
          <p className="text-gray-300 text-lg">
            Follow friends, join challenges, and celebrate milestones together.
            Macro Maxxing turns solo dieting into a team sport.
          </p>
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
                  q: "What is a gamified macro tracker?",
                  a: "A gamified macro tracker is a nutrition tracking app that uses game mechanics like streaks, points (XP), leaderboards, and social features to make tracking fun and keep you accountable. Macro Maxxing is a free gamified macro tracker with AI-powered food scanning, daily streaks, Aura XP, and competitive leaderboards.",
                },
                {
                  q: "Do streaks really help with diet consistency?",
                  a: "Yes. Behavioral research shows that streak mechanics significantly increase habit adherence. Once you build a streak of 7+ days, the psychological cost of breaking it becomes a powerful motivator. Macro Maxxing displays your streak prominently and rewards milestones with bonus Aura XP.",
                },
                {
                  q: "How do leaderboards work in Macro Maxxing?",
                  a: "Leaderboards rank users by total Aura XP earned. You earn XP by logging meals, hitting protein and calorie targets, maintaining streaks, and logging workouts. There are weekly and all-time leaderboards so both new and veteran users can compete.",
                },
                {
                  q: "Is Macro Maxxing free?",
                  a: "Yes, Macro Maxxing is completely free to download and use. All features including AI food scanning, streaks, leaderboards, and the social community are available at no cost.",
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
            headline="Turn Tracking Into a Game"
            subheadline="Streaks, leaderboards, Aura XP, and a community that keeps you accountable. Download free."
          />
        </div>
      </article>
    </>
  );
}
