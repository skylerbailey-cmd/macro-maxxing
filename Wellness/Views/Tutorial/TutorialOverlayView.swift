//
//  TutorialOverlayView.swift
//  Wellness
//

import SwiftUI

// MARK: - Tutorial Step

struct TutorialStep {
    let title: String
    let body: String
    /// App-tour only: switch to this tab index before showing the step.
    let tabIndex: Int?
    /// Primary anchor ID — drives card positioning and the spotlight cutout.
    /// Nil = full-screen dim with no cutout.
    let anchorID: String?
    /// Extra anchor IDs to include in the spotlight when a single card needs
    /// to highlight multiple elements at once (e.g. the combined Feed step
    /// that calls out the aura stream, scope picker, and label chips together).
    let additionalAnchorIDs: [String]
    /// Optional inline icon view shown between the body and navigation buttons.
    let icon: TutorialIcon?

    init(title: String, body: String,
         tabIndex: Int? = nil,
         anchorID: String? = nil,
         additionalAnchorIDs: [String] = [],
         icon: TutorialIcon? = nil) {
        self.title    = title
        self.body     = body
        self.tabIndex = tabIndex
        self.anchorID = anchorID
        self.additionalAnchorIDs = additionalAnchorIDs
        self.icon     = icon
    }
}

enum TutorialIcon {
    case goldPlus
    case mealScore
}

// MARK: - Step Collections

enum TutorialSteps {

    // MARK: Full App Tour (shortened, hand-authored)
    //
    // The first-time tour intentionally combines and trims steps from the
    // per-tab tutorials so a brand-new user gets a faster onboarding pass
    // without losing context. The per-tab collections below (`hub`, `log`,
    // `feed`, `board`, `profile`) remain the source of truth for the help
    // icons in each tab — editing this array does NOT change those.
    static let appTour: [TutorialStep] = [
        .init(
            title: "Welcome to Macromaxxing",
            body: "Let's walk you through the app. This quick tour covers each tab so you know where everything is.\n\nYou can revisit this tutorial anytime — just tap the ? icon at the top of any tab.",
            anchorID: nil
        ),

        // ── Hub ────────────────────────────────────────────────────────
        .init(
            title: "Stats at a Glance",
            body: "Your streak count and aura level are pinned at the top, alongside the bell icon for in-app notifications and your profile picture for editing your profile. Streaks grow each day you hit all four macro goals; aura XP stacks from streaks, posts, and achievements to level you up over time.",
            tabIndex: 0,
            anchorID: "hub.header"
        ),
        .init(
            title: "Macro Goal Bars",
            body: "Each bar shows your actual vs. target for calories, protein, carbs, and fat. Tap any bar to see a 30-day history chart.",
            tabIndex: 0,
            anchorID: "hub.macros"
        ),
        .init(
            title: "AI Meal Planner",
            body: "Tap 'Brainstorm next meal' and AI will suggest specific meals or snacks tailored to your remaining macro gaps for the day. You get 2 suggestions per day — use them wisely.",
            tabIndex: 0,
            anchorID: "hub.mealPlanner"
        ),

        // ── Log ────────────────────────────────────────────────────────
        .init(
            title: "Fuel / Duel Tabs",
            body: "Fuel is your daily food log. Duel is where you log workouts — track exercises, duration, and calories burned. Tap the gold + button anywhere in the app to log a meal or workout.",
            tabIndex: 1,
            anchorID: "log.tabBar",
            icon: .goldPlus
        ),
        .init(
            title: "Meal Score Circle",
            body: "Each logged entry shows a small circle score (0–100) based on how well that meal's macro ratio aligns with your personal goals. Tap it to see the full breakdown.",
            tabIndex: 1,
            anchorID: nil,
            icon: .mealScore
        ),
        .init(
            title: "AI Nutrition Coach",
            body: "Scroll to the bottom of your food log to find the AI Nutrition Coach. It reviews your full day — every meal, macro distribution, and workout timing — then gives you a personalized nutritionist-level debrief with actionable advice. Available once per day.",
            tabIndex: 1,
            anchorID: "log.nutritionCoach"
        ),

        // ── Feed ───────────────────────────────────────────────────────
        .init(
            title: "Your Feed",
            body: "The Aura Stream is your community feed — logging meals, hitting streaks, and sharing progress builds your standing. Use the scope picker to switch between Arena (everyone), Team (friends), Following, and Local. Tap any label chip — Fuel Log, Workout, Transformation, Goal — to filter the feed to exactly what you want to see.",
            tabIndex: 2,
            anchorID: "feed.header",
            additionalAnchorIDs: ["feed.scopePicker", "feed.labelChips"]
        ),
        .init(
            title: "Create a Post",
            body: "Tap the + floating button in the bottom right to create a new post. Pick a label to pre-fill the title and body, then make it yours.",
            tabIndex: 2,
            anchorID: nil,
            icon: .goldPlus
        ),

        // ── Board ──────────────────────────────────────────────────────
        .init(
            title: "Mog Board",
            body: "The weekly leaderboard resets every Sunday at 8 PM ET. Your rank is based on the aura XP you earn during the week — hit your macro goals daily, keep your streak alive, and stay active to climb. Use the scope selector to compare yourself within your Team, your Local area, or across the full Arena.",
            tabIndex: 3,
            anchorID: "board.header"
        ),
        .init(
            title: "Your Standing",
            body: "Your row is always highlighted so you can find your rank at a glance. Pull down to refresh the board with the latest data.",
            tabIndex: 3,
            anchorID: "board.rows"
        ),
    ]

