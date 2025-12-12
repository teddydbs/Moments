//
//  RemoteModels.swift
//  Moments
//
//  Description: Modèles Remote pour la synchronisation avec Supabase
//  Architecture: Model (Remote layer)
//
//  Ces structures représentent les données telles qu'elles sont stockées dans Supabase.
//  Elles seront converties vers/depuis les modèles SwiftData locaux lors de la sync.
//

import Foundation
import Supabase

// MARK: - Remote MyEvent

/// Événement tel qu'il est stocké dans Supabase (table: my_events)
struct RemoteMyEvent: Codable {
    let id: UUID
    let ownerId: UUID?

    // Informations de base
    let type: String
    let title: String
    let eventDescription: String?

    // Date et heure
    let date: String  // Format: "YYYY-MM-DD"
    let time: String? // Format: "HH:MM:SS"

    // Lieu
    let location: String?
    let locationAddress: String?

    // Photos (URLs vers Storage)
    let coverPhotoUrl: String?
    let profilePhotoUrl: String?

    // Configuration
    let maxGuests: Int?
    let rsvpDeadline: String? // Format: "YYYY-MM-DD"

    // Métadonnées
    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case ownerId = "owner_id"
        case type
        case title
        case eventDescription = "event_description"
        case date
        case time
        case location
        case locationAddress = "location_address"
        case coverPhotoUrl = "cover_photo_url"
        case profilePhotoUrl = "profile_photo_url"
        case maxGuests = "max_guests"
        case rsvpDeadline = "rsvp_deadline"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Remote Invitation

/// Invitation telle qu'elle est stockée dans Supabase (table: invitations)
struct RemoteInvitation: Codable {
    let id: UUID
    let myEventId: UUID

    // Informations de l'invité
    let guestName: String
    let guestEmail: String?
    let guestPhoneNumber: String?

    // Statut de l'invitation
    let status: String // 'pending', 'accepted', 'declined', 'waitingApproval'
    let plusOnes: Int

    // Dates
    let sentAt: String?
    let respondedAt: String?

    let createdAt: String
    let updatedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case myEventId = "my_event_id"
        case guestName = "guest_name"
        case guestEmail = "guest_email"
        case guestPhoneNumber = "guest_phone_number"
        case status
        case plusOnes = "plus_ones"
        case sentAt = "sent_at"
        case respondedAt = "responded_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Remote WishlistItem

/// ⚠️ DÉPLACÉ: RemoteWishlistItem est maintenant dans Models/Remote/RemoteWishlistItem.swift
/// Cette structure a été refactorisée pour être synchronisée avec la vraie table Supabase
/// qui utilise des catégories (Mode, Tech, etc.) et des statuts (Souhaité, Réservé, etc.)

// MARK: - Remote EventPhoto

/// Photo d'événement telle qu'elle est stockée dans Supabase (table: event_photos)
struct RemoteEventPhoto: Codable {
    let id: UUID
    let myEventId: UUID

    // URL de l'image (dans Supabase Storage)
    let imageUrl: String

    // Métadonnées
    let caption: String?
    let uploadedBy: String?
    let displayOrder: Int

    let createdAt: String
    let uploadedAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case myEventId = "my_event_id"
        case imageUrl = "image_url"
        case caption
        case uploadedBy = "uploaded_by"
        case displayOrder = "display_order"
        case createdAt = "created_at"
        case uploadedAt = "uploaded_at"
    }
}

// MARK: - Conversion Extensions

// Ces extensions permettent de convertir entre les modèles SwiftData locaux et les modèles Remote Supabase

extension RemoteMyEvent {
    /// Convertir un MyEvent local en RemoteMyEvent pour Supabase
    init(from localEvent: MyEvent, ownerId: UUID?) {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"

        self.id = localEvent.id
        self.ownerId = ownerId
        self.type = localEvent.type.rawValue // Convert enum to String
        self.title = localEvent.title
        self.eventDescription = localEvent.eventDescription
        self.date = dateFormatter.string(from: localEvent.date)
        self.time = localEvent.time.map { timeFormatter.string(from: $0) }
        self.location = localEvent.location
        self.locationAddress = localEvent.locationAddress
        self.coverPhotoUrl = nil // TODO: Upload vers Storage
        self.profilePhotoUrl = nil // TODO: Upload vers Storage
        self.maxGuests = localEvent.maxGuests
        self.rsvpDeadline = localEvent.rsvpDeadline.map { dateFormatter.string(from: $0) }
        self.createdAt = ISO8601DateFormatter().string(from: Date())
        self.updatedAt = ISO8601DateFormatter().string(from: Date())
    }

