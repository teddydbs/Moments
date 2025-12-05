//
//  SupabaseConfig.swift
//  Moments
//
//  Configuration pour Supabase
//

import Foundation

struct SupabaseConfig {
    // IMPORTANT: Remplacez ces valeurs par vos vraies valeurs Supabase
    // Vous les trouverez dans: Dashboard Supabase > Settings > API

    static let supabaseURL = URL(string: "https://ksbsvscfplmokacngouo.supabase.co")!
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtzYnN2c2NmcGxtb2thY25nb3VvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ4NzM1NDAsImV4cCI6MjA4MDQ0OTU0MH0.zbeowqtJ5yxieZ63yMXXk-Dy0OMrbVQqtPcIUIJ8fSc"

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
