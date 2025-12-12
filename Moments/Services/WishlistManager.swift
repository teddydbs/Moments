//
//  WishlistManager.swift
//  Moments
//
//  Service de gestion de la wishlist personnelle (synchronisation Supabase ↔ SwiftData)
//  Architecture: Service Layer
//

import Foundation
import SwiftData
import Supabase
import Combine

/// Erreurs spécifiques à la gestion de la wishlist
enum WishlistError: LocalizedError {
    case notAuthenticated
    case itemNotFound
    case syncFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Vous devez être connecté pour gérer votre wishlist"
        case .itemNotFound:
            return "L'item de wishlist est introuvable"
        case .syncFailed(let message):
            return "Échec de la synchronisation: \(message)"
        }
    }
}

/// Manager pour gérer la wishlist personnelle et sa synchronisation
/// ⚠️ IMPORTANT: Ce manager gère UNIQUEMENT la wishlist personnelle
///              (les cadeaux que l'utilisateur souhaite recevoir)
@MainActor
class WishlistManager: ObservableObject {
    // MARK: - Properties

    /// Liste des items de wishlist (synchronisée avec Supabase)
    @Published var wishlistItems: [WishlistItem] = []

    /// Indicateur de chargement
    @Published var isLoading: Bool = false

    /// Message d'erreur (si présent)
    @Published var errorMessage: String?

    private let modelContext: ModelContext
    private let supabase: SupabaseManager

    // MARK: - Initialization

