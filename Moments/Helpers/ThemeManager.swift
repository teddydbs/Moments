//
//  ThemeManager.swift
//  Moments
//
//  Gestionnaire du thème de l'application (clair/sombre/auto)
//

import SwiftUI
import Combine

/// Mode de thème de l'application
enum AppThemeMode: String, CaseIterable {
    case light = "Clair"
    case dark = "Sombre"
    case system = "Automatique"

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .system: return "circle.lefthalf.filled"
        }
    }

    /// Convertit en ColorScheme SwiftUI
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil // Utilise le thème système
        }
    }
}

/// Gestionnaire global du thème de l'application
@MainActor
class ThemeManager: ObservableObject {
    /// Instance partagée (singleton)
    static let shared = ThemeManager()

    /// Mode de thème actuel
    @Published var currentMode: AppThemeMode {
        didSet {
            // ✅ Sauvegarder la préférence dans UserDefaults
            UserDefaults.standard.set(currentMode.rawValue, forKey: "appThemeMode")
        }
    }

    private init() {
        // ✅ Charger la préférence sauvegardée ou utiliser le mode système par défaut
        if let savedMode = UserDefaults.standard.string(forKey: "appThemeMode"),
           let mode = AppThemeMode(rawValue: savedMode) {
            self.currentMode = mode
        } else {
            self.currentMode = .system
        }
    }

    /// Change le mode de thème
    func setMode(_ mode: AppThemeMode) {
        currentMode = mode
    }
}
