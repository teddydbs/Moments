//
//  ProfileManager.swift
//  Moments
//
//  Service de gestion du profil utilisateur (synchronisation Supabase ↔ SwiftData)
//  Architecture: Service Layer
//

import Foundation
import SwiftData
import Supabase
import Combine

/// Manager pour gérer le profil utilisateur et sa synchronisation
@MainActor
class ProfileManager: ObservableObject {
    // MARK: - Properties

    @Published var currentProfile: UserProfile?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let modelContext: ModelContext
    private let supabase: SupabaseManager

    // MARK: - Initialization

    /// Initialise le ProfileManager avec un ModelContext SwiftData
    /// - Parameter modelContext: Le contexte SwiftData pour accéder aux données locales
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        self.supabase = SupabaseManager.shared
    }

    // MARK: - Public Methods

    /// Charge le profil de l'utilisateur connecté depuis Supabase
    /// Si un profil local existe déjà, il sera mis à jour
    /// Si aucun profil n'existe, il sera créé automatiquement
    func loadUserProfile() async throws {
        isLoading = true
        errorMessage = nil

        guard let session = try? await supabase.client.auth.session else {
            throw ProfileError.notAuthenticated
        }

        let userId = session.user.id

        do {
            // 1. Essayer de récupérer le profil depuis Supabase
            print("🔄 Récupération du profil depuis Supabase...")

            let profiles: [RemoteUserProfile] = try await supabase.client
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .execute()
                .value

            var remoteProfile: RemoteUserProfile

            if profiles.isEmpty {
                // ⚠️ Aucun profil trouvé, créer un profil par défaut
                print("⚠️ Aucun profil trouvé, création automatique...")

                // ✅ Helper pour extraire les valeurs AnyJSON en String
                func extractString(from json: AnyJSON?) -> String? {
                    guard let json = json else { return nil }
                    switch json {
                    case .string(let value):
                        return value
                    default:
                        return nil
                    }
                }

                // Extraire le nom depuis les métadonnées OAuth
                let metadata = session.user.userMetadata
                let firstName = extractString(from: metadata["given_name"]) ?? extractString(from: metadata["name"])?.components(separatedBy: " ").first ?? ""
                let lastName = extractString(from: metadata["family_name"]) ?? extractString(from: metadata["name"])?.components(separatedBy: " ").last ?? ""

                // Créer un nouveau profil
                let newProfile = UserProfile(
                    id: userId,
                    firstName: firstName,
                    lastName: lastName,
                    onboardingCompleted: false
                )

                // Insérer dans Supabase
                let remoteNewProfile = RemoteUserProfile(from: newProfile)
                try await supabase.client
                    .from("profiles")
                    .insert(remoteNewProfile.toDictionary())
                    .execute()

                print("✅ Profil créé automatiquement: \(firstName) \(lastName)")
                remoteProfile = remoteNewProfile
            } else {
                // ✅ Profil trouvé
                remoteProfile = profiles[0]
                print("✅ Profil récupéré: \(remoteProfile.firstName ?? "nil") \(remoteProfile.lastName ?? "nil")")

                // 🔧 Si le profil existe mais est vide, le mettre à jour avec les données OAuth
                if (remoteProfile.firstName == nil || remoteProfile.firstName == "") &&
                   (remoteProfile.lastName == nil || remoteProfile.lastName == "") {
                    print("⚠️ Profil existant mais vide, mise à jour avec OAuth...")

                    // ✅ Helper pour extraire les valeurs AnyJSON en String
                    func extractString(from json: AnyJSON?) -> String? {
                        guard let json = json else { return nil }
                        switch json {
                        case .string(let value):
                            return value
                        default:
                            return nil
                        }
                    }

                    // Extraire le nom depuis les métadonnées OAuth
                    let metadata = session.user.userMetadata
                    let firstName = extractString(from: metadata["given_name"]) ?? extractString(from: metadata["name"])?.components(separatedBy: " ").first ?? ""
                    let lastNameParts = extractString(from: metadata["name"])?.components(separatedBy: " ").dropFirst()
                    let lastName = extractString(from: metadata["family_name"]) ?? (lastNameParts?.joined(separator: " ") ?? "")

                    // Sauvegarder dans Supabase (mise à jour directe des champs)
                    try await supabase.client
                        .from("profiles")
                        .update([
                            "first_name": AnyJSON.string(firstName),
                            "last_name": AnyJSON.string(lastName)
                        ])
                        .eq("id", value: userId.uuidString)
                        .execute()

                    print("✅ Profil mis à jour avec OAuth: \(firstName) \(lastName)")

                    // Recharger le profil mis à jour
                    let updatedProfiles: [RemoteUserProfile] = try await supabase.client
                        .from("profiles")
                        .select()
                        .eq("id", value: userId.uuidString)
                        .execute()
                        .value
                    remoteProfile = updatedProfiles[0]
                }
            }

            // 2. Vérifier si un profil local existe déjà
            let descriptor = FetchDescriptor<UserProfile>(
                predicate: #Predicate { $0.id == userId }
            )

            let existingProfiles = try modelContext.fetch(descriptor)

            if let existingProfile = existingProfiles.first {
                // Mettre à jour le profil existant
                print("📝 Mise à jour du profil local existant")
                updateLocalProfile(existingProfile, with: remoteProfile)
                currentProfile = existingProfile
            } else {
                // Créer un nouveau profil local
                print("➕ Création d'un nouveau profil local")
                let newProfile = remoteProfile.toLocal()
                modelContext.insert(newProfile)
                currentProfile = newProfile
            }

            // Sauvegarder dans SwiftData
            try modelContext.save()

            isLoading = false

        } catch {
            isLoading = false
            errorMessage = "Erreur de chargement du profil: \(error.localizedDescription)"
            print("❌ Erreur loadUserProfile: \(error)")
            throw error
        }
    }

    /// Met à jour le profil utilisateur (local et distant)
    /// - Parameter profile: Le profil à mettre à jour
    func updateProfile(_ profile: UserProfile) async throws {
        isLoading = true
        errorMessage = nil

        do {
            // 1. Mettre à jour dans Supabase
            print("🔄 Mise à jour du profil sur Supabase...")

            let remoteProfile = RemoteUserProfile(from: profile)

            try await supabase.client
                .from("profiles")
                .update(remoteProfile.toDictionary())
                .eq("id", value: profile.id.uuidString)
                .execute()

            print("✅ Profil mis à jour sur Supabase")

            // 2. Mettre à jour localement
            profile.updatedAt = Date()
            try modelContext.save()

            currentProfile = profile
            isLoading = false

        } catch {
            isLoading = false
            errorMessage = "Erreur de mise à jour du profil: \(error.localizedDescription)"
            print("❌ Erreur updateProfile: \(error)")
            throw error
        }
    }

    /// Upload une photo de profil vers Supabase Storage et met à jour le profil
    /// - Parameters:
    ///   - imageData: Les données de l'image (JPEG)
    ///   - profile: Le profil à mettre à jour
    func uploadProfilePhoto(_ imageData: Data, for profile: UserProfile) async throws {
        isLoading = true
        errorMessage = nil

        do {
            // 1. Upload vers Supabase Storage
            print("🔄 Upload de la photo de profil vers Storage...")

            let fileName = "\(profile.id.uuidString)/profile.jpg"

            let imageUrl = try await supabase.uploadImage(
                imageData,
                toBucket: "profile-photos",
                fileName: fileName
            )

            print("✅ Photo uploadée: \(imageUrl)")

            // 2. Mettre à jour l'URL dans le profil
            profile.profilePhotoUrl = imageUrl
            profile.profilePhotoData = imageData // Sauvegarder localement aussi
            profile.updatedAt = Date()

            // 3. Mettre à jour sur Supabase
            try await supabase.client
                .from("profiles")
                .update(["profile_photo_url": AnyJSON.string(imageUrl)])
                .eq("id", value: profile.id.uuidString)
                .execute()

            // 4. Sauvegarder localement
            try modelContext.save()

            currentProfile = profile
            isLoading = false

        } catch {
            isLoading = false
            errorMessage = "Erreur d'upload de la photo: \(error.localizedDescription)"
            print("❌ Erreur uploadProfilePhoto: \(error)")
            throw error
        }
    }

    /// Crée un nouveau profil pour l'utilisateur connecté
    /// - Parameter profile: Le profil à créer
    func createProfile(_ profile: UserProfile) async throws {
        isLoading = true
        errorMessage = nil

        do {
            // 1. Créer dans Supabase
            print("🔄 Création du profil sur Supabase...")

            let remoteProfile = RemoteUserProfile(from: profile)

            try await supabase.client
                .from("profiles")
                .insert(remoteProfile.toDictionary())
                .execute()

            print("✅ Profil créé sur Supabase")

            // 2. Créer localement
            modelContext.insert(profile)
            try modelContext.save()

            currentProfile = profile
            isLoading = false

        } catch {
            isLoading = false
            errorMessage = "Erreur de création du profil: \(error.localizedDescription)"
            print("❌ Erreur createProfile: \(error)")
            throw error
        }
    }

    /// Récupère le profil local de l'utilisateur connecté
    /// - Returns: Le profil local s'il existe, nil sinon
    func getLocalProfile() async -> UserProfile? {
        guard let userId = try? await supabase.client.auth.session.user.id else {
            return nil
        }

        let descriptor = FetchDescriptor<UserProfile>(
            predicate: #Predicate { $0.id == userId }
        )

        do {
            let profiles = try modelContext.fetch(descriptor)
            return profiles.first
        } catch {
            print("❌ Erreur getLocalProfile: \(error)")
            return nil
        }
    }

    /// Vérifie si l'utilisateur a complété l'onboarding
    /// - Returns: true si l'onboarding est complété, false sinon
    func hasCompletedOnboarding() async -> Bool {
        // Vérifier d'abord localement
        if let localProfile = await getLocalProfile() {
            return localProfile.onboardingCompleted
        }

        // Sinon, vérifier sur Supabase
        do {
            guard let userId = try? await supabase.client.auth.session.user.id else {
                return false
            }

            let profile: RemoteUserProfile = try await supabase.client
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value

            return profile.onboardingCompleted ?? false
        } catch {
            print("❌ Erreur hasCompletedOnboarding: \(error)")
            return false
        }
    }

    /// Marque l'onboarding comme complété
    func completeOnboarding() async throws {
        guard let profile = currentProfile else {
            throw ProfileError.profileNotFound
        }

        profile.onboardingCompleted = true
        profile.onboardingStep = 0

        try await updateProfile(profile)
    }

    // MARK: - Private Methods

    /// Met à jour un profil local avec les données d'un profil distant
    /// - Parameters:
    ///   - localProfile: Le profil local à mettre à jour
    ///   - remoteProfile: Le profil distant source
    private func updateLocalProfile(_ localProfile: UserProfile, with remoteProfile: RemoteUserProfile) {
        localProfile.firstName = remoteProfile.firstName ?? ""
        localProfile.lastName = remoteProfile.lastName ?? ""

        if let birthDateString = remoteProfile.birthDate {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]
            if let birthDate = dateFormatter.date(from: birthDateString) {
                localProfile.birthDate = birthDate
            }
        }

        localProfile.phoneNumber = remoteProfile.phoneNumber
        localProfile.profilePhotoUrl = remoteProfile.profilePhotoUrl
        localProfile.addressStreet = remoteProfile.addressStreet
        localProfile.addressCity = remoteProfile.addressCity
        localProfile.addressPostalCode = remoteProfile.addressPostalCode
        localProfile.addressCountry = remoteProfile.addressCountry

        if let notificationEnabled = remoteProfile.notificationEnabled {
            localProfile.notificationEnabled = notificationEnabled
        }
        if let themePreference = remoteProfile.themePreference {
            localProfile.themePreference = themePreference
        }
        if let onboardingCompleted = remoteProfile.onboardingCompleted {
            localProfile.onboardingCompleted = onboardingCompleted
        }
        if let onboardingStep = remoteProfile.onboardingStep {
            localProfile.onboardingStep = onboardingStep
        }

        if let updatedAtString = remoteProfile.updatedAt,
           let updatedAt = ISO8601DateFormatter().date(from: updatedAtString) {
            localProfile.updatedAt = updatedAt
        }
    }
}

// MARK: - Errors

enum ProfileError: LocalizedError {
    case notAuthenticated
    case profileNotFound
    case invalidData

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Utilisateur non authentifié"
        case .profileNotFound:
            return "Profil non trouvé"
        case .invalidData:
            return "Données invalides"
        }
    }
}
