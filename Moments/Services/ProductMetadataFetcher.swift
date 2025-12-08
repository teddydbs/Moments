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

        // ✅ ÉTAPE 3: Extraire l'image avec plusieurs stratégies
        productMetadata.imageData = await extractProductImage(from: html, baseURL: url)

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

    /// Extrait l'image du produit avec plusieurs stratégies de fallback
    /// - Parameters:
    ///   - html: Le HTML de la page
    ///   - baseURL: L'URL de base pour les liens relatifs
    /// - Returns: Les données de l'image ou nil
    private func extractProductImage(from html: String, baseURL: URL) async -> Data? {
        // ✅ STRATÉGIE 1: Open Graph (og:image) - Le plus fiable
        if let ogImageURL = extractOpenGraphTag(from: html, property: "og:image") {
            print("🖼️ Image Open Graph trouvée: \(ogImageURL)")
            let fullURL = makeAbsoluteURL(ogImageURL, baseURL: baseURL)
            if let imageData = await downloadImage(from: fullURL) {
                print("✅ Image Open Graph téléchargée")
                return imageData
            }
        }

        // ✅ STRATÉGIE 2: Twitter Card (twitter:image)
        if let twitterImageURL = extractOpenGraphTag(from: html, property: "twitter:image") {
            print("🖼️ Image Twitter Card trouvée: \(twitterImageURL)")
            let fullURL = makeAbsoluteURL(twitterImageURL, baseURL: baseURL)
            if let imageData = await downloadImage(from: fullURL) {
                print("✅ Image Twitter Card téléchargée")
                return imageData
            }
        }

        // ✅ STRATÉGIE 3: Balise meta avec itemprop="image"
        if let micropDataImageURL = extractImageFromMicrodata(html: html) {
            print("🖼️ Image Microdata trouvée: \(micropDataImageURL)")
            let fullURL = makeAbsoluteURL(micropDataImageURL, baseURL: baseURL)
            if let imageData = await downloadImage(from: fullURL) {
                print("✅ Image Microdata téléchargée")
                return imageData
            }
        }

        // ✅ STRATÉGIE 4: Chercher dans le JSON-LD (structured data)
        if let jsonLDImageURL = extractImageFromJSONLD(html: html) {
            print("🖼️ Image JSON-LD trouvée: \(jsonLDImageURL)")
            let fullURL = makeAbsoluteURL(jsonLDImageURL, baseURL: baseURL)
            if let imageData = await downloadImage(from: fullURL) {
                print("✅ Image JSON-LD téléchargée")
                return imageData
            }
        }

        // ✅ STRATÉGIE 5: Chercher les balises <img> avec des classes spécifiques
        if let productImageURL = extractImageFromImgTag(html: html) {
            print("🖼️ Image <img> trouvée: \(productImageURL)")
            let fullURL = makeAbsoluteURL(productImageURL, baseURL: baseURL)
            if let imageData = await downloadImage(from: fullURL) {
                print("✅ Image <img> téléchargée")
                return imageData
            }
        }

        print("❌ Aucune image trouvée avec les stratégies de scraping")
        return nil
    }

    /// Extrait l'URL de l'image depuis les microdata (itemprop="image")
    private func extractImageFromMicrodata(html: String) -> String? {
        let patterns = [
            "itemprop=\"image\"[^>]*content=\"([^\"]+)\"",
            "content=\"([^\"]+)\"[^>]*itemprop=\"image\"",
            "itemprop=\"image\"[^>]*src=\"([^\"]+)\"",
            "src=\"([^\"]+)\"[^>]*itemprop=\"image\""
        ]

        for pattern in patterns {
            if let url = extractFirstMatch(from: html, pattern: pattern) {
                return url
            }
        }
        return nil
    }

    /// Extrait l'URL de l'image depuis le JSON-LD
    private func extractImageFromJSONLD(html: String) -> String? {
        // Chercher le bloc <script type="application/ld+json">
        let jsonLDPattern = "<script[^>]*type=\"application/ld\\+json\"[^>]*>([^<]+)</script>"

        guard let regex = try? NSRegularExpression(pattern: jsonLDPattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: html, options: [], range: NSRange(html.startIndex..., in: html)),
              match.numberOfRanges > 1,
              let jsonRange = Range(match.range(at: 1), in: html) else {
            return nil
        }

        let jsonString = String(html[jsonRange])

        // Chercher "image": "URL" dans le JSON
        let imagePattern = "\"image\"\\s*:\\s*\"([^\"]+)\""
        return extractFirstMatch(from: jsonString, pattern: imagePattern)
    }

    /// Extrait l'URL de l'image depuis les balises <img>
    private func extractImageFromImgTag(html: String) -> String? {
        // Chercher les <img> avec des classes spécifiques aux produits
        let patterns = [
            "<img[^>]*class=\"[^\"]*product[^\"]*\"[^>]*src=\"([^\"]+)\"",
            "<img[^>]*class=\"[^\"]*main[^\"]*image[^\"]*\"[^>]*src=\"([^\"]+)\"",
            "<img[^>]*id=\"[^\"]*product[^\"]*image[^\"]*\"[^>]*src=\"([^\"]+)\"",
            "<img[^>]*data-src=\"([^\"]+)\"[^>]*class=\"[^\"]*product[^\"]*\"",
            // Lazy loading images
            "<img[^>]*data-lazy-src=\"([^\"]+)\""
        ]

        for pattern in patterns {
            if let url = extractFirstMatch(from: html, pattern: pattern) {
                return url
            }
        }
        return nil
    }

    /// Helper pour extraire la première correspondance d'un pattern regex
    private func extractFirstMatch(from text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]),
              let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
              match.numberOfRanges > 1,
              let matchRange = Range(match.range(at: 1), in: text) else {
            return nil
        }

        return String(text[matchRange])
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
        // ✅ Patterns exhaustifs pour capturer le maximum de formats de prix
        let patterns = [
            // JSON-LD et structured data (très fiable)
            "\"price\":\\s*\"?([0-9]+[,\\.]?[0-9]*)",
            "\"@type\":\\s*\"Offer\"[^}]*\"price\":\\s*\"?([0-9]+[,\\.]?[0-9]*)",

            // Balises HTML avec class/id "price"
            "<span[^>]*class=\"[^\"]*price[^\"]*\"[^>]*>\\s*€?\\s*([0-9]+[,\\.]?[0-9]*)",
            "<div[^>]*class=\"[^\"]*price[^\"]*\"[^>]*>\\s*€?\\s*([0-9]+[,\\.]?[0-9]*)",
            "<p[^>]*class=\"[^\"]*price[^\"]*\"[^>]*>\\s*€?\\s*([0-9]+[,\\.]?[0-9]*)",
            "<span[^>]*id=\"[^\"]*price[^\"]*\"[^>]*>\\s*€?\\s*([0-9]+[,\\.]?[0-9]*)",

            // Formats français avec €
            "€\\s*([0-9]+[,\\.]?[0-9]*)",
            "([0-9]+[,\\.]?[0-9]*)\\s*€",
            "([0-9]+[,\\.]?[0-9]*)\\s*EUR",

            // Formats e-commerce courants (Amazon, Fnac, etc.)
            "data-price=\"([0-9]+[,\\.]?[0-9]*)\"",
            "content=\"([0-9]+[,\\.]?[0-9]*)\"[^>]*property=\"product:price:amount\"",

            // Microdata
            "itemprop=\"price\"[^>]*content=\"([0-9]+[,\\.]?[0-9]*)\"",
            "content=\"([0-9]+[,\\.]?[0-9]*)\"[^>]*itemprop=\"price\"",

            // Classes spécifiques sites français
            "class=\"[^\"]*prix[^\"]*\"[^>]*>\\s*([0-9]+[,\\.]?[0-9]*)",
            "class=\"[^\"]*montant[^\"]*\"[^>]*>\\s*([0-9]+[,\\.]?[0-9]*)"
        ]

        // ✅ Essayer chaque pattern et retourner le premier prix valide trouvé
        for pattern in patterns {
            if let price = extractFirstPrice(from: html, pattern: pattern) {
                print("💰 Prix trouvé avec pattern: \(pattern)")
                return price
            }
        }

        print("❌ Aucun prix trouvé dans le HTML")
        return nil
    }

    /// Helper pour extraire le premier prix valide avec un pattern donné
    private func extractFirstPrice(from html: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return nil
        }

        let nsString = html as NSString
        let range = NSRange(location: 0, length: nsString.length)

        // ✅ Trouver TOUTES les correspondances (pas juste la première)
        let matches = regex.matches(in: html, options: [], range: range)

        for match in matches {
            if match.numberOfRanges > 1 {
                let priceRange = match.range(at: 1)
                if let swiftRange = Range(priceRange, in: html) {
                    let priceString = String(html[swiftRange])
                        .replacingOccurrences(of: ",", with: ".")
                        .replacingOccurrences(of: " ", with: "")
                        .trimmingCharacters(in: .whitespacesAndNewlines)

                    // ✅ Vérifier que c'est un prix réaliste (entre 0.01 et 100000 €)
                    if let price = Double(priceString), price >= 0.01 && price <= 100000 {
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
