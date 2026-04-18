//
//  Log_WorkoutLiveActivity.swift
//  Log Workout
//
//  Created by Skyler Bailey on 4/17/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Log_WorkoutAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct Log_WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Log_WorkoutAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension Log_WorkoutAttributes {
    fileprivate static var preview: Log_WorkoutAttributes {
        Log_WorkoutAttributes(name: "World")
    }
}

extension Log_WorkoutAttributes.ContentState {
    fileprivate static var smiley: Log_WorkoutAttributes.ContentState {
        Log_WorkoutAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Log_WorkoutAttributes.ContentState {
         Log_WorkoutAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Log_WorkoutAttributes.preview) {
   Log_WorkoutLiveActivity()
} contentStates: {
    Log_WorkoutAttributes.ContentState.smiley
    Log_WorkoutAttributes.ContentState.starEyes
}
