import type { Metadata } from "next";
import Image from "next/image";
import { DownloadCTA } from "@/components/DownloadCTA";
import { ArticleJsonLd, BreadcrumbJsonLd, FAQPageJsonLd } from "@/components/JsonLd";

export const metadata: Metadata = {
  title: "AI Meal Planner — Smart Meal Suggestions Based on Your Macros",
  description:
    "Macromaxxing's AI Meal Planner analyzes your remaining macro gaps and suggests specific meals with exact portions to help you hit your daily targets. Powered by Claude AI.",
  keywords: [
    "AI meal planner",
    "AI meal suggestions",
    "macro-based meal planner",
    "meal planner app",
    "what to eat to hit macros",
    "AI nutrition planner",
    "smart meal suggestions",
    "macro meal ideas",
    "personalized meal planner",
    "AI diet planner",
  ],
};

const faqs = [
  {
    question: "What is the AI Meal Planner in Macromaxxing?",
    answer:
      "The AI Meal Planner analyzes your remaining calorie, protein, carb, and fat targets for the day and suggests 2 specific meals or snacks — with exact portion sizes in grams — that fill your macro gaps without exceeding any macro you've already hit. It's powered by Claude Haiku AI and respects your dietary restrictions (dairy-free, gluten-free).",
  },
  {
    question: "How does the AI Meal Planner know what to suggest?",
    answer:
      "It calculates the exact gap between what you've eaten so far and your daily macro goals. If you're short on carbs but already hit your protein and fat, it suggests carb-forward foods that won't spike your other macros. Each suggestion includes specific portions (e.g., '300g jasmine rice + 80g mango chunks') and estimated macros.",
  },
  {
    question: "How many times can I use the AI Meal Planner per day?",
    answer:
      "You can generate AI meal suggestions up to 2 times per day. The limit resets at midnight. Your most recent suggestions are cached so you can revisit them throughout the day without using another generation.",
  },
  {
    question: "Does the AI Meal Planner account for dietary restrictions?",
    answer:
      "Yes. If you've set dairy or gluten exclusions in your settings, the AI Meal Planner will never suggest foods containing those ingredients. It automatically substitutes with appropriate alternatives.",
  },
];

