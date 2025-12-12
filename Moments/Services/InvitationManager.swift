//
//  InvitationManager.swift
//  Moments
//
//  Service de gestion des invitations avec synchronisation Supabase
//  Gère la création, la modification et le partage des invitations
//

import Foundation
import SwiftData
import Supabase

/// Manager pour gérer les invitations et leur synchronisation avec Supabase
@MainActor
class InvitationManager {
    // MARK: - Properties

    private let modelContext: ModelContext
    private let supabase = SupabaseManager.shared

    /// URL de base pour les deep links (sera configurée plus tard)
    private let baseDeepLinkURL = "moments://invite"

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Create Invitation

    /// Créer une nouvelle invitation et la synchroniser avec Supabase
    /// - Parameters:
    ///   - invitation: Invitation locale à créer
    ///   - eventId: ID de l'événement Supabase
    /// - Throws: Erreur si la création ou la sync échoue
    func createInvitation(_ invitation: Invitation, for eventId: UUID) async throws {
        guard let currentUserId = supabase.currentUserId else {
            throw InvitationError.notAuthenticated
        }

        // 1. Sauvegarder localement d'abord (offline-first)
        invitation.inviterId = currentUserId
        invitation.isSynced = false
        modelContext.insert(invitation)
        try modelContext.save()

        print("✅ Invitation créée localement: \(invitation.guestName)")

        // 2. Synchroniser avec Supabase
        do {
            let payload = CreateInvitationPayload.from(
                invitation: invitation,
                inviterId: currentUserId,
                eventId: eventId
            )

            let remoteInvitation: RemoteInvitation = try await supabase.client
                .from("invitations")
                .insert(payload)
                .select()
                .single()
                .execute()
                .value

            // 3. Mettre à jour l'invitation locale avec les données de Supabase
            invitation.shareToken = remoteInvitation.shareToken
            invitation.shareUrl = generateShareURL(token: remoteInvitation.shareToken)
            invitation.isSynced = true
            invitation.lastSyncedAt = Date()

            try modelContext.save()

            print("✅ Invitation synchronisée avec Supabase")
            print("🔗 Share token: \(remoteInvitation.shareToken)")
            print("🔗 Share URL: \(invitation.shareUrl ?? "nil")")

        } catch {
            print("❌ Erreur lors de la sync Supabase: \(error)")
            // L'invitation reste locale, sera resynchronisée plus tard
            throw InvitationError.syncFailed(error)
        }
    }

    // MARK: - Update Invitation

    /// Mettre à jour une invitation (accepter/refuser/approuver)
    /// - Parameter invitation: Invitation à mettre à jour
    /// - Throws: Erreur si la mise à jour échoue
    func updateInvitation(_ invitation: Invitation) async throws {
        // 1. Mettre à jour localement
        invitation.updatedAt = Date()
        invitation.isSynced = false
        try modelContext.save()

        print("✅ Invitation mise à jour localement")

        // 2. Synchroniser avec Supabase
        guard invitation.shareToken != nil else {
            print("⚠️ Invitation non synchronisée, skip update Supabase")
            return
        }

        do {
            let payload = UpdateInvitationPayload(
                status: invitation.status.toRemoteStatus(),
                respondedAt: invitation.respondedAt,
                guestMessage: invitation.guestMessage,
                plusOnes: invitation.plusOnes
            )

            try await supabase.client
                .from("invitations")
                .update(payload)
                .eq("id", value: invitation.id.uuidString)
                .execute()

            invitation.isSynced = true
            invitation.lastSyncedAt = Date()
            try modelContext.save()

            print("✅ Invitation mise à jour dans Supabase")

        } catch {
            print("❌ Erreur lors de la sync Supabase: \(error)")
            throw InvitationError.syncFailed(error)
        }
    }

    // MARK: - Accept/Decline Invitation

    /// Accepter une invitation (côté invité)
    /// - Parameters:
    ///   - invitation: Invitation à accepter
    ///   - message: Message optionnel de l'invité
    /// - Throws: Erreur si l'acceptation échoue
    func acceptInvitation(_ invitation: Invitation, message: String? = nil) async throws {
        guard let currentUserId = supabase.currentUserId else {
            throw InvitationError.notAuthenticated
        }

        // Mettre à jour localement
        invitation.accept(message: message)
        invitation.inviteeUserId = currentUserId

        try await updateInvitation(invitation)

        print("✅ Invitation acceptée")
    }

