//
//  AmazonProductAPIManager.swift
//  Moments
//
//  Description: Gestionnaire de l'API Amazon Product Advertising
//  Architecture: Service
//

import Foundation
import CryptoKit

/// Gestionnaire pour l'API Amazon Product Advertising API 5.0
/// ✅ Permet de récupérer les prix exacts des produits Amazon
class AmazonProductAPIManager {

    // MARK: - Properties

    /// Clé d'accès Amazon
    private let accessKey = "AKPAQ31PAA1765203032"

    /// Clé secrète Amazon
    private let secretKey = "1Ucb0MLGstkyLWdWrdq9IsQNepg4tA0hLMi"

    /// Tag partenaire Amazon
    private let partnerTag = "crossfit046-21"

    /// Région de l'API (France)
    private let region = "eu-west-1"

    /// Host de l'API
    private let host = "webservices.amazon.fr"

    /// Endpoint de l'API
    private let endpoint = "https://webservices.amazon.fr/paapi5/getitems"

    // MARK: - Singleton

    static let shared = AmazonProductAPIManager()

    private init() {}

    // MARK: - Public Methods

    /// Récupère les informations d'un produit Amazon depuis son ASIN
    /// - Parameter asin: L'identifiant Amazon (ex: B0DZGGYQ6T)
    /// - Returns: Métadonnées du produit (titre, prix, image)
    func fetchProductInfo(asin: String) async throws -> AmazonProductInfo {
        print("🛒 Récupération des infos Amazon pour ASIN: \(asin)")

        // ✅ ÉTAPE 1: Créer le body de la requête
        let requestBody = createRequestBody(asin: asin)

        // ✅ ÉTAPE 2: Créer la requête signée avec AWS Signature v4
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.httpBody = requestBody.data(using: .utf8)

        // Headers requis
        let timestamp = ISO8601DateFormatter().string(from: Date())
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue(host, forHTTPHeaderField: "Host")
        request.setValue(timestamp, forHTTPHeaderField: "X-Amz-Date")
        request.setValue("aws4_request", forHTTPHeaderField: "X-Amz-Target")

        // ✅ ÉTAPE 3: Signer la requête avec AWS Signature v4
        let signature = generateAWSSignature(
            method: "POST",
            uri: "/paapi5/getitems",
            headers: [
                "content-type": "application/json; charset=utf-8",
                "host": host,
                "x-amz-date": timestamp
            ],
            payload: requestBody,
            timestamp: timestamp
        )

        request.setValue(signature, forHTTPHeaderField: "Authorization")

        // ✅ ÉTAPE 4: Envoyer la requête
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AmazonAPIError.invalidResponse
        }

