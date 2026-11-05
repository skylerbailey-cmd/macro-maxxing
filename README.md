# Macro Maxxing

**An iOS nutrition and macro tracker where you log a meal by taking a photo of it.** Claude identifies the food and estimates the macros; you confirm before anything is saved.

🌐 **[macromaxxing.app](https://macromaxxing.app)** · iOS 18+ · SwiftUI · Firebase · Claude API

---

## Features

- **Photo food logging:** snap one or several photos, optionally mark up or crop them, and get each item with calories, protein, carbs and fat. Voice notes work too.
- **Restaurant mode:** reads a restaurant menu and estimates macros for each dish.
- **Nutrition coach & meal planner:** daily targets that adjust to your weigh-ins and goals, plus AI-generated meal plans.
- **Fasting timer:** intermittent-fasting windows on a timeline.
- **Workout logging** with a Live Activity on the Lock Screen and Dynamic Island.
- **Home Screen widgets:** log a meal in one tap.
- **Streaks and accountability:** streaks with shields and extensions, a weekly leaderboard, and a feed for following friends.
- **Subscriptions** through StoreKit 2, with affiliate promo codes.

## How food recognition works

A two-tier pipeline (`Wellness/Services/FoodRecognitionManager.swift`) keeps scans fast and cheap without giving up accuracy:

1. **Tier 1, Claude Haiku (vision):** identifies the items and estimates macros. If its confidence is low, the identified items go to Sonnet as a cheap **text-only** cross-check instead of re-sending the image.
2. **Tier 2, Claude Sonnet (vision):** full analysis for hard photos, escalations and voice notes.

Results are cached, and the user reviews every item before it's logged. The app never calls Anthropic directly: requests go through an authenticated Firebase Cloud Function (`proxyClaude`), so **no API keys ship in the app**, and photos are only sent after the user has consented to AI processing.

## Architecture

```
Wellness/             SwiftUI app (MVVM, @Observable view models)
  Models/             data types (food entries, posts, workouts, settings)
  Services/           food recognition, Firebase, StoreKit, notifications
  ViewModels/         business logic
  Views/              screens: Home, Macros, Social, Workout, Settings, …
WellnessWidgets/      widgets and Live Activities (WidgetKit, ActivityKit)
functions/            Firebase Cloud Functions (Node 20)
website/              marketing site (Next.js + Tailwind)
firestore.rules       per-user security rules
```

**Stack:** Swift · SwiftUI · WidgetKit · ActivityKit · StoreKit 2 · Firebase (Auth with Sign in with Apple, Firestore, Storage, Cloud Functions, App Check, Remote Config) · Claude API (Haiku + Sonnet) · Next.js

### Backend (Cloud Functions)

| Function | Purpose |
|---|---|
| `proxyClaude` | Authenticated proxy to the Claude API; the key lives in Secret Manager |
| `exchangeAppleAuthCode`, `deleteAccount` | Sign in with Apple token handling and full account deletion (App Store requirement) |
| `appStoreNotifications` | App Store Server Notifications v2 for subscription state |
| `affiliateCommissionReport` / `CSV` | Commission reporting for creator promo codes |
| `onFollowCreate` / `onFollowDelete`, `sendPushOnNewPostNotification` | Social graph counters and push notifications |
| `resetWeeklyAura` | Scheduled weekly leaderboard reset |

## Running locally

1. Open `Macro Maxxing.xcodeproj` in Xcode 16+.
2. Replace `Wellness/GoogleService-Info.plist` with one from your own Firebase project.
3. If you enforce App Check, register a debug token for the simulator in the Firebase console and set `FIRAAppCheckDebugToken` in a **local, unshared** scheme. Never commit it.
4. Cloud Functions: `cd functions && npm install`, then `firebase functions:secrets:set ANTHROPIC_API_KEY` and `firebase deploy --only functions`.

---

© Skyler Bailey. Source shared for review; not licensed for reuse.
