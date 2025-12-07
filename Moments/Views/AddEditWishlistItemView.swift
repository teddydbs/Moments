//
//  AddEditWishlistItemView.swift
//  Moments
//
//  Vue pour ajouter ou éditer un cadeau dans une wishlist
//

import SwiftUI
import SwiftData

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
    @State private var showingAutoFillAlert = false
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
                    // Section: Informations
                    Section("Informations") {
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
                    }

                    // Section: Image du produit
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

                    // Section: Prix & Lien
                    Section {
                        HStack {
                            Text("Prix estimé")
                            Spacer()
                            TextField("0", text: $price)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                            Text("€")
                                .foregroundColor(.secondary)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            TextField("Lien du produit (optionnel)", text: $url)
                                .textContentType(.URL)
                                .autocapitalization(.none)
                                .keyboardType(.URL)
                                .onChange(of: url) { oldValue, newValue in
                                    // ✅ Afficher le bouton de remplissage auto si URL valide
                                    if isValidURL(newValue) && !isAutoFilling {
                                        showingAutoFillAlert = true
                                    }
                                }

                            // Bouton de remplissage automatique
                            if isValidURL(url) && !url.isEmpty {
                                Button {
                                    Task {
                                        await autoFillFromURL()
                                    }
                                } label: {
                                    HStack {
                                        if isAutoFilling {
                                            ProgressView()
                                                .scaleEffect(0.8)
                                        } else {
                                            Image(systemName: "wand.and.stars")
                                        }
                                        Text(isAutoFilling ? "Récupération..." : "Remplir automatiquement")
                                            .font(.subheadline)
                                    }
                                    .foregroundStyle(MomentsTheme.primaryGradient)
                                }
                                .disabled(isAutoFilling)
                            }
                        }
                    } header: {
                        Text("Prix et lien")
                    } footer: {
                        if isValidURL(url) {
                            Text("💡 L'app peut récupérer automatiquement le nom, le prix et l'image du produit")
                                .font(.caption)
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
                    .disabled(title.isEmpty)
                    .foregroundColor(title.isEmpty ? .secondary : MomentsTheme.primaryPurple)
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
        showingAutoFillAlert = false

        // ❓ POURQUOI: On récupère les métadonnées du produit
        if let metadata = await metadataFetcher.fetchMetadata(from: url) {
            // ✅ Remplir uniquement les champs vides pour ne pas écraser les modifications
            if title.isEmpty, let productTitle = metadata.title {
                title = productTitle
            }

            if price.isEmpty, let productPrice = metadata.price {
                price = String(format: "%.2f", productPrice)
            }

            if let productImageData = metadata.imageData {
                imageData = productImageData
            }

            // ✅ Afficher un feedback de succès
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        } else {
            // ✅ Afficher un feedback d'erreur
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

        if let existingItem = wishlistItem {
            // Mise à jour
            existingItem.title = title
            existingItem.itemDescription = itemDescription.isEmpty ? nil : itemDescription
            existingItem.price = priceDouble
            existingItem.url = url.isEmpty ? nil : url
            existingItem.category = category
            existingItem.priority = priority
            existingItem.image = imageData // ✅ Sauvegarder l'image
            existingItem.updatedAt = Date()
        } else {
            // Création
            let newItem = WishlistItem(
                title: title,
                itemDescription: itemDescription.isEmpty ? nil : itemDescription,
                price: priceDouble,
                url: url.isEmpty ? nil : url,
                image: imageData, // ✅ Sauvegarder l'image
                category: category,
                status: .wanted,
                priority: priority,
                contact: contact,
                myEvent: myEvent
            )
            modelContext.insert(newItem)
        }

        // Sauvegarder
        do {
            try modelContext.save()
            print("✅ Cadeau sauvegardé avec succès")
            dismiss()
        } catch {
            print("❌ Erreur lors de la sauvegarde du cadeau: \(error)")
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
