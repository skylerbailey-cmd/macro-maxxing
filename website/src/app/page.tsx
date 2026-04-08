import { FeatureCard } from "@/components/FeatureCard";
import { DownloadCTA } from "@/components/DownloadCTA";
import { AppJsonLd } from "@/components/JsonLd";
import Image from "next/image";
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
          <p className="text-gray-300 text-lg sm:text-xl max-w-2xl mx-auto mb-4">
            Macro Maxxing is an AI-powered macro tracking app for iOS that
            lets you log food by snapping a photo or describing your meal with
            your voice. It estimates calories, protein, carbs, and fat using
            Claude AI models (Haiku and Sonnet).
          </p>
          <p className="text-gray-400 text-base max-w-2xl mx-auto mb-10">
            Includes workout tracking with automatic macro adjustments, an
            intermittent fasting timer, daily streaks, leaderboards, and a
            social community.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <a
              href="#download"
              className="bg-brand-purple hover:bg-brand-purple/80 text-white px-8 py-4 rounded-full font-bold text-lg transition"
            >
              Download Now
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
            <p className="text-2xl font-bold text-brand-gold">Claude AI</p>
            <p className="text-gray-500 text-sm">Food Recognition</p>
          </div>
          <div>
            <p className="text-2xl font-bold text-brand-purple">Voice + Photo</p>
            <p className="text-gray-500 text-sm">Input Methods</p>
          </div>
          <div>
            <p className="text-2xl font-bold text-brand-teal">Haiku + Sonnet</p>
            <p className="text-gray-500 text-sm">Dual-Model AI Pipeline</p>
          </div>
          <div>
            <p className="text-2xl font-bold text-brand-green">iOS App</p>
            <p className="text-gray-500 text-sm">Download Now</p>
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
              tool you need in one app.
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
              icon="🍽️"
              title="AI Meal Planner"
              description="Not sure what to eat next? AI analyzes your remaining macro gaps and suggests specific meals with exact portions to hit your targets."
            />
            <FeatureCard
              icon="🧠"
              title="AI Nutrition Coach"
              description="Get a personalized daily debrief on your eating. AI reviews your meals, macros, workouts, and timing — then tells you what to change tomorrow."
            />
            <FeatureCard
              icon="🏆"
              title="Streaks & Leaderboards"
              description="Build streaks by hitting your macro goals daily. Compete on Team, Local, and Arena leaderboards. Earn Aura XP and level up."
            />
            <FeatureCard
              icon="👥"
              title="Social Feed & Community"
              description="Share your nutrition wins, rep other trackers, and stay motivated with a global community of macro trackers."
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
                Take a picture of your plate and our AI system identifies
                every food item. Powered by Claude Haiku and Sonnet, it
                analyzes your food and estimates accurate macros using
                real-world nutritional knowledge.
              </p>
              <ul className="space-y-3">
                {[
                  "Vision AI identifies food items on your plate",
                  "Dual-model AI pipeline for maximum accuracy",
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

      {/* Screenshots */}
      <section id="screenshots" className="py-24 px-4 sm:px-6">
        <div className="max-w-6xl mx-auto text-center">
          <h2 className="text-3xl sm:text-4xl font-bold mb-4">
            See It in Action
          </h2>
          <p className="text-gray-400 max-w-xl mx-auto mb-12">
            A dark-mode interface designed for real people. Every screen built for
            speed and clarity.
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-3 lg:grid-cols-5 gap-6 max-w-6xl mx-auto">
            {[
              {
                title: "Log Food with AI Photo",
                desc: "Snap your plate, get instant macro breakdown",
                src: "/screenshots/photo-log.png",
              },
              {
                title: "Voice Meal Logging",
                desc: "Describe your meal, AI generates the macros",
                src: "/screenshots/voice-log.png",
              },
              {
                title: "Smart Workout Tracking",
                desc: "Log workouts with auto macro adjustments",
                src: "/screenshots/workout-log.png",
              },
              {
                title: "AI Meal Planner",
                desc: "AI suggests meals to fill your remaining macro gaps",
                src: "/screenshots/ai-meal-planner.png",
              },
              {
                title: "AI Nutrition Coach",
                desc: "Daily debrief on your meals, timing, and food quality",
                src: "/screenshots/ai-nutrition-coach.png",
              },
            ].map((screen, i) => (
              <div
                key={i}
                className="bg-brand-card rounded-2xl border border-white/5 p-6"
              >
                <div className="rounded-xl overflow-hidden mb-4">
                  <Image
                    src={screen.src}
                    alt={screen.title}
                    width={390}
                    height={844}
                    className="w-full h-auto"
                    priority={i === 0}
                  />
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

      {/* Learn More */}
      <section className="py-16 px-4 sm:px-6 bg-brand-card/30">
        <div className="max-w-4xl mx-auto">
          <h2 className="text-2xl font-bold text-center mb-8">Learn More</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
            {[
              {
                category: "Features",
                links: [
                  { href: "/best-macro-tracking-app", title: "Best Macro Tracking App in 2026" },
                  { href: "/ai-food-scanner", title: "AI Food Scanner" },
                  { href: "/calorie-counter-app", title: "Calorie Counter" },
                  { href: "/intermittent-fasting-tracker", title: "Intermittent Fasting Tracker" },
                  { href: "/workout-tracker-app", title: "Workout Tracker with Macros" },
                  { href: "/voice-food-logging", title: "Voice Food Logging" },
                  { href: "/ai-meal-planner", title: "AI Meal Planner" },
                  { href: "/ai-nutrition-coach", title: "AI Nutrition Coach" },
                  { href: "/streaks-and-gamification", title: "Streaks & Gamification" },
                  { href: "/social-fitness-community", title: "Social Community" },
                ],
              },
              {
                category: "Goals",
                links: [
                  { href: "/looksmaxxing-macro-tracker", title: "Looksmaxxing Nutrition" },
                  { href: "/protein-tracker-app", title: "Protein Tracker" },
                  { href: "/weight-loss-app", title: "Weight Loss App" },
                  { href: "/muscle-building-nutrition", title: "Muscle Building Nutrition" },
                  { href: "/meal-prep-tracker", title: "Meal Prep Tracker" },
                  { href: "/tdee-calculator", title: "TDEE Calculator" },
                  { href: "/gym-diet-plan", title: "Gym Diet Plan" },
                  { href: "/accountability-partner-app", title: "Accountability Partner" },
                  { href: "/body-recomposition-tracker", title: "Body Recomp Tracker" },
                ],
              },
              {
                category: "Compare",
                links: [
                  { href: "/myfitnesspal-alternative", title: "MyFitnessPal Alternative" },
                  { href: "/noom-alternative", title: "Noom Alternative" },
                  { href: "/cronometer-alternative", title: "Cronometer Alternative" },
                  { href: "/macrofactor-alternative", title: "MacroFactor Alternative" },
                  { href: "/lose-it-alternative", title: "Lose It! Alternative" },
                  { href: "/lifesum-alternative", title: "Lifesum Alternative" },
                  { href: "/carbon-diet-coach-alternative", title: "Carbon Diet Coach Alternative" },
                  { href: "/yazio-alternative", title: "YAZIO Alternative" },
                  { href: "/fatsecret-alternative", title: "FatSecret Alternative" },
                  { href: "/cal-ai-alternative", title: "Cal AI Alternative" },
                ],
              },
            ].map((group) => (
              <div key={group.category}>
                <h3 className="text-sm font-semibold text-brand-purple uppercase tracking-wider mb-3">
                  {group.category}
                </h3>
                <ul className="space-y-1">
                  {group.links.map((link) => (
                    <li key={link.href}>
                      <Link
                        href={link.href}
                        className="text-gray-400 hover:text-white text-sm transition"
                      >
                        {link.title}
                      </Link>
                    </li>
                  ))}
                </ul>
              </div>
            ))}
          </div>
        </div>
      </section>

      <DownloadCTA />

      {/* Freshness signal for AI crawlers */}
      <div className="text-center py-4 text-gray-600 text-xs">
        <p>Last updated: March 24, 2026</p>
      </div>
    </>
  );
}
