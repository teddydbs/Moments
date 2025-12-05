//
//  GiftIdeasManagementView.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import SwiftUI
import SwiftData

struct GiftIdeasManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let event: Event

    @State private var showingAddGiftIdea = false

    var body: some View {
        NavigationStack {
            List {
                if event.giftIdeas.isEmpty {
                    ContentUnavailableView(
                        "Aucune idée cadeau",
                        systemImage: "gift",
                        description: Text("Proposez une idée de cadeau pour cet événement")
                    )
                } else {
                    ForEach(event.giftIdeas) { giftIdea in
                        GiftIdeaRow(giftIdea: giftIdea)
                    }
                    .onDelete(perform: deleteGiftIdeas)
                }
            }
            .navigationTitle("Idées cadeaux")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddGiftIdea = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddGiftIdea) {
                AddGiftIdeaView(event: event)
            }
        }
    }

    private func deleteGiftIdeas(at offsets: IndexSet) {
        for index in offsets {
            let giftIdea = event.giftIdeas[index]
            modelContext.delete(giftIdea)
        }
    }
}

struct GiftIdeaRow: View {
    let giftIdea: GiftIdea

    var body: some View {
        HStack(spacing: 12) {
            // Image du produit
            if let imageURLString = giftIdea.productImageURL,
               let imageURL = URL(string: imageURLString) {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .frame(width: 80, height: 80)
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    case .failure:
                        Image(systemName: "photo")
                            .font(.largeTitle)
                            .foregroundColor(.gray)
                            .frame(width: 80, height: 80)
                            .background(Color(.systemGray5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                Image(systemName: "gift.fill")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .frame(width: 80, height: 80)
                    .background(Color(.systemGray5))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(giftIdea.title)
                    .font(.headline)
                    .lineLimit(2)

                if let price = giftIdea.price {
                    Text(String(format: "%.2f €", price))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }

                Text("Proposé par \(giftIdea.proposedBy)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let productURL = giftIdea.productURL {
                    Link(destination: URL(string: productURL)!) {
                        HStack(spacing: 4) {
                            Text("Voir le produit")
                                .font(.caption)
                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct AddGiftIdeaView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let event: Event

    @State private var title = ""
    @State private var productURL = ""
    @State private var proposedBy = ""
    @State private var isLoadingProduct = false
    @State private var scrapedData: ProductData?

    var body: some View {
        NavigationStack {
            Form {
                Section("Informations") {
                    TextField("Titre du cadeau", text: $title)

                    TextField("Votre nom", text: $proposedBy)
                }

                Section("Lien produit (optionnel)") {
                    TextField("URL du produit", text: $productURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)

                    if !productURL.isEmpty {
                        Button {
                            scrapeProduct()
                        } label: {
                            HStack {
                                if isLoadingProduct {
                                    ProgressView()
                                        .controlSize(.small)
                                } else {
                                    Image(systemName: "arrow.down.circle")
                                }
                                Text("Récupérer les infos du produit")
                            }
                        }
                        .disabled(isLoadingProduct)
                    }
                }

                if let data = scrapedData {
                    Section("Aperçu") {
                        if let imageURL = data.imageURL {
                            AsyncImage(url: URL(string: imageURL)) { image in
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                            } placeholder: {
                                ProgressView()
                            }
                        }

                        HStack {
                            Text("Nom")
                            Spacer()
                            Text(data.name)
                                .foregroundColor(.secondary)
                        }

                        if let price = data.price {
                            HStack {
                                Text("Prix")
                                Spacer()
                                Text(String(format: "%.2f €", price))
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Nouvelle idée cadeau")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        addGiftIdea()
                    }
                    .disabled(title.isEmpty || proposedBy.isEmpty)
                }
            }
        }
    }

    private func scrapeProduct() {
        guard !productURL.isEmpty, let url = URL(string: productURL) else { return }

        isLoadingProduct = true

        Task {
            do {
                let data = try await ProductScraper.scrape(url: url)
                await MainActor.run {
                    scrapedData = data
                    if title.isEmpty {
                        title = data.name
                    }
                    isLoadingProduct = false
                }
            } catch {
                await MainActor.run {
                    print("Erreur de scraping: \(error)")
                    isLoadingProduct = false
                }
            }
        }
    }

    private func addGiftIdea() {
        let giftIdea = GiftIdea(
            title: scrapedData?.name ?? title,
            productURL: productURL.isEmpty ? nil : productURL,
            productImageURL: scrapedData?.imageURL,
            price: scrapedData?.price,
            proposedBy: proposedBy
        )

        giftIdea.event = event
        event.giftIdeas.append(giftIdea)
        modelContext.insert(giftIdea)

        dismiss()
    }
}

// Service de scraping de données produit
struct ProductData {
    let name: String
    let imageURL: String?
    let price: Double?
}

enum ProductScraper {
    static func scrape(url: URL) async throws -> ProductData {
        // Simuler le scraping pour le moment
        // Dans une vraie app, on utiliserait une API ou du web scraping
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde

        // Extraction basique des métadonnées
        let (data, _) = try await URLSession.shared.data(from: url)
        let html = String(data: data, encoding: .utf8) ?? ""

        // Parser le HTML pour extraire les meta tags Open Graph
        let name = extractMetaTag(from: html, property: "og:title") ?? "Produit"
        let imageURL = extractMetaTag(from: html, property: "og:image")
        let priceString = extractMetaTag(from: html, property: "og:price:amount")
        let price = priceString != nil ? Double(priceString!) : nil

        return ProductData(name: name, imageURL: imageURL, price: price)
    }

    private static func extractMetaTag(from html: String, property: String) -> String? {
        // Recherche simple de meta tag Open Graph
        let pattern = "<meta\\s+property=\"\(property)\"\\s+content=\"([^\"]+)\""
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let range = NSRange(html.startIndex..., in: html)
        guard let match = regex.firstMatch(in: html, options: [], range: range),
              let contentRange = Range(match.range(at: 1), in: html) else {
            return nil
        }

        return String(html[contentRange])
    }
}
