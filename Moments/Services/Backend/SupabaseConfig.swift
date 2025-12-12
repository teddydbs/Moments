//
//  SupabaseConfig.swift
//  Moments
//
//  Configuration pour Supabase
//  ✅ Lecture sécurisée des clés depuis Info.plist (alimenté par .xcconfig)
//

import Foundation

struct SupabaseConfig {
    // ✅ Lecture sécurisée des credentials depuis Info.plist
    // Les valeurs sont définies dans Debug.xcconfig / Release.xcconfig
    // et ne sont JAMAIS committées sur Git

    static var supabaseURL: URL {
        guard let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let url = URL(string: urlString) else {
            fatalError("❌ SUPABASE_URL manquante dans Info.plist. Vérifier Debug.xcconfig / Release.xcconfig")
        }
        return url
    }

    static var supabaseAnonKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String else {
            fatalError("❌ SUPABASE_ANON_KEY manquante dans Info.plist. Vérifier Debug.xcconfig / Release.xcconfig")
        }
        return key
    }

    // Configuration pour les Edge Functions
    struct EdgeFunctions {
        static let affiliateConvert = "affiliate-convert"
        static let stripeWebhook = "stripe-webhook"
        static let eventsShare = "events-share"
    }

    // Configuration pour le stockage
    struct Storage {
        static let eventImages = "event-images"
        static let avatars = "avatars"
    }
}
