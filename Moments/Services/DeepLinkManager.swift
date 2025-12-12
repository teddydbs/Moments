//
//  DeepLinkManager.swift
//  Moments
//
//  Description: Gestion des deep links pour partager des événements
//  Architecture: Service (Singleton)
//

import Foundation
import SwiftUI

/// Gestionnaire de deep links pour partager et ouvrir des événements
@Observable
class DeepLinkManager {
    // ✅ Singleton pour accès global
    static let shared = DeepLinkManager()

    /// URL scheme personnalisé de l'app
    private let urlScheme = "moments://"

    /// L'événement à ouvrir (détecté depuis un deep link)
    var eventToOpen: UUID?

    /// Le token d'invitation à traiter (détecté depuis un deep link)
    var invitationTokenToHandle: String?

    private init() {}

    // MARK: - Génération de liens

    /// Génère un lien de partage pour un événement
    /// - Parameter eventId: L'ID de l'événement à partager
    /// - Returns: L'URL de partage
    func generateEventShareLink(eventId: UUID) -> URL {
        // ❓ POURQUOI ce format ?
        // moments://event/{eventId} est notre URL scheme personnalisé
        // Il sera intercepté par l'app quand quelqu'un clique dessus
        let urlString = "\(urlScheme)event/\(eventId.uuidString)"
        return URL(string: urlString)!
    }

    /// Génère un message de partage complet pour un événement
    /// - Parameters:
    ///   - eventTitle: Le titre de l'événement
    ///   - eventDate: La date de l'événement
    ///   - eventTime: L'heure de l'événement (optionnel)
    ///   - eventId: L'ID de l'événement
    /// - Returns: Le texte à partager avec le lien
    func generateShareMessage(eventTitle: String, eventDate: Date, eventTime: Date?, eventId: UUID) -> String {
        let link = generateEventShareLink(eventId: eventId)

        // ✅ Formatter pour la date (sans l'heure)
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "fr_FR")

        var formattedDate = dateFormatter.string(from: eventDate)

        // ✅ Si une heure est spécifiée, l'ajouter
        if let eventTime = eventTime {
            let timeFormatter = DateFormatter()
            timeFormatter.timeStyle = .short
            timeFormatter.locale = Locale(identifier: "fr_FR")

            let formattedTime = timeFormatter.string(from: eventTime)
            formattedDate += " à \(formattedTime)"
        }

