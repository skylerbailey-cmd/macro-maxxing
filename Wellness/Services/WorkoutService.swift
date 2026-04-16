//
//  WorkoutService.swift
//  Wellness
//
//  Firestore: users/{userID}/workoutEntries/{workoutID}
//  Saved workout templates: UserDefaults (device-local)
//

import Foundation
import FirebaseFirestore

final class WorkoutService {

    static let shared = WorkoutService()
    private init() {}

    /// Post this after a successful save so the Duel tab can reload.
    static let workoutSavedNotification = Notification.Name("com.sbailey.Wellness.workoutSaved")

    private var db: Firestore { FirebaseManager.shared.db }
    private let savedWorkoutsKey = "savedWorkoutTemplates"

    // MARK: - Save

    func save(entry: WorkoutEntry, userID: String) async throws {
        guard !userID.isEmpty else { return }
        let exerciseDicts: [[String: Any]] = entry.exercises.map { ex in
            let setDicts: [[String: Any]] = ex.sets.map { s in
                var sd: [String: Any] = ["id": s.id, "reps": s.reps]
                if let w = s.weight { sd["weight"] = w }
                return sd
            }
            return [
                "id":   ex.id,
                "name": ex.name,
                "sets": setDicts
            ]
        }
        let data: [String: Any] = [
            "workoutID":          entry.workoutID,
            "name":               entry.name,
            "workoutType":        entry.workoutType.rawValue,
            "durationMinutes":    entry.durationMinutes,
            "caloriesBurned":     entry.caloriesBurned,
            "loggedAt":           Timestamp(date: entry.loggedAt),
            "adjustmentApplied":  entry.adjustmentApplied,
            "exercises":          exerciseDicts
        ]
        try await db.collection("users").document(userID)
            .collection("workoutEntries").document(entry.workoutID)
            .setData(data)

        NotificationCenter.default.post(name: Self.workoutSavedNotification, object: nil)
    }

    // MARK: - Fetch

    func fetch(userID: String, date: Date) async throws -> [WorkoutEntry] {
        guard !userID.isEmpty else { return [] }
        let cal   = Calendar.current
        let start = cal.startOfDay(for: date)
        let end   = cal.date(byAdding: .day, value: 1, to: start)!

        let snapshot = try await db.collection("users").document(userID)
            .collection("workoutEntries")
            .whereField("loggedAt", isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField("loggedAt", isLessThan:             Timestamp(date: end))
            .getDocuments()

        return snapshot.documents.compactMap { doc in
            let d = doc.data()
            guard let name     = d["name"]            as? String,
                  let duration = d["durationMinutes"] as? Int,
                  let calories = d["caloriesBurned"]  as? Int,
                  let ts       = d["loggedAt"]        as? Timestamp else { return nil }
            let wid        = d["workoutID"]          as? String ?? doc.documentID
            let typeRaw    = d["workoutType"]        as? String ?? ""
            let wType      = WorkoutType(rawValue: typeRaw) ?? .other
            let adjApplied = d["adjustmentApplied"]  as? Bool ?? false
            let rawEx      = d["exercises"]          as? [[String: Any]] ?? []
            let exercises: [Exercise] = rawEx.compactMap { e in
                guard let exName = e["name"] as? String, !exName.isEmpty else { return nil }
                let exID = (e["id"] as? String) ?? UUID().uuidString

                // New shape: sets is an array of {reps, weight, id?}
                if let setArr = e["sets"] as? [[String: Any]] {
                    let sets: [ExerciseSet] = setArr.map { sd in
                        let sid = (sd["id"] as? String) ?? UUID().uuidString
                        let reps = (sd["reps"] as? Int) ?? (sd["reps"] as? NSNumber)?.intValue ?? 1
                        let weight: Double? = {
                            if let w = sd["weight"] as? Double { return w }
                            if let w = sd["weight"] as? NSNumber { return w.doubleValue }
                            return nil
                        }()
                        return ExerciseSet(id: sid, reps: reps, weight: weight)
                    }
                    return Exercise(id: exID, name: exName, sets: sets)
                }

                // Legacy shape: sets is an Int with top-level reps/weight.
                let setCount = (e["sets"] as? Int) ?? (e["sets"] as? NSNumber)?.intValue ?? 1
                let reps     = (e["reps"] as? Int) ?? (e["reps"] as? NSNumber)?.intValue ?? 1
                let weight: Double? = {
                    if let w = e["weight"] as? Double   { return w }
                    if let w = e["weight"] as? NSNumber { return w.doubleValue }
                    return nil
                }()
                let sets = (0..<max(1, setCount)).map { _ in
                    ExerciseSet(reps: reps, weight: weight)
                }
                return Exercise(id: exID, name: exName, sets: sets)
            }
            return WorkoutEntry(workoutID: wid, name: name, workoutType: wType,
                                durationMinutes: duration, caloriesBurned: calories,
                                loggedAt: ts.dateValue(), adjustmentApplied: adjApplied,
                                exercises: exercises)
        }
        .sorted { $0.loggedAt > $1.loggedAt }
    }

    // MARK: - Delete

    func delete(workoutID: String, userID: String) async {
        guard !workoutID.isEmpty, !userID.isEmpty else { return }
        try? await db.collection("users").document(userID)
            .collection("workoutEntries").document(workoutID)
            .delete()
    }

    // MARK: - Saved Workout Templates (UserDefaults)

    var savedWorkouts: [SavedWorkout] {
        guard let data     = UserDefaults.standard.data(forKey: savedWorkoutsKey),
              let workouts = try? JSONDecoder().decode([SavedWorkout].self, from: data)
        else { return [] }
        return workouts
    }

    func addSavedWorkout(_ workout: SavedWorkout) {
        var list = savedWorkouts
        list.append(workout)
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: savedWorkoutsKey)
        }
    }

    func deleteSavedWorkout(id: String) {
        let list = savedWorkouts.filter { $0.id != id }
        if let data = try? JSONEncoder().encode(list) {
            UserDefaults.standard.set(data, forKey: savedWorkoutsKey)
        }
    }
}
