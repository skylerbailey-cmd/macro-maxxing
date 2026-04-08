import type { Metadata } from "next";
import Image from "next/image";
import { DownloadCTA } from "@/components/DownloadCTA";
import { ArticleJsonLd, BreadcrumbJsonLd, FAQPageJsonLd } from "@/components/JsonLd";

export const metadata: Metadata = {
  title: "AI Nutrition Coach — Personalized Daily Macro Reviews",
  description:
    "Macro Maxxing's AI Nutrition Coach reviews your entire day of eating and training, then gives you a personalized debrief with specific advice on what to change tomorrow. Powered by Claude Sonnet AI.",
  keywords: [
    "AI nutrition coach",
    "AI diet coach",
    "personalized nutrition advice",
    "macro coaching app",
    "AI nutrition advisor",
    "daily nutrition review",
    "nutrition coach app",
    "macro review",
    "AI fitness coach",
    "nutrition feedback app",
  ],
};

const faqs = [
  {
    question: "What is the AI Nutrition Coach in Macro Maxxing?",
    answer:
      "The AI Nutrition Coach reviews your entire day of eating and training — every meal logged, your macro totals vs. goals, workouts, and fasting window — then delivers a personalized daily debrief. It covers macro accuracy, meal timing and distribution, food quality, and gives you one specific, actionable recommendation for tomorrow.",
  },
  {
    question: "How is the AI Nutrition Coach different from a generic chatbot?",
    answer:
      "It's not a generic Q&A chatbot. The AI Nutrition Coach has full context of your actual food log, macro goals, workouts, and fasting schedule for the day. It analyzes your real data and gives specific advice like 'add a high-carb post-workout meal after your session tomorrow, something like white rice with lean protein, to close that 116g carb gap without spiking fat.'",
  },
  {
    question: "How often can I use the AI Nutrition Coach?",
    answer:
      "You can get one AI Nutrition Coach review per calendar day. It's designed to be a daily debrief — a summary of how your nutrition went and what to improve tomorrow. The review is available once you've logged meals for the day.",
  },
  {
    question: "What does the AI Nutrition Coach analyze?",
    answer:
      "It analyzes four dimensions: (1) Macro overview — how you landed vs. your calorie, protein, carb, and fat targets with specific numbers and percentages. (2) Meal timing and distribution — protein spread across meals, pre/post-workout fueling, eating gaps. (3) Food quality — nutrient density, whole foods vs. processed. (4) One actionable recommendation — a specific food or meal swap to make tomorrow.",
  },
];

