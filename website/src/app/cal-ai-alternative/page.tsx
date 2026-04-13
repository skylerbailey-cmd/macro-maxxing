import { Metadata } from "next";
import { ArticleJsonLd, FAQPageJsonLd, BreadcrumbJsonLd } from "@/components/JsonLd";
import { ComparisonTable } from "@/components/ComparisonTable";
import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Best Cal AI Alternative 2026 — Macromaxxing vs Cal AI",
  description:
    "Looking for a Cal AI alternative with more features? Macromaxxing offers AI photo scanning, voice logging, an AI meal planner, AI nutrition coach, streaks, leaderboards, and a social community.",
  keywords: [
    "Cal AI alternative",
    "Cal AI replacement",
    "better than Cal AI",
    "apps like Cal AI",
    "Cal AI vs",
    "Cal AI alternative app",
    "calorie tracker alternative",
    "AI calorie tracker",
    "Cal AI competitor",
    "macro tracker vs Cal AI",
  ],
};

const faqs = [
  {
    question: "What is the best alternative to Cal AI?",
    answer:
      "Macromaxxing is the best alternative to Cal AI for anyone who wants more than just calorie counting. Core features like full macro tracking, streaks, leaderboards, and community are free to download. AI-powered features (photo scanning, voice logging, meal planner, nutrition coach) are available through AI Pro at $9.99/month with transparent pricing.",
  },
  {
    question: "Is Macromaxxing more accurate than Cal AI?",
    answer:
      "Macromaxxing uses Claude AI (Haiku and Sonnet) by Anthropic for food recognition and macro estimation. Cal AI users frequently report accuracy issues with complex dishes, hidden ingredients, and portion sizes. Macromaxxing also offers voice logging as a second input method, which Cal AI lacks.",
  },
  {
    question: "Does Macromaxxing have features Cal AI doesn't?",
    answer:
      "Yes. Macromaxxing includes several features Cal AI doesn't offer: voice meal logging, an AI meal planner that suggests what to eat based on remaining macros, an AI nutrition coach that reviews your day, smart workout tracking with automatic macro adjustments, an intermittent fasting timer, daily streaks, Aura XP leaderboards, and a social community feed.",
  },
  {
    question: "Does Cal AI track macros?",
    answer:
      "Cal AI tracks calories, protein, carbs, and fat from photos. However, it's primarily marketed as a calorie tracker rather than a macro tracker. Macromaxxing is built as a macro tracker first — protein, carbs, and fat are displayed prominently alongside calories, and features like the AI meal planner are designed to help you hit specific macro targets.",
  },
];