    // MARK: Profile
    static let profile: [TutorialStep] = [
        .init(
            title: "Your Profile",
            body: "This is your public-facing page. If your account is set to public in Settings, anyone on the platform can view your profile, posts, and stats.",
            anchorID: "profile.header"
        ),
        .init(
            title: "Balance Score",
            body: "Your Balance Score (0–100) measures how precisely you hit all four macro goals — calories, protein, carbs, and fat. Hitting every target perfectly gives you 100. Going over OR under both lower the score equally. Tap the ring to learn more.",
            anchorID: "profile.balanceScore"
        ),
        .init(
            title: "Streak & Aura XP",
            body: "Your current streak and total Aura XP are pinned here so anyone who views your profile can see your consistency at a glance.",
            anchorID: "profile.stats"
        ),
        .init(
            title: "Connections & Posts",
            body: "Tap Connections to see followers and following. Your logged meals, workouts, and posts appear in the grid below — everything you've shared lives here.",
            anchorID: "profile.stats"
        ),
    ]

    // MARK: Per-Tab — Hub
    static let hub: [TutorialStep] = [
        .init(
            title: "Stats at a Glance",
            body: "Your streak count and aura level are pinned at the top. Streaks grow each day you hit all four macro goals — calories, protein, carbs, and fat. Aura XP stacks from streaks, posts, and achievements to level you up over time.",
            anchorID: "hub.header"
        ),
        .init(
            title: "Notifications & Profile",
            body: "The bell icon shows in-app notifications — new followers, likes, and streak alerts. Tap your profile picture to view and edit your profile.",
            anchorID: "hub.notifications"
        ),
        .init(
            title: "Macro Goal Bars",
            body: "Each bar shows your actual vs. target for calories, protein, carbs, and fat. Tap any bar to see a 30-day history chart.",
            anchorID: "hub.macros"
        ),
        .init(
            title: "Discipline Score",
            body: "Averages how closely you hit each active macro goal. 100% = perfect. Both over-goal and under-goal penalize the score — precision is the game.",
            anchorID: "hub.discipline"
        ),
        .init(
            title: "AI Meal Planner",
            body: "Tap 'Brainstorm next meal' and AI will suggest specific meals or snacks tailored to your remaining macro gaps for the day. You get 2 suggestions per day — use them wisely.",
            anchorID: "hub.mealPlanner"
        ),
    ]

    // MARK: Per-Tab — Log
    static let log: [TutorialStep] = [
        .init(
            title: "Fuel / Duel Tabs",
            body: "Fuel is your daily food log. Duel is where you log workouts — track exercises, duration, and calories burned.",
            anchorID: "log.tabBar"
        ),
        .init(
            title: "Log a Meal or Workout",
            body: "Tap the gold + button to log a meal or workout. It's always visible no matter which tab you're on, so you can log from anywhere in the app.",
            anchorID: nil,
            icon: .goldPlus
        ),
        .init(
            title: "Meal Score Circle",
            body: "Each logged entry shows a small circle score (0–100) based on how well that meal's macro ratio aligns with your personal goals. Tap it to see the full breakdown.",
            anchorID: nil,
            icon: .mealScore
        ),
        .init(
            title: "AI Nutrition Coach",
            body: "Scroll to the bottom of your food log to find the AI Nutrition Coach. It reviews your full day — every meal, macro distribution, and workout timing — then gives you a personalized nutritionist-level debrief with actionable advice. Available once per day.",
            anchorID: "log.nutritionCoach"
        ),
    ]

