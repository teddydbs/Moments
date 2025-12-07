//
//  Contact.swift
//  Moments
//
//  Modèle représentant un contact (ami/famille)
//  Utilisé pour suivre les anniversaires et wishlists des autres
//  Architecture: Model (SwiftData)
//

import Foundation
import SwiftData

/// Représente une personne (ami, famille) dont on veut suivre l'anniversaire
@Model
class Contact {
    // MARK: - Properties

    /// Identifiant unique
    var id: UUID

    /// Prénom du contact
    var firstName: String

    /// Nom du contact
    var lastName: String

    /// Date de naissance (OBLIGATOIRE pour les anniversaires)
    var birthDate: Date

    /// Photo du contact (optionnel)
    var photo: Data?

    /// Email du contact (optionnel)
    var email: String?

    /// Numéro de téléphone (optionnel)
    var phoneNumber: String?

    /// Notes personnelles sur le contact
    var notes: String?

    /// Date de création
    var createdAt: Date

    /// Dernière mise à jour
    var updatedAt: Date

    // MARK: - Relationships

    /// ✅ RELATION: Wishlist du contact (ce qu'il/elle veut comme cadeaux)
    /// On pourra voir cette wishlist pour savoir quoi lui offrir
    @Relationship(deleteRule: .cascade, inverse: \WishlistItem.contact)
    var wishlistItems: [WishlistItem]?

    // MARK: - Computed Properties

    /// Nom complet
    var fullName: String {
        "\(firstName) \(lastName)"
    }

    /// Initiales
    var initials: String {
        let first = firstName.prefix(1).uppercased()
        let last = lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }

    /// Âge actuel
    var age: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year ?? 0
    }

    /// Prochain anniversaire (date complète)
    var nextBirthday: Date {
        let calendar = Calendar.current
        let now = Date()

        // Composants de la date de naissance
        let birthComponents = calendar.dateComponents([.month, .day], from: birthDate)

        // Année actuelle
        var nextBirthdayComponents = DateComponents()
        nextBirthdayComponents.month = birthComponents.month
        nextBirthdayComponents.day = birthComponents.day
        nextBirthdayComponents.year = calendar.component(.year, from: now)

        guard let birthdayThisYear = calendar.date(from: nextBirthdayComponents) else {
            return birthDate
        }

        // Si l'anniversaire de cette année est déjà passé, prendre l'année suivante
        if birthdayThisYear < now {
            nextBirthdayComponents.year = (nextBirthdayComponents.year ?? 0) + 1
            return calendar.date(from: nextBirthdayComponents) ?? birthDate
        }

        return birthdayThisYear
    }

    /// Jours restants jusqu'au prochain anniversaire
    var daysUntilBirthday: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: nextBirthday)
        return components.day ?? 0
    }

    /// Est-ce que l'anniversaire est aujourd'hui ?
    var isBirthdayToday: Bool {
        Calendar.current.isDateInToday(nextBirthday)
    }

    /// Est-ce que l'anniversaire est cette semaine ?
    var isBirthdayThisWeek: Bool {
        daysUntilBirthday <= 7
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        firstName: String,
        lastName: String,
        birthDate: Date,
        photo: Data? = nil,
        email: String? = nil,
        phoneNumber: String? = nil,
        notes: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.birthDate = birthDate
        self.photo = photo
        self.email = email
        self.phoneNumber = phoneNumber
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Preview Helper

extension Contact {
    /// Contact de preview pour les tests
    static var preview: Contact {
        Contact(
            firstName: "Marie",
            lastName: "Dupont",
            birthDate: Calendar.current.date(from: DateComponents(year: 1998, month: 3, day: 20))!,
            email: "marie.dupont@example.com",
            phoneNumber: "+33 6 98 76 54 32",
            notes: "Meilleure amie depuis le lycée"
        )
    }

    /// Contact avec anniversaire aujourd'hui
    static var birthdayToday: Contact {
        let calendar = Calendar.current
        let today = Date()
        let month = calendar.component(.month, from: today)
        let day = calendar.component(.day, from: today)

        return Contact(
            firstName: "Sophie",
            lastName: "Martin",
            birthDate: calendar.date(from: DateComponents(year: 1995, month: month, day: day))!
        )
    }

    /// Contact avec anniversaire dans 3 jours
    static var birthdayInThreeDays: Contact {
        let calendar = Calendar.current
        guard let futureDate = calendar.date(byAdding: .day, value: 3, to: Date()) else {
            return preview
        }

        let month = calendar.component(.month, from: futureDate)
        let day = calendar.component(.day, from: futureDate)

        return Contact(
            firstName: "Thomas",
            lastName: "Bernard",
            birthDate: calendar.date(from: DateComponents(year: 1992, month: month, day: day))!
        )
    }
}
