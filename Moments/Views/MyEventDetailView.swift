//
//  MyEventDetailView.swift
//  Moments
//
//  Vue détail d'un de MES événements avec invitations et wishlist
//

import SwiftUI
import SwiftData
import MapKit

struct MyEventDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let myEvent: MyEvent

    @State private var showingEditEvent = false
    @State private var showingInvitationManagement = false
    @State private var showingAddGift = false

    // Pour la carte
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var locationCoordinate: CLLocationCoordinate2D?

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }

    private var daysText: String {
        let days = myEvent.daysUntilEvent

        if myEvent.isPast {
            return "Événement passé"
        } else if days == 0 {
            return "C'est aujourd'hui ! 🎉"
        } else if days == 1 {
            return "C'est demain !"
        } else {
            return "Dans \(days) jours"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // En-tête avec icône
                    VStack(spacing: 16) {
                        // Icône
                        ZStack {
                            Circle()
                                .fill(MomentsTheme.primaryGradient.opacity(0.2))
                                .frame(width: 120, height: 120)

                            Image(systemName: myEvent.type.icon)
                                .font(.system(size: 50))
                                .gradientIcon()
                        }

                        // Titre
                        Text(myEvent.title)
                            .font(.title)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        // Type
                        Text(myEvent.type.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Carte date
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.title2)
                                .gradientIcon()

                            VStack(alignment: .leading, spacing: 4) {
                                Text(dateFormatter.string(from: myEvent.date))
                                    .font(.headline)

                                if let time = myEvent.time {
                                    Text("À \(timeFormatter.string(from: time))")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(daysText)
                                    .font(.headline)
                                    .foregroundStyle(MomentsTheme.primaryGradient)
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

                    // Lieu
                    if myEvent.location != nil || myEvent.locationAddress != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Lieu")
                                .font(.headline)
                                .padding(.horizontal)

                            VStack(alignment: .leading, spacing: 12) {
                                if let location = myEvent.location {
                                    HStack(spacing: 12) {
                                        Image(systemName: "mappin.circle.fill")
                                            .foregroundStyle(MomentsTheme.primaryGradient)

                                        Text(location)
                                            .font(.body)
                                    }
                                }

                                if let address = myEvent.locationAddress {
                                    Text(address)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 34)
                                }

                                // ✅ Carte interactive
                                if let coordinate = locationCoordinate {
                                    Map(position: $mapPosition) {
                                        Marker(myEvent.location ?? "Lieu", coordinate: coordinate)
                                    }
                                    .frame(height: 200)
                                    .cornerRadius(12)
                                    .allowsHitTesting(true) // Permettre l'interaction avec la carte
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            )
                            .padding(.horizontal)
                        }
                        .task {
                            // ✅ Géocoder l'adresse au chargement
                            if let address = myEvent.locationAddress {
                                await geocodeAddress(address)
                            }
                        }
                    }

                    // Description
                    if let description = myEvent.eventDescription, !description.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Description")
                                .font(.headline)
                                .padding(.horizontal)

                            Text(description)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                                .padding(.horizontal)
                        }
                    }

                    // Invitations
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Invitations")
                                .font(.headline)

                            Spacer()

                            Button {
                                showingInvitationManagement = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text("\(myEvent.totalInvitations)")
                                        .font(.caption)
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                }
                                .foregroundStyle(MomentsTheme.primaryGradient)
                            }
                        }
                        .padding(.horizontal)

                        if let invitations = myEvent.invitations, !invitations.isEmpty {
                            VStack(spacing: 8) {
                                // Stats
                                HStack(spacing: 16) {
                                    StatBadge(
                                        count: myEvent.acceptedCount,
                                        label: "Accepté\(myEvent.acceptedCount > 1 ? "s" : "")",
                                        color: .green
                                    )

                                    StatBadge(
                                        count: myEvent.pendingCount,
                                        label: "En attente",
                                        color: .orange
                                    )

                                    StatBadge(
                                        count: myEvent.declinedCount,
                                        label: "Refusé\(myEvent.declinedCount > 1 ? "s" : "")",
                                        color: .red
                                    )
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                                )

                                // Liste des invitations (simplifiée)
                                ForEach(invitations) { invitation in
                                    InvitationRowView(invitation: invitation)
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "person.2")
                                    .font(.system(size: 40))
                                    .foregroundStyle(MomentsTheme.primaryGradient.opacity(0.5))

                                Text("Aucune invitation envoyée")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Button {
                                    showingInvitationManagement = true
                                } label: {
                                    Label("Inviter quelqu'un", systemImage: "plus.circle.fill")
                                }
                                .buttonStyle(MomentsTheme.PrimaryButtonStyle())
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 40)
                        }
                    }

                    // Ma wishlist pour cet événement
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Ma wishlist")
                                .font(.headline)

                            Spacer()

                            Text("\(myEvent.wishlistCount) \(myEvent.wishlistCount <= 1 ? "cadeau" : "cadeaux")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        if let wishlistItems = myEvent.wishlistItems, !wishlistItems.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(wishlistItems) { item in
                                    WishlistItemRowView(item: item)
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "gift")
                                    .font(.system(size: 40))
                                    .foregroundStyle(MomentsTheme.primaryGradient.opacity(0.5))

                                Text("Aucun cadeau dans votre wishlist")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Button {
                                    showingAddGift = true
                                } label: {
                                    Label("Ajouter un cadeau", systemImage: "plus.circle.fill")
                                }
                                .buttonStyle(MomentsTheme.PrimaryButtonStyle())
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 40)
                        }
                    }

                    Spacer()
                }
            }
            .background(
                MomentsTheme.diagonalGradient
                    .ignoresSafeArea()
                    .opacity(0.03)
            )
            .navigationTitle("Événement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditEvent = true
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
            .sheet(isPresented: $showingEditEvent) {
                AddEditMyEventView(myEvent: myEvent)
            }
            .sheet(isPresented: $showingInvitationManagement) {
                InvitationManagementView(myEvent: myEvent)
            }
            .sheet(isPresented: $showingAddGift) {
                AddEditWishlistItemView(myEvent: myEvent, wishlistItem: nil)
            }
        }
    }

    // MARK: - Methods

    /// Géocode une adresse pour obtenir les coordonnées GPS
    /// - Parameter address: L'adresse à géocoder
    private func geocodeAddress(_ address: String) async {
        // ❓ POURQUOI: CLGeocoder permet de convertir une adresse en coordonnées GPS
        let geocoder = CLGeocoder()

        do {
            // ✅ ÉTAPE 1: Demander les coordonnées à Apple Maps
            let placemarks = try await geocoder.geocodeAddressString(address)

            // ✅ ÉTAPE 2: Récupérer la première position trouvée
            if let coordinate = placemarks.first?.location?.coordinate {
                await MainActor.run {
                    locationCoordinate = coordinate
                    // Centrer la carte sur la position
                    mapPosition = .region(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
            }
        } catch {
            print("❌ Erreur de géocodage: \(error.localizedDescription)")
            // Si l'adresse n'est pas trouvée, on ne fait rien
        }
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let count: Int
    let label: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Invitation Row

struct InvitationRowView: View {
    let invitation: Invitation

    var body: some View {
        HStack(spacing: 12) {
            // Icône de statut
            Image(systemName: invitation.statusIcon)
                .foregroundColor(statusColor)
                .frame(width: 24)

            // Infos
            VStack(alignment: .leading, spacing: 4) {
                Text(invitation.guestName)
                    .font(.headline)

                Text(invitation.status.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if invitation.plusOnes > 0 {
                Text("+\(invitation.plusOnes)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    private var statusColor: Color {
        switch invitation.status {
        case .pending: return .orange
        case .accepted: return .green
        case .declined: return .red
        case .waitingApproval: return .purple
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MyEvent.self, configurations: config)
    let event = MyEvent.preview
    container.mainContext.insert(event)

    return MyEventDetailView(myEvent: event)
        .modelContainer(container)
}
