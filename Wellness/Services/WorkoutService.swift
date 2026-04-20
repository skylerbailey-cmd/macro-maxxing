//
//  WorkoutService.swift
//  Wellness
//
//  Firestore: users/{userID}/workoutEntries/{workoutID}
//  Saved workout templates: users/{userID}/savedWorkouts/{workoutID}
//

import Foundation
import FirebaseFirestore

final class WorkoutService {

    static let shared = WorkoutService()
    private init() {}

    /// Post this after a successful save so the Duel tab can reload.
    static let workoutSavedNotification = Notification.Name("com.sbailey.Wellness.workoutSaved")
    /// Post this after a saved workout template is added/updated/deleted so
    /// other views (LogWorkoutSheet, WorkoutRoutinesView) can refresh.
    static let savedWorkoutTemplatesChanged = Notification.Name("com.sbailey.Wellness.savedWorkoutTemplatesChanged")

    private var db: Firestore { FirebaseManager.shared.db }

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
        var data: [String: Any] = [
            "workoutID":          entry.workoutID,
            "name":               entry.name,
            "workoutType":        entry.workoutType.rawValue,
            "durationMinutes":    entry.durationMinutes,
            "caloriesBurned":     entry.caloriesBurned,
            "loggedAt":           Timestamp(date: entry.loggedAt),
            "adjustmentApplied":  entry.adjustmentApplied,
            "exercises":          exerciseDicts
        ]
        // Tagged gym/location (optional) — only written when the user
        // actually tagged one, so older docs stay small and untagged.
        if let loc = entry.location, loc.isValid {
            data["gymName"]      = loc.name
            data["gymAddress"]   = loc.address
            data["gymLatitude"]  = loc.latitude
            data["gymLongitude"] = loc.longitude
        }
        // Tagged friends — stored as an array of flat dicts. Skipped
        // when empty so we don't bloat untagged workouts.
        if !entry.taggedFriends.isEmpty {
            data["taggedFriends"] = entry.taggedFriends.map {
                [
                    "userID":      $0.userID,
                    "username":    $0.username,
                    "displayName": $0.displayName
                ]
            }
        }
        try await db.collection("users").document(userID)
            .collection("workoutEntries").document(entry.workoutID)
            .setData(data)

