//
//  MomentsApp.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import SwiftUI
import SwiftData
import Supabase
import Auth

@main
struct MomentsApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @State private var deepLinkManager = DeepLinkManager.shared

    // Container SwiftData
    var modelContainer: ModelContainer = {
        let schema = Schema([
            // Nouveaux modèles (architecture correcte)
            AppUser.self,
            Contact.self,
            MyEvent.self,
            WishlistItem.self,
            Invitation.self,
            EventPhoto.self,
            UserProfile.self, // ✅ Profil utilisateur
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
            Group {
                if authManager.isAuthenticated {
                    // ✅ Vérifier si l'utilisateur a complété l'onboarding
                    if let profile = authManager.userProfile, profile.onboardingCompleted {
                        // Onboarding complété, afficher l'app principale
                        MainTabView()
                            .environmentObject(authManager)
                            .task {
                                // ✅ Initialiser le ProfileManager
                                authManager.setupProfileManager(modelContext: modelContainer.mainContext)
                                // ✅ Synchronisation automatique au lancement
                                await performInitialSync()
                            }
                    } else {
                        // Onboarding non complété, afficher l'onboarding
                        OnboardingView()
                            .environmentObject(authManager)
                            .task {
                                // ✅ Initialiser le ProfileManager
                                authManager.setupProfileManager(modelContext: modelContainer.mainContext)
                            }
                    }
                } else {
                    LoginView()
                        .environmentObject(authManager)
                        .task {
                            // ✅ Initialiser le ProfileManager même en mode non authentifié
                            authManager.setupProfileManager(modelContext: modelContainer.mainContext)
                        }
                }
            }
            // ✅ Application du thème choisi par l'utilisateur (clair/sombre/automatique)
            .preferredColorScheme(themeManager.currentMode.colorScheme)
            // 🇫🇷 Forcer la locale en français pour tous les calendriers et dates
            .environment(\.locale, Locale(identifier: "fr_FR"))
            // ✅ Gérer les deep links et OAuth callbacks
            .onOpenURL { url in
                handleIncomingURL(url)
            }
            .environment(deepLinkManager)
        }
        .modelContainer(modelContainer)
    }

    // MARK: - URL Handling

    /// Gère les URLs entrantes (deep links + OAuth callbacks)
    /// - Parameter url: L'URL reçue
    private func handleIncomingURL(_ url: URL) {
        print("📱 URL reçue: \(url.absoluteString)")
        print("📱 Scheme: \(url.scheme ?? "nil"), Host: \(url.host ?? "nil")")

        // ✅ Vérifier si c'est un callback OAuth Supabase
        if url.scheme == "com.supabase.ksbsvscfplmokacngouo" {
            print("🔐 OAuth callback détecté")

            // Vérifier que c'est bien un callback de login
            if url.host == "login-callback" || url.path.contains("callback") {
                Task {
                    do {
                        // Gérer le callback OAuth
                        print("🔐 Traitement du callback OAuth avec Supabase...")
                        try await SupabaseManager.shared.client.auth.session(from: url)

                        // Vérifier l'authentification
                        await SupabaseManager.shared.checkAuthStatus()

                        // ✅ Charger les informations utilisateur
                        await authManager.loadUserFromSupabase()

                        print("✅ OAuth callback traité avec succès")
                    } catch {
                        print("❌ Erreur lors du traitement du callback OAuth: \(error)")
                        print("❌ Error details: \(error.localizedDescription)")
                    }
                }
                return
            }
        }

        // ✅ Sinon, gérer comme un deep link normal
        if let eventId = deepLinkManager.handleIncomingURL(url) {
            deepLinkManager.setEventToOpen(eventId)
        }
    }

    // MARK: - Sync

    /// Synchronisation initiale au lancement de l'app
    private func performInitialSync() async {
        // Vérifier si l'utilisateur est authentifié avec Supabase
        guard SupabaseManager.shared.isAuthenticated else {
            print("ℹ️ Utilisateur non authentifié avec Supabase, skip sync")
            return
        }

        print("🔄 Démarrage de la synchronisation initiale...")

        do {
            // Créer le SyncManager avec le ModelContext
            let syncManager = SyncManager(modelContext: modelContainer.mainContext)

            // Lancer la synchronisation complète
            try await syncManager.performFullSync()

            print("✅ Synchronisation initiale terminée avec succès")
        } catch {
            print("❌ Erreur lors de la synchronisation initiale: \(error)")
            // Ne pas bloquer l'app si la sync échoue (offline-first)
        }
    }
}
