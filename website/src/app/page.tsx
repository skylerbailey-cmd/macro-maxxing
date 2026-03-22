import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";
import { AppJsonLd } from "@/components/JsonLd";
import Link from "next/link";

export default function Home() {
  return (
    <>
      <AppJsonLd />

      {/* Hero */}
      <section className="pt-32 pb-20 px-4 sm:px-6">
        <div className="max-w-6xl mx-auto text-center">
          <div className="inline-block bg-brand-purple/10 border border-brand-purple/20 rounded-full px-4 py-1.5 text-sm text-brand-purple font-medium mb-6">
            AI-Powered Nutrition Tracking
          </div>
          <h1 className="text-4xl sm:text-6xl lg:text-7xl font-black leading-tight mb-6">
            Track Macros with
            <br />
            <span className="text-gradient">AI Precision</span>
          </h1>
          <p className="text-gray-400 text-lg sm:text-xl max-w-2xl mx-auto mb-10">
            Snap a photo of your meal. Describe it with your voice. Let AI do
            the rest. The smartest macro tracker for athletes who are built
            different.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <a
              href="#download"
              className="bg-brand-purple hover:bg-brand-purple/80 text-white px-8 py-4 rounded-full font-bold text-lg transition"
            >
              Download Free
            </a>
            <a
              href="#ai-powered"
              className="border border-white/10 hover:border-white/20 text-white px-8 py-4 rounded-full font-semibold transition"
            >
              See How It Works
            </a>
          </div>
        </div>
      </section>

      {/* Social proof bar */}
      <section className="border-y border-white/5 py-8 px-4 sm:px-6">
        <div className="max-w-4xl mx-auto flex flex-wrap justify-center gap-8 sm:gap-16 text-center">
          <div>
            <p className="text-2xl font-bold text-brand-gold">3-Tier AI</p>
            <p className="text-gray-500 text-sm">Food Recognition</p>
          </div>
          <div>
            <p className="text-2xl font-bold text-brand-purple">Voice + Photo</p>
            <p className="text-gray-500 text-sm">Input Methods</p>
          </div>
          <div>
            <p className="text-2xl font-bold text-brand-teal">4 Databases</p>
            <p className="text-gray-500 text-sm">USDA, FatSecret & more</p>
          </div>
          <div>
            <p className="text-2xl font-bold text-brand-green">100% Free</p>
            <p className="text-gray-500 text-sm">No Paywall</p>
          </div>
        </div>
      </section>

      {/* Core Features */}
      <section id="features" className="py-24 px-4 sm:px-6">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-16">
            <h2 className="text-3xl sm:text-4xl font-bold mb-4">
              Everything You Need to{" "}
              <span className="text-gradient">Maxx Your Macros</span>
            </h2>
            <p className="text-gray-400 max-w-xl mx-auto">
              From AI-powered food logging to smart workout adjustments — every
              tool a serious athlete needs in one app.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            <FeatureCard
              icon="📸"
              title="AI Photo Food Scanner"
              description="Take a photo of your meal and AI instantly identifies every item and estimates calories, protein, carbs, and fat — no manual entry needed."
            />
            <FeatureCard
              icon="🎙️"
              title="Voice Meal Logging"
              description='Say "ground turkey with rice and mixed vegetables" and AI generates accurate macros from your voice description. Hands-free tracking.'
            />
            <FeatureCard
              icon="🏋️"
              title="Smart Workout Tracking"
              description="Log workouts by voice or manually. Choose from Strength, Cardio, HIIT, Flex/Yoga, and more. Auto-adjusts daily macros based on activity."
            />
            <FeatureCard
              icon="⏱️"
              title="Intermittent Fasting Timer"
              description="Built-in fasting timer that persists across app restarts. Track your 16:8, 20:4, or custom fasting window with real-time countdowns."
            />
            <FeatureCard
              icon="🏆"
              title="Streaks & Leaderboards"
              description="Build streaks by hitting your macro goals daily. Compete on Team, Local, and Arena leaderboards. Earn Aura XP and level up."
            />
            <FeatureCard
              icon="👥"
              title="Social Feed & Community"
              description="Share your nutrition wins, rep other athletes, and stay motivated with a global community of macro trackers."
            />
          </div>
        </div>
      </section>

      {/* AI-Powered Section — detailed showcase */}
      <section id="ai-powered" className="py-24 px-4 sm:px-6 bg-brand-card/30">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-16">
            <div className="inline-block bg-brand-gold/10 border border-brand-gold/20 rounded-full px-4 py-1.5 text-sm text-brand-gold font-medium mb-4">
              Powered by AI
            </div>
            <h2 className="text-3xl sm:text-4xl font-bold mb-4">
              Three Ways to Log.{" "}
              <span className="text-gradient-gold">Zero Excuses.</span>
            </h2>
            <p className="text-gray-400 max-w-xl mx-auto">
              Whether you prefer snapping a photo, speaking to your phone, or
              typing it in — Macro Maxxing makes logging effortless.
            </p>
          </div>

          {/* Photo Analysis */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center mb-24">
            <div>
              <div className="bg-brand-purple/10 text-brand-purple text-xs font-semibold px-3 py-1 rounded-full inline-block mb-4">
                PHOTO MODE
              </div>
              <h3 className="text-2xl sm:text-3xl font-bold mb-4">
                Snap a Photo. Get Instant Macros.
              </h3>
              <p className="text-gray-400 mb-6 leading-relaxed">
                Take a picture of your plate and our 3-tier AI system identifies
                every food item. It cross-references USDA, FatSecret, and
                OpenFoodFacts databases for the most accurate nutrition data
                possible.
              </p>
              <ul className="space-y-3">
                {[
                  "Vision AI identifies food items on your plate",
                  "Cross-references 4 nutrition databases for accuracy",
                  "Edit and adjust portions before saving",
                  "Save meals as templates for quick re-logging",
                ].map((item, i) => (
                  <li key={i} className="flex items-start gap-3 text-gray-300 text-sm">
                    <span className="text-brand-green mt-0.5">✓</span>
                    {item}
                  </li>
                ))}
              </ul>
            </div>
            <div className="relative">
              <div className="bg-brand-card rounded-3xl border border-white/5 p-8 text-center">
                <div className="bg-brand-bg rounded-2xl p-6 mb-4">
                  <div className="text-6xl mb-3">📸</div>
                  <p className="text-brand-purple font-semibold text-lg">
                    AI Photo Analysis
                  </p>
                  <p className="text-gray-500 text-sm mt-1">
                    Snap your meal → get instant macros
                  </p>
                </div>
                <div className="flex justify-center gap-3">
                  <div className="bg-brand-bg rounded-xl px-4 py-2 text-center">
                    <p className="text-brand-orange font-bold">2,704</p>
                    <p className="text-gray-500 text-xs">kcal</p>
                  </div>
                  <div className="bg-brand-bg rounded-xl px-4 py-2 text-center">
                    <p className="text-brand-cyan font-bold">165g</p>
                    <p className="text-gray-500 text-xs">protein</p>
                  </div>
                  <div className="bg-brand-bg rounded-xl px-4 py-2 text-center">
                    <p className="text-brand-mint font-bold">350g</p>
                    <p className="text-gray-500 text-xs">carbs</p>
                  </div>
                  <div className="bg-brand-bg rounded-xl px-4 py-2 text-center">
                    <p className="text-brand-rose font-bold">71g</p>
                    <p className="text-gray-500 text-xs">fat</p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Voice Input */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center mb-24">
            <div className="order-2 lg:order-1">
              <div className="bg-brand-card rounded-3xl border border-white/5 p-8 text-center">
                <div className="bg-brand-bg rounded-2xl p-6 mb-4">
                  <div className="text-6xl mb-3">🎙️</div>
                  <p className="text-brand-gold font-semibold text-lg">
                    Voice Recognition
                  </p>
                  <p className="text-gray-500 text-sm mt-1">
                    Tap to record → describe your meal
                  </p>
                </div>
                <div className="bg-brand-bg rounded-xl p-4 text-left">
                  <p className="text-gray-300 text-sm italic">
                    &ldquo;This is the ground turkey with rice and mixed
                    vegetables&rdquo;
                  </p>
                </div>
                <button className="mt-4 bg-gradient-to-r from-brand-purple to-brand-rose text-white px-6 py-3 rounded-full font-semibold text-sm w-full">
                  ✨ Generate with AI
                </button>
              </div>
            </div>
            <div className="order-1 lg:order-2">
              <div className="bg-brand-gold/10 text-brand-gold text-xs font-semibold px-3 py-1 rounded-full inline-block mb-4">
                VOICE MODE
              </div>
              <h3 className="text-2xl sm:text-3xl font-bold mb-4">
                Just Say What You Ate.
              </h3>
              <p className="text-gray-400 mb-6 leading-relaxed">
                Hands full? Just tap the mic and describe your meal naturally.
                AI transcribes your voice and generates accurate macro
                breakdowns instantly. Perfect for post-workout logging.
              </p>
              <ul className="space-y-3">
                {[
                  "Natural language voice recognition",
                  "AI parses quantities, ingredients, and cooking methods",
                  "Works for both meals and workouts",
                  "Tap to re-record if needed",
                ].map((item, i) => (
                  <li key={i} className="flex items-start gap-3 text-gray-300 text-sm">
                    <span className="text-brand-green mt-0.5">✓</span>
                    {item}
                  </li>
                ))}
              </ul>
            </div>
          </div>

          {/* Workout Tracking */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            <div>
              <div className="bg-brand-teal/10 text-brand-teal text-xs font-semibold px-3 py-1 rounded-full inline-block mb-4">
                WORKOUT MODE
              </div>
              <h3 className="text-2xl sm:text-3xl font-bold mb-4">
                Log Workouts. Auto-Adjust Macros.
              </h3>
              <p className="text-gray-400 mb-6 leading-relaxed">
                Choose your workout type — Strength, Cardio, HIIT, Flex/Yoga,
                or Rest Day. Macro Maxxing automatically adjusts your daily
                macro targets based on ISSN & ACSM guidelines so you fuel your
                training properly.
              </p>
              <ul className="space-y-3">
                {[
                  "6 workout types with smart macro adjustments",
                  "Voice logging — describe your workout and AI fills the details",
                  "Save workout templates for one-tap logging",
                  "Macro adjustments based on ISSN & ACSM guidelines",
                ].map((item, i) => (
                  <li key={i} className="flex items-start gap-3 text-gray-300 text-sm">
                    <span className="text-brand-green mt-0.5">✓</span>
                    {item}
                  </li>
                ))}
              </ul>
            </div>
            <div>
              <div className="bg-brand-card rounded-3xl border border-white/5 p-8">
                <div className="grid grid-cols-3 gap-3 mb-6">
                  {[
                    { icon: "🏋️", label: "Strength", active: true },
                    { icon: "🏃", label: "Cardio", active: false },
                    { icon: "⚡", label: "HIIT", active: false },
                    { icon: "🧘", label: "Flex / Yoga", active: false },
                    { icon: "😴", label: "Rest Day", active: false },
                    { icon: "🏃‍♂️", label: "Other", active: false },
                  ].map((type, i) => (
                    <div
                      key={i}
                      className={`rounded-xl p-3 text-center text-sm ${
                        type.active
                          ? "bg-brand-green/20 border border-brand-green/40 text-brand-green"
                          : "bg-brand-bg border border-white/5 text-gray-400"
                      }`}
                    >
                      <div className="text-xl mb-1">{type.icon}</div>
                      {type.label}
                    </div>
                  ))}
                </div>
                <div className="bg-brand-bg rounded-xl p-4 border border-brand-gold/20">
                  <div className="flex justify-between items-center mb-3">
                    <p className="text-sm font-semibold text-white">
                      📊 Macro Adjustment
                    </p>
                    <span className="text-brand-green text-xs font-semibold">
                      Strength
                    </span>
                  </div>
                  <div className="grid grid-cols-4 gap-2 text-center">
                    <div>
                      <p className="text-brand-orange font-bold text-sm">
                        2,704kcal
                      </p>
                      <p className="text-brand-green text-xs">+140</p>
                    </div>
                    <div>
                      <p className="text-brand-mint font-bold text-sm">350g</p>
                      <p className="text-brand-green text-xs">+23</p>
                    </div>
                    <div>
                      <p className="text-brand-cyan font-bold text-sm">165g</p>
                      <p className="text-brand-green text-xs">+12</p>
                    </div>
                    <div>
                      <p className="text-brand-rose font-bold text-sm">71g</p>
                      <p className="text-gray-500 text-xs">—</p>
                    </div>
                  </div>
                  <p className="text-gray-500 text-xs mt-3">
                    Based on ISSN & ACSM guidelines. Applied to today only.
                  </p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Screenshots placeholder */}
      <section id="screenshots" className="py-24 px-4 sm:px-6">
        <div className="max-w-6xl mx-auto text-center">
          <h2 className="text-3xl sm:text-4xl font-bold mb-4">
            See It in Action
          </h2>
          <p className="text-gray-400 max-w-xl mx-auto mb-12">
            A dark-mode interface designed for athletes. Every screen built for
            speed and clarity.
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-8 max-w-4xl mx-auto">
            {[
              {
                title: "Log Food with AI Photo",
                desc: "Snap your plate, get instant macro breakdown",
              },
              {
                title: "Voice Meal Logging",
                desc: "Describe your meal, AI generates the macros",
              },
              {
                title: "Smart Workout Tracking",
                desc: "Log workouts with auto macro adjustments",
              },
            ].map((screen, i) => (
              <div
                key={i}
                className="bg-brand-card rounded-2xl border border-white/5 p-6"
              >
                <div className="bg-brand-bg rounded-xl aspect-[9/16] flex items-center justify-center mb-4">
                  <p className="text-gray-500 text-sm px-4 text-center">
                    [App Screenshot: {screen.title}]
                  </p>
                </div>
                <h3 className="text-white font-semibold text-sm">
                  {screen.title}
                </h3>
                <p className="text-gray-500 text-xs mt-1">{screen.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Lead gen links */}
      <section className="py-16 px-4 sm:px-6 bg-brand-card/30">
        <div className="max-w-4xl mx-auto">
          <h2 className="text-2xl font-bold text-center mb-8">Learn More</h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
            {[
              {
                href: "/best-macro-tracking-app",
                title: "Best Macro Tracking App in 2026",
                desc: "See how Macro Maxxing compares",
              },
              {
                href: "/ai-food-scanner",
                title: "AI Food Scanner",
                desc: "How our 3-tier AI recognition works",
              },
              {
                href: "/calorie-counter-app",
                title: "Free Calorie Counter",
                desc: "Why barcode scanning is outdated",
              },
              {
                href: "/intermittent-fasting-tracker",
                title: "Intermittent Fasting Tracker",
                desc: "Built-in timer with macro integration",
              },
              {
                href: "/workout-tracker-app",
                title: "Workout Tracker with Macros",
                desc: "Auto-adjust nutrition for training",
              },
              {
                href: "/voice-food-logging",
                title: "Voice Food Logging",
                desc: "Log meals hands-free with AI",
              },
              {
                href: "/streaks-and-gamification",
                title: "Streaks & Gamification",
                desc: "Turn tracking into a game",
              },
              {
                href: "/social-fitness-community",
                title: "Social Community",
                desc: "Accountability through community",
              },
              {
                href: "/looksmaxxing-macro-tracker",
                title: "Looksmaxxing Nutrition",
                desc: "Optimize your glow up diet",
              },
              {
                href: "/protein-tracker-app",
                title: "Protein Tracker",
                desc: "Hit your protein goals daily",
              },
              {
                href: "/weight-loss-app",
                title: "Weight Loss App",
                desc: "AI-powered calorie deficit tracking",
              },
              {
                href: "/muscle-building-nutrition",
                title: "Muscle Building Nutrition",
                desc: "Track your bulking macros",
              },
              {
                href: "/meal-prep-tracker",
                title: "Meal Prep Tracker",
                desc: "Scan once, log all week",
              },
              {
                href: "/tdee-calculator",
                title: "TDEE Calculator",
                desc: "Know your maintenance calories",
              },
              {
                href: "/gym-diet-plan",
                title: "Gym Diet Plan",
                desc: "Nutrition for every training style",
              },
              {
                href: "/accountability-partner-app",
                title: "Accountability Partner",
                desc: "Never diet alone again",
              },
              {
                href: "/body-recomposition-tracker",
                title: "Body Recomp Tracker",
                desc: "Lose fat and build muscle",
              },
              {
                href: "/myfitnesspal-alternative",
                title: "MyFitnessPal Alternative",
                desc: "Why athletes are switching",
              },
              {
                href: "/noom-alternative",
                title: "Noom Alternative",
                desc: "Real macros, not color codes",
              },
              {
                href: "/cronometer-alternative",
                title: "Cronometer Alternative",
                desc: "Accuracy without the complexity",
              },
              {
                href: "/macrofactor-alternative",
                title: "MacroFactor Alternative",
                desc: "Save $144/year",
              },
              {
                href: "/lose-it-alternative",
                title: "Lose It! Alternative",
                desc: "More than just calorie counting",
              },
              {
                href: "/lifesum-alternative",
                title: "Lifesum Alternative",
                desc: "All features, no paywall",
              },
              {
                href: "/carbon-diet-coach-alternative",
                title: "Carbon Diet Coach Alternative",
                desc: "AI tracking for serious athletes",
              },
              {
                href: "/yazio-alternative",
                title: "YAZIO Alternative",
                desc: "Accurate tracking, zero upsells",
              },
              {
                href: "/fatsecret-alternative",
                title: "FatSecret Alternative",
                desc: "Free tracking, modernized",
              },
            ].map((link, i) => (
              <Link
                key={i}
                href={link.href}
                className="bg-brand-card rounded-xl p-5 border border-white/5 hover:border-brand-purple/30 transition group"
              >
                <h3 className="text-white font-semibold text-sm group-hover:text-brand-purple transition">
                  {link.title}
                </h3>
                <p className="text-gray-500 text-xs mt-1">{link.desc}</p>
              </Link>
            ))}
          </div>
        </div>
      </section>

      <DownloadCTA />
    </>
  );
}
