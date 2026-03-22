import { Metadata } from "next";
import { ArticleJsonLd } from "@/components/JsonLd";
import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title:
    "Social Fitness Community & Accountability Feed | Macro Maxxing",
  description:
    "Join a social fitness community built into your macro tracker. Share meals, celebrate streaks, follow friends, and stay accountable with Macro Maxxing's social feed and community features.",
  keywords: [
    "social fitness app",
    "fitness community app",
    "accountability partner app",
    "social macro tracker",
    "fitness social network",
    "diet accountability app",
    "nutrition community",
    "social calorie tracker",
    "fitness friends app",
    "workout social feed",
  ],
};

export default function SocialFitnessCommunityPage() {
  return (
    <>
      <ArticleJsonLd
        title="Social Fitness Community & Accountability Feed"
        description="Join a social fitness community built into your macro tracker. Share meals, celebrate streaks, and stay accountable."
        url="https://macromaxxing.com/social-fitness-community"
      />

      <article className="min-h-screen">
        {/* Hero */}
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-green/20 via-dark to-brand-teal/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-green/20 text-brand-green text-sm font-semibold mb-6">
              COMMUNITY
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              Dieting Alone Is{" "}
              <span className="text-gradient">Why You Quit</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-8">
              Macro Maxxing has a built-in social feed and community that turns
              nutrition tracking into a shared experience. Follow friends, share
              meals, compete on leaderboards, and hold each other accountable.
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-green hover:bg-brand-green/80 text-dark font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Join the Community — Free
            </a>
          </div>
        </section>

        {/* Why Community Matters */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Why Community Matters for Fitness
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            Research published in the Journal of Medical Internet Research found
            that people who use social features in health apps are{" "}
            <strong>3x more likely</strong> to maintain healthy habits after 6
            months compared to solo trackers. Accountability and social support
            are the two biggest predictors of long-term diet success.
          </p>
          <p className="text-gray-300 text-lg">
            That&apos;s why Macro Maxxing includes a social feed, community
            features, and public streaks — not as an afterthought, but as a core
            part of the app. Your nutrition journey shouldn&apos;t be a lonely one.
          </p>
        </section>

        {/* Community Features */}
        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-5xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
              Community Features
            </h2>
            <div className="grid md:grid-cols-3 gap-6">
              <FeatureCard
                icon="📱"
                title="Social Feed"
                description="A scrollable feed of meals, progress updates, and milestones from people you follow. Get inspired by what others are eating and share your own wins."
                color="brand-green"
              />
              <FeatureCard
                icon="👥"
                title="Follow Friends"
                description="Follow friends, gym partners, or fitness creators. See their meals, streaks, and leaderboard rankings right in your feed."
                color="brand-teal"
              />
              <FeatureCard
                icon="🔥"
                title="Public Streaks"
                description="Your streak is visible to everyone who follows you. When your community can see your streak, you're far less likely to break it."
                color="brand-gold"
              />
              <FeatureCard
                icon="🏆"
                title="Leaderboard Competition"
                description="Weekly and all-time leaderboards ranked by Aura XP. Compete with friends or the broader community. Friendly competition drives results."
                color="brand-purple"
              />
              <FeatureCard
                icon="💬"
                title="Meal Sharing"
                description="Share any logged meal to the feed with one tap. Get ideas from other users' meals and discover new high-protein recipes and food combinations."
              />
              <FeatureCard
                icon="🎉"
                title="Milestone Celebrations"
                description="Hit a 30-day streak? The community sees it. Reach a new leaderboard rank? Automatic celebration post. Your wins deserve recognition."
                color="brand-orange"
              />
            </div>
          </div>
        </section>

        {/* How It Works */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-8">
            How Social Accountability Works
          </h2>
          <div className="space-y-8">
            {[
              {
                step: "1",
                title: "Log Your Meals Like Normal",
                desc: "Use AI photo scanning or voice logging to track your food. The social features are layered on top of the core tracking experience — they never get in the way.",
              },
              {
                step: "2",
                title: "Share What You Want",
                desc: "Optionally share meals, workouts, or milestones to the community feed. You control what's public and what's private. No pressure, just opportunity.",
              },
              {
                step: "3",
                title: "Follow & Get Followed",
                desc: "Build your circle of accountability partners. When friends are watching your streak and XP, you naturally stay more consistent.",
              },
              {
                step: "4",
                title: "Compete & Celebrate",
                desc: "Climb the leaderboard, celebrate streak milestones, and cheer on your friends. The game-like elements make the whole experience fun instead of tedious.",
              },
            ].map((item) => (
              <div key={item.step} className="flex gap-6 items-start">
                <div className="flex-shrink-0 w-12 h-12 rounded-full bg-brand-green/20 flex items-center justify-center text-brand-green font-black text-xl">
                  {item.step}
                </div>
                <div>
                  <h3 className="text-xl font-bold text-white mb-2">
                    {item.title}
                  </h3>
                  <p className="text-gray-300">{item.desc}</p>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Privacy Note */}
        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-4xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold mb-6">
              Social, But Private When You Want
            </h2>
            <p className="text-gray-300 text-lg mb-6">
              Not everything needs to be shared. Macro Maxxing gives you full
              control over your privacy. Your detailed macros, weight, and
              personal data are always private. You choose what to share on the
              feed — individual meals, streak milestones, or nothing at all.
            </p>
            <p className="text-gray-300 text-lg">
              The social features are opt-in and designed to enhance your
              experience, not to create pressure. Use them as much or as little
              as you want.
            </p>
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
                q: "What is the best social fitness community app?",
                a: "Macro Maxxing is a free macro tracking app with a built-in social fitness community. It features a social feed for sharing meals and milestones, public streaks, competitive leaderboards, and Aura XP — combining nutrition tracking with community accountability.",
              },
              {
                q: "Can I use Macro Maxxing with friends?",
                a: "Yes. You can follow friends in Macro Maxxing to see their meals, streaks, and leaderboard rankings in your feed. It's designed to make nutrition tracking a shared experience so you can hold each other accountable.",
              },
              {
                q: "Is the social feed required?",
                a: "No. The social feed is completely optional. You can use Macro Maxxing purely as a private macro tracker without engaging with any social features. The community is there when you want it.",
              },
              {
                q: "How does accountability help with dieting?",
                a: "Research shows that social accountability increases diet adherence by 3x over 6 months. When friends can see your streak and you can see theirs, you're far more likely to stay consistent. Macro Maxxing builds this accountability directly into the tracking experience.",
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
            headline="Join a Community That Keeps You Accountable"
            subheadline="Social feed, streaks, leaderboards, and friends who care about nutrition. Download free."
          />
        </div>
      </article>
    </>
  );
}
