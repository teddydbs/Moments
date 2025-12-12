//
//  AddEditWishlistItemView.swift
//  Moments
//
//  Vue pour ajouter ou éditer un cadeau dans une wishlist
//

import SwiftUI
import SwiftData
import Supabase

struct AddEditWishlistItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Événement OU Contact (un seul des deux)
    let myEvent: MyEvent?
    let contact: Contact?
    let wishlistItem: WishlistItem?

    @State private var title: String = ""
    @State private var itemDescription: String = ""
    @State private var price: String = ""
    @State private var url: String = ""
    @State private var category: GiftCategory = .autre
    @State private var priority: Int = 2
    @State private var imageData: Data?

    // Pour le remplissage automatique
    @StateObject private var metadataFetcher = ProductMetadataFetcher()
    @State private var isAutoFilling = false

    init(myEvent: MyEvent?, contact: Contact? = nil, wishlistItem: WishlistItem?) {
        self.myEvent = myEvent
        self.contact = contact
        self.wishlistItem = wishlistItem
    }

    private var isEditing: Bool {
        wishlistItem != nil
    }

    private var titleText: String {
        if isEditing {
            return "Modifier le cadeau"
        } else if myEvent != nil {
            return "Ajouter à ma wishlist"
        } else {
            return "Ajouter à la wishlist"
        }
    }

    private var saveButtonTitle: String {
        isEditing ? "Mettre à jour" : "Ajouter"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                MomentsTheme.diagonalGradient
                    .ignoresSafeArea()
                    .opacity(0.05)

                Form {
                    // ✅ Section: URL du produit (EN PREMIER et OBLIGATOIRE)
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                TextField("https://example.com/produit", text: $url)
                                    .textContentType(.URL)
                                    .autocapitalization(.none)
                                    .keyboardType(.URL)
                                    .onChange(of: url) { oldValue, newValue in
                                        // ✅ Auto-fill AUTOMATIQUE dès qu'on entre une URL valide
                                        if isValidURL(newValue) && !isAutoFilling {
                                            Task {
                                                await autoFillFromURL()
                                            }
                                        }
                                    }

                                // ✅ Bouton Coller
                                if url.isEmpty {
                                    Button {
                                        // Récupérer le contenu du presse-papiers
                                        if let clipboardContent = UIPasteboard.general.string {
                                            url = clipboardContent
                                        }
                                    } label: {
                                        Text("Coller")
                                            .font(.subheadline)
                                            .foregroundStyle(MomentsTheme.primaryGradient)
                                    }
                                }
                            }

                            // Indicateur de chargement
                            if isAutoFilling {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Récupération des informations du produit...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.top, 4)
                            }
                        }
                    } header: {
                        Text("Lien du produit")
                    } footer: {
                        Text("💡 Collez le lien du produit, toutes les informations se rempliront automatiquement")
                            .font(.caption)
                    }

                    // Section: Informations (pré-remplies automatiquement)
                    Section {
                        TextField("Nom du cadeau", text: $title)
                            .textContentType(.name)

                        TextEditor(text: $itemDescription)
                            .frame(height: 80)
                            .overlay(
                                VStack {
                                    HStack {
                                        if itemDescription.isEmpty {
                                            Text("Description (optionnel)")
                                                .foregroundColor(.secondary)
                                                .padding(.top, 8)
                                                .padding(.leading, 4)
                                        }
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            )

                        Picker("Catégorie", selection: $category) {
                            ForEach(GiftCategory.allCases, id: \.self) { cat in
                                HStack {
                                    Image(systemName: cat.icon)
                                    Text(cat.rawValue)
                                }
                                .tag(cat)
                            }
                        }
                    } header: {
                        Text("Informations")
                    } footer: {
                        Text("Ces informations sont remplies automatiquement, vous pouvez les modifier si besoin")
                            .font(.caption)
                    }

                    // Section: Image du produit (pré-remplie automatiquement)
                    if let currentImageData = imageData,
                       let uiImage = UIImage(data: currentImageData) {
                        Section("Image du produit") {
                            HStack {
                                Spacer()
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(maxHeight: 200)
                                    .cornerRadius(12)
                                Spacer()
                            }
                            .padding(.vertical, 8)

                            Button(role: .destructive) {
                                imageData = nil
                            } label: {
                                Label("Supprimer l'image", systemImage: "trash")
                            }
                        }
                    }

                    // Section: Prix (pré-rempli automatiquement)
                    Section {
                        HStack {
                            TextField("0", text: $price)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("€")
                                .foregroundColor(.secondary)
                        }
                    } header: {
                        Text("Prix")
                    } footer: {
                        // ⚠️ Message d'avertissement si Amazon et prix semble incorrect
                        if url.contains("amazon") || url.contains("amzn") {
                            Text("⚠️ Pour Amazon, vérifiez et corrigez le prix si nécessaire (prix promotionnel)")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }

                    // Section: Priorité
                    Section("Priorité") {
                        Picker("Priorité", selection: $priority) {
                            HStack {
                                Image(systemName: "star")
                                Text("Faible")
                            }
                            .tag(1)

                            HStack {
                                Image(systemName: "star.fill")
                                Text("Moyenne")
                            }
                            .tag(2)

                            HStack {
                                Image(systemName: "star.fill")
                                Image(systemName: "star.fill")
                                Text("Haute")
                            }
                            .tag(3)
                        }
                        .pickerStyle(.segmented)
                    }

                    // Section: Pour quel événement/contact
                    Section("Pour") {
                        if let event = myEvent {
                            HStack {
                                Image(systemName: event.type.icon)
                                    .foregroundStyle(MomentsTheme.primaryGradient)
                                Text(event.title)
                                    .font(.headline)
                            }
                        } else if let contact = contact {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundStyle(MomentsTheme.primaryGradient)
                                Text(contact.fullName)
                                    .font(.headline)
                            }
                        }
                    }
                }
            }
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(saveButtonTitle) {
                        saveWishlistItem()
                    }
                    // ✅ URL obligatoire (le titre se remplit auto)
                    .disabled(url.isEmpty || !isValidURL(url))
                    .foregroundColor((url.isEmpty || !isValidURL(url)) ? .secondary : MomentsTheme.primaryPurple)
                }
            }
            .onAppear {
                loadItemData()
            }
        }
    }

    // MARK: - Methods

    /// Vérifie si une URL est valide
    private func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return url.scheme == "http" || url.scheme == "https"
    }

    /// Remplit automatiquement les champs depuis l'URL
    private func autoFillFromURL() async {
        isAutoFilling = true

        // ❓ POURQUOI: On récupère les métadonnées du produit depuis l'URL
        if let metadata = await metadataFetcher.fetchMetadata(from: url) {
            // ✅ Remplir TOUS les champs automatiquement (nouvelle URL = nouvelles infos)
            if let productTitle = metadata.title {
                title = productTitle
            }

            if let productPrice = metadata.price {
                price = String(format: "%.2f", productPrice)
            }

            if let productImageData = metadata.imageData {
                imageData = productImageData
            }

            // ✅ Feedback haptique de succès
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } else {
            // ❌ Échec: feedback haptique d'erreur
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }

        isAutoFilling = false
    }

    private func loadItemData() {
        guard let item = wishlistItem else { return }

        title = item.title
        itemDescription = item.itemDescription ?? ""
        price = item.price != nil ? String(format: "%.2f", item.price!) : ""
        url = item.url ?? ""
        category = item.category
        priority = item.priority
        imageData = item.image
    }

    private func saveWishlistItem() {
        let priceDouble = Double(price.replacingOccurrences(of: ",", with: "."))

        // ✅ Si pas de titre récupéré, utiliser un titre par défaut
        let finalTitle = title.isEmpty ? "Produit" : title

        Task {
            do {
                if let existingItem = wishlistItem {
                    // ✅ MISE À JOUR
                    print("⚙️ Mise à jour de l'item: \(existingItem.title)")

                    // 1. Mettre à jour localement
                    existingItem.title = finalTitle
                    existingItem.itemDescription = itemDescription.isEmpty ? nil : itemDescription
                    existingItem.price = priceDouble
                    existingItem.url = url.isEmpty ? nil : url
                    existingItem.category = category
                    existingItem.priority = priority
                    existingItem.image = imageData
                    existingItem.updatedAt = Date()

                    try modelContext.save()
                    print("✅ Item mis à jour localement")

                    // 2. Synchroniser avec Supabase (SEULEMENT pour wishlist personnelle)
                    if existingItem.isMyWishlistItem, let session = try? await SupabaseManager.shared.client.auth.session {
                        let userId = session.user.id

                        let remoteItem = RemoteWishlistItem(from: existingItem, userId: userId)

                        try await SupabaseManager.shared.client
                            .from("wishlist_items")
                            .update(remoteItem)
                            .eq("id", value: existingItem.id.uuidString)
                            .execute()

                        print("✅ Item synchronisé avec Supabase")
                    }

                } else {
                    // ✅ CRÉATION
                    let newItem = WishlistItem(
                        title: finalTitle,
                        itemDescription: itemDescription.isEmpty ? nil : itemDescription,
                        price: priceDouble,
                        url: url.isEmpty ? nil : url,
                        image: imageData,
                        category: category,
                        status: .wanted,
                        priority: priority,
                        contact: contact,
                        myEvent: myEvent
                    )

                    // 1. Ajouter localement
                    modelContext.insert(newItem)
                    try modelContext.save()
                    print("✅ Item créé localement")

                    // 2. Synchroniser avec Supabase (SEULEMENT pour wishlist personnelle)
                    if newItem.isMyWishlistItem, let session = try? await SupabaseManager.shared.client.auth.session {
                        let userId = session.user.id

                        let remoteItem = RemoteWishlistItem(from: newItem, userId: userId)

                        try await SupabaseManager.shared.client
                            .from("wishlist_items")
                            .insert(remoteItem)
                            .execute()

                        print("✅ Item synchronisé avec Supabase")
                    }
                }

                await MainActor.run {
                    print("✅ Cadeau sauvegardé avec succès")
                    dismiss()
                }

            } catch {
                await MainActor.run {
                    print("❌ Erreur lors de la sauvegarde du cadeau: \(error)")
                }
            }
        }
    }
}

#Preview("Pour mon événement") {
    @Previewable @State var event = MyEvent.preview

    AddEditWishlistItemView(myEvent: event, wishlistItem: nil)
        .modelContainer(for: [MyEvent.self, WishlistItem.self])
}

#Preview("Pour un contact") {
    @Previewable @State var contact = Contact.preview

    AddEditWishlistItemView(myEvent: nil, contact: contact, wishlistItem: nil)
        .modelContainer(for: [Contact.self, WishlistItem.self])
}