export default function AINutritionCoachPage() {
  return (
    <>
      <ArticleJsonLd
        title="AI Nutrition Coach — Personalized Daily Macro Reviews"
        description="How Macro Maxxing's AI Nutrition Coach reviews your daily eating and training to give personalized, actionable nutrition advice."
        url="https://macromaxxing.app/ai-nutrition-coach"
      />
      <FAQPageJsonLd faqs={faqs} />
      <BreadcrumbJsonLd
        items={[
          { name: "Home", url: "https://macromaxxing.app" },
          {
            name: "AI Nutrition Coach",
            url: "https://macromaxxing.app/ai-nutrition-coach",
          },
        ]}
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-purple/20 via-dark to-brand-teal/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-purple/20 text-brand-purple text-sm font-semibold mb-6">
              AI FEATURE
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              AI Nutrition Coach:{" "}
              <span className="text-gradient">Your Daily Debrief</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-4">
              The AI Nutrition Coach in Macro Maxxing reviews your entire day of
              eating and training, then delivers a personalized debrief with
              specific advice on macro accuracy, meal timing, food quality, and
              what to change tomorrow. Powered by Claude Sonnet AI.
            </p>
            <p className="text-gray-500 text-sm mb-8">
              Last updated: March 2026
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-purple hover:bg-brand-purple/80 text-white font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Download Macro Maxxing
            </a>
          </div>
        </section>

        {/* TL;DR */}
        <section className="max-w-4xl mx-auto px-4 py-8 border-b border-white/5">
          <div className="bg-brand-purple/5 border border-brand-purple/20 rounded-2xl p-6">
            <h2 className="text-sm font-semibold text-brand-purple uppercase tracking-wider mb-3">
              TL;DR
            </h2>
            <p className="text-gray-300 text-lg leading-relaxed">
              <strong className="text-white">
                Macro Maxxing&apos;s AI Nutrition Coach gives you a daily
                debrief on how your nutrition went — with specific,
                data-driven advice.
              </strong>{" "}
              It analyzes every meal you logged, your macro totals vs. goals,
              workouts, and fasting window. Then it tells you exactly what went
              well, what didn&apos;t, and one specific thing to change tomorrow.
              No generic tips — real coaching based on your actual data.
            </p>
          </div>
        </section>

        {/* What it analyzes */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            What the AI Nutrition Coach Reviews
          </h2>
          <p className="text-gray-300 text-lg mb-8">
            At the end of your day (or whenever you want a check-in), tap
            &ldquo;Get My Recommendation&rdquo; in the Fuel Log tab. The AI
            reviews everything and delivers your debrief.
          </p>
          <div className="grid md:grid-cols-2 gap-6">
            {[
              {
                icon: "📊",
                title: "Macro Accuracy",
                desc: "How your actual calories, protein, carbs, and fat landed against your daily goals — with specific numbers and percentages.",
                color: "brand-purple",
              },
              {
                icon: "⏰",
                title: "Meal Timing & Distribution",
                desc: "Your protein spread across meals, pre- and post-workout fueling, gaps between meals, and whether you're front-loading or back-loading calories.",
                color: "brand-gold",
              },
              {
                icon: "🥗",
                title: "Food Quality",
                desc: "Whether your food choices are nutrient-dense or empty calories. Highlights quality whole food meals and flags processed choices.",
                color: "brand-green",
              },
              {
                icon: "🎯",
                title: "One Actionable Change",
                desc: "A specific, concrete recommendation for tomorrow — not 'eat more protein' but 'add a 200g chicken breast post-workout to close your 40g protein gap.'",
                color: "brand-teal",
              },
            ].map((item) => (
              <div
                key={item.title}
                className="bg-white/5 border border-white/10 rounded-2xl p-6"
              >
                <div className="text-3xl mb-3">{item.icon}</div>
                <h3 className={`text-lg font-bold text-${item.color} mb-2`}>
                  {item.title}
                </h3>
                <p className="text-gray-400 text-sm">{item.desc}</p>
              </div>
            ))}
          </div>
        </section>

        {/* Screenshot */}
        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-4xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold text-center mb-4">
              See It in Action
            </h2>
            <p className="text-gray-400 text-center max-w-xl mx-auto mb-12">
              The AI Nutrition Coach appears at the bottom of your Fuel Log
              after you&apos;ve logged meals. It has full context of everything
              you ate and every workout you did.
            </p>
            <div className="max-w-sm mx-auto">
              <div className="bg-brand-card rounded-2xl border border-white/5 p-4">
                <Image
                  src="/screenshots/ai-nutrition-coach.png"
                  alt="AI Nutrition Coach showing personalized daily debrief with meal timing, food quality, and actionable recommendations"
                  width={390}
                  height={844}
                  className="w-full h-auto rounded-xl"
                />
              </div>
            </div>
          </div>
        </section>

        {/* How it works technically */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-8">
            Context-Aware, Not Generic
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            The AI Nutrition Coach isn&apos;t a chatbot giving generic advice.
            It has full access to your day&apos;s data before generating its
            review:
          </p>
          <div className="space-y-4">
            {[
              {
                data: "Every meal logged",
                detail: "Food name, calories, protein, carbs, fat, and the exact time each meal was logged",
              },
              {
                data: "Your macro goals",
                detail: "Daily targets for calories, protein, carbs, and fat — and how close you got",
              },
              {
                data: "Workouts logged",
                detail: "Type (strength, cardio, HIIT), duration, calories burned, and time of session",
              },
              {
                data: "Fasting window",
                detail: "If intermittent fasting is enabled, it considers your eating window timing",
              },
              {
                data: "Dietary restrictions",
                detail: "Dairy and gluten exclusions so recommendations stay within your preferences",
              },
            ].map((item) => (
              <div
                key={item.data}
                className="bg-white/5 border border-white/10 rounded-2xl p-5 flex gap-4"
              >
                <span className="text-brand-purple mt-0.5 shrink-0">●</span>
                <div>
                  <p className="font-semibold text-white">{item.data}</p>
                  <p className="text-gray-400 text-sm">{item.detail}</p>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Comparison */}
        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-4xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold mb-8">
              How It Compares to Other &ldquo;Coaching&rdquo; Features
            </h2>
            <div className="grid md:grid-cols-2 gap-6">
              <div className="bg-brand-purple/5 border border-brand-purple/20 rounded-2xl p-6">
                <h3 className="text-lg font-bold text-brand-purple mb-4">
                  Macro Maxxing AI Coach
                </h3>
                <ul className="space-y-2 text-gray-300 text-sm">
                  <li className="flex items-start gap-2">
                    <span className="text-brand-green mt-0.5">✓</span>Reviews
                    your actual meals, macros, and workouts
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-brand-green mt-0.5">✓</span>Gives
                    specific advice with real numbers
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-brand-green mt-0.5">✓</span>Analyzes
                    meal timing and food quality
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-brand-green mt-0.5">✓</span>One
                    concrete action item for tomorrow
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-brand-green mt-0.5">✓</span>Powered by
                    Claude Sonnet AI
                  </li>
                </ul>
              </div>
              <div className="bg-white/5 border border-white/10 rounded-2xl p-6">
                <h3 className="text-lg font-bold text-gray-400 mb-4">
                  Typical App &ldquo;Coaching&rdquo;
                </h3>
                <ul className="space-y-2 text-gray-400 text-sm">
                  <li className="flex items-start gap-2">
                    <span className="text-gray-500 mt-0.5">✗</span>Generic tips
                    not connected to your data
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-gray-500 mt-0.5">✗</span>Scripted
                    responses from human coaches
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-gray-500 mt-0.5">✗</span>No analysis
                    of meal timing or food quality
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-gray-500 mt-0.5">✗</span>Vague advice
                    like &ldquo;try to eat more vegetables&rdquo;
                  </li>
                  <li className="flex items-start gap-2">
                    <span className="text-gray-500 mt-0.5">✗</span>Often costs
                    $40-60/month extra
                  </li>
                </ul>
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
            headline="Get Your Daily Nutrition Debrief"
            subheadline="AI reviews your meals, workouts, and macros — then tells you exactly what to change. Download Macro Maxxing."
          />
        </div>
      </article>
    </>
  );
}
