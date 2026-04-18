//
//  Log_WorkoutBundle.swift
//  Log Workout
//
//  Created by Skyler Bailey on 4/17/26.
//

import WidgetKit
import SwiftUI

@main
struct Log_WorkoutBundle: WidgetBundle {
    var body: some Widget {
        Log_Workout()
        Log_WorkoutControl()
        Log_WorkoutLiveActivity()
    }
}
