import type { Metadata } from "next";
import Link from "next/link";
import {
  ArticleJsonLd,
  BreadcrumbJsonLd,
  FAQPageJsonLd,
} from "@/components/JsonLd";

export const metadata: Metadata = {
  title: "How to Delete Your Account — Macro Maxxing Help",
  description:
    "Learn how to permanently delete your Macro Maxxing account and all associated data. Step-by-step guide covering what gets deleted, data rights, and regulatory compliance.",
  keywords: [
    "macro maxxing delete account",
    "macro maxxing remove account",
    "macro maxxing data deletion",
    "delete macro maxxing data",
    "macro maxxing account removal",
    "macro maxxing privacy",
    "macro maxxing gdpr",
    "macro maxxing ccpa",
    "how to delete macro maxxing",
  ],
  openGraph: {
    title: "How to Delete Your Account — Macro Maxxing Help",
    description:
      "Step-by-step guide to permanently deleting your Macro Maxxing account and all associated data.",
    url: "https://macromaxxing.app/help/how-to-delete-account",
    type: "article",
  },
  alternates: {
    canonical: "https://macromaxxing.app/help/how-to-delete-account",
  },
};

const faqs = [
  {
    question: "How do I delete my Macro Maxxing account?",
    answer:
      "Open the app, tap your profile picture in the top-right corner of the Hub screen to go to Account settings, scroll to the very bottom, and tap 'Delete Account.' Confirm the deletion when prompted. Your account and all data will be permanently removed within 30 days.",
  },
  {
    question: "What data is deleted when I delete my account?",
    answer:
      "All of your data is permanently deleted, including: your profile information, nutrition and food logs, meal photos, fasting history, workout logs, body metrics, streak history, Aura XP and leaderboard data, social posts and comments, and any AI-generated content (meal plans, coaching history). Nothing is retained except where required by law.",
  },
  {
    question: "Can I recover my account after deleting it?",
    answer:
      "No. Account deletion is permanent and cannot be undone. Once you confirm deletion, all data is queued for permanent removal and cannot be recovered. We recommend exporting your data before deleting your account if you want to keep a copy.",
  },
  {
    question: "How long does it take to delete my data?",
    answer:
      "Your account is deactivated immediately upon confirmation. All associated personal data is permanently deleted from our systems within 30 days, consistent with requirements under GDPR, CCPA/CPRA, and other applicable privacy regulations.",
  },
  {
    question: "What happens to my subscription if I delete my account?",
    answer:
      "Deleting your Macro Maxxing account does not automatically cancel your Apple App Store subscription. You must cancel your subscription separately in your Apple ID account settings (Settings > Apple ID > Subscriptions) to stop future billing. We recommend canceling your subscription before deleting your account.",
  },
  {
    question: "Can I delete my data without deleting my account?",
    answer:
      "Yes. You can delete individual food log entries, workout logs, and social posts within the app at any time. You can also export a copy of all your data from Account > Privacy & Data > Export My Data before making any changes.",
  },
  {
    question: "Can I request data deletion by email?",
    answer:
      "Yes. If you are unable to delete your account through the app, you can request account and data deletion by emailing support@grnd-lab.com. We will verify your identity and process your request within 30 days as required by applicable law.",
  },
  {
    question:
      "Is Macro Maxxing compliant with GDPR, CCPA, and other privacy laws?",
    answer:
      "Yes. Macro Maxxing complies with the EU General Data Protection Regulation (GDPR), the California Consumer Privacy Act and California Privacy Rights Act (CCPA/CPRA), the Washington My Health My Data Act, and other applicable state and international privacy laws. You have the right to access, export, correct, and delete your personal data at any time.",
  },
];

