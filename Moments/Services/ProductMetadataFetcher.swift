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

        // ✅ ÉTAPE 4: Extraire le prix avec priorisation intelligente
        // Stratégie 1: JSON-LD (le plus fiable, structure standardisée)
        if let jsonLDPrice = extractPriceFromJSONLD(html: html) {
            productMetadata.price = jsonLDPrice
            print("💰 Prix JSON-LD: \(jsonLDPrice)")
        }
        // Stratégie 2: Open Graph
        else if let priceString = extractOpenGraphTag(from: html, property: "og:price:amount") ?? extractOpenGraphTag(from: html, property: "product:price:amount") {
            productMetadata.price = Double(priceString)
            print("💰 Prix Open Graph: \(priceString)")
        }
        // Stratégie 3: Microdata (itemprop)
        else if let microdataPrice = extractPriceFromMicrodata(html: html) {
            productMetadata.price = microdataPrice
            print("💰 Prix Microdata: \(microdataPrice)")
        }
        // Stratégie 4: Fallback HTML avec patterns spécifiques
        else {
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

    /// Extrait le prix depuis le JSON-LD (données structurées)
    /// ✅ C'est la méthode LA PLUS FIABLE car standardisée
    private func extractPriceFromJSONLD(html: String) -> Double? {
        // Chercher TOUS les blocs <script type="application/ld+json">
        let jsonLDPattern = "<script[^>]*type=\"application/ld\\+json\"[^>]*>([\\s\\S]*?)</script>"

        guard let regex = try? NSRegularExpression(pattern: jsonLDPattern, options: [.caseInsensitive]) else {
            return nil
        }

        let nsString = html as NSString
        let range = NSRange(location: 0, length: nsString.length)
        let matches = regex.matches(in: html, options: [], range: range)

        for match in matches {
            if match.numberOfRanges > 1,
               let jsonRange = Range(match.range(at: 1), in: html) {
                let jsonString = String(html[jsonRange])

                // Patterns pour trouver le prix dans le JSON-LD
                // Format: "price": "89.99" ou "price": 89.99 ou "offers": {"price": "89.99"}
                let pricePatterns = [
                    "\"price\"\\s*:\\s*\"?([0-9]+[.,]?[0-9]{0,2})\"?",
                    "\"lowPrice\"\\s*:\\s*\"?([0-9]+[.,]?[0-9]{0,2})\"?",  // Pour les prix variables
                ]

                for pattern in pricePatterns {
                    if let priceString = extractFirstMatch(from: jsonString, pattern: pattern) {
                        let cleanPrice = priceString
                            .replacingOccurrences(of: ",", with: ".")
                            .trimmingCharacters(in: .whitespacesAndNewlines)

                        if let price = Double(cleanPrice), price >= 1.0 && price <= 100000 {
                            print("🎯 Prix JSON-LD trouvé: \(price)€ dans le bloc structured data")
                            return price
                        }
                    }
                }
            }
        }

        return nil
    }

    /// Extrait le prix depuis les microdata (itemprop="price")
    /// ✅ Deuxième méthode la plus fiable après JSON-LD
    private func extractPriceFromMicrodata(html: String) -> Double? {
        let patterns = [
            "itemprop=\"price\"[^>]*content=\"([0-9]+[.,]?[0-9]{0,2})\"",
            "content=\"([0-9]+[.,]?[0-9]{0,2})\"[^>]*itemprop=\"price\"",
            "itemprop=\"lowPrice\"[^>]*content=\"([0-9]+[.,]?[0-9]{0,2})\"",
        ]

        for pattern in patterns {
            if let priceString = extractFirstMatch(from: html, pattern: pattern) {
                let cleanPrice = priceString
                    .replacingOccurrences(of: ",", with: ".")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if let price = Double(cleanPrice), price >= 1.0 && price <= 100000 {
                    print("🎯 Prix Microdata trouvé: \(price)€")
                    return price
                }
            }
        }

        return nil
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
        // NOTE: L'ordre est IMPORTANT - les patterns les plus spécifiques doivent être en premier
        let patterns = [
            // JSON-LD et structured data (très fiable) - EN PREMIER
            "\"@type\":\\s*\"Offer\"[^}]*\"price\":\\s*\"?([0-9]+[,\\.]?[0-9]{2})",
            "\"price\":\\s*\"?([0-9]+[,\\.]?[0-9]{2})\"",

            // ✅ Amazon spécifique (classes CSS Amazon)
            "<span[^>]*class=\"[^\"]*a-price-whole[^\"]*\"[^>]*>([0-9]+)[,\\.]?</span>",
            "<span[^>]*class=\"[^\"]*a-offscreen[^\"]*\"[^>]*>\\s*€?\\s*([0-9]+)[,\\.]([0-9]{2})",
            "id=\"priceblock_ourprice\"[^>]*>\\s*€?\\s*([0-9]+[,\\.]?[0-9]{2})",
            "id=\"priceblock_dealprice\"[^>]*>\\s*€?\\s*([0-9]+[,\\.]?[0-9]{2})",

            // Microdata (très fiable)
            "itemprop=\"price\"[^>]*content=\"([0-9]+[,\\.]?[0-9]{2})\"",
            "content=\"([0-9]+[,\\.]?[0-9]{2})\"[^>]*itemprop=\"price\"",

            // Attributs data (e-commerce)
            "data-price=\"([0-9]+[,\\.]?[0-9]{2})\"",
            "data-a-price=\"([0-9]+[,\\.]?[0-9]{2})\"",
            "content=\"([0-9]+[,\\.]?[0-9]{2})\"[^>]*property=\"product:price:amount\"",

            // Classes spécifiques sites français
            "class=\"[^\"]*prix[^\"]*principal[^\"]*\"[^>]*>\\s*([0-9]+[,\\.]?[0-9]{2})",
            "class=\"[^\"]*price[^\"]*product[^\"]*\"[^>]*>\\s*€?\\s*([0-9]+[,\\.]?[0-9]{2})",
            "class=\"[^\"]*product[^\"]*price[^\"]*\"[^>]*>\\s*€?\\s*([0-9]+[,\\.]?[0-9]{2})",

            // Balises HTML génériques avec "price" (moins spécifiques, donc à la fin)
            "<span[^>]*class=\"[^\"]*price[^\"]*\"[^>]*>\\s*€?\\s*([0-9]+[,\\.]?[0-9]{2})",
            "<div[^>]*class=\"[^\"]*price[^\"]*\"[^>]*>\\s*€?\\s*([0-9]+[,\\.]?[0-9]{2})",
            "<p[^>]*class=\"[^\"]*price[^\"]*\"[^>]*>\\s*€?\\s*([0-9]+[,\\.]?[0-9]{2})",
            "<span[^>]*id=\"[^\"]*price[^\"]*\"[^>]*>\\s*€?\\s*([0-9]+[,\\.]?[0-9]{2})",

            // Formats français génériques (symbole € - très large, donc tout à la fin)
            "€\\s*([0-9]+[,\\.]?[0-9]{2})",
            "([0-9]+[,\\.]?[0-9]{2})\\s*€",
            "([0-9]+[,\\.]?[0-9]{2})\\s*EUR"
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
    /// ✅ Retourne simplement le PREMIER prix valide trouvé
    /// (Les patterns sont ordonnés du plus spécifique au plus général)
    private func extractFirstPrice(from html: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return nil
        }

        let nsString = html as NSString
        let range = NSRange(location: 0, length: nsString.length)

        // ✅ Trouver la PREMIÈRE correspondance
        guard let match = regex.firstMatch(in: html, options: [], range: range),
              match.numberOfRanges > 1 else {
            return nil
        }

        let priceRange = match.range(at: 1)
        guard let swiftRange = Range(priceRange, in: html) else {
            return nil
        }

        var priceString = String(html[swiftRange])
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: "") // Espace insécable
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Si pattern Amazon avec 2 groupes de capture (partie entière + décimales)
        if match.numberOfRanges > 2 {
            let decimalRange = match.range(at: 2)
            if let decimalSwiftRange = Range(decimalRange, in: html) {
                let decimalPart = String(html[decimalSwiftRange])
                priceString = "\(priceString).\(decimalPart)"
            }
        }

        // ✅ Vérifier que c'est un prix réaliste (entre 1€ et 100000€)
        if let price = Double(priceString), price >= 1.0 && price <= 100000 {
            print("🎯 Prix trouvé: \(price)€")
            return price
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
