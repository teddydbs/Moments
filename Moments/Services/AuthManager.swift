//
//  AuthManager.swift
//  Moments
//
//  Service de gestion de l'authentification avec Supabase
//

import SwiftUI
import Combine
import Supabase
import Auth
import SwiftData

/// Manager d'authentification qui synchronise l'état auth avec SupabaseManager
@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User?
    @Published var userProfile: UserProfile?

    /// Structure utilisateur (synchronisée avec Supabase)
    struct User: Codable {
        let id: String
        let email: String
        let fullName: String?
        let avatarUrl: String?
        let provider: String? // "google", "apple", "email"

        var displayName: String {
            fullName ?? email.components(separatedBy: "@").first ?? "Utilisateur"
        }
    }

    // Singleton
    static let shared = AuthManager()

    // ProfileManager (sera initialisé avec le modelContext)
    private var profileManager: ProfileManager?

    // Cancellable pour observer les changements de SupabaseManager
    private var authCancellable: AnyCancellable?

    private init() {
        // ✅ Observer les changements d'authentification de SupabaseManager
        authCancellable = SupabaseManager.shared.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                guard let self = self else { return }

                if isAuthenticated {
                    // Session restaurée ou login réussi
                    Task { @MainActor in
                        await self.loadUserFromSupabase()
                    }
                } else {
                    // Session expirée ou logout
                    Task { @MainActor in
                        self.isAuthenticated = false
                        self.currentUser = nil
                        self.userProfile = nil
                        print("ℹ️ Session expirée, utilisateur déconnecté")
                    }
                }
            }
    }

    /// Initialise le ProfileManager avec le ModelContext
    /// Doit être appelé depuis MomentsApp au démarrage
    func setupProfileManager(modelContext: ModelContext) {
        self.profileManager = ProfileManager(modelContext: modelContext)
    }

    /// Charger les informations utilisateur depuis Supabase
    func loadUserFromSupabase() async {
        guard SupabaseManager.shared.isAuthenticated else {
            print("ℹ️ Pas d'utilisateur connecté")
            self.isAuthenticated = false
            self.currentUser = nil
            return
        }

        do {
            // Récupérer la session courante
            let session = try await SupabaseManager.shared.client.auth.session

            // Extraire les métadonnées utilisateur
            let userId = session.user.id.uuidString
            let email = session.user.email ?? ""

            // ✅ Accéder aux métadonnées utilisateur (raw_user_meta_data de Supabase)
            let metadata = session.user.userMetadata

            // 🔍 DEBUG: Afficher toutes les métadonnées disponibles
            print("📋 Métadonnées brutes:")
            for (key, value) in metadata {
                print("  - \(key): \(value)")
            }

            // ✅ Helper pour extraire les valeurs AnyJSON en String
            func extractString(from json: AnyJSON?) -> String? {
                guard let json = json else { return nil }
                switch json {
                case .string(let value):
                    return value
                default:
                    return nil
                }
            }

            // Essayer d'extraire le nom complet depuis différents champs possibles
            let fullName: String? = {
                if let name = extractString(from: metadata["full_name"]) {
                    return name
                } else if let name = extractString(from: metadata["name"]) {
                    return name
                } else if let firstName = extractString(from: metadata["given_name"]),
                          let lastName = extractString(from: metadata["family_name"]) {
                    return "\(firstName) \(lastName)"
                }
                return nil
            }()

            // Essayer d'extraire l'avatar URL
            let avatarUrl: String? = {
                if let url = extractString(from: metadata["avatar_url"]) {
                    return url
                } else if let url = extractString(from: metadata["picture"]) {
                    return url
                }
                return nil
            }()

            // Extraire le provider (google, apple, email, etc.)
            let appMetadata = session.user.appMetadata
            let provider = extractString(from: appMetadata["provider"])

            // Créer l'objet User
            let user = User(
                id: userId,
                email: email,
                fullName: fullName,
                avatarUrl: avatarUrl,
                provider: provider
            )

            self.currentUser = user
            self.isAuthenticated = true

            print("✅ Utilisateur chargé: \(user.displayName) (\(email))")
            print("📋 Métadonnées: fullName=\(fullName ?? "nil"), provider=\(provider ?? "nil")")

            // Sauvegarder en cache (optionnel)
            saveUserToCache(user)

            // ✅ Charger le profil complet depuis Supabase
            await loadUserProfile()

        } catch {
            print("❌ Erreur lors du chargement utilisateur: \(error)")
            self.isAuthenticated = false
            self.currentUser = nil
            self.userProfile = nil
        }
    }

    /// Charge le profil utilisateur complet depuis Supabase
    private func loadUserProfile() async {
        guard let manager = profileManager else {
            print("⚠️ ProfileManager non initialisé")
            return
        }

        do {
            try await manager.loadUserProfile()
            self.userProfile = manager.currentProfile
            print("✅ Profil chargé: \(userProfile?.fullName ?? "nil")")
        } catch {
            print("❌ Erreur lors du chargement du profil: \(error)")
        }
    }

    /// Déconnexion
    func logout() async {
        do {
            try await SupabaseManager.shared.signOut()

            self.currentUser = nil
            self.userProfile = nil
            self.isAuthenticated = false

            // Nettoyer le cache
            clearUserCache()

            print("✅ Déconnexion réussie")
        } catch {
            print("❌ Erreur lors de la déconnexion: \(error)")
        }
    }

    /// Suppression définitive du compte utilisateur
    /// ⚠️ Cette action est irréversible et supprime TOUTES les données
    func deleteAccount() async throws {
        guard let userId = SupabaseManager.shared.currentUserId else {
            throw AuthError.notAuthenticated
        }

        print("🗑️ Suppression du compte utilisateur: \(userId)")

        do {
            // 1. Supprimer toutes les données utilisateur de Supabase
            // Note: Les politiques RLS CASCADE devraient supprimer automatiquement:
            // - invitations (via my_events)
            // - wishlist_items (via user_id)
            // - event_photos (via my_events)

            // Supprimer tous les événements de l'utilisateur
            try await SupabaseManager.shared.client
                .from("my_events")
                .delete()
                .eq("owner_id", value: userId.uuidString)
                .execute()

            print("✅ Événements supprimés")

            // Supprimer tous les items wishlist de l'utilisateur
            try await SupabaseManager.shared.client
                .from("wishlist_items")
                .delete()
                .eq("user_id", value: userId.uuidString)
                .execute()

            print("✅ Wishlist supprimée")

            // Supprimer le profil utilisateur
            try await SupabaseManager.shared.client
                .from("profiles")
                .delete()
                .eq("id", value: userId.uuidString)
                .execute()

            print("✅ Profil supprimé")

            // 2. Supprimer le compte Auth Supabase
            // ⚠️ IMPORTANT: Supabase ne fournit pas d'API client pour supprimer un compte
            // Il faut utiliser l'API Admin ou une Edge Function
            // Pour l'instant, on se contente de supprimer les données et de déconnecter

            // TODO: Implémenter une Edge Function pour supprimer le compte Auth
            // await SupabaseManager.shared.client.functions.invoke("delete-user")

            print("✅ Compte utilisateur supprimé avec succès")

            // 3. Déconnexion
            await logout()

        } catch {
            print("❌ Erreur lors de la suppression du compte: \(error)")
            throw error
        }
    }

    // MARK: - Cache (UserDefaults)

    private func saveUserToCache(_ user: User) {
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: "cachedUser")
        }
    }

    private func loadUserFromCache() -> User? {
        guard let data = UserDefaults.standard.data(forKey: "cachedUser"),
              let user = try? JSONDecoder().decode(User.self, from: data) else {
            return nil
        }
        return user
    }

    private func clearUserCache() {
        UserDefaults.standard.removeObject(forKey: "cachedUser")
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case notAuthenticated
    case deleteFailed

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Vous devez être connecté pour effectuer cette action"
        case .deleteFailed:
            return "Impossible de supprimer le compte"
        }
    }
}