    /// Refuser une invitation (côté invité)
    /// - Parameters:
    ///   - invitation: Invitation à refuser
    ///   - message: Message optionnel de l'invité
    /// - Throws: Erreur si le refus échoue
    func declineInvitation(_ invitation: Invitation, message: String? = nil) async throws {
        guard let currentUserId = supabase.currentUserId else {
            throw InvitationError.notAuthenticated
        }

        // Mettre à jour localement
        invitation.decline(message: message)
        invitation.inviteeUserId = currentUserId

        try await updateInvitation(invitation)

        print("✅ Invitation refusée")
    }

    // MARK: - Approve/Reject Request

    /// Approuver une demande d'invitation (côté organisateur)
    /// - Parameter invitation: Invitation à approuver
    /// - Throws: Erreur si l'approbation échoue
    func approveInvitationRequest(_ invitation: Invitation) async throws {
        guard invitation.status == .waitingApproval else {
            throw InvitationError.invalidStatus
        }

        invitation.approve()
        try await updateInvitation(invitation)

        print("✅ Demande d'invitation approuvée")
    }

    /// Rejeter une demande d'invitation (côté organisateur)
    /// - Parameter invitation: Invitation à rejeter
    /// - Throws: Erreur si le rejet échoue
    func rejectInvitationRequest(_ invitation: Invitation) async throws {
        guard invitation.status == .waitingApproval else {
            throw InvitationError.invalidStatus
        }

        invitation.reject()
        try await updateInvitation(invitation)

        print("✅ Demande d'invitation rejetée")
    }

    // MARK: - Delete Invitation

    /// Supprimer une invitation
    /// - Parameter invitation: Invitation à supprimer
    /// - Throws: Erreur si la suppression échoue
    func deleteInvitation(_ invitation: Invitation) async throws {
        // 1. Supprimer de Supabase si synchronisée
        if invitation.isSynced, invitation.shareToken != nil {
            do {
                try await supabase.client
                    .from("invitations")
                    .delete()
                    .eq("id", value: invitation.id.uuidString)
                    .execute()

                print("✅ Invitation supprimée de Supabase")
            } catch {
                print("❌ Erreur lors de la suppression Supabase: \(error)")
                // Continue quand même la suppression locale
            }
        }

        // 2. Supprimer localement
        modelContext.delete(invitation)
        try modelContext.save()

        print("✅ Invitation supprimée localement")
    }

    // MARK: - Sync Invitations

    /// Synchroniser toutes les invitations d'un événement avec Supabase
    /// - Parameter eventId: ID de l'événement Supabase
    /// - Throws: Erreur si la synchronisation échoue
    func syncInvitations(for eventId: UUID) async throws {
        do {
            // Récupérer les invitations depuis Supabase
            let remoteInvitations: [RemoteInvitation] = try await supabase.client
                .from("invitations")
                .select()
                .eq("event_id", value: eventId.uuidString)
                .execute()
                .value

            print("📥 \(remoteInvitations.count) invitation(s) récupérée(s) depuis Supabase")

            // Trouver l'événement local correspondant
            let descriptor = FetchDescriptor<MyEvent>(
                predicate: #Predicate { $0.id == eventId }
            )
            guard let myEvent = try modelContext.fetch(descriptor).first else {
                print("⚠️ Événement local non trouvé: \(eventId)")
                return
            }

            // Mettre à jour les invitations locales
            for remoteInvitation in remoteInvitations {
                await updateOrCreateLocalInvitation(from: remoteInvitation, myEvent: myEvent)
            }

            print("✅ Synchronisation des invitations terminée")

        } catch {
            print("❌ Erreur lors de la sync des invitations: \(error)")
            throw InvitationError.syncFailed(error)
        }
    }

