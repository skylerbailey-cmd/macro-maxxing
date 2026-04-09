import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import {
  ArticleJsonLd,
  BreadcrumbJsonLd,
  FAQPageJsonLd,
} from "@/components/JsonLd";

export const metadata: Metadata = {
  title: "Settings & Account — Macro Maxxing Help",
  description:
    "Complete guide to Macro Maxxing account settings. Learn how to set up your profile, configure nutrition goals, manage privacy, connect social accounts, enable fasting tracking, and customize notifications.",
  keywords: [
    "macro maxxing settings",
    "macro maxxing account",
    "macro maxxing profile setup",
    "macro maxxing nutrition settings",
    "macro maxxing privacy",
    "macro maxxing protein per lb",
    "macro maxxing fasting tracker",
    "macro maxxing help",
    "macro maxxing export data",
    "macro maxxing private account",
  ],
  openGraph: {
    title: "Settings & Account — Macro Maxxing Help",
    description:
      "Configure your profile, nutrition goals, privacy, notifications, and more in Macro Maxxing.",
    url: "https://macromaxxing.app/help/settings",
    type: "article",
  },
  alternates: {
    canonical: "https://macromaxxing.app/help/settings",
  },
};

const faqs = [
  {
    question: "How do I access settings in Macro Maxxing?",
    answer:
      "Tap your profile picture in the top-right corner of the Hub screen to open the Account settings page.",
  },
  {
    question: "How do I make my Macro Maxxing account private?",
    answer:
      "Go to Account settings and toggle on 'Private Account' under the Profile section. When private, only approved followers can see your posts and progress.",
  },
  {
    question: "How do I change my protein goal in Macro Maxxing?",
    answer:
      "In Account settings, scroll to the Nutrition section. The 'Protein per lb' setting controls how many grams of protein per pound of body weight are used to calculate your daily protein goal. General fitness is typically 0.7–0.8 g/lb, while strength training is 0.8–1.0 g/lb.",
  },
  {
    question: "Does Macro Maxxing auto-adjust macros for workouts?",
    answer:
      "Yes. In the Nutrition section of Account settings, toggle on 'Auto-adjust macros for workouts.' When enabled, the workout log sheet will default to applying macro adjustments based on the type and duration of your workout.",
  },
  {
    question: "Can I exclude dairy or gluten from AI meal suggestions?",
    answer:
      "Yes. In Account settings under Nutrition, toggle on 'Exclude dairy' and/or 'Exclude gluten.' These dietary exclusions are used by the AI meal planner to avoid suggesting meals with those ingredients.",
  },
  {
    question: "How do I enable intermittent fasting tracking in Macro Maxxing?",
    answer:
      "In Account settings, scroll to the Intermittent Fasting section and toggle on 'Track Intermittent Fasting Window.' This enables the fasting window tracker on the Home screen.",
  },
  {
    question: "How do I export my data from Macro Maxxing?",
    answer:
      "In Account settings, scroll to Privacy & Data and tap 'Export My Data.' You can download a copy of all your data at any time.",
  },
  {
    question: "How do I connect Instagram or TikTok to Macro Maxxing?",
    answer:
      "In Account settings, scroll to the Socials section. Enter your Instagram and/or TikTok username to link your social accounts to your Macro Maxxing profile.",
  },
  {
    question: "How do I delete my Macro Maxxing account?",
    answer:
      "In Account settings, scroll to the very bottom and tap 'Delete Account.' This action is permanent and removes all your data from Macro Maxxing.",
  },
];

