//
//  WishlistItem.swift
//  Moments
//
//  Modèle représentant un cadeau dans une wishlist
//  Peut appartenir à un Contact (ce qu'il veut) OU à un MyEvent (ce que TU veux)
//  Architecture: Model (SwiftData)
//

import Foundation
import SwiftData

/// Catégorie de cadeau
enum GiftCategory: String, Codable, CaseIterable {
    case mode = "Mode"
    case tech = "Tech"
    case maison = "Maison"
    case beaute = "Beauté"
    case sport = "Sport"
    case loisirs = "Loisirs"
    case livre = "Livre"
    case experience = "Expérience"
    case argent = "Argent"
    case autre = "Autre"

    var icon: String {
        switch self {
        case .mode: return "tshirt.fill"
        case .tech: return "laptopcomputer"
        case .maison: return "house.fill"
        case .beaute: return "sparkles"
        case .sport: return "figure.run"
        case .loisirs: return "gamecontroller.fill"
        case .livre: return "book.fill"
        case .experience: return "ticket.fill"
        case .argent: return "banknote.fill"
        case .autre: return "gift.fill"
        }
    }
}

/// Statut du cadeau
enum GiftStatus: String, Codable {
    case wanted = "Souhaité"          // Cadeau souhaité, pas encore réservé
    case reserved = "Réservé"         // Quelqu'un a réservé ce cadeau
    case purchased = "Acheté"         // Cadeau acheté
    case received = "Reçu"            // Cadeau reçu par le destinataire
}

/// Représente un cadeau dans une wishlist
@Model
class WishlistItem {
    // MARK: - Properties

    /// Identifiant unique
    var id: UUID

    /// Nom du cadeau
    var title: String

    /// Description détaillée (renommé pour éviter le conflit avec description de NSObject)
    var itemDescription: String?

    /// Prix estimé (optionnel)
    var price: Double?

    /// URL du produit (lien Amazon, etc.)
    var url: String?

    /// Image du produit (stockée en base64)
    var image: Data?

    /// Catégorie du cadeau
    var category: GiftCategory

    /// Statut du cadeau
    var status: GiftStatus

    /// Priorité (1 = faible, 2 = moyenne, 3 = haute)
    var priority: Int

    /// Date de création
    var createdAt: Date

    /// Dernière mise à jour
    var updatedAt: Date

    // MARK: - Relationships

    /// ✅ RELATION OPTIONNELLE: Contact qui souhaite ce cadeau
    /// Si rempli → c'est LEUR wishlist (ce qu'ils veulent)
    @Relationship var contact: Contact?

    /// ✅ RELATION OPTIONNELLE: Événement pour lequel TU souhaites ce cadeau
    /// Si rempli → c'est TA wishlist pour cet événement
    @Relationship var myEvent: MyEvent?

    /// ⚠️ NOTE: Un WishlistItem a SOIT un contact, SOIT un myEvent, mais pas les deux

    // MARK: - Computed Properties

    /// Nom de la personne qui a réservé ce cadeau (si status = reserved)
    var reservedBy: String?

    /// Est-ce que ce cadeau est dans MA wishlist ?
    var isMyWishlistItem: Bool {
        myEvent != nil && contact == nil
    }

    /// Est-ce que ce cadeau est dans la wishlist d'un contact ?
    var isContactWishlistItem: Bool {
        contact != nil && myEvent == nil
    }

    /// Prix formaté
    var formattedPrice: String? {
        guard let price = price else { return nil }
        return String(format: "%.2f €", price)
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        itemDescription: String? = nil,
        price: Double? = nil,
        url: String? = nil,
        image: Data? = nil,
        category: GiftCategory = .autre,
        status: GiftStatus = .wanted,
        priority: Int = 2,
        contact: Contact? = nil,
        myEvent: MyEvent? = nil,
        reservedBy: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.itemDescription = itemDescription
        self.price = price
        self.url = url
        self.image = image
        self.category = category
        self.status = status
        self.priority = priority
        self.contact = contact
        self.myEvent = myEvent
        self.reservedBy = reservedBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Preview Helper

extension WishlistItem {
    /// Cadeau pour un contact (ce qu'il veut)
    static var contactGift: WishlistItem {
        WishlistItem(
            title: "AirPods Pro",
            itemDescription: "Les nouveaux écouteurs sans fil avec réduction de bruit",
            price: 279.0,
            url: "https://www.apple.com/fr/airpods-pro/",
            category: .tech,
            status: .wanted,
            priority: 3
        )
    }

    /// Cadeau pour mon événement (ce que JE veux)
    static var myGift: WishlistItem {
        WishlistItem(
            title: "Machine à café Nespresso",
            itemDescription: "Modèle Vertuo avec mousseur de lait",
            price: 199.0,
            category: .maison,
            status: .wanted,
            priority: 2
        )
    }

    /// Cadeau réservé
    static var reservedGift: WishlistItem {
        WishlistItem(
            title: "Parfum Chanel N°5",
            price: 120.0,
            category: .beaute,
            status: .reserved,
            priority: 3,
            reservedBy: "Sophie"
        )
    }
}
