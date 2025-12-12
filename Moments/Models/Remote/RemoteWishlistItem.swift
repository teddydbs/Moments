//
//  RemoteWishlistItem.swift
//  Moments
//
//  Description: Modèle représentant un item de wishlist côté Supabase
//  Architecture: Model (Remote)
//

import Foundation

/// 📦 Modèle Remote pour synchroniser les items de wishlist PERSONNELLE avec Supabase
///
/// ⚠️ IMPORTANT: Ce modèle synchronise UNIQUEMENT la wishlist personnelle
/// (les cadeaux que l'utilisateur souhaite recevoir), PAS les wishlists des contacts.
///
/// Ce modèle fait le pont entre SwiftData (WishlistItem) et PostgreSQL.
/// Il gère la sérialisation/désérialisation pour l'API Supabase.
struct RemoteWishlistItem: Codable {
    // MARK: - Properties

    /// Identifiant unique (UUID)
    let id: UUID

    /// ID de l'utilisateur propriétaire (celui qui souhaite le cadeau)
    let userId: UUID

    /// Titre du produit souhaité
    let title: String

    /// Description optionnelle
    let description: String?

    /// Prix estimé (en centimes pour éviter les problèmes de float)
    let priceInCents: Int?

    /// URL du produit
    let url: String?

    /// Catégorie du cadeau (tech, mode, maison, etc.)
    let category: String

    /// Statut du cadeau (wanted, reserved, purchased, received)
    let status: String

    /// Priorité (1 = basse, 2 = moyenne, 3 = haute)
    let priority: Int

    /// Nom de la personne qui a réservé ce cadeau (optionnel)
    let reservedBy: String?

    /// Date de création
    let createdAt: String // ISO8601

    /// Date de dernière modification
    let updatedAt: String // ISO8601

    // MARK: - Codable Keys

    /// ⚠️ IMPORTANT: Les noms des colonnes doivent correspondre EXACTEMENT
    /// à ceux de la table Supabase (snake_case)
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title
        case description
        case priceInCents = "price_in_cents"
        case url
        case category
        case status
        case priority
        case reservedBy = "reserved_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Initialization

    /// Initialise un RemoteWishlistItem depuis un WishlistItem local
    /// - Parameter local: L'item de wishlist SwiftData
    /// - Parameter userId: ID de l'utilisateur propriétaire
    ///
    /// ⚠️ NOTE: On ne synchronise QUE les items de la wishlist personnelle
    /// (myEvent != nil && contact == nil)
    init(from local: WishlistItem, userId: UUID) {
        self.id = local.id
        self.userId = userId
        self.title = local.title
        self.description = local.itemDescription

        // 💰 Conversion prix: Double → Int (centimes)
        // Exemple: 29.99€ → 2999 centimes
        if let price = local.price {
            self.priceInCents = Int(price * 100)
        } else {
            self.priceInCents = nil
        }

        self.url = local.url
        self.category = local.category.rawValue
        self.status = local.status.rawValue
        self.priority = local.priority
        self.reservedBy = local.reservedBy

        // 📅 Dates au format ISO8601
        let formatter = ISO8601DateFormatter()
        self.createdAt = formatter.string(from: local.createdAt)
        self.updatedAt = formatter.string(from: local.updatedAt)
    }

    // MARK: - Public Methods

    /// 📤 Convertit le modèle en dictionnaire pour Supabase
    /// - Returns: Dictionnaire compatible avec .insert() et .update()
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id.uuidString,
            "user_id": userId.uuidString,
            "title": title,
            "category": category,
            "status": status,
            "priority": priority,
            "created_at": createdAt,
            "updated_at": updatedAt
        ]

        // ✅ Ajouter les champs optionnels seulement s'ils existent
        if let description = description {
            dict["description"] = description
        }
        if let priceInCents = priceInCents {
            dict["price_in_cents"] = priceInCents
        }
        if let url = url {
            dict["url"] = url
        }
        if let reservedBy = reservedBy {
            dict["reserved_by"] = reservedBy
        }

        return dict
    }

    /// 📥 Convertit le modèle Remote en modèle local SwiftData
    /// - Returns: WishlistItem pour SwiftData
    func toLocal() -> WishlistItem {
        // 📅 Parser les dates ISO8601
        let formatter = ISO8601DateFormatter()
        let created = formatter.date(from: createdAt) ?? Date()
        let updated = formatter.date(from: updatedAt) ?? Date()

        // 💰 Conversion prix: Int (centimes) → Double
        // Exemple: 2999 centimes → 29.99€
        let price: Double? = priceInCents.map { Double($0) / 100.0 }

        // 🏷️ Parser category et status depuis String
        let giftCategory = GiftCategory(rawValue: category) ?? .autre
        let giftStatus = GiftStatus(rawValue: status) ?? .wanted

        return WishlistItem(
            id: id,
            title: title,
            itemDescription: description,
            price: price,
            url: url,
            image: nil, // ⚠️ Les images ne sont PAS synchronisées dans la table wishlist
            category: giftCategory,
            status: giftStatus,
            priority: priority,
            contact: nil, // ✅ Wishlist personnelle = pas de contact
            myEvent: nil, // ⚠️ La relation myEvent sera gérée par WishlistManager
            reservedBy: reservedBy,
            createdAt: created,
            updatedAt: updated
        )
    }
}

// MARK: - Preview Data

#if DEBUG
extension RemoteWishlistItem {
    /// Données de test pour les previews SwiftUI
    static var preview: RemoteWishlistItem {
        let formatter = ISO8601DateFormatter()
        let previewItem = WishlistItem(
            title: "AirPods Pro 2",
            itemDescription: "Écouteurs avec réduction de bruit active",
            price: 279.99,
            url: "https://www.apple.com/fr/airpods-pro/",
            category: .tech,
            status: .wanted,
            priority: 3
        )
        return RemoteWishlistItem(from: previewItem, userId: UUID())
    }
}
#endif
