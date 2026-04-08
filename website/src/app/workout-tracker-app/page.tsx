import type { Metadata } from "next";
import { DownloadCTA } from "@/components/DownloadCTA";
import { ArticleJsonLd } from "@/components/JsonLd";

export const metadata: Metadata = {
  title: "Workout Tracker App with Auto Macro Adjustments",
  description:
    "Log workouts by voice or manually. Auto-adjust daily macro targets based on workout type using ISSN & ACSM guidelines. iOS workout tracker.",
  keywords: [
    "workout tracker app",
    "workout logging app",
    "exercise tracker with macros",
    "workout macro adjustment",
    "voice workout logger",
    "fitness tracker app",
    "gym tracker app",
    "strength training tracker",
  ],
};

export default function WorkoutTrackerApp() {
  return (
    <>
      <ArticleJsonLd
        title="Workout Tracker App with Auto Macro Adjustments"
        description="Log workouts by voice or manually and auto-adjust daily macros based on ISSN & ACSM guidelines."
        url="https://macromaxxing.app/workout-tracker-app"
      />

      <article className="pt-32 pb-12 px-4 sm:px-6">
        <div className="max-w-3xl mx-auto">
          <div className="bg-brand-green/10 text-brand-green text-xs font-semibold px-3 py-1 rounded-full inline-block mb-4">
            WORKOUTS
          </div>
          <h1 className="text-3xl sm:text-5xl font-black mb-6 leading-tight">
            Log Workouts.
            <br />
            <span className="text-gradient">Auto-Adjust Your Macros.</span>
          </h1>
          <p className="text-gray-400 text-lg leading-relaxed mb-12">
            The first workout tracker that automatically adjusts your daily
            nutrition targets based on your training. Log by voice, pick a type,
            and your macros update in real-time.
          </p>

          <h2 className="text-2xl font-bold mb-6">6 Workout Types, Smart Adjustments</h2>
          <p className="text-gray-400 leading-relaxed mb-6">
            Different workouts demand different nutrition. A heavy strength
            session needs more protein and carbs than a yoga class. Macro
            Maxxing knows this and adjusts accordingly.
          </p>

          <div className="grid grid-cols-2 sm:grid-cols-3 gap-4 mb-12">
            {[
              { icon: "🏋️", label: "Strength", adjustment: "+140 kcal, +12g protein, +23g carbs" },
              { icon: "🏃", label: "Cardio", adjustment: "+200 kcal, +30g carbs" },
              { icon: "⚡", label: "HIIT", adjustment: "+180 kcal, +8g protein, +25g carbs" },
              { icon: "🧘", label: "Flex / Yoga", adjustment: "+60 kcal" },
              { icon: "😴", label: "Rest Day", adjustment: "No adjustment" },
              { icon: "🏃‍♂️", label: "Other", adjustment: "Custom adjustment" },
            ].map((type, i) => (
              <div
                key={i}
                className="bg-brand-card rounded-xl p-4 border border-white/5 text-center"
              >
                <div className="text-3xl mb-2">{type.icon}</div>
                <p className="font-semibold text-white text-sm mb-1">
                  {type.label}
                </p>
                <p className="text-gray-500 text-xs">{type.adjustment}</p>
              </div>
            ))}
          </div>

          <h2 className="text-2xl font-bold mb-4">Voice Workout Logging</h2>
          <p className="text-gray-400 leading-relaxed mb-4">
            Just finished a set? Tap the mic and say &ldquo;30 minute run, about
            200 calories.&rdquo; AI parses your description and fills in the
            workout details — type, duration, and estimated calorie burn.
          </p>
          <p className="text-gray-400 leading-relaxed mb-8">
            No fiddling with dropdowns or number pickers when you&apos;re
            catching your breath between sets.
          </p>

          <div className="bg-brand-card rounded-xl p-6 border border-white/5 mb-12">
            <h3 className="text-lg font-semibold text-white mb-4">
              How Macro Adjustments Work
            </h3>
            <div className="space-y-4">
              <div className="flex items-start gap-3">
                <span className="bg-brand-purple/20 text-brand-purple rounded-full w-7 h-7 flex items-center justify-center text-sm font-bold shrink-0">
                  1
                </span>
                <p className="text-gray-400 text-sm">
                  Log your workout — choose a type (or let voice AI detect it)
                  and enter duration + estimated calories burned.
                </p>
              </div>
              <div className="flex items-start gap-3">
                <span className="bg-brand-purple/20 text-brand-purple rounded-full w-7 h-7 flex items-center justify-center text-sm font-bold shrink-0">
                  2
                </span>
                <p className="text-gray-400 text-sm">
                  Macro Maxxing calculates additional macro needs based on ISSN
                  & ACSM sports nutrition guidelines for your workout type.
                </p>
              </div>
              <div className="flex items-start gap-3">
                <span className="bg-brand-purple/20 text-brand-purple rounded-full w-7 h-7 flex items-center justify-center text-sm font-bold shrink-0">
                  3
                </span>
                <p className="text-gray-400 text-sm">
                  Your daily macro targets update in real-time. The adjustment
                  applies to today only and resets tomorrow.
                </p>
              </div>
              <div className="flex items-start gap-3">
                <span className="bg-brand-purple/20 text-brand-purple rounded-full w-7 h-7 flex items-center justify-center text-sm font-bold shrink-0">
                  4
                </span>
                <p className="text-gray-400 text-sm">
                  Toggle macro adjustments on or off per workout — you&apos;re
                  always in control.
                </p>
              </div>
            </div>
          </div>

          <h2 className="text-2xl font-bold mb-4">Saved Workout Templates</h2>
          <p className="text-gray-400 leading-relaxed mb-4">
            Do the same workout every Monday? Save it as a template. Next time,
            just tap your saved &ldquo;run — 30m · 200 cal&rdquo; chip and
            it&apos;s logged instantly. No re-entering details.
          </p>
          <p className="text-gray-400 leading-relaxed">
            Templates save the workout name, type, duration, and calorie
            estimate — everything you need for a one-tap log.
          </p>
        </div>
      </article>

      <DownloadCTA
        headline="Train hard. Fuel smart."
        subheadline="Download Macro Maxxing and let your workouts drive your nutrition."
      />
    </>
  );
}
