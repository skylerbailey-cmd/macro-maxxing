//
//  DataMigrationService.swift
//  Wellness
//
//  One-time migration of local SwiftData + UserDefaults data to Firestore.
//  Guarded by a UserDefaults flag — runs exactly once per device, then never again.
//
//  What gets migrated:
//    • FuelLogEntry (SwiftData) → users/{userID}/fuelLog/{dateString}
//    • FoodEntry    (SwiftData) → users/{userID}/macroHistory/{dateString}
//    • Fasting window (UserDefaults) → users/{userID} document fields
//

import UIKit
import SwiftData
import FirebaseFirestore
import FirebaseStorage

final class DataMigrationService {

    // MARK: - Singleton

    static let shared = DataMigrationService()
    private init() {}

    // MARK: - Private refs

    private var db:      Firestore        { FirebaseManager.shared.db }
    private var storage: StorageReference { FirebaseManager.shared.storage }

    private let migrationKey            = "localDataMigrated_v1"
    private let fastingMigrationKey     = "fastingWindowHistoryMigrated_v1"

    // MARK: - Entry Point

    /// Runs the full migration if it hasn't been completed yet.
    /// Safe to call on every launch — exits immediately once the flag is set.
    func migrateIfNeeded(userSettings: UserSettings, modelContext: ModelContext) async {
        guard !UserDefaults.standard.bool(forKey: migrationKey) else { return }
        let userID = userSettings.userID
        guard !userID.isEmpty else { return }

        print("[DataMigration] Starting local → Firestore migration for \(userID)")

        // Run the three migrations concurrently
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.migrateFuelLog(userID: userID, modelContext: modelContext) }
            group.addTask { await self.migrateMacroHistory(userID: userID, userSettings: userSettings, modelContext: modelContext) }
            group.addTask { await self.migrateFastingWindow(userID: userID) }
        }

        UserDefaults.standard.set(true, forKey: migrationKey)
        print("[DataMigration] Migration complete.")
    }

    // MARK: - Fasting Window History Entry Point

    /// Migrates existing dailyWindowSnapshots from UserDefaults into
    /// their corresponding macroHistory Firestore documents as FastingSnapshot records.
    /// Runs exactly once, independently of the main migration flag.
    func migrateFastingWindowHistoryIfNeeded(userID: String) async {
        guard !UserDefaults.standard.bool(forKey: fastingMigrationKey) else { return }
        guard !userID.isEmpty else { return }

        print("[DataMigration] Starting fasting window history migration for \(userID)")
        await migrateFastingWindow(userID: userID)
        UserDefaults.standard.set(true, forKey: fastingMigrationKey)
        print("[DataMigration] Fasting window history migration complete.")
    }

    // MARK: - 1. Fuel Log Migration (FuelLogEntry → fuelLog subcollection)

    private func migrateFuelLog(userID: String, modelContext: ModelContext) async {
        let descriptor = FetchDescriptor<FuelLogEntry>(
            sortBy: [SortDescriptor(\.loggedAt)]
        )
        guard let entries = try? modelContext.fetch(descriptor), !entries.isEmpty else {
            print("[DataMigration] No FuelLogEntry records to migrate.")
            return
        }

        // Group entries by "yyyy-MM-dd"
        var byDate: [String: [FuelLogEntry]] = [:]
        for entry in entries {
            let key = dateString(for: entry.loggedAt)
            byDate[key, default: []].append(entry)
        }

        print("[DataMigration] Migrating \(entries.count) FuelLogEntry records across \(byDate.count) days…")

        for (dateKey, dayEntries) in byDate {
            let date = dayEntries.first!.loggedAt

            // Build FuelLogMeal array, uploading photos as we go
            var meals: [FuelLogMeal] = []
            for entry in dayEntries {
                let mealID = UUID().uuidString
                var photoURL = ""

                if let imageData = entry.imageData, let image = UIImage(data: imageData) {
                    let ref      = storage.child("fuel_log/\(userID)/\(dateKey)/\(mealID).jpg")
                    let metadata = StorageMetadata()
                    metadata.contentType = "image/jpeg"
                    if let compressed = compress(image),
                       let url = try? await uploadAndGetURL(data: compressed, ref: ref, metadata: metadata) {
                        photoURL = url
                    }
                }

                let meal = FuelLogMeal(
                    mealID:    mealID,
                    foodName:  entry.foodName,
                    calories:  Int(entry.calories.rounded()),
                    protein:   entry.protein,
                    carbs:     entry.carbs,
                    fat:       entry.fat,
                    photoURL:  photoURL,
                    timestamp: entry.loggedAt
                )
                meals.append(meal)
            }

            var log = FuelLog(dateString: dateKey, date: date, meals: meals)
            log.recalculateTotals()

            do {
                let data = try log.firestoreData()
                try await db.collection("users").document(userID)
                    .collection("fuelLog").document(dateKey)
                    .setData(data, merge: true)
                print("[DataMigration] fuelLog/\(dateKey) — \(meals.count) meals")
            } catch {
                print("[DataMigration] fuelLog/\(dateKey) FAILED: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 2. Macro History Migration (FoodEntry → macroHistory subcollection)

    private func migrateMacroHistory(
        userID: String,
        userSettings: UserSettings,
        modelContext: ModelContext
    ) async {
        let descriptor = FetchDescriptor<FoodEntry>(
            sortBy: [SortDescriptor(\.loggedAt)]
        )
        guard let entries = try? modelContext.fetch(descriptor), !entries.isEmpty else {
            print("[DataMigration] No FoodEntry records to migrate.")
            return
        }

        // Read current goals from UserDefaults (best approximation for historical days)
        let goalCalories = UserDefaults.standard.double(forKey: "goalCalories").nonZero ?? 2000
        let goalProtein  = UserDefaults.standard.double(forKey: "goalProtein").nonZero  ?? 150
        let goalCarbs    = UserDefaults.standard.double(forKey: "goalCarbs").nonZero    ?? 200
        let goalFat      = UserDefaults.standard.double(forKey: "goalFat").nonZero      ?? 65

        // Group by date
        var byDate: [String: [FoodEntry]] = [:]
        for entry in entries {
            let key = dateString(for: entry.loggedAt)
            byDate[key, default: []].append(entry)
        }

        print("[DataMigration] Migrating \(entries.count) FoodEntry records across \(byDate.count) days…")

        let goalsMetDates = userSettings.goalsMetDates

        for (dateKey, dayEntries) in byDate {
            let date         = dayEntries.first!.loggedAt
            let totalCals    = dayEntries.reduce(0.0) { $0 + $1.calories }
            let totalProtein = dayEntries.reduce(0.0) { $0 + $1.protein }
            let totalCarbs   = dayEntries.reduce(0.0) { $0 + $1.carbs }
            let totalFat     = dayEntries.reduce(0.0) { $0 + $1.fat }

            let snapshot = DailyMacros(
                dateString:    dateKey,
                date:          date,
                totalCalories: Int(totalCals.rounded()),
                totalProtein:  totalProtein,
                totalCarbs:    totalCarbs,
                totalFat:      totalFat,
                goalCalories:  Int(goalCalories.rounded()),
                goalProtein:   goalProtein,
                goalCarbs:     goalCarbs,
                goalFat:       goalFat,
                mealCount:     dayEntries.count,
                // streakDay can't be reconstructed accurately from local data
                streakDay:     goalsMetDates.contains(dateKey) ? 1 : 0
            )

            do {
                let data = try snapshot.firestoreData()
                try await db.collection("users").document(userID)
                    .collection("macroHistory").document(dateKey)
                    .setData(data, merge: true)
                print("[DataMigration] macroHistory/\(dateKey) — \(dayEntries.count) entries")
            } catch {
                print("[DataMigration] macroHistory/\(dateKey) FAILED: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 3. Fasting Window Migration (UserDefaults dailyWindowSnapshots → macroHistory)

    private func migrateFastingWindow(userID: String) async {
        let enabled       = UserDefaults.standard.bool(forKey: "fastingEnabled")
        let currentHour   = UserDefaults.standard.integer(forKey: "windowStartHour")
        let currentMinute = UserDefaults.standard.integer(forKey: "windowStartMinute")
        let currentDur    = UserDefaults.standard.integer(forKey: "windowDurationHours")

        // Write current fasting settings to the user profile document
        let profileFields: [String: Any] = [
            "fastingEnabled":             enabled,
            "fastingWindowStartHour":     currentHour,
            "fastingWindowStartMinute":   currentMinute,
            "fastingWindowDurationHours": currentDur
        ]
        try? await db.collection("users").document(userID).setData(profileFields, merge: true)

        // Backfill per-day fasting snapshots from dailyWindowSnapshots into macroHistory
        guard let outer = UserDefaults.standard.dictionary(forKey: "dailyWindowSnapshots"),
              !outer.isEmpty else {
            print("[DataMigration] No dailyWindowSnapshots to migrate.")
            return
        }

        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.calendar   = Calendar.current
        let cal = Calendar.current

        var count = 0
        for (dateKey, value) in outer {
            guard let inner   = value as? [String: Any],
                  let date    = fmt.date(from: dateKey),
                  let sHour   = (inner["startHour"]     as? NSNumber).map({ $0.intValue }),
                  let sMin    = (inner["startMinute"]   as? NSNumber).map({ $0.intValue }),
                  let dur     = (inner["durationHours"] as? NSNumber).map({ $0.intValue })
            else { continue }

            let startOfDay     = cal.startOfDay(for: date)
            let windowStart    = startOfDay.addingTimeInterval(Double(sHour) * 3600 + Double(sMin) * 60)
            let windowEnd      = windowStart.addingTimeInterval(Double(dur) * 3600)

            let snapshot = FastingSnapshot(
                fastingEnabled:      enabled,
                windowStartTime:     Timestamp(date: windowStart),
                windowEndTime:       Timestamp(date: windowEnd),
                windowDurationHours: Double(dur),
                fastingHours:        24.0 - Double(dur),
                firstMealTime:       nil,
                lastMealTime:        nil,
                mealsWithinWindow:   0,
                mealsOutsideWindow:  0,
                isCompleted:         false,
                isLocked:            true   // all migrated past days are locked
            )

            do {
                let encoded = try Firestore.Encoder().encode(snapshot)
                try await db.collection("users").document(userID)
                    .collection("macroHistory").document(dateKey)
                    .setData(["fasting": encoded], merge: true)
                count += 1
            } catch {
                print("[DataMigration] fastingWindow/\(dateKey) FAILED: \(error.localizedDescription)")
            }
        }
        print("[DataMigration] Migrated fasting snapshots for \(count) past day(s)")
    }

    // MARK: - Private Helpers

    private func dateString(for date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.calendar   = Calendar.current
        return fmt.string(from: date)
    }

    private func uploadAndGetURL(
        data: Data,
        ref: StorageReference,
        metadata: StorageMetadata
    ) async throws -> String {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            ref.putData(data, metadata: metadata) { _, error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }
        let url = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
            ref.downloadURL { url, error in
                if let error { cont.resume(throwing: error) }
                else if let url { cont.resume(returning: url) }
                else { cont.resume(throwing: URLError(.badURL)) }
            }
        }
        return url.absoluteString
    }

    private func compress(_ image: UIImage, targetBytes: Int = 600_000) -> Data? {
        let steps: [CGFloat] = [0.85, 0.75, 0.65, 0.55, 0.45, 0.35, 0.20]
        for q in steps {
            if let data = image.jpegData(compressionQuality: q), data.count <= targetBytes { return data }
        }
        guard let oversized = image.jpegData(compressionQuality: 0.20) else { return nil }
        let ratio   = sqrt(Double(targetBytes) / Double(oversized.count))
        let newSize = CGSize(width: (image.size.width * ratio).rounded(),
                             height: (image.size.height * ratio).rounded())
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized  = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: 0.85)
    }
}

// MARK: - Double helper

private extension Double {
    /// Returns self if > 0, otherwise nil.
    var nonZero: Double? { self > 0 ? self : nil }
}
