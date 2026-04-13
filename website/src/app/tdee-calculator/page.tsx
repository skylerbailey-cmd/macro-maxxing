import { Metadata } from "next";
import { ArticleJsonLd } from "@/components/JsonLd";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "TDEE Calculator & Macro Tracker — Know Your Numbers | Macromaxxing",
  description:
    "Calculate your TDEE (Total Daily Energy Expenditure) and track macros with AI. Macromaxxing helps you find your maintenance calories, set the right deficit or surplus, and stay on track with streaks and leaderboards.",
  keywords: [
    "TDEE calculator",
    "TDEE calculator app",
    "total daily energy expenditure",
    "maintenance calories calculator",
    "calorie calculator app",
    "macro calculator",
    "TDEE tracker",
    "BMR calculator app",
    "calorie needs calculator",
    "how many calories should I eat",
  ],
};

export default function TDEECalculatorPage() {
  return (
    <>
      <ArticleJsonLd
        title="TDEE Calculator & Macro Tracker — Know Your Numbers"
        description="Calculate your TDEE and track macros with AI. Find your maintenance calories, set targets, and stay on track."
        url="https://macromaxxing.app/tdee-calculator"
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-gold/20 via-dark to-brand-cyan/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-gold/20 text-brand-gold text-sm font-semibold mb-6">
              TDEE
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              Know Your Numbers,{" "}
              <span className="text-gradient-gold">Hit Your Goals</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-8">
              Your TDEE (Total Daily Energy Expenditure) is the foundation of
              any nutrition plan. Macromaxxing helps you calculate it, set the
              right calorie target, and track with AI precision — all with
              streaks and leaderboards to keep you consistent.
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-gold hover:bg-brand-gold/80 text-dark font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Calculate & Track 
            </a>
          </div>
        </section>

        {/* What is TDEE */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            What Is TDEE and Why Does It Matter?
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            TDEE stands for Total Daily Energy Expenditure — the total number of
            calories your body burns in a day, including your basal metabolic
            rate (BMR), physical activity, and the thermic effect of food.
            Knowing your TDEE is essential because:
          </p>
          <div className="grid md:grid-cols-3 gap-6 mb-8">
            <div className="bg-white/5 border border-white/10 rounded-2xl p-6 text-center">
              <div className="text-3xl mb-3">📉</div>
              <h3 className="font-bold mb-2">Fat Loss</h3>
              <p className="text-gray-400 text-sm">
                Eat below your TDEE (deficit) to lose fat. A 300-500 kcal
                deficit is sustainable and effective.
              </p>
            </div>
            <div className="bg-white/5 border border-white/10 rounded-2xl p-6 text-center">
              <div className="text-3xl mb-3">⚖️</div>
              <h3 className="font-bold mb-2">Maintenance</h3>
              <p className="text-gray-400 text-sm">
                Eat at your TDEE to maintain your current weight and body
                composition.
              </p>
            </div>
            <div className="bg-white/5 border border-white/10 rounded-2xl p-6 text-center">
              <div className="text-3xl mb-3">📈</div>
              <h3 className="font-bold mb-2">Muscle Gain</h3>
              <p className="text-gray-400 text-sm">
                Eat above your TDEE (surplus) to build muscle. A 200-400 kcal
                surplus supports lean gains.
              </p>
            </div>
          </div>
        </section>

        {/* TDEE Formula */}
        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-4xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold mb-6">
              How TDEE Is Calculated
            </h2>
            <p className="text-gray-300 text-lg mb-8">
              TDEE is calculated by multiplying your Basal Metabolic Rate (BMR)
              by an activity factor. The most commonly used formula is the
              Mifflin-St Jeor equation:
            </p>
            <div className="bg-white/5 border border-white/10 rounded-2xl p-6 md:p-8 mb-8">
              <h3 className="text-lg font-bold mb-4 text-brand-gold">
                Mifflin-St Jeor BMR Formula
              </h3>
              <div className="space-y-3 font-mono text-gray-300">
                <p>
                  <span className="text-brand-purple">Men:</span> BMR = (10 ×
                  weight in kg) + (6.25 × height in cm) - (5 × age) + 5
                </p>
                <p>
                  <span className="text-brand-purple">Women:</span> BMR = (10 ×
                  weight in kg) + (6.25 × height in cm) - (5 × age) - 161
                </p>
              </div>
            </div>
            <div className="bg-white/5 border border-white/10 rounded-2xl p-6 md:p-8">
              <h3 className="text-lg font-bold mb-4 text-brand-gold">
                Activity Multipliers
              </h3>
              <div className="space-y-3">
                {[
                  { level: "Sedentary", mult: "BMR × 1.2", desc: "Little to no exercise" },
                  { level: "Lightly Active", mult: "BMR × 1.375", desc: "Exercise 1-3 days/week" },
                  { level: "Moderately Active", mult: "BMR × 1.55", desc: "Exercise 3-5 days/week" },
                  { level: "Very Active", mult: "BMR × 1.725", desc: "Exercise 6-7 days/week" },
                  { level: "Extremely Active", mult: "BMR × 1.9", desc: "Intense training + physical job" },
                ].map((row) => (
                  <div
                    key={row.level}
                    className="flex flex-col md:flex-row md:items-center gap-1 md:gap-4"
                  >
                    <span className="font-semibold text-white w-40">
                      {row.level}
                    </span>
                    <span className="font-mono text-brand-gold w-32">
                      {row.mult}
                    </span>
                    <span className="text-gray-400 text-sm">{row.desc}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>

        {/* From TDEE to Tracking */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            From TDEE to Daily Tracking
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            Knowing your TDEE is step one. Step two is actually tracking your
            food consistently to hit your target. This is where most people
            fail — not because they don&apos;t know the numbers, but because
            tracking is too tedious.
          </p>
          <p className="text-gray-300 text-lg mb-8">
            Macromaxxing bridges this gap with AI food scanning (photo and
            voice), saved meal templates, and gamified accountability. Once you
            know your TDEE, set your daily target in the app and let AI handle
            the tracking.
          </p>
          <div className="grid md:grid-cols-2 gap-6">
            <div className="bg-white/5 border border-white/10 rounded-2xl p-6">
              <h3 className="text-xl font-bold mb-3 text-brand-gold">
                Streaks Keep You Honest
              </h3>
              <p className="text-gray-300">
                Build a daily logging streak to stay consistent. Once you have
                a streak going, the fear of breaking it keeps you tracking —
                which keeps you hitting your TDEE target.
              </p>
            </div>
            <div className="bg-white/5 border border-white/10 rounded-2xl p-6">
              <h3 className="text-xl font-bold mb-3 text-brand-teal">
                Leaderboard Competition
              </h3>
              <p className="text-gray-300">
                Earn Aura XP for hitting your calorie target, maintaining
                streaks, and logging consistently. Compete with the community
                on the leaderboard for extra motivation.
              </p>
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
              {[
                {
                  q: "What is TDEE and how do I calculate it?",
                  a: "TDEE (Total Daily Energy Expenditure) is the total calories your body burns per day, including BMR, activity, and digestion. Calculate it using the Mifflin-St Jeor equation: find your BMR based on weight, height, age, and sex, then multiply by an activity factor (1.2 for sedentary up to 1.9 for extremely active).",
                },
                {
                  q: "What is the best TDEE calculator app?",
                  a: "Macromaxxing helps you determine your calorie needs and then track your food intake with AI-powered photo and voice scanning. Unlike standalone calculators, it combines TDEE-based targets with effortless daily tracking, streaks, leaderboards, and a social community for accountability.",
                },
                {
                  q: "How many calories should I eat to lose weight?",
                  a: "To lose weight, eat 300-500 calories below your TDEE. This creates a sustainable calorie deficit that results in approximately 0.5-1 lb of fat loss per week. Use Macromaxxing to set your target and track your intake with AI food scanning.",
                },
                {
                  q: "How accurate are TDEE calculators?",
                  a: "TDEE calculators provide an estimate, typically within 10-15% of actual expenditure. The best approach is to use a calculator as a starting point, track your food consistently for 2-3 weeks, and adjust based on actual weight changes. Macromaxxing makes this tracking process effortless.",
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
            headline="Calculate Your TDEE, Then Track It"
            subheadline="Know your numbers. Track with AI. Stay consistent with streaks and leaderboards. Download now."
          />
        </div>
      </article>
    </>
  );
}
