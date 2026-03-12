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
    var currentWeight: Double = 0 {
        didSet { UserDefaults.standard.set(currentWeight, forKey: "currentWeight") }
    }
    var goalWeight: Double = 0 {
        didSet { UserDefaults.standard.set(goalWeight, forKey: "goalWeight") }
    }

    init() {
        self.name          = UserDefaults.standard.string(forKey: "userName") ?? ""
        let storedFasting  = UserDefaults.standard.object(forKey: "fastingEnabled")
        self.fastingEnabled = storedFasting != nil
            ? UserDefaults.standard.bool(forKey: "fastingEnabled")
            : false
        self.currentWeight = UserDefaults.standard.double(forKey: "currentWeight")
        self.goalWeight    = UserDefaults.standard.double(forKey: "goalWeight")
    }
}
