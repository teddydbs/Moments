//
//  UserProfile.swift
//  Moments
//
//  Modèle pour stocker le profil utilisateur (date de naissance, photo, etc.)
//  Architecture: Model Layer avec SwiftData
//

import Foundation
import SwiftData

/// Profil utilisateur local (SwiftData)
@Model
final class UserProfile {
    // MARK: - Properties

    /// ID unique (lié à l'ID Supabase auth.users)
    @Attribute(.unique) var id: UUID

    // Informations personnelles
    var firstName: String
    var lastName: String
    var birthDate: Date?
    var phoneNumber: String?

    // Photos
    var profilePhotoUrl: String?
    @Attribute(.externalStorage) var profilePhotoData: Data? // Photo locale

    // Adresse
    var addressStreet: String?
    var addressCity: String?
    var addressPostalCode: String?
    var addressCountry: String?

    // Préférences
    var notificationEnabled: Bool
    var themePreference: String // "light", "dark", "auto"

    // Onboarding
    var onboardingCompleted: Bool
    var onboardingStep: Int

    // Timestamps
    var createdAt: Date
    var updatedAt: Date

    // MARK: - Computed Properties

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    var age: Int? {
        guard let birthDate = birthDate else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year
    }

    var daysUntilBirthday: Int {
        guard let birthDate = birthDate else { return Int.max }

        let calendar = Calendar.current
        let today = Date()

        // Extraire le jour et le mois de la date de naissance
        let birthdayComponents = calendar.dateComponents([.month, .day], from: birthDate)

        // Créer la date d'anniversaire pour cette année
        var nextBirthdayComponents = calendar.dateComponents([.year], from: today)
        nextBirthdayComponents.month = birthdayComponents.month
        nextBirthdayComponents.day = birthdayComponents.day

        guard let nextBirthday = calendar.date(from: nextBirthdayComponents) else {
            return Int.max
        }

        // Si l'anniversaire est déjà passé cette année, prendre l'année prochaine
        let finalBirthday: Date
        if nextBirthday < today {
            guard let nextYear = calendar.date(byAdding: .year, value: 1, to: nextBirthday) else {
                return Int.max
            }
            finalBirthday = nextYear
        } else {
            finalBirthday = nextBirthday
        }

        let components = calendar.dateComponents([.day], from: today, to: finalBirthday)
        return components.day ?? Int.max
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        firstName: String = "",
        lastName: String = "",
        birthDate: Date? = nil,
        phoneNumber: String? = nil,
        profilePhotoUrl: String? = nil,
        profilePhotoData: Data? = nil,
        addressStreet: String? = nil,
        addressCity: String? = nil,
        addressPostalCode: String? = nil,
        addressCountry: String? = nil,
        notificationEnabled: Bool = true,
        themePreference: String = "auto",
        onboardingCompleted: Bool = false,
        onboardingStep: Int = 0,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.birthDate = birthDate
        self.phoneNumber = phoneNumber
        self.profilePhotoUrl = profilePhotoUrl
        self.profilePhotoData = profilePhotoData
        self.addressStreet = addressStreet
        self.addressCity = addressCity
        self.addressPostalCode = addressPostalCode
        self.addressCountry = addressCountry
        self.notificationEnabled = notificationEnabled
        self.themePreference = themePreference
        self.onboardingCompleted = onboardingCompleted
        self.onboardingStep = onboardingStep
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Preview

extension UserProfile {
    static var preview: UserProfile {
        UserProfile(
            firstName: "John",
            lastName: "Doe",
            birthDate: Calendar.current.date(byAdding: .year, value: -30, to: Date()),
            phoneNumber: "+33 6 12 34 56 78",
            addressCity: "Paris",
            addressCountry: "France",
            onboardingCompleted: true
        )
    }
}