    // MARK: Per-Tab — Feed
    static let feed: [TutorialStep] = [
        .init(
            title: "Aura Stream",
            body: "Your community feed. Logging meals, hitting streaks, and sharing progress generates aura and builds your standing in the community.",
            anchorID: "feed.header"
        ),
        .init(
            title: "Scope Filters",
            body: "Arena = everyone on the platform. Team = your friends. Following = people you've followed. Local = users near you.",
            anchorID: "feed.scopePicker"
        ),
        .init(
            title: "Post Label Chips",
            body: "Tap any label chip to filter the feed. Fuel Log, Workout, Transformation, Goal — find exactly what you want to see.",
            anchorID: "feed.labelChips"
        ),
        .init(
            title: "Create a Post",
            body: "Tap the + floating button in the bottom right to create a new post. Pick a label to pre-fill the title and body, then make it yours.",
            anchorID: nil,
            icon: .goldPlus
        ),
    ]

    // MARK: Per-Tab — Board
    static let board: [TutorialStep] = [
        .init(
            title: "Mog Board",
            body: "The weekly leaderboard resets every Sunday at 8 PM ET. Your rank is based on the aura XP you earn during the week — hit your macro goals daily, keep your streak alive, and stay active to climb.",
            anchorID: "board.header"
        ),
        .init(
            title: "Scope Selector",
            body: "Compare yourself within your Team, your Local area, or across the full Arena. Switch scopes to see how you stack up against friends, nearby users, or everyone on the platform.",
            anchorID: "board.scopePicker"
        ),
        .init(
            title: "Your Standing",
            body: "Your row is always highlighted so you can find your rank at a glance. Pull down to refresh the board with the latest data.",
            anchorID: "board.rows"
        ),
    ]
}

// MARK: - View

struct TutorialOverlayView: View {
    let steps: [TutorialStep]
    /// Pass `$selectedTab` for the full app tour; omit (defaults to `.constant(0)`) for per-tab.
    var selectedTab: Binding<Int> = .constant(0)
    /// Resolved anchor frames from `TutorialAnchorKey` via `onPreferenceChange`.
    var anchors: [String: Anchor<CGRect>] = [:]
    let onDismiss: () -> Void
    /// Called when the active step changes, passing the new step's `anchorID`.
    var onStepChange: ((_ anchorID: String?) -> Void)? = nil

    @State private var currentStep = 0

    private var step: TutorialStep { steps[currentStep] }
    private var isLast: Bool { currentStep == steps.count - 1 }

    var body: some View {
        GeometryReader { geo in
            // Resolve every anchor for the current step (primary + extras)
            // into real CGRects. Most steps have a single anchor; the
            // combined Feed step uses several so the spotlight covers the
            // aura stream, scope picker, and label chips together.
            let allAnchorIDs: [String] =
                (step.anchorID.map { [$0] } ?? []) + step.additionalAnchorIDs
            let highlightRects: [CGRect] = allAnchorIDs.compactMap { id in
                anchors[id].map { geo[$0] }
            }
            // Card positioning is driven by the primary (first) rect.
            let primaryRect = highlightRects.first
            // If primary highlight is in the lower half, put the card at the top
            let cardAtTop = (primaryRect?.midY ?? 0) > geo.size.height * 0.45

            ZStack {
                // ── Spotlight layer ──────────────────────────────────────────
                if !highlightRects.isEmpty {
                    Color.black.opacity(0.72)
                        .overlay(
                            // Punch a transparent hole over each target element
                            ZStack {
                                ForEach(highlightRects.indices, id: \.self) { i in
                                    let rect = highlightRects[i]
                                    RoundedRectangle(cornerRadius: 14)
                                        .frame(width: rect.width  + 8,
                                               height: rect.height + 8)
                                        .position(x: rect.midX, y: rect.midY)
                                        .blendMode(.destinationOut)
                                }
                            }
                        )
                        .drawingGroup()
                        .allowsHitTesting(false)

                    // Purple highlight ring on top of each hole
                    ForEach(highlightRects.indices, id: \.self) { i in
                        let rect = highlightRects[i]
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(red: 0.65, green: 0.45, blue: 1.00).opacity(0.85),
                                    lineWidth: 2)
                            .frame(width: rect.width  + 8,
                                   height: rect.height + 8)
                            .position(x: rect.midX, y: rect.midY)
                            .shadow(color: Color(red: 0.65, green: 0.45, blue: 1.00).opacity(0.45),
                                    radius: 10)
                            .allowsHitTesting(false)
                    }
                } else {
                    Color.black.opacity(0.65).allowsHitTesting(false)
                }

                // ── Tutorial card ────────────────────────────────────────────
                VStack(spacing: 0) {
                    if cardAtTop {
                        card
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                        Spacer()
                    } else {
                        Spacer()
                        card
                            .padding(.horizontal, 16)
                            .padding(.bottom, 90)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.3), value: currentStep)
            .onAppear {
                if let tab = steps[0].tabIndex {
                    selectedTab.wrappedValue = tab
                }
            }
        }
    }

    // MARK: Card

