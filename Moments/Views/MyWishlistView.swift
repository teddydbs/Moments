//
//  MyWishlistView.swift
//  Moments
//
//  Vue centralisée de TOUTES mes wishlists groupées par événement
//

import SwiftUI
import SwiftData

struct MyWishlistView: View {
    @Environment(\.modelContext) private var modelContext

    // 🆕 WishlistManager pour la synchronisation Supabase
    @StateObject private var wishlistManager: WishlistManager

    // Query tous mes événements
    @Query(sort: \MyEvent.date, order: .forward) private var allMyEvents: [MyEvent]

    // Query tous les wishlist items LOCAUX
    @Query private var allWishlistItems: [WishlistItem]

    // Mes wishlists (cadeaux liés à mes événements)
    private var myWishlistItems: [WishlistItem] {
        allWishlistItems.filter { $0.isMyWishlistItem }
    }

    // Grouper par événement
    private var wishlistsByEvent: [(MyEvent, [WishlistItem])] {
        let eventsWithWishlists = allMyEvents.compactMap { event -> (MyEvent, [WishlistItem])? in
            let items = myWishlistItems.filter { $0.myEvent?.id == event.id }
            return items.isEmpty ? nil : (event, items)
        }
        return eventsWithWishlists
    }

    @State private var showingSettings = false
    @State private var selectedEvent: MyEvent?
    @State private var showingAddWishlistItem = false
    @State private var itemToEdit: WishlistItem?
    @State private var showingSyncError = false

    // MARK: - Initialization

    /// ✅ Initialiser le manager avec le modelContext
    init() {
        // ⚠️ On utilise un placeholder qui sera remplacé dans .onAppear
        _wishlistManager = StateObject(wrappedValue: WishlistManager(modelContext: ModelContext(ModelContainer.preview)))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                MomentsTheme.diagonalGradient
                    .ignoresSafeArea()
                    .opacity(0.03)

                if wishlistManager.isLoading {
                    // 🔄 Indicateur de chargement
                    ProgressView("Synchronisation...")
                        .controlSize(.large)
                } else if wishlistsByEvent.isEmpty {
                    emptyStateView
                } else {
                    wishlistsList
                }
            }
            .navigationTitle("Mes Wishlists")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }

                // 🔄 Bouton de synchronisation manuelle
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task {
                            await syncWishlist()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.title3)
                            .foregroundColor(wishlistManager.isLoading ? .gray : .blue)
                    }
                    .disabled(wishlistManager.isLoading)
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(item: $selectedEvent) { event in
                QuickAddWishlistItemView(myEvent: event, contact: nil)
            }
            .sheet(item: $itemToEdit) { item in
                AddEditWishlistItemView(myEvent: item.myEvent, contact: item.contact, wishlistItem: item)
            }
            .alert("Erreur de synchronisation", isPresented: $showingSyncError) {
                Button("OK", role: .cancel) {
                    wishlistManager.errorMessage = nil
                }
                Button("Réessayer") {
                    Task {
                        await syncWishlist()
                    }
                }
            } message: {
                Text(wishlistManager.errorMessage ?? "Une erreur est survenue")
            }
            .task {
                // 🔄 Synchronisation automatique au chargement de la vue
                await syncWishlist()
            }
            .onChange(of: wishlistManager.errorMessage) { _, newValue in
                showingSyncError = newValue != nil
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "gift.fill")
                .font(.system(size: 80))
                .gradientIcon()

            Text("Aucune wishlist")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Créez un événement et ajoutez\ndes cadeaux à votre wishlist")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            NavigationLink(destination: EventsView()) {
                Label("Créer un événement", systemImage: "calendar.badge.plus")
            }
            .buttonStyle(MomentsTheme.PrimaryButtonStyle())
            .padding(.top)
        }
        .padding()
    }

    // MARK: - Wishlists List

    private var wishlistsList: some View {
        List {
            ForEach(wishlistsByEvent, id: \.0.id) { event, items in
                Section {
                    ForEach(items) { item in
                        WishlistItemRowView(item: item)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Navigation vers le détail
                                // TODO: Implémenter navigation
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                deleteWishlistItem(item)
                            } label: {
                                Label("Supprimer", systemImage: "trash")
                            }

                            Button {
                                itemToEdit = item
                            } label: {
                                Label("Modifier", systemImage: "pencil")
                            }
                            .tint(.orange)
                        }
                    }
                } header: {
                    HStack(spacing: 12) {
                        Image(systemName: event.type.icon)
                            .foregroundStyle(MomentsTheme.primaryGradient)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.title)
                                .textCase(.uppercase)
                                .fontWeight(.semibold)

                            Text("\(items.count) \(items.count <= 1 ? "cadeau" : "cadeaux")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .textCase(.none)
                        }

                        Spacer()

                        Button {
                            selectedEvent = event
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .gradientIcon()
                        }
                    }
                }
            }

            // Section pour ajouter une wishlist
            if !allMyEvents.isEmpty {
                Section {
                    Menu {
                        ForEach(allMyEvents) { event in
                            Button {
                                selectedEvent = event
                            } label: {
                                HStack {
                                    Image(systemName: event.type.icon)
                                    Text(event.title)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(MomentsTheme.primaryGradient)
                            Text("Ajouter un cadeau")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("Nouveau cadeau")
                        .textCase(.uppercase)
                        .fontWeight(.semibold)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Methods

    /// Synchronise la wishlist avec Supabase
    private func syncWishlist() async {
        do {
            try await wishlistManager.loadWishlist()
        } catch {
            print("❌ Erreur de synchronisation: \(error)")
            // L'erreur sera affichée via l'alert
        }
    }

    /// Supprime un item de la wishlist (local + Supabase)
    private func deleteWishlistItem(_ item: WishlistItem) {
        Task {
            do {
                // ✅ Utiliser le manager pour supprimer (synchronise automatiquement)
                try await wishlistManager.deleteItem(item)
            } catch {
                print("❌ Erreur lors de la suppression du cadeau: \(error)")
                wishlistManager.errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Preview Helper

extension ModelContainer {
    /// Container pour les previews
    static var preview: ModelContainer {
        let schema = Schema([MyEvent.self, WishlistItem.self, Contact.self, UserProfile.self])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: configuration)
        return container
    }
}

#Preview {
    MyWishlistView()
        .modelContainer(for: [MyEvent.self, WishlistItem.self])
}
