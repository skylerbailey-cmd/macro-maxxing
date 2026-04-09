import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import {
  ArticleJsonLd,
  BreadcrumbJsonLd,
  FAQPageJsonLd,
} from "@/components/JsonLd";

export const metadata: Metadata = {
  title: "How to Log a Workout in Macro Maxxing — Step-by-Step Guide",
  description:
    "Learn how to log workouts in Macro Maxxing using manual entry or voice logging with AI. Track duration, calories burned, workout type, and get automatic macro goal adjustments. Earn aura points for every workout you log.",
  keywords: [
    "how to log a workout macro maxxing",
    "macro maxxing workout tracker",
    "voice workout logging",
    "AI workout tracker",
    "log exercise macro tracker",
    "workout macro adjustments",
    "track calories burned workout",
    "fitness app workout log",
    "macro maxxing help",
    "workout tracking app iOS",
  ],
  openGraph: {
    title: "How to Log a Workout in Macro Maxxing — Step-by-Step Guide",
    description:
      "Log workouts manually or with your voice. Get AI-powered macro adjustments and earn aura points. Full step-by-step guide.",
    url: "https://macromaxxing.app/help/how-to-log-a-workout",
    type: "article",
  },
  alternates: {
    canonical: "https://macromaxxing.app/help/how-to-log-a-workout",
  },
};

const faqs = [
  {
    question: "How do I log a workout in Macro Maxxing?",
    answer:
      "Open Macro Maxxing, tap the yellow + button on the Hub screen, then select 'Log a Workout.' You can log manually by filling in the workout name, duration, calories burned, and workout type, or use Voice mode to describe your workout and let AI fill in the details automatically.",
  },
  {
    question: "Does Macro Maxxing adjust my macros after a workout?",
    answer:
      "Yes. When you enable 'Apply macro adjustments,' Macro Maxxing automatically adjusts your daily macro goals based on the workout type, duration, and calories burned. For example, a 45-minute strength workout might add +140 kcal, +23g carbs, and +12g protein to your daily targets. These adjustments follow ISSN and ACSM guidelines.",
  },
  {
    question: "Can I log a workout with my voice in Macro Maxxing?",
    answer:
      "Yes. On the Log a Workout screen, tap the 'Voice' tab, then tap the microphone to start recording. Describe your workout naturally — for example, 'I did five shoulder workouts, three sets each with 10 reps, then 15 minutes of jump rope, and 10 minutes of abs.' Tap to stop, then tap 'Generate with AI' and the app will fill in the workout name, duration, calories burned, and type automatically.",
  },
  {
    question: "What workout types does Macro Maxxing support?",
    answer:
      "Macro Maxxing supports six workout types: Strength, Cardio, HIIT, Flex/Yoga, Rest Day, and Other. Each type affects how your macro goals are adjusted after logging.",
  },
  {
    question: "Can I save a workout as a template in Macro Maxxing?",
    answer:
      "Yes. When logging a workout, toggle on 'Save as Saved Workout' to save it as a template. The next time you log a workout, you can quickly select it from your saved workouts instead of entering everything from scratch.",
  },
  {
    question: "Do I earn points for logging workouts in Macro Maxxing?",
    answer:
      "Yes. Logging workouts and sharing them with the Workout post label earns you aura points. These contribute to your XP, level, and daily streak displayed on the Hub screen.",
  },
  {
    question: "Where can I see my logged workouts in Macro Maxxing?",
    answer:
      "Go to the Log tab and tap 'Duel' to see all your workouts for the day. You'll see total calories burned, total workout time, macro goal adjustments, and each individual workout entry with its details. Tap any workout to edit it.",
  },
];

