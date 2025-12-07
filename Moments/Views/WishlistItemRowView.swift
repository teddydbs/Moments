//
//  WishlistItemRowView.swift
//  Moments
//
//  Vue en ligne pour afficher un item de wishlist
//

import SwiftUI
import SwiftData

struct WishlistItemRowView: View {
    let item: WishlistItem

    private var priorityStars: some View {
        HStack(spacing: 2) {
            ForEach(0..<item.priority, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .foregroundStyle(MomentsTheme.primaryGradient)
            }
        }
        .font(.caption2)
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icône catégorie
            ZStack {
                Circle()
                    .fill(MomentsTheme.primaryGradient.opacity(0.15))
                    .frame(width: 50, height: 50)

                Image(systemName: item.category.icon)
                    .font(.title3)
                    .gradientIcon()
            }

            // Informations
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(item.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if item.priority > 0 {
                        priorityStars
                    }
                }

                if let formattedPrice = item.formattedPrice {
                    Text(formattedPrice)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(MomentsTheme.primaryGradient)
                }
            }

            Spacer()

            // Statut
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }

    private var statusColor: Color {
        switch item.status {
        case .wanted: return .blue
        case .reserved: return .orange
        case .purchased: return .purple
        case .received: return .green
        }
    }
}

#Preview {
    @Previewable @State var item = WishlistItem(
        title: "Machine à café",
        itemDescription: "Nespresso Vertuo",
        price: 199.0,
        category: .maison,
        status: .wanted,
        priority: 3
    )

    WishlistItemRowView(item: item)
        .modelContainer(for: [WishlistItem.self])
        .padding()
}
