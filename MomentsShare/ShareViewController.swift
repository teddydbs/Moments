//
//  ShareViewController.swift
//  MomentsShare
//
//  Description: Interface SwiftUI de la Share Extension
//  Architecture: Extension
//

import SwiftUI
import UniformTypeIdentifiers

/// Host UIViewController pour SwiftUI
class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Créer la vue SwiftUI
        let shareView = ShareView()
            .environment(\.extensionContext, extensionContext)

        // Embed dans un UIHostingController
        let hostingController = UIHostingController(rootView: shareView)

        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }
}

// MARK: - ShareView

/// Vue principale de la Share Extension
struct ShareView: View {

    // MARK: - Environment

    @Environment(\.extensionContext) private var extensionContext

    // MARK: - State

    /// URL extraite depuis le partage
    @State private var sharedURL: String = ""

    /// Priorité sélectionnée
    @State private var priority: Int = 3

    /// Événements disponibles
    @State private var availableEvents: [SharedEvent] = []

    /// Événement sélectionné
    @State private var selectedEventId: UUID?

    /// Indique si on est en train de sauvegarder
    @State private var isSaving: Bool = false

    /// Indique si la sauvegarde est terminée
    @State private var isDone: Bool = false

    /// Métadonnées extraites du produit
    @State private var extractedTitle: String?
    @State private var extractedPrice: Double?
    @State private var extractedImageData: Data?
    @State private var isExtractingMetadata: Bool = false

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // Fond
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if isDone {
                    successView
                } else {
                    formView
                }
            }
            .navigationTitle("Ajouter à Moments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        extensionContext?.cancelRequest(withError: NSError(domain: "MomentsShare", code: 0))
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        saveToWishlist()
                    }
                    .disabled(sharedURL.isEmpty || isSaving || isExtractingMetadata)
                }
            }
        }
        .onAppear {
            extractURL()
            loadAvailableEvents()
        }
    }

    // MARK: - Form View

    private var formView: some View {
        VStack(spacing: 24) {
            // Icône
            Image(systemName: "gift.fill")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color(red: 0.67, green: 0.51, blue: 0.95), Color(red: 0.98, green: 0.67, blue: 0.95)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .padding(.top, 40)

            // URL
            VStack(alignment: .leading, spacing: 8) {
                Text("Lien du produit")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(sharedURL.isEmpty ? "Chargement..." : sharedURL)
                    .font(.subheadline)
                    .foregroundColor(sharedURL.isEmpty ? .secondary : .primary)
                    .lineLimit(2)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)

                if isExtractingMetadata {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Extraction des infos...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Aperçu des métadonnées extraites
                if let title = extractedTitle {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Produit détecté")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 12) {
                            if let imageData = extractedImageData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 50, height: 50)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .lineLimit(2)

                                if let price = extractedPrice {
                                    Text(String(format: "%.2f €", price))
                                        .font(.caption)
                                        .foregroundColor(.green)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)

            // Sélecteur d'événement
            if !availableEvents.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Événement")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Menu {
                        ForEach(availableEvents) { event in
                            Button {
                                selectedEventId = event.id
                            } label: {
                                HStack {
                                    Image(systemName: event.icon)
                                    Text(event.title)
                                }
                            }
                        }
                    } label: {
                        HStack {
                            if let selectedId = selectedEventId,
                               let event = availableEvents.first(where: { $0.id == selectedId }) {
                                Image(systemName: event.icon)
                                    .foregroundColor(.purple)
                                Text(event.title)
                                    .foregroundColor(.primary)
                            } else {
                                Image(systemName: "calendar")
                                    .foregroundColor(.gray)
                                Text("Choisir un événement")
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }

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

                Text(priorityDescription(priority))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            Spacer()

            if isSaving {
                ProgressView("Ajout en cours...")
                    .padding()
            }
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            VStack(spacing: 12) {
                Text("Produit ajouté !")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Ouvrez Moments pour le voir dans votre wishlist")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            Button(action: {
                extensionContext?.completeRequest(returningItems: nil)
            }) {
                Text("OK")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.67, green: 0.51, blue: 0.95), Color(red: 0.98, green: 0.67, blue: 0.95)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
    }

    // MARK: - Actions

    /// Extrait l'URL depuis le contexte de partage
    private func extractURL() {
        guard let extensionContext = extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            print("❌ Impossible de récupérer les inputItems")
            return
        }

        for item in inputItems {
            guard let attachments = item.attachments else { continue }

            for provider in attachments {
                // Chercher une URL
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (url, error) in
                        if let shareURL = url as? URL {
                            DispatchQueue.main.async {
                                self.sharedURL = shareURL.absoluteString
                                print("✅ URL extraite: \(self.sharedURL)")

                                // Extraire les métadonnées automatiquement
                                self.extractProductMetadata(from: shareURL.absoluteString)
                            }
                        } else if let error = error {
                            print("❌ Erreur lors de l'extraction de l'URL: \(error)")
                        }
                    }
                    return
                }

                // Fallback: chercher du texte (peut contenir une URL)
                if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                    provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { (text, error) in
                        if let shareText = text as? String {
                            DispatchQueue.main.async {
                                // Extraire l'URL du texte (Amazon partage "Titre... https://url")
                                if let extractedURL = self.extractURLFromText(shareText) {
                                    self.sharedURL = extractedURL
                                    print("✅ URL extraite du texte: \(self.sharedURL)")

                                    // Extraire les métadonnées automatiquement
                                    self.extractProductMetadata(from: extractedURL)
                                } else {
                                    // Fallback: utiliser le texte tel quel
                                    self.sharedURL = shareText
                                    print("✅ Texte extrait (pas d'URL détectée): \(self.sharedURL)")
                                }
                            }
                        }
                    }
                    return
                }
            }
        }
    }

    /// Charge les événements disponibles
    private func loadAvailableEvents() {
        let events = SharedDataManager.shared.getAvailableEvents()
        self.availableEvents = events

        // Sélectionner le premier événement par défaut
        if let first = events.first {
            self.selectedEventId = first.id
        }

        print("✅ \(events.count) événements chargés pour la Share Extension")
    }

    /// Extrait les métadonnées du produit depuis l'URL
    private func extractProductMetadata(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        isExtractingMetadata = true
        print("🔍 Début extraction métadonnées pour: \(urlString)")

        Task {
            do {
                // Timeout de 10 secondes pour l'extraction
                let metadata = try await withTimeout(seconds: 10) {
                    let fetcher = ProductMetadataFetcher()
                    return await fetcher.fetchMetadata(from: urlString)
                }

                await MainActor.run {
                    if let metadata = metadata {
                        self.extractedTitle = metadata.title
                        self.extractedPrice = metadata.price
                        self.extractedImageData = metadata.imageData
                        print("✅ Métadonnées extraites:")
                        print("   - Titre: \(metadata.title ?? "N/A")")
                        print("   - Prix: \(metadata.price ?? 0)")
                        print("   - Image: \(metadata.imageData != nil ? "✓ (\(metadata.imageData!.count) bytes)" : "✗")")
                    } else {
                        print("⚠️ Aucune métadonnée extraite")
                    }
                    self.isExtractingMetadata = false
                }
            } catch {
                print("❌ Timeout ou erreur lors de l'extraction: \(error)")
                await MainActor.run {
                    self.isExtractingMetadata = false
                }
            }
        }
    }

    /// Timeout helper
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    struct TimeoutError: Error {}

    /// Sauvegarde le produit dans les données partagées
    private func saveToWishlist() {
        guard !sharedURL.isEmpty else { return }

        isSaving = true

        // Créer un pending item avec les métadonnées
        let pendingItem = PendingWishlistItem(
            url: sharedURL,
            title: extractedTitle,
            price: extractedPrice,
            imageData: extractedImageData,
            priority: priority,
            eventId: selectedEventId
        )

        // Sauvegarder via SharedDataManager
        SharedDataManager.shared.addPendingWishlistItem(pendingItem)

        // Simuler un petit délai pour l'UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isSaving = false
            isDone = true

            // Fermer après 1.5 secondes
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                extensionContext?.completeRequest(returningItems: nil)
            }
        }
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

    /// Extrait une URL d'un texte (pour Amazon qui partage "Titre... https://url")
    private func extractURLFromText(_ text: String) -> String? {
        // Regex pour trouver une URL dans le texte
        let pattern = "(https?://[^\\s]+)"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }

        let range = NSRange(text.startIndex..., in: text)
        if let match = regex.firstMatch(in: text, options: [], range: range) {
            if let urlRange = Range(match.range(at: 1), in: text) {
                return String(text[urlRange])
            }
        }

        return nil
    }
}

// MARK: - Environment Key

/// Clé d'environnement pour accéder au contexte d'extension
private struct ExtensionContextKey: EnvironmentKey {
    static let defaultValue: NSExtensionContext? = nil
}

extension EnvironmentValues {
    var extensionContext: NSExtensionContext? {
        get { self[ExtensionContextKey.self] }
        set { self[ExtensionContextKey.self] = newValue }
    }
}
