//
//  ScraperAPIManager.swift
//  Moments
//
//  Description: Gestionnaire pour ScraperAPI - Service de scraping avec JavaScript
//  Architecture: Service
//

import Foundation

/// Gestionnaire pour ScraperAPI
/// ✅ Permet de scraper des pages web avec JavaScript (résout le problème Amazon)
class ScraperAPIManager {

    // MARK: - Properties

    /// Clé API ScraperAPI (5000 crédits gratuits au signup)
    /// 🔗 Obtenir une clé : https://www.scraperapi.com
    private let apiKey = "fb3761d9267609bc0ceb3872a35ac289"

    /// Endpoint de base ScraperAPI
    private let baseURL = "https://api.scraperapi.com"

    // MARK: - Singleton

    static let shared = ScraperAPIManager()

    private init() {}

    // MARK: - Public Methods

    /// Récupère le HTML complet d'une URL avec JavaScript exécuté
    /// ✅ Parfait pour Amazon qui charge les prix dynamiquement
    /// - Parameter url: URL à scraper
    /// - Returns: HTML complet avec JavaScript exécuté
    func fetchHTML(from url: String) async throws -> String {
        // ✅ ÉTAPE 1: Construire l'URL de ScraperAPI
        guard let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw ScraperAPIError.invalidURL
        }

        // ScraperAPI format: https://api.scraperapi.com?api_key=YOUR_KEY&url=TARGET_URL&render=true
        let scraperURL = "\(baseURL)?api_key=\(apiKey)&url=\(encodedURL)&render=true&country_code=fr"

        print("🌐 ScraperAPI: Requête vers \(url)")

        guard let requestURL = URL(string: scraperURL) else {
            throw ScraperAPIError.invalidURL
        }

        // ✅ ÉTAPE 2: Faire la requête HTTP
        var request = URLRequest(url: requestURL)
        request.timeoutInterval = 60  // ScraperAPI peut prendre du temps (JavaScript rendering + images lazy-load)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ScraperAPIError.invalidResponse
        }

        print("📡 ScraperAPI: Status \(httpResponse.statusCode)")

        // ✅ ÉTAPE 3: Vérifier le statut
        guard httpResponse.statusCode == 200 else {
            if let errorMessage = String(data: data, encoding: .utf8) {
                print("❌ ScraperAPI Error: \(errorMessage)")
            }
            throw ScraperAPIError.httpError(httpResponse.statusCode)
        }

        // ✅ ÉTAPE 4: Retourner le HTML
        guard let html = String(data: data, encoding: .utf8) else {
            throw ScraperAPIError.invalidEncoding
        }

        print("✅ ScraperAPI: HTML récupéré (\(html.count) caractères)")
        return html
    }

    /// Vérifie si ScraperAPI est configuré (clé API renseignée)
    var isConfigured: Bool {
        return apiKey != "VOTRE_CLE_API_ICI" && !apiKey.isEmpty
    }
}

// MARK: - Errors

enum ScraperAPIError: Error {
    case invalidURL
    case invalidResponse
    case invalidEncoding
    case httpError(Int)
    case notConfigured
}
