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
        <p className="text-gray-500 mb-12">Effective Date: March 25, 2026</p>

        <div className="space-y-10 text-sm leading-relaxed">
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              1. Introduction
            </h2>
            <p>
              GRND Labs LLC (&ldquo;we&rdquo;, &ldquo;our&rdquo;, or
              &ldquo;us&rdquo;), doing business as Macro Maxxing, operates the
              Macro Maxxing mobile application (the &ldquo;App&rdquo;) and the
              website at macromaxxing.app (the &ldquo;Website&rdquo;). This Privacy Policy explains what
              information we collect, how we use it, the legal bases for
              processing, and your rights regarding your data. It applies to all
              users of the App and Website worldwide.
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
                <strong className="text-white">Workout data:</strong> exercise
                type, duration, and intensity logged through the App.
              </li>
              <li>
                <strong className="text-white">Voice input:</strong> audio
                recordings when using voice food logging (processed in
                real-time via speech-to-text, not stored as audio).
              </li>
              <li>
                <strong className="text-white">Social content:</strong> posts,
                comments, and interactions on the community feed.
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
              <li>
                IP address (used for approximate location and security
                purposes; not stored long-term).
              </li>
              <li>
                Advertising identifiers (e.g., IDFA on iOS), if you have
                granted tracking permission.
              </li>
            </ul>

            <h3 className="text-base font-semibold text-white mt-4 mb-2">
              2.3 Information from Food Photos
            </h3>
            <p>
              When you use the AI food scanner, your photo is sent to
              Anthropic&apos;s servers for analysis by Claude AI. Photos are
              processed to estimate nutritional content and are not retained by
              Anthropic after analysis is complete. If you choose to save a meal
              to your food log, the photo thumbnail is stored in your account.
            </p>

            <h3 className="text-base font-semibold text-white mt-4 mb-2">
              2.4 Consumer Health Data Notice
            </h3>
            <p>
              Certain information we collect — including nutrition data, fasting
              data, body metrics, and workout data — may constitute
              &ldquo;consumer health data&rdquo; under the Washington My Health
              My Data Act and similar state laws, or &ldquo;sensitive personal
              information&rdquo; under the California Privacy Rights Act (CPRA).
              We collect this data solely to provide the App&apos;s core
              nutrition tracking functionality. We do not sell consumer health
              data. We do not use consumer health data for advertising purposes.
              We share consumer health data with Anthropic (Claude AI) only as
              necessary to provide the AI food analysis feature, and with
              Firebase (Google) only as necessary to store and sync your data.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              3. How We Use Your Information
            </h2>
            <ul className="list-disc list-inside space-y-1 ml-2">
              <li>
                To provide and improve the App&apos;s core features, including
                nutrition tracking, fasting timers, and workout adjustments.
              </li>
              <li>
                To analyze food photos and voice descriptions using Claude AI
                and estimate macro/calorie content.
              </li>
              <li>
                To display your nutrition history, streaks, and leaderboard
                rankings.
              </li>
              <li>
                To power social features, including displaying your display
                name, profile photo, streak count, Aura XP level, and any
                content you post to the community feed.
              </li>
              <li>
                To send you notifications (e.g., fasting reminders, streak
                alerts) if you opt in.
              </li>
              <li>
                To serve advertisements via Google AdMob (subject to your
                tracking preferences).
              </li>
              <li>To diagnose bugs and improve app performance.</li>
              <li>
                To comply with legal obligations and respond to lawful
                requests.
              </li>
            </ul>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              4. AI Processing &amp; Automated Decision-Making
            </h2>
            <p className="mb-3">
              The App uses artificial intelligence (Anthropic&apos;s Claude
              Haiku and Sonnet models) to analyze food photos and voice
              descriptions and estimate nutritional content. This processing
              is automated but does not produce legal or similarly significant
              effects — it generates nutrition estimates that you can review,
              edit, and override before saving. No decisions about access to
              services, pricing, or other significant outcomes are made based
              on AI outputs.
            </p>
            <p>
              You always have the option to manually enter or correct any
              macro values. AI-generated estimates are provided as a
              convenience and should not be relied upon for medical or
              clinical nutrition decisions.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              5. Third-Party Services
            </h2>
            <p className="mb-3">
              We use the following third-party services to operate the App. Each
              has its own privacy policy governing how it handles data:
            </p>
            <ul className="list-disc list-inside space-y-2 ml-2">
              <li>
                <strong className="text-white">Firebase (Google):</strong>{" "}
                Authentication, cloud database (Firestore), analytics, and
                crash reporting. Data may be stored on Google servers in the
                United States.{" "}
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
                analysis. Anthropic does not use API inputs to train its models.
                No other third-party AI services are used.{" "}
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
              6. Data Sharing
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
                With other users, if you participate in social features. The
                following information may be publicly visible: your display
                name, profile photo, streak count, Aura XP level, leaderboard
                rank, and any content you post to the community feed. You
                control what you post.
              </li>
              <li>
                With Google AdMob for advertising purposes, subject to your
                App Tracking Transparency preferences (see Section 11).
              </li>
              <li>
                If required by law, regulation, subpoena, court order, or
                other valid legal process.
              </li>
              <li>
                In connection with a merger, acquisition, or sale of all or a
                portion of our assets, in which case you will be notified via
                the App or email.
              </li>
            </ul>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              7. Data Retention
            </h2>
            <p className="mb-3">
              We retain your data for as long as your account is active or as
              needed to provide the App&apos;s services. Specific retention
              periods by category:
            </p>
            <ul className="list-disc list-inside space-y-1 ml-2 mb-3">
              <li>
                <strong className="text-white">Account information:</strong>{" "}
                Retained until you delete your account.
              </li>
              <li>
                <strong className="text-white">
                  Nutrition, fasting, and workout data:
                </strong>{" "}
                Retained until you delete your account or delete individual
                entries.
              </li>
              <li>
                <strong className="text-white">Food photos:</strong> Retained
                only if saved to your food log; deleted when you remove the
                entry or delete your account. Photos sent for AI analysis are
                not retained after processing.
              </li>
              <li>
                <strong className="text-white">Voice input:</strong> Processed
                in real-time via speech-to-text; audio is not stored.
              </li>
              <li>
                <strong className="text-white">Community posts:</strong>{" "}
                Retained until you delete the post or delete your account.
              </li>
              <li>
                <strong className="text-white">Analytics data:</strong>{" "}
                Anonymous, aggregated analytics may be retained indefinitely.
              </li>
            </ul>
            <p>
              If you delete your account, we will delete your personal data
              within 30 days, except where we are required to retain it for
              legal or compliance purposes.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              8. Your Rights
            </h2>
            <p className="mb-2">
              Regardless of where you live, you have the right to:
            </p>
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
                <strong className="text-white">Withdraw consent</strong> — where
                processing is based on consent (e.g., photo analysis, ad
                tracking), you may withdraw consent at any time. Withdrawal
                does not affect the lawfulness of processing performed before
                withdrawal.
              </li>
              <li>
                <strong className="text-white">Opt out</strong> of
                notifications at any time through your device settings.
              </li>
            </ul>
            <p className="mt-3">
              To exercise any of these rights, use the in-App settings or
              contact us at{" "}
              <a
                href="mailto:privacy@macromaxxing.app"
                className="text-brand-purple hover:underline"
              >
                privacy@macromaxxing.app
              </a>
              . We will respond within 30 days (or sooner if required by
              applicable law). You may also designate an authorized agent to
              submit a request on your behalf, subject to identity verification.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              9. Data Security
            </h2>
            <p>
              We use industry-standard security measures to protect your data,
              including encryption in transit (TLS 1.2+) and at rest.
              Authentication is handled through Firebase Authentication with
              secure token management. However, no method of electronic
              transmission or storage is 100% secure, and we cannot guarantee
              absolute security.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              10. Data Breach Notification
            </h2>
            <p>
              In the event of a data breach that poses a risk to your rights and
              freedoms, we will notify affected users via email and/or in-App
              notification without undue delay, and no later than required by
              applicable law (72 hours under GDPR, or as required by state law).
              We will also notify relevant supervisory authorities as required.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              11. Advertising, Tracking &amp; Do Not Track
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
            <ul className="list-disc list-inside space-y-1 ml-2 mb-3">
              <li>
                <strong className="text-white">iOS:</strong> Settings &gt;
                Privacy &amp; Security &gt; Tracking, and disable &ldquo;Allow
                Apps to Request to Track.&rdquo; You may also decline the App
                Tracking Transparency prompt when first launching the App.
              </li>
              <li>
                <strong className="text-white">Web:</strong> Manage cookie
                preferences via your browser settings or our cookie banner (if
                displayed).
              </li>
            </ul>
            <p>
              <strong className="text-white">Do Not Track Signals:</strong>{" "}
              Some browsers transmit &ldquo;Do Not Track&rdquo; (DNT) signals.
              There is currently no industry standard for how to respond to DNT
              signals. Our Website does not currently respond to DNT signals,
              but you can manage tracking preferences through the controls
              described above.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              12. Children&apos;s Privacy
            </h2>
            <p>
              The App is not intended for children under 13 (or under 16 in
              jurisdictions where GDPR applies, unless the member state has
              set a lower age of consent). We do not knowingly collect personal
              information from children under these age thresholds. If we learn
              that we have collected data from a child below the applicable age
              threshold, we will delete it promptly. If you believe a child has
              provided us with personal information, please contact us at{" "}
              <a
                href="mailto:privacy@macromaxxing.app"
                className="text-brand-purple hover:underline"
              >
                privacy@macromaxxing.app
              </a>
              .
            </p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              13. International Data Transfers
            </h2>
            <p className="mb-3">
              Your data may be processed and stored on servers located in the
              United States and other countries where our service providers
              operate (including Google and Anthropic).
            </p>
            <p className="mb-3">
              For transfers of personal data from the European Economic Area
              (EEA), United Kingdom, or Switzerland to the United States, we
              rely on (a) the EU-U.S. Data Privacy Framework and UK Extension
              (where our processors are certified), (b) Standard Contractual
              Clauses approved by the European Commission, or (c) other
              lawful transfer mechanisms as applicable. We take steps to ensure
              that your data receives an adequate level of protection wherever
              it is processed, consistent with the requirements of applicable
              data protection laws.
            </p>
            <p>
              By using the App, you acknowledge that your data will be
              transferred to and processed in the United States and other
              jurisdictions that may have different data-protection laws than
              your country of residence.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              14. Your Privacy Rights Under Applicable Law
            </h2>
            <p className="mb-3">
              Depending on where you live, you may have additional rights under
              local privacy laws. Below is a summary of key jurisdictions. If
              your jurisdiction is not listed, contact us at{" "}
              <a
                href="mailto:privacy@macromaxxing.app"
                className="text-brand-purple hover:underline"
              >
                privacy@macromaxxing.app
              </a>{" "}
              to learn about your specific rights.
            </p>

            <h3 className="text-base font-semibold text-white mt-4 mb-2">
              California Residents (CCPA/CPRA)
            </h3>
            <p className="mb-2">
              Under the California Consumer Privacy Act, as amended by the
              California Privacy Rights Act (collectively, &ldquo;CCPA&rdquo;):
            </p>
            <ul className="list-disc list-inside space-y-1 ml-2 mb-3">
              <li>
                <strong className="text-white">Right to Know:</strong> You may
                request details about the categories and specific pieces of
                personal information we have collected, used, disclosed, and
                sold (if any) in the past 12 months.
              </li>
              <li>
                <strong className="text-white">Right to Delete:</strong> You
                may request deletion of your personal information, subject to
                certain legal exceptions.
              </li>
              <li>
                <strong className="text-white">Right to Correct:</strong> You
                may request correction of inaccurate personal information.
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
                <strong className="text-white">
                  Right to Limit Use of Sensitive Personal Information:
                </strong>{" "}
                Nutrition data, body metrics, and health-related information
                may constitute sensitive personal information under the CPRA. We
                use this data only to provide the App&apos;s core nutrition
                tracking services — not for advertising, profiling, or any
                purpose beyond what is necessary to deliver the service.
              </li>
              <li>
                <strong className="text-white">Non-Discrimination:</strong> We
                will not discriminate against you for exercising your CCPA
                rights.
              </li>
              <li>
                <strong className="text-white">Authorized Agent:</strong> You
                may designate an authorized agent to submit requests on your
                behalf. We may require proof of authorization and identity
                verification.
              </li>
            </ul>

            <h3 className="text-base font-semibold text-white mt-4 mb-2">
              Washington Residents (My Health My Data Act)
            </h3>
            <ul className="list-disc list-inside space-y-1 ml-2 mb-3">
              <li>
                Nutrition data, fasting data, body metrics, and workout data
                may constitute &ldquo;consumer health data&rdquo; under the
                Washington My Health My Data Act.
              </li>
              <li>
                We collect this health data with your consent to provide the
                App&apos;s nutrition tracking functionality. We do not sell
                consumer health data.
              </li>
              <li>
                You have the right to access, delete, and withdraw consent for
                the collection of your consumer health data.
              </li>
              <li>
                Consumer health data is shared with Anthropic (for AI food
                analysis) and Google Firebase (for data storage) only as
                necessary to provide the service.
              </li>
            </ul>

            <h3 className="text-base font-semibold text-white mt-4 mb-2">
              Virginia, Colorado, Connecticut, Texas, Oregon &amp; Other U.S. States
            </h3>
            <p className="mb-2">
              If you reside in a state with a comprehensive privacy law (such as
              the Virginia Consumer Data Protection Act, Colorado Privacy Act,
              Connecticut Data Privacy Act, Texas Data Privacy and Security Act,
              or Oregon Consumer Privacy Act), you generally have the right to:
            </p>
            <ul className="list-disc list-inside space-y-1 ml-2 mb-3">
              <li>Access, correct, and delete your personal data.</li>
              <li>Obtain a portable copy of your data.</li>
              <li>
                Opt out of targeted advertising, the sale of personal data
                (we do not sell your data), and profiling in furtherance of
                decisions that produce legal or similarly significant effects.
              </li>
              <li>
                Appeal a denial of your privacy request by contacting us at{" "}
                <a
                  href="mailto:privacy@macromaxxing.app"
                  className="text-brand-purple hover:underline"
                >
                  privacy@macromaxxing.app
                </a>
                .
              </li>
            </ul>

            <h3 className="text-base font-semibold text-white mt-4 mb-2">
              EU/UK Residents (GDPR)
            </h3>
            <ul className="list-disc list-inside space-y-1 ml-2 mb-3">
              <li>
                <strong className="text-white">Legal Basis:</strong> We process
                your data based on: (a) your consent (e.g., photo analysis, ad
                tracking — which you may withdraw at any time), (b) contractual
                necessity (e.g., providing App features you requested), and
                (c) legitimate interests (e.g., improving the App, preventing
                fraud, and ensuring security), where those interests are not
                overridden by your rights.
              </li>
              <li>
                <strong className="text-white">Data Portability:</strong> You
                may request a copy of your data in a structured,
                machine-readable format (JSON export is available in-App).
              </li>
              <li>
                <strong className="text-white">Right to Restriction:</strong>{" "}
                You may request that we restrict processing of your data in
                certain circumstances (e.g., while we verify a correction
                request).
              </li>
              <li>
                <strong className="text-white">Right to Object:</strong> You
                may object to processing based on legitimate interests.
              </li>
              <li>
                <strong className="text-white">
                  Automated Decision-Making:
                </strong>{" "}
                The App uses AI to estimate nutritional content from food photos
                and voice descriptions. This does not constitute automated
                decision-making with legal or similarly significant effects
                under Article 22 of the GDPR, as you can review, edit, and
                override all AI outputs.
              </li>
              <li>
                <strong className="text-white">Withdrawal of Consent:</strong>{" "}
                Where processing is based on your consent, you have the right to
                withdraw consent at any time without affecting the lawfulness
                of processing performed before withdrawal.
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
              15. Changes to This Policy
            </h2>
            <p>
              We may update this Privacy Policy from time to time. We will
              notify you of material changes by posting the updated policy in the
              App or on our Website with a revised effective date. Where
              required by law, we will obtain your consent before making
              material changes to how we process your data.
            </p>
          </div>

          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              16. Contact Us
            </h2>
            <p>
              If you have questions about this Privacy Policy, want to
              exercise your data rights, or wish to file a complaint, contact
              us at:
            </p>
            <p className="mt-2">
              GRND Labs LLC
              <br />
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
