//
//  UserSettings.swift
//  Wellness
//

import Foundation

@Observable final class UserSettings {
    // MARK: - Identity
    var userID: String = "" {
        didSet { UserDefaults.standard.set(userID, forKey: "userID") }
    }
    var username: String = "" {
        didSet { UserDefaults.standard.set(username, forKey: "username") }
    }
    var name: String = "" {
        didSet { UserDefaults.standard.set(name, forKey: "userName") }
    }

    // MARK: - Body
    var fastingEnabled: Bool = false {
        didSet { UserDefaults.standard.set(fastingEnabled, forKey: "fastingEnabled") }
    }
    var currentWeight: Double = 160 {
        didSet { UserDefaults.standard.set(currentWeight, forKey: "currentWeight") }
    }
    var goalWeight: Double = 160 {
        didSet { UserDefaults.standard.set(goalWeight, forKey: "goalWeight") }
    }
    var proteinPerLb: Double = 0.9 {
        didSet { UserDefaults.standard.set(proteinPerLb, forKey: "proteinPerLb") }
    }

    // MARK: - Aura

    var auraPoints: Int = 0 {
        didSet { UserDefaults.standard.set(auraPoints, forKey: "auraPoints") }
    }
    /// Comma-separated streak milestones already awarded, e.g. "3,7,14"
    private var achievedMilestonesRaw: String = "" {
        didSet { UserDefaults.standard.set(achievedMilestonesRaw, forKey: "achievedMilestones") }
    }
    /// Set when aura is earned; observe this to show the popup.
    var pendingAura: AuraAward? = nil

    // MARK: Computed aura properties

    var auraLevel: Int { min(auraPoints / 100, 100) }

    var auraTitle: String {
        switch auraLevel {
        case 0:       return ""
        case 1...9:   return "Initiate"
        case 10...24: return "Disciple"
        case 25...39: return "Ascender"
        case 40...59: return "Mog Apprentice"
        case 60...79: return "Aura Farmer"
        case 80...94: return "Elite Aesthetic"
        default:      return "Final Form"
        }
    }

    var achievedMilestones: Set<Int> {
        Set(achievedMilestonesRaw.split(separator: ",").compactMap { Int($0) })
    }

    // MARK: Aura award

    struct AuraAward: Identifiable {
        let id    = UUID()
        let points:  Int
        let reason:  String   // e.g. "🔥 7-Day Streak"
        let message: String   // gym bro hype line
    }

    func awardAura(points: Int, reason: String, message: String) {
        auraPoints   += points
        pendingAura   = AuraAward(points: points, reason: reason, message: message)
    }

    func markMilestoneAchieved(_ milestone: Int) {
        var set = achievedMilestones
        set.insert(milestone)
        achievedMilestonesRaw = set.map { String($0) }.joined(separator: ",")
    }

    // MARK: - Init

    init() {
        if let saved = UserDefaults.standard.string(forKey: "userID"), !saved.isEmpty {
            self.userID = saved
        } else {
            let id = UUID().uuidString
            self.userID = id
            UserDefaults.standard.set(id, forKey: "userID")
        }
        self.username = UserDefaults.standard.string(forKey: "username") ?? ""
        self.name     = UserDefaults.standard.string(forKey: "userName") ?? ""

        let storedFasting = UserDefaults.standard.object(forKey: "fastingEnabled")
        self.fastingEnabled = storedFasting != nil
            ? UserDefaults.standard.bool(forKey: "fastingEnabled") : false

        let cw = UserDefaults.standard.double(forKey: "currentWeight")
        self.currentWeight = cw > 0 ? cw : 160
        let gw = UserDefaults.standard.double(forKey: "goalWeight")
        self.goalWeight    = gw > 0 ? gw : 160

        let pp = UserDefaults.standard.object(forKey: "proteinPerLb")
        self.proteinPerLb = pp != nil ? UserDefaults.standard.double(forKey: "proteinPerLb") : 0.9

        self.auraPoints = UserDefaults.standard.integer(forKey: "auraPoints")
        self.achievedMilestonesRaw = UserDefaults.standard.string(forKey: "achievedMilestones") ?? ""
    }
}