    /// Mettre à jour ou créer une invitation locale depuis une remote
    private func updateOrCreateLocalInvitation(
        from remoteInvitation: RemoteInvitation,
        myEvent: MyEvent
    ) async {
        // Chercher si l'invitation existe déjà localement
        let descriptor = FetchDescriptor<Invitation>(
            predicate: #Predicate { $0.id == remoteInvitation.id }
        )

        do {
            if let existingInvitation = try modelContext.fetch(descriptor).first {
                // Mettre à jour l'invitation existante
                existingInvitation.guestName = remoteInvitation.guestName
                existingInvitation.guestEmail = remoteInvitation.guestEmail
                existingInvitation.guestPhoneNumber = remoteInvitation.guestPhoneNumber
                existingInvitation.status = InvitationStatus.fromRemoteStatus(remoteInvitation.status)
                existingInvitation.respondedAt = remoteInvitation.respondedAt
                existingInvitation.guestMessage = remoteInvitation.guestMessage
                existingInvitation.plusOnes = remoteInvitation.plusOnes
                existingInvitation.shareToken = remoteInvitation.shareToken
                existingInvitation.shareUrl = remoteInvitation.shareUrl
                existingInvitation.inviterId = remoteInvitation.inviterId
                existingInvitation.inviteeUserId = remoteInvitation.inviteeUserId
                existingInvitation.isSynced = true
                existingInvitation.lastSyncedAt = Date()
                existingInvitation.updatedAt = remoteInvitation.updatedAt

                print("✅ Invitation locale mise à jour: \(existingInvitation.guestName)")
            } else {
                // Créer une nouvelle invitation locale
                let newInvitation = remoteInvitation.toLocalInvitation(myEvent: myEvent)
                newInvitation.shareToken = remoteInvitation.shareToken
                newInvitation.shareUrl = remoteInvitation.shareUrl
                newInvitation.inviterId = remoteInvitation.inviterId
                newInvitation.inviteeUserId = remoteInvitation.inviteeUserId
                newInvitation.isSynced = true
                newInvitation.lastSyncedAt = Date()

                modelContext.insert(newInvitation)
                print("✅ Nouvelle invitation locale créée: \(newInvitation.guestName)")
            }

            try modelContext.save()
        } catch {
            print("❌ Erreur lors de la mise à jour locale: \(error)")
        }
    }

    // MARK: - Share URL Generation

    /// Générer l'URL de partage pour une invitation
    /// - Parameter token: Token de partage unique
    /// - Returns: URL de partage complète
    func generateShareURL(token: String) -> String {
        return "\(baseDeepLinkURL)?token=\(token)"
    }

    /// Générer le message de partage pour une invitation
    /// - Parameters:
    ///   - invitation: Invitation à partager
    ///   - eventTitle: Titre de l'événement
    ///   - eventDate: Date de l'événement
    /// - Returns: Message pré-rempli pour SMS/WhatsApp
    func generateShareMessage(
        for invitation: Invitation,
        eventTitle: String,
        eventDate: Date
    ) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "fr_FR")

        let formattedDate = dateFormatter.string(from: eventDate)

        guard let shareUrl = invitation.shareUrl else {
            return """
            Salut \(invitation.guestName) !

            Je t'invite à mon événement "\(eventTitle)" le \(formattedDate).

            Rejoins-moi sur l'app Moments pour confirmer ta présence !
            """
        }

        return """
        Salut \(invitation.guestName) !

        Je t'invite à mon événement "\(eventTitle)" le \(formattedDate).

        Clique ici pour répondre :
        \(shareUrl)

        À bientôt ! 🎉
        """
    }

    // MARK: - Fetch Invitation by Token

    /// Récupérer une invitation depuis Supabase par son token
    /// - Parameter token: Token de partage
    /// - Returns: RemoteInvitation correspondante
    /// - Throws: Erreur si l'invitation n'est pas trouvée
    func fetchInvitation(by token: String) async throws -> RemoteInvitation {
        do {
            let invitation: RemoteInvitation = try await supabase.client
                .from("invitations")
                .select()
                .eq("share_token", value: token)
                .single()
                .execute()
                .value

            print("✅ Invitation trouvée par token: \(invitation.guestName)")
            return invitation

        } catch {
            print("❌ Invitation non trouvée pour le token: \(token)")
            throw InvitationError.invitationNotFound
        }
    }

    // MARK: - Statistics

    /// Récupérer les statistiques des invitations d'un événement
    /// - Parameter eventId: ID de l'événement
    /// - Returns: Statistiques des invitations
    /// - Throws: Erreur si la requête échoue
    func getInvitationStats(for eventId: UUID) async throws -> InvitationStats {
        do {
            // Appeler la fonction SQL get_event_invitation_stats
            let response = try await supabase.client
                .rpc("get_event_invitation_stats", params: ["event_uuid": eventId.uuidString])
                .execute()

            let stats: InvitationStats = try JSONDecoder().decode(
                InvitationStats.self,
                from: response.data
            )

            print("📊 Stats récupérées: \(stats.totalInvitations) invitation(s)")
            return stats

        } catch {
            print("❌ Erreur lors de la récupération des stats: \(error)")
            throw InvitationError.syncFailed(error)
        }
    }
}

// MARK: - Errors

enum InvitationError: LocalizedError {
    case notAuthenticated
    case syncFailed(Error)
    case invalidStatus
    case invitationNotFound

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Vous devez être connecté pour gérer les invitations"
        case .syncFailed(let error):
            return "Erreur de synchronisation: \(error.localizedDescription)"
        case .invalidStatus:
            return "Le statut de l'invitation ne permet pas cette action"
        case .invitationNotFound:
            return "Invitation non trouvée"
        }
    }
}