function HowToJsonLd() {
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "HowTo",
    name: "How to Configure Settings in Macro Maxxing",
    description:
      "Guide to setting up your profile, nutrition goals, privacy, and notifications in the Macro Maxxing iOS app.",
    totalTime: "PT3M",
    tool: [
      {
        "@type": "HowToTool",
        name: "Macro Maxxing iOS app",
      },
    ],
    step: [
      {
        "@type": "HowToStep",
        name: "Open Account settings",
        text: "Tap your profile picture in the top-right corner of the Hub screen to open the Account settings page.",
        image: "https://macromaxxing.app/help/Home%20Screen.png",
      },
      {
        "@type": "HowToStep",
        name: "Set up your Profile",
        text: "Configure your name, username, email, private account toggle, and date of birth. Set your Profile Location and enable GPS Location for the local leaderboard.",
        image: "https://macromaxxing.app/help/settings1.png",
      },
      {
        "@type": "HowToStep",
        name: "Configure Body and Nutrition",
        text: "Enter your current weight, goal weight, height, and gender. Set protein per lb for macro calculations, and toggle dietary exclusions like dairy and gluten.",
        image: "https://macromaxxing.app/help/settings2.png",
      },
      {
        "@type": "HowToStep",
        name: "Customize features and notifications",
        text: "Enable Aura XP popups, intermittent fasting tracking, and daily meal reminders. Review privacy settings and manage your data.",
        image: "https://macromaxxing.app/help/settings3.png",
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

export default function SettingsPage() {
  return (
    <>
      <HowToJsonLd />
      <ArticleJsonLd
        title="Settings & Account — Macro Maxxing Help"
        description="Complete guide to Macro Maxxing account settings including profile, nutrition goals, privacy, notifications, and data management."
        url="https://macromaxxing.app/help/settings"
        datePublished="2026-04-09"
        dateModified="2026-04-09"
      />
      <BreadcrumbJsonLd
        items={[
          { name: "Home", url: "https://macromaxxing.app" },
          { name: "Help", url: "https://macromaxxing.app/help" },
          {
            name: "Settings & Account",
            url: "https://macromaxxing.app/help/settings",
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
            <span className="text-gray-300">Settings &amp; Account</span>
          </nav>

          <div className="bg-brand-cyan/10 text-brand-cyan text-xs font-semibold px-3 py-1 rounded-full inline-block mb-4">
            ACCOUNT
          </div>
          <h1 className="text-3xl sm:text-5xl font-black mb-6 leading-tight">
            Settings &amp; Account
          </h1>
          <p className="text-gray-300 text-lg leading-relaxed mb-4">
            Your Account settings control everything from your profile and
            nutrition goals to privacy, notifications, and data. Here&apos;s a
            walkthrough of every section.
          </p>
          <p className="text-gray-500 text-sm mb-12">
            Last updated: April 2026
          </p>

          {/* How to access */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              How to Open Settings
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              Tap your <strong className="text-white">profile picture</strong>{" "}
              in the top-right corner of the Hub screen. The{" "}
              <strong className="text-white">Account</strong> page opens with
              all your settings.
            </p>
          </section>

          {/* Profile */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">Profile</h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              The top of the Account page covers your identity and visibility.
            </p>

            <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center mb-8">
              <Image
                src="/help/settings1.png"
                alt="Account settings showing Profile section with View Profile, Name, Username, Email, Private Account toggle, Date of Birth, Location settings, and Socials"
                width={300}
                height={650}
                className="rounded-lg"
              />
            </div>

            <div className="space-y-4">
              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-purple" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    View Profile
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Tap to see your profile as other users see it.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-gold" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Name, Username &amp; Email
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Your display name, @username, and email address. The
                    username is how others find and mention you.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-green" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Private Account
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Toggle on to make your account private. Only approved
                    followers will be able to see your posts and progress.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-teal" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Location
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Set your <strong className="text-white">Profile Location</strong>{" "}
                    (displayed on your profile and used as a fallback) and toggle{" "}
                    <strong className="text-white">Use GPS Location</strong> for
                    real-time positioning on posts and the local leaderboard.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-rose" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Socials
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Link your{" "}
                    <span className="text-brand-rose">Instagram</span> and{" "}
                    <strong className="text-white">TikTok</strong> usernames to
                    your profile so others can connect with you on other
                    platforms.
                  </p>
                </div>
              </div>
            </div>
          </section>

          {/* Body & Nutrition */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">Body &amp; Nutrition</h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              These settings determine how your daily macro goals are calculated.
            </p>

            <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center mb-8">
              <Image
                src="/help/settings2.png"
                alt="Account settings showing Body section with current weight, goal weight, height, gender, and Nutrition section with protein per lb, auto-adjust macros, exclude dairy, and exclude gluten"
                width={300}
                height={650}
                className="rounded-lg"
              />
            </div>

            <h3 className="text-lg font-bold mb-3 text-white">Body</h3>
            <div className="space-y-4 mb-8">
              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-orange" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Current Weight &amp; Goal Weight
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Your current and target weight in pounds. Goal weight is
                    limited to 5 lbs from your current weight &mdash; aim for
                    1&ndash;2 lbs per week for healthy progress.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-cyan" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Height &amp; Gender
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Used to calculate your daily calorie goal more accurately.
                  </p>
                </div>
              </div>
            </div>

            <h3 className="text-lg font-bold mb-3 text-white">Nutrition</h3>
            <div className="space-y-4">
              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-green" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Protein per lb
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Grams of protein per pound of goal body weight. General
                    fitness: 0.7&ndash;0.8 g/lb. Strength training:
                    0.8&ndash;1.0 g/lb. This directly sets your daily protein
                    target.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-teal" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Auto-adjust Macros for Workouts
                  </h4>
                  <p className="text-gray-400 text-sm">
                    When enabled, the workout log sheet will default the
                    &ldquo;Apply macro adjustments&rdquo; toggle to ON,
                    automatically updating your daily macro targets based on
                    the type of workout logged.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-orange" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Exclude Dairy &amp; Exclude Gluten
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Dietary exclusions used by the AI meal planner to avoid
                    suggesting meals with dairy or gluten ingredients.
                  </p>
                </div>
              </div>
            </div>
          </section>

          {/* FAQ, Aura, Fasting, Notifications */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Features &amp; Notifications
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              Control which features are enabled and how the app notifies you.
            </p>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-8">
              <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
                <Image
                  src="/help/settings3.png"
                  alt="Account settings showing Blocked Users, FAQ section with House Rules, Aura XP, and Aura Levels links, Aura XP Popups toggle, Intermittent Fasting toggle, and Daily Meal Reminder toggle"
                  width={280}
                  height={600}
                  className="rounded-lg"
                />
              </div>
              <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
                <Image
                  src="/help/settings4.png"
                  alt="Account settings showing Intermittent Fasting toggle, Daily Meal Reminder toggle, Health Disclaimer, Privacy and Data section with Privacy Policy, Terms of Service, Ad Tracking Permissions, Export My Data, Sign Out, and Delete Account buttons"
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
                    Blocked Users
                  </h4>
                  <p className="text-gray-400 text-sm">
                    View and manage your list of blocked users.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-cyan" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    FAQ
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Quick links to{" "}
                    <strong className="text-white">House Rules</strong>,{" "}
                    <strong className="text-white">What is Aura XP?</strong>,
                    and{" "}
                    <strong className="text-white">What are Aura Levels?</strong>{" "}
                    &mdash; learn how the gamification system works.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-gold" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Aura XP Popups
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Toggle on to show a popup whenever you earn Aura XP,
                    displaying your XP gain, total, and progress to the next
                    level.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-green" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Track Intermittent Fasting Window
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Enable this to display your daily intermittent fasting
                    window on the Home screen, showing when your eating window
                    starts and ends.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-orange" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Daily Meal Reminder
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Toggle on to receive a daily push notification reminding you
                    to log your meals. Helps you stay consistent with tracking.
                  </p>
                </div>
              </div>
            </div>
          </section>

          {/* Privacy & Data */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">Privacy &amp; Data</h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              At the bottom of the Account page, manage your privacy and data.
            </p>

            <div className="space-y-4">
              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-teal" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Health Disclaimer
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Review the health disclaimer for using macro tracking and
                    nutrition features.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-purple" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Privacy Policy &amp; Terms of Service
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Links to the full Privacy Policy and Terms of Service.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-cyan" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Ad Tracking Permissions
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Control whether personalized ads are shown. Macro Maxxing
                    does not sell or share your personal information for
                    advertising purposes.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-green" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Export My Data
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Download a copy of all your data at any time.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-red-500" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Sign Out &amp; Delete Account
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Sign out of your account, or permanently delete it along
                    with all your data. Account deletion cannot be undone.
                  </p>
                </div>
              </div>
            </div>
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
