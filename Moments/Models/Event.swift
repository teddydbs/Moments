//
//  Event.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import Foundation
import SwiftData

@Model
final class Event {
    var id: UUID
    var title: String
    var date: Date
    var category: EventCategory
    var isRecurring: Bool
    var notes: String
    var notificationIdentifier: String?
    @Attribute(.externalStorage) var imageData: Data?

    // Nouvelles propriétés pour les événements
    var hasGiftPool: Bool // Cagnotte activée ou non
    @Relationship(deleteRule: .cascade) var participants: [Participant]
    @Relationship(deleteRule: .cascade) var giftIdeas: [GiftIdea]

    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        category: EventCategory,
        isRecurring: Bool = false,
        notes: String = "",
        notificationIdentifier: String? = nil,
        imageData: Data? = nil,
        hasGiftPool: Bool = false,
        participants: [Participant] = [],
        giftIdeas: [GiftIdea] = []
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.category = category
        self.isRecurring = isRecurring
        self.notes = notes
        self.notificationIdentifier = notificationIdentifier
        self.imageData = imageData
        self.hasGiftPool = hasGiftPool
        self.participants = participants
        self.giftIdeas = giftIdeas
    }
}

enum EventCategory: String, Codable, CaseIterable {
    case birthday = "Anniversaire"
    case wedding = "Mariage"
    case barMitzvah = "Bar/Bat Mitsva"
    case bachelorParty = "EVG"
    case bacheloretteParty = "EVJF"
    case party = "Soirée/Fête"
    case other = "Autre"

    var icon: String {
        switch self {
        case .birthday:
            return "🎂"
        case .wedding:
            return "💍"
        case .barMitzvah:
            return "✡️"
        case .bachelorParty:
            return "🍻"
        case .bacheloretteParty:
            return "🥂"
        case .party:
            return "🎉"
        case .other:
            return "📅"
        }
    }

    var color: String {
        switch self {
        case .birthday:
            return "pink"
        case .wedding:
            return "purple"
        case .barMitzvah:
            return "blue"
        case .bachelorParty:
            return "orange"
        case .bacheloretteParty:
            return "mint"
        case .party:
            return "yellow"
        case .other:
            return "gray"
        }
    }
}
