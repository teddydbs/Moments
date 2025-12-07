//
//  ProductMetadataFetcher.swift
//  Moments
//
//  Service pour récupérer automatiquement les métadonnées d'un produit depuis une URL
//  ✅ Utilise LinkPresentation (framework Apple) pour une meilleure fiabilité
//

import Foundation
import UIKit
import Combine
import LinkPresentation
import UniformTypeIdentifiers

/// ❓ POURQUOI: Structure pour stocker les métadonnées d'un produit
struct ProductMetadata {
    var title: String?
    var price: Double?
    var imageData: Data?
}

/// Service pour extraire les métadonnées d'un produit depuis une URL
/// ✅ Utilise LinkPresentation (framework Apple) pour une meilleure fiabilité
@MainActor
class ProductMetadataFetcher: ObservableObject {

    @Published var isLoading = false
    @Published var error: String?

    /// Récupère les métadonnées d'un produit depuis une URL avec LinkPresentation
    /// - Parameter urlString: L'URL du produit
    /// - Returns: ProductMetadata avec titre et image
    func fetchMetadata(from urlString: String) async -> ProductMetadata? {
        guard let url = URL(string: urlString) else {
            error = "URL invalide"
            return nil
        }

        isLoading = true
        error = nil

        defer { isLoading = false }

        // ✅ ÉTAPE 1: Utiliser LinkPresentation pour récupérer les métadonnées
        let provider = LPMetadataProvider()

        do {
            let metadata = try await provider.startFetchingMetadata(for: url)

            var productMetadata = ProductMetadata()

            // ✅ ÉTAPE 2: Extraire le titre
            if let title = metadata.title {
                productMetadata.title = cleanTitle(title)
            }

            // ✅ ÉTAPE 3: Extraire l'image (de manière asynchrone)
            if let imageProvider = metadata.imageProvider {
                productMetadata.imageData = await loadImage(from: imageProvider)
            }

            // ✅ ÉTAPE 4: Essayer d'extraire le prix depuis l'URL (pour certains sites)
            // Note: LinkPresentation ne donne pas le prix, mais on peut essayer de deviner
            if let originalURL = metadata.originalURL?.absoluteString {
                productMetadata.price = extractPriceFromURL(originalURL)
            }

            return productMetadata

        } catch {
            self.error = "Impossible de récupérer les informations du produit"
            print("❌ Erreur LinkPresentation: \(error)")
            return nil
        }
    }

    // MARK: - Helper Methods

    /// Charge l'image depuis un NSItemProvider de manière asynchrone
    /// - Parameter imageProvider: Le provider d'image de LinkPresentation
    /// - Returns: Les données de l'image redimensionnée
    private func loadImage(from imageProvider: NSItemProvider) async -> Data? {
        // ❓ POURQUOI: NSItemProvider fonctionne avec completion handlers
        // On utilise withCheckedContinuation pour le convertir en async/await

        return await withCheckedContinuation { continuation in
            // Essayer de charger comme UIImage
            imageProvider.loadObject(ofClass: UIImage.self) { image, error in
                if let error = error {
                    print("❌ Erreur chargement image: \(error)")
                    continuation.resume(returning: nil)
                    return
                }

                guard let uiImage = image as? UIImage else {
                    continuation.resume(returning: nil)
                    return
                }

                // ✅ OPTIMISATION: Redimensionner l'image
                let resizedData = self.resizeImage(uiImage, maxSize: 800)
                continuation.resume(returning: resizedData)
            }
        }
    }

    /// Redimensionne une image pour économiser de l'espace
    /// - Parameters:
    ///   - image: L'image à redimensionner
    ///   - maxSize: Taille maximale (largeur ou hauteur)
    /// - Returns: Les données JPEG de l'image redimensionnée
    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> Data? {
        let size = image.size

        // Si déjà plus petite, pas besoin de redimensionner
        if size.width <= maxSize && size.height <= maxSize {
            return image.jpegData(compressionQuality: 0.8)
        }

        // Calculer le nouveau ratio
        let ratio = min(maxSize / size.width, maxSize / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        // Créer une nouvelle image redimensionnée
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage?.jpegData(compressionQuality: 0.8)
    }

    /// Nettoie le titre (enlève le nom du site, etc.)
    /// - Parameter title: Le titre brut
    /// - Returns: Le titre nettoyé
    private func cleanTitle(_ title: String) -> String {
        var cleaned = title.trimmingCharacters(in: .whitespacesAndNewlines)

        // ❓ POURQUOI: Les sites mettent souvent "Produit - Nom du Site"
        // On veut juste "Produit"

        // Enlever les parties après " - ", " | ", " • " (souvent le nom du site)
        if let range = cleaned.range(of: " - ") {
            cleaned = String(cleaned[..<range.lowerBound])
        } else if let range = cleaned.range(of: " | ") {
            cleaned = String(cleaned[..<range.lowerBound])
        } else if let range = cleaned.range(of: " • ") {
            cleaned = String(cleaned[..<range.lowerBound])
        }

        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Essaie d'extraire le prix depuis l'URL (tentative basique)
    /// - Parameter urlString: L'URL du produit
    /// - Returns: Le prix si trouvé
    private func extractPriceFromURL(_ urlString: String) -> Double? {
        // ❓ POURQUOI: Certains sites mettent le prix dans les paramètres URL
        // Exemple: ?price=29.99 ou /p/29-99-EUR

        // Pattern basique pour chercher des nombres qui ressemblent à des prix
        let patterns = [
            "price=([0-9]+\\.?[0-9]*)",     // ?price=29.99
            "([0-9]{2,}[\\.\\-][0-9]{2})"   // 29-99 ou 29.99
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: urlString, options: [], range: NSRange(urlString.startIndex..., in: urlString)),
               match.numberOfRanges > 1 {

                let matchRange = match.range(at: 1)
                if let range = Range(matchRange, in: urlString) {
                    let priceString = String(urlString[range])
                        .replacingOccurrences(of: "-", with: ".")

                    if let price = Double(priceString) {
                        return price
                    }
                }
            }
        }

        return nil
    }
}
