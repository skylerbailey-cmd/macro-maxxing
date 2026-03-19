//
//  FuelLogService.swift
//  Wellness
//
//  Manages the Firestore fuel log subcollection and keeps MacroHistoryService in sync.
//  Document path: users/{userID}/fuelLog/{dateString}
//  Photo path:    fuel_log/{userID}/{dateString}/{mealID}.jpg
//

import UIKit
import FirebaseFirestore
import FirebaseStorage

final class FuelLogService {

    // MARK: - Singleton

    static let shared = FuelLogService()
    private init() {}

    /// Posted on the main queue whenever a meal is added or deleted (today only).
    /// HomeView observes this to trigger an immediate streak/totals refresh.
    static let mealChangedNotification = Notification.Name("FuelLogMealChanged")

    // MARK: - Private refs

    private var db:      Firestore        { FirebaseManager.shared.db }
    private var storage: StorageReference { FirebaseManager.shared.storage }

    // MARK: - Errors

    enum FuelLogError: LocalizedError {
        case logNotFound
        case mealNotFound
        case imageCompressionFailed

        var errorDescription: String? {
            switch self {
            case .logNotFound:            return "No fuel log found for that date."
            case .mealNotFound:           return "Meal not found in the fuel log."
            case .imageCompressionFailed: return "Could not compress the meal photo."
            }
        }
    }

    // MARK: - Path Helpers

    private func logCollection(userID: String) -> CollectionReference {
        db.collection("users").document(userID).collection("fuelLog")
    }

    private func logDocument(userID: String, dateString: String) -> DocumentReference {
        logCollection(userID: userID).document(dateString)
    }