        print("📡 Réponse Amazon API: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let errorMessage = String(data: data, encoding: .utf8) {
                print("❌ Erreur Amazon API: \(errorMessage)")
            }
            throw AmazonAPIError.httpError(httpResponse.statusCode)
        }

        // ✅ ÉTAPE 5: Parser la réponse JSON
        let productInfo = try parseResponse(data: data)
        print("✅ Produit Amazon récupéré: \(productInfo.title ?? "Sans titre") - \(productInfo.price ?? 0)€")

        return productInfo
    }

    /// Extrait l'ASIN depuis une URL Amazon (supporte les URLs raccourcies avec redirection)
    /// - Parameter url: URL Amazon (ex: https://www.amazon.fr/dp/B0DZGGYQ6T ou https://amzn.eu/d/XXXXX)
    /// - Returns: ASIN si trouvé
    func extractASIN(from url: String) async -> String? {
        var finalURL = url

        // ✅ Si c'est une URL raccourcie (amzn.eu), suivre la redirection pour obtenir l'URL complète
        if url.contains("amzn.eu") || url.contains("amzn.to") {
            print("🔗 URL raccourcie détectée, suivi de la redirection...")
            if let redirectedURL = await followRedirect(url: url) {
                print("🔗 Redirection vers: \(redirectedURL)")
                finalURL = redirectedURL
            } else {
                print("⚠️ Impossible de suivre la redirection")
                return nil
            }
        }

        // Patterns pour extraire l'ASIN depuis différents formats d'URL Amazon
        let patterns = [
            "/dp/([A-Z0-9]{10})",           // /dp/B0DZGGYQ6T
            "/gp/product/([A-Z0-9]{10})",   // /gp/product/B0DZGGYQ6T
            "/product/([A-Z0-9]{10})",      // /product/B0DZGGYQ6T
            "ASIN=([A-Z0-9]{10})",          // ASIN=B0DZGGYQ6T
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               let match = regex.firstMatch(in: finalURL, options: [], range: NSRange(location: 0, length: finalURL.utf16.count)),
               let range = Range(match.range(at: 1), in: finalURL) {
                let asin = String(finalURL[range])
                print("🔍 ASIN extrait: \(asin) depuis \(finalURL)")
                return asin
            }
        }

        print("❌ Impossible d'extraire l'ASIN depuis: \(finalURL)")
        return nil
    }

    /// Suit toutes les redirections d'une URL raccourcie pour obtenir l'URL complète
    /// ❓ POURQUOI: Amazon peut avoir plusieurs redirections en chaîne (amzn.eu -> amzn.eu -> amazon.fr)
    private func followRedirect(url: String) async -> String? {
        guard let urlObject = URL(string: url) else { return nil }

        // Configuration pour suivre automatiquement TOUTES les redirections
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)

        var request = URLRequest(url: urlObject)
        request.httpMethod = "GET"  // GET au lieu de HEAD pour forcer le suivi complet des redirections
        request.timeoutInterval = 10

        // ✅ User-Agent pour éviter d'être bloqué
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")

        do {
            let (_, response) = try await session.data(for: request)

            // URLSession suit automatiquement les redirections
            // On récupère l'URL finale après toutes les redirections
            if let finalURL = response.url?.absoluteString {
                print("🔗 URL finale après redirections: \(finalURL)")
                return finalURL
            }

            return nil
        } catch {
            print("❌ Erreur lors du suivi de redirection: \(error)")
            return nil
        }
    }

    // MARK: - Private Methods

    /// Crée le body JSON de la requête API
    private func createRequestBody(asin: String) -> String {
        return """
        {
            "ItemIds": ["\(asin)"],
            "PartnerTag": "\(partnerTag)",
            "PartnerType": "Associates",
            "Marketplace": "www.amazon.fr",
            "Resources": [
                "Images.Primary.Large",
                "ItemInfo.Title",
                "Offers.Listings.Price"
            ]
        }
        """
    }

    /// Génère la signature AWS v4 pour authentifier la requête
    private func generateAWSSignature(method: String, uri: String, headers: [String: String], payload: String, timestamp: String) -> String {
        // ❓ POURQUOI: Amazon nécessite une signature cryptographique pour sécuriser les appels API
        // Cette signature prouve que vous possédez les clés secrètes sans les transmettre

        let date = String(timestamp.prefix(8)) // Format: YYYYMMDD
        let credentialScope = "\(date)/\(region)/ProductAdvertisingAPI/aws4_request"

        // Canonical request
        let sortedHeaders = headers.sorted { $0.key < $1.key }
        let canonicalHeaders = sortedHeaders.map { "\($0.key):\($0.value)" }.joined(separator: "\n")
        let signedHeaders = sortedHeaders.map { $0.key }.joined(separator: ";")
        let payloadHash = SHA256.hash(data: payload.data(using: .utf8)!).hexString

        let canonicalRequest = """
        \(method)
        \(uri)

        \(canonicalHeaders)

        \(signedHeaders)
        \(payloadHash)
        """

        // String to sign
        let canonicalRequestHash = SHA256.hash(data: canonicalRequest.data(using: .utf8)!).hexString
        let stringToSign = """
        AWS4-HMAC-SHA256
        \(timestamp)
        \(credentialScope)
        \(canonicalRequestHash)
        """

        // Signing key
        let kDate = hmacSHA256(key: "AWS4\(secretKey)".data(using: .utf8)!, data: date.data(using: .utf8)!)
        let kRegion = hmacSHA256(key: kDate, data: region.data(using: .utf8)!)
        let kService = hmacSHA256(key: kRegion, data: "ProductAdvertisingAPI".data(using: .utf8)!)
        let kSigning = hmacSHA256(key: kService, data: "aws4_request".data(using: .utf8)!)

        // Signature
        let signature = hmacSHA256(key: kSigning, data: stringToSign.data(using: .utf8)!).hexString

        // Authorization header
        return "AWS4-HMAC-SHA256 Credential=\(accessKey)/\(credentialScope), SignedHeaders=\(signedHeaders), Signature=\(signature)"
    }

    /// Helper HMAC-SHA256
    private func hmacSHA256(key: Data, data: Data) -> Data {
        let symmetricKey = SymmetricKey(data: key)
        let signature = HMAC<SHA256>.authenticationCode(for: data, using: symmetricKey)
        return Data(signature)
    }

    /// Parse la réponse JSON de l'API Amazon
    private func parseResponse(data: Data) throws -> AmazonProductInfo {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let itemsResult = json["ItemsResult"] as? [String: Any],
              let items = itemsResult["Items"] as? [[String: Any]],
              let item = items.first else {
            print("❌ Format de réponse Amazon invalide")
            throw AmazonAPIError.invalidResponse
        }

        var productInfo = AmazonProductInfo()

        // Titre
        if let itemInfo = item["ItemInfo"] as? [String: Any],
           let title = itemInfo["Title"] as? [String: Any],
           let displayValue = title["DisplayValue"] as? String {
            productInfo.title = displayValue
        }

        // Prix
        if let offers = item["Offers"] as? [String: Any],
           let listings = offers["Listings"] as? [[String: Any]],
           let firstListing = listings.first,
           let price = firstListing["Price"] as? [String: Any],
           let amount = price["Amount"] as? Double {
            productInfo.price = amount
        }

        // Image
        if let images = item["Images"] as? [String: Any],
           let primary = images["Primary"] as? [String: Any],
           let large = primary["Large"] as? [String: Any],
           let url = large["URL"] as? String {
            productInfo.imageURL = url
        }

        return productInfo
    }
}

// MARK: - Models

/// Informations d'un produit Amazon
struct AmazonProductInfo {
    var title: String?
    var price: Double?
    var imageURL: String?
}

/// Erreurs de l'API Amazon
enum AmazonAPIError: Error {
    case invalidResponse
    case httpError(Int)
    case missingASIN
}

// MARK: - Extensions

extension Digest {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}

extension Data {
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