    /// Initialise le WishlistManager avec un ModelContext SwiftData
    /// - Parameter modelContext: Le contexte SwiftData pour accéder aux données locales
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.supabase = SupabaseManager.shared
    }

    // MARK: - Public Methods

    /// Charge la wishlist personnelle depuis Supabase
    /// ⚠️ Ne charge QUE les items de la wishlist personnelle, pas ceux des contacts
    func loadWishlist() async throws {
        isLoading = true
        errorMessage = nil

        guard let session = try? await supabase.client.auth.session else {
            throw WishlistError.notAuthenticated
        }

        let userId = session.user.id

        do {
            print("🔄 Récupération de la wishlist depuis Supabase...")

            // 1. Récupérer tous les items de wishlist depuis Supabase
            let remoteItems: [RemoteWishlistItem] = try await supabase.client
                .from("wishlist_items")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value

            print("✅ \(remoteItems.count) items récupérés depuis Supabase")

            // 2. Convertir en modèles locaux SwiftData
            let localItems = remoteItems.map { $0.toLocal() }

            // 3. Synchroniser avec SwiftData
            for localItem in localItems {
                // Vérifier si l'item existe déjà localement
                let itemId = localItem.id // ✅ Capturer l'UUID comme constante
                let descriptor = FetchDescriptor<WishlistItem>(
                    predicate: #Predicate { $0.id == itemId }
                )

                let existingItems = try modelContext.fetch(descriptor)

                if existingItems.isEmpty {
                    // ➕ Ajouter l'item s'il n'existe pas
                    modelContext.insert(localItem)
                    print("➕ Item ajouté localement: \(localItem.title)")
                } else if let existingItem = existingItems.first {
                    // ⚙️ Mettre à jour l'item existant
                    existingItem.title = localItem.title
                    existingItem.itemDescription = localItem.itemDescription
                    existingItem.price = localItem.price
                    existingItem.url = localItem.url
                    existingItem.category = localItem.category
                    existingItem.status = localItem.status
                    existingItem.priority = localItem.priority
                    existingItem.reservedBy = localItem.reservedBy
                    existingItem.updatedAt = localItem.updatedAt
                    print("⚙️ Item mis à jour localement: \(localItem.title)")
                }
            }

            // 4. Sauvegarder les changements
            try modelContext.save()

            // 5. Recharger la liste depuis SwiftData
            try await refreshLocalWishlist()

            isLoading = false
            print("✅ Wishlist synchronisée avec succès")

        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            print("❌ Erreur loadWishlist: \(error)")
            throw WishlistError.syncFailed(error.localizedDescription)
        }
    }

    /// Recharge la wishlist depuis SwiftData (local)
    /// ⚠️ Filtre pour ne charger QUE les items de la wishlist personnelle
    func refreshLocalWishlist() async throws {
        guard let session = try? await supabase.client.auth.session else {
            throw WishlistError.notAuthenticated
        }

        // ✅ Récupérer UNIQUEMENT les items de la wishlist personnelle
        // (myEvent != nil ET contact == nil)
        let descriptor = FetchDescriptor<WishlistItem>(
            predicate: #Predicate { item in
                item.contact == nil // Pas de contact = wishlist personnelle
            },
            sortBy: [
                SortDescriptor(\.priority, order: .reverse), // Priorité décroissante
                SortDescriptor(\.createdAt, order: .reverse) // Plus récent en premier
            ]
        )

        wishlistItems = try modelContext.fetch(descriptor)
        print("📋 \(wishlistItems.count) items dans la wishlist personnelle")
    }

    /// Ajoute un nouvel item à la wishlist
    /// - Parameter item: L'item à ajouter
    func addItem(_ item: WishlistItem) async throws {
        guard let session = try? await supabase.client.auth.session else {
            throw WishlistError.notAuthenticated
        }

        let userId = session.user.id

        do {
            print("➕ Ajout de l'item à la wishlist: \(item.title)")

            // 1. Ajouter localement (SwiftData)
            modelContext.insert(item)
            try modelContext.save()

            // 2. Synchroniser avec Supabase
            let remoteItem = RemoteWishlistItem(from: item, userId: userId)
            try await supabase.client
                .from("wishlist_items")
                .insert(remoteItem)
                .execute()

            // 3. Recharger la liste
            try await refreshLocalWishlist()

            print("✅ Item ajouté avec succès")

        } catch {
            print("❌ Erreur addItem: \(error)")
            throw WishlistError.syncFailed(error.localizedDescription)
        }
    }

    /// Met à jour un item de wishlist existant
    /// - Parameter item: L'item à mettre à jour
    func updateItem(_ item: WishlistItem) async throws {
        guard let session = try? await supabase.client.auth.session else {
            throw WishlistError.notAuthenticated
        }

        let userId = session.user.id

        do {
            print("⚙️ Mise à jour de l'item: \(item.title)")

            // 1. Mettre à jour localement
            item.updatedAt = Date()
            try modelContext.save()

            // 2. Synchroniser avec Supabase
            let remoteItem = RemoteWishlistItem(from: item, userId: userId)
            try await supabase.client
                .from("wishlist_items")
                .update(remoteItem)
                .eq("id", value: item.id.uuidString)
                .execute()

            // 3. Recharger la liste
            try await refreshLocalWishlist()

            print("✅ Item mis à jour avec succès")

        } catch {
            print("❌ Erreur updateItem: \(error)")
            throw WishlistError.syncFailed(error.localizedDescription)
        }
    }

    /// Supprime un item de la wishlist
    /// - Parameter item: L'item à supprimer
    func deleteItem(_ item: WishlistItem) async throws {
        do {
            print("🗑️ Suppression de l'item: \(item.title)")

            // 1. Supprimer localement
            modelContext.delete(item)
            try modelContext.save()

            // 2. Supprimer depuis Supabase
            try await supabase.client
                .from("wishlist_items")
                .delete()
                .eq("id", value: item.id.uuidString)
                .execute()

            // 3. Recharger la liste
            try await refreshLocalWishlist()

            print("✅ Item supprimé avec succès")

        } catch {
            print("❌ Erreur deleteItem: \(error)")
            throw WishlistError.syncFailed(error.localizedDescription)
        }
    }

    /// Réserve un item de wishlist
    /// - Parameters:
    ///   - item: L'item à réserver
    ///   - personName: Nom de la personne qui réserve
    func reserveItem(_ item: WishlistItem, by personName: String) async throws {
        item.status = .reserved
        item.reservedBy = personName
        try await updateItem(item)
    }

    /// Annule la réservation d'un item
    /// - Parameter item: L'item dont on annule la réservation
    func unreserveItem(_ item: WishlistItem) async throws {
        item.status = .wanted
        item.reservedBy = nil
        try await updateItem(item)
    }

    /// Marque un item comme acheté
    /// - Parameter item: L'item à marquer comme acheté
    func markAsPurchased(_ item: WishlistItem) async throws {
        item.status = .purchased
        try await updateItem(item)
    }

    /// Marque un item comme reçu
    /// - Parameter item: L'item à marquer comme reçu
    func markAsReceived(_ item: WishlistItem) async throws {
        item.status = .received
        try await updateItem(item)
    }
}
