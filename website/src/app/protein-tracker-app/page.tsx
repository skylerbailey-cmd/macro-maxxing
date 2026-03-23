import { Metadata } from "next";
import { ArticleJsonLd } from "@/components/JsonLd";
import { FeatureCard } from "@/components/FeatureCard";
import { ComparisonTable } from "@/components/ComparisonTable";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Best Protein Tracker App — AI-Powered Protein Tracking | Macro Maxxing",
  description:
    "Track your daily protein intake effortlessly with Macro Maxxing. AI photo scanning and voice logging calculate protein automatically. Free protein tracker with streaks, leaderboards, and a social community.",
  keywords: [
    "protein tracker app",
    "protein intake tracker",
    "daily protein tracker",
    "protein counter app",
    "best protein tracker",
    "protein tracking app free",
    "high protein diet app",
    "protein goal tracker",
    "protein per meal tracker",
    "protein macro tracker",
  ],
};

export default function ProteinTrackerPage() {
  return (
    <>
      <ArticleJsonLd
        title="Best Protein Tracker App — AI-Powered Protein Tracking"
        description="Track your daily protein intake effortlessly with AI photo scanning and voice logging."
        url="https://macromaxxing.app/protein-tracker-app"
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-teal/20 via-dark to-brand-green/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-teal/20 text-brand-teal text-sm font-semibold mb-6">
              PROTEIN TRACKING
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              The Easiest Way to Hit Your{" "}
              <span className="text-gradient">Protein Goals</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-8">
              Macro Maxxing puts protein front and center. Snap a photo, say it
              out loud, or enter it manually — your daily protein is always
              visible and always accurate. Build streaks, climb leaderboards,
              and join a community of people who prioritize protein.
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-teal hover:bg-brand-teal/80 text-dark font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Track Protein Free
            </a>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Why Protein Is the Most Important Macro
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            Protein is the single most important macronutrient for body
            composition. It builds and repairs muscle, keeps you full longer,
            has the highest thermic effect of food (your body burns 20-30% of
            protein calories just digesting it), and preserves lean mass during
            a calorie deficit.
          </p>
          <p className="text-gray-300 text-lg mb-8">
            Whether you&apos;re bulking, cutting, or maintaining, hitting your daily
            protein target is non-negotiable. Macro Maxxing makes it easy by
            showing your protein intake prominently throughout the day.
          </p>

          <div className="grid md:grid-cols-3 gap-6">
            <div className="text-center p-6 bg-white/5 border border-white/10 rounded-2xl">
              <div className="text-4xl font-black text-brand-teal mb-2">
                0.8-1g
              </div>
              <p className="text-gray-300 text-sm">
                per lb bodyweight for maintenance
              </p>
            </div>
            <div className="text-center p-6 bg-white/5 border border-white/10 rounded-2xl">
              <div className="text-4xl font-black text-brand-purple mb-2">
                1-1.2g
              </div>
              <p className="text-gray-300 text-sm">
                per lb bodyweight for muscle gain
              </p>
            </div>
            <div className="text-center p-6 bg-white/5 border border-white/10 rounded-2xl">
              <div className="text-4xl font-black text-brand-gold mb-2">
                1.2-1.5g
              </div>
              <p className="text-gray-300 text-sm">
                per lb bodyweight during a cut
              </p>
            </div>
          </div>
        </section>

        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-5xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
              3 Ways to Track Protein
            </h2>
            <div className="grid md:grid-cols-3 gap-6">
              <FeatureCard
                icon="📸"
                title="Photo Scan"
                description="Take a photo of your meal and AI identifies the food, estimates portions, and calculates protein content from 4 nutrition databases."
                color="brand-teal"
              />
              <FeatureCard
                icon="🎤"
                title="Voice Log"
                description="Say 'two chicken breasts and a cup of rice' — AI transcribes, identifies foods, and calculates protein automatically."
                color="brand-purple"
              />
              <FeatureCard
                icon="✏️"
                title="Manual Entry"
                description="Search the database or enter custom values. Perfect for packaged foods or recipes where you know the exact macros."
                color="brand-gold"
              />
            </div>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-8">
            Macro Maxxing vs. Other Protein Trackers
          </h2>
          <ComparisonTable
            features={[
              { name: "AI photo protein scanning", macroMaxxing: true, others: false },
              { name: "Voice protein logging", macroMaxxing: true, others: false },
              { name: "Protein-first dashboard", macroMaxxing: true, others: false },
              { name: "Daily streaks", macroMaxxing: true, others: false },
              { name: "Leaderboards & Aura XP", macroMaxxing: true, others: false },
              { name: "Social community feed", macroMaxxing: true, others: false },
              { name: "Workout protein adjustments", macroMaxxing: true, others: "Some" },
              { name: "100% free", macroMaxxing: true, others: "Freemium" },
            ]}
          />
        </section>

        {/* Gamification */}
        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-4xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold text-center mb-6">
              Make Protein Tracking a{" "}
              <span className="text-gradient-gold">Game</span>
            </h2>
            <p className="text-gray-300 text-lg text-center max-w-2xl mx-auto mb-12">
              Earn Aura XP every time you hit your protein target. Build daily
              streaks. Compete on the leaderboard. Join a community of macro
              trackers who take protein seriously.
            </p>
            <div className="grid md:grid-cols-2 gap-6">
              <div className="bg-white/5 border border-white/10 rounded-2xl p-6">
                <h3 className="text-xl font-bold mb-3 text-brand-gold">
                  Protein Target Streak
                </h3>
                <p className="text-gray-300">
                  Hit your protein goal every day to build a protein-specific
                  streak. It&apos;s not just about logging — it&apos;s about
                  consistently hitting the number that matters most.
                </p>
              </div>
              <div className="bg-white/5 border border-white/10 rounded-2xl p-6">
                <h3 className="text-xl font-bold mb-3 text-brand-teal">
                  Community Accountability
                </h3>
                <p className="text-gray-300">
                  Share your high-protein meals to the social feed. Follow
                  friends who prioritize protein. When your community is
                  watching, you stay disciplined.
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
                q: "What is the best app for tracking protein intake?",
                a: "Macro Maxxing is the best free protein tracker app. It uses AI photo scanning and voice logging to calculate protein automatically, displays protein prominently on a protein-first dashboard, and includes streaks, leaderboards, and a social community for accountability.",
              },
              {
                q: "How much protein do I need per day?",
                a: "For most active adults, 0.8 to 1.2 grams of protein per pound of bodyweight is recommended. If you're cutting (calorie deficit), aim for the higher end (1.2-1.5g/lb) to preserve muscle mass. Macro Maxxing helps you set and track a personalized protein target.",
              },
              {
                q: "Can Macro Maxxing scan food and tell me the protein?",
                a: "Yes. Take a photo of any meal and Macro Maxxing's 3-tier AI system identifies the food, estimates portions, and calculates protein (plus all other macros) using data from 4 nutrition databases including USDA FoodData Central.",
              },
              {
                q: "Is Macro Maxxing free for protein tracking?",
                a: "Yes. Macro Maxxing is 100% free with no premium tier. All features including AI scanning, voice logging, streaks, leaderboards, and the social community are free.",
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
            headline="Hit Your Protein Goals Every Day"
            subheadline="AI-powered protein tracking with streaks, leaderboards, and community accountability. Free forever."
          />
        </div>
      </article>
    </>
  );
}
