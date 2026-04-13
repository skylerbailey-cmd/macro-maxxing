"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useState,
} from "react";

/**
 * Cookie consent categories.
 *
 * - `essential`: strictly necessary for the site to function (e.g. remembering
 *   the user's own consent choice). Always on — cannot be disabled under
 *   GDPR/ePrivacy because the site could not operate without them.
 * - `preferences`: remembers non-essential UI preferences. Opt-in only.
 * - `analytics`: measurement of site usage. Opt-in only.
 * - `marketing`: advertising / cross-site tracking. Opt-in only.
 *
 * As of this commit the Macromaxxing website does not actually set any
 * non-essential cookies, so every opt-in category is currently unused. The
 * stored consent exists as a gate: any future analytics or marketing scripts
 * must check the corresponding flag before loading.
 */
export type ConsentCategories = {
  essential: true;
  preferences: boolean;
  analytics: boolean;
  marketing: boolean;
};

type OptionalCategories = Omit<ConsentCategories, "essential">;

type StoredConsent = {
  version: number;
  timestamp: number;
  choices: OptionalCategories;
};

const STORAGE_KEY = "mm-cookie-consent";
const STORAGE_VERSION = 1;

const DEFAULT_OPTIONAL: OptionalCategories = {
  preferences: false,
  analytics: false,
  marketing: false,
};

const ALL_OPTIONAL: OptionalCategories = {
  preferences: true,
  analytics: true,
  marketing: true,
};

type CookieConsentContextValue = {
  /** True once mounted on the client and the stored state has been read. */
  ready: boolean;
  /** Has the user made an explicit choice yet? */
  hasChosen: boolean;
  /** Current consent categories. */
  consent: ConsentCategories;
  /** Whether the preferences modal is currently open. */
  preferencesOpen: boolean;
  openPreferences: () => void;
  closePreferences: () => void;
  acceptAll: () => void;
  rejectAll: () => void;
  savePreferences: (choices: OptionalCategories) => void;
};

const CookieConsentContext = createContext<CookieConsentContextValue | null>(
  null,
);

function readStored(): StoredConsent | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as StoredConsent;
    if (parsed.version !== STORAGE_VERSION) return null;
    return parsed;
  } catch {
    return null;
  }
}

function writeStored(choices: OptionalCategories) {
  if (typeof window === "undefined") return;
  const value: StoredConsent = {
    version: STORAGE_VERSION,
    timestamp: Date.now(),
    choices,
  };
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(value));
  } catch {
    // ignore quota / private-mode errors
  }
}

export function CookieConsentProvider({
  children,
}: {
  children: React.ReactNode;
}) {
  const [ready, setReady] = useState(false);
  const [hasChosen, setHasChosen] = useState(false);
  const [optional, setOptional] =
    useState<OptionalCategories>(DEFAULT_OPTIONAL);
  const [preferencesOpen, setPreferencesOpen] = useState(false);

  useEffect(() => {
    const stored = readStored();
    if (stored) {
      setOptional(stored.choices);
      setHasChosen(true);
    }
    setReady(true);
  }, []);

  const acceptAll = useCallback(() => {
    setOptional(ALL_OPTIONAL);
    setHasChosen(true);
    setPreferencesOpen(false);
    writeStored(ALL_OPTIONAL);
  }, []);

  const rejectAll = useCallback(() => {
    setOptional(DEFAULT_OPTIONAL);
    setHasChosen(true);
    setPreferencesOpen(false);
    writeStored(DEFAULT_OPTIONAL);
  }, []);

  const savePreferences = useCallback((choices: OptionalCategories) => {
    setOptional(choices);
    setHasChosen(true);
    setPreferencesOpen(false);
    writeStored(choices);
  }, []);

  const openPreferences = useCallback(() => setPreferencesOpen(true), []);
  const closePreferences = useCallback(() => setPreferencesOpen(false), []);

  const value = useMemo<CookieConsentContextValue>(
    () => ({
      ready,
      hasChosen,
      consent: { essential: true, ...optional },
      preferencesOpen,
      openPreferences,
      closePreferences,
      acceptAll,
      rejectAll,
      savePreferences,
    }),
    [
      ready,
      hasChosen,
      optional,
      preferencesOpen,
      openPreferences,
      closePreferences,
      acceptAll,
      rejectAll,
      savePreferences,
    ],
  );

  return (
    <CookieConsentContext.Provider value={value}>
      {children}
    </CookieConsentContext.Provider>
  );
}

export function useCookieConsent(): CookieConsentContextValue {
  const ctx = useContext(CookieConsentContext);
  if (!ctx) {
    throw new Error(
      "useCookieConsent must be used within a CookieConsentProvider",
    );
  }
  return ctx;
}
