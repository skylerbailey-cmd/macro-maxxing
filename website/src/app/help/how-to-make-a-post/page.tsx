import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import {
  ArticleJsonLd,
  BreadcrumbJsonLd,
  FAQPageJsonLd,
} from "@/components/JsonLd";

export const metadata: Metadata = {
  title: "How to Make a Post in Macromaxxing — Step-by-Step Guide",
  description:
    "Learn how to create posts in Macromaxxing. Share your fuel log, goal progress, workouts, transformations, and more with the community. Earn aura points for Fuel Log and Workout posts.",
  keywords: [
    "how to post macromaxxing",
    "macromaxxing post",
    "macromaxxing feed",
    "macromaxxing community",
    "fitness social post",
    "share meal log",
    "share workout post",
    "macromaxxing help",
    "macromaxxing labels",
    "macromaxxing aura points",
  ],
  openGraph: {
    title: "How to Make a Post in Macromaxxing — Step-by-Step Guide",
    description:
      "Share your fuel log, goal progress, workouts, and wins with the community. Full step-by-step guide with screenshots.",
    url: "https://macromaxxing.app/help/how-to-make-a-post",
    type: "article",
  },
  alternates: {
    canonical: "https://macromaxxing.app/help/how-to-make-a-post",
  },
};

const faqs = [
  {
    question: "How do I make a post in Macromaxxing?",
    answer:
      "Open Macromaxxing, tap the yellow + button on the Hub screen, then select 'Make a Post.' Choose an optional label (Fuel Log, Goal, Workout, Mog Board, Transformation, Meal Inspo, or Advice), set your audience visibility, write a title and body, optionally attach a photo, and tap Post.",
  },
  {
    question: "What are post labels in Macromaxxing?",
    answer:
      "Post labels categorize your posts and some automatically attach content. Fuel Log attaches your daily food entries with calorie counts. Goal shows your macro discipline percentage and progress bars. Workout attaches your logged exercises with duration and calories burned. Mog Board, Transformation, Meal Inspo, and Advice are purely for categorization.",
  },
  {
    question: "Do I earn points for posting in Macromaxxing?",
    answer:
      "Yes. Posts with the Fuel Log or Workout labels earn you aura points, which contribute to your XP, level, and daily streak displayed on the Hub screen.",
  },
  {
    question: "Who can see my posts in Macromaxxing?",
    answer:
      "You control visibility with the 'Visible to' picker when creating a post. Options include Arena (the broader community), and other audience scopes depending on the label. The Mog Board label also offers Team, Local, and Arena visibility options.",
  },
  {
    question: "Can I attach photos to posts in Macromaxxing?",
    answer:
      "Yes. When creating a post, tap 'Take Photo' to use your camera or 'Library' to pick from your photo library. Photos are optional but make your posts more engaging on the feed.",
  },
];

