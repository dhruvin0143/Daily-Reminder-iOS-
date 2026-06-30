//
//  Persistence.swift
//  dailyreminder
//
//  Created by BMIIT on 02/12/25.
//
import SwiftUI

/// Global Color System for App Themes
struct AppTheme {

    // MARK: 🌞 Light Theme (Colourful, Attractive)
    struct Light {
        static let background = LinearGradient(
            colors: [
                Color(red: 0.92, green: 0.96, blue: 1.00),  // baby blue
                Color(red: 1.00, green: 0.93, blue: 0.97),  // soft peach
                Color(red: 0.95, green: 1.00, blue: 0.90)   // mint tint
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let card = Color.white.opacity(0.65)
        static let shadow = Color.blue.opacity(0.10)
        static let textPrimary = Color(red: 0.08, green: 0.11, blue: 0.22)
        static let textSecondary = Color(red: 0.15, green: 0.20, blue: 0.35).opacity(0.7)
    }

    // MARK: 🌙 Dark Theme (Premium)
    struct Dark {
        static let background = LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.02, blue: 0.12),  // deep violet
                Color(red: 0.02, green: 0.07, blue: 0.18),  // dark navy
                Color(red: 0.04, green: 0.02, blue: 0.10)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let card = Color.white.opacity(0.12)
        static let shadow = Color.black.opacity(0.60)
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.60)
    }

    // MARK: 🔺 Priority Colors (same for both themes)
    static func priorityColor(_ priority: TaskPriority) -> Color {
        switch priority {
        case .low:
            return Color(red: 0.47, green: 0.56, blue: 0.85) // calm blue
        case .medium:
            return Color(red: 0.98, green: 0.71, blue: 0.20) // orange
        case .high:
            return Color(red: 0.95, green: 0.28, blue: 0.35) // red
        }
    }
}