    static func dateString(for date: Date = Date()) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.calendar   = Calendar.current
        return fmt.string(from: date)
    }

    // MARK: - 1. Add Meal

    /// Adds a meal to today's fuel log, uploading the photo to Storage first if provided.
    /// Creates the daily document if it doesn't exist yet.
    /// Automatically recalculates totals and syncs macro history.
    ///
    /// - Returns: The saved `FuelLogMeal` (with photoURL populated if a photo was uploaded).
    @discardableResult
    func addMeal(
        userID:       String,
        foodName:     String,
        calories:     Int,
        protein:      Double,
        carbs:        Double,
        fat:          Double,
        photo:        UIImage?    = nil,
        goalCalories: Double      = 0,
        goalProtein:  Double      = 0,
        goalCarbs:    Double      = 0,
        goalFat:      Double      = 0,
        streakDay:    Int         = 0
    ) async throws -> FuelLogMeal {
        guard !userID.isEmpty else { throw FuelLogError.logNotFound }

        let today      = Date()
        let dateKey    = Self.dateString(for: today)
        let docRef     = logDocument(userID: userID, dateString: dateKey)
        let mealID     = UUID().uuidString

        // 1. Upload photo if provided
        var photoURL = ""
        if let photo {
            photoURL = (try? await uploadMealPhoto(photo, userID: userID, dateString: dateKey, mealID: mealID)) ?? ""
        }

        // 2. Build the meal
        let meal = FuelLogMeal(
            mealID:   mealID,
            foodName: foodName,
            calories: calories,
            protein:  protein,
            carbs:    carbs,
            fat:      fat,
            photoURL: photoURL
        )

        // 3. Read existing log (or create a blank one)
        let existingDoc = try? await docRef.getDocument()
        var log: FuelLog
        if let existingDoc, let decoded = FuelLog(document: existingDoc) {
            log = decoded
        } else {
            log = FuelLog(dateString: dateKey, date: today)
        }

        // 4. Append meal, recalculate totals, write back
        log.meals.append(meal)
        log.recalculateTotals()

        let data = try log.firestoreData()
        try await docRef.setData(data)
        print("[FuelLogService] Added meal '\(foodName)' to \(dateKey) (\(log.meals.count) meals total)")

        // 5. Keep macro history in sync
        syncMacroHistory(log: log, userID: userID,
                         goalCalories: goalCalories, goalProtein: goalProtein,
                         goalCarbs: goalCarbs, goalFat: goalFat, streakDay: streakDay)

        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Self.mealChangedNotification, object: nil)
        }
        return meal
    }

    // MARK: - 2. Delete Meal

    /// Removes a meal from the fuel log for `date` (defaults to today).
    /// Recalculates totals and syncs macro history.
    func deleteMeal(
        userID:       String,
        date:         Date   = Date(),
        mealID:       String,
        goalCalories: Double = 0,
        goalProtein:  Double = 0,
        goalCarbs:    Double = 0,
        goalFat:      Double = 0,
        streakDay:    Int    = 0
    ) async throws {
        guard !userID.isEmpty else { return }

        let dateKey = Self.dateString(for: date)
        let docRef  = logDocument(userID: userID, dateString: dateKey)

        // 1. Fetch existing log
        let snapshot = try await docRef.getDocument()
        guard var log = FuelLog(document: snapshot) else { throw FuelLogError.logNotFound }

        // 2. Find and remove the meal
        let before = log.meals.count
        log.meals.removeAll { $0.mealID == mealID }
        guard log.meals.count < before else { throw FuelLogError.mealNotFound }

        // 3. Delete the meal photo from Storage (best-effort)
        Task {
            let photoRef = storage.child("fuel_log/\(userID)/\(dateKey)/\(mealID).jpg")
            try? await photoRef.delete()
        }

        // 4. Recalculate totals and write back
        log.recalculateTotals()
        let data = try log.firestoreData()
        try await docRef.setData(data)
        print("[FuelLogService] Deleted meal \(mealID) from \(dateKey) (\(log.meals.count) meals remaining)")

        // 5. Sync macro history (only meaningful for today)
        let isToday = Calendar.current.isDateInToday(date)
        if isToday {
            syncMacroHistory(log: log, userID: userID,
                             goalCalories: goalCalories, goalProtein: goalProtein,
                             goalCarbs: goalCarbs, goalFat: goalFat, streakDay: streakDay)
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Self.mealChangedNotification, object: nil)
            }
        }
    }

    // MARK: - 3. Fetch Today's Log

    /// Fetches the fuel log document for today.
    /// Returns nil if no meals have been logged yet today.
    func fetchTodaysLog(userID: String) async throws -> FuelLog? {
        return try await fetchLog(userID: userID, date: Date())
    }

    // MARK: - 4. Fetch Log for Date

    /// Fetches the fuel log document for a specific date.
    /// Returns nil if no document exists for that date.
    func fetchLog(userID: String, date: Date) async throws -> FuelLog? {
        guard !userID.isEmpty else { return nil }
        let dateKey  = Self.dateString(for: date)
        let snapshot = try await logDocument(userID: userID, dateString: dateKey).getDocument()
        return FuelLog(document: snapshot)
    }

    // MARK: - Private: Macro History Sync

    /// Calls MacroHistoryService.updateTodaysMacros with the log's current totals.
    /// Fire-and-forget — runs in a detached Task so it never blocks the caller.
    private func syncMacroHistory(
        log:          FuelLog,
        userID:       String,
        goalCalories: Double,
        goalProtein:  Double,
        goalCarbs:    Double,
        goalFat:      Double,
        streakDay:    Int
    ) {
        MacroHistoryService.shared.updateTodaysMacros(
            userID:        userID,
            totalCalories: Double(log.totalCalories),
            totalProtein:  log.totalProtein,
            totalCarbs:    log.totalCarbs,
            totalFat:      log.totalFat,
            goalCalories:  goalCalories,
            goalProtein:   goalProtein,
            goalCarbs:     goalCarbs,
            goalFat:       goalFat,
            mealCount:     log.meals.count,
            streakDay:     streakDay
        )
    }

    // MARK: - Private: Photo Upload

    private func uploadMealPhoto(
        _ image: UIImage,
        userID: String,
        dateString: String,
        mealID: String
    ) async throws -> String {
        guard let data = compress(image) else { throw FuelLogError.imageCompressionFailed }

        let ref      = storage.child("fuel_log/\(userID)/\(dateString)/\(mealID).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            ref.putData(data, metadata: metadata) { _, error in
                if let error { cont.resume(throwing: error) } else { cont.resume() }
            }
        }

        let url = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
            ref.downloadURL { url, error in
                if let error { cont.resume(throwing: error) }
                else if let url { cont.resume(returning: url) }
                else { cont.resume(throwing: FuelLogError.logNotFound) }
            }
        }

        print("[FuelLogService] Meal photo uploaded: \(url)")
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