    private var card: some View {
        VStack(alignment: .leading, spacing: 18) {

            // Progress dots + step counter + close
            HStack(spacing: 0) {
                HStack(spacing: 5) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Capsule()
                            .fill(i == currentStep
                                  ? Color(red: 0.65, green: 0.45, blue: 1.00)
                                  : Color.white.opacity(0.20))
                            .frame(width: i == currentStep ? 18 : 6, height: 6)
                            .animation(.spring(duration: 0.3), value: currentStep)
                    }
                }
                Spacer()
                Text("\(currentStep + 1) / \(steps.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.40))
                    .padding(.trailing, 10)
                Button { onDismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white.opacity(0.55))
                        .padding(7)
                        .background(Color.white.opacity(0.10), in: Circle())
                }
                .buttonStyle(.plain)
            }

            // Title + body
            VStack(alignment: .leading, spacing: 8) {
                Text(step.title)
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                Text(step.body)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Inline icon (e.g. pulsing gold + button)
            if let icon = step.icon {
                TutorialIconView(icon: icon)
                    .frame(maxWidth: .infinity)
            }

            // Navigation
            HStack(spacing: 10) {
                if currentStep > 0 {
                    Button { advance(by: -1) } label: {
                        Text("Back")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.75))
                            .padding(.horizontal, 18)
                            .padding(.vertical, 9)
                            .background(Color.white.opacity(0.10),
                                        in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Button { isLast ? onDismiss() : advance(by: 1) } label: {
                    Text(isLast ? "Got it!" : "Next")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 9)
                        .background(Color(red: 0.65, green: 0.45, blue: 1.00),
                                    in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.10, green: 0.10, blue: 0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            Color(red: 0.65, green: 0.45, blue: 1.00).opacity(0.30),
                            lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.50), radius: 24, y: 8)
        }
    }

    // MARK: Helpers

    private func advance(by delta: Int) {
        let next = currentStep + delta
        guard next >= 0 && next < steps.count else { return }
        if let tab = steps[next].tabIndex {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedTab.wrappedValue = tab
            }
        }
        // Notify the parent before animating so it can scroll the target into view
        onStepChange?(steps[next].anchorID)
        withAnimation(.spring(duration: 0.30)) {
            currentStep = next
        }
    }
}

// MARK: - Tutorial Icon View

private struct TutorialIconView: View {
    let icon: TutorialIcon
    @State private var pulsing = false

    private let gold = Color(red: 1.00, green: 0.80, blue: 0.20)

    var body: some View {
        switch icon {
        case .goldPlus:
            ZStack {
                Circle()
                    .fill(gold.opacity(0.15))
                    .frame(width: 64, height: 64)
                    .scaleEffect(pulsing ? 1.25 : 1.0)
                    .opacity(pulsing ? 0.0 : 1.0)

                Circle()
                    .fill(gold)
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.black)
                    }
                    .scaleEffect(pulsing ? 1.08 : 1.0)
            }
            .padding(.vertical, 4)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    pulsing = true
                }
            }

        case .mealScore:
            let scoreGreen = Color(red: 0.25, green: 0.85, blue: 0.50)
            let cardBg     = Color(red: 0.13, green: 0.10, blue: 0.22)
            let proClr     = Color(red: 0.35, green: 0.75, blue: 1.00)
            let carbClr    = Color(red: 0.40, green: 0.90, blue: 0.72)
            let fatClr     = Color(red: 1.00, green: 0.50, blue: 0.72)

            HStack(spacing: 16) {
                // Score circle
                ZStack {
                    Circle()
                        .stroke(scoreGreen.opacity(0.35), lineWidth: 3)
                        .frame(width: 60, height: 60)
                    Text("85")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundStyle(scoreGreen)
                }

                // Macro breakdown table
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("Macro")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("This Meal")
                            .frame(width: 65, alignment: .center)
                        Text("Your Goal")
                            .frame(width: 65, alignment: .center)
                    }
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.40))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)

                    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)

                    // Protein row
                    mealScoreRow(label: "Protein", meal: "32%", goal: "30%", color: proClr, arrow: nil)
                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                    // Carbs row
                    mealScoreRow(label: "Carbs", meal: "43%", goal: "45%", color: carbClr, arrow: nil)
                    Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                    // Fat row
                    mealScoreRow(label: "Fat", meal: "25%", goal: "25%", color: fatClr, arrow: nil)
                }
                .background(cardBg)
                .cornerRadius(10)
            }
            .padding(.vertical, 4)
        }
    }

    private func mealScoreRow(label: String, meal: String, goal: String, color: Color, arrow: String?) -> some View {
        HStack {
            HStack(spacing: 4) {
                Circle().fill(color).frame(width: 5, height: 5)
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(meal)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 65, alignment: .center)

            Text(goal)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))
                .frame(width: 65, alignment: .center)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
    }
}
