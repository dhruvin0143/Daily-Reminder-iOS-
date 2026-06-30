//
//  DailyReminderWidgetBundle.swift
//  DailyReminderWidget
//
//  Created by BMIIT on 03/12/25.
//

import WidgetKit
import SwiftUI

@main
struct DailyReminderWidgetBundle: WidgetBundle {
    var body: some Widget {
        DailyReminderWidget()
        DailyReminderWidgetLiveActivity()
    }
}
