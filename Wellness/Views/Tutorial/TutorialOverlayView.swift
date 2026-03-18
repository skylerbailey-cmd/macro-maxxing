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
    /// ID passed to `.tutorialAnchor(_:)` on the element to spotlight.
    /// Nil = full-screen dim with no cutout.
    let anchorID: String?

    init(title: String, body: String,
         tabIndex: Int? = nil,
         anchorID: String? = nil) {
        self.title    = title
        self.body     = body
        self.tabIndex = tabIndex
        self.anchorID = anchorID
    }
}

// MARK: - Step Collections

enum TutorialSteps {

    // MARK: Full App Tour
    static let appTour: [TutorialStep] = [
        .init(
            title: "Welcome to Your Hub",
            body: "This is your daily command center. Your greeting, streak, aura level, and weight are always visible at the top. Everything starts here.",
            tabIndex: 0
        ),
        .init(
            title: "Fasting Window",
            body: "Tap the fasting card to start or stop your fast. The arc fills as you move through your chosen window — 16:8, 18:6, or whatever you set.",
            tabIndex: 0
        ),
        .init(
            title: "Daily Macro Goals",
            body: "Your calorie, protein, carb, and fat targets live here. Log meals in the Fuel tab and these bars fill in automatically throughout the day.",
            tabIndex: 0
        ),
        .init(
            title: "Discipline Score",
            body: "A 0–100% score that averages how precisely you hit each macro goal. Going over OR under your target both lower the score equally.",
            tabIndex: 0
        ),
        .init(
            title: "Streaks & Aura XP",
            body: "Hit all four macro goals every day to extend your streak. Aura XP stacks from streaks, posts, and goal hits to level you up over time.",
            tabIndex: 0
        ),
        .init(
            title: "Notifications & Profile",
            body: "The bell icon shows streak alerts, new followers, and likes. Tap your profile picture to view your stats and aura progress.",
            tabIndex: 0
        ),
        .init(
            title: "Fuel Log — Log a Meal",
            body: "Snap or upload a photo of your meal. AI reads the plate and estimates your macros instantly. You can edit any value before saving.",
            tabIndex: 1
        ),
        .init(
            title: "Duel Mode",
            body: "Tap 'Duel' to compare your daily macros head-to-head with a friend. Challenge someone or accept a pending challenge from here.",
            tabIndex: 1
        ),
        .init(
            title: "Aura Stream",
            body: "Your community feed. Every post earns the creator aura points — likes, comments, and consistent posting boost them further.",
            tabIndex: 2
        ),
        .init(
            title: "Feed Filters",
            body: "Switch between Arena (everyone), Team, Following, and Local to control whose content you see.",
            tabIndex: 2
        ),
        .init(
            title: "Post Label Chips",
            body: "Tap a chip — Fuel Log, Workout, Transformation, Goal, etc. — to filter the feed to that content type only.",
            tabIndex: 2
        ),
        .init(
            title: "Mog Board",
            body: "The weekly leaderboard resets every Monday. Earn points by logging meals, hitting streak milestones, and posting consistently.",
            tabIndex: 3
        ),
        .init(
            title: "Leaderboard Types",
            body: "Switch between Weekly Aura, Engagement (all-time), and Streak boards. Use the scope picker to compare across Team, Local, or Arena.",
            tabIndex: 3
        ),
    ]

    // MARK: Per-Tab — Hub
    static let hub: [TutorialStep] = [
        .init(
            title: "Stats at a Glance",
            body: "Your streak count, aura level, and current weight are pinned at the top so you always know where you stand before you start your day.",
            anchorID: "hub.header"
        ),
        .init(
            title: "Notifications & Profile",
            body: "The bell icon shows in-app notifications — new followers, likes, and streak alerts. Tap your profile picture to view and edit your profile.",
            anchorID: "hub.notifications"
        ),
        .init(
            title: "Streaks & Aura",
            body: "Hit all four macro KPIs — calories, protein, carbs, and fat — each day to extend your streak. Aura XP stacks from streaks, posts, and achievements.",
            anchorID: "hub.header"
        ),
        .init(
            title: "Macro Goal Bars",
            body: "Each bar shows your actual vs. target for calories, protein, carbs, and fat. Tap any bar to see a 30-day history chart.",
            anchorID: "hub.macros"
        ),
        .init(
            title: "Discipline Score",
            body: "Averages how closely you hit each active macro goal. 100% = perfect. Both over-goal and under-goal penalize the score — precision is the game.",
            anchorID: "hub.macros"
        ),
    ]

