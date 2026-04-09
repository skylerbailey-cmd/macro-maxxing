import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import {
  ArticleJsonLd,
  BreadcrumbJsonLd,
  FAQPageJsonLd,
} from "@/components/JsonLd";

export const metadata: Metadata = {
  title: "How to Find People in Macro Maxxing — Step-by-Step Guide",
  description:
    "Learn how to search for and follow other users in Macro Maxxing. Find friends, follow their progress, and build your fitness community.",
  keywords: [
    "how to find people macro maxxing",
    "macro maxxing search users",
    "macro maxxing follow",
    "macro maxxing community",
    "fitness app find friends",
    "macro maxxing social",
    "macro maxxing help",
    "follow fitness friends app",
  ],
  openGraph: {
    title: "How to Find People in Macro Maxxing — Step-by-Step Guide",
    description:
      "Search for users by name or username and follow their fitness journey. Build your community in Macro Maxxing.",
    url: "https://macromaxxing.app/help/how-to-find-people",
    type: "article",
  },
  alternates: {
    canonical: "https://macromaxxing.app/help/how-to-find-people",
  },
};

const faqs = [
  {
    question: "How do I find people in Macro Maxxing?",
    answer:
      "Open Macro Maxxing, tap the yellow + button on the Hub screen, then select 'Find People.' Type a name or username into the search bar and matching results will appear. Tap 'Follow' to follow a user.",
  },
  {
    question: "Can I search by username in Macro Maxxing?",
    answer:
      "Yes. The search finds users by both their display name and their @username. For example, searching 'juan' would match a user named Juan with the username @juanwon1.",
  },
  {
    question: "How do I follow someone in Macro Maxxing?",
    answer:
      "After finding a user via the search, tap the yellow 'Follow' button next to their name. You'll then see their posts in your feed and be able to view their profile.",
  },
  {
    question: "Can I see where other users are located in Macro Maxxing?",
    answer:
      "Yes. If a user has set their Profile Location in their account settings, their city and country appear below their username in search results. For example, you might see 'Los Angeles, CA, United States' under a user's name.",
  },
  {
    question: "Is there a follower count in Macro Maxxing?",
    answer:
      "Yes. Each user's follower count is displayed next to a people icon in search results, so you can see how many followers they have before deciding to follow them.",
  },
];

function HowToJsonLd() {
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "HowTo",
    name: "How to Find People in Macro Maxxing",
    description:
      "Step-by-step guide to finding and following other users in the Macro Maxxing iOS app.",
    totalTime: "PT1M",
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
        name: "Select Find People",
        text: "From the action menu, tap 'Find People' to open the user search screen.",
        image: "https://macromaxxing.app/help/step1.png",
      },
      {
        "@type": "HowToStep",
        name: "Search and follow",
        text: "Type a name or username into the search bar. Matching users appear with their profile photo, username, location, and follower count. Tap 'Follow' to follow them.",
        image: "https://macromaxxing.app/help/findPeople1.png",
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

export default function HowToFindPeople() {
  return (
    <>
      <HowToJsonLd />
      <ArticleJsonLd
        title="How to Find People in Macro Maxxing"
        description="Step-by-step guide to finding and following other users in the Macro Maxxing community."
        url="https://macromaxxing.app/help/how-to-find-people"
        datePublished="2026-04-09"
        dateModified="2026-04-09"
      />
      <BreadcrumbJsonLd
        items={[
          { name: "Home", url: "https://macromaxxing.app" },
          { name: "Help", url: "https://macromaxxing.app/help" },
          {
            name: "How to Find People",
            url: "https://macromaxxing.app/help/how-to-find-people",
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
            <span className="text-gray-300">How to Find People</span>
          </nav>

          <div className="bg-brand-green/10 text-brand-green text-xs font-semibold px-3 py-1 rounded-full inline-block mb-4">
            COMMUNITY
          </div>
          <h1 className="text-3xl sm:text-5xl font-black mb-6 leading-tight">
            How to Find People
          </h1>
          <p className="text-gray-300 text-lg leading-relaxed mb-4">
            Macro Maxxing is better with a community. Find friends, follow other
            users, and see their posts, progress, and wins on your feed. Here&apos;s
            how to search for and follow people.
          </p>
          <p className="text-gray-500 text-sm mb-12">
            Last updated: April 2026
          </p>

          {/* Step 1 */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Step 1: Tap the + Button on the Hub
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              From the <strong className="text-white">Hub</strong> tab, tap the
              yellow <strong className="text-brand-gold">+</strong> button in
              the bottom-right corner to open the quick-action menu.
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

          {/* Step 2 */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Step 2: Select &ldquo;Find People&rdquo;
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              From the action menu, tap{" "}
              <strong className="text-brand-green">Find People</strong> to open
              the user search screen.
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

          {/* Step 3 */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Step 3: Search &amp; Follow
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              Type a name or username into the search bar at the top. Matching
              users appear instantly under{" "}
              <strong className="text-white">Results</strong>. Each result shows:
            </p>

            <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center mb-8">
              <Image
                src="/help/findPeople1.png"
                alt="Find People search screen showing a search for 'juan' with a matching user result displaying profile photo, username, location, follower count, and Follow button"
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
                    Profile Photo &amp; Username
                  </h4>
                  <p className="text-gray-400 text-sm">
                    The user&apos;s profile picture, display name, and
                    @username so you can confirm you&apos;re following the right
                    person.
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
                    If the user has set a Profile Location, their city and
                    country appear below their username (e.g. &ldquo;Los
                    Angeles, CA, United States&rdquo;).
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-green" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Follower Count
                  </h4>
                  <p className="text-gray-400 text-sm">
                    A people icon with their follower count, so you can see how
                    active they are in the community.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-5 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-gold" />
                <div className="pl-4">
                  <h4 className="text-sm font-semibold text-white mb-1">
                    Follow Button
                  </h4>
                  <p className="text-gray-400 text-sm">
                    Tap the yellow{" "}
                    <strong className="text-brand-gold">Follow</strong> button
                    to follow the user. Their posts will start appearing in your
                    feed, and you can view their full profile.
                  </p>
                </div>
              </div>
            </div>
          </section>

          {/* Tips */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">Tips</h2>
            <div className="space-y-4">
              <div className="bg-brand-card rounded-xl p-5 border border-white/5">
                <p className="text-gray-300 text-sm">
                  <strong className="text-brand-purple">
                    Search by Username
                  </strong>{" "}
                  &mdash; If you know someone&apos;s @username, searching for it
                  directly is the fastest way to find them.
                </p>
              </div>
              <div className="bg-brand-card rounded-xl p-5 border border-white/5">
                <p className="text-gray-300 text-sm">
                  <strong className="text-brand-teal">
                    Build Your Community
                  </strong>{" "}
                  &mdash; Following people keeps you accountable. See their
                  posts, cheer on their progress, and stay motivated together.
                </p>
              </div>
              <div className="bg-brand-card rounded-xl p-5 border border-white/5">
                <p className="text-gray-300 text-sm">
                  <strong className="text-brand-gold">
                    Set Your Location
                  </strong>{" "}
                  &mdash; Add your city in{" "}
                  <Link
                    href="/help/settings"
                    className="text-brand-purple hover:underline"
                  >
                    Settings
                  </Link>{" "}
                  so others can find you and you show up on the local
                  leaderboard.
                </p>
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
