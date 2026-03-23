import type { Metadata } from "next";
import { DownloadCTA } from "@/components/DownloadCTA";
import { ArticleJsonLd } from "@/components/JsonLd";

export const metadata: Metadata = {
  title: "Voice Food Logging — Log Meals by Speaking",
  description:
    "Log meals and workouts with your voice. Say what you ate and AI generates accurate macro breakdowns. Hands-free food tracking for people on the go.",
  keywords: [
    "voice food logging",
    "voice meal tracker",
    "speak to log food",
    "hands free calorie tracker",
    "voice nutrition tracker",
    "AI voice food logger",
    "talk to track calories",
    "voice macro tracker",
  ],
};

export default function VoiceFoodLogging() {
  return (
    <>
      <ArticleJsonLd
        title="Voice Food Logging — Log Meals by Speaking"
        description="Log meals and workouts with your voice. AI generates accurate macro breakdowns from natural speech."
        url="https://macromaxxing.app/voice-food-logging"
      />

      <article className="pt-32 pb-12 px-4 sm:px-6">
        <div className="max-w-3xl mx-auto">
          <div className="bg-brand-gold/10 text-brand-gold text-xs font-semibold px-3 py-1 rounded-full inline-block mb-4">
            VOICE INPUT
          </div>
          <h1 className="text-3xl sm:text-5xl font-black mb-6 leading-tight">
            Just Say What You Ate.
            <br />
            <span className="text-gradient-gold">AI Does the Rest.</span>
          </h1>
          <p className="text-gray-400 text-lg leading-relaxed mb-12">
            Hands covered in protein powder? Just finished a set? Driving home
            from the gym? Tap the mic, describe your meal, and AI generates
            the full macro breakdown. No typing. No searching. No excuses.
          </p>

          <h2 className="text-2xl font-bold mb-6">How Voice Logging Works</h2>
          <div className="space-y-6 mb-12">
            <div className="bg-brand-card rounded-xl p-6 border border-white/5">
              <div className="flex items-center gap-3 mb-3">
                <span className="bg-brand-gold/20 text-brand-gold rounded-full w-8 h-8 flex items-center justify-center font-bold">
                  1
                </span>
                <h3 className="font-semibold text-white">Tap the Mic</h3>
              </div>
              <p className="text-gray-400 text-sm pl-11">
                On the Log Food or Log Workout screen, switch to Voice mode and
                tap the microphone button.
              </p>
            </div>
            <div className="bg-brand-card rounded-xl p-6 border border-white/5">
              <div className="flex items-center gap-3 mb-3">
                <span className="bg-brand-gold/20 text-brand-gold rounded-full w-8 h-8 flex items-center justify-center font-bold">
                  2
                </span>
                <h3 className="font-semibold text-white">
                  Describe Your Meal Naturally
                </h3>
              </div>
              <p className="text-gray-400 text-sm pl-11">
                Speak naturally: &ldquo;This is the ground turkey with rice and
                mixed vegetables&rdquo; or &ldquo;Two scoops of whey protein
                with almond milk.&rdquo; No special format needed.
              </p>
            </div>
            <div className="bg-brand-card rounded-xl p-6 border border-white/5">
              <div className="flex items-center gap-3 mb-3">
                <span className="bg-brand-gold/20 text-brand-gold rounded-full w-8 h-8 flex items-center justify-center font-bold">
                  3
                </span>
                <h3 className="font-semibold text-white">Review Transcription</h3>
              </div>
              <p className="text-gray-400 text-sm pl-11">
                Your speech is transcribed in real-time. Review the text and tap
                to re-record if needed. When it looks right, hit &ldquo;Generate
                with AI.&rdquo;
              </p>
            </div>
            <div className="bg-brand-card rounded-xl p-6 border border-white/5">
              <div className="flex items-center gap-3 mb-3">
                <span className="bg-brand-gold/20 text-brand-gold rounded-full w-8 h-8 flex items-center justify-center font-bold">
                  4
                </span>
                <h3 className="font-semibold text-white">
                  AI Generates Macros
                </h3>
              </div>
              <p className="text-gray-400 text-sm pl-11">
                AI parses your description, identifies foods and quantities,
                cross-references nutrition databases, and generates a full
                breakdown — calories, protein, carbs, and fat.
              </p>
            </div>
          </div>

          <h2 className="text-2xl font-bold mb-4">
            Voice Works for Food <em>and</em> Workouts
          </h2>
          <p className="text-gray-400 leading-relaxed mb-6">
            Voice logging isn&apos;t just for meals. On the Log Workout screen,
            tap the mic and say &ldquo;30 minute run, about 200 calories&rdquo;
            — and your workout is logged with smart macro adjustments.
          </p>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-12">
            <div className="bg-brand-card rounded-xl p-5 border border-white/5">
              <h3 className="font-semibold text-brand-purple mb-2 text-sm">
                🎙️ Voice + Photo Combo
              </h3>
              <p className="text-gray-400 text-sm">
                Take a photo of your meal <em>and</em> describe it with voice
                for maximum accuracy. AI combines both signals.
              </p>
            </div>
            <div className="bg-brand-card rounded-xl p-5 border border-white/5">
              <h3 className="font-semibold text-brand-gold mb-2 text-sm">
                🔄 Tap to Re-Record
              </h3>
              <p className="text-gray-400 text-sm">
                Misspoke? Just tap the mic again to re-record. No need to
                delete and start over.
              </p>
            </div>
            <div className="bg-brand-card rounded-xl p-5 border border-white/5">
              <h3 className="font-semibold text-brand-teal mb-2 text-sm">
                🧠 Natural Language
              </h3>
              <p className="text-gray-400 text-sm">
                Say it however you want — &ldquo;chicken and rice&rdquo; or
                &ldquo;about 6 ounces of grilled chicken breast with a cup of
                white rice and steamed broccoli.&rdquo;
              </p>
            </div>
            <div className="bg-brand-card rounded-xl p-5 border border-white/5">
              <h3 className="font-semibold text-brand-green mb-2 text-sm">
                ✨ Generate with AI
              </h3>
              <p className="text-gray-400 text-sm">
                One tap after recording and AI does the heavy lifting — parsing
                ingredients, estimating portions, and pulling nutrition data.
              </p>
            </div>
          </div>

          <h2 className="text-2xl font-bold mb-4">
            Perfect for Post-Workout Logging
          </h2>
          <p className="text-gray-400 leading-relaxed mb-4">
            You just crushed a workout. Your hands are sweaty. You&apos;re
            downing a protein shake. The last thing you want to do is type
            &ldquo;whey protein isolate 2 scoops 240ml almond milk&rdquo; into
            a tiny search bar.
          </p>
          <p className="text-gray-400 leading-relaxed">
            Just say it. Macro Maxxing handles the rest. That&apos;s what voice
            logging was built for.
          </p>
        </div>
      </article>

      <DownloadCTA
        headline="Log meals without lifting a finger."
        subheadline="Download Macro Maxxing and start voice-logging your nutrition."
      />
    </>
  );
}
