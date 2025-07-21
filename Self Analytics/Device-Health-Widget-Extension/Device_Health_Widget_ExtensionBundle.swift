//
//  Device_Health_Widget_ExtensionBundle.swift
//  Device-Health-Widget-Extension
//
//  Created by Israel Manzo on 7/21/25.
//

import WidgetKit
import SwiftUI

@main
struct Device_Health_Widget_ExtensionBundle: WidgetBundle {
    var body: some Widget {
        Device_Health_Widget_Extension()
        Device_Health_Widget_ExtensionControl()
        Device_Health_Widget_ExtensionLiveActivity()
    }
}
