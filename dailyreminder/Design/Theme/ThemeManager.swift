//
//  Persistence.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import SwiftUI

/// Controls whether the app uses Light or Dark theme
class ThemeManager: ObservableObject {

    enum ThemeMode: String, CaseIterable, Identifiable {
        case light
        case dark
        var id: String { self.rawValue }
    }

    // Default → DARK
    @AppStorage("selectedTheme") private var savedTheme: String = ThemeMode.dark.rawValue

    @Published var mode: ThemeMode = .dark {
        didSet { savedTheme = mode.rawValue }
    }

    static let shared = ThemeManager()

    private init() {
        mode = ThemeMode(rawValue: savedTheme) ?? .dark
    }

    /// Return whether dark UI must be used
    var isDarkNow: Bool {
        mode == .dark
    }
}
