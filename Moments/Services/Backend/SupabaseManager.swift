//
//  SupabaseManager.swift
//  Moments
//
//  Manager principal pour les interactions avec Supabase
//  Architecture: Service Layer
//

import Foundation
import SwiftUI
import Combine
import Supabase

/// Manager principal pour toutes les interactions avec Supabase
/// Gère l'authentification, les requêtes CRUD et le Storage
@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()

    let client: SupabaseClient

    @Published var isAuthenticated = false
    @Published var currentUserId: UUID?

    private init() {
        // ✅ Initialiser le client Supabase avec nos credentials
        self.client = SupabaseClient(
            supabaseURL: SupabaseConfig.supabaseURL,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )

        print("🟢 SupabaseManager initialisé")

        // ✅ Écouter les changements d'état d'authentification
        Task {
            await listenToAuthChanges()
        }
    }

    /// Écoute les changements d'état d'authentification (session restaurée, login, logout)
    private func listenToAuthChanges() async {
        for await state in client.auth.authStateChanges {
            await MainActor.run {
                switch state.event {
                case .signedIn, .tokenRefreshed, .initialSession:
                    self.isAuthenticated = true
                    self.currentUserId = state.session?.user.id
                    print("✅ Session active - User ID: \(state.session?.user.id.uuidString ?? "nil")")
                case .signedOut:
                    self.isAuthenticated = false
                    self.currentUserId = nil
                    print("🚪 Session fermée")
                default:
                    break
                }
            }
        }
    }

    // MARK: - Authentication

    /// Vérifier le statut d'authentification actuel
    func checkAuthStatus() async {
        do {
            let session = try await client.auth.session
            self.currentUserId = session.user.id
            self.isAuthenticated = true
            print("✅ Session active - User ID: \(session.user.id)")
        } catch {
            self.isAuthenticated = false
            self.currentUserId = nil
            print("ℹ️ Pas de session active")
        }
    }

    /// Inscription avec email et mot de passe
    func signUp(email: String, password: String, fullName: String) async throws {
        let response = try await client.auth.signUp(
            email: email,
            password: password,
            data: ["full_name": .string(fullName)]
        )

        self.currentUserId = response.user.id
        self.isAuthenticated = true

        print("✅ Inscription réussie - User ID: \(response.user.id)")
    }

    /// Connexion avec email et mot de passe
    func signIn(email: String, password: String) async throws {
        let session = try await client.auth.signIn(
            email: email,
            password: password
        )

        self.currentUserId = session.user.id
        self.isAuthenticated = true

        print("✅ Connexion réussie - User ID: \(session.user.id)")
    }

    /// Connexion avec Google OAuth
    func signInWithGoogle() async throws {
        // ✅ Lancer le flow OAuth avec Google
        // redirectTo doit pointer vers notre URL scheme iOS
        try await client.auth.signInWithOAuth(
            provider: .google,
            redirectTo: URL(string: "com.supabase.ksbsvscfplmokacngouo://login-callback")
        )

        print("✅ OAuth Google lancé - En attente du callback...")

        // Note: La session sera récupérée dans handleIncomingURL() dans MomentsApp.swift
        // après le callback OAuth
    }

    /// Connexion avec Apple OAuth
    func signInWithApple() async throws {
        // ✅ Lancer le flow OAuth avec Apple
        // redirectTo doit pointer vers notre URL scheme iOS
        try await client.auth.signInWithOAuth(
            provider: .apple,
            redirectTo: URL(string: "com.supabase.ksbsvscfplmokacngouo://login-callback")
        )

        print("✅ OAuth Apple lancé - En attente du callback...")

        // Note: La session sera récupérée dans handleIncomingURL() dans MomentsApp.swift
        // après le callback OAuth
    }

    /// Déconnexion
    func signOut() async throws {
        try await client.auth.signOut()
        self.currentUserId = nil
        self.isAuthenticated = false

        print("✅ Déconnexion réussie")
    }

    // MARK: - MyEvents

    /// Récupérer tous les événements de l'utilisateur connecté
    func fetchMyEvents() async throws -> [RemoteMyEvent] {
        guard isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }

        let response: [RemoteMyEvent] = try await client
            .from("my_events")
            .select()
            .order("date", ascending: true)
            .execute()
            .value

        print("✅ Récupéré \(response.count) événements depuis Supabase")
        return response
    }

    /// Créer un nouvel événement
    func createMyEvent(_ event: RemoteMyEvent) async throws -> RemoteMyEvent {
        guard isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }

        let response: RemoteMyEvent = try await client
            .from("my_events")
            .insert(event.toDictionary())
            .select()
            .single()
            .execute()
            .value

        print("✅ Événement créé - ID: \(response.id)")
        return response
    }

    /// Mettre à jour un événement existant
    func updateMyEvent(_ event: RemoteMyEvent) async throws {
        guard isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }

        try await client
            .from("my_events")
            .update(event.toDictionary())
            .eq("id", value: event.id.uuidString)
            .execute()

        print("✅ Événement mis à jour - ID: \(event.id)")
    }

    /// Supprimer un événement
    func deleteMyEvent(id: UUID) async throws {
        guard isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }

        try await client
            .from("my_events")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()

        print("✅ Événement supprimé - ID: \(id)")
    }

    // MARK: - Invitations

    /// Récupérer toutes les invitations d'un événement
    func fetchInvitations(for eventId: UUID) async throws -> [RemoteInvitation] {
        guard isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }

        let response: [RemoteInvitation] = try await client
            .from("invitations")
            .select()
            .eq("my_event_id", value: eventId.uuidString)
            .execute()
            .value

        print("✅ Récupéré \(response.count) invitations pour l'événement \(eventId)")
        return response
    }

    /// Créer une nouvelle invitation
    func createInvitation(_ invitation: RemoteInvitation) async throws -> RemoteInvitation {
        guard isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }

        let response: RemoteInvitation = try await client
            .from("invitations")
            .insert(invitation.toDictionary())
            .select()
            .single()
            .execute()
            .value

        print("✅ Invitation créée - ID: \(response.id)")
        return response
    }

    /// Mettre à jour une invitation
    func updateInvitation(_ invitation: RemoteInvitation) async throws {
        guard isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }

        try await client
            .from("invitations")
            .update(invitation.toDictionary())
            .eq("id", value: invitation.id.uuidString)
            .execute()

        print("✅ Invitation mise à jour - ID: \(invitation.id)")
    }

    /// Supprimer une invitation
    func deleteInvitation(id: UUID) async throws {
        guard isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }

        try await client
            .from("invitations")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()

        print("✅ Invitation supprimée - ID: \(id)")
    }

    // MARK: - Wishlist Items

    /// ⚠️ OBSOLÈTE: Ces méthodes utilisaient l'ancien schéma avec my_event_id
    ///
    /// La wishlist est maintenant gérée par WishlistManager qui utilise le nouveau
    /// schéma avec catégories et statuts. Ces méthodes ne sont plus utilisées
    /// mais conservées temporairement pour référence.
    ///
    /// TODO: Supprimer ces méthodes une fois la migration complète

    /// Récupérer tous les produits wishlist d'un événement (OBSOLÈTE)
    @available(*, deprecated, message: "Utiliser WishlistManager à la place")
    func fetchWishlistItems(for eventId: UUID) async throws -> [RemoteWishlistItem] {
        fatalError("Cette méthode est obsolète. Utiliser WishlistManager.loadWishlist() à la place.")
    }

    /// Créer un nouveau produit wishlist (OBSOLÈTE)
    @available(*, deprecated, message: "Utiliser WishlistManager à la place")
    func createWishlistItem(_ item: RemoteWishlistItem) async throws -> RemoteWishlistItem {
        fatalError("Cette méthode est obsolète. Utiliser WishlistManager.addItem() à la place.")
    }

    /// Mettre à jour un produit wishlist (OBSOLÈTE)
    @available(*, deprecated, message: "Utiliser WishlistManager à la place")
    func updateWishlistItem(_ item: RemoteWishlistItem) async throws {
        fatalError("Cette méthode est obsolète. Utiliser WishlistManager.updateItem() à la place.")

        print("✅ Produit wishlist mis à jour - ID: \(item.id)")
    }

    /// Supprimer un produit wishlist
    func deleteWishlistItem(id: UUID) async throws {
        guard isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }

        try await client
            .from("wishlist_items")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()

        print("✅ Produit wishlist supprimé - ID: \(id)")
    }

    // MARK: - Event Photos

    /// Récupérer toutes les photos d'un événement
    func fetchEventPhotos(for eventId: UUID) async throws -> [RemoteEventPhoto] {
        guard isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }

        let response: [RemoteEventPhoto] = try await client
            .from("event_photos")
            .select()
            .eq("my_event_id", value: eventId.uuidString)
            .order("display_order", ascending: true)
            .execute()
            .value

        print("✅ Récupéré \(response.count) photos pour l'événement \(eventId)")
        return response
    }

    /// Créer une nouvelle photo d'événement
    func createEventPhoto(_ photo: RemoteEventPhoto) async throws -> RemoteEventPhoto {
        guard isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }

        let response: RemoteEventPhoto = try await client
            .from("event_photos")
            .insert(photo.toDictionary())
            .select()
            .single()
            .execute()
            .value

        print("✅ Photo d'événement créée - ID: \(response.id)")
        return response
    }

    /// Supprimer une photo d'événement
    func deleteEventPhoto(id: UUID) async throws {
        guard isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }

        try await client
            .from("event_photos")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()

        print("✅ Photo d'événement supprimée - ID: \(id)")
    }

    // MARK: - Storage

    /// Upload une image vers Supabase Storage
    /// - Parameters:
    ///   - imageData: Données de l'image
    ///   - bucket: Nom du bucket ("event-covers", "event-profiles", "event-photos", "wishlist-images")
    ///   - fileName: Nom du fichier (doit être unique)
    /// - Returns: URL publique de l'image uploadée
    func uploadImage(_ imageData: Data, toBucket bucket: String, fileName: String) async throws -> String {
        guard isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }

        // ✅ Upload le fichier vers le bucket
        try await client.storage
            .from(bucket)
            .upload(
                fileName,
                data: imageData,
                options: FileOptions(contentType: "image/jpeg")
            )

        // ✅ Récupérer l'URL publique
        let publicURL = try client.storage
            .from(bucket)
            .getPublicURL(path: fileName)

        print("✅ Image uploadée - URL: \(publicURL.absoluteString)")
        return publicURL.absoluteString
    }

    /// Supprimer une image du Storage
    func deleteImage(at url: String, fromBucket bucket: String) async throws {
        guard isAuthenticated else {
            throw SupabaseError.notAuthenticated
        }

        // Extraire le nom du fichier depuis l'URL
        guard let fileName = URL(string: url)?.lastPathComponent else {
            throw SupabaseError.invalidImageURL
        }

        try await client.storage
            .from(bucket)
            .remove(paths: [fileName])

        print("✅ Image supprimée - Fichier: \(fileName)")
    }
}

// MARK: - Errors

enum SupabaseError: LocalizedError {
    case notImplemented
    case notAuthenticated
    case noUserReturned
    case invalidImageURL

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Cette fonctionnalité n'est pas encore implémentée."
        case .notAuthenticated:
            return "Vous devez être connecté pour effectuer cette action."
        case .noUserReturned:
            return "Aucun utilisateur retourné par Supabase"
        case .invalidImageURL:
            return "URL d'image invalide"
        }
    }
}