        NotificationCenter.default.post(name: Self.workoutSavedNotification, object: nil)
    }

    // MARK: - Fetch

    func fetch(userID: String, date: Date) async throws -> [WorkoutEntry] {
        let cal   = Calendar.current
        let start = cal.startOfDay(for: date)
        let end   = cal.date(byAdding: .day, value: 1, to: start)!
        return try await fetchRange(userID: userID, from: start, to: end)
    }

    /// Fetches all workouts in `[start, end)` for the user, sorted most-recent
    /// first. Used by the Hub tab's workouts card to build weekly aggregates.
    func fetchRange(userID: String, from start: Date, to end: Date) async throws -> [WorkoutEntry] {
        guard !userID.isEmpty else { return [] }

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
            // Optional tagged gym — absent from older docs, so every field is tolerated.
            let gymName = (d["gymName"] as? String) ?? ""
            let location: WorkoutLocation? = {
                guard !gymName.isEmpty else { return nil }
                let addr = (d["gymAddress"] as? String) ?? ""
                let lat: Double = {
                    if let v = d["gymLatitude"]  as? Double   { return v }
                    if let v = d["gymLatitude"]  as? NSNumber { return v.doubleValue }
                    return 0
                }()
                let lng: Double = {
                    if let v = d["gymLongitude"] as? Double   { return v }
                    if let v = d["gymLongitude"] as? NSNumber { return v.doubleValue }
                    return 0
                }()
                return WorkoutLocation(name: gymName, address: addr,
                                       latitude: lat, longitude: lng)
            }()

            // Tagged friends — tolerated if missing (older docs).
            let rawTags = (d["taggedFriends"] as? [[String: Any]]) ?? []
            let taggedFriends: [TaggedFriend] = rawTags.compactMap { dict in
                guard let userID = dict["userID"] as? String, !userID.isEmpty else { return nil }
                return TaggedFriend(
                    userID:      userID,
                    username:    (dict["username"]    as? String) ?? "",
                    displayName: (dict["displayName"] as? String) ?? ""
                )
            }

            return WorkoutEntry(workoutID: wid, name: name, workoutType: wType,
                                durationMinutes: duration, caloriesBurned: calories,
                                loggedAt: ts.dateValue(), adjustmentApplied: adjApplied,
                                exercises: exercises, location: location,
                                taggedFriends: taggedFriends)
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

    // MARK: - Saved Workout Templates (Firestore)

    private func savedWorkoutsRef(userID: String) -> CollectionReference {
        db.collection("users").document(userID).collection("savedWorkouts")
    }

    func fetchSavedWorkouts(userID: String) async -> [SavedWorkout] {
        guard !userID.isEmpty else { return [] }
        do {
            let snapshot = try await savedWorkoutsRef(userID: userID)
                .getDocuments(source: .default)
            let results = snapshot.documents.compactMap { decodeSavedWorkout($0) }
            AppLogger.log("[WorkoutService] fetchSavedWorkouts: \(results.count) found for \(userID)")
            return results
        } catch {
            AppLogger.log("[WorkoutService] Failed to fetch saved workouts: \(error.localizedDescription)")
            return []
        }
    }

    func addSavedWorkout(_ workout: SavedWorkout, userID: String) async {
        guard !userID.isEmpty else { return }
        do {
            try await savedWorkoutsRef(userID: userID).document(workout.id)
                .setData(encodeSavedWorkout(workout))
            AppLogger.log("[WorkoutService] addSavedWorkout succeeded: \(workout.name) (\(workout.id))")
        } catch {
            AppLogger.log("[WorkoutService] addSavedWorkout FAILED: \(error.localizedDescription)")
        }
        NotificationCenter.default.post(name: Self.savedWorkoutTemplatesChanged, object: nil)
    }

    func updateSavedWorkout(_ workout: SavedWorkout, userID: String) async {
        guard !userID.isEmpty else { return }
        try? await savedWorkoutsRef(userID: userID).document(workout.id)
            .setData(encodeSavedWorkout(workout))
        NotificationCenter.default.post(name: Self.savedWorkoutTemplatesChanged, object: nil)
    }

    func deleteSavedWorkout(id: String, userID: String) async {
        guard !id.isEmpty, !userID.isEmpty else { return }
        try? await savedWorkoutsRef(userID: userID).document(id).delete()
        NotificationCenter.default.post(name: Self.savedWorkoutTemplatesChanged, object: nil)
    }

    private func encodeSavedWorkout(_ w: SavedWorkout) -> [String: Any] {
        let exerciseDicts: [[String: Any]] = w.exercises.map { ex in
            let setDicts: [[String: Any]] = ex.sets.map { s in
                var sd: [String: Any] = ["id": s.id, "reps": s.reps]
                if let wt = s.weight { sd["weight"] = wt }
                return sd
            }
            return ["id": ex.id, "name": ex.name, "sets": setDicts]
        }
        return [
            "id":              w.id,
            "name":            w.name,
            "workoutType":     w.workoutType.rawValue,
            "durationMinutes": w.durationMinutes,
            "caloriesBurned":  w.caloriesBurned,
            "exercises":       exerciseDicts
        ]
    }

    private func decodeSavedWorkout(_ doc: QueryDocumentSnapshot) -> SavedWorkout? {
        let d = doc.data()
        guard let name = d["name"] as? String else { return nil }
        let id           = (d["id"] as? String) ?? doc.documentID
        let typeRaw      = (d["workoutType"] as? String) ?? ""
        let wType        = WorkoutType(rawValue: typeRaw) ?? .other
        let duration     = (d["durationMinutes"] as? Int) ?? (d["durationMinutes"] as? NSNumber)?.intValue ?? 0
        let calories     = (d["caloriesBurned"] as? Int) ?? (d["caloriesBurned"] as? NSNumber)?.intValue ?? 0
        let rawEx        = (d["exercises"] as? [[String: Any]]) ?? []
        let exercises: [Exercise] = rawEx.compactMap { e in
            guard let exName = e["name"] as? String, !exName.isEmpty else { return nil }
            let exID = (e["id"] as? String) ?? UUID().uuidString
            if let setArr = e["sets"] as? [[String: Any]] {
                let sets: [ExerciseSet] = setArr.map { sd in
                    let sid  = (sd["id"] as? String) ?? UUID().uuidString
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
            return Exercise(id: exID, name: exName, sets: [])
        }
        return SavedWorkout(id: id, name: name, workoutType: wType,
                            durationMinutes: duration, caloriesBurned: calories,
                            exercises: exercises)
    }

    /// One-time migration: moves saved workout templates from UserDefaults to
    /// Firestore so they sync across devices. Call once at app launch; it's a
    /// no-op if UserDefaults is empty or the user is logged out.
    func migrateUserDefaultsToFirestore(userID: String) {
        guard !userID.isEmpty else { return }
        let key = "savedWorkoutTemplates"
        guard let data = UserDefaults.standard.data(forKey: key),
              let workouts = try? JSONDecoder().decode([SavedWorkout].self, from: data),
              !workouts.isEmpty
        else { return }
        // Fire-and-forget migration writes — don't need to await each one
        for w in workouts {
            savedWorkoutsRef(userID: userID).document(w.id)
                .setData(encodeSavedWorkout(w))
        }
        UserDefaults.standard.removeObject(forKey: key)
    }

    // MARK: - Workout Routines (Firestore)

    private func encodeDays(_ days: [PlanDay]) -> [[String: Any]] {
        days.map { ["id": $0.id, "label": $0.label, "itemIDs": $0.itemIDs] }
    }

    private func decodeDays(_ raw: [[String: Any]]) -> [PlanDay] {
        raw.compactMap { d in
            guard let id    = d["id"]    as? String,
                  let label = d["label"] as? String else { return nil }
            let ids = d["itemIDs"] as? [String] ?? []
            return PlanDay(id: id, label: label, itemIDs: ids)
        }
    }

    func fetchRoutines(userID: String) async -> [WorkoutRoutine] {
        guard !userID.isEmpty else { return [] }
        do {
            let snapshot = try await db.collection("users").document(userID)
                .collection("workoutRoutines")
                .order(by: "createdAt", descending: false)
                .getDocuments()
            return snapshot.documents.compactMap { doc in
                let d = doc.data()
                guard let name = d["name"] as? String else { return nil }
                let createdAt = (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()

                // Parse days array; fall back to legacy flat workoutIDs
                var days: [PlanDay]
                if let rawDays = d["days"] as? [[String: Any]] {
                    days = decodeDays(rawDays)
                } else if let flat = d["workoutIDs"] as? [String], !flat.isEmpty {
                    days = [PlanDay(label: "Day 1", itemIDs: flat)]
                } else {
                    days = []
                }

                return WorkoutRoutine(id: doc.documentID, name: name,
                                      days: days, createdAt: createdAt)
            }
        } catch {
            AppLogger.log("[WorkoutService] Failed to fetch routines: \(error.localizedDescription)")
            return []
        }
    }

    func addRoutine(_ routine: WorkoutRoutine, userID: String) {
        guard !userID.isEmpty else { return }
        let data: [String: Any] = [
            "name":      routine.name,
            "days":      encodeDays(routine.days),
            "createdAt": Timestamp(date: routine.createdAt)
        ]
        db.collection("users").document(userID)
            .collection("workoutRoutines").document(routine.id)
            .setData(data)
    }

    func updateRoutine(_ routine: WorkoutRoutine, userID: String) {
        guard !userID.isEmpty else { return }
        let data: [String: Any] = [
            "name": routine.name,
            "days": encodeDays(routine.days),
        ]
        db.collection("users").document(userID)
            .collection("workoutRoutines").document(routine.id)
            .updateData(data)
    }

    func deleteRoutine(id: String, userID: String) {
        guard !userID.isEmpty, !id.isEmpty else { return }
        db.collection("users").document(userID)
            .collection("workoutRoutines").document(id)
            .delete()
    }
}
