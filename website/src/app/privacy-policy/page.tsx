import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy Policy",
  description:
    "Macro Maxxing privacy policy. Learn how we collect, use, and protect your data.",
};

export default function PrivacyPolicyPage() {
  return (
    <section className="bg-brand-bg text-gray-300 py-20">
      <div className="max-w-3xl mx-auto px-4 sm:px-6">
        <h1 className="text-4xl font-bold text-white mb-2">Privacy Policy</h1>
        <p className="text-gray-500 mb-12">Effective Date: March 23, 2026</p>

        <div className="space-y-10 text-sm leading-relaxed">
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              1. Introduction
            </h2>
            <p>
              Macro Maxxing (&ldquo;we&rdquo;, &ldquo;our&rdquo;, or
              &ldquo;us&rdquo;) operates the Macro Maxxing mobile application
              (the &ldquo;App&rdquo;). This Privacy Policy explains what
              information we collect, how we use it, and your rights regarding
              your data.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              2. Information We Collect
            </h2>

            <h3 className="text-base font-semibold text-white mt-4 mb-2">
              2.1 Information You Provide
            </h3>
            <ul className="list-disc list-inside space-y-1 ml-2">
              <li>
                <strong className="text-white">Account information:</strong>{" "}
                email address, display name, and profile photo (optional).
              </li>
              <li>
                <strong className="text-white">Nutrition data:</strong> food
                logs, macro entries, meal photos, and daily nutrition totals
                (calories, protein, carbs, fat).
              </li>
              <li>
                <strong className="text-white">Fasting data:</strong> fasting
                timer start/end timestamps and fasting window preferences.
              </li>
              <li>
                <strong className="text-white">Body metrics:</strong> weight,
                body measurements, and fitness goals (if provided).
              </li>
              <li>
                <strong className="text-white">Voice input:</strong> audio
                recordings when using voice food logging (processed in
                real-time, not stored).
              </li>
            </ul>

            <h3 className="text-base font-semibold text-white mt-4 mb-2">
              2.2 Information Collected Automatically
            </h3>
            <ul className="list-disc list-inside space-y-1 ml-2">
              <li>Device type, operating system version, and app version.</li>
              <li>
                Anonymous usage analytics (screens viewed, features used).
              </li>
              <li>Crash reports and performance diagnostics.</li>
            </ul>

            <h3 className="text-base font-semibold text-white mt-4 mb-2">
              2.3 Information from Food Photos
            </h3>
            <p>
              When you use the AI food scanner, your photo is sent to our
              servers for analysis. Photos are processed to estimate nutritional
              content and are not retained after analysis is complete unless you
              choose to save them to your food log.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              3. How We Use Your Information
            </h2>
            <ul className="list-disc list-inside space-y-1 ml-2">
              <li>To provide and improve the App&apos;s features.</li>
              <li>
                To analyze food photos and estimate macro/calorie content.
              </li>
              <li>
                To display your nutrition history, streaks, and leaderboard
                rankings.
              </li>
              <li>
                To send you notifications (e.g., fasting reminders, streak
                alerts) if you opt in.
              </li>
              <li>To diagnose bugs and improve app performance.</li>
            </ul>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              4. Third-Party Services
            </h2>
            <p className="mb-3">
              We use the following third-party services to operate the App. Each
              has its own privacy policy governing how it handles data:
            </p>
            <ul className="list-disc list-inside space-y-2 ml-2">
              <li>
                <strong className="text-white">Firebase (Google):</strong>{" "}
                Authentication, cloud database, analytics, and crash reporting.
                Data may be stored on Google servers in the United States.{" "}
                <a
                  href="https://firebase.google.com/support/privacy"
                  className="text-brand-purple hover:underline"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Firebase Privacy Policy
                </a>
              </li>
              <li>
                <strong className="text-white">Anthropic (Claude AI):</strong>{" "}
                All AI food photo analysis and voice input processing is
                handled exclusively by Anthropic&apos;s Claude models (Haiku and
                Sonnet). Photos and text are sent to Anthropic&apos;s API for
                analysis. No other third-party AI services are used.{" "}
                <a
                  href="https://www.anthropic.com/privacy"
                  className="text-brand-purple hover:underline"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Anthropic Privacy Policy
                </a>
              </li>
              <li>
                <strong className="text-white">USDA FoodData Central:</strong>{" "}
                Nutritional database lookups for food items. Only food search
                queries are sent; no personal data is transmitted.{" "}
                <a
                  href="https://fdc.nal.usda.gov/api-guide"
                  className="text-brand-purple hover:underline"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  USDA API Info
                </a>
              </li>
              <li>
                <strong className="text-white">
                  Google AdMob:
                </strong>{" "}
                In-app advertising, including banner, interstitial, and rewarded
                ads. AdMob may collect device identifiers (such as the
                Advertising ID), IP address, and interaction data to serve and
                measure ads. Ad data is processed by Google.{" "}
                <a
                  href="https://policies.google.com/technologies/ads"
                  className="text-brand-purple hover:underline"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Google Ads Privacy
                </a>
              </li>
            </ul>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              5. Data Sharing
            </h2>
            <p>
              We do not sell your personal information to third parties. We share
              data only in the following circumstances:
            </p>
            <ul className="list-disc list-inside space-y-1 ml-2 mt-2">
              <li>
                With the third-party services listed above, solely to provide
                App functionality.
              </li>
              <li>
                With other users, if you participate in social features
                (leaderboards, community posts). You control what you share
                publicly.
              </li>
              <li>
                If required by law, regulation, or valid legal process.
              </li>
            </ul>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              6. Data Retention
            </h2>
            <p>
              We retain your account and nutrition data for as long as your
              account is active. If you delete your account, we will delete your
              personal data within 30 days, except where we are required to
              retain it for legal or compliance purposes. Anonymous, aggregated
              analytics data may be retained indefinitely.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              7. Your Rights
            </h2>
            <p className="mb-2">You have the right to:</p>
            <ul className="list-disc list-inside space-y-1 ml-2">
              <li>
                <strong className="text-white">Access</strong> your data — view
                all nutrition logs, fasting history, and account information
                within the App.
              </li>
              <li>
                <strong className="text-white">Export</strong> your data —
                export a full copy of your data in JSON format directly from
                Account &gt; Privacy &amp; Data &gt; Export My Data in the App.
              </li>
              <li>
                <strong className="text-white">Delete</strong> your data —
                delete your account and all associated data from within the App
                settings or by contacting us.
              </li>
              <li>
                <strong className="text-white">Correct</strong> your data —
                edit or update any information you have provided.
              </li>
              <li>
                <strong className="text-white">Opt out</strong> of
                notifications at any time through your device settings.
              </li>
            </ul>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              8. Data Security
            </h2>
            <p>
              We use industry-standard security measures to protect your data,
              including encryption in transit (TLS) and at rest. However, no
              method of electronic storage is 100% secure, and we cannot
              guarantee absolute security.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              9. Children&apos;s Privacy
            </h2>
            <p>
              The App is not intended for children under 13. We do not knowingly
              collect personal information from children under 13. If we learn
              that we have collected data from a child under 13, we will delete
              it promptly.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              10. Advertising &amp; Cookies
            </h2>
            <p className="mb-2">
              The App itself does not use cookies. Our website (macromaxxing.app)
              may use cookies and similar tracking technologies for analytics and
              to improve your browsing experience.
            </p>
            <p className="mb-2">
              We display advertisements within the App using Google AdMob,
              including banner ads, interstitial ads, and rewarded ads. Google
              AdMob may collect device identifiers (such as your Advertising ID),
              IP address, and ad interaction data to serve and measure
              personalized ads. You can opt out of personalized advertising by
              adjusting your device settings:
            </p>
            <ul className="list-disc list-inside space-y-1 ml-2">
              <li>
                <strong className="text-white">iOS:</strong> Settings &gt;
                Privacy &amp; Security &gt; Tracking, and disable &ldquo;Allow
                Apps to Request to Track.&rdquo;
              </li>
              <li>
                <strong className="text-white">Web:</strong> Manage cookie
                preferences via your browser settings or our cookie banner (if
                displayed).
              </li>
            </ul>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              11. International Data Transfers
            </h2>
            <p>
              Your data may be processed and stored on servers located in the
              United States and other countries where our service providers
              operate (including Google and Anthropic). By using the App, you
              consent to the transfer of your information to countries that may
              have different data-protection laws than your country of residence.
              We take steps to ensure that your data receives an adequate level
              of protection wherever it is processed.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              12. Your Privacy Rights Under Applicable Law
            </h2>
            <p className="mb-3">
              Depending on where you live, you may have additional rights under
              local privacy laws such as the California Consumer Privacy Act
              (CCPA) or the EU/UK General Data Protection Regulation (GDPR).
            </p>

            <h3 className="text-base font-semibold text-white mt-4 mb-2">
              California Residents (CCPA)
            </h3>
            <ul className="list-disc list-inside space-y-1 ml-2 mb-3">
              <li>
                <strong className="text-white">Right to Know:</strong> You may
                request details about the categories and specific pieces of
                personal information we have collected about you in the past 12
                months.
              </li>
              <li>
                <strong className="text-white">Right to Delete:</strong> You
                may request deletion of your personal information, subject to
                certain legal exceptions.
              </li>
              <li>
                <strong className="text-white">
                  Right to Opt Out of Sale/Sharing:
                </strong>{" "}
                We do not sell your personal information. We share limited data
                with Google AdMob for ad delivery, which may constitute
                &ldquo;sharing&rdquo; under the CCPA. You can opt out of
                personalized ads by declining the App Tracking Transparency
                prompt or adjusting your preferences in Account &gt; Privacy
                &amp; Data &gt; Ad Tracking Permissions.
              </li>
              <li>
                <strong className="text-white">Non-Discrimination:</strong> We
                will not discriminate against you for exercising your CCPA
                rights.
              </li>
            </ul>

            <h3 className="text-base font-semibold text-white mt-4 mb-2">
              EU/UK Residents (GDPR)
            </h3>
            <ul className="list-disc list-inside space-y-1 ml-2 mb-3">
              <li>
                <strong className="text-white">Legal Basis:</strong> We process
                your data based on your consent (e.g., photo analysis),
                contractual necessity (e.g., providing App features), and
                legitimate interests (e.g., improving the App and preventing
                fraud).
              </li>
              <li>
                <strong className="text-white">Data Portability:</strong> You
                may request a copy of your data in a structured,
                machine-readable format.
              </li>
              <li>
                <strong className="text-white">Right to Object:</strong> You
                may object to processing based on legitimate interests.
              </li>
              <li>
                <strong className="text-white">Supervisory Authority:</strong>{" "}
                You have the right to lodge a complaint with your local data
                protection authority.
              </li>
            </ul>
            <p>
              To exercise any of these rights, contact us at{" "}
              <a
                href="mailto:privacy@macromaxxing.app"
                className="text-brand-purple hover:underline"
              >
                privacy@macromaxxing.app
              </a>
              . We will respond within the timeframe required by applicable law.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              13. Changes to This Policy
            </h2>
            <p>
              We may update this Privacy Policy from time to time. We will
              notify you of material changes by posting the updated policy in the
              App or on our website with a revised effective date.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              14. Contact Us
            </h2>
            <p>
              If you have questions about this Privacy Policy or want to
              exercise your data rights, contact us at:
            </p>
            <p className="mt-2">
              <a
                href="mailto:privacy@macromaxxing.app"
                className="text-brand-purple hover:underline"
              >
                privacy@macromaxxing.app
              </a>
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