function HowToJsonLd() {
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "HowTo",
    name: "How to Delete Your Macro Maxxing Account",
    description:
      "Step-by-step guide to permanently deleting your Macro Maxxing account and all associated data from the iOS app.",
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
        name: "Open Account settings",
        text: "Tap your profile picture in the top-right corner of the Hub screen to open the Account settings page.",
      },
      {
        "@type": "HowToStep",
        name: "Scroll to the bottom",
        text: "Scroll to the very bottom of the Account settings page, past Privacy & Data.",
      },
      {
        "@type": "HowToStep",
        name: "Tap Delete Account",
        text: "Tap the 'Delete Account' button. A confirmation dialog will appear explaining that this action is permanent.",
      },
      {
        "@type": "HowToStep",
        name: "Confirm deletion",
        text: "Confirm that you want to permanently delete your account and all associated data. This action cannot be undone.",
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

export default function DeleteAccountPage() {
  return (
    <>
      <HowToJsonLd />
      <ArticleJsonLd
        title="How to Delete Your Account — Macro Maxxing Help"
        description="Step-by-step guide to permanently deleting your Macro Maxxing account and all associated data, with information on data rights and regulatory compliance."
        url="https://macromaxxing.app/help/how-to-delete-account"
        datePublished="2026-04-12"
        dateModified="2026-04-12"
      />
      <BreadcrumbJsonLd
        items={[
          { name: "Home", url: "https://macromaxxing.app" },
          { name: "Help", url: "https://macromaxxing.app/help" },
          {
            name: "How to Delete Your Account",
            url: "https://macromaxxing.app/help/how-to-delete-account",
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
            <span className="text-gray-300">How to Delete Your Account</span>
          </nav>

          <div className="bg-red-500/10 text-red-400 text-xs font-semibold px-3 py-1 rounded-full inline-block mb-4">
            ACCOUNT DELETION
          </div>
          <h1 className="text-3xl sm:text-5xl font-black mb-6 leading-tight">
            How to Delete Your Account
          </h1>
          <p className="text-gray-300 text-lg leading-relaxed mb-4">
            You can permanently delete your Macro Maxxing account and all
            associated data at any time from within the app. This guide explains
            exactly how to do it, what gets deleted, and your rights under
            applicable privacy regulations.
          </p>
          <p className="text-gray-500 text-sm mb-12">
            Last updated: April 2026
          </p>

          {/* Steps */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-6">
              Steps to Delete Your Account
            </h2>

            <div className="space-y-4">
              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-purple" />
                <div className="pl-4">
                  <div className="flex items-center gap-3 mb-2">
                    <span className="bg-brand-purple/20 text-brand-purple text-xs font-bold w-6 h-6 rounded-full flex items-center justify-center shrink-0">
                      1
                    </span>
                    <h3 className="text-sm font-semibold text-white">
                      Open Account Settings
                    </h3>
                  </div>
                  <p className="text-gray-400 text-sm">
                    Tap your{" "}
                    <strong className="text-white">profile picture</strong> in
                    the top-right corner of the Hub screen to open the Account
                    settings page.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-gold" />
                <div className="pl-4">
                  <div className="flex items-center gap-3 mb-2">
                    <span className="bg-brand-gold/20 text-brand-gold text-xs font-bold w-6 h-6 rounded-full flex items-center justify-center shrink-0">
                      2
                    </span>
                    <h3 className="text-sm font-semibold text-white">
                      Scroll to the Bottom
                    </h3>
                  </div>
                  <p className="text-gray-400 text-sm">
                    Scroll past all settings sections to the very bottom of the
                    page, past{" "}
                    <strong className="text-white">Privacy &amp; Data</strong>.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-orange" />
                <div className="pl-4">
                  <div className="flex items-center gap-3 mb-2">
                    <span className="bg-brand-orange/20 text-brand-orange text-xs font-bold w-6 h-6 rounded-full flex items-center justify-center shrink-0">
                      3
                    </span>
                    <h3 className="text-sm font-semibold text-white">
                      Tap &ldquo;Delete Account&rdquo;
                    </h3>
                  </div>
                  <p className="text-gray-400 text-sm">
                    Tap the{" "}
                    <strong className="text-white">Delete Account</strong>{" "}
                    button. A confirmation dialog will appear warning you that
                    this action is permanent.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-red-500" />
                <div className="pl-4">
                  <div className="flex items-center gap-3 mb-2">
                    <span className="bg-red-500/20 text-red-400 text-xs font-bold w-6 h-6 rounded-full flex items-center justify-center shrink-0">
                      4
                    </span>
                    <h3 className="text-sm font-semibold text-white">
                      Confirm Deletion
                    </h3>
                  </div>
                  <p className="text-gray-400 text-sm">
                    Confirm that you want to permanently delete your account.{" "}
                    <strong className="text-red-400">
                      This action cannot be undone.
                    </strong>{" "}
                    Your account will be deactivated immediately and all data
                    permanently deleted within 30 days.
                  </p>
                </div>
              </div>
            </div>
          </section>

          {/* What gets deleted */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              What Gets Permanently Deleted
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              When you delete your account,{" "}
              <strong className="text-white">
                all of your personal data is permanently removed
              </strong>{" "}
              from our systems. This includes:
            </p>

            <div className="bg-red-500/5 border border-red-500/20 rounded-2xl p-6">
              <ul className="space-y-3 text-gray-300 text-sm">
                <li className="flex items-start gap-3">
                  <span className="text-red-400 mt-0.5 shrink-0">&#10005;</span>
                  <span>
                    <strong className="text-white">Account information</strong>{" "}
                    &mdash; email address, display name, username, profile
                    photo, and date of birth
                  </span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-red-400 mt-0.5 shrink-0">&#10005;</span>
                  <span>
                    <strong className="text-white">Nutrition data</strong>{" "}
                    &mdash; all food logs, macro entries, meal photos, daily
                    nutrition totals, and saved meal templates
                  </span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-red-400 mt-0.5 shrink-0">&#10005;</span>
                  <span>
                    <strong className="text-white">Fasting data</strong> &mdash;
                    all fasting timer history, start/end timestamps, and fasting
                    window preferences
                  </span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-red-400 mt-0.5 shrink-0">&#10005;</span>
                  <span>
                    <strong className="text-white">Workout data</strong> &mdash;
                    all workout logs, exercise history, and saved workout
                    templates
                  </span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-red-400 mt-0.5 shrink-0">&#10005;</span>
                  <span>
                    <strong className="text-white">Body metrics</strong> &mdash;
                    weight, goal weight, height, and other body measurements
                  </span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-red-400 mt-0.5 shrink-0">&#10005;</span>
                  <span>
                    <strong className="text-white">
                      Streaks &amp; gamification
                    </strong>{" "}
                    &mdash; streak history, Aura XP, level progress, and
                    leaderboard rankings
                  </span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-red-400 mt-0.5 shrink-0">&#10005;</span>
                  <span>
                    <strong className="text-white">Social content</strong>{" "}
                    &mdash; all posts, comments, follows, and interactions on
                    the community feed
                  </span>
                </li>
                <li className="flex items-start gap-3">
                  <span className="text-red-400 mt-0.5 shrink-0">&#10005;</span>
                  <span>
                    <strong className="text-white">
                      AI-generated content
                    </strong>{" "}
                    &mdash; meal planner history, nutrition coaching history,
                    and any AI analysis results
                  </span>
                </li>
              </ul>
            </div>
          </section>

          {/* Before you delete */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">Before You Delete</h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              We recommend taking these steps before deleting your account:
            </p>

            <div className="space-y-4">
              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-green" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Export Your Data
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Go to Account &gt; Privacy &amp; Data &gt;{" "}
                    <strong className="text-white">Export My Data</strong> to
                    download a JSON copy of all your data before deletion.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-gold" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Cancel Your Subscription
                  </h4>
                  <p className="text-gray-400 text-sm">
                    If you have an active AI Pro subscription, cancel it in your
                    Apple&nbsp;ID settings (Settings &gt; Apple&nbsp;ID &gt;
                    Subscriptions) before deleting your account. Deleting your
                    Macro Maxxing account does{" "}
                    <strong className="text-white">not</strong> automatically
                    cancel your App Store subscription.
                  </p>
                </div>
              </div>
            </div>
          </section>

          {/* Regulatory compliance */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Your Data Rights &amp; Regulatory Compliance
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              Macro Maxxing is committed to protecting your privacy and
              complying with all applicable data protection regulations. Your
              right to delete your data is guaranteed under multiple
              frameworks:
            </p>

            <div className="space-y-4">
              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-purple" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    GDPR (EU/UK/EEA)
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Under the General Data Protection Regulation, you have the{" "}
                    <strong className="text-white">right to erasure</strong>{" "}
                    (Article 17). Upon request, we delete all personal data
                    associated with your account. Data is erased within 30 days
                    unless retention is required by law.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-gold" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    CCPA / CPRA (California)
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Under the California Consumer Privacy Act and California
                    Privacy Rights Act, you have the{" "}
                    <strong className="text-white">right to deletion</strong>.
                    We delete all personal information collected about you,
                    including any data classified as sensitive personal
                    information (nutrition data, body metrics). We do not sell
                    your personal data.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-teal" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Washington My Health My Data Act
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Nutrition data, fasting data, body metrics, and workout
                    data may constitute consumer health data under this act.
                    You have the right to delete all such data, and we comply
                    with all requirements for handling consumer health data
                    deletion requests.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-cyan" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Other U.S. State Privacy Laws
                  </h4>
                  <p className="text-gray-400 text-sm">
                    We comply with the Virginia Consumer Data Protection Act
                    (VCDPA), Colorado Privacy Act (CPA), Connecticut Data
                    Privacy Act (CTDPA), Texas Data Privacy and Security Act
                    (TDPSA), Oregon Consumer Privacy Act (OCPA), and other
                    applicable state privacy laws that grant deletion rights.
                  </p>
                </div>
              </div>
            </div>

            <div className="bg-brand-purple/5 border border-brand-purple/20 rounded-2xl p-6 mt-6">
              <p className="text-gray-300 text-sm leading-relaxed">
                <strong className="text-white">
                  Alternative deletion method:
                </strong>{" "}
                If you are unable to access the app, you can request account
                and data deletion by emailing{" "}
                <a
                  href="mailto:support@grnd-lab.com"
                  className="text-brand-purple hover:underline"
                >
                  support@grnd-lab.com
                </a>{" "}
                from the email address associated with your account. We will
                verify your identity and process your request within 30 days
                (or sooner if required by applicable law). You may also
                designate an authorized agent to submit a request on your
                behalf.
              </p>
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

          {/* Related links */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">Related</h2>
            <div className="space-y-2">
              <Link
                href="/privacy-policy"
                className="block text-brand-purple hover:underline text-sm"
              >
                Privacy Policy
              </Link>
              <Link
                href="/terms"
                className="block text-brand-purple hover:underline text-sm"
              >
                Terms of Service &amp; EULA
              </Link>
              <Link
                href="/help/settings"
                className="block text-brand-purple hover:underline text-sm"
              >
                Settings &amp; Account Guide
              </Link>
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
