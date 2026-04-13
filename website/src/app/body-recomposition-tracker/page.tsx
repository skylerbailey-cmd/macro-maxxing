import { Metadata } from "next";
import { ArticleJsonLd } from "@/components/JsonLd";
import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";

export const metadata: Metadata = {
  title: "Body Recomposition Tracker — Lose Fat & Build Muscle | Macromaxxing",
  description:
    "Track your body recomposition with AI. Macromaxxing helps you lose fat and build muscle simultaneously by tracking macros with photo scanning, adjusting for workouts, and keeping you accountable with streaks and leaderboards.",
  keywords: [
    "body recomposition tracker",
    "body recomp app",
    "lose fat build muscle app",
    "recomp diet tracker",
    "body recomposition diet",
    "recomp macro tracker",
    "simultaneous fat loss muscle gain",
    "body recomp nutrition",
    "lean gains tracker",
    "recomp calorie tracker",
  ],
};

export default function BodyRecompositionPage() {
  return (
    <>
      <ArticleJsonLd
        title="Body Recomposition Tracker — Lose Fat & Build Muscle"
        description="Track your body recomposition with AI. Lose fat and build muscle simultaneously with precise macro tracking."
        url="https://macromaxxing.app/body-recomposition-tracker"
      />

      <article className="min-h-screen">
        <section className="relative py-20 md:py-28 overflow-hidden">
          <div className="absolute inset-0 bg-gradient-to-br from-brand-mint/20 via-dark to-brand-purple/10" />
          <div className="relative z-10 max-w-4xl mx-auto px-4 text-center">
            <span className="inline-block px-4 py-1 rounded-full bg-brand-mint/20 text-brand-mint text-sm font-semibold mb-6">
              BODY RECOMP
            </span>
            <h1 className="text-4xl md:text-6xl font-black mb-6">
              Lose Fat. Build Muscle.{" "}
              <span className="text-gradient">At the Same Time.</span>
            </h1>
            <p className="text-xl text-gray-300 max-w-2xl mx-auto mb-8">
              Body recomposition requires precise nutrition — eating at or near
              maintenance while hitting high protein targets. Macromaxxing
              makes it possible with AI tracking, workout-adjusted macros,
              daily streaks, and a community that keeps you locked in.
            </p>
            <a
              href="#download"
              className="inline-flex items-center gap-2 bg-brand-mint hover:bg-brand-mint/80 text-dark font-bold py-4 px-8 rounded-2xl text-lg transition-all"
            >
              Start Your Recomp 
            </a>
          </div>
        </section>

        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            What Is Body Recomposition?
          </h2>
          <p className="text-gray-300 text-lg mb-6">
            Body recomposition (recomp) is the process of losing body fat and
            building muscle simultaneously. Unlike traditional bulk/cut cycles,
            recomp lets you improve your physique without extreme phases of
            gaining or losing weight.
          </p>
          <p className="text-gray-300 text-lg mb-6">
            The key to a successful recomp is <strong>precise nutrition</strong>.
            You need to eat at or slightly below maintenance calories while
            consuming enough protein (1-1.2g per lb bodyweight) to support
            muscle growth. This narrow margin makes accurate tracking essential.
          </p>
          <p className="text-gray-300 text-lg">
            Macromaxxing&apos;s AI-powered tracking makes hitting these precise
            targets effortless. Snap a photo, say what you ate, or use saved
            meal templates — every meal is tracked accurately in seconds.
          </p>
        </section>

        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-5xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
              Why Macromaxxing Is Perfect for Recomp
            </h2>
            <div className="grid md:grid-cols-3 gap-6">
              <FeatureCard
                icon="🎯"
                title="Precise Calorie Tracking"
                description="Recomp requires eating near maintenance — not too much, not too little. AI food scanning gives you accurate calorie counts without tedious manual entry."
                color="brand-mint"
              />
              <FeatureCard
                icon="🥩"
                title="Protein-First Dashboard"
                description="Protein is the #1 priority for recomp. Macromaxxing displays your protein intake prominently so you always know if you're hitting your target."
                color="brand-purple"
              />
              <FeatureCard
                icon="🏋️"
                title="Workout Adjustments"
                description="Recomp works best with carb cycling — more carbs on training days, fewer on rest days. Macromaxxing adjusts your macros automatically when you log a workout."
                color="brand-teal"
              />
              <FeatureCard
                icon="🔥"
                title="Consistency Streaks"
                description="Recomp is a slow process that requires months of consistency. Daily streaks keep you tracking and eating on point every single day."
                color="brand-gold"
              />
              <FeatureCard
                icon="🏆"
                title="Leaderboard Motivation"
                description="When progress is slow (as it is with recomp), external motivation matters. Earning XP and climbing the leaderboard keeps you engaged."
                color="brand-green"
              />
              <FeatureCard
                icon="👥"
                title="Recomp Community"
                description="Connect with others doing body recomp on the social feed. Share progress, exchange tips, and stay motivated through the long process."
                color="brand-orange"
              />
            </div>
          </div>
        </section>

        {/* Recomp Guidelines */}
        <section className="py-16 md:py-20 max-w-4xl mx-auto px-4">
          <h2 className="text-3xl md:text-4xl font-bold mb-8">
            Body Recomp Nutrition Guidelines
          </h2>
          <div className="bg-white/5 border border-white/10 rounded-2xl p-6 md:p-8">
            <div className="space-y-6">
              <div>
                <h3 className="text-lg font-bold text-brand-mint mb-2">
                  Calories
                </h3>
                <p className="text-gray-300">
                  Eat at maintenance or in a very slight deficit (100-200 kcal
                  below TDEE). A larger deficit will compromise muscle growth.
                  Macromaxxing helps you track precisely enough to stay in this
                  narrow range.
                </p>
              </div>
              <div>
                <h3 className="text-lg font-bold text-brand-purple mb-2">
                  Protein
                </h3>
                <p className="text-gray-300">
                  Aim for 1-1.2g per pound of bodyweight. This is higher than
                  typical bulking recommendations because you need to maximize
                  muscle protein synthesis while in a calorie-neutral state.
                </p>
              </div>
              <div>
                <h3 className="text-lg font-bold text-brand-gold mb-2">
                  Carbs & Fat
                </h3>
                <p className="text-gray-300">
                  After protein, fill remaining calories with carbs and fat
                  based on preference. Many recomp athletes benefit from
                  higher carbs on training days and higher fat on rest days.
                  Macromaxxing&apos;s workout adjustments handle this
                  automatically.
                </p>
              </div>
              <div>
                <h3 className="text-lg font-bold text-brand-teal mb-2">
                  Training
                </h3>
                <p className="text-gray-300">
                  Progressive overload is essential for recomp. Log your
                  workouts in Macromaxxing to ensure your daily macros
                  adjust for training intensity.
                </p>
              </div>
            </div>
          </div>
        </section>

        {/* Who is recomp for */}
        <section className="py-16 md:py-20 bg-white/[0.02]">
          <div className="max-w-4xl mx-auto px-4">
            <h2 className="text-3xl md:text-4xl font-bold mb-8">
              Who Is Body Recomp Best For?
            </h2>
            <div className="grid md:grid-cols-2 gap-6">
              {[
                {
                  title: "Beginners",
                  desc: "Beginners experience 'newbie gains' — the ability to build muscle rapidly even without a calorie surplus. Recomp is ideal for new lifters.",
                },
                {
                  title: "Returning Athletes",
                  desc: "If you're returning after a break, muscle memory allows rapid regain. Recomp lets you lean out while rebuilding lost muscle.",
                },
                {
                  title: "Skinny-Fat Individuals",
                  desc: "If you're at a normal weight but lack muscle definition, recomp lets you build muscle and lose fat without bulking up first.",
                },
                {
                  title: "People Who Hate Bulking",
                  desc: "Not everyone wants to gain weight during a bulk. Recomp lets you improve your physique while staying at a comfortable weight.",
                },
              ].map((item) => (
                <div
                  key={item.title}
                  className="bg-white/5 border border-white/10 rounded-2xl p-6"
                >
                  <h3 className="text-lg font-bold text-white mb-2">
                    {item.title}
                  </h3>
                  <p className="text-gray-300">{item.desc}</p>
                </div>
              ))}
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
                q: "What is the best app for body recomposition?",
                a: "Macromaxxing is the best app for body recomposition. It features AI-powered food scanning for precise calorie and protein tracking, automatic workout macro adjustments, and gamified accountability (streaks, leaderboards, community) to keep you consistent through the long recomp process.",
              },
              {
                q: "Can you really lose fat and build muscle at the same time?",
                a: "Yes. Body recomposition is well-supported by research, especially for beginners, returning athletes, and those with higher body fat. The key is precise nutrition — eating at or near maintenance calories while consuming enough protein (1-1.2g/lb bodyweight) and training with progressive overload.",
              },
              {
                q: "How many calories should I eat for body recomp?",
                a: "For body recomposition, eat at maintenance calories (your TDEE) or in a very slight deficit (100-200 kcal below). The margin is narrow, which is why accurate tracking with Macromaxxing's AI food scanning is essential for success.",
              },
              {
                q: "How long does body recomposition take?",
                a: "Body recomp is a gradual process. Most people see noticeable changes in 3-6 months with consistent training and precise nutrition. Macromaxxing's streaks and community keep you accountable through the entire journey.",
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
            headline="Start Your Body Recomp"
            subheadline="Precise AI tracking, workout-adjusted macros, streaks, and a community. Everything you need for body recomposition.."
          />
        </div>
      </article>
    </>
  );
}
