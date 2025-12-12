//
//  AddToWishlistIntent.swift
//  Moments
//
//  Description: App Intent pour ajouter un produit à la wishlist depuis les Actions iOS
//  Architecture: AppIntent (iOS 16+)
//

import AppIntents
import SwiftUI

/// Intent pour ajouter un produit à la wishlist depuis les Actions iOS
@available(iOS 16.0, *)
struct AddToWishlistIntent: AppIntent {

    static var title: LocalizedStringResource = "Ajouter à Moments"
    static var description = IntentDescription("Ajouter rapidement un produit à votre wishlist Moments")

    // Icône qui apparaîtra dans les Actions
    static var openAppWhenRun: Bool = true

    /// URL du produit à ajouter
    @Parameter(title: "URL du produit")
    var productURL: String?

    /// Exécute l'intent
    @MainActor
    func perform() async throws -> some IntentResult {
        // L'app s'ouvre automatiquement grâce à openAppWhenRun = true
        // On pourrait aussi utiliser les URL Schemes pour ouvrir directement la vue d'ajout

        return .result()
    }
}

/// Configuration de l'App Shortcut
@available(iOS 16.0, *)
struct MomentsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddToWishlistIntent(),
            phrases: [
                "Ajouter à \(.applicationName)",
                "Ajouter un produit à \(.applicationName)",
                "Sauvegarder dans \(.applicationName)"
            ],
            shortTitle: "Ajouter à Moments",
            systemImageName: "gift.fill"
        )
    }
}
