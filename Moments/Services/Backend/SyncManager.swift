//
//  SyncManager.swift
//  Moments
//
//  Gestion de la synchronisation SwiftData ↔ Supabase
//

import Foundation
import SwiftData
import SwiftUI
import Combine

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
        let remoteEvents = try await supabase.fetchEvents()
        print("📥 Fetched \(remoteEvents.count) events from Supabase")

        // Récupérer tous les événements locaux
        let localEvents = try modelContext.fetch(FetchDescriptor<Event>())
        print("📱 Found \(localEvents.count) local events")

        // Créer un dictionnaire des événements locaux pour un accès rapide
        let localEventsByID = Dictionary(uniqueKeysWithValues: localEvents.map { ($0.id, $0) })

        // Synchroniser les événements
        for remoteEvent in remoteEvents {
            if let localEvent = localEventsByID[remoteEvent.id] {
                // L'événement existe localement, vérifier s'il faut le mettre à jour
                if remoteEvent.updatedAt > (localEvent.updatedAt ?? Date.distantPast) {
                    print("🔄 Updating local event: \(localEvent.title)")
                    updateLocalEvent(localEvent, with: remoteEvent)
                }
            } else {
                // Nouvel événement distant → Créer localement
                print("➕ Creating new local event: \(remoteEvent.title)")
                createLocalEvent(from: remoteEvent)
            }
        }

        // Supprimer les événements locaux qui n'existent plus sur Supabase
        let remoteEventIDs = Set(remoteEvents.map { $0.id })
        for localEvent in localEvents {
            if !remoteEventIDs.contains(localEvent.id) && localEvent.existsOnServer {
                print("🗑️ Deleting local event (removed from server): \(localEvent.title)")
                modelContext.delete(localEvent)
            }
        }

        // Sauvegarder les changements
        try modelContext.save()
        print("💾 Local changes saved")
    }

    // MARK: - Push (Local → Supabase)

    private func pushToSupabase() async throws {
        // Récupérer tous les événements locaux marqués comme "non synchronisés"
        let localEvents = try modelContext.fetch(FetchDescriptor<Event>())
        let eventsToSync = localEvents.filter { $0.needsSync }

        print("📤 Found \(eventsToSync.count) events to push")

        for localEvent in eventsToSync {
            do {
                if localEvent.existsOnServer {
                    // UPDATE: L'événement existe déjà sur le serveur
                    print("🔄 Updating remote event: \(localEvent.title)")
                    try await supabase.updateEvent(
                        id: localEvent.id.uuidString,
                        title: localEvent.title,
                        date: localEvent.date,
                        notes: localEvent.notes,
                        hasGiftPool: localEvent.hasGiftPool,
                        isRecurring: localEvent.isRecurring
                    )
                } else {
                    // CREATE: Nouvel événement à créer sur le serveur
                    print("➕ Creating remote event: \(localEvent.title)")
                    let remoteEvent = try await supabase.createEvent(
                        title: localEvent.title,
                        date: localEvent.date,
                        category: localEvent.category.rawValue,
                        notes: localEvent.notes,
                        hasGiftPool: localEvent.hasGiftPool,
                        isRecurring: localEvent.isRecurring
                    )

                    // Mettre à jour l'ID local si différent
                    if localEvent.id != remoteEvent.id {
                        localEvent.id = remoteEvent.id
                    }

                    localEvent.existsOnServer = true
                }

                // Marquer comme synchronisé
                localEvent.needsSync = false
                localEvent.updatedAt = Date()

                // Synchroniser les participants de cet événement
                try await syncParticipants(for: localEvent)

                // Synchroniser les idées cadeaux de cet événement
                try await syncGiftIdeas(for: localEvent)

            } catch {
                print("❌ Failed to sync event \(localEvent.id): \(error)")
                // Continuer avec les autres événements même en cas d'erreur
            }
        }

        // Sauvegarder les changements
        try modelContext.save()
        print("💾 Sync flags saved")
    }

    // MARK: - Synchronisation des participants

    private func syncParticipants(for event: Event) async throws {
        let remoteParticipants = try await supabase.fetchParticipants(eventId: event.id.uuidString)
        let localParticipants = event.participants

        // Créer un dictionnaire des participants locaux
        let localParticipantsByID = Dictionary(uniqueKeysWithValues: localParticipants.map { ($0.id, $0) })

        // Synchroniser depuis le serveur
        for remoteParticipant in remoteParticipants {
            if !localParticipantsByID.keys.contains(remoteParticipant.id) {
                // Nouveau participant distant → Créer localement
                let newParticipant = Participant(
                    id: remoteParticipant.id,
                    name: remoteParticipant.name,
                    phone: remoteParticipant.phone,
                    email: remoteParticipant.email,
                    source: ParticipantSource(rawValue: remoteParticipant.source) ?? .manual,
                    contactIdentifier: remoteParticipant.contactIdentifier,
                    socialMediaId: remoteParticipant.socialMediaId
                )
                newParticipant.event = event
                event.participants.append(newParticipant)
                modelContext.insert(newParticipant)
            }
        }

        // Envoyer les participants locaux non synchronisés
        let remoteParticipantIDs = Set(remoteParticipants.map { $0.id })
        for localParticipant in localParticipants {
            if !remoteParticipantIDs.contains(localParticipant.id) {
                // Participant local non présent sur le serveur → Créer sur le serveur
                _ = try await supabase.createParticipant(
                    eventId: event.id.uuidString,
                    name: localParticipant.name,
                    phone: localParticipant.phone,
                    email: localParticipant.email,
                    source: localParticipant.source.rawValue
                )
            }
        }
    }

    // MARK: - Synchronisation des idées cadeaux

    private func syncGiftIdeas(for event: Event) async throws {
        let remoteGiftIdeas = try await supabase.fetchGiftIdeas(eventId: event.id.uuidString)
        let localGiftIdeas = event.giftIdeas

        // Créer un dictionnaire des idées locales
        let localGiftIdeasByID = Dictionary(uniqueKeysWithValues: localGiftIdeas.map { ($0.id, $0) })

        // Synchroniser depuis le serveur
        for remoteGiftIdea in remoteGiftIdeas {
            if !localGiftIdeasByID.keys.contains(remoteGiftIdea.id) {
                // Nouvelle idée distante → Créer localement
                let newGiftIdea = GiftIdea(
                    id: remoteGiftIdea.id,
                    title: remoteGiftIdea.title,
                    productURL: remoteGiftIdea.productUrl,
                    productImageURL: remoteGiftIdea.productImageUrl,
                    price: remoteGiftIdea.price,
                    proposedBy: remoteGiftIdea.proposedBy
                )
                newGiftIdea.event = event
                event.giftIdeas.append(newGiftIdea)
                modelContext.insert(newGiftIdea)
            }
        }

        // Envoyer les idées locales non synchronisées
        let remoteGiftIdeaIDs = Set(remoteGiftIdeas.map { $0.id })
        for localGiftIdea in localGiftIdeas {
            if !remoteGiftIdeaIDs.contains(localGiftIdea.id) {
                // Idée locale non présente sur le serveur → Créer sur le serveur
                _ = try await supabase.createGiftIdea(
                    eventId: event.id.uuidString,
                    title: localGiftIdea.title,
                    description: nil,
                    productUrl: localGiftIdea.productURL,
                    proposedBy: localGiftIdea.proposedBy
                )
            }
        }
    }

    // MARK: - Helpers

    private func updateLocalEvent(_ local: Event, with remote: RemoteEvent) {
        local.title = remote.title
        local.date = remote.date
        local.notes = remote.notes
        local.hasGiftPool = remote.hasGiftPool
        local.isRecurring = remote.isRecurring
        local.updatedAt = remote.updatedAt

        // Convertir la catégorie
        if let category = EventCategory.allCases.first(where: { $0.rawValue == remote.category }) {
            local.category = category
        }
    }

    private func createLocalEvent(from remote: RemoteEvent) {
        // Convertir la catégorie
        guard let category = EventCategory.allCases.first(where: { $0.rawValue == remote.category }) else {
            print("⚠️ Unknown category: \(remote.category)")
            return
        }

        let newEvent = Event(
            id: remote.id,
            title: remote.title,
            date: remote.date,
            category: category,
            isRecurring: remote.isRecurring,
            notes: remote.notes,
            imageData: nil,
            hasGiftPool: remote.hasGiftPool
        )

        newEvent.existsOnServer = true
        newEvent.needsSync = false
        newEvent.updatedAt = remote.updatedAt

        modelContext.insert(newEvent)
    }

    // MARK: - Sync déclenché par les changements

    /// Marquer un événement comme nécessitant une synchronisation
    func markEventForSync(_ event: Event) {
        event.needsSync = true
        event.updatedAt = Date()
    }

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

// MARK: - Extensions au modèle Event pour le sync

extension Event {
    @Transient
    var needsSync: Bool {
        get {
            // Utiliser UserDefaults comme stockage temporaire
            UserDefaults.standard.bool(forKey: "needsSync_\(id.uuidString)")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "needsSync_\(id.uuidString)")
        }
    }

    @Transient
    var existsOnServer: Bool {
        get {
            UserDefaults.standard.bool(forKey: "existsOnServer_\(id.uuidString)")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "existsOnServer_\(id.uuidString)")
        }
    }

    @Transient
    var updatedAt: Date? {
        get {
            UserDefaults.standard.object(forKey: "updatedAt_\(id.uuidString)") as? Date
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "updatedAt_\(id.uuidString)")
        }
    }
}
