import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import {
  ArticleJsonLd,
  BreadcrumbJsonLd,
  FAQPageJsonLd,
} from "@/components/JsonLd";

export const metadata: Metadata = {
  title: "How to Log a Meal in Macro Maxxing — Step-by-Step Guide",
  description:
    "Learn how to log meals in Macro Maxxing using AI photo scanning, voice logging, or manual entry. Get instant macro estimates for calories, protein, carbs, and fat. See your meal score and full breakdown.",
  keywords: [
    "how to log a meal macro maxxing",
    "macro maxxing food log",
    "AI food scanner macro tracker",
    "voice food logging app",
    "photo macro tracking",
    "log calories with photo",
    "AI meal analysis app",
    "macro maxxing help",
    "food photo calorie counter",
    "meal score macro tracker",
    "log food with voice",
    "macro tracking app iOS",
  ],
  openGraph: {
    title: "How to Log a Meal in Macro Maxxing — Step-by-Step Guide",
    description:
      "Log meals with AI photo analysis, voice, or manual entry. Get instant macro breakdowns, meal scores, and portion size adjustments.",
    url: "https://macromaxxing.app/help/how-to-log-a-meal",
    type: "article",
  },
  alternates: {
    canonical: "https://macromaxxing.app/help/how-to-log-a-meal",
  },
};

const faqs = [
  {
    question: "How do I log a meal in Macro Maxxing?",
    answer:
      "Open Macro Maxxing, tap the yellow + button on the Hub screen, then select 'Log a Meal.' You can log using three modes: Photo (snap or upload a picture and let AI estimate macros), Voice (describe what you ate and AI fills in the details), or Manual (type in the food name, calories, protein, carbs, and fat yourself).",
  },
  {
    question: "How does AI photo food scanning work in Macro Maxxing?",
    answer:
      "In Photo mode, take a picture of your meal or choose one from your library. Optionally add details like '2 eggs with toast' for better accuracy. Tap 'Analyze Photo' and Claude AI identifies each food item, estimates portion sizes, and calculates calories, protein, carbs, and fat. You can review and edit the results before logging.",
  },
  {
    question: "Can I log food with my voice in Macro Maxxing?",
    answer:
      "Yes. On the Log Food screen, tap the Voice tab, then tap the microphone and describe what you ate in natural language — for example, 'chicken curry with white rice.' The AI will process your description and estimate the macros automatically.",
  },
  {
    question: "What is the Meal Score in Macro Maxxing?",
    answer:
      "The Meal Score is a number from 0 to 100 that measures how closely a meal's macro distribution (protein, carbs, fat) matches your personal goals. A score of 100 means the meal's caloric ratio perfectly matches your target percentages. Tap any meal in the Fuel Log to see its score and a breakdown showing how each macro compares to your goal. Scores are shown for meals over 300 calories.",
  },
  {
    question: "Can I adjust portion size after AI analysis in Macro Maxxing?",
    answer:
      "Yes. On the Confirm Food screen after AI analysis, use the Portion Size slider to scale between 0.5x and 3x. All macros and calories update in real time as you adjust. You can also tap 'Edit Macros' to manually change any value.",
  },
  {
    question: "Can I save meals as templates in Macro Maxxing?",
    answer:
      "Yes. When logging a meal (in any mode), toggle on 'Save as Saved Meal' to save it as a template. Your saved meals appear at the top of the Log Food screen so you can quickly re-log them with a single tap.",
  },
  {
    question: "Where do I see my logged meals in Macro Maxxing?",
    answer:
      "Go to the Log tab and make sure the 'Fuel' tab is selected. You'll see your eating window, all logged meals with their photos, macro summaries, and meal scores. Tap any meal to see the full breakdown and score details.",
  },
  {
    question: "What AI models does Macro Maxxing use for food scanning?",
    answer:
      "Macro Maxxing uses Claude AI by Anthropic. Simple, single-ingredient foods are handled by the fast Claude Haiku model, while complex meals with multiple items get the full power of Claude Sonnet for more detailed analysis.",
  },
];