    // MARK: Per-Tab — Log
    static let log: [TutorialStep] = [
        .init(
            title: "Fuel Tab — Log a Meal",
            body: "Tap the camera icon or photo icon at the bottom right to add a meal. AI analyzes the image and pre-fills your macros. Edit before saving.",
            anchorID: "log.header"
        ),
        .init(
            title: "Notifications & Profile",
            body: "The bell icon shows streak alerts, new followers, and likes. Tap your profile picture to view your stats, posts, and aura progress.",
            anchorID: "log.notifications"
        ),
        .init(
            title: "Fuel / Duel Tabs",
            body: "Switch between Fuel (your food log) and Duel (macro comparison with a friend). Send a challenge or accept a pending one in Duel.",
            anchorID: "log.tabBar"
        ),
        .init(
            title: "Daily Macro Summary",
            body: "The running total at the top updates in real time as you log meals. Check your remaining macros before each meal to stay on track.",
            anchorID: "log.macroSummary"
        ),
        .init(
            title: "Meal Score Circle",
            body: "Each logged entry shows a small circle score (0–100) based on how well that meal's macro ratio aligns with your personal goals.",
            anchorID: "log.entries"
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
            title: "Notifications & Profile",
            body: "The bell icon shows streak alerts, new followers, and likes. Tap your profile picture to view your stats, posts, and aura progress.",
            anchorID: "feed.notifications"
        ),
        .init(
            title: "Scope Filters",
            body: "Arena = everyone on the platform. Team = your crew. Following = people you've followed. Local = users near you.",
            anchorID: "feed.scopePicker"
        ),
        .init(
            title: "Post Label Chips",
            body: "Tap any label chip to filter the feed. Fuel Log, Workout, Transformation, Goal, Makeup Day — find exactly what you want to see.",
            anchorID: "feed.labelChips"
        ),
        .init(
            title: "Inline Macro Charts",
            body: "Fuel Log posts show a discipline chart right in the feed. No tapping needed — you can see the full macro breakdown at a glance.",
            anchorID: "feed.posts"
        ),
        .init(
            title: "Create a Post",
            body: "Tap the + floating button in the bottom right to create a new post. Pick a label to pre-fill the title and body, then make it yours.",
            anchorID: nil
        ),
    ]

    // MARK: Per-Tab — Board
    static let board: [TutorialStep] = [
        .init(
            title: "Mog Board",
            body: "The weekly competition resets every Monday. Stay consistent — every day you hit all four macro goals earns points and keeps you on the board.",
            anchorID: "board.header"
        ),
        .init(
            title: "Notifications & Profile",
            body: "The bell icon shows streak alerts, new followers, and likes. Tap your profile picture to view your stats, posts, and aura progress.",
            anchorID: "board.notifications"
        ),
        .init(
            title: "Scope Selector",
            body: "Compare yourself within your Team, your Local area, or across the full Arena. Scope changes apply to all leaderboard types.",
            anchorID: "board.scopePicker"
        ),
        .init(
            title: "Weekly Aura",
            body: "Points earned this week from meal logs, streak bonuses, and post engagement. Top earners are featured at the top of the board.",
            anchorID: "board.rows"
        ),
        .init(
            title: "Engagement & Streak Boards",
            body: "Engagement tracks all-time likes and interactions. Streak tracks the longest active logging chain — these never reset.",
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

    @State private var currentStep = 0

    private var step: TutorialStep { steps[currentStep] }
    private var isLast: Bool { currentStep == steps.count - 1 }

    var body: some View {
        GeometryReader { geo in
            // Resolve the anchor for the current step into a real CGRect
            let highlightRect: CGRect? = step.anchorID.flatMap { id in
                anchors[id].map { geo[$0] }
            }
            // If highlight is in the lower half of the screen, put the card at the top
            let cardAtTop = (highlightRect?.midY ?? 0) > geo.size.height * 0.45

            ZStack {
                // ── Spotlight layer ──────────────────────────────────────────
                if let rect = highlightRect {
                    Color.black.opacity(0.72)
                        .overlay(
                            // Punch a transparent hole over the target element
                            RoundedRectangle(cornerRadius: 14)
                                .frame(width: rect.width  + 8,
                                       height: rect.height + 8)
                                .position(x: rect.midX, y: rect.midY)
                                .blendMode(.destinationOut)
                        )
                        .drawingGroup()
                        .allowsHitTesting(false)

                    // Purple highlight ring on top of the hole
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(red: 0.65, green: 0.45, blue: 1.00).opacity(0.85),
                                lineWidth: 2)
                        .frame(width: rect.width  + 8,
                               height: rect.height + 8)
                        .position(x: rect.midX, y: rect.midY)
                        .shadow(color: Color(red: 0.65, green: 0.45, blue: 1.00).opacity(0.45),
                                radius: 10)
                        .allowsHitTesting(false)
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
        withAnimation(.spring(duration: 0.30)) {
            currentStep = next
        }
    }
}
