//
//  SyncManager.swift
//  Moments
//
//  Gestion de la synchronisation SwiftData ↔ Supabase
//  Architecture: Service Layer
//

import Foundation
import SwiftData
import SwiftUI
import Combine

/// Manager de synchronisation bidirectionnelle entre SwiftData local et Supabase
@MainActor
class SyncManager: ObservableObject {
    private let modelContext: ModelContext
    private let supabase = SupabaseManager.shared

    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?
    @Published var syncStatus: SyncStatus = .idle

    enum SyncStatus {
        case idle
        case pulling
        case pushing
        case completed
        case error(String)
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.lastSyncDate = UserDefaults.standard.object(forKey: "lastSyncDate") as? Date
    }

    // MARK: - Synchronisation complète

    /// Synchronisation complète : Pull depuis Supabase → Push vers Supabase
    func performFullSync() async throws {
        guard !isSyncing else {
            print("⚠️ Sync already in progress")
            return
        }

        guard supabase.isAuthenticated else {
            print("⚠️ User not authenticated, skipping sync")
            return
        }

        isSyncing = true
        syncStatus = .pulling

        do {
            // 1. Pull: Récupérer toutes les données depuis Supabase
            print("📥 Starting pull from Supabase...")
            try await pullFromSupabase()

            syncStatus = .pushing

            // 2. Push: Envoyer les modifications locales non synchronisées
            print("📤 Starting push to Supabase...")
            try await pushToSupabase()

            // 3. Mettre à jour la date de dernière sync
            lastSyncDate = Date()
            UserDefaults.standard.set(lastSyncDate, forKey: "lastSyncDate")

            syncStatus = .completed
            print("✅ Sync completed successfully")
        } catch {
            syncError = error
            syncStatus = .error(error.localizedDescription)
            print("❌ Sync failed: \(error)")
            throw error
        }

        isSyncing = false
    }

    // MARK: - Pull (Supabase → Local)

    private func pullFromSupabase() async throws {
        // Récupérer tous les événements depuis Supabase
        let remoteEvents = try await supabase.fetchMyEvents()
        print("📥 Fetched \(remoteEvents.count) events from Supabase")

        // Récupérer tous les événements locaux
        let localEvents = try modelContext.fetch(FetchDescriptor<MyEvent>())
        print("📱 Found \(localEvents.count) local events")

        // Créer un dictionnaire des événements locaux pour un accès rapide
        let localEventsByID = Dictionary(uniqueKeysWithValues: localEvents.map { ($0.id, $0) })

        // Synchroniser les événements
        for remoteEvent in remoteEvents {
            if let localEvent = localEventsByID[remoteEvent.id] {
                // L'événement existe localement, vérifier s'il faut le mettre à jour
                // TODO: Comparer les dates de mise à jour
                print("🔄 Event already exists locally: \(localEvent.title)")
            } else {
                // Nouvel événement distant → Créer localement
                print("➕ Creating new local event: \(remoteEvent.title)")
                try await createLocalMyEvent(from: remoteEvent)
            }
        }

        // Sauvegarder les changements
        try modelContext.save()
        print("💾 Local changes saved")
    }

    // MARK: - Push (Local → Supabase)

    private func pushToSupabase() async throws {
        // Récupérer tous les événements locaux
        let localEvents = try modelContext.fetch(FetchDescriptor<MyEvent>())

        print("📤 Pushing \(localEvents.count) local events to Supabase...")

        for localEvent in localEvents {
            do {
                // Vérifier si l'événement existe déjà sur le serveur
                let existsOnServer = getExistsOnServer(for: localEvent.id)

                if existsOnServer {
                    // UPDATE: L'événement existe déjà sur le serveur
                    print("🔄 Updating remote event: \(localEvent.title)")
                    let remoteEvent = RemoteMyEvent(
                        from: localEvent,
                        ownerId: supabase.currentUserId
                    )
                    try await supabase.updateMyEvent(remoteEvent)
                } else {
                    // CREATE: Nouvel événement à créer sur le serveur
                    print("➕ Creating remote event: \(localEvent.title)")
                    let remoteEvent = RemoteMyEvent(
                        from: localEvent,
                        ownerId: supabase.currentUserId
                    )
                    _ = try await supabase.createMyEvent(remoteEvent)
                    setExistsOnServer(for: localEvent.id, value: true)
                }

                // Synchroniser les invitations de cet événement
                try await syncInvitations(for: localEvent)

                // Synchroniser les produits wishlist de cet événement
                try await syncWishlistItems(for: localEvent)

                // Synchroniser les photos de cet événement
                try await syncEventPhotos(for: localEvent)

            } catch {
                print("❌ Failed to sync event \(localEvent.id): \(error)")
                // Continuer avec les autres événements même en cas d'erreur
            }
        }

        // Sauvegarder les changements
        try modelContext.save()
        print("💾 Sync flags saved")
    }

