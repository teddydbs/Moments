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

        // ⚠️ API Amazon Product Advertising désactivée temporairement
        // L'API nécessite un compte avec des ventes qualifiées
        // TODO: Réactiver quand le compte Amazon Associates aura généré des ventes
        /*
        if urlString.contains("amazon.") || urlString.contains("amzn.") {
            print("🛒 URL Amazon détectée, utilisation de l'API officielle")
            if let asin = await AmazonProductAPIManager.shared.extractASIN(from: urlString) {
                do {
                    let amazonInfo = try await AmazonProductAPIManager.shared.fetchProductInfo(asin: asin)
                    productMetadata.title = amazonInfo.title
                    productMetadata.price = amazonInfo.price
                    if let imageURL = amazonInfo.imageURL {
                        productMetadata.imageData = await downloadImage(from: imageURL)
                    }
                    print("✅ Données Amazon récupérées via API officielle")
                    return productMetadata
                } catch {
                    print("⚠️ Erreur API Amazon: \(error), fallback vers scraping HTML")
                }
            }
        }
        */

        // ✅ ÉTAPE 2: Télécharger le HTML de la page (pour les sites non-Amazon ou en fallback)
        guard let html = await downloadHTML(from: url) else {
            print("❌ Impossible de télécharger le HTML, fallback vers LinkPresentation")
            return await fallbackToLinkPresentation(url: url)
        }

        print("✅ HTML téléchargé: \(html.prefix(500))...")

        // ✅ Détection Amazon pour extraction spécifique
        let isAmazon = url.absoluteString.contains("amazon") || url.absoluteString.contains("amzn")

        // ✅ ÉTAPE 2: Extraire le titre
        var rawTitle: String?

        if isAmazon {
            // Amazon: Extraction spécifique depuis JavaScript ou <title>
            rawTitle = extractAmazonTitle(from: html)
        }

        // Fallback vers Open Graph si Amazon n'a pas fonctionné ou si ce n'est pas Amazon
        if rawTitle == nil {
            rawTitle = extractOpenGraphTag(from: html, property: "og:title") ?? extractOpenGraphTag(from: html, property: "twitter:title")
        }

        // ✅ Raccourcir le titre si trop long (garder marque + type de produit)
        if let title = rawTitle, title.count > 60 {
            productMetadata.title = shortenProductTitle(title)
            print("📝 Titre raccourci: \(productMetadata.title ?? "nil") (original: \(title.prefix(50))...)")
        } else {
            productMetadata.title = rawTitle
            print("📝 Titre extrait: \(productMetadata.title ?? "nil")")
        }

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
        // Stratégie 3: JavaScript Data (Amazon, sites dynamiques)
        else if let jsPrice = extractPriceFromJavaScriptData(html: html) {
            productMetadata.price = jsPrice
            print("💰 Prix JavaScript: \(jsPrice)")
        }
        // Stratégie 4: Microdata (itemprop)
        else if let microdataPrice = extractPriceFromMicrodata(html: html) {
            productMetadata.price = microdataPrice
            print("💰 Prix Microdata: \(microdataPrice)")
        }
        // Stratégie 5: Fallback HTML avec patterns spécifiques
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
    /// ✅ Utilise ScraperAPI pour Amazon (avec JavaScript) si configuré
    private func downloadHTML(from url: URL) async -> String? {
        var finalURLString = url.absoluteString

        // ✅ ÉTAPE 1: Si URL raccourcie Amazon, extraire l'ASIN et construire l'URL complète
        if finalURLString.contains("amzn.eu") || finalURLString.contains("amzn.to") {
            print("🔗 URL raccourcie Amazon, extraction de l'ASIN...")
            if let asin = await AmazonProductAPIManager.shared.extractASIN(from: finalURLString) {
                finalURLString = "https://www.amazon.fr/dp/\(asin)"
                print("✅ URL complète reconstruite: \(finalURLString)")
            }
        }

        // ✅ ÉTAPE 2: Si c'est Amazon ET ScraperAPI est configuré, utiliser ScraperAPI
        if (finalURLString.contains("amazon") || finalURLString.contains("amzn")) && ScraperAPIManager.shared.isConfigured {
            print("🚀 Utilisation de ScraperAPI pour Amazon (avec JavaScript)")
            do {
                return try await ScraperAPIManager.shared.fetchHTML(from: finalURLString)
            } catch {
                print("⚠️ ScraperAPI échoué, fallback vers scraping classique")
                // Continue avec scraping classique en cas d'erreur
            }
        }

        // Scraping classique (sans JavaScript)
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
        // ✅ STRATÉGIE 0: Amazon - Image principale du produit (landingImage ou hiRes)
        if baseURL.absoluteString.contains("amazon") {
            if let amazonImageURL = extractAmazonMainImage(from: html) {
                print("🖼️ Image principale Amazon trouvée: \(amazonImageURL)")
                if let imageData = await downloadImage(from: amazonImageURL) {
                    print("✅ Image principale Amazon téléchargée")
                    return imageData
                }
            }
        }

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
            print("❌ JSON-LD: Erreur création regex")
            return nil
        }

        let nsString = html as NSString
        let range = NSRange(location: 0, length: nsString.length)
        let matches = regex.matches(in: html, options: [], range: range)

        print("🔍 JSON-LD: \(matches.count) blocs trouvés dans le HTML")

        for (index, match) in matches.enumerated() {
            if match.numberOfRanges > 1,
               let jsonRange = Range(match.range(at: 1), in: html) {
                let jsonString = String(html[jsonRange])
                print("📦 JSON-LD Bloc #\(index + 1): \(jsonString.prefix(200))...")

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
                            print("🎯 Prix JSON-LD trouvé: \(price)€ dans le bloc #\(index + 1)")
                            return price
                        } else {
                            print("⚠️ Prix JSON-LD invalide: \(priceString) -> \(cleanPrice)")
                        }
                    }
                }
            }
        }

        print("❌ JSON-LD: Aucun prix valide trouvé dans les \(matches.count) blocs")
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

    /// Raccourcit un titre de produit en gardant l'essentiel (marque + type)
    /// Exemple: "SONGMICS Chaise de Bureau, Chaise Ergonomique, avec..." → "SONGMICS Chaise de Bureau"
    private func shortenProductTitle(_ title: String) -> String {
        // Supprimer les informations après une virgule, tiret ou parenthèse
        let separators = [",", " -", "(", "|"]

        var shortened = title
        for separator in separators {
            if let range = shortened.range(of: separator) {
                shortened = String(shortened[..<range.lowerBound])
                break
            }
        }

        // Limiter à 50 caractères maximum
        if shortened.count > 50 {
            shortened = String(shortened.prefix(50)).trimmingCharacters(in: .whitespaces) + "..."
        }

        return shortened.trimmingCharacters(in: .whitespaces)
    }

    /// Extrait le titre Amazon depuis le HTML
    /// PRIORITÉ à la balise <title> qui est la plus fiable
    private func extractAmazonTitle(from html: String) -> String? {
        // Stratégie 1: Balise <title> (LE PLUS FIABLE)
        if let titleRange = html.range(of: "<title>", options: .caseInsensitive),
           let endTitleRange = html.range(of: "</title>", options: .caseInsensitive, range: titleRange.upperBound..<html.endIndex) {

            let titleContent = String(html[titleRange.upperBound..<endTitleRange.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)

            // Supprimer " : Amazon.fr..." ou "- Amazon.fr..." à la fin
            var cleanTitle = titleContent

            if let amazonSeparator = cleanTitle.range(of: " : Amazon", options: .caseInsensitive) {
                cleanTitle = String(cleanTitle[..<amazonSeparator.lowerBound])
            } else if let amazonSeparator = cleanTitle.range(of: "- Amazon", options: .caseInsensitive) {
                cleanTitle = String(cleanTitle[..<amazonSeparator.lowerBound])
            }

            cleanTitle = cleanTitle.trimmingCharacters(in: .whitespacesAndNewlines)

            // Vérifier que ce n'est pas du code CSS ou JavaScript
            if !cleanTitle.isEmpty && !cleanTitle.contains("<style") && !cleanTitle.contains("{") {
                print("🎯 Titre Amazon extrait de <title>: \(cleanTitle.prefix(60))...")
                return cleanTitle
            }
        }

        // Stratégie 2: Meta property="og:title"
        if let ogTitleRange = html.range(of: "<meta\\s+property=\"og:title\"\\s+content=\"([^\"]+)\"", options: .regularExpression),
           let regex = try? NSRegularExpression(pattern: "<meta\\s+property=\"og:title\"\\s+content=\"([^\"]+)\"", options: [.caseInsensitive]),
           let match = regex.firstMatch(in: html, range: NSRange(ogTitleRange, in: html)),
           match.numberOfRanges > 1,
           let contentRange = Range(match.range(at: 1), in: html) {

            let ogTitle = String(html[contentRange])
            print("🎯 Titre Amazon extrait de og:title: \(ogTitle.prefix(60))...")
            return ogTitle
        }

        // Stratégie 3: ID productTitle dans le HTML
        if let productTitleRange = html.range(of: "id=\"productTitle\"[^>]*>\\s*([^<]+)", options: .regularExpression),
           let regex = try? NSRegularExpression(pattern: "id=\"productTitle\"[^>]*>\\s*([^<]+)", options: []),
           let match = regex.firstMatch(in: html, range: NSRange(productTitleRange, in: html)),
           match.numberOfRanges > 1,
           let titleRange = Range(match.range(at: 1), in: html) {

            let productTitle = String(html[titleRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            print("🎯 Titre Amazon extrait de #productTitle: \(productTitle.prefix(60))...")
            return productTitle
        }

        print("❌ Aucun titre Amazon trouvé")
        return nil
    }

    /// Extrait l'image principale Amazon (haute résolution)
    /// Amazon stocke les images dans des objets JavaScript
    private func extractAmazonMainImage(from html: String) -> String? {
        // Patterns pour trouver l'image principale Amazon (par ordre de préférence)
        let patterns = [
            // 1. Image haute résolution dans colorImages (la meilleure qualité)
            "\"hiRes\"\\s*:\\s*\"(https://m\\.media-amazon\\.com/images/I/[^\"]+)\"",

            // 2. Image large dans imageGalleryData
            "\"large\"\\s*:\\s*\"(https://m\\.media-amazon\\.com/images/I/[^\"]+\\.jpg)\"",

            // 3. Meta tag og:image
            "<meta\\s+property=\"og:image\"\\s+content=\"(https://m\\.media-amazon\\.com/images/I/[^\"]+)\"",

            // 4. Image dans landingImage
            "\"landingImageUrl\"\\s*:\\s*\"(https://[^\"]+)\"",

            // 5. Pattern générique pour toute image Amazon haute résolution
            "(https://m\\.media-amazon\\.com/images/I/[A-Za-z0-9+_-]+\\._AC_SL1500_\\.jpg)",
            "(https://m\\.media-amazon\\.com/images/I/[A-Za-z0-9+_-]+\\._AC_SX\\d+_\\.jpg)",
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
               let match = regex.firstMatch(in: html, options: [], range: NSRange(location: 0, length: html.utf16.count)),
               match.numberOfRanges > 1,
               let imageRange = Range(match.range(at: 1), in: html) {

                var imageURL = String(html[imageRange])

                // Nettoyer l'URL (parfois il y a des échappements)
                imageURL = imageURL.replacingOccurrences(of: "\\/", with: "/")

                print("🎯 Image Amazon extraite avec pattern: \(pattern.prefix(60))...")
                return imageURL
            }
        }

        print("❌ Aucune image Amazon haute résolution trouvée")
        return nil
    }

    /// Extrait le prix depuis les objets JavaScript embarqués d'Amazon
    /// Amazon stocke souvent les prix dans des blocs JSON dans <script> ou data attributes
    private func extractPriceFromJavaScriptData(html: String) -> Double? {
        // Patterns pour extraire les prix depuis les objets JS d'Amazon
        let patterns = [
            // Prix dans les objets JSON JavaScript (ex: priceAmount, displayPrice)
            "\"priceAmount\"\\s*:\\s*([0-9]+\\.?[0-9]{0,2})",
            "\"displayPrice\"\\s*:\\s*\"?([0-9]+[.,]?[0-9]{0,2})\"?",
            "\"ourPrice\"\\s*:\\s*\"?([0-9]+[.,]?[0-9]{0,2})\"?",
            "\"salePrice\"\\s*:\\s*\"?([0-9]+[.,]?[0-9]{0,2})\"?",
            // Prix dans data-attributes
            "data-a-price-amount=\"([0-9]+\\.?[0-9]{0,2})\"",
            "data-price=\"([0-9]+[.,]?[0-9]{0,2})\"",
        ]

        for pattern in patterns {
            if let priceString = extractFirstMatch(from: html, pattern: pattern) {
                let cleanPrice = priceString
                    .replacingOccurrences(of: ",", with: ".")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if let price = Double(cleanPrice), price >= 1.0 && price <= 100000 {
                    print("🎯 Prix JavaScript trouvé: \(price)€ avec pattern: \(pattern)")
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
            // ✅✅✅ AMAZON PROMO/DEAL PRICE (ULTRA PRIORITAIRE) - Prix après réduction
            // Ces patterns ciblent spécifiquement le prix promotionnel, pas le prix barré
            "class=\"[^\"]*priceToPay[^\"]*\"[\\s\\S]{0,300}?<span[^>]*class=\"[^\"]*a-offscreen[^\"]*\"[^>]*>\\s*€?\\s*([0-9]+)[,\\.]([0-9]{2})",
            "class=\"[^\"]*priceToPay[^\"]*\"[\\s\\S]{0,300}?<span[^>]*class=\"[^\"]*a-price-whole[^\"]*\"[^>]*>([0-9]+)",
            "data-a-color=\"price\"[\\s\\S]{0,300}?<span[^>]*class=\"[^\"]*a-offscreen[^\"]*\"[^>]*>\\s*€?\\s*([0-9]+)[,\\.]([0-9]{2})",
            "id=\"kindle-price\"[\\s\\S]{0,300}?<span[^>]*class=\"[^\"]*a-offscreen[^\"]*\"[^>]*>\\s*€?\\s*([0-9]+)[,\\.]([0-9]{2})",

            // JSON-LD et structured data (très fiable)
            "\"@type\":\\s*\"Offer\"[^}]*\"price\":\\s*\"?([0-9]+[.,]?[0-9]{2})",
            "\"price\":\\s*\"?([0-9]+[.,]?[0-9]{2})\"",

            // ✅ Amazon spécifique - Chercher explicitement dans la zone de prix principal
            // Pattern très spécifique: div avec id contenant "price" puis span avec le prix
            "id=\"corePriceDisplay_desktop_feature_div\"[\\s\\S]{0,500}?<span[^>]*class=\"[^\"]*a-price-whole[^\"]*\"[^>]*>([0-9]+)",
            "id=\"corePrice_desktop_feature_div\"[\\s\\S]{0,500}?<span[^>]*class=\"[^\"]*a-offscreen[^\"]*\"[^>]*>([0-9]+)[,\\.]([0-9]{2})",

            // Patterns Amazon généraux (moins spécifiques)
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