function HowToJsonLd() {
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "HowTo",
    name: "How to Make a Post in Macromaxxing",
    description:
      "Step-by-step guide to creating posts in the Macromaxxing iOS app, including choosing labels, setting visibility, and sharing fuel logs, goals, and workouts.",
    totalTime: "PT1M",
    tool: [
      {
        "@type": "HowToTool",
        name: "Macromaxxing iOS app",
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
        name: "Select Make a Post",
        text: "From the action menu, tap 'Make a Post' to open the New Post screen.",
        image: "https://macromaxxing.app/help/step1.png",
      },
      {
        "@type": "HowToStep",
        name: "Compose your post",
        text: "Choose an optional label (Fuel Log, Goal, Workout, Mog Board, Transformation, Meal Inspo, or Advice), set your audience visibility, write a title (up to 80 characters) and body (up to 300 characters), and optionally attach a photo.",
        image: "https://macromaxxing.app/help/makePost1.png",
      },
      {
        "@type": "HowToStep",
        name: "Publish",
        text: "Tap the Post button in the top-right corner to publish your post to the feed.",
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

export default function HowToMakeAPost() {
  return (
    <>
      <HowToJsonLd />
      <ArticleJsonLd
        title="How to Make a Post in Macromaxxing"
        description="Step-by-step guide on how to create posts in Macromaxxing with labels like Fuel Log, Goal, Workout, and more."
        url="https://macromaxxing.app/help/how-to-make-a-post"
        datePublished="2026-04-09"
        dateModified="2026-04-09"
      />
      <BreadcrumbJsonLd
        items={[
          { name: "Home", url: "https://macromaxxing.app" },
          { name: "Help", url: "https://macromaxxing.app/help" },
          {
            name: "How to Make a Post",
            url: "https://macromaxxing.app/help/how-to-make-a-post",
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
            <span className="text-gray-300">How to Make a Post</span>
          </nav>

          <div className="bg-brand-purple/10 text-brand-purple text-xs font-semibold px-3 py-1 rounded-full inline-block mb-4">
            COMMUNITY
          </div>
          <h1 className="text-3xl sm:text-5xl font-black mb-6 leading-tight">
            How to Make a Post
          </h1>
          <p className="text-gray-300 text-lg leading-relaxed mb-4">
            Posts are how you share your progress, fuel logs, goals, and wins
            with the Macromaxxing community. This guide walks you through
            creating a post from start to finish.
          </p>
          <p className="text-gray-500 text-sm mb-12">
            Last updated: April 2026
          </p>

          {/* Step 1: Home Screen */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Step 1: Tap the + Button on the Hub
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              From the <strong className="text-white">Hub</strong> tab (your
              home screen), look for the yellow{" "}
              <strong className="text-brand-gold">+</strong> button in the
              bottom-right corner of the screen. This is your quick-action
              button. Tap it to reveal the action menu.
            </p>
            <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
              <Image
                src="/help/Home Screen.png"
                alt="Macromaxxing Hub screen showing the yellow plus button in the bottom-right corner"
                width={300}
                height={650}
                className="rounded-lg"
              />
            </div>
          </section>

          {/* Step 2: Select Make a Post */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Step 2: Select &ldquo;Make a Post&rdquo;
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              After tapping the + button, a menu appears with four
              options: <strong className="text-white">Log a Meal</strong>,{" "}
              <strong className="text-white">Log a Workout</strong>,{" "}
              <strong className="text-white">Make a Post</strong>, and{" "}
              <strong className="text-white">Find People</strong>. Tap{" "}
              <strong className="text-brand-purple">Make a Post</strong> to open
              the New Post screen.
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

          {/* Step 3: New Post Screen */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">
              Step 3: Compose Your Post
            </h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              The <strong className="text-white">New Post</strong> screen is
              where you put your post together. Here&apos;s what each part does:
            </p>

            <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center mb-8">
              <Image
                src="/help/makePost1.png"
                alt="New Post screen showing label options, visibility picker, title field, body field, and photo buttons"
                width={300}
                height={650}
                className="rounded-lg"
              />
            </div>

            <div className="space-y-6">
              <div className="bg-brand-card rounded-xl p-6 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-purple" />
                <div className="pl-4">
                  <h3 className="text-lg font-semibold text-white mb-2">
                    Label (optional)
                  </h3>
                  <p className="text-gray-400 text-sm">
                    Choose a label to categorize your post. Labels appear as
                    colored tags at the top: <strong>None</strong>,{" "}
                    <span className="text-brand-orange">Fuel Log</span>,{" "}
                    <span className="text-brand-green">Goal</span>,{" "}
                    <span className="text-brand-teal">Workout</span>,{" "}
                    <span className="text-brand-gold">Mog Board</span>,{" "}
                    <span className="text-brand-cyan">Transformation</span>,{" "}
                    <span className="text-brand-mint">Meal Inspo</span>, and{" "}
                    <span className="text-brand-rose">Advice</span>. Some
                    labels automatically attach extra content to your
                    post &mdash; more on that below.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-6 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-teal" />
                <div className="pl-4">
                  <h3 className="text-lg font-semibold text-white mb-2">
                    Visible to
                  </h3>
                  <p className="text-gray-400 text-sm">
                    Control who sees your post. Use the{" "}
                    <strong className="text-white">Visible to</strong> picker to
                    choose your audience &mdash; for example,{" "}
                    <strong>Arena</strong> makes it visible to the broader
                    community.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-6 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-gold" />
                <div className="pl-4">
                  <h3 className="text-lg font-semibold text-white mb-2">
                    Title &amp; Body
                  </h3>
                  <p className="text-gray-400 text-sm">
                    Give your post a title (up to 80 characters) and a body (up
                    to 300 characters). The title is your headline &mdash; keep
                    it punchy. The body is where you share details, ask
                    questions, or hype up your wins.
                  </p>
                </div>
              </div>

              <div className="bg-brand-card rounded-xl p-6 border border-white/5 relative overflow-hidden">
                <div className="absolute top-0 left-0 w-1 h-full bg-brand-green" />
                <div className="pl-4">
                  <h3 className="text-lg font-semibold text-white mb-2">
                    Photos
                  </h3>
                  <p className="text-gray-400 text-sm">
                    Attach a photo by tapping{" "}
                    <strong className="text-white">Take Photo</strong> to use
                    your camera or{" "}
                    <strong className="text-white">Library</strong> to pick from
                    your photo library. Photos are optional but make your posts
                    stand out on the feed.
                  </p>
                </div>
              </div>
            </div>
          </section>

          {/* Post Labels Explained */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">Post Labels Explained</h2>
            <p className="text-gray-400 leading-relaxed mb-8">
              Labels do more than just categorize &mdash; some automatically
              attach content to your post. Here&apos;s what each label does:
            </p>

            {/* Fuel Log */}
            <div className="mb-12">
              <h3 className="text-xl font-bold mb-2">
                <span className="text-brand-orange">Fuel Log</span>
              </h3>
              <p className="text-gray-400 leading-relaxed mb-4">
                Selecting the{" "}
                <span className="text-brand-orange font-semibold">
                  Fuel Log
                </span>{" "}
                label automatically attaches today&apos;s food log to your post.
                Your post will show a preview card with the number of items
                logged, each food entry with its calorie count, and a note that
                meal photos will appear in the published post. This is a great
                way to share what you&apos;re eating and keep yourself
                accountable.
              </p>
              <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center mb-4">
                <Image
                  src="/help/makePost2fuelLog.png"
                  alt="New Post screen with Fuel Log label selected, showing attached food items and calories"
                  width={300}
                  height={650}
                  className="rounded-lg"
                />
              </div>
              <div className="bg-brand-orange/10 border border-brand-orange/20 rounded-lg p-4">
                <p className="text-brand-orange text-sm font-semibold">
                  Earns Aura Points!
                </p>
                <p className="text-gray-400 text-sm mt-1">
                  Posting with the Fuel Log label earns you aura points toward
                  your level and streak. Stay consistent to level up faster.
                </p>
              </div>
            </div>

            {/* Goal */}
            <div className="mb-12">
              <h3 className="text-xl font-bold mb-2">
                <span className="text-brand-green">Goal</span>
              </h3>
              <p className="text-gray-400 leading-relaxed mb-4">
                The{" "}
                <span className="text-brand-green font-semibold">Goal</span>{" "}
                label attaches a snapshot of today&apos;s progress toward your
                macro goals. The preview card shows your overall{" "}
                <strong className="text-white">Discipline</strong> percentage
                along with individual progress bars for Calories, Protein,
                Carbs, and Fat &mdash; each with their current intake vs. target.
                Share your progress to motivate others and flex your discipline.
              </p>
              <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
                <Image
                  src="/help/makePost2goal.png"
                  alt="New Post screen with Goal label selected, showing discipline percentage and macro progress bars"
                  width={300}
                  height={650}
                  className="rounded-lg"
                />
              </div>
            </div>

            {/* Workout */}
            <div className="mb-12">
              <h3 className="text-xl font-bold mb-2">
                <span className="text-brand-teal">Workout</span>
              </h3>
              <p className="text-gray-400 leading-relaxed mb-4">
                The{" "}
                <span className="text-brand-teal font-semibold">Workout</span>{" "}
                label automatically attaches today&apos;s workout summary to
                your post. The preview card shows the number of workouts logged,
                each exercise with its duration, type, and calories burned, plus
                the total time and calories. The body field is pre-filled with a
                summary of your session &mdash; share what you crushed at the
                gym today.
              </p>
              <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center mb-4">
                <Image
                  src="/help/makePost2workout.png"
                  alt="New Post screen with Workout label selected, showing attached workout summary with exercises, duration, and calories burned"
                  width={300}
                  height={650}
                  className="rounded-lg"
                />
              </div>
              <div className="bg-brand-teal/10 border border-brand-teal/20 rounded-lg p-4">
                <p className="text-brand-teal text-sm font-semibold">
                  Earns Aura Points!
                </p>
                <p className="text-gray-400 text-sm mt-1">
                  Posting with the Workout label earns you aura points. Log
                  your workouts consistently to build your streak and climb the
                  leaderboard.
                </p>
              </div>
            </div>

            {/* Mog Board */}
            <div className="mb-12">
              <h3 className="text-xl font-bold mb-2">
                <span className="text-brand-gold">Mog Board</span>
              </h3>
              <p className="text-gray-400 leading-relaxed mb-4">
                The{" "}
                <span className="text-brand-gold font-semibold">
                  Mog Board
                </span>{" "}
                label is for sharing your biggest wins and achievements. When
                selected, a{" "}
                <strong className="text-white">Mog Board Options</strong> panel
                appears letting you choose your Feed visibility &mdash;{" "}
                <strong>Team</strong>, <strong>Local</strong>, or{" "}
                <strong>Arena</strong>. Hit a new PR? Reached a milestone? Mog
                on the timeline.
              </p>
              <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
                <Image
                  src="/help/makePost2mogBoard.png"
                  alt="New Post screen with Mog Board label selected, showing Mog Board Options with Team, Local, and Arena visibility choices"
                  width={300}
                  height={650}
                  className="rounded-lg"
                />
              </div>
            </div>

            {/* Transformation */}
            <div className="mb-12">
              <h3 className="text-xl font-bold mb-2">
                <span className="text-brand-cyan">Transformation</span>
              </h3>
              <p className="text-gray-400 leading-relaxed mb-4">
                Use the{" "}
                <span className="text-brand-cyan font-semibold">
                  Transformation
                </span>{" "}
                label to document your physical progress over time. Attach
                before-and-after photos to show your glow-up, then add a title
                and description to tell your story. Physique updates, progress
                pics, and transformation posts all belong here.
              </p>
              <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
                <Image
                  src="/help/makePost2transformation.png"
                  alt="New Post screen with Transformation label selected, showing a before and after photo with progress details"
                  width={300}
                  height={650}
                  className="rounded-lg"
                />
              </div>
            </div>

            {/* Meal Inspo */}
            <div className="mb-12">
              <h3 className="text-xl font-bold mb-2">
                <span className="text-brand-mint">Meal Inspo</span>
              </h3>
              <p className="text-gray-400 leading-relaxed mb-4">
                Share meal ideas and recipes with the{" "}
                <span className="text-brand-mint font-semibold">
                  Meal Inspo
                </span>{" "}
                label. Attach a photo of your meal to show it off, and use the
                title and body to share the recipe or why it works for your
                macros. Found a high-protein meal that actually tastes good? Post
                it here so others can benefit.
              </p>
              <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
                <Image
                  src="/help/mealPost2mealInspo.png"
                  alt="New Post screen with Meal Inspo label selected, showing a meal photo with macro breakdown"
                  width={300}
                  height={650}
                  className="rounded-lg"
                />
              </div>
            </div>

            {/* Advice */}
            <div className="mb-12">
              <h3 className="text-xl font-bold mb-2">
                <span className="text-brand-rose">Advice</span>
              </h3>
              <p className="text-gray-400 leading-relaxed mb-4">
                The{" "}
                <span className="text-brand-rose font-semibold">Advice</span>{" "}
                label is for asking questions or sharing tips with the
                community. Whether you need help hitting your macros or want to
                share what&apos;s working for you, this is the place.
              </p>
              <div className="bg-brand-card rounded-xl p-4 border border-white/5 flex justify-center">
                <Image
                  src="/help/makePost2advice.png"
                  alt="New Post screen with Advice label selected, showing a question about hitting fat goals"
                  width={300}
                  height={650}
                  className="rounded-lg"
                />
              </div>
            </div>
          </section>

          {/* Posting */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">Publishing Your Post</h2>
            <p className="text-gray-400 leading-relaxed mb-6">
              Once you&apos;ve filled in your title and body, chosen a label
              (optional), and attached any photos, tap the{" "}
              <strong className="text-white">Post</strong> button in the
              top-right corner to publish. Your post will appear on the feed for
              others to see, react to, and comment on.
            </p>
            <p className="text-gray-400 leading-relaxed">
              Changed your mind? Tap{" "}
              <strong className="text-white">Cancel</strong> in the top-left
              corner to discard your post and go back.
            </p>
          </section>

          {/* Tips */}
          <section className="mb-16">
            <h2 className="text-2xl font-bold mb-4">Tips</h2>
            <div className="space-y-4">
              <div className="bg-brand-card rounded-xl p-5 border border-white/5">
                <p className="text-gray-300 text-sm">
                  <strong className="text-brand-gold">Earn Aura Points</strong>{" "}
                  &mdash; Posts with the{" "}
                  <span className="text-brand-orange">Fuel Log</span> or{" "}
                  <span className="text-brand-teal">Workout</span> labels earn
                  you aura points. These contribute to your XP, level, and
                  streak shown on the Hub.
                </p>
              </div>
              <div className="bg-brand-card rounded-xl p-5 border border-white/5">
                <p className="text-gray-300 text-sm">
                  <strong className="text-brand-purple">
                    Show Your Discipline
                  </strong>{" "}
                  &mdash; Use the{" "}
                  <span className="text-brand-green">Goal</span> label to flex
                  your daily discipline score. The higher the percentage, the
                  harder you went.
                </p>
              </div>
              <div className="bg-brand-card rounded-xl p-5 border border-white/5">
                <p className="text-gray-300 text-sm">
                  <strong className="text-brand-teal">Add a Photo</strong>{" "}
                  &mdash; Posts with photos get more engagement on the feed. Snap
                  your meal, your pump, or your progress.
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
