//
//  SupabaseQuickTest.swift
//  Moments
//
//  Test rapide de connexion Supabase
//

import Foundation
import Combine
import Supabase

/// Service simple pour tester la connexion Supabase
@MainActor
class SupabaseQuickTest: ObservableObject {
    static let shared = SupabaseQuickTest()

    let client: SupabaseClient

    @Published var isConnected = false
    @Published var testMessage = "Non testé"

    private init() {
        // ✅ Initialiser le client Supabase
        self.client = SupabaseClient(
            supabaseURL: SupabaseConfig.supabaseURL,
            supabaseKey: SupabaseConfig.supabaseAnonKey
        )

        print("🟢 Supabase client initialisé")
        print("📍 URL: \(SupabaseConfig.supabaseURL)")
    }

    /// Test de connexion simple
    func testConnection() async {
        print("\n🧪 === TEST DE CONNEXION SUPABASE ===")

        do {
            // ✅ Test 1: Vérifier que la base de données répond
            print("📡 Test 1: Connexion à la base de données...")

            // Simple requête pour vérifier la connexion
            let _: [EmptyResponse] = try await client
                .from("my_events")
                .select()
                .limit(1)
                .execute()
                .value

            print("✅ Connexion réussie à la base de données !")

            // ✅ Test 2: Vérifier l'auth
            print("🔐 Test 2: Vérification de l'authentification...")

            do {
                let session = try await client.auth.session
                print("✅ Session active: \(session.user.email ?? "Pas d'email")")
                testMessage = "✅ Connecté - User: \(session.user.email ?? "Anonyme")"
            } catch {
                print("ℹ️ Pas de session active (normal si pas encore connecté)")
                testMessage = "✅ Base de données accessible - Pas encore connecté"
            }

            isConnected = true

            print("\n🎉 Tous les tests passés !")
            print("👉 Tu peux maintenant voir ton projet sur:")
            print("   \(SupabaseConfig.supabaseURL)/project/default")

        } catch {
            print("❌ Erreur de connexion: \(error)")
            testMessage = "❌ Erreur: \(error.localizedDescription)"
            isConnected = false
        }
    }

    /// Créer un événement de test
    func createTestEvent() async throws {
        print("\n📝 Création d'un événement de test...")

        // ⚠️ Important: Il faut d'abord s'authentifier
        // Pour l'instant, on va juste tester l'insertion

        let testEvent: [String: AnyJSON] = [
            "type": .string("birthday"),
            "title": .string("Test depuis iOS"),
            "date": .string("2025-12-25"),
            "owner_id": .string(UUID().uuidString)
        ]

        let response: MyEventRemote = try await client
            .from("my_events")
            .insert(testEvent)
            .select()
            .single()
            .execute()
            .value

        print("✅ Événement créé avec succès!")
        print("   ID: \(response.id)")
        print("   Titre: \(response.title)")
        print("\n👉 Vérifie dans Supabase Dashboard → Table Editor → my_events")
    }
}

// MARK: - Modèles temporaires pour les tests

struct EmptyResponse: Codable {}

struct MyEventRemote: Codable {
    let id: UUID
    let type: String
    let title: String
    let date: String

    enum CodingKeys: String, CodingKey {
        case id, type, title, date
    }
}
