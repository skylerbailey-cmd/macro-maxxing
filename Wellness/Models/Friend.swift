//
//  Friend.swift
//  Wellness
//

import Foundation
import SwiftData

@Model final class Friend {
    var id:          UUID   = UUID()
    var userID:      String = ""   // their unique app user ID
    var username:    String = ""   // their @handle
    var displayName: String = ""
    var addedAt:     Date   = Date()

    init(userID: String = "", username: String, displayName: String) {
        self.userID      = userID
        self.username    = username
        self.displayName = displayName
        self.addedAt     = Date()
    }
}
