//
//  QuickAddWishlistItemView.swift
//  Moments
//
//  Description: Vue d'ajout rapide de produit via URL (paste-first UX)
//  Architecture: View
//

import SwiftUI
import SwiftData

/// Vue d'ajout rapide de produit via collage d'URL
/// Flow optimisé : Coller → Chargement → Récapitulatif → Ajouter
struct QuickAddWishlistItemView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    /// WishlistManager pour la synchronisation Supabase
    @State private var wishlistManager: WishlistManager?

    /// Étape du flow
    @State private var step: AddStep = .paste

    /// Indicateur de sauvegarde en cours
    @State private var isSaving = false

    /// Message d'erreur si échec de sauvegarde
    @State private var saveError: String?

    /// URL collée
    @State private var url: String = ""

    /// Métadonnées extraites
    @State private var metadata: ProductMetadata?

    /// Priorité sélectionnée (1-5)
    @State private var priority: Int = 3

    /// Événement pour lequel on ajoute le cadeau
    let myEvent: MyEvent?

    /// Contact pour lequel on ajoute le cadeau
    let contact: Contact?

    // MARK: - Computed

    /// Titre de la vue selon l'étape
    private var title: String {
        switch step {
        case .paste: return "Ajouter un produit"
        case .loading: return "Chargement..."
        case .review: return "Vérifier les informations"
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Fond dégradé
                MomentsTheme.diagonalGradient
                    .ignoresSafeArea()
                    .opacity(0.05)

                // Contenu selon l'étape
                switch step {
                case .paste:
                    pasteView
                case .loading:
                    loadingView
                case .review:
                    reviewView
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                // ✅ Initialiser le WishlistManager avec le modelContext
                if wishlistManager == nil {
                    wishlistManager = WishlistManager(modelContext: modelContext)
                }
            }
            .alert("Erreur", isPresented: .constant(saveError != nil)) {
                Button("OK") {
                    saveError = nil
                }
            } message: {
                if let error = saveError {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Paste View

    /// Vue de collage d'URL
    private var pasteView: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icône
            Image(systemName: "link.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(MomentsTheme.primaryGradient)

            // Instructions
            VStack(spacing: 12) {
                Text("Collez le lien du produit")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Amazon, FNAC, ou n'importe quel site")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Champ URL
            VStack(alignment: .leading, spacing: 8) {
                TextField("https://exemple.com/produit", text: $url)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.URL)
                    .autocapitalization(.none)
                    .keyboardType(.URL)
                    .padding(.horizontal)
                    .submitLabel(.go)
                    .onSubmit {
                        if isValidURL(url) {
                            loadMetadata()
                        }
                    }

                // Bouton Coller géant si URL vide
                if url.isEmpty {
                    Button(action: pasteFromClipboard) {
                        HStack {
                            Image(systemName: "doc.on.clipboard")
                            Text("Coller depuis le presse-papier")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(MomentsTheme.primaryGradient)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }

            Spacer()

            // Bouton Continuer
            Button(action: loadMetadata) {
                Text("Continuer")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isValidURL(url) ? AnyShapeStyle(MomentsTheme.primaryGradient) : AnyShapeStyle(Color.gray))
                    .cornerRadius(12)
            }
            .disabled(!isValidURL(url))
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }

    // MARK: - Loading View

    /// Vue de chargement
    private var loadingView: some View {
        VStack(spacing: 30) {
            Spacer()

            // Animation de chargement
            ProgressView()
                .scaleEffect(2)
                .tint(.white)

            VStack(spacing: 12) {
                Text("Récupération des informations...")
                    .font(.headline)

                Text("Cela peut prendre quelques secondes")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }

    // MARK: - Review View

    /// Vue de récapitulatif
    private var reviewView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Image du produit
                if let imageData = metadata?.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 250)
                        .cornerRadius(16)
                        .shadow(radius: 8)
                        .padding(.horizontal)
                } else {
                    // Placeholder si pas d'image
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 250)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal)
                }

                // Informations du produit
                VStack(alignment: .leading, spacing: 16) {
                    // Titre
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nom du produit")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(metadata?.title ?? "Sans titre")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }

                    // Prix
                    if let price = metadata?.price {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Prix")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.2f €", price))
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(MomentsTheme.primaryGradient)
                        }
                    }

                    Divider()

                    // Sélecteur de priorité
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Niveau de priorité")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { level in
                                Button(action: { priority = level }) {
                                    Image(systemName: level <= priority ? "star.fill" : "star")
                                        .font(.title2)
                                        .foregroundColor(level <= priority ? .yellow : .gray)
                                }
                            }
                        }

                        // Description de la priorité
                        Text(priorityDescription(priority))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                .padding(.horizontal)

                // Bouton Ajouter
                Button(action: saveWishlistItem) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isSaving ? "Sauvegarde..." : "Ajouter à ma liste")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isSaving ? AnyShapeStyle(Color.gray) : AnyShapeStyle(MomentsTheme.primaryGradient))
                    .cornerRadius(12)
                }
                .disabled(isSaving)
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
            .padding(.top, 20)
        }
    }

    // MARK: - Actions

    /// Coller depuis le presse-papier
    private func pasteFromClipboard() {
        if let clipboardContent = UIPasteboard.general.string {
            url = clipboardContent
            // Auto-lancer si URL valide
            if isValidURL(clipboardContent) {
                loadMetadata()
            }
        }
    }

    /// Charger les métadonnées du produit
    private func loadMetadata() {
        guard let productURL = URL(string: url) else { return }

        // Passer en mode chargement
        step = .loading

        // Récupérer les métadonnées
        Task {
            let fetcher = ProductMetadataFetcher()
            let result = await fetcher.fetchMetadata(from: productURL.absoluteString)

            await MainActor.run {
                metadata = result
                step = .review
            }
        }
    }

    /// Sauvegarder le produit dans la wishlist
    private func saveWishlistItem() {
        guard let metadata = metadata,
              let manager = wishlistManager else { return }

        isSaving = true

        Task {
            do {
                // Créer l'item
                let item = WishlistItem(
                    title: metadata.title ?? "Produit sans nom",
                    itemDescription: nil, // Pas de description dans le quick add
                    price: metadata.price,
                    url: url,
                    image: metadata.imageData,
                    category: .autre, // Catégorie par défaut
                    status: .wanted,
                    priority: priority,
                    contact: contact,
                    myEvent: myEvent
                )

                // ✅ Sauvegarder avec WishlistManager (synchronise avec Supabase)
                try await manager.addItem(item)

                // Fermer la vue
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    saveError = "Impossible de sauvegarder: \(error.localizedDescription)"
                    print("❌ Erreur lors de la sauvegarde: \(error)")
                }
            }
        }
    }

    // MARK: - Helpers

    /// Valide si l'URL est correcte
    private func isValidURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              let scheme = url.scheme else {
            return false
        }
        return scheme == "http" || scheme == "https"
    }

    /// Description de la priorité
    private func priorityDescription(_ level: Int) -> String {
        switch level {
        case 1: return "Pas urgent"
        case 2: return "Faible priorité"
        case 3: return "Priorité normale"
        case 4: return "Haute priorité"
        case 5: return "Priorité maximale"
        default: return ""
        }
    }
}

// MARK: - Add Step Enum

/// Étapes du flow d'ajout
enum AddStep {
    case paste      // Collage de l'URL
    case loading    // Chargement des métadonnées
    case review     // Récapitulatif et validation
}

// MARK: - Preview

#Preview {
    QuickAddWishlistItemView(myEvent: nil, contact: nil)
        .modelContainer(for: WishlistItem.self, inMemory: true)
}
