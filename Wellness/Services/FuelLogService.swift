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

        // 3-4. Atomically read-modify-write inside a transaction so
        //       concurrent addMeal / deleteMeal calls don't corrupt LevelDB.
        let mealCount: Int = try await db.runTransaction { transaction, errorPointer in
            let existingDoc = try? transaction.getDocument(docRef)
            var log: FuelLog
            if let existingDoc, let decoded = FuelLog(document: existingDoc) {
                log = decoded
            } else {
                log = FuelLog(dateString: dateKey, date: today)
            }

            log.meals.append(meal)
            log.recalculateTotals()

            do {
                let data = try log.firestoreData()
                transaction.setData(data, forDocument: docRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return 0
            }
            return log.meals.count
        } as! Int
        AppLogger.log("[FuelLogService] Added meal '\(foodName)' to \(dateKey) (\(mealCount) meals total)")

        // Notify HomeView so it recalculates totals and syncs macro history in one place.
        // (No direct syncMacroHistory call here — HomeView.loadTodayTotals handles it.)
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

        // 1-4. Atomically read-modify-write inside a transaction so
        //       concurrent addMeal / deleteMeal calls don't corrupt LevelDB.
        let remaining: Int = try await db.runTransaction { transaction, errorPointer in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(docRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return -1
            }
            guard var log = FuelLog(document: snapshot) else {
                errorPointer?.pointee = FuelLogError.logNotFound as NSError
                return -1
            }

            let before = log.meals.count
            log.meals.removeAll { $0.mealID == mealID }
            guard log.meals.count < before else {
                errorPointer?.pointee = FuelLogError.mealNotFound as NSError
                return -1
            }

            log.recalculateTotals()
            do {
                let data = try log.firestoreData()
                transaction.setData(data, forDocument: docRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return -1
            }
            return log.meals.count
        } as! Int

        // Delete the meal photo from Storage (best-effort, outside transaction)
        Task {
            let photoRef = storage.child("fuel_log/\(userID)/\(dateKey)/\(mealID).jpg")
            try? await photoRef.delete()
        }
        AppLogger.log("[FuelLogService] Deleted meal \(mealID) from \(dateKey) (\(remaining) meals remaining)")

        // Notify HomeView so it recalculates totals and syncs macro history in one place.
        let isToday = Calendar.current.isDateInToday(date)
        if isToday {
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

        AppLogger.log("[FuelLogService] Meal photo uploaded: \(url)")
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
