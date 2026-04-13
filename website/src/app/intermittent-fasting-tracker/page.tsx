import type { Metadata } from "next";
import { DownloadCTA } from "@/components/DownloadCTA";
import { ArticleJsonLd } from "@/components/JsonLd";

export const metadata: Metadata = {
  title: "Intermittent Fasting Tracker with Macro Integration",
  description:
    "Track intermittent fasting with a persistent timer that syncs with your macro goals. Support for 16:8, 20:4, and custom fasting windows. Available on iOS.",
  keywords: [
    "intermittent fasting tracker",
    "intermittent fasting app",
    "fasting timer app",
    "16:8 fasting app",
    "IF tracker",
    "fasting app with macros",
    "intermittent fasting timer",
    "best fasting app",
  ],
};

export default function IntermittentFastingTracker() {
  return (
    <>
      <ArticleJsonLd
        title="Intermittent Fasting Tracker with Macro Integration"
        description="Track intermittent fasting with a persistent timer that syncs with your macro goals."
        url="https://macromaxxing.app/intermittent-fasting-tracker"
      />

      <article className="pt-32 pb-12 px-4 sm:px-6">
        <div className="max-w-3xl mx-auto">
          <div className="bg-brand-teal/10 text-brand-teal text-xs font-semibold px-3 py-1 rounded-full inline-block mb-4">
            FASTING
          </div>
          <h1 className="text-3xl sm:text-5xl font-black mb-6 leading-tight">
            Intermittent Fasting Tracker
            <br />
            <span className="text-gradient">That Talks to Your Macros</span>
          </h1>
          <p className="text-gray-400 text-lg leading-relaxed mb-12">
            Most fasting apps track your eating window. Macromaxxing does that{" "}
            <em>and</em> integrates with your daily macro tracking — so you know
            exactly what to eat during your feeding window.
          </p>

          <h2 className="text-2xl font-bold mb-4">
            Why Fasting + Macros Together?
          </h2>
          <p className="text-gray-400 leading-relaxed mb-4">
            Intermittent fasting restricts <em>when</em> you eat. Macro tracking
            controls <em>what</em> you eat. Together, they&apos;re the most
            effective combination for body composition — but most apps make you
            use two separate tools.
          </p>
          <p className="text-gray-400 leading-relaxed mb-8">
            Macromaxxing is the only app that combines a persistent fasting
            timer with AI-powered macro tracking in one interface.
          </p>

          <h2 className="text-2xl font-bold mb-6">Fasting Timer Features</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-12">
            {[
              {
                icon: "⏱️",
                title: "Persistent Timer",
                desc: "Timer survives app restarts, phone reboots, and background kills. Your fast never gets lost.",
              },
              {
                icon: "🔄",
                title: "Custom Windows",
                desc: "16:8, 18:6, 20:4, OMAD, or any custom fasting window that fits your lifestyle.",
              },
              {
                icon: "📊",
                title: "Fasting History",
                desc: "Log completed fasts with start/end timestamps. Track your consistency over time.",
              },
              {
                icon: "🔔",
                title: "Smart Reminders",
                desc: "Get notified when your eating window opens and closes so you never miss your timing.",
              },
              {
                icon: "🏠",
                title: "Hub Integration",
                desc: "Fasting timer displays right on your home hub alongside daily macro rings for a complete overview.",
              },
              {
                icon: "🔥",
                title: "Streak Compatible",
                desc: "Fasting consistency contributes to your daily engagement and Aura XP progression.",
              },
            ].map((feature, i) => (
              <div
                key={i}
                className="bg-brand-card rounded-xl p-5 border border-white/5"
              >
                <div className="text-2xl mb-2">{feature.icon}</div>
                <h3 className="font-semibold text-white mb-1 text-sm">
                  {feature.title}
                </h3>
                <p className="text-gray-400 text-sm">{feature.desc}</p>
              </div>
            ))}
          </div>

          <h2 className="text-2xl font-bold mb-4">
            Common Fasting Protocols We Support
          </h2>
          <div className="space-y-3 mb-12">
            {[
              {
                protocol: "16:8",
                desc: "Fast 16 hours, eat in an 8-hour window. The most popular IF protocol.",
              },
              {
                protocol: "18:6",
                desc: "Fast 18 hours, eat in a 6-hour window. A step up for experienced fasters.",
              },
              {
                protocol: "20:4",
                desc: "Fast 20 hours, eat in a 4-hour window. Also known as the Warrior Diet.",
              },
              {
                protocol: "OMAD",
                desc: "One Meal A Day. A 23:1 fast with all calories in a single meal.",
              },
              {
                protocol: "Custom",
                desc: "Set any fasting and eating window that fits your schedule.",
              },
            ].map((item, i) => (
              <div
                key={i}
                className="bg-brand-card rounded-xl px-5 py-4 border border-white/5 flex items-center gap-4"
              >
                <span className="text-brand-teal font-bold text-lg min-w-[60px]">
                  {item.protocol}
                </span>
                <p className="text-gray-400 text-sm">{item.desc}</p>
              </div>
            ))}
          </div>

          <h2 className="text-2xl font-bold mb-4">
            Log Your Meals With AI During Your Eating Window
          </h2>
          <p className="text-gray-400 leading-relaxed mb-4">
            When your eating window opens, make every meal count. Use Macro
            Maxxing&apos;s AI photo scanner or voice logging to quickly track
            your meals and ensure you&apos;re hitting your macro targets within
            your feeding window.
          </p>
          <p className="text-gray-400 leading-relaxed">
            With saved meal templates, your go-to meals are just a tap away —
            so you can focus on eating, not logging.
          </p>
        </div>
      </article>

      <DownloadCTA
        headline="Fast smarter, not just longer."
        subheadline="Download Macromaxxing and sync your fasting with your macros."
      />
    </>
  );
}