    // MARK: - Synchronisation des invitations

    private func syncInvitations(for event: MyEvent) async throws {
        guard let invitations = event.invitations else { return }

        let remoteInvitations = try await supabase.fetchInvitations(for: event.id)
        let remoteInvitationIDs = Set(remoteInvitations.map { $0.id })

        // Envoyer les invitations locales non présentes sur le serveur
        for invitation in invitations {
            if !remoteInvitationIDs.contains(invitation.id) {
                print("➕ Creating remote invitation for: \(invitation.guestName)")
                let remoteInvitation = RemoteInvitation(from: invitation)
                _ = try await supabase.createInvitation(remoteInvitation)
            }
        }
    }

    // MARK: - Synchronisation des produits wishlist

    /// ⚠️ OBSOLÈTE: La synchronisation de la wishlist est maintenant gérée par WishlistManager
    ///
    /// Cette méthode utilisait l'ancien schéma où les wishlists étaient liées aux événements.
    /// Maintenant, la wishlist personnelle est synchronisée indépendamment des événements
    /// via WishlistManager.
    ///
    /// TODO: Supprimer cette méthode une fois la migration complète
    private func syncWishlistItems(for event: MyEvent) async throws {
        print("⚠️ syncWishlistItems est obsolète - utiliser WishlistManager à la place")
        // Ne rien faire - la wishlist est gérée par WishlistManager
    }

    // MARK: - Synchronisation des photos

    private func syncEventPhotos(for event: MyEvent) async throws {
        guard let photos = event.eventPhotos else { return }

        let remotePhotos = try await supabase.fetchEventPhotos(for: event.id)
        let remotePhotoIDs = Set(remotePhotos.map { $0.id })

        // Upload et créer les photos locales non présentes sur le serveur
        for photo in photos {
            if !remotePhotoIDs.contains(photo.id) {
                print("➕ Uploading event photo to Storage...")

                // Upload l'image vers Storage
                let imageData = photo.imageData

                let fileName = "\(photo.id.uuidString).jpg"
                let imageUrl = try await supabase.uploadImage(
                    imageData,
                    toBucket: "event-photos",
                    fileName: fileName
                )

                // Créer l'enregistrement de la photo
                let remotePhoto = RemoteEventPhoto(from: photo, imageUrl: imageUrl)
                _ = try await supabase.createEventPhoto(remotePhoto)
            }
        }
    }

    // MARK: - Helpers

    /// Créer un MyEvent local depuis un RemoteMyEvent
    private func createLocalMyEvent(from remote: RemoteMyEvent) async throws {
        // Convertir le type
        guard let eventType = MyEventType(rawValue: remote.type) else {
            print("⚠️ Unknown event type: \(remote.type)")
            return
        }

        // Parser la date
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        guard let date = dateFormatter.date(from: remote.date) else {
            print("⚠️ Invalid date format: \(remote.date)")
            return
        }

        // Parser l'heure (optionnel)
        var time: Date?
        if let timeString = remote.time {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            time = timeFormatter.date(from: timeString)
        }

        // Parser rsvpDeadline (optionnel)
        var rsvpDeadline: Date?
        if let deadlineString = remote.rsvpDeadline {
            rsvpDeadline = dateFormatter.date(from: deadlineString)
        }

        // Créer le nouvel événement local
        let newEvent = MyEvent(
            id: remote.id,
            type: eventType,
            title: remote.title,
            eventDescription: remote.eventDescription,
            date: date,
            time: time,
            location: remote.location,
            locationAddress: remote.locationAddress,
            maxGuests: remote.maxGuests,
            rsvpDeadline: rsvpDeadline
        )

        // Marquer comme existant sur le serveur
        setExistsOnServer(for: newEvent.id, value: true)

        modelContext.insert(newEvent)
    }

    // MARK: - Persistance des flags de sync

    /// Vérifier si un événement existe sur le serveur
    private func getExistsOnServer(for id: UUID) -> Bool {
        UserDefaults.standard.bool(forKey: "existsOnServer_\(id.uuidString)")
    }

    /// Marquer un événement comme existant (ou non) sur le serveur
    private func setExistsOnServer(for id: UUID, value: Bool) {
        UserDefaults.standard.set(value, forKey: "existsOnServer_\(id.uuidString)")
    }

    // MARK: - API publique

    /// Synchronisation rapide (push uniquement)
    func quickSync() async {
        guard !isSyncing && supabase.isAuthenticated else { return }

        do {
            try await pushToSupabase()
        } catch {
            print("❌ Quick sync failed: \(error)")
        }
    }
}