    /// Convertir en dictionnaire pour insertion Supabase
    func toDictionary() -> [String: AnyJSON] {
        var dict: [String: AnyJSON] = [
            "id": .string(id.uuidString),
            "type": .string(type),
            "title": .string(title),
            "date": .string(date)
        ]

        if let ownerId = ownerId {
            dict["owner_id"] = .string(ownerId.uuidString)
        }
        if let eventDescription = eventDescription {
            dict["event_description"] = .string(eventDescription)
        }
        if let time = time {
            dict["time"] = .string(time)
        }
        if let location = location {
            dict["location"] = .string(location)
        }
        if let locationAddress = locationAddress {
            dict["location_address"] = .string(locationAddress)
        }
        if let coverPhotoUrl = coverPhotoUrl {
            dict["cover_photo_url"] = .string(coverPhotoUrl)
        }
        if let profilePhotoUrl = profilePhotoUrl {
            dict["profile_photo_url"] = .string(profilePhotoUrl)
        }
        if let maxGuests = maxGuests {
            dict["max_guests"] = .integer(maxGuests)
        }
        if let rsvpDeadline = rsvpDeadline {
            dict["rsvp_deadline"] = .string(rsvpDeadline)
        }

        return dict
    }
}

extension RemoteInvitation {
    /// Convertir une Invitation locale en RemoteInvitation pour Supabase
    init(from localInvitation: Invitation) {
        let dateFormatter = ISO8601DateFormatter()

        self.id = localInvitation.id
        self.myEventId = localInvitation.myEvent?.id ?? UUID()
        self.guestName = localInvitation.guestName
        self.guestEmail = localInvitation.guestEmail
        self.guestPhoneNumber = localInvitation.guestPhoneNumber
        self.status = localInvitation.status.rawValue // Convert enum to String
        self.plusOnes = localInvitation.plusOnes
        self.sentAt = dateFormatter.string(from: localInvitation.sentAt) // sentAt is not optional
        self.respondedAt = localInvitation.respondedAt.map { dateFormatter.string(from: $0) }
        self.createdAt = dateFormatter.string(from: Date())
        self.updatedAt = dateFormatter.string(from: Date())
    }

    /// Convertir en dictionnaire pour insertion Supabase
    func toDictionary() -> [String: AnyJSON] {
        var dict: [String: AnyJSON] = [
            "id": .string(id.uuidString),
            "my_event_id": .string(myEventId.uuidString),
            "guest_name": .string(guestName),
            "status": .string(status),
            "plus_ones": .integer(plusOnes)
        ]

        if let guestEmail = guestEmail {
            dict["guest_email"] = .string(guestEmail)
        }
        if let guestPhoneNumber = guestPhoneNumber {
            dict["guest_phone_number"] = .string(guestPhoneNumber)
        }
        if let sentAt = sentAt {
            dict["sent_at"] = .string(sentAt)
        }
        if let respondedAt = respondedAt {
            dict["responded_at"] = .string(respondedAt)
        }

        return dict
    }
}

/// ⚠️ OBSOLÈTE: Les extensions RemoteWishlistItem sont maintenant dans
/// Models/Remote/RemoteWishlistItem.swift avec le nouveau schéma

extension RemoteEventPhoto {
    /// Convertir une EventPhoto locale en RemoteEventPhoto pour Supabase
    init(from localPhoto: EventPhoto, imageUrl: String) {
        let dateFormatter = ISO8601DateFormatter()

        self.id = localPhoto.id
        self.myEventId = localPhoto.myEvent?.id ?? UUID()
        self.imageUrl = imageUrl
        self.caption = localPhoto.caption
        self.uploadedBy = localPhoto.uploadedBy
        self.displayOrder = localPhoto.displayOrder
        self.createdAt = dateFormatter.string(from: localPhoto.uploadedAt)
        self.uploadedAt = dateFormatter.string(from: localPhoto.uploadedAt)
    }

