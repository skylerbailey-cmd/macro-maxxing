"use client";

import { useCookieConsent } from "./CookieConsentProvider";

/**
 * Footer button that re-opens the cookie preferences modal so users can change
 * or withdraw their consent at any time. Rendered as a plain button styled to
 * match the other footer links.
 */
export function CookieSettingsLink({ className }: { className?: string }) {
  const { openPreferences } = useCookieConsent();
  return (
    <button type="button" onClick={openPreferences} className={className}>
      Cookie settings
    </button>
  );
}
