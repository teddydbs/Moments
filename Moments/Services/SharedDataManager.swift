//
//  SharedDataManager.swift
//  Moments
//
//  Description: Gestionnaire de données partagées entre l'app et l'extension
//  Architecture: Service partagé (App Group)
//

import Foundation

/// Gestionnaire pour partager des données entre l'app principale et la Share Extension
/// Utilise UserDefaults avec App Group
class SharedDataManager {

    // MARK: - Properties

    /// Nom de l'App Group (doit être identique dans les deux targets)
    private static let appGroupIdentifier = "group.com.teddydubois.moments.shared"

    /// UserDefaults partagés
    private let sharedDefaults: UserDefaults?

    /// Singleton
    static let shared = SharedDataManager()

    // MARK: - Keys

    private enum Keys {
        static let pendingWishlistItems = "pendingWishlistItems"
        static let availableEvents = "availableEvents"
    }

    // MARK: - Initialization

    private init() {
        sharedDefaults = UserDefaults(suiteName: SharedDataManager.appGroupIdentifier)
    }

    // MARK: - Public Methods

    /// Ajoute un produit en attente depuis la Share Extension
    /// - Parameter item: Élément à ajouter
    func addPendingWishlistItem(_ item: PendingWishlistItem) {
        var items = getPendingWishlistItems()
        items.append(item)
        savePendingWishlistItems(items)
        print("✅ Produit ajouté aux pending items: \(item.url)")
    }

    /// Récupère tous les produits en attente
    /// - Returns: Liste des produits en attente
    func getPendingWishlistItems() -> [PendingWishlistItem] {
        guard let sharedDefaults = sharedDefaults,
              let data = sharedDefaults.data(forKey: Keys.pendingWishlistItems) else {
            return []
        }

        do {
            let items = try JSONDecoder().decode([PendingWishlistItem].self, from: data)
            print("📦 \(items.count) produits en attente récupérés")
            return items
        } catch {
            print("❌ Erreur lors de la lecture des pending items: \(error)")
            return []
        }
    }

    /// Supprime tous les produits en attente (après traitement)
    func clearPendingWishlistItems() {
        sharedDefaults?.removeObject(forKey: Keys.pendingWishlistItems)
        print("🗑️ Tous les produits en attente ont été supprimés")
    }

    /// Supprime un produit en attente spécifique
    /// - Parameter id: ID du produit à supprimer
    func removePendingWishlistItem(id: UUID) {
        var items = getPendingWishlistItems()
        items.removeAll { $0.id == id }
        savePendingWishlistItems(items)
        print("🗑️ Produit supprimé des pending items: \(id)")
    }

    // MARK: - Event Sync

    /// Sauvegarde la liste des événements pour la Share Extension
    /// - Parameter events: Liste d'événements simplifiés
    func saveAvailableEvents(_ events: [SharedEvent]) {
        do {
            let data = try JSONEncoder().encode(events)
            sharedDefaults?.set(data, forKey: Keys.availableEvents)
            print("💾 \(events.count) événements sauvegardés pour Share Extension")
        } catch {
            print("❌ Erreur lors de la sauvegarde des événements: \(error)")
        }
    }

    /// Récupère la liste des événements disponibles
    /// - Returns: Liste des événements
    func getAvailableEvents() -> [SharedEvent] {
        guard let sharedDefaults = sharedDefaults,
              let data = sharedDefaults.data(forKey: Keys.availableEvents) else {
            return []
        }

        do {
            let events = try JSONDecoder().decode([SharedEvent].self, from: data)
            print("📦 \(events.count) événements récupérés")
            return events
        } catch {
            print("❌ Erreur lors de la lecture des événements: \(error)")
            return []
        }
    }

    // MARK: - Private Methods

    /// Sauvegarde la liste des produits en attente
    private func savePendingWishlistItems(_ items: [PendingWishlistItem]) {
        do {
            let data = try JSONEncoder().encode(items)
            sharedDefaults?.set(data, forKey: Keys.pendingWishlistItems)
            print("💾 \(items.count) produits sauvegardés")
        } catch {
            print("❌ Erreur lors de la sauvegarde des pending items: \(error)")
        }
    }
}

// MARK: - PendingWishlistItem Model

/// Représente un produit en attente d'être ajouté à la wishlist
/// Utilisé pour passer des données de la Share Extension à l'app principale
struct PendingWishlistItem: Codable, Identifiable {
    /// Identifiant unique
    let id: UUID

    /// URL du produit
    let url: String

    /// Titre du produit (optionnel, peut être extrait plus tard)
    let title: String?

    /// Prix du produit (optionnel)
    let price: Double?

    /// Image du produit en base64 (optionnel)
    let imageData: Data?

    /// Priorité (1-5)
    let priority: Int

    /// ID de l'événement associé (optionnel)
    let eventId: UUID?

    /// Date de création
    let createdAt: Date

    init(
        id: UUID = UUID(),
        url: String,
        title: String? = nil,
        price: Double? = nil,
        imageData: Data? = nil,
        priority: Int = 3,
        eventId: UUID? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.price = price
        self.imageData = imageData
        self.priority = priority
        self.eventId = eventId
        self.createdAt = createdAt
    }
}

// MARK: - SharedEvent Model

/// Représente un événement simplifié pour la Share Extension
struct SharedEvent: Codable, Identifiable {
    /// Identifiant unique
    let id: UUID

    /// Titre de l'événement
    let title: String

    /// Icône SF Symbol
    let icon: String

    /// Date de l'événement
    let date: Date

    init(id: UUID, title: String, icon: String, date: Date) {
        self.id = id
        self.title = title
        self.icon = icon
        self.date = date
    }
}
