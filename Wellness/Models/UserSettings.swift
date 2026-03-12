//
//  UserSettings.swift
//  Wellness
//

import Foundation

@Observable final class UserSettings {
    var name: String = "" {
        didSet { UserDefaults.standard.set(name, forKey: "userName") }
    }
    var fastingEnabled: Bool = false {
        didSet { UserDefaults.standard.set(fastingEnabled, forKey: "fastingEnabled") }
    }
    var currentWeight: Double = 160 {
        didSet { UserDefaults.standard.set(currentWeight, forKey: "currentWeight") }
    }
    var goalWeight: Double = 160 {
        didSet { UserDefaults.standard.set(goalWeight, forKey: "goalWeight") }
    }
    /// Grams of protein per pound of goal body weight (0.7 – 1.0).
    var proteinPerLb: Double = 0.9 {
        didSet { UserDefaults.standard.set(proteinPerLb, forKey: "proteinPerLb") }
    }

    init() {
        self.name          = UserDefaults.standard.string(forKey: "userName") ?? ""
        let storedFasting  = UserDefaults.standard.object(forKey: "fastingEnabled")
        self.fastingEnabled = storedFasting != nil
            ? UserDefaults.standard.bool(forKey: "fastingEnabled") : false

        // Default to 160 lbs if never saved
        let cw = UserDefaults.standard.double(forKey: "currentWeight")
        self.currentWeight = cw > 0 ? cw : 160
        let gw = UserDefaults.standard.double(forKey: "goalWeight")
        self.goalWeight    = gw > 0 ? gw : 160

        let pp = UserDefaults.standard.object(forKey: "proteinPerLb")
        self.proteinPerLb  = pp != nil ? UserDefaults.standard.double(forKey: "proteinPerLb") : 0.9
    }
}
