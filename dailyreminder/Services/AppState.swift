//
//  AppState.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//

import Foundation
import Combine

/// Global app state used for navigation like full-screen alerts.
final class AppState: ObservableObject {

    /// Shared singleton instance so AppDelegate can access it.
    static let shared = AppState()

    /// When non-nil, we show the full-screen high-priority alert for this task base id.
    @Published var activeAlarmTaskBaseId: String?

    private init() {}
}





