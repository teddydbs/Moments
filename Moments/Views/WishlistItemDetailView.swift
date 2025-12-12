//
//  WishlistItemDetailView.swift
//  Moments
//
//  Description: Vue de détail d'un item de wishlist avec URL cliquable
//  Architecture: View
//

import SwiftUI
import SafariServices

/// Vue de détail pour un produit de wishlist
/// ✅ Affiche les informations complètes avec URL cliquable
struct WishlistItemDetailView: View {

    // MARK: - Properties

    let item: WishlistItem
    @Environment(\.dismiss) private var dismiss
    @State private var showingSafari = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Image du produit
                    productImage

                    // Informations principales
                    mainInfo

                    // Prix et priorité
                    priceAndPriority

                    // Description
                    if let description = item.itemDescription, !description.isEmpty {
                        descriptionSection(description)
                    }

                    // Bouton pour ouvrir l'URL
                    if let urlString = item.url, !urlString.isEmpty {
                        openURLButton(urlString)
                    }

                    // Statut
                    statusSection
                }
                .padding()
            }
            .background(
                MomentsTheme.diagonalGradient
                    .ignoresSafeArea()
                    .opacity(0.03)
            )
            .navigationTitle("Détails du produit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingSafari) {
                if let urlString = item.url, let url = URL(string: urlString) {
                    SafariView(url: url)
                }
            }
        }
    }

    // MARK: - Subviews

    /// Image du produit
    private var productImage: some View {
        Group {
            if let imageData = item.image,
               let uiImage = UIImage(data: imageData) {
                // Image du produit
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
            } else {
                // Fallback : icône de catégorie
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(MomentsTheme.primaryGradient.opacity(0.15))
                        .frame(height: 200)

                    Image(systemName: item.category.icon)
                        .font(.system(size: 80))
                        .gradientIcon()
                }
            }
        }
    }

    /// Informations principales
    private var mainInfo: some View {
        VStack(spacing: 12) {
            // Titre
            Text(item.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Catégorie
            HStack {
                Image(systemName: item.category.icon)
                    .foregroundStyle(MomentsTheme.primaryGradient)
                Text(item.category.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(.systemGray6))
            )
        }
    }

    /// Prix et priorité
    private var priceAndPriority: some View {
        HStack(spacing: 40) {
            // Prix
            if let formattedPrice = item.formattedPrice {
                VStack(spacing: 4) {
                    Text("Prix")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(formattedPrice)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(MomentsTheme.primaryGradient)
                }
            }

            // Priorité
            VStack(spacing: 4) {
                Text("Priorité")
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 4) {
                    ForEach(0..<item.priority, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .foregroundStyle(MomentsTheme.primaryGradient)
                    }
                }
                .font(.body)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    /// Section description
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)

            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    /// Bouton pour ouvrir l'URL
    private func openURLButton(_ urlString: String) -> some View {
        Button(action: {
            showingSafari = true
        }) {
            HStack {
                Image(systemName: "safari")
                Text("Voir le produit en ligne")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(MomentsTheme.primaryGradient)
            .cornerRadius(12)
        }
    }

    /// Section statut
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statut")
                .font(.headline)

            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)

                Text(statusText)
                    .font(.body)
                    .foregroundColor(.secondary)

                Spacer()
            }

            // Si réservé, afficher par qui
            if item.status == .reserved, let reservedBy = item.reservedBy {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.secondary)
                    Text("Réservé par \(reservedBy)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    // MARK: - Helpers

    private var statusColor: Color {
        switch item.status {
        case .wanted: return .blue
        case .reserved: return .orange
        case .purchased: return .purple
        case .received: return .green
        }
    }

    private var statusText: String {
        switch item.status {
        case .wanted: return "Souhaité"
        case .reserved: return "Réservé"
        case .purchased: return "Acheté"
        case .received: return "Reçu"
        }
    }
}

// MARK: - Safari View

/// Wrapper SwiftUI pour SFSafariViewController
struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // Pas besoin de mise à jour
    }
}

// MARK: - Preview

#Preview {
    WishlistItemDetailView(
        item: WishlistItem(
            title: "AirPods Pro 2",
            itemDescription: "Écouteurs sans fil avec réduction de bruit active",
            price: 279.99,
            url: "https://www.apple.com/fr/airpods-pro/",
            category: .tech,
            status: .wanted,
            priority: 3
        )
    )
}