export default function CalAIAlternativePage() {
  return (
    <>
      <ArticleJsonLd
        title="Best Cal AI Alternative 2026 — Macromaxxing"
        description="Macromaxxing is a feature-rich Cal AI alternative with voice logging, AI meal planning, nutrition coaching, and gamified accountability."
        url="https://macromaxxing.app/cal-ai-alternative"
      />
      <FAQPageJsonLd faqs={faqs} />
      <BreadcrumbJsonLd
        items={[
          { name: "Home", url: "https://macromaxxing.app" },
          {
            name: "Cal AI Alternative",
            url: "https://macromaxxing.app/cal-ai-alternative",
          },
        ]}
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-orange/20 via-dark to-brand-purple/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-orange/20 text-brand-orange text-sm font-semibold mb-6">
              VS CAL AI
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              More Than Just{" "}
              <span className="text-gradient-gold">Calorie Counting</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-4">
              Macromaxxing is a Cal AI alternative that goes beyond photo
              calorie counting with full macro tracking, voice logging, an AI
              meal planner, AI nutrition coach, workout tracking, streaks,
              leaderboards, and a social community.
            </p>
            <p className="text-gray-500 text-sm mb-8">
              Last updated: March 2026
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-orange hover:bg-brand-orange/80 text-dark font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Switch to Macromaxxing
            </a>
          </div>
        </section>

        {/* TL;DR */}
        <section className="max-w-4xl mx-auto px-4 py-8 border-b border-white/5">
          <div className="bg-brand-orange/5 border border-brand-orange/20 rounded-2xl p-6">
            <h2 className="text-sm font-semibold text-brand-orange uppercase tracking-wider mb-3">
              TL;DR
            </h2>
            <p className="text-gray-300 text-lg leading-relaxed">
              <strong className="text-white">
                Macromaxxing is the best Cal AI alternative for anyone who
                wants more than photo-based calorie counting.
              </strong>{" "}
              It matches Cal AI&apos;s photo scanning and adds voice logging, an
              AI meal planner, AI nutrition coach, workout tracking with auto
              macro adjustments, intermittent fasting, streaks, leaderboards,
              and a social community. The trade-off: Cal AI has a simpler
              onboarding flow and is available on Android, while Macromaxxing
              is iOS only with deeper features.
            </p>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Where Cal AI Falls Short
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            Cal AI went viral for its simple premise — snap a photo and get
            calories. It&apos;s quick to set up and easy to use. But for anyone
            serious about their nutrition, it has significant limitations:
          </p>
          <div className="space-y-4">
            {[
              {
                issue: "Calorie-First, Not Macro-First",
                desc: "Cal AI is primarily a calorie tracker. While it shows macros, it's designed around calorie counting rather than hitting specific protein, carb, and fat targets.",
              },
              {
                issue: "No Voice Logging",
                desc: "Cal AI only supports photo scanning and manual search. No hands-free voice input for logging meals when you're busy or post-workout.",
              },
              {
                issue: "No AI Meal Planner",
                desc: "Cal AI doesn't tell you what to eat next. It counts what you've already eaten but doesn't help you fill remaining macro gaps with specific meal suggestions.",
              },
              {
                issue: "No AI Nutrition Coach",
                desc: "No daily review of your eating patterns, meal timing, or food quality. Cal AI gives you numbers but no analysis or actionable advice.",
              },
              {
                issue: "No Gamification or Community",
                desc: "No daily streaks, no XP system, no leaderboards, and limited social features. Cal AI recently added groups, but there's no community feed or competitive accountability.",
              },
              {
                issue: "Opaque Pricing",
                desc: "Cal AI's pricing isn't shown until after onboarding, and different users may see different prices. Core AI scanning requires a paid subscription.",
              },
            ].map((item) => (
              <div
                key={item.issue}
                className="bg-white/5 border border-white/10 rounded-2xl p-5"
              >
                <h3 className="font-bold text-white mb-1">{item.issue}</h3>
                <p className="text-gray-400 text-sm">{item.desc}</p>
              </div>
            ))}
          </div>
        </section>

        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-4xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold text-center mb-8">
              Macromaxxing vs Cal AI
            </h2>
            <ComparisonTable
              features={[
                {
                  name: "Price",
                  macroMaxxing: "Free / $9.99/mo AI Pro",
                  others: "Subscription required",
                },
                {
                  name: "AI photo food scanning",
                  macroMaxxing: true,
                  others: true,
                },
                {
                  name: "Voice meal logging",
                  macroMaxxing: true,
                  others: false,
                },
                {
                  name: "Full macro tracking (P/C/F)",
                  macroMaxxing: true,
                  others: "Calorie-first",
                },
                {
                  name: "AI meal planner",
                  macroMaxxing: "AI Pro ($9.99/mo)",
                  others: false,
                },
                {
                  name: "AI nutrition coach",
                  macroMaxxing: "AI Pro ($9.99/mo)",
                  others: false,
                },
                {
                  name: "Workout macro adjustments",
                  macroMaxxing: true,
                  others: false,
                },
                {
                  name: "Intermittent fasting timer",
                  macroMaxxing: true,
                  others: false,
                },
                {
                  name: "Daily streaks",
                  macroMaxxing: true,
                  others: false,
                },
                {
                  name: "Leaderboards & XP",
                  macroMaxxing: true,
                  others: false,
                },
                {
                  name: "Social community feed",
                  macroMaxxing: true,
                  others: "Basic groups",
                },
                {
                  name: "Saved meal templates",
                  macroMaxxing: true,
                  others: "Relog feature",
                },
                {
                  name: "Transparent pricing",
                  macroMaxxing: "Free core + $9.99/mo AI Pro",
                  others: "Hidden until onboarding",
                },
              ]}
            />
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-5xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
            What Macromaxxing Adds
          </h2>
          <div className="grid md:grid-cols-3 gap-6">
            <FeatureCard
              icon="🎤"
              title="Voice Logging"
              description="Say 'chicken breast with rice and broccoli' and AI logs it instantly. Cal AI has no voice input — every entry requires a photo or manual search."
              color="brand-gold"
            />
            <FeatureCard
              icon="🍽️"
              title="AI Meal Planner"
              description="Not sure what to eat? AI analyzes your remaining macro gaps and suggests specific meals with exact portions. Cal AI only counts what you've eaten."
              color="brand-purple"
            />
            <FeatureCard
              icon="🧠"
              title="AI Nutrition Coach"
              description="Get a daily debrief on your eating — macro accuracy, meal timing, food quality, and one specific thing to change tomorrow. Cal AI gives numbers, not coaching."
              color="brand-teal"
            />
            <FeatureCard
              icon="🏋️"
              title="Smart Workouts"
              description="Log workouts and your macro targets adjust automatically based on training type. Cal AI doesn't connect your training to your nutrition."
              color="brand-green"
            />
            <FeatureCard
              icon="🔥"
              title="Streaks & Leaderboards"
              description="Build daily streaks, earn Aura XP, and compete on leaderboards. Cal AI has no gamification to keep you consistent."
              color="brand-orange"
            />
            <FeatureCard
              icon="👥"
              title="Social Community"
              description="A full social feed for sharing meals, celebrating streaks, and holding each other accountable. Not just basic groups."
              color="brand-cyan"
            />
          </div>
        </section>

        {/* Who should switch */}
        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-4xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold mb-8">
              Who Should Switch — and Who Shouldn&apos;t
            </h2>
            <div className="grid md:grid-cols-2 gap-6">
              <div className="bg-brand-green/5 border border-brand-green/20 rounded-2xl p-6">
                <h3 className="text-lg font-bold text-brand-green mb-4">
                  Switch to Macromaxxing if you:
                </h3>
                <ul className="space-y-2 text-gray-300 text-sm">
                  <li className="flex items-start gap-2">
                    <span className="text-brand-green mt-0.5">✓</span>Want to
                    track macros (protein, carbs, fat) — not just calories
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-brand-green mt-0.5">✓</span>Want
                    voice logging for hands-free tracking
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-brand-green mt-0.5">✓</span>Want AI
                    to tell you what to eat next (meal planner)
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-brand-green mt-0.5">✓</span>Want a
                    daily review of your nutrition (AI coach)
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-brand-green mt-0.5">✓</span>Want
                    gamification and social accountability
                  </li>
                </ul>
              </div>
              <div className="bg-white/5 border border-white/10 rounded-2xl p-6">
                <h3 className="text-lg font-bold text-gray-400 mb-4">
                  Cal AI may still be better if you:
                </h3>
                <ul className="space-y-2 text-gray-400 text-sm">
                  <li className="flex items-start gap-2">
                    <span className="text-gray-500 mt-0.5">•</span>Only need
                    simple calorie counting from photos
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-gray-500 mt-0.5">•</span>Need Android
                    support (Macromaxxing is iOS only)
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-gray-500 mt-0.5">•</span>Prefer the
                    simplest possible onboarding experience
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-gray-500 mt-0.5">•</span>Don&apos;t
                    need workout tracking, fasting, or social features
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </section>

        {/* How to switch */}
        <section className="py-12 max-w-4xl mx-auto px-4">
          <div className="bg-brand-card rounded-2xl border border-white/5 p-6 md:p-8">
            <h2 className="text-2xl font-bold mb-4">
              How to Switch from Cal AI
            </h2>
            <div className="grid md:grid-cols-3 gap-6">
              <div>
                <p className="text-brand-orange font-bold text-lg mb-1">
                  1. Download
                </p>
                <p className="text-gray-400 text-sm">
                  Get Macromaxxing from the App Store. Set up in under 2
                  minutes.
                </p>
              </div>
              <div>
                <p className="text-brand-orange font-bold text-lg mb-1">
                  2. Set Macro Targets
                </p>
                <p className="text-gray-400 text-sm">
                  Go beyond calories — set specific protein, carb, and fat
                  targets for your goal.
                </p>
              </div>
              <div>
                <p className="text-brand-orange font-bold text-lg mb-1">
                  3. Experience the Difference
                </p>
                <p className="text-gray-400 text-sm">
                  Log with photos or voice. Get AI meal suggestions. Build your
                  streak.
                </p>
              </div>
            </div>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-8">
            Frequently Asked Questions
          </h2>
          <div className="space-y-6">
            {faqs.map((faq) => (
              <div
                key={faq.question}
                className="bg-white/5 border border-white/10 rounded-2xl p-6"
              >
                <h3 className="text-lg font-bold text-white mb-2">
                  {faq.question}
                </h3>
                <p className="text-gray-300">{faq.answer}</p>
              </div>
            ))}
          </div>
        </section>

        <div id="download">
          <DownloadCTA
            headline="More Than Calorie Counting"
            subheadline="Core tracking and community free. AI scanning, voice logging, and coaching at $9.99/mo with transparent pricing. Download Macromaxxing."
          />
        </div>
      </article>
    </>
  );
}
