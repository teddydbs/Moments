//
//  MainTabView.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(DeepLinkManager.self) private var deepLinkManager
    @Query private var allMyEvents: [MyEvent]

    @State private var selectedTab = 0
    @State private var eventToShow: MyEvent?
    @State private var wishlistManager: WishlistManager?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Accueil", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                BirthdaysView()
            }
            .tabItem {
                Label("Anniversaires", systemImage: "gift.fill")
            }
            .tag(1)

            NavigationStack {
                EventsView()
            }
            .tabItem {
                Label("Événements", systemImage: "calendar")
            }
            .tag(2)

            NavigationStack {
                MyWishlistView()
            }
            .tabItem {
                Label("Wishlists", systemImage: "heart.text.square.fill")
            }
            .tag(3)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Profil", systemImage: "person.fill")
            }
            .tag(4)

            // 🧪 ONGLET TEMPORAIRE: Test Supabase
            NavigationStack {
                SupabaseTestView()
            }
            .tabItem {
                Label("Test DB", systemImage: "externaldrive.badge.checkmark")
            }
            .tag(5)
        }
        .tint(MomentsTheme.primaryPurple)
        .onAppear {
            // Initialiser le WishlistManager
            if wishlistManager == nil {
                wishlistManager = WishlistManager(modelContext: modelContext)
            }
            syncWithShareExtension()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            syncWithShareExtension()
        }
        .onChange(of: deepLinkManager.eventToOpen) { _, eventId in
            handleDeepLinkEvent(eventId)
        }
        .sheet(item: $eventToShow) { event in
            MyEventDetailView(myEvent: event)
        }
    }

    // MARK: - Deep Link Handling

    /// Gère l'ouverture d'un événement depuis un deep link
    /// - Parameter eventId: L'ID de l'événement à ouvrir
    private func handleDeepLinkEvent(_ eventId: UUID?) {
        guard let eventId = eventId else { return }

        print("🔗 Tentative d'ouverture de l'événement: \(eventId)")

        // ✅ ÉTAPE 1: Chercher l'événement dans SwiftData
        if let event = allMyEvents.first(where: { $0.id == eventId }) {
            print("✅ Événement trouvé: \(event.title)")

            // ✅ ÉTAPE 2: Basculer vers l'onglet Événements
            selectedTab = 2

            // ✅ ÉTAPE 3: Afficher le détail de l'événement après un court délai
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                eventToShow = event
                // ✅ ÉTAPE 4: Réinitialiser l'état du deep link manager
                deepLinkManager.clearEventToOpen()
            }
        } else {
            print("❌ Événement non trouvé avec l'ID: \(eventId)")
            // TODO: Afficher une alerte ou télécharger l'événement depuis Supabase
        }
    }

    // MARK: - Share Extension Sync

    /// Synchronise les données avec la Share Extension
    private func syncWithShareExtension() {
        // 1. Exporter les événements vers SharedDataManager
        exportEventsToShareExtension()

        // 2. Importer les produits en attente depuis la Share Extension
        importPendingWishlistItems()
    }

    /// Exporte les événements vers SharedDataManager pour la Share Extension
    private func exportEventsToShareExtension() {
        let sharedEvents = allMyEvents.map { event in
            SharedEvent(
                id: event.id,
                title: event.title,
                icon: event.type.icon,
                date: event.date
            )
        }

        SharedDataManager.shared.saveAvailableEvents(sharedEvents)
        print("✅ \(sharedEvents.count) événements exportés vers Share Extension")
    }

    /// Importe les produits en attente depuis la Share Extension
    private func importPendingWishlistItems() {
        guard let manager = wishlistManager else {
            print("⚠️ WishlistManager non initialisé")
            return
        }

        let pendingItems = SharedDataManager.shared.getPendingWishlistItems()

        guard !pendingItems.isEmpty else {
            print("ℹ️ Aucun produit en attente à importer")
            return
        }

        print("📥 Importation de \(pendingItems.count) produit(s) depuis Share Extension")

        Task {
            for pendingItem in pendingItems {
                do {
                    // Trouver l'événement associé
                    let event = allMyEvents.first(where: { $0.id == pendingItem.eventId })

                    // Créer le WishlistItem
                    let wishlistItem = WishlistItem(
                        title: pendingItem.title ?? "Produit",
                        itemDescription: nil,
                        price: pendingItem.price,
                        url: pendingItem.url,
                        image: pendingItem.imageData,
                        category: .autre,
                        status: .wanted,
                        priority: pendingItem.priority,
                        contact: nil,
                        myEvent: event
                    )

                    // Associer à l'événement
                    if let event = event {
                        print("✅ Produit associé à l'événement: \(event.title)")
                    } else {
                        print("⚠️ Aucun événement trouvé pour le produit")
                    }

                    // ✅ Sauvegarder avec WishlistManager (synchronise avec Supabase)
                    try await manager.addItem(wishlistItem)
                    print("✅ Produit importé et synchronisé: \(wishlistItem.title)")

                } catch {
                    print("❌ Erreur lors de l'import du produit: \(error)")
                }
            }

            // Supprimer les produits en attente
            SharedDataManager.shared.clearPendingWishlistItems()
            print("✅ Tous les produits en attente ont été importés")
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Event.self, inMemory: true)
}