export default function AIMealPlannerPage() {
  return (
    <>
      <ArticleJsonLd
        title="AI Meal Planner — Smart Meal Suggestions Based on Your Macros"
        description="How Macromaxxing's AI Meal Planner suggests specific meals to fill your remaining macro gaps."
        url="https://macromaxxing.app/ai-meal-planner"
      />
      <FAQPageJsonLd faqs={faqs} />
      <BreadcrumbJsonLd
        items={[
          { name: "Home", url: "https://macromaxxing.app" },
          {
            name: "AI Meal Planner",
            url: "https://macromaxxing.app/ai-meal-planner",
          },
        ]}
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-gold/20 via-dark to-brand-purple/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-gold/20 text-brand-gold text-sm font-semibold mb-6">
              AI FEATURE
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              AI Meal Planner:{" "}
              <span className="text-gradient-gold">
                What Should I Eat Next?
              </span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-4">
              The AI Meal Planner in Macromaxxing analyzes your remaining macro
              gaps for the day and suggests specific meals with exact portion
              sizes — so you always know what to eat next to hit your targets.
              Powered by Claude Haiku AI.
            </p>
            <p className="text-gray-500 text-sm mb-8">
              Last updated: March 2026
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-gold hover:bg-brand-gold/80 text-dark font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Download Macromaxxing
            </a>
          </div>
        </section>

        {/* TL;DR */}
        <section className="max-w-4xl mx-auto px-4 py-8 border-b border-white/5">
          <div className="bg-brand-gold/5 border border-brand-gold/20 rounded-2xl p-6">
            <h2 className="text-sm font-semibold text-brand-gold uppercase tracking-wider mb-3">
              TL;DR
            </h2>
            <p className="text-gray-300 text-lg leading-relaxed">
              <strong className="text-white">
                Macromaxxing&apos;s AI Meal Planner tells you exactly what to
                eat next to hit your daily macros.
              </strong>{" "}
              It calculates your remaining calorie, protein, carb, and fat gaps,
              then suggests 2 specific meals with exact portions in grams. It
              won&apos;t suggest foods that push you over on any macro
              you&apos;ve already hit. Most macro tracking apps leave you
              guessing — this one does the math for you.
            </p>
          </div>
        </section>

        {/* How it works */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            How the AI Meal Planner Works
          </h2>
          <p className="text-gray-300 text-lg mb-8">
            Every day, after you log some meals, the AI Meal Planner on your Hub
            screen analyzes exactly where you stand on each macro and suggests
            what to eat next.
          </p>
          <div className="space-y-6 mb-12">
            {[
              {
                step: "1",
                title: "It Reads Your Macro Gaps",
                desc: "The AI calculates the exact remaining calories, protein, carbs, and fat you need for the day. Any macro that's already at or over goal is marked as off-limits.",
                color: "brand-gold",
              },
              {
                step: "2",
                title: "It Generates 2 Smart Suggestions",
                desc: "Claude Haiku AI suggests 2 specific meals or snacks — each with different protein sources, exact portion sizes in grams, and estimated macros. No generic advice like 'eat more protein.'",
                color: "brand-purple",
              },
              {
                step: "3",
                title: "It Respects Your Restrictions",
                desc: "If you've excluded dairy or gluten in your settings, the AI automatically avoids those ingredients and suggests appropriate alternatives.",
                color: "brand-green",
              },
            ].map((item) => (
              <div
                key={item.step}
                className="bg-white/5 border border-white/10 rounded-2xl p-6 flex gap-5"
              >
                <div
                  className={`w-12 h-12 shrink-0 rounded-full bg-${item.color}/20 flex items-center justify-center text-${item.color} font-black text-xl`}
                >
                  {item.step}
                </div>
                <div>
                  <h3 className="text-lg font-bold text-white mb-1">
                    {item.title}
                  </h3>
                  <p className="text-gray-400 text-sm">{item.desc}</p>
                </div>
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
              The AI Meal Planner lives on your Hub screen. Tap
              &ldquo;Brainstorm next meal&rdquo; and get instant, personalized
              suggestions.
            </p>
            <div className="max-w-sm mx-auto">
              <div className="bg-brand-card rounded-2xl border border-white/5 p-4">
                <Image
                  src="/screenshots/ai-meal-planner.png"
                  alt="AI Meal Planner showing personalized meal suggestions based on remaining macro gaps"
                  width={390}
                  height={844}
                  className="w-full h-auto rounded-xl"
                />
              </div>
            </div>
          </div>
        </section>

        {/* What makes it different */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-8">
            Not a Generic Meal Plan — It&apos;s Math
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            Most meal planning apps give you a static weekly plan that
            doesn&apos;t adapt to what you&apos;ve already eaten. Macro
            Maxxing&apos;s AI Meal Planner is different — it runs in real-time
            based on your actual food log.
          </p>
          <div className="grid md:grid-cols-2 gap-6">
            <div className="bg-white/5 border border-white/10 rounded-2xl p-6">
              <h3 className="text-lg font-bold text-brand-gold mb-3">
                What Macromaxxing Does
              </h3>
              <ul className="space-y-2 text-gray-300 text-sm">
                <li className="flex items-start gap-2">
                  <span className="text-brand-green mt-0.5">✓</span>Reads your
                  actual remaining macros for today
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-brand-green mt-0.5">✓</span>Suggests
                  meals that fill gaps without exceeding limits
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-brand-green mt-0.5">✓</span>Gives exact
                  portions in grams
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-brand-green mt-0.5">✓</span>Different
                  suggestions every time based on current gaps
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-brand-green mt-0.5">✓</span>Respects
                  dairy and gluten restrictions
                </li>
              </ul>
            </div>
            <div className="bg-white/5 border border-white/10 rounded-2xl p-6">
              <h3 className="text-lg font-bold text-gray-400 mb-3">
                What Other Apps Do
              </h3>
              <ul className="space-y-2 text-gray-400 text-sm">
                <li className="flex items-start gap-2">
                  <span className="text-gray-500 mt-0.5">✗</span>Static weekly
                  meal plans that don&apos;t adapt
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-gray-500 mt-0.5">✗</span>Generic recipe
                  suggestions not tied to your macros
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-gray-500 mt-0.5">✗</span>No awareness
                  of what you&apos;ve already eaten today
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-gray-500 mt-0.5">✗</span>Vague portions
                  like &ldquo;1 serving&rdquo;
                </li>
                <li className="flex items-start gap-2">
                  <span className="text-gray-500 mt-0.5">✗</span>Often locked
                  behind premium subscriptions
                </li>
              </ul>
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
          </div>
        </section>

        <div id="download">
          <DownloadCTA
            headline="Never Wonder What to Eat Next"
            subheadline="AI analyzes your remaining macros and tells you exactly what to eat. Download Macromaxxing."
          />
        </div>
      </article>
    </>
  );
}
