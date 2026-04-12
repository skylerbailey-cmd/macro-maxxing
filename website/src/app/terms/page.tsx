import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Terms of Service & End User License Agreement",
  description:
    "Macro Maxxing terms of service and end user license agreement (EULA). Read the terms governing your use of the Macro Maxxing app and website.",
};

export default function TermsPage() {
  return (
    <section className="bg-brand-bg text-gray-300 py-20">
      <div className="max-w-3xl mx-auto px-4 sm:px-6">
        <h1 className="text-4xl font-bold text-white mb-2">
          Terms of Service &amp; End User License Agreement
        </h1>
        <p className="text-gray-500 mb-12">Effective Date: April 12, 2026</p>

        <div className="space-y-10 text-sm leading-relaxed">
          {/* 1 */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              1. Agreement to Terms
            </h2>
            <p className="mb-3">
              This End User License Agreement (&ldquo;Agreement&rdquo; or
              &ldquo;EULA&rdquo;) is a legally binding contract between you
              (&ldquo;User&rdquo; or &ldquo;you&rdquo;) and GRND Labs LLC, a
              Florida limited liability company doing business as Macro Maxxing
              (&ldquo;Company,&rdquo; &ldquo;we,&rdquo; &ldquo;our,&rdquo; or
              &ldquo;us&rdquo;).
            </p>
            <p className="mb-3">
              This Agreement governs your access to and use of the Macro Maxxing
              mobile application (the &ldquo;App&rdquo;), the website located at
              macromaxxing.app (the &ldquo;Website&rdquo;), and all related
              services, content, features, and functionality (collectively, the
              &ldquo;Service&rdquo;).
            </p>
            <p>
              By downloading, installing, accessing, or using the Service, you
              acknowledge that you have read, understood, and agree to be bound
              by this Agreement and our{" "}
              <a
                href="/privacy-policy"
                className="text-brand-purple hover:underline"
              >
                Privacy Policy
              </a>
              , which is incorporated herein by reference. If you do not agree
              to these terms, do not download, install, or use the Service.
            </p>
          </div>

          {/* 2 */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              2. License Grant
            </h2>
            <p className="mb-3">
              Subject to your compliance with this Agreement, the Company grants
              you a limited, non-exclusive, non-transferable, non-sublicensable,
              revocable license to download, install, and use the App on a
              single Apple iOS device that you own or control, solely for your
              personal, non-commercial purposes.
            </p>
            <p>
              This license does not grant you any ownership interest in the
              Service. All rights not expressly granted to you are reserved by
              the Company.
            </p>
          </div>

          {/* 3 */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              3. License Restrictions
            </h2>
            <p className="mb-3">You agree that you will not:</p>
            <ul className="list-disc list-inside space-y-1 ml-2">
              <li>
                Copy, modify, adapt, translate, reverse engineer, decompile,
                disassemble, or create derivative works based on the Service or
                any portion thereof.
              </li>
              <li>
                Remove, alter, or obscure any copyright, trademark, or other
                proprietary notices contained in or on the Service.
              </li>
              <li>
                Use the Service for any commercial purpose, or for the benefit
                of any third party, without the prior written consent of the
                Company.
              </li>
              <li>
                Use the Service to transmit any viruses, malware, or other
                harmful code, or to interfere with the operation of the Service
                or any other user&apos;s enjoyment thereof.
              </li>
              <li>
                Use any automated means (including bots, scrapers, or crawlers)
                to access or interact with the Service, except as expressly
                permitted.
              </li>
              <li>
                Attempt to gain unauthorized access to any portion of the
                Service, other accounts, computer systems, or networks connected
                to the Service.
              </li>
              <li>
                Sublicense, sell, resell, transfer, assign, distribute, or
                otherwise make the Service available to any third party.
              </li>
              <li>
                Use the Service in violation of any applicable law, regulation,
                or this Agreement.
              </li>
            </ul>
          </div>

          {/* 4 */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              4. Account Registration &amp; Security
            </h2>
            <p className="mb-3">
              To use certain features of the Service, you must create an account
              using a valid email address or third-party authentication provider
              (e.g., Google Sign-In, Apple Sign-In). You agree to:
            </p>
            <ul className="list-disc list-inside space-y-1 ml-2 mb-3">
              <li>
                Provide accurate, current, and complete information during
                registration.
              </li>
              <li>
                Maintain and promptly update your account information to keep it
                accurate and current.
              </li>
              <li>
                Maintain the security and confidentiality of your login
                credentials.
              </li>
              <li>
                Accept responsibility for all activities that occur under your
                account.
              </li>
              <li>
                Notify us immediately at{" "}
                <a
                  href="mailto:support@grnd-lab.com"
                  className="text-brand-purple hover:underline"
                >
                  support@grnd-lab.com
                </a>{" "}
                of any unauthorized use of your account.
              </li>
            </ul>
            <p>
              You must be at least 13 years of age (or 16 in jurisdictions
              where GDPR applies) to create an account and use the Service.
            </p>
          </div>

          {/* 5 */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              5. Subscriptions, In-App Purchases &amp; Billing
            </h2>
            <p className="mb-3">
              The App is free to download and includes core features such as
              manual macro tracking, intermittent fasting timer, workout
              tracking with automatic macro adjustments, daily streaks,
              leaderboards, Aura&nbsp;XP, and the social community feed. The
              App also offers optional paid features as described below. All
              purchases are processed through the Apple App Store and are
              subject to Apple&apos;s terms and conditions.
            </p>

            <h3 className="text-base font-semibold text-white mt-4 mb-2">
              5.1 AI Features Subscription (&ldquo;AI Pro&rdquo;)
            </h3>
            <p className="mb-3">
              The App offers an optional auto-renewable monthly subscription
              that unlocks the following AI-powered features:
            </p>
            <ul className="list-disc list-inside space-y-1 ml-2 mb-3">
              <li>
                <strong className="text-white">AI Food Photo Scanner:</strong>{" "}
                Snap a photo of your meal and Claude AI identifies every item
                and estimates calories, protein, carbs, and fat.
              </li>
              <li>
                <strong className="text-white">AI Voice Meal Logging:</strong>{" "}
                Describe your meal by voice and AI generates accurate macro
                breakdowns from your description.
              </li>
              <li>
                <strong className="text-white">AI Meal Planner:</strong>{" "}
                AI analyzes your remaining macro gaps and suggests specific
                meals with portions to help you hit your targets.
              </li>
              <li>
                <strong className="text-white">AI Nutrition Coach:</strong>{" "}
                A personalized daily debrief that reviews your meals, macros,
                workouts, and timing, with actionable recommendations.
              </li>
            </ul>
            <p className="mb-3">
              The AI Features subscription is billed at $9.99/month (USD).
              Your Apple&nbsp;ID account will be charged upon confirmation of
              purchase.
            </p>

            <h3 className="text-base font-semibold text-white mt-4 mb-2">
              5.2 Streak In-App Purchases
            </h3>
            <p className="mb-3">
              The App offers optional one-time (consumable) purchases related
              to the streak system:
            </p>
            <ul className="list-disc list-inside space-y-1 ml-2 mb-3">
              <li>
                <strong className="text-white">Streak Extension ($4.99):</strong>{" "}
                Extends your macro logging streak by 7&nbsp;days without
                requiring daily logging during that period.
              </li>
              <li>
                <strong className="text-white">Streak Shield ($0.99):</strong>{" "}
                Restores a broken streak one time.
              </li>
              <li>
                <strong className="text-white">Cheat Day ($0.99):</strong>{" "}
                Allows you to skip logging for one day without breaking your
                current streak.
              </li>
            </ul>

            <h3 className="text-base font-semibold text-white mt-4 mb-2">
              5.3 Billing &amp; Renewal
            </h3>
            <ul className="list-disc list-inside space-y-1 ml-2 mb-3">
              <li>
                <strong className="text-white">Auto-Renewal:</strong>{" "}
                The AI Features subscription automatically renews unless
                canceled at least 24&nbsp;hours before the end of the current
                billing period. You can manage and cancel subscriptions in your
                Apple&nbsp;ID account settings.
              </li>
              <li>
                <strong className="text-white">Refunds:</strong> All purchases
                are handled by Apple. Refund requests must be submitted through
                Apple&apos;s refund process at{" "}
                <a
                  href="https://reportaproblem.apple.com"
                  className="text-brand-purple hover:underline"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  reportaproblem.apple.com
                </a>
                . The Company does not process refunds directly.
              </li>
              <li>
                <strong className="text-white">Price Changes:</strong> We
                reserve the right to change subscription pricing. Existing
                subscribers will be notified of price changes in advance and may
                cancel before the new price takes effect.
              </li>
              <li>
                <strong className="text-white">Free Trial:</strong> If offered,
                free trial periods convert to paid subscriptions automatically
                unless canceled before the trial ends.
              </li>
              <li>
                <strong className="text-white">Consumable Purchases:</strong>{" "}
                One-time streak purchases are non-refundable once used. Unused
                consumables are subject to Apple&apos;s standard refund policy.
              </li>
            </ul>
          </div>

          {/* 6 */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              6. AI-Generated Content &amp; Disclaimers
            </h2>
            <p className="mb-3">
              The Service uses artificial intelligence (Anthropic&apos;s Claude
              AI) to analyze food photos, process voice descriptions, estimate
              nutritional content, suggest meals, and provide nutrition
              coaching. You acknowledge and agree that:
            </p>
            <ul className="list-disc list-inside space-y-1 ml-2 mb-3">
              <li>
                <strong className="text-white">Estimates Only:</strong>{" "}
                AI-generated nutritional estimates (calories, protein, carbs,
                fat) are approximations and may not be perfectly accurate. They
                should not be relied upon for medical, clinical, or therapeutic
                nutrition decisions.
              </li>
              <li>
                <strong className="text-white">Not Medical Advice:</strong> The
                AI meal planner, AI nutrition coach, and all other AI-generated
                content are for informational and convenience purposes only.
                They do not constitute medical advice, dietary counseling, or
                professional nutritional guidance.
              </li>
              <li>
                <strong className="text-white">User Responsibility:</strong>{" "}
                You are solely responsible for reviewing, editing, and verifying
                all AI-generated content before relying on it. You can modify
                any AI output within the App.
              </li>
              <li>
                <strong className="text-white">Allergies &amp; Conditions:</strong>{" "}
                If you have food allergies, medical conditions, or dietary
                restrictions beyond the settings available in the App, you
                should consult a qualified healthcare professional before
                following any AI-generated meal suggestions.
              </li>
              <li>
                <strong className="text-white">No Guarantee:</strong> We do not
                guarantee the accuracy, completeness, or reliability of any
                AI-generated content, and we disclaim all liability arising from
                your reliance on such content.
              </li>
            </ul>
          </div>

          {/* 7 */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              7. User Content &amp; Community Guidelines
            </h2>
            <p className="mb-3">
              The Service allows you to post content to a social community feed,
              including meal photos, text posts, and comments (&ldquo;User
              Content&rdquo;). By posting User Content, you:
            </p>
            <ul className="list-disc list-inside space-y-1 ml-2 mb-3">
              <li>
                Grant the Company a worldwide, non-exclusive, royalty-free,
                sublicensable, and transferable license to use, reproduce,
                distribute, display, and create derivative works of your User
                Content in connection with operating and promoting the Service.
              </li>
              <li>
                Represent and warrant that you own or have the necessary rights
                to post such content and that it does not violate any third
                party&apos;s rights.
              </li>
              <li>
                Agree not to post content that is illegal, harmful, threatening,
                abusive, harassing, defamatory, vulgar, obscene, hateful,
                discriminatory, or otherwise objectionable.
              </li>
              <li>
                Agree not to post spam, advertisements, or solicitations.
              </li>
              <li>
                Agree not to impersonate any person or entity or misrepresent
                your affiliation with any person or entity.
              </li>
            </ul>
            <p>
              We reserve the right to remove any User Content at our sole
              discretion, with or without notice, for any reason, including
              content that we determine violates this Agreement or is otherwise
              objectionable. Repeated violations may result in account
              suspension or termination.
            </p>
          </div>

          {/* 8 */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              8. Intellectual Property
            </h2>
            <p className="mb-3">
              The Service, including all software, code, design, text, graphics,
              logos, icons, images, audio, video, data compilations, and the
              selection and arrangement thereof, is the exclusive property of
              GRND Labs LLC or its licensors and is protected by United States
              and international copyright, trademark, patent, trade secret, and
              other intellectual property laws.
            </p>
            <p className="mb-3">
              &ldquo;Macro Maxxing,&rdquo; the Macro Maxxing logo, &ldquo;Aura
              XP,&rdquo; &ldquo;Mog Board,&rdquo; and all related names,
              logos, product and service names, designs, and slogans are
              trademarks of GRND Labs LLC. You may not use such marks without
              our prior written permission.
            </p>
            <p>
              Your User Content remains yours. Except for the license granted
              above, nothing in this Agreement transfers ownership of your User
              Content to the Company.
            </p>
          </div>

          {/* 9 */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              9. Third-Party Services
            </h2>
            <p className="mb-3">
              The Service integrates with or relies upon third-party services,
              including but not limited to:
            </p>
            <ul className="list-disc list-inside space-y-1 ml-2 mb-3">
              <li>
                <strong className="text-white">
                  Anthropic (Claude AI):
                </strong>{" "}
                For food photo analysis, voice input processing, meal planning,
                and nutrition coaching.
              </li>
              <li>
                <strong className="text-white">Firebase (Google):</strong> For
                authentication, data storage, analytics, and crash reporting.
              </li>
              <li>
                <strong className="text-white">Google AdMob:</strong> For
                in-app advertising.
              </li>
              <li>
                <strong className="text-white">Apple App Store:</strong> For
                app distribution, in-app purchases, and subscriptions.
              </li>
            </ul>
            <p>
              Your use of these third-party services is subject to their
              respective terms of service and privacy policies. The Company is
              not responsible for the availability, accuracy, or content of
              third-party services, and your use of such services is at your
              own risk.
            </p>
          </div>

          {/* 10 */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              10. Disclaimer of Warranties
            </h2>
            <p className="mb-3 uppercase text-xs text-gray-400">
              THE SERVICE IS PROVIDED &ldquo;AS IS&rdquo; AND &ldquo;AS
              AVAILABLE&rdquo; WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS
              OR IMPLIED, INCLUDING BUT NOT LIMITED TO IMPLIED WARRANTIES OF
              MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
              NON-INFRINGEMENT, AND ANY WARRANTIES ARISING OUT OF COURSE OF
              DEALING OR USAGE OF TRADE.
            </p>
            <p className="mb-3 uppercase text-xs text-gray-400">
              THE COMPANY DOES NOT WARRANT THAT THE SERVICE WILL BE
              UNINTERRUPTED, ERROR-FREE, SECURE, OR FREE OF VIRUSES OR OTHER
              HARMFUL COMPONENTS. THE COMPANY DOES NOT WARRANT THE ACCURACY,
              RELIABILITY, OR COMPLETENESS OF ANY NUTRITIONAL ESTIMATES, AI
              OUTPUTS, OR OTHER INFORMATION PROVIDED THROUGH THE SERVICE.
            </p>
            <p className="uppercase text-xs text-gray-400">
              YOU ACKNOWLEDGE THAT THE SERVICE IS NOT INTENDED TO BE A
              SUBSTITUTE FOR PROFESSIONAL MEDICAL ADVICE, DIAGNOSIS, OR
              TREATMENT. ALWAYS SEEK THE ADVICE OF A QUALIFIED HEALTHCARE
              PROVIDER WITH ANY QUESTIONS REGARDING A MEDICAL CONDITION OR
              DIETARY NEEDS.
            </p>
          </div>

          {/* 11 */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              11. Limitation of Liability
            </h2>
            <p className="mb-3 uppercase text-xs text-gray-400">
              TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW, IN NO EVENT
              SHALL GRND LABS LLC, ITS OFFICERS, DIRECTORS, EMPLOYEES, AGENTS,
              OR AFFILIATES BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL,
              CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO
              LOSS OF PROFITS, DATA, USE, GOODWILL, OR OTHER INTANGIBLE
              LOSSES, RESULTING FROM:
            </p>
            <ul className="list-disc list-inside space-y-1 ml-2 mb-3 uppercase text-xs text-gray-400">
              <li>
                YOUR ACCESS TO, USE OF, OR INABILITY TO ACCESS OR USE THE
                SERVICE;
              </li>
              <li>
                ANY CONDUCT OR CONTENT OF ANY THIRD PARTY ON THE SERVICE,
                INCLUDING OTHER USERS;
              </li>
              <li>
                ANY AI-GENERATED CONTENT, INCLUDING NUTRITIONAL ESTIMATES, MEAL
                SUGGESTIONS, OR COACHING ADVICE;
              </li>
              <li>
                UNAUTHORIZED ACCESS, USE, OR ALTERATION OF YOUR TRANSMISSIONS
                OR CONTENT;
              </li>
              <li>
                ANY DIETARY, HEALTH, OR FITNESS OUTCOMES RESULTING FROM YOUR
                USE OF THE SERVICE.
              </li>
            </ul>
            <p className="uppercase text-xs text-gray-400">
              IN NO EVENT SHALL THE COMPANY&apos;S TOTAL LIABILITY TO YOU FOR
              ALL CLAIMS EXCEED THE GREATER OF (A) THE AMOUNT YOU HAVE PAID TO
              THE COMPANY IN THE TWELVE (12) MONTHS PRECEDING THE CLAIM, OR
              (B) ONE HUNDRED U.S. DOLLARS ($100.00).
            </p>
          </div>

          {/* 12 */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              12. Indemnification
            </h2>
            <p>
              You agree to indemnify, defend, and hold harmless GRND Labs LLC,
              its officers, directors, employees, agents, and affiliates from
              and against any and all claims, damages, losses, liabilities,
              costs, and expenses (including reasonable attorneys&apos; fees)
              arising out of or relating to: (a) your use of or access to the
              Service; (b) your violation of this Agreement; (c) your User
              Content; (d) your violation of any third party&apos;s rights,
              including intellectual property rights; or (e) any claim that your
              User Content caused damage to a third party.
            </p>
          </div>

          {/* 13 */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              13. Binding Arbitration &amp; Class Action Waiver
            </h2>
            <p className="mb-3">
              <strong className="text-white">
                PLEASE READ THIS SECTION CAREFULLY. IT AFFECTS YOUR LEGAL
                RIGHTS, INCLUDING YOUR RIGHT TO FILE A LAWSUIT IN COURT.
              </strong>
            </p>
            <p className="mb-3">
              You and the Company agree that any dispute, claim, or controversy
              arising out of or relating to this Agreement or the Service
              (&ldquo;Dispute&rdquo;) will be resolved through binding
              individual arbitration rather than in court, except that either
              party may bring claims in small claims court if they qualify.
            </p>
            <p className="mb-3">
              <strong className="text-white">Arbitration Rules:</strong>{" "}
              Arbitration will be administered by the American Arbitration
              Association (&ldquo;AAA&rdquo;) under its Consumer Arbitration
              Rules. The arbitration will be conducted in the State of Florida
              or at a location mutually agreed upon. The arbitrator&apos;s
              decision will be final and binding.
            </p>
            <p className="mb-3">
              <strong className="text-white">Class Action Waiver:</strong> YOU
              AND THE COMPANY AGREE THAT EACH MAY BRING CLAIMS AGAINST THE
              OTHER ONLY IN YOUR OR ITS INDIVIDUAL CAPACITY AND NOT AS A
              PLAINTIFF OR CLASS MEMBER IN ANY PURPORTED CLASS, CONSOLIDATED,
              OR REPRESENTATIVE ACTION.
            </p>
            <p>
              <strong className="text-white">Opt-Out:</strong> You may opt out
              of this arbitration provision by sending written notice to{" "}
              <a
                href="mailto:support@grnd-lab.com"
                className="text-brand-purple hover:underline"
              >
                support@grnd-lab.com
              </a>{" "}
              within 30 days of first accepting this Agreement. If you opt out,
              the Governing Law and Jurisdiction provisions below will apply.
            </p>
          </div>

          {/* 14 */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              14. Termination
            </h2>
            <p className="mb-3">
              We may suspend or terminate your access to the Service at any
              time, with or without cause, and with or without notice.
              Grounds for termination include, but are not limited to:
              violation of this Agreement, abusive or harmful behavior toward
              other users, fraudulent activity, or extended periods of
              inactivity.
            </p>
            <p className="mb-3">
              You may terminate your account at any time by using the
              &ldquo;Delete Account&rdquo; feature in the App settings or by
              contacting us at{" "}
              <a
                href="mailto:support@grnd-lab.com"
                className="text-brand-purple hover:underline"
              >
                support@grnd-lab.com
              </a>
              .
            </p>
            <p>
              Upon termination, your license to use the Service will immediately
              cease. Sections 6, 8, 10, 11, 12, 13, 15, and 16 of this
              Agreement shall survive termination.
            </p>
          </div>

          {/* 15 */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              15. Governing Law &amp; Jurisdiction
            </h2>
            <p>
              This Agreement shall be governed by and construed in accordance
              with the laws of the State of Florida, United States, without
              regard to its conflict of law provisions. To the extent that
              arbitration does not apply, you agree to submit to the exclusive
              jurisdiction of the state and federal courts located in the State
              of Florida for any legal proceedings arising out of or relating
              to this Agreement.
            </p>
          </div>

          {/* 16 */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              16. General Provisions
            </h2>
            <ul className="list-disc list-inside space-y-2 ml-2">
              <li>
                <strong className="text-white">Entire Agreement:</strong> This
                Agreement, together with the Privacy Policy, constitutes the
                entire agreement between you and the Company regarding the
                Service and supersedes all prior agreements and understandings.
              </li>
              <li>
                <strong className="text-white">Severability:</strong> If any
                provision of this Agreement is found to be unenforceable or
                invalid, that provision shall be limited or eliminated to the
                minimum extent necessary, and the remaining provisions shall
                remain in full force and effect.
              </li>
              <li>
                <strong className="text-white">Waiver:</strong> The failure of
                the Company to enforce any right or provision of this Agreement
                shall not constitute a waiver of such right or provision.
              </li>
              <li>
                <strong className="text-white">Assignment:</strong> You may not
                assign or transfer this Agreement without the Company&apos;s
                prior written consent. The Company may assign this Agreement
                without restriction.
              </li>
              <li>
                <strong className="text-white">Force Majeure:</strong> The
                Company shall not be liable for any failure or delay in
                performance due to causes beyond its reasonable control,
                including but not limited to natural disasters, war, terrorism,
                pandemics, government actions, or internet or infrastructure
                failures.
              </li>
              <li>
                <strong className="text-white">Notices:</strong> We may provide
                notices to you via the App, email, or posting on the Website.
                You may provide notices to us at{" "}
                <a
                  href="mailto:support@grnd-lab.com"
                  className="text-brand-purple hover:underline"
                >
                  support@grnd-lab.com
                </a>
                .
              </li>
            </ul>
          </div>

          {/* 17 */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              17. Apple-Specific Terms
            </h2>
            <p className="mb-3">
              If you downloaded the App from the Apple App Store, the following
              additional terms apply:
            </p>
            <ul className="list-disc list-inside space-y-1 ml-2">
              <li>
                This Agreement is between you and GRND Labs LLC, not Apple Inc.
                Apple has no obligation to furnish any maintenance or support
                services for the App.
              </li>
              <li>
                In the event of any failure of the App to conform to any
                applicable warranty, you may notify Apple and Apple will refund
                the purchase price (if any). To the maximum extent permitted by
                law, Apple has no other warranty obligation with respect to the
                App.
              </li>
              <li>
                Apple is not responsible for addressing any claims by you or a
                third party relating to the App, including product liability
                claims, regulatory compliance, or intellectual property
                infringement claims.
              </li>
              <li>
                Apple and its subsidiaries are third-party beneficiaries of
                this Agreement. Upon your acceptance, Apple will have the right
                to enforce this Agreement against you as a third-party
                beneficiary.
              </li>
              <li>
                You represent and warrant that you are not located in a country
                subject to a U.S. Government embargo or designated as a
                &ldquo;terrorist supporting&rdquo; country, and that you are
                not listed on any U.S. Government list of prohibited or
                restricted parties.
              </li>
            </ul>
          </div>

          {/* 18 */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              18. Changes to This Agreement
            </h2>
            <p>
              We reserve the right to modify this Agreement at any time. We will
              notify you of material changes by posting the updated Agreement on
              the Website and/or through the App with a revised effective date.
              Your continued use of the Service after such changes constitutes
              your acceptance of the updated Agreement. If you do not agree to
              the updated terms, you must stop using the Service and delete your
              account.
            </p>
          </div>

          {/* 19 */}
          <div>
            <h2 className="text-xl font-semibold text-white mb-3">
              19. Contact Information
            </h2>
            <p>
              If you have any questions about this Agreement, please contact us:
            </p>
            <p className="mt-3">
              GRND Labs LLC
              <br />
              <a
                href="mailto:support@grnd-lab.com"
                className="text-brand-purple hover:underline"
              >
                support@grnd-lab.com
              </a>
            </p>
          </div>
        </div>
      </div>
    </section>
  );
}
