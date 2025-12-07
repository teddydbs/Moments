//
//  WishlistItemDetailView.swift
//  Moments
//
//  Vue détail d'un cadeau dans une wishlist
//

import SwiftUI
import SwiftData

struct WishlistItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let wishlistItem: WishlistItem

    @State private var showingEditItem = false

    private var priorityStars: some View {
        HStack(spacing: 4) {
            ForEach(0..<wishlistItem.priority, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .foregroundStyle(MomentsTheme.primaryGradient)
            }
            ForEach(wishlistItem.priority..<3, id: \.self) { _ in
                Image(systemName: "star")
                    .foregroundColor(.secondary)
            }
        }
        .font(.caption)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Icône catégorie
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(MomentsTheme.primaryGradient.opacity(0.2))
                                .frame(width: 120, height: 120)

                            Image(systemName: wishlistItem.category.icon)
                                .font(.system(size: 50))
                                .gradientIcon()
                        }

                        Text(wishlistItem.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text(wishlistItem.category.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Prix
                    if let formattedPrice = wishlistItem.formattedPrice {
                        VStack(spacing: 8) {
                            Text("Prix estimé")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Text(formattedPrice)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(MomentsTheme.primaryGradient)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                    }

                    // Informations
                    VStack(alignment: .leading, spacing: 16) {
                        // Description
                        if let description = wishlistItem.itemDescription, !description.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Description")
                                    .font(.headline)

                                Text(description)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Priorité
                        HStack {
                            Text("Priorité")
                                .font(.headline)

                            Spacer()

                            priorityStars
                        }

                        // Statut
                        HStack {
                            Text("Statut")
                                .font(.headline)

                            Spacer()

                            HStack(spacing: 8) {
                                Circle()
                                    .fill(statusColor)
                                    .frame(width: 10, height: 10)

                                Text(wishlistItem.status.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }

                        // Réservé par
                        if let reservedBy = wishlistItem.reservedBy {
                            HStack {
                                Text("Réservé par")
                                    .font(.headline)

                                Spacer()

                                Text(reservedBy)
                                    .font(.subheadline)
                                    .foregroundStyle(MomentsTheme.primaryGradient)
                            }
                        }

                        // Pour quel événement/contact
                        if let event = wishlistItem.myEvent {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Pour l'événement")
                                    .font(.headline)

                                HStack {
                                    Image(systemName: event.type.icon)
                                        .foregroundStyle(MomentsTheme.primaryGradient)
                                    Text(event.title)
                                }
                            }
                        } else if let contact = wishlistItem.contact {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Pour")
                                    .font(.headline)

                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .foregroundStyle(MomentsTheme.primaryGradient)
                                    Text(contact.fullName)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal)

                    // Lien
                    if let urlString = wishlistItem.url,
                       let url = URL(string: urlString) {
                        Link(destination: url) {
                            HStack {
                                Image(systemName: "link")
                                Text("Voir le produit")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                        }
                        .buttonStyle(MomentsTheme.PrimaryButtonStyle())
                        .padding(.horizontal)
                    }

                    Spacer()
                }
            }
            .background(
                MomentsTheme.diagonalGradient
                    .ignoresSafeArea()
                    .opacity(0.03)
            )
            .navigationTitle("Cadeau")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditItem = true
                    } label: {
                        Text("Modifier")
                            .foregroundStyle(MomentsTheme.primaryGradient)
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditItem) {
                AddEditWishlistItemView(
                    myEvent: wishlistItem.myEvent,
                    contact: wishlistItem.contact,
                    wishlistItem: wishlistItem
                )
            }
        }
    }

    private var statusColor: Color {
        switch wishlistItem.status {
        case .wanted: return .blue
        case .reserved: return .orange
        case .purchased: return .purple
        case .received: return .green
        }
    }
}

#Preview {
    @Previewable @State var item = WishlistItem(
        title: "Machine à café Nespresso",
        itemDescription: "Modèle Vertuo avec mousseur de lait intégré",
        price: 199.0,
        url: "https://www.nespresso.com",
        category: .maison,
        status: .wanted,
        priority: 3
    )

    WishlistItemDetailView(wishlistItem: item)
        .modelContainer(for: [MyEvent.self, WishlistItem.self])
}
