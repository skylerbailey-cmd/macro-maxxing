//
//  FuelLogService.swift
//  Wellness
//
//  Historical note: this used to be a full CRUD service for the
//  `users/{userID}/fuelLog/{date}` Firestore collection, with its own
//  photo uploads and compress helper. All of that code was superseded
//  by `FoodEntryService` (`users/{userID}/foodEntries/{entryID}`) and
//  had zero remaining callers — the singleton only stuck around because
//  HomeView and FoodLogViewModel share a `mealChangedNotification`
//  name through it as a lightweight pub/sub channel.
//
//  If you're about to add a new meal-writing path, use
//  `FoodEntryService` — it already handles compression, retries,
//  offline queuing, and sync-state surfacing.
//

import Foundation

enum FuelLogService {
    /// Posted on the main queue whenever a meal is added or deleted (today only).
    /// HomeView observes this to trigger an immediate streak/totals refresh;
    /// FoodLogViewModel posts it whenever saveEntry / deleteEntry / duplicateEntry
    /// mutate the log.
    static let mealChangedNotification = Notification.Name("FuelLogMealChanged")
}
