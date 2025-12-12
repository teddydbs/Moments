//
//  QuickAddWishlistItemView.swift
//  Moments
//
//  Description: Vue d'ajout rapide de produit via URL (flow ultra-simplifié)
//  Architecture: View
//

import SwiftUI
import SwiftData

/// Vue d'ajout rapide de produit via collage d'URL
/// ✅ Flow simplifié : Coller URL → Sauvegarder immédiatement → Extraction en arrière-plan
struct QuickAddWishlistItemView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    /// WishlistManager pour la synchronisation Supabase
    @State private var wishlistManager: WishlistManager?

    /// Indicateur de sauvegarde en cours
    @State private var isSaving = false

    /// Message d'erreur si échec de sauvegarde
    @State private var saveError: String?

    /// URL collée
    @State private var url: String = ""

    /// Événement pour lequel on ajoute le cadeau
    let myEvent: MyEvent?

    /// Contact pour lequel on ajoute le cadeau
    let contact: Contact?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Fond dégradé
                MomentsTheme.diagonalGradient
                    .ignoresSafeArea()
                    .opacity(0.05)

                pasteView
            }
            .navigationTitle("Ajouter un produit")
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
                    .submitLabel(.done)
                    .onSubmit {
                        if isValidURL(url) {
                            saveWishlistItem()
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

            // Bouton Ajouter
            Button(action: saveWishlistItem) {
                HStack {
                    if isSaving {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(isSaving ? "Ajout en cours..." : "Ajouter à ma liste")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(isValidURL(url) && !isSaving ? AnyShapeStyle(MomentsTheme.primaryGradient) : AnyShapeStyle(Color.gray))
                .cornerRadius(12)
            }
            .disabled(!isValidURL(url) || isSaving)
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }

    // MARK: - Actions

    /// Coller depuis le presse-papier
    private func pasteFromClipboard() {
        if let clipboardContent = UIPasteboard.general.string {
            url = clipboardContent
            // Auto-sauvegarder si URL valide
            if isValidURL(clipboardContent) {
                saveWishlistItem()
            }
        }
    }

    /// Sauvegarder le produit dans la wishlist
    /// ✅ NOUVELLE LOGIQUE : Sauvegarde immédiate + extraction en arrière-plan
    private func saveWishlistItem() {
        guard let manager = wishlistManager,
              isValidURL(url) else { return }

        isSaving = true

        Task {
            do {
                // ✅ Créer un item placeholder avec juste l'URL
                let item = WishlistItem(
                    title: "Chargement...", // Placeholder qui sera mis à jour
                    itemDescription: nil,
                    price: nil, // Sera mis à jour en arrière-plan
                    url: url,
                    image: nil, // Sera mis à jour en arrière-plan
                    category: .autre,
                    status: .wanted,
                    priority: 3, // Priorité par défaut
                    contact: contact,
                    myEvent: myEvent
                )

                // ✅ Sauvegarder immédiatement (local + Supabase)
                try await manager.addItem(item)

                // ✅ Lancer l'extraction en arrière-plan (ne bloque pas)
                Task.detached(priority: .background) {
                    await manager.fetchAndUpdateMetadata(for: item, from: url)
                }

                // ✅ Fermer immédiatement la vue
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
}

// MARK: - Preview

#Preview {
    QuickAddWishlistItemView(myEvent: nil, contact: nil)
        .modelContainer(for: WishlistItem.self, inMemory: true)
}
