//
//  RemoteInvitation.swift
//  Moments
//
//  Modèle pour la synchronisation des invitations avec Supabase
//  Correspond à la table "invitations" dans Supabase
//

import Foundation

/// Modèle remote pour les invitations (table Supabase)
struct RemoteInvitation: Codable, Identifiable {
    // MARK: - Properties

    /// Identifiant unique (UUID de Supabase)
    let id: UUID

    /// ID de l'événement (référence my_events)
    let eventId: UUID

    /// ID de l'organisateur qui invite (référence auth.users)
    let inviterId: UUID

    /// ID de l'invité s'il a un compte Moments (optionnel)
    let inviteeUserId: UUID?

    /// Nom de l'invité
    let guestName: String

    /// Email de l'invité (optionnel)
    let guestEmail: String?

    /// Téléphone de l'invité (optionnel)
    let guestPhoneNumber: String?

    /// Statut de l'invitation (pending, accepted, declined, waiting_approval)
    let status: String

    /// Date d'envoi de l'invitation
    let sentAt: Date

    /// Date de réponse (optionnel)
    let respondedAt: Date?

    /// Message de l'invité (optionnel)
    let guestMessage: String?

    /// Nombre d'accompagnants (+1, +2, etc.)
    let plusOnes: Int

    /// Token de partage unique (généré automatiquement par Supabase)
    let shareToken: String

    /// URL de partage (optionnel)
    let shareUrl: String?

    /// ID du contact local (optionnel, pas de FK dans Supabase)
    let contactId: UUID?

    /// Date de création
    let createdAt: Date

    /// Dernière mise à jour
    let updatedAt: Date

    // MARK: - Coding Keys

    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case inviterId = "inviter_id"
        case inviteeUserId = "invitee_user_id"
        case guestName = "guest_name"
        case guestEmail = "guest_email"
        case guestPhoneNumber = "guest_phone_number"
        case status
        case sentAt = "sent_at"
        case respondedAt = "responded_at"
        case guestMessage = "guest_message"
        case plusOnes = "plus_ones"
        case shareToken = "share_token"
        case shareUrl = "share_url"
        case contactId = "contact_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    // MARK: - Conversion depuis Invitation (SwiftData -> Supabase)

    /// Créer un RemoteInvitation depuis un modèle local Invitation
    /// - Parameters:
    ///   - invitation: Invitation SwiftData locale
    ///   - inviterId: ID de l'organisateur (utilisateur connecté)
    ///   - eventId: ID de l'événement Supabase
    /// - Returns: RemoteInvitation prêt à être envoyé à Supabase
    static func from(
        invitation: Invitation,
        inviterId: UUID,
        eventId: UUID
    ) -> RemoteInvitation {
        return RemoteInvitation(
            id: invitation.id,
            eventId: eventId,
            inviterId: inviterId,
            inviteeUserId: nil, // Sera mis à jour quand l'invité créera un compte
            guestName: invitation.guestName,
            guestEmail: invitation.guestEmail,
            guestPhoneNumber: invitation.guestPhoneNumber,
            status: invitation.status.toRemoteStatus(),
            sentAt: invitation.sentAt,
            respondedAt: invitation.respondedAt,
            guestMessage: invitation.guestMessage,
            plusOnes: invitation.plusOnes,
            shareToken: "", // Sera généré par Supabase
            shareUrl: nil,
            contactId: invitation.contact?.id,
            createdAt: invitation.createdAt,
            updatedAt: invitation.updatedAt
        )
    }

    // MARK: - Conversion vers Invitation (Supabase -> SwiftData)

    /// Convertir vers un modèle local Invitation
    /// - Parameter myEvent: L'événement local auquel lier l'invitation
    /// - Returns: Invitation SwiftData
    func toLocalInvitation(myEvent: MyEvent?) -> Invitation {
        return Invitation(
            id: self.id,
            guestName: self.guestName,
            guestEmail: self.guestEmail,
            guestPhoneNumber: self.guestPhoneNumber,
            status: InvitationStatus.fromRemoteStatus(self.status),
            sentAt: self.sentAt,
            respondedAt: self.respondedAt,
            guestMessage: self.guestMessage,
            plusOnes: self.plusOnes,
            myEvent: myEvent,
            contact: nil, // Sera lié après si contactId existe
            createdAt: self.createdAt,
            updatedAt: self.updatedAt
        )
    }
}

// MARK: - InvitationStatus Extensions

extension InvitationStatus {
    /// Convertir le statut local vers le format Supabase
    func toRemoteStatus() -> String {
        switch self {
        case .pending: return "pending"
        case .accepted: return "accepted"
        case .declined: return "declined"
        case .waitingApproval: return "waiting_approval"
        }
    }

    /// Créer un statut local depuis le format Supabase
    static func fromRemoteStatus(_ remoteStatus: String) -> InvitationStatus {
        switch remoteStatus {
        case "pending": return .pending
        case "accepted": return .accepted
        case "declined": return .declined
        case "waiting_approval": return .waitingApproval
        default:
            print("⚠️ Statut inconnu: \(remoteStatus), utilisation de .pending par défaut")
            return .pending
        }
    }
}

// MARK: - Payload pour Création/Mise à Jour

/// Payload pour créer une nouvelle invitation dans Supabase
struct CreateInvitationPayload: Codable {
    let eventId: UUID
    let inviterId: UUID
    let guestName: String
    let guestEmail: String?
    let guestPhoneNumber: String?
    let status: String
    let plusOnes: Int
    let contactId: UUID?

    enum CodingKeys: String, CodingKey {
        case eventId = "event_id"
        case inviterId = "inviter_id"
        case guestName = "guest_name"
        case guestEmail = "guest_email"
        case guestPhoneNumber = "guest_phone_number"
        case status
        case plusOnes = "plus_ones"
        case contactId = "contact_id"
    }

    /// Créer un payload depuis une Invitation locale
    static func from(
        invitation: Invitation,
        inviterId: UUID,
        eventId: UUID
    ) -> CreateInvitationPayload {
        return CreateInvitationPayload(
            eventId: eventId,
            inviterId: inviterId,
            guestName: invitation.guestName,
            guestEmail: invitation.guestEmail,
            guestPhoneNumber: invitation.guestPhoneNumber,
            status: invitation.status.toRemoteStatus(),
            plusOnes: invitation.plusOnes,
            contactId: invitation.contact?.id
        )
    }
}

/// Payload pour mettre à jour une invitation existante
struct UpdateInvitationPayload: Codable {
    let status: String?
    let respondedAt: Date?
    let guestMessage: String?
    let plusOnes: Int?

    enum CodingKeys: String, CodingKey {
        case status
        case respondedAt = "responded_at"
        case guestMessage = "guest_message"
        case plusOnes = "plus_ones"
    }
}

// MARK: - Statistiques des Invitations

/// Réponse de la fonction get_event_invitation_stats()
struct InvitationStats: Codable {
    let totalInvitations: Int
    let acceptedCount: Int
    let pendingCount: Int
    let declinedCount: Int
    let waitingApprovalCount: Int
    let totalGuests: Int

    enum CodingKeys: String, CodingKey {
        case totalInvitations = "total_invitations"
        case acceptedCount = "accepted_count"
        case pendingCount = "pending_count"
        case declinedCount = "declined_count"
        case waitingApprovalCount = "waiting_approval_count"
        case totalGuests = "total_guests"
    }
}
