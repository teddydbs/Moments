//
//  Invitation.swift
//  Moments
//
//  Modèle représentant une invitation à un de TES événements
//  Gère le statut (accepté/refusé/en attente) et l'approbation
//  Architecture: Model (SwiftData)
//

import Foundation
import SwiftData

/// Statut de l'invitation
enum InvitationStatus: String, Codable {
    case pending = "En attente"      // Invitation envoyée, pas de réponse
    case accepted = "Accepté"        // Invité a accepté
    case declined = "Refusé"         // Invité a refusé
    case waitingApproval = "En attente d'approbation" // Invité a demandé à venir, tu dois approuver
}

/// Représente une invitation à un événement
@Model
class Invitation {
    // MARK: - Properties

    /// Identifiant unique
    var id: UUID

    /// Nom complet de l'invité
    var guestName: String

    /// Email de l'invité (optionnel)
    var guestEmail: String?

    /// Numéro de téléphone de l'invité (optionnel)
    var guestPhoneNumber: String?

    /// Statut de l'invitation
    var status: InvitationStatus

    /// Date d'envoi de l'invitation
    var sentAt: Date

    /// Date de réponse de l'invité (optionnel)
    var respondedAt: Date?

    /// Message personnalisé de l'invité (lors de la réponse)
    var guestMessage: String?

    /// Nombre de personnes accompagnantes (+1, famille, etc.)
    var plusOnes: Int

    // MARK: - Supabase Sync Fields

    /// Token de partage unique (généré par Supabase)
    var shareToken: String?

    /// URL de partage complète (généré par l'app)
    var shareUrl: String?

    /// ID de l'organisateur (celui qui invite) - référence Supabase
    var inviterId: UUID?

    /// ID de l'invité s'il a un compte Moments - référence Supabase
    var inviteeUserId: UUID?

    /// Indique si l'invitation a été synchronisée avec Supabase
    var isSynced: Bool

    /// Date de dernière synchronisation avec Supabase
    var lastSyncedAt: Date?

    /// Date de création
    var createdAt: Date

    /// Dernière mise à jour
    var updatedAt: Date

    // MARK: - Relationships

    /// ✅ RELATION: Événement auquel cette invitation est liée
    @Relationship var myEvent: MyEvent?

    /// ✅ RELATION OPTIONNELLE: Contact lié à cette invitation (si c'est un ami dans tes contacts)
    @Relationship var contact: Contact?

    // MARK: - Computed Properties

    /// Est-ce que l'invité a répondu ?
    var hasResponded: Bool {
        status != .pending && status != .waitingApproval
    }

    /// Nombre total de personnes (invité + accompagnants)
    var totalGuests: Int {
        1 + plusOnes
    }

    /// Jours depuis l'envoi de l'invitation
    var daysSinceSent: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: sentAt, to: Date())
        return components.day ?? 0
    }

    /// Icône de statut
    var statusIcon: String {
        switch status {
        case .pending: return "clock.fill"
        case .accepted: return "checkmark.circle.fill"
        case .declined: return "xmark.circle.fill"
        case .waitingApproval: return "hourglass"
        }
    }

    /// Couleur de statut
    var statusColorName: String {
        switch status {
        case .pending: return "orange"
        case .accepted: return "green"
        case .declined: return "red"
        case .waitingApproval: return "purple"
        }
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        guestName: String,
        guestEmail: String? = nil,
        guestPhoneNumber: String? = nil,
        status: InvitationStatus = .pending,
        sentAt: Date = Date(),
        respondedAt: Date? = nil,
        guestMessage: String? = nil,
        plusOnes: Int = 0,
        shareToken: String? = nil,
        shareUrl: String? = nil,
        inviterId: UUID? = nil,
        inviteeUserId: UUID? = nil,
        isSynced: Bool = false,
        lastSyncedAt: Date? = nil,
        myEvent: MyEvent? = nil,
        contact: Contact? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.guestName = guestName
        self.guestEmail = guestEmail
        self.guestPhoneNumber = guestPhoneNumber
        self.status = status
        self.sentAt = sentAt
        self.respondedAt = respondedAt
        self.guestMessage = guestMessage
        self.plusOnes = plusOnes
        self.shareToken = shareToken
        self.shareUrl = shareUrl
        self.inviterId = inviterId
        self.inviteeUserId = inviteeUserId
        self.isSynced = isSynced
        self.lastSyncedAt = lastSyncedAt
        self.myEvent = myEvent
        self.contact = contact
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Methods

    /// Marquer l'invitation comme acceptée
    func accept(message: String? = nil) {
        self.status = .accepted
        self.respondedAt = Date()
        self.guestMessage = message
        self.updatedAt = Date()
    }

    /// Marquer l'invitation comme refusée
    func decline(message: String? = nil) {
        self.status = .declined
        self.respondedAt = Date()
        self.guestMessage = message
        self.updatedAt = Date()
    }

    /// Demander à venir (en attente d'approbation de l'organisateur)
    func requestToJoin(message: String? = nil) {
        self.status = .waitingApproval
        self.respondedAt = Date()
        self.guestMessage = message
        self.updatedAt = Date()
    }

    /// Approuver une demande (par l'organisateur)
    func approve() {
        guard status == .waitingApproval else { return }
        self.status = .accepted
        self.updatedAt = Date()
    }

    /// Rejeter une demande (par l'organisateur)
    func reject() {
        guard status == .waitingApproval else { return }
        self.status = .declined
        self.updatedAt = Date()
    }
}

// MARK: - Preview Helper

extension Invitation {
    /// Invitation acceptée
    static var accepted: Invitation {
        Invitation(
            guestName: "Marie Dupont",
            guestEmail: "marie@example.com",
            status: .accepted,
            sentAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            respondedAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
            guestMessage: "J'ai hâte ! Merci pour l'invitation 🎉"
        )
    }

    /// Invitation refusée
    static var declined: Invitation {
        Invitation(
            guestName: "Thomas Bernard",
            guestEmail: "thomas@example.com",
            status: .declined,
            sentAt: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date(),
            respondedAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()),
            guestMessage: "Désolé, je ne pourrai pas venir 😔"
        )
    }

    /// Invitation en attente
    static var pending: Invitation {
        Invitation(
            guestName: "Sophie Martin",
            guestEmail: "sophie@example.com",
            status: .pending,
            sentAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        )
    }

    /// Demande en attente d'approbation
    static var waitingApproval: Invitation {
        Invitation(
            guestName: "Lucas Petit",
            guestEmail: "lucas@example.com",
            status: .waitingApproval,
            sentAt: Date(),
            respondedAt: Date(),
            guestMessage: "Salut ! Je peux venir avec ma copine ?",
            plusOnes: 1
        )
    }

    /// Invitation avec +2
    static var withPlusOnes: Invitation {
        Invitation(
            guestName: "Famille Durand",
            guestEmail: "durand@example.com",
            status: .accepted,
            sentAt: Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date(),
            respondedAt: Calendar.current.date(byAdding: .day, value: -8, to: Date()),
            plusOnes: 2
        )
    }
}
