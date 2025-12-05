//
//  Participant.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import Foundation
import SwiftData

@Model
final class Participant {
    var id: UUID
    var name: String
    var phone: String?
    var email: String?
    var source: ParticipantSource
    var contactIdentifier: String? // Pour les contacts iPhone
    var socialMediaId: String? // Pour Facebook/Instagram/WhatsApp
    var event: Event?

    init(
        id: UUID = UUID(),
        name: String,
        phone: String? = nil,
        email: String? = nil,
        source: ParticipantSource = .manual,
        contactIdentifier: String? = nil,
        socialMediaId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.phone = phone
        self.email = email
        self.source = source
        self.contactIdentifier = contactIdentifier
        self.socialMediaId = socialMediaId
    }
}

enum ParticipantSource: String, Codable {
    case manual = "Manuel"
    case contacts = "Contacts"
    case facebook = "Facebook"
    case instagram = "Instagram"
    case whatsapp = "WhatsApp"

    var icon: String {
        switch self {
        case .manual:
            return "person.fill"
        case .contacts:
            return "person.crop.circle"
        case .facebook:
            return "f.circle.fill"
        case .instagram:
            return "camera.circle.fill"
        case .whatsapp:
            return "message.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .manual:
            return "blue"
        case .contacts:
            return "green"
        case .facebook:
            return "blue"
        case .instagram:
            return "purple"
        case .whatsapp:
            return "green"
        }
    }
}