function HowToJsonLd() {
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "HowTo",
    name: "How to Log a Meal in Macro Maxxing",
    description:
      "Step-by-step guide to logging meals in the Macro Maxxing iOS app using AI photo scanning, voice logging, or manual entry.",
    totalTime: "PT1M",
    tool: [
      {
        "@type": "HowToTool",
        name: "Macro Maxxing iOS app",
      },
    ],
    step: [
      {
        "@type": "HowToStep",
        name: "Open the quick-action menu",
        text: "From the Hub tab, tap the yellow + button in the bottom-right corner of the screen.",
        image: "https://macromaxxing.app/help/Home%20Screen.png",
      },
      {
        "@type": "HowToStep",
        name: "Select Log a Meal",
        text: "From the action menu, tap 'Log a Meal' to open the Log Food screen. You can also tap 'Saved Meals,' 'Photo Library,' or 'Camera' for quick access.",
        image: "https://macromaxxing.app/help/logMeal1.png",
      },
      {
        "@type": "HowToStep",
        name: "Choose your logging mode",
        text: "Select Photo mode to scan your food with AI, Voice mode to describe what you ate, or Manual mode to type in the details yourself.",
        image: "https://macromaxxing.app/help/logMeal2.3.png",
      },
      {
        "@type": "HowToStep",
        name: "Review and confirm",
        text: "After AI analysis, review the food name, calories, macros, portion size, and meal breakdown. Adjust anything that needs correcting, then tap 'Looks right, log it' to save.",
        image: "https://macromaxxing.app/help/logMeal3.1.png",
      },
      {
        "@type": "HowToStep",
        name: "View in your Fuel Log",
        text: "Go to the Log tab to see all your logged meals with photos, macro summaries, meal scores, and your eating window timeline.",
        image: "https://macromaxxing.app/help/logMeal4.png",
      },
    ],
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
    />
  );
}

