//
//  User.swift
//  Moments
//
//  Modèle représentant l'utilisateur connecté (TOI)
//  Architecture: Model (SwiftData)
//

import Foundation
import SwiftData

/// Représente l'utilisateur connecté à l'application
/// ⚠️ Il ne devrait y avoir qu'UN SEUL AppUser dans la base de données locale
/// Note: Nommé "AppUser" pour éviter le conflit avec Supabase.User
@Model
class AppUser {
    // MARK: - Properties

    /// Identifiant unique
    var id: UUID

    /// Prénom de l'utilisateur
    var firstName: String

    /// Nom de l'utilisateur
    var lastName: String

    /// Email (synchronisé avec AuthManager)
    var email: String

    /// Date de naissance (optionnel)
    var birthDate: Date?

    /// Photo de profil (stockée en base64 ou chemin local)
    var profilePhoto: Data?

    /// Numéro de téléphone (optionnel)
    var phoneNumber: String?

    /// Date de création du profil
    var createdAt: Date

    /// Dernière mise à jour
    var updatedAt: Date

    // MARK: - Computed Properties

    /// Nom complet
    var fullName: String {
        "\(firstName) \(lastName)"
    }

    /// Âge calculé à partir de la date de naissance
    var age: Int? {
        guard let birthDate = birthDate else { return nil }

        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        email: String,
        birthDate: Date? = nil,
        profilePhoto: Data? = nil,
        phoneNumber: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.birthDate = birthDate
        self.profilePhoto = profilePhoto
        self.phoneNumber = phoneNumber
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Preview Helper

extension AppUser {
    /// Utilisateur de preview pour les tests
    static var preview: AppUser {
        AppUser(
            firstName: "Teddy",
            lastName: "Dubois",
            email: "teddy@moments.app",
            birthDate: Calendar.current.date(from: DateComponents(year: 1995, month: 6, day: 15)),
            phoneNumber: "+33 6 12 34 56 78"
        )
    }
}
