"use client";

import Link from "next/link";
import { useEffect, useState } from "react";
import { useCookieConsent } from "./CookieConsentProvider";

export function CookieBanner() {
  const {
    ready,
    hasChosen,
    preferencesOpen,
    openPreferences,
    closePreferences,
    acceptAll,
    rejectAll,
    savePreferences,
    consent,
  } = useCookieConsent();

  // Draft state for the modal toggles — kept separate from committed consent
  // so users can change sliders without side-effects until they hit Save.
  const [draftPreferences, setDraftPreferences] = useState(consent.preferences);
  const [draftAnalytics, setDraftAnalytics] = useState(consent.analytics);
  const [draftMarketing, setDraftMarketing] = useState(consent.marketing);

  // Seed drafts from current consent whenever the modal opens.
  useEffect(() => {
    if (preferencesOpen) {
      setDraftPreferences(consent.preferences);
      setDraftAnalytics(consent.analytics);
      setDraftMarketing(consent.marketing);
    }
  }, [preferencesOpen, consent]);

  // Don't render anything until the client has read localStorage — prevents
  // hydration mismatch and the banner flashing for already-consented users.
  if (!ready) return null;

  const showBanner = !hasChosen && !preferencesOpen;

  return (
    <>
      {showBanner && (
        <Banner
          onAccept={acceptAll}
          onReject={rejectAll}
          onCustomize={openPreferences}
        />
      )}
      {preferencesOpen && (
        <PreferencesModal
          draftPreferences={draftPreferences}
          draftAnalytics={draftAnalytics}
          draftMarketing={draftMarketing}
          setDraftPreferences={setDraftPreferences}
          setDraftAnalytics={setDraftAnalytics}
          setDraftMarketing={setDraftMarketing}
          onClose={closePreferences}
          onAcceptAll={acceptAll}
          onRejectAll={rejectAll}
          onSave={() =>
            savePreferences({
              preferences: draftPreferences,
              analytics: draftAnalytics,
              marketing: draftMarketing,
            })
          }
        />
      )}
    </>
  );
}