export default function HowToLogAMeal() {
  return (
    <>
      <HowToJsonLd />
      <ArticleJsonLd
        title="How to Log a Meal in Macro Maxxing"
        description="Step-by-step guide to logging meals in Macro Maxxing using AI photo scanning, voice logging, or manual entry with instant macro estimates."
        url="https://macromaxxing.app/help/how-to-log-a-meal"
        datePublished="2026-04-09"
        dateModified="2026-04-09"
      />
      <BreadcrumbJsonLd
        items={[
          { name: "Home", url: "https://macromaxxing.app" },
          { name: "Help", url: "https://macromaxxing.app/help" },
          {
            name: "How to Log a Meal",
            url: "https://macromaxxing.app/help/how-to-log-a-meal",
          },
        ]}
      />
      <FAQPageJsonLd faqs={faqs} />

      <article className="pt-32 pb-20 px-4 sm:px-6">
        <div className="max-w-3xl mx-auto">
          {/* Breadcrumb */}
          <nav className="mb-6 text-sm text-gray-500">
            <Link href="/help" className="hover:text-white transition">
              Help
            </Link>
            <span className="mx-2">/</span>
            <span className="text-gray-300">How to Log a Meal</span>
          </nav>

          <div className="bg-brand-orange/10 text-brand-orange text-xs font-semibold px-3 py-1 rounded-full inline-block mb-4">
            FOOD LOGGING
          </div>
          <h1 className="text-3xl sm:text-5xl font-black mb-6 leading-tight">
            How to Log a Meal
          </h1>
          <p className="text-gray-300 text-lg leading-relaxed mb-4">
            Macro Maxxing gives you three ways to log meals: snap a photo and
            let AI estimate your macros, describe what you ate with your voice,
            or type it in manually. Every meal gets a detailed breakdown of
            calories, protein, carbs, and fat &mdash; plus a Meal Score showing
            how well it matches your goals.
          </p>
          <p className="text-gray-500 text-sm mb-12">
            Last updated: April 2026
          </p>

          {/* Step 1: Open the menu */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Step 1: Tap the + Button on the Hub
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              From the <strong className="text-white">Hub</strong> tab, tap the
              yellow <strong className="text-brand-gold">+</strong> button in
              the bottom-right corner. The quick-action menu expands with
              several options including{" "}
              <strong className="text-white">Saved Meals</strong>,{" "}
              <strong className="text-white">Photo Library</strong>,{" "}
              <strong className="text-white">Camera</strong>,{" "}
              <strong className="text-white">Log a Meal</strong>, and more.
            </p>
            <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
              <Image
                src="/help/logMeal1.png"
                alt="Hub screen with expanded quick-action menu showing Saved Meals, Photo Library, Camera, Log a Meal, Log a Workout, Make a Post, and Find People options"
                width={300}
                height={650}
                className="rounded-lg"
              />
            </div>
          </section>

          {/* Step 2: Choose logging mode */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Step 2: Choose How to Log
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              Tap <strong className="text-brand-orange">Log a Meal</strong> (or
              use one of the shortcuts like Camera or Photo Library). The{" "}
              <strong className="text-white">Log Food</strong> screen opens with
              three modes: <strong className="text-brand-gold">Manual</strong>,{" "}
              <strong className="text-brand-purple">Voice</strong>, and{" "}
              <strong className="text-brand-orange">Photo</strong>.
            </p>

            {/* Photo Mode */}
            <div className="mb-12">
              <h3 className="text-xl font-bold mb-3">
                <span className="text-brand-orange">Photo Mode</span>{" "}
                <span className="text-gray-500 text-sm font-normal">
                  &mdash; AI Food Scanner
                </span>
              </h3>
              <p className="text-gray-400 leading-relaxed mb-4">
                Take a photo of your food or select one from your library.
                The image appears at the top of the screen. Optionally add
                details in the text field (e.g. &ldquo;2 eggs with toast&rdquo;)
                to help the AI be more accurate. Then tap{" "}
                <strong className="text-brand-purple">Analyze Photo</strong> and
                Claude AI will identify every item, estimate portions, and
                calculate your macros.
              </p>
              <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
                <Image
                  src="/help/logMeal2.3.png"
                  alt="Log Food screen in Photo mode showing a meal photo, optional details text field, and purple Analyze Photo button"
                  width={300}
                  height={650}
                  className="rounded-lg"
                />
              </div>
            </div>

            {/* Voice Mode */}
            <div className="mb-12">
              <h3 className="text-xl font-bold mb-3">
                <span className="text-brand-purple">Voice Mode</span>{" "}
                <span className="text-gray-500 text-sm font-normal">
                  &mdash; Describe What You Ate
                </span>
              </h3>
              <p className="text-gray-400 leading-relaxed mb-4">
                Tap the <strong className="text-white">Voice</strong> tab, then
                tap the microphone and describe your meal in natural
                language &mdash; for example,{" "}
                <em className="text-gray-300">
                  &ldquo;chicken curry with white rice&rdquo;
                </em>
                . The AI processes your description and estimates the macros
                automatically.
              </p>
              <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
                <Image
                  src="/help/logMeal2.2.png"
                  alt="Log Food screen in Voice mode showing the microphone button and prompt to tap and describe what you ate"
                  width={300}
                  height={650}
                  className="rounded-lg"
                />
              </div>
            </div>

            {/* Manual Mode */}
            <div className="mb-12">
              <h3 className="text-xl font-bold mb-3">
                <span className="text-brand-gold">Manual Mode</span>{" "}
                <span className="text-gray-500 text-sm font-normal">
                  &mdash; Type It In
                </span>
              </h3>
              <p className="text-gray-400 leading-relaxed mb-4">
                Tap the <strong className="text-white">Manual</strong> tab to
                enter everything yourself. Fill in the food name, calories,
                protein, carbs, and fat. Toggle on{" "}
                <strong className="text-white">Save as Saved Meal</strong> if
                you want to re-log this meal quickly in the future. Then tap{" "}
                <strong className="text-brand-green">Log Food</strong> to save.
              </p>
              <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
                <Image
                  src="/help/logMeal2.1.png"
                  alt="Log Food screen in Manual mode showing fields for food name, calories, protein, carbs, fat, and a Save as Saved Meal toggle"
                  width={300}
                  height={650}
                  className="rounded-lg"
                />
              </div>
            </div>

            {/* Saved Meals */}
            <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
              <div className="absolute top-0 left-0 w-1 h-full bg-brand-gold" />
              <div className="pl-4">
                <h4 className="text-sm font-semibold text-white mb-1">
                  Saved Meals
                </h4>
                <p className="text-gray-400 text-sm">
                  Your saved meals appear as quick-select chips at the top of
                  the Log Food screen. Tap any saved meal to instantly log it
                  again without re-entering details.
                </p>
              </div>
            </div>
          </section>

          {/* Step 3: Review AI Results */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Step 3: Review &amp; Confirm
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              After AI analysis (Photo or Voice mode), the{" "}
              <strong className="text-white">Confirm Food</strong> screen shows
              everything the AI detected. Review the results and adjust anything
              that needs correcting:
            </p>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-8">
              <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
                <Image
                  src="/help/logMeal3.1.png"
                  alt="Confirm Food screen showing AI analysis confidence, food name, total calories, protein, carbs, fat, portion size slider, and meal breakdown with individual items"
                  width={280}
                  height={600}
                  className="rounded-lg"
                />
              </div>
              <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
                <Image
                  src="/help/logMeal3.2.png"
                  alt="Confirm Food screen scrolled down showing full meal breakdown with each ingredient, calories, portion size slider, Save as Saved Meal toggle, and Looks right log it button"
                  width={280}
                  height={600}
                  className="rounded-lg"
                />
              </div>
            </div>

            <div className="space-y-4">
              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-purple" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    AI Confidence
                  </h4>
                  <p className="text-gray-400 text-sm">
                    The AI shows a confidence percentage (e.g. 72% confident).
                    If it&apos;s not fully sure, you&apos;ll see a yellow
                    warning asking you to review. You can always edit the macros
                    or food name.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-green" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Macros &amp; Edit
                  </h4>
                  <p className="text-gray-400 text-sm">
                    See the total calories, protein, carbs, and fat at a glance.
                    Tap{" "}
                    <strong className="text-white">Edit Macros</strong> to
                    manually adjust any value if the AI estimate needs
                    correcting.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-orange" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Portion Size
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Use the slider to scale the portion between 0.5x and 3x.
                    All macros update in real time as you adjust. This is useful
                    when you ate more or less than a standard serving.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-teal" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Meal Breakdown
                  </h4>
                  <p className="text-gray-400 text-sm">
                    The AI lists every individual ingredient it detected with
                    its portion weight and calorie count &mdash; for example,
                    grilled chicken breast (170g, 281 kcal), cooked quinoa
                    (130g, 160 kcal), steamed broccoli, and more.
                  </p>
                </div>
              </div>
            </div>

            <p className="text-gray-400 leading-relaxed mt-6">
              When everything looks good, tap{" "}
              <strong className="text-brand-purple">
                Looks right, log it
              </strong>{" "}
              to save the meal to your Fuel Log.
            </p>
          </section>

          {/* Step 4: View Fuel Log */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Step 4: View Your Fuel Log
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              Head to the <strong className="text-white">Log</strong> tab and
              make sure <strong className="text-white">Fuel</strong> is
              selected. Here you&apos;ll see your full day at a glance:
            </p>
            <ul className="list-disc list-inside text-gray-400 space-y-2 mb-6">
              <li>
                <strong className="text-white">Eating Window</strong> &mdash;
                a timeline showing when you ate during the day
              </li>
              <li>
                All logged meals with their photo, macro summary, and{" "}
                <strong className="text-white">Meal Score</strong>
              </li>
              <li>
                <strong className="text-white">AI Nutrition Coach</strong>{" "}
                &mdash; tap &ldquo;Get My Recommendation&rdquo; for a
                personalized debrief reviewing your meals, macro distribution,
                and timing
              </li>
            </ul>

            <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
              <Image
                src="/help/logMeal4.png"
                alt="Fuel Log tab showing eating window timeline, three logged meals with photos and macro summaries, meal scores, and the AI Nutrition Coach recommendation button"
                width={300}
                height={650}
                className="rounded-lg"
              />
            </div>
          </section>

          {/* Step 5: Meal Score */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Understanding Your Meal Score
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              Tap any meal in the Fuel Log to see its{" "}
              <strong className="text-white">Meal Score</strong> &mdash; a
              number from 0 to 100 that measures how closely the meal&apos;s
              macro distribution matches your personal goals. The breakdown
              shows each macro&apos;s percentage in the meal vs. your target,
              so you can see exactly where to adjust.
            </p>

            <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center mb-6">
              <Image
                src="/help/logMeal5.png"
                alt="Meal Score detail view showing a score of 81, with a breakdown comparing protein, carbs, and fat percentages in the meal vs personal goal percentages"
                width={300}
                height={650}
                className="rounded-lg"
              />
            </div>

            <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
              <div className="absolute top-0 left-0 w-1 h-full bg-brand-green" />
              <div className="pl-4">
                <h4 className="text-sm font-semibold text-white mb-1">
                  How to Score Higher
                </h4>
                <p className="text-gray-400 text-sm">
                  A score of 100 means the meal&apos;s caloric ratio of protein,
                  carbs, and fat perfectly matches your target percentages. The
                  closer each macro is to your goal, the higher the score.
                  Scores are shown for meals over 300 calories.
                </p>
              </div>
            </div>
          </section>

          {/* Sharing */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Share Your Fuel Log as a Post
            </h2>
            <p className="text-gray-400 leading-relaxed mb-4">
              Want to share what you ate with the community? When creating a
              post, select the{" "}
              <span className="text-brand-orange font-semibold">Fuel Log</span>{" "}
              label and your day&apos;s meals will be automatically attached
              with each food entry and calorie count.
            </p>
            <div className="bg-brand-orange/10 border border-brand-orange/20 rounded-lg p-4 mb-4">
              <p className="text-brand-orange text-sm font-semibold">
                Earns Aura Points!
              </p>
              <p className="text-gray-400 text-sm mt-1">
                Posting with the Fuel Log label earns you aura points toward
                your level and streak. Stay consistent to level up faster.
              </p>
            </div>
            <p className="text-gray-400 text-sm">
              See our{" "}
              <Link
                href="/help/how-to-make-a-post"
                className="text-brand-purple hover:underline"
              >
                How to Make a Post
              </Link>{" "}
              guide for the full walkthrough on creating posts.
            </p>
          </section>

          {/* FAQ */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-6">
              Frequently Asked Questions
            </h2>
            <div className="space-y-4">
              {faqs.map((faq) => (
                <details
                  key={faq.question}
                  className="bg-brand-card rounded-xl border border-white/5 group"
                >
                  <summary className="p-5 cursor-pointer text-white font-semibold text-sm list-none flex items-center justify-between">
                    {faq.question}
                    <span className="text-gray-500 group-open:rotate-180 transition-transform ml-4 shrink-0">
                      &#9662;
                    </span>
                  </summary>
                  <div className="px-5 pb-5 text-gray-400 text-sm leading-relaxed border-t border-white/5 pt-4">
                    {faq.answer}
                  </div>
                </details>
              ))}
            </div>
          </section>

          {/* Back to Help */}
          <div className="border-t border-white/5 pt-8">
            <Link
              href="/help"
              className="text-brand-purple hover:text-brand-purple/80 text-sm font-semibold transition"
            >
              &larr; Back to Help &amp; Guides
            </Link>
          </div>
        </div>
      </article>
    </>
  );
}
