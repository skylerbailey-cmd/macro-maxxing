//
//  WellnessWidgetsLiveActivity.swift
//  WellnessWidgets
//
//  Created by Skyler Bailey on 4/17/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct WellnessWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct WellnessWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WellnessWidgetsAttributes.self) { context in
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

extension WellnessWidgetsAttributes {
    fileprivate static var preview: WellnessWidgetsAttributes {
        WellnessWidgetsAttributes(name: "World")
    }
}

extension WellnessWidgetsAttributes.ContentState {
    fileprivate static var smiley: WellnessWidgetsAttributes.ContentState {
        WellnessWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: WellnessWidgetsAttributes.ContentState {
         WellnessWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: WellnessWidgetsAttributes.preview) {
   WellnessWidgetsLiveActivity()
} contentStates: {
    WellnessWidgetsAttributes.ContentState.smiley
    WellnessWidgetsAttributes.ContentState.starEyes
}