        return """
        🎉 Tu es invité(e) à mon événement !

        📅 \(eventTitle)
        🗓️ \(formattedDate)

        Clique sur ce lien pour voir tous les détails :
        \(link.absoluteString)
        """
    }

    // MARK: - Génération de liens d'invitation

    /// Génère un lien de partage pour une invitation
    /// - Parameter token: Le token unique de l'invitation
    /// - Returns: L'URL d'invitation
    func generateInvitationShareLink(token: String) -> URL {
        let urlString = "\(urlScheme)invite?token=\(token)"
        return URL(string: urlString)!
    }

    /// Génère un message de partage complet pour une invitation
    /// - Parameters:
    ///   - guestName: Le nom de l'invité
    ///   - eventTitle: Le titre de l'événement
    ///   - eventDate: La date de l'événement
    ///   - token: Le token d'invitation
    /// - Returns: Le texte à partager avec le lien
    func generateInvitationMessage(
        guestName: String,
        eventTitle: String,
        eventDate: Date,
        token: String
    ) -> String {
        let link = generateInvitationShareLink(token: token)

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        dateFormatter.locale = Locale(identifier: "fr_FR")

        let formattedDate = dateFormatter.string(from: eventDate)

        return """
        Salut \(guestName) ! 👋

        Je t'invite à mon événement "\(eventTitle)" le \(formattedDate).

        Clique sur ce lien pour répondre à l'invitation :
        \(link.absoluteString)

        À bientôt ! 🎉
        """
    }

    // MARK: - Parsing de liens

    /// Parse une URL reçue pour extraire l'ID de l'événement ou le token d'invitation
    /// - Parameter url: L'URL à parser
    /// - Returns: L'ID de l'événement si valide, nil sinon
    func handleIncomingURL(_ url: URL) -> UUID? {
        // ❓ POURQUOI guard ?
        // On vérifie que c'est bien notre URL scheme
        guard url.scheme == "moments" else {
            print("❌ URL scheme invalide: \(url.scheme ?? "nil")")
            return nil
        }

        let host = url.host()

        // ✅ CAS 1: Invitation (moments://invite?token=XXX)
        if host == "invite" {
            return handleInvitationURL(url)
        }

        // ✅ CAS 2: Événement (moments://event/{eventId})
        guard host == "event" else {
            print("❌ Host invalide: \(host ?? "nil")")
            return nil
        }

        // ✅ ÉTAPE 2: Extraire le path (l'ID de l'événement)
        let path = url.path()
        let eventIdString = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        // ✅ ÉTAPE 3: Convertir en UUID
        guard let eventId = UUID(uuidString: eventIdString) else {
            print("❌ UUID invalide: \(eventIdString)")
            return nil
        }

        print("✅ Événement détecté depuis le lien: \(eventId)")
        return eventId
    }

    /// Parse une URL d'invitation pour extraire le token
    /// - Parameter url: L'URL d'invitation (moments://invite?token=XXX)
    /// - Returns: Nil (le token est stocké dans invitationTokenToHandle)
    private func handleInvitationURL(_ url: URL) -> UUID? {
        // Extraire le query parameter "token"
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              let tokenItem = queryItems.first(where: { $0.name == "token" }),
              let token = tokenItem.value else {
            print("❌ Token d'invitation manquant dans l'URL")
            return nil
        }

        print("✅ Invitation détectée depuis le lien: token=\(token)")

        // Stocker le token pour qu'il soit traité par l'app
        self.invitationTokenToHandle = token

        // Retourner nil car ce n'est pas un événement direct
        return nil
    }

    /// Définit l'événement à ouvrir (depuis un deep link)
    /// - Parameter eventId: L'ID de l'événement
    func setEventToOpen(_ eventId: UUID) {
        self.eventToOpen = eventId
    }

    /// Réinitialise l'événement à ouvrir (après l'avoir traité)
    func clearEventToOpen() {
        self.eventToOpen = nil
    }

    /// Définit le token d'invitation à traiter
    /// - Parameter token: Le token d'invitation
    func setInvitationTokenToHandle(_ token: String) {
        self.invitationTokenToHandle = token
    }

    /// Réinitialise le token d'invitation (après l'avoir traité)
    func clearInvitationToken() {
        self.invitationTokenToHandle = nil
    }
}

// MARK: - Share Sheet Helper

/// Présente la feuille de partage native iOS
/// - Parameters:
///   - items: Les éléments à partager (texte, liens, images)
///   - completion: Callback optionnel appelé après le partage
func presentShareSheet(items: [Any], completion: (() -> Void)? = nil) {
    // ❓ POURQUOI UIActivityViewController ?
    // C'est le controller natif iOS pour partager du contenu
    // Il affiche automatiquement toutes les apps de partage disponibles
    let activityVC = UIActivityViewController(
        activityItems: items,
        applicationActivities: nil
    )

    // ✅ Callback de completion
    activityVC.completionWithItemsHandler = { _, _, _, _ in
        completion?()
    }

    // ✅ ÉTAPE: Trouver la fenêtre principale pour présenter le controller
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let rootViewController = windowScene.windows.first?.rootViewController {

        // ⚠️ IMPORTANT: Sur iPad, il faut spécifier une position pour le popover
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = rootViewController.view
            popoverController.sourceRect = CGRect(
                x: rootViewController.view.bounds.midX,
                y: rootViewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }

        rootViewController.present(activityVC, animated: true)
    }
}