function Banner({
  onAccept,
  onReject,
  onCustomize,
}: {
  onAccept: () => void;
  onReject: () => void;
  onCustomize: () => void;
}) {
  return (
    <div
      role="dialog"
      aria-live="polite"
      aria-label="Cookie consent"
      className="fixed bottom-0 left-0 right-0 z-[100] p-4 sm:p-6"
    >
      <div className="max-w-6xl mx-auto bg-brand-card border border-white/10 rounded-2xl shadow-2xl p-6 sm:p-8">
        <div className="grid gap-6 lg:grid-cols-[1fr_auto] lg:items-center">
          <div>
            <h2 className="text-lg font-bold text-white mb-2">
              We respect your privacy
            </h2>
            <p className="text-sm text-gray-300 leading-relaxed">
              We use cookies and similar technologies to make this site work
              and — if you agree — to measure usage and improve the experience.
              You can accept all, reject all non-essential cookies, or
              customize your choices by category. You can change your mind at
              any time via &ldquo;Cookie settings&rdquo; in the footer.{" "}
              <Link
                href="/privacy-policy"
                className="text-brand-purple underline hover:text-white"
              >
                Learn more in our Privacy Policy
              </Link>
              .
            </p>
          </div>
          <div className="flex flex-col sm:flex-row lg:flex-col gap-3 lg:min-w-[200px]">
            <button
              type="button"
              onClick={onAccept}
              className="px-5 py-2.5 rounded-full text-sm font-semibold bg-brand-purple hover:bg-brand-purple/80 text-white transition"
            >
              Accept all
            </button>
            <button
              type="button"
              onClick={onReject}
              className="px-5 py-2.5 rounded-full text-sm font-semibold bg-brand-purple hover:bg-brand-purple/80 text-white transition"
            >
              Reject all
            </button>
            <button
              type="button"
              onClick={onCustomize}
              className="px-5 py-2.5 rounded-full text-sm font-semibold border border-white/20 text-white hover:bg-white/10 transition"
            >
              Customize
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}

function PreferencesModal({
  draftPreferences,
  draftAnalytics,
  draftMarketing,
  setDraftPreferences,
  setDraftAnalytics,
  setDraftMarketing,
  onClose,
  onAcceptAll,
  onRejectAll,
  onSave,
}: {
  draftPreferences: boolean;
  draftAnalytics: boolean;
  draftMarketing: boolean;
  setDraftPreferences: (v: boolean) => void;
  setDraftAnalytics: (v: boolean) => void;
  setDraftMarketing: (v: boolean) => void;
  onClose: () => void;
  onAcceptAll: () => void;
  onRejectAll: () => void;
  onSave: () => void;
}) {
  // Close on Escape for keyboard users.
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") onClose();
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);

  return (
    <div
      role="dialog"
      aria-modal="true"
      aria-labelledby="cookie-preferences-title"
      className="fixed inset-0 z-[110] flex items-end sm:items-center justify-center p-4 sm:p-6 bg-black/70 backdrop-blur-sm"
      onClick={onClose}
    >
      <div
        className="w-full max-w-2xl bg-brand-card border border-white/10 rounded-2xl shadow-2xl max-h-[90vh] overflow-hidden flex flex-col"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between p-6 border-b border-white/10">
          <h2
            id="cookie-preferences-title"
            className="text-xl font-bold text-white"
          >
            Cookie preferences
          </h2>
          <button
            type="button"
            onClick={onClose}
            aria-label="Close cookie preferences"
            className="text-gray-400 hover:text-white transition"
          >
            <svg
              className="w-6 h-6"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M6 18L18 6M6 6l12 12"
              />
            </svg>
          </button>
        </div>

        <div className="p-6 overflow-y-auto space-y-4 text-sm text-gray-300">
          <p>
            We use different kinds of cookies and similar technologies to
            operate this website. Strictly necessary cookies are always on
            because the site cannot function without them. Everything else is
            opt-in — we will not set these unless you agree.{" "}
            <Link
              href="/privacy-policy"
              className="text-brand-purple underline hover:text-white"
            >
              Read the full Privacy Policy
            </Link>
            .
          </p>

          <CategoryRow
            title="Strictly necessary"
            description="Required for the site to work, including remembering your cookie choices and basic security. These cannot be switched off."
            enabled={true}
            disabled
            onChange={() => {}}
          />
          <CategoryRow
            title="Preferences"
            description="Remember non-essential choices you make on the site, such as UI preferences. We do not currently set any preference cookies."
            enabled={draftPreferences}
            onChange={setDraftPreferences}
          />
          <CategoryRow
            title="Analytics"
            description="Help us understand how visitors use the site (pages viewed, buttons clicked) so we can improve it. We do not currently set any analytics cookies."
            enabled={draftAnalytics}
            onChange={setDraftAnalytics}
          />
          <CategoryRow
            title="Marketing"
            description="Used to measure advertising effectiveness and show relevant ads on other sites. We do not currently set any marketing cookies."
            enabled={draftMarketing}
            onChange={setDraftMarketing}
          />
        </div>

        <div className="p-6 border-t border-white/10 flex flex-col sm:flex-row gap-3">
          <button
            type="button"
            onClick={onRejectAll}
            className="flex-1 px-5 py-2.5 rounded-full text-sm font-semibold bg-brand-purple hover:bg-brand-purple/80 text-white transition"
          >
            Reject all
          </button>
          <button
            type="button"
            onClick={onSave}
            className="flex-1 px-5 py-2.5 rounded-full text-sm font-semibold border border-white/20 text-white hover:bg-white/10 transition"
          >
            Save my choices
          </button>
          <button
            type="button"
            onClick={onAcceptAll}
            className="flex-1 px-5 py-2.5 rounded-full text-sm font-semibold bg-brand-purple hover:bg-brand-purple/80 text-white transition"
          >
            Accept all
          </button>
        </div>
      </div>
    </div>
  );
}

function CategoryRow({
  title,
  description,
  enabled,
  disabled = false,
  onChange,
}: {
  title: string;
  description: string;
  enabled: boolean;
  disabled?: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <div className="flex items-start justify-between gap-4 p-4 bg-brand-bg/50 border border-white/5 rounded-xl">
      <div className="flex-1">
        <h3 className="text-white font-semibold mb-1">{title}</h3>
        <p className="text-xs text-gray-400 leading-relaxed">{description}</p>
      </div>
      <Toggle
        checked={enabled}
        disabled={disabled}
        onChange={onChange}
        label={title}
      />
    </div>
  );
}

function Toggle({
  checked,
  disabled,
  onChange,
  label,
}: {
  checked: boolean;
  disabled?: boolean;
  onChange: (v: boolean) => void;
  label: string;
}) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      disabled={disabled}
      onClick={() => onChange(!checked)}
      className={`relative inline-flex h-6 w-11 shrink-0 items-center rounded-full transition ${
        checked ? "bg-brand-purple" : "bg-white/20"
      } ${disabled ? "opacity-50 cursor-not-allowed" : "cursor-pointer"}`}
    >
      <span
        className={`inline-block h-5 w-5 transform rounded-full bg-white shadow transition ${
          checked ? "translate-x-[22px]" : "translate-x-0.5"
        }`}
      />
    </button>
  );
}