function HowToJsonLd() {
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "HowTo",
    name: "How to Log a Workout in Macro Maxxing",
    description:
      "Step-by-step guide to logging workouts in the Macro Maxxing iOS app using manual entry or AI-powered voice logging.",
    totalTime: "PT2M",
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
        name: "Select Log a Workout",
        text: "From the action menu, tap 'Log a Workout' to open the workout logging screen.",
        image: "https://macromaxxing.app/help/step1.png",
      },
      {
        "@type": "HowToStep",
        name: "Enter workout details",
        text: "Use Manual mode to type your workout name, duration, calories burned, time completed, and workout type. Or switch to Voice mode, describe your workout, and tap 'Generate with AI' to auto-fill the fields.",
        image: "https://macromaxxing.app/help/logWorkout1.png",
      },
      {
        "@type": "HowToStep",
        name: "Configure options and log",
        text: "Optionally toggle on 'Save as Saved Workout' for quick access next time and 'Apply macro adjustments' to update your daily macro goals. Then tap 'Log Workout' to save.",
        image: "https://macromaxxing.app/help/logWorkout4.png",
      },
      {
        "@type": "HowToStep",
        name: "View your workout log",
        text: "Go to the Log tab and tap 'Duel' to see all your workouts for the day, including total calories burned, total time, and macro goal adjustments.",
        image: "https://macromaxxing.app/help/logWorkout5.png",
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

export default function HowToLogAWorkout() {
  return (
    <>
      <HowToJsonLd />
      <ArticleJsonLd
        title="How to Log a Workout in Macro Maxxing"
        description="Step-by-step guide to logging workouts in Macro Maxxing using manual entry or AI voice logging, with automatic macro goal adjustments."
        url="https://macromaxxing.app/help/how-to-log-a-workout"
        datePublished="2026-04-09"
        dateModified="2026-04-09"
      />
      <BreadcrumbJsonLd
        items={[
          { name: "Home", url: "https://macromaxxing.app" },
          { name: "Help", url: "https://macromaxxing.app/help" },
          {
            name: "How to Log a Workout",
            url: "https://macromaxxing.app/help/how-to-log-a-workout",
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
            <span className="text-gray-300">How to Log a Workout</span>
          </nav>

          <div className="bg-brand-teal/10 text-brand-teal text-xs font-semibold px-3 py-1 rounded-full inline-block mb-4">
            WORKOUT TRACKING
          </div>
          <h1 className="text-3xl sm:text-5xl font-black mb-6 leading-tight">
            How to Log a Workout
          </h1>
          <p className="text-gray-300 text-lg leading-relaxed mb-4">
            Macro Maxxing lets you log workouts manually or by describing them
            with your voice. When you log a workout, the app can automatically
            adjust your daily macro goals based on the exercise type, duration,
            and calories burned &mdash; so your nutrition stays aligned with your
            training.
          </p>
          <p className="text-gray-500 text-sm mb-12">
            Last updated: April 2026
          </p>

          {/* Step 1: Home Screen */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Step 1: Tap the + Button on the Hub
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              From the <strong className="text-white">Hub</strong> tab (your
              home screen), tap the yellow{" "}
              <strong className="text-brand-gold">+</strong> button in the
              bottom-right corner to open the quick-action menu.
            </p>
            <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
              <Image
                src="/help/Home Screen.png"
                alt="Macro Maxxing Hub screen showing the yellow plus button in the bottom-right corner"
                width={300}
                height={650}
                className="rounded-lg"
              />
            </div>
          </section>

          {/* Step 2: Select Log a Workout */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Step 2: Select &ldquo;Log a Workout&rdquo;
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              The action menu shows four options. Tap{" "}
              <strong className="text-brand-teal">Log a Workout</strong> to open
              the workout logging screen.
            </p>
            <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
              <Image
                src="/help/step1.png"
                alt="Expanded quick-action menu showing Log a Meal, Log a Workout, Make a Post, and Find People options"
                width={300}
                height={650}
                className="rounded-lg"
              />
            </div>
          </section>

          {/* Step 3: Manual Mode */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Step 3: Log Your Workout
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              The <strong className="text-white">Log a Workout</strong> screen
              has two modes:{" "}
              <strong className="text-brand-gold">Manual</strong> and{" "}
              <strong className="text-brand-teal">Voice</strong>. Choose
              whichever fits your flow.
            </p>

            {/* Manual */}
            <div className="mb-12">
              <h3 className="text-xl font-bold mb-3">
                <span className="text-brand-gold">Manual Entry</span>
              </h3>
              <p className="text-gray-400 leading-relaxed mb-4">
                In Manual mode, fill in the following fields:
              </p>
              <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center mb-6">
                <Image
                  src="/help/logWorkout1.png"
                  alt="Manual workout entry screen showing fields for workout name, duration, calories burned, time completed, and workout type"
                  width={300}
                  height={650}
                  className="rounded-lg"
                />
              </div>

              <div className="space-y-4 mb-6">
                <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                  <div className="absolute top-0 left-0 w-1 h-full bg-brand-gold" />
                  <div className="pl-4">
                    <h4 className="text-sm font-semibold text-white mb-1">
                      Workout Name
                    </h4>
                    <p className="text-gray-400 text-sm">
                      A descriptive name for your session (e.g. &ldquo;Upper
                      Body, 5 Mile Run&rdquo;).
                    </p>
                  </div>
                </div>

                <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                  <div className="absolute top-0 left-0 w-1 h-full bg-brand-green" />
                  <div className="pl-4">
                    <h4 className="text-sm font-semibold text-white mb-1">
                      Duration &amp; Calories Burned
                    </h4>
                    <p className="text-gray-400 text-sm">
                      Enter the workout duration in minutes and estimated
                      calories burned.
                    </p>
                  </div>
                </div>

                <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                  <div className="absolute top-0 left-0 w-1 h-full bg-brand-purple" />
                  <div className="pl-4">
                    <h4 className="text-sm font-semibold text-white mb-1">
                      Time Completed
                    </h4>
                    <p className="text-gray-400 text-sm">
                      The time you finished the workout. Defaults to the current
                      time.
                    </p>
                  </div>
                </div>

                <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                  <div className="absolute top-0 left-0 w-1 h-full bg-brand-teal" />
                  <div className="pl-4">
                    <h4 className="text-sm font-semibold text-white mb-1">
                      Workout Type
                    </h4>
                    <p className="text-gray-400 text-sm">
                      Choose from{" "}
                      <strong className="text-white">Strength</strong>,{" "}
                      <strong className="text-white">Cardio</strong>,{" "}
                      <strong className="text-white">HIIT</strong>,{" "}
                      <strong className="text-white">Flex / Yoga</strong>,{" "}
                      <strong className="text-white">Rest Day</strong>, or{" "}
                      <strong className="text-white">Other</strong>. The workout
                      type affects how your macro goals are adjusted.
                    </p>
                  </div>
                </div>
              </div>
            </div>

            {/* Voice */}
            <div className="mb-12">
              <h3 className="text-xl font-bold mb-3">
                <span className="text-brand-teal">Voice Logging with AI</span>
              </h3>
              <p className="text-gray-400 leading-relaxed mb-4">
                Prefer to talk? Switch to the{" "}
                <strong className="text-white">Voice</strong> tab and tap the
                microphone to start recording. Describe your workout in natural
                language &mdash; for example:{" "}
                <em className="text-gray-300">
                  &ldquo;I did five different shoulder workouts, three sets each
                  with 10 reps. Then I jumped rope for 15 minutes. And I did
                  about 10 minutes of abs.&rdquo;
                </em>
              </p>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-6">
                <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
                  <Image
                    src="/help/logWorkout2.png"
                    alt="Voice recording in progress, showing the microphone listening and transcribed workout description"
                    width={280}
                    height={600}
                    className="rounded-lg"
                  />
                </div>
                <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
                  <Image
                    src="/help/logWorkout3.png"
                    alt="Voice recording complete with transcribed text and Generate with AI button"
                    width={280}
                    height={600}
                    className="rounded-lg"
                  />
                </div>
              </div>

              <p className="text-gray-400 leading-relaxed mb-4">
                Once you stop recording, your description appears as text. Tap{" "}
                <strong className="text-brand-gold">
                  Generate with AI
                </strong>{" "}
                and Macro Maxxing will automatically fill in the workout name,
                duration, calories burned, and workout type based on what you
                said.
              </p>
            </div>
          </section>

          {/* Step 4: Macro Adjustments & Options */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Step 4: Review Macro Adjustments &amp; Log
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              Before you log, check the{" "}
              <strong className="text-white">Macro Adjustment</strong> preview
              at the bottom. This shows how your daily macro goals will change
              based on the workout. For example, a 45-minute Strength workout
              might add{" "}
              <span className="text-brand-green">+140 kcal</span>,{" "}
              <span className="text-brand-green">+23g carbs</span>, and{" "}
              <span className="text-brand-green">+12g protein</span> to your
              daily targets. These adjustments follow ISSN and ACSM guidelines.
            </p>

            <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center mb-8">
              <Image
                src="/help/logWorkout4.png"
                alt="Completed workout form with AI-generated fields filled in, Save as Saved Workout and Apply macro adjustments toggles enabled, and Log Workout button"
                width={300}
                height={650}
                className="rounded-lg"
              />
            </div>

            <div className="space-y-4">
              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-orange" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Save as Saved Workout
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Toggle this on to save the workout as a template. Next time
                    you can quick-select it instead of entering everything again.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-green" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Apply Macro Adjustments
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Toggle this on to automatically update your daily macro goals
                    for the workout you just logged. Your calorie, carb,
                    protein, and fat targets adjust based on workout type and
                    intensity.
                  </p>
                </div>
              </div>
            </div>

            <p className="text-gray-400 leading-relaxed mt-6">
              When everything looks good, tap the green{" "}
              <strong className="text-brand-green">Log Workout</strong> button
              at the bottom to save your workout.
            </p>

            <div className="bg-brand-teal/10 border border-brand-teal/20 rounded-lg p-4 mt-6">
              <p className="text-brand-teal text-sm font-semibold">
                Earns Aura Points!
              </p>
              <p className="text-gray-400 text-sm mt-1">
                Every workout you log earns you aura points toward your level
                and daily streak. Stay consistent to climb the leaderboard.
              </p>
            </div>
          </section>

          {/* Step 5: View Your Workouts */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Step 5: View Your Workout Log
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              After logging, head to the{" "}
              <strong className="text-white">Log</strong> tab and tap{" "}
              <strong className="text-white">Duel</strong> to see your workout
              history for the day. You&apos;ll see:
            </p>
            <ul className="list-disc list-inside text-gray-400 space-y-2 mb-6">
              <li>
                <strong className="text-white">Total Calories Burned</strong>{" "}
                and <strong className="text-white">Total Time</strong> across
                all workouts
              </li>
              <li>
                <strong className="text-white">Macro Goal Adjustments</strong>{" "}
                showing how much was added to each macro (calories, carbs,
                protein, fat)
              </li>
              <li>
                Each individual workout entry with its name, time logged,
                duration, and calories burned
              </li>
            </ul>
            <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
              <Image
                src="/help/logWorkout5.png"
                alt="Log tab Duel view showing total calories burned, total workout time, macro goal adjustments, and list of individual workouts"
                width={300}
                height={650}
                className="rounded-lg"
              />
            </div>
          </section>

          {/* Step 6: Edit a Workout */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Editing a Workout
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              Made a mistake? Tap any workout entry in the Log tab to open the{" "}
              <strong className="text-white">Edit Workout</strong> screen. From
              here you can update the name, type, duration, calories burned, or
              time logged. Tap{" "}
              <strong className="text-white">Save</strong> to apply your
              changes, or{" "}
              <span className="text-red-400">Delete Entry</span> to remove it.
            </p>
            <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
              <Image
                src="/help/logWorkout6.png"
                alt="Edit Workout screen showing editable fields for name, type, duration, calories burned, and time, with Save and Delete Entry options"
                width={300}
                height={650}
                className="rounded-lg"
              />
            </div>
          </section>

          {/* Sharing */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Share Your Workout as a Post
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              Want to share your training with the community? When creating a
              post, select the{" "}
              <span className="text-brand-teal font-semibold">Workout</span>{" "}
              label and your day&apos;s workouts will be automatically attached.
              The post shows each exercise with its duration and calories burned,
              plus the total session summary.
            </p>
            <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center mb-4">
              <Image
                src="/help/logWorkout7.png"
                alt="New Post screen with Workout label, showing today's workouts attached with exercise details, duration, and calories"
                width={300}
                height={650}
                className="rounded-lg"
              />
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