    /// Convertir en dictionnaire pour insertion Supabase
    func toDictionary() -> [String: AnyJSON] {
        var dict: [String: AnyJSON] = [
            "id": .string(id.uuidString),
            "my_event_id": .string(myEventId.uuidString),
            "image_url": .string(imageUrl),
            "display_order": .integer(displayOrder)
        ]

        if let caption = caption {
            dict["caption"] = .string(caption)
        }
        if let uploadedBy = uploadedBy {
            dict["uploaded_by"] = .string(uploadedBy)
        }

        return dict
    }
}


// MARK: - RemoteUserProfile

/// Modèle pour synchroniser le profil utilisateur avec Supabase
struct RemoteUserProfile: Codable {
    let id: UUID
    let firstName: String?
    let lastName: String?
    let birthDate: String? // ISO8601 date format (YYYY-MM-DD)
    let phoneNumber: String?
    let profilePhotoUrl: String?
    let addressStreet: String?
    let addressCity: String?
    let addressPostalCode: String?
    let addressCountry: String?
    let notificationEnabled: Bool?
    let themePreference: String?
    let onboardingCompleted: Bool?
    let onboardingStep: Int?
    let createdAt: String? // ISO8601
    let updatedAt: String? // ISO8601

    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case birthDate = "birth_date"
        case phoneNumber = "phone_number"
        case profilePhotoUrl = "profile_photo_url"
        case addressStreet = "address_street"
        case addressCity = "address_city"
        case addressPostalCode = "address_postal_code"
        case addressCountry = "address_country"
        case notificationEnabled = "notification_enabled"
        case themePreference = "theme_preference"
        case onboardingCompleted = "onboarding_completed"
        case onboardingStep = "onboarding_step"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Initialiser depuis le modèle local UserProfile
    init(from localProfile: UserProfile) {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        let timestampFormatter = ISO8601DateFormatter()

        self.id = localProfile.id
        self.firstName = localProfile.firstName.isEmpty ? nil : localProfile.firstName
        self.lastName = localProfile.lastName.isEmpty ? nil : localProfile.lastName
        self.birthDate = localProfile.birthDate.map { dateFormatter.string(from: $0) }
        self.phoneNumber = localProfile.phoneNumber
        self.profilePhotoUrl = localProfile.profilePhotoUrl
        self.addressStreet = localProfile.addressStreet
        self.addressCity = localProfile.addressCity
        self.addressPostalCode = localProfile.addressPostalCode
        self.addressCountry = localProfile.addressCountry
        self.notificationEnabled = localProfile.notificationEnabled
        self.themePreference = localProfile.themePreference
        self.onboardingCompleted = localProfile.onboardingCompleted
        self.onboardingStep = localProfile.onboardingStep
        self.createdAt = timestampFormatter.string(from: localProfile.createdAt)
        self.updatedAt = timestampFormatter.string(from: localProfile.updatedAt)
    }

    /// Convertir vers le modèle local UserProfile
    func toLocal(photoData: Data? = nil) -> UserProfile {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        let timestampFormatter = ISO8601DateFormatter()

        let parsedBirthDate: Date? = {
            guard let birthDate = birthDate else { return nil }
            return dateFormatter.date(from: birthDate)
        }()

        let parsedCreatedAt: Date = {
            guard let createdAt = createdAt else { return Date() }
            return timestampFormatter.date(from: createdAt) ?? Date()
        }()

        let parsedUpdatedAt: Date = {
            guard let updatedAt = updatedAt else { return Date() }
            return timestampFormatter.date(from: updatedAt) ?? Date()
        }()

        return UserProfile(
            id: id,
            firstName: firstName ?? "",
            lastName: lastName ?? "",
            birthDate: parsedBirthDate,
            phoneNumber: phoneNumber,
            profilePhotoUrl: profilePhotoUrl,
            profilePhotoData: photoData,
            addressStreet: addressStreet,
            addressCity: addressCity,
            addressPostalCode: addressPostalCode,
            addressCountry: addressCountry,
            notificationEnabled: notificationEnabled ?? true,
            themePreference: themePreference ?? "auto",
            onboardingCompleted: onboardingCompleted ?? false,
            onboardingStep: onboardingStep ?? 0,
            createdAt: parsedCreatedAt,
            updatedAt: parsedUpdatedAt
        )
    }

    /// Convertir en dictionnaire pour insertion/update Supabase
    func toDictionary() -> [String: AnyJSON] {
        var dict: [String: AnyJSON] = [
            "id": .string(id.uuidString),
            "notification_enabled": .bool(notificationEnabled ?? true),
            "theme_preference": .string(themePreference ?? "auto"),
            "onboarding_completed": .bool(onboardingCompleted ?? false),
            "onboarding_step": .integer(onboardingStep ?? 0)
        ]

        if let firstName = firstName {
            dict["first_name"] = .string(firstName)
        }
        if let lastName = lastName {
            dict["last_name"] = .string(lastName)
        }
        if let birthDate = birthDate {
            dict["birth_date"] = .string(birthDate)
        }
        if let phoneNumber = phoneNumber {
            dict["phone_number"] = .string(phoneNumber)
        }
        if let profilePhotoUrl = profilePhotoUrl {
            dict["profile_photo_url"] = .string(profilePhotoUrl)
        }
        if let addressStreet = addressStreet {
            dict["address_street"] = .string(addressStreet)
        }
        if let addressCity = addressCity {
            dict["address_city"] = .string(addressCity)
        }
        if let addressPostalCode = addressPostalCode {
            dict["address_postal_code"] = .string(addressPostalCode)
        }
        if let addressCountry = addressCountry {
            dict["address_country"] = .string(addressCountry)
        }

        return dict
    }
}

