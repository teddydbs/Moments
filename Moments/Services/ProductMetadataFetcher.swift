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
class ProductMetadataFetcher: ObservableObject {

    @Published var isLoading = false
    @Published var error: String?

    /// Récupère les métadonnées d'un produit depuis une URL
    /// - Parameter urlString: L'URL du produit
    /// - Returns: ProductMetadata avec titre, image et prix
    func fetchMetadata(from urlString: String) async -> ProductMetadata? {
        guard let url = URL(string: urlString) else {
            await MainActor.run { error = "URL invalide" }
            return nil
        }

        await MainActor.run {
            isLoading = true
            error = nil
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        var productMetadata = ProductMetadata()

        // ✅ ÉTAPE 1: Télécharger le HTML de la page
        guard let html = await downloadHTML(from: url) else {
            print("❌ Impossible de télécharger le HTML, fallback vers LinkPresentation")
            return await fallbackToLinkPresentation(url: url)
        }

        print("✅ HTML téléchargé: \(html.prefix(500))...")

        // ✅ ÉTAPE 2: Extraire les métadonnées Open Graph
        productMetadata.title = extractOpenGraphTag(from: html, property: "og:title") ?? extractOpenGraphTag(from: html, property: "twitter:title")
        print("📝 Titre extrait: \(productMetadata.title ?? "nil")")

        // ✅ ÉTAPE 3: Extraire l'image Open Graph (meilleure que LinkPresentation)
        if let imageURL = extractOpenGraphTag(from: html, property: "og:image") ?? extractOpenGraphTag(from: html, property: "twitter:image") {
            print("🖼️ URL image Open Graph: \(imageURL)")
            // Gérer les URLs relatives
            let fullImageURL = makeAbsoluteURL(imageURL, baseURL: url)
            productMetadata.imageData = await downloadImage(from: fullImageURL)
        } else {
            print("❌ Pas d'image Open Graph trouvée")
        }

        // ✅ ÉTAPE 4: Extraire le prix (Open Graph puis HTML)
        if let priceString = extractOpenGraphTag(from: html, property: "og:price:amount") ?? extractOpenGraphTag(from: html, property: "product:price:amount") {
            productMetadata.price = Double(priceString)
            print("💰 Prix Open Graph: \(priceString)")
        } else {
            // Fallback: chercher dans le HTML
            productMetadata.price = extractPriceFromHTML(html)
            print("💰 Prix HTML: \(productMetadata.price ?? 0)")
        }

        // Si on n'a rien récupéré, fallback vers LinkPresentation
        if productMetadata.title == nil || productMetadata.imageData == nil {
            print("⚠️ Données incomplètes, fallback vers LinkPresentation")
            let fallbackData = await fallbackToLinkPresentation(url: url)

            // Garder les données qu'on a réussi à récupérer
            if productMetadata.title == nil {
                productMetadata.title = fallbackData?.title
            }
            if productMetadata.imageData == nil {
                productMetadata.imageData = fallbackData?.imageData
            }
        }

        // Nettoyer le titre
        if let title = productMetadata.title {
            productMetadata.title = cleanTitle(title)
        }

        return productMetadata
    }

    /// Fallback vers LinkPresentation si le scraping échoue
    private func fallbackToLinkPresentation(url: URL) async -> ProductMetadata? {
        let provider = LPMetadataProvider()

        do {
            let metadata = try await provider.startFetchingMetadata(for: url)
            var productMetadata = ProductMetadata()

            if let title = metadata.title {
                productMetadata.title = cleanTitle(title)
            }

            if let imageProvider = metadata.imageProvider {
                productMetadata.imageData = await loadImage(from: imageProvider)
            }

            return productMetadata
        } catch {
            print("❌ Erreur LinkPresentation: \(error)")
            return nil
        }
    }

    // MARK: - Helper Methods

    /// Convertit une URL relative en URL absolue
    private func makeAbsoluteURL(_ urlString: String, baseURL: URL) -> String {
        // Si c'est déjà une URL absolue, la retourner telle quelle
        if urlString.hasPrefix("http://") || urlString.hasPrefix("https://") {
            return urlString
        }

        // Si c'est une URL relative commençant par /
        if urlString.hasPrefix("/") {
            if let scheme = baseURL.scheme, let host = baseURL.host {
                return "\(scheme)://\(host)\(urlString)"
            }
        }

        // Sinon, concaténer avec l'URL de base
        return baseURL.absoluteString + urlString
    }

    /// Télécharge le HTML d'une page web
    private func downloadHTML(from url: URL) async -> String? {
        do {
            var request = URLRequest(url: url)
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

            let (data, _) = try await URLSession.shared.data(for: request)
            return String(data: data, encoding: .utf8)
        } catch {
            print("❌ Erreur téléchargement HTML: \(error)")
            return nil
        }
    }

    /// Télécharge une image depuis une URL
    private func downloadImage(from urlString: String) async -> Data? {
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let uiImage = UIImage(data: data) {
                return resizeImage(uiImage, maxSize: 800)
            }
            return nil
        } catch {
            print("❌ Erreur téléchargement image: \(error)")
            return nil
        }
    }

    /// Extrait une balise Open Graph depuis le HTML
    private func extractOpenGraphTag(from html: String, property: String) -> String? {
        // Pattern pour <meta property="og:title" content="...">
        let pattern = "<meta\\s+property=\"\(property)\"\\s+content=\"([^\"]+)\""

        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }

        let nsString = html as NSString
        let range = NSRange(location: 0, length: nsString.length)

        if let match = regex.firstMatch(in: html, options: [], range: range),
           match.numberOfRanges > 1 {
            let contentRange = match.range(at: 1)
            return nsString.substring(with: contentRange)
        }

        // Alternative: content="..." property="..."
        let altPattern = "<meta\\s+content=\"([^\"]+)\"\\s+property=\"\(property)\""
        guard let altRegex = try? NSRegularExpression(pattern: altPattern, options: .caseInsensitive) else {
            return nil
        }

        if let match = altRegex.firstMatch(in: html, options: [], range: range),
           match.numberOfRanges > 1 {
            let contentRange = match.range(at: 1)
            return nsString.substring(with: contentRange)
        }

        return nil
    }

    /// Extrait le prix depuis le HTML (fallback si pas d'Open Graph)
    private func extractPriceFromHTML(_ html: String) -> Double? {
        // Patterns courants pour les prix
        let patterns = [
            "<span[^>]*class=\"[^\"]*price[^\"]*\"[^>]*>.*?([0-9]+[,\\.]?[0-9]*)",  // class="price"
            "<div[^>]*class=\"[^\"]*price[^\"]*\"[^>]*>.*?([0-9]+[,\\.]?[0-9]*)",   // div.price
            "\"price\":\\s*\"?([0-9]+\\.?[0-9]*)",  // JSON {"price": "99.99"}
            "€\\s*([0-9]+[,\\.]?[0-9]*)",           // 99,99 €
            "([0-9]+[,\\.]?[0-9]*)\\s*€"            // € 99,99
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
               match.numberOfRanges > 1 {

                let priceRange = match.range(at: 1)
                if let range = Range(priceRange, in: html) {
                    let priceString = String(html[range])
                        .replacingOccurrences(of: ",", with: ".")
                        .trimmingCharacters(in: .whitespaces)

                    if let price = Double(priceString), price > 0 && price < 1000000 {
                        return price
                    }
                }
            }
        }

        return nil
    }

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
    nonisolated private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> Data? {
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
}
