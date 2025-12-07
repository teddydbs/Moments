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

    // Query tous mes événements
    @Query(sort: \MyEvent.date, order: .forward) private var allMyEvents: [MyEvent]

    // Query tous les wishlist items
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

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                MomentsTheme.diagonalGradient
                    .ignoresSafeArea()
                    .opacity(0.03)

                if wishlistsByEvent.isEmpty {
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
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(item: $selectedEvent) { event in
                AddEditWishlistItemView(myEvent: event, wishlistItem: nil)
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
        ScrollView {
            VStack(spacing: 24) {
                ForEach(wishlistsByEvent, id: \.0.id) { event, items in
                    VStack(alignment: .leading, spacing: 16) {
                        // En-tête de l'événement
                        HStack(spacing: 12) {
                            Image(systemName: event.type.icon)
                                .font(.title2)
                                .gradientIcon()

                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.title)
                                    .font(.headline)

                                Text("\(items.count) \(items.count <= 1 ? "cadeau" : "cadeaux")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button {
                                selectedEvent = event
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .gradientIcon()
                            }
                        }
                        .padding(.horizontal)

                        // Liste des cadeaux
                        VStack(spacing: 12) {
                            ForEach(items) { item in
                                NavigationLink(destination: WishlistItemDetailView(wishlistItem: item)) {
                                    WishlistItemRowView(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }

                // Section pour ajouter une wishlist
                if !allMyEvents.isEmpty {
                    VStack(spacing: 16) {
                        Divider()
                            .padding(.horizontal)

                        Text("Ajouter un cadeau à un événement")
                            .font(.headline)
                            .foregroundColor(.secondary)

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
                            Label("Choisir un événement", systemImage: "plus.circle.fill")
                        }
                        .buttonStyle(MomentsTheme.PrimaryButtonStyle())
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .padding(.vertical)
        }
    }
}

#Preview {
    MyWishlistView()
        .modelContainer(for: [MyEvent.self, WishlistItem.self])
}
