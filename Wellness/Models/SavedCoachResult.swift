//
//  SavedCoachResult.swift
//  Wellness
//
//  Persistence for AI Nutrition Coach results (last 3).
//

import Foundation

struct SavedCoachResult: Identifiable, Codable, Equatable {
    let id: String
    let date: Date
    /// The AI-generated coaching text (markdown).
    let text: String

    init(text: String) {
        self.id   = UUID().uuidString
        self.date = Date()
        self.text = text
    }
}

enum SavedCoachResultStore {
    private static let key = "savedCoachResults"
    private static let maxResults = 30

    static func load() -> [SavedCoachResult] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let results = try? JSONDecoder().decode([SavedCoachResult].self, from: data)
        else { return [] }
        return results
    }

    static func save(_ result: SavedCoachResult) {
        var results = load()
        results.insert(result, at: 0)
        if results.count > maxResults { results = Array(results.prefix(maxResults)) }
        if let data = try? JSONEncoder().encode(results) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    static func delete(_ id: String) {
        var results = load()
        results.removeAll { $0.id == id }
        if let data = try? JSONEncoder().encode(results) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
