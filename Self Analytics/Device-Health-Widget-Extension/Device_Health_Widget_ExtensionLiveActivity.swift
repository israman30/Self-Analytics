//
//  Device_Health_Widget_ExtensionLiveActivity.swift
//  Device-Health-Widget-Extension
//
//  Created by Israel Manzo on 7/21/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct Device_Health_Widget_ExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct Device_Health_Widget_ExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: Device_Health_Widget_ExtensionAttributes.self) { context in
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

extension Device_Health_Widget_ExtensionAttributes {
    fileprivate static var preview: Device_Health_Widget_ExtensionAttributes {
        Device_Health_Widget_ExtensionAttributes(name: "World")
    }
}

extension Device_Health_Widget_ExtensionAttributes.ContentState {
    fileprivate static var smiley: Device_Health_Widget_ExtensionAttributes.ContentState {
        Device_Health_Widget_ExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: Device_Health_Widget_ExtensionAttributes.ContentState {
         Device_Health_Widget_ExtensionAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: Device_Health_Widget_ExtensionAttributes.preview) {
   Device_Health_Widget_ExtensionLiveActivity()
} contentStates: {
    Device_Health_Widget_ExtensionAttributes.ContentState.smiley
    Device_Health_Widget_ExtensionAttributes.ContentState.starEyes
}
