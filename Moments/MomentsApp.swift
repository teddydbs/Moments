//
//  MomentsApp.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import SwiftUI
import SwiftData

@main
struct MomentsApp: App {
    @StateObject private var authManager = AuthManager.shared

    // Container SwiftData
    var modelContainer: ModelContainer = {
        let schema = Schema([
            // Nouveaux modèles (architecture correcte)
            AppUser.self,
            Contact.self,
            MyEvent.self,
            WishlistItem.self,
            Invitation.self,
            // Anciens modèles (à migrer progressivement)
            Event.self,
            Participant.self,
            GiftIdea.self
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])

            // Créer des données de test au premier lancement
            Task { @MainActor in
                SampleData.createSampleData(in: container)
            }

            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if authManager.isAuthenticated {
                MainTabView()
                    .environmentObject(authManager)
            } else {
                LoginView()
                    .environmentObject(authManager)
            }
        }
        .modelContainer(modelContainer)
    }
}
