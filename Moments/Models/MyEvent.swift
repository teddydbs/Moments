//
//  MyEvent.swift
//  Moments
//
//  Modèle représentant UN de TES événements (anniversaire, mariage, etc.)
//  C'est TOI qui organises et invites des gens
//  Architecture: Model (SwiftData)
//

import Foundation
import SwiftData

/// Type d'événement
enum MyEventType: String, Codable, CaseIterable {
    case birthday = "Mon anniversaire"
    case wedding = "Mon mariage"
    case babyShower = "Baby shower"
    case bachelorParty = "EVG/EVJF"
    case houseWarming = "Pendaison de crémaillère"
    case graduation = "Diplôme"
    case christmas = "Noël"
    case newYear = "Nouvel An"
    case other = "Autre"

    var icon: String {
        switch self {
        case .birthday: return "gift.fill"
        case .wedding: return "heart.circle.fill"
        case .babyShower: return "figure.and.child.holdinghands"
        case .bachelorParty: return "party.popper.fill"
        case .houseWarming: return "house.fill"
        case .graduation: return "graduationcap.fill"
        case .christmas: return "tree.fill"
        case .newYear: return "sparkles"
        case .other: return "star.fill"
        }
    }
}

/// Représente un événement que TU organises
@Model
class MyEvent {
    // MARK: - Properties

    /// Identifiant unique
    var id: UUID

    /// Type d'événement
    var type: MyEventType

    /// Titre personnalisé (ex: "Mes 30 ans", "Mariage de Teddy & Marie")
    var title: String

    /// Description de l'événement (renommé pour éviter le conflit avec description de NSObject)
    var eventDescription: String?

    /// Date de l'événement
    var date: Date

    /// Heure de l'événement (optionnel)
    var time: Date?

    /// Nom du lieu (ex: "Chez moi", "Restaurant Le Bouquet")
    var location: String?

    /// Adresse complète
    var locationAddress: String?

    /// Photo de couverture de l'événement (bannière en haut)
    var coverPhoto: Data?

    /// Photo de profil de l'événement (icône circulaire)
    var profilePhoto: Data?

    /// Nombre maximum d'invités (optionnel, pour gérer la capacité)
    var maxGuests: Int?

    /// Date limite pour confirmer la présence
    var rsvpDeadline: Date?

    /// Date de création
    var createdAt: Date

    /// Dernière mise à jour
    var updatedAt: Date

    // MARK: - Relationships

    /// ✅ RELATION: Invitations envoyées pour cet événement
    @Relationship(deleteRule: .cascade, inverse: \Invitation.myEvent)
    var invitations: [Invitation]?

    /// ✅ RELATION: Ta wishlist pour cet événement (ce que TU veux recevoir)
    @Relationship(deleteRule: .cascade, inverse: \WishlistItem.myEvent)
    var wishlistItems: [WishlistItem]?

    /// ✅ RELATION: Photos de l'événement (album partagé)
    @Relationship(deleteRule: .cascade)
    var eventPhotos: [EventPhoto]?

    // MARK: - Computed Properties

    /// Nombre total d'invités
    var totalInvitations: Int {
        invitations?.count ?? 0
    }

    /// Nombre d'invités qui ont accepté
    var acceptedCount: Int {
        invitations?.filter { $0.status == .accepted }.count ?? 0
    }

    /// Nombre d'invités qui ont refusé
    var declinedCount: Int {
        invitations?.filter { $0.status == .declined }.count ?? 0
    }

    /// Nombre d'invités en attente de réponse
    var pendingCount: Int {
        invitations?.filter { $0.status == .pending }.count ?? 0
    }

    /// Jours restants jusqu'à l'événement
    var daysUntilEvent: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: Date(), to: date)
        return components.day ?? 0
    }

    /// Est-ce que l'événement est passé ?
    var isPast: Bool {
        date < Date()
    }

    /// Est-ce que l'événement est aujourd'hui ?
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    /// Est-ce que l'événement est cette semaine ?
    var isThisWeek: Bool {
        daysUntilEvent >= 0 && daysUntilEvent <= 7
    }

    /// Nombre de cadeaux dans la wishlist
    var wishlistCount: Int {
        wishlistItems?.count ?? 0
    }

    /// Nombre de photos dans l'album
    var photosCount: Int {
        eventPhotos?.count ?? 0
    }

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        type: MyEventType,
        title: String,
        eventDescription: String? = nil,
        date: Date,
        time: Date? = nil,
        location: String? = nil,
        locationAddress: String? = nil,
        coverPhoto: Data? = nil,
        profilePhoto: Data? = nil,
        maxGuests: Int? = nil,
        rsvpDeadline: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.eventDescription = eventDescription
        self.date = date
        self.time = time
        self.location = location
        self.locationAddress = locationAddress
        self.coverPhoto = coverPhoto
        self.profilePhoto = profilePhoto
        self.maxGuests = maxGuests
        self.rsvpDeadline = rsvpDeadline
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Preview Helper

extension MyEvent {
    /// Événement de preview - Mon anniversaire
    static var preview: MyEvent {
        let calendar = Calendar.current
        let futureDate = calendar.date(byAdding: .day, value: 30, to: Date()) ?? Date()

        return MyEvent(
            type: .birthday,
            title: "Mes 30 ans 🎉",
            eventDescription: "Grande fête pour célébrer mes 30 ans avec tous mes amis !",
            date: futureDate,
            time: calendar.date(from: DateComponents(hour: 20, minute: 0)),
            location: "Chez moi",
            locationAddress: "12 rue de la Joie, 75001 Paris",
            maxGuests: 50,
            rsvpDeadline: calendar.date(byAdding: .day, value: -7, to: futureDate)
        )
    }

    /// Événement passé
    static var pastEvent: MyEvent {
        let calendar = Calendar.current
        let pastDate = calendar.date(byAdding: .day, value: -10, to: Date()) ?? Date()

        return MyEvent(
            type: .christmas,
            title: "Noël en famille",
            date: pastDate,
            location: "Chez mes parents"
        )
    }

    /// Mariage
    static var wedding: MyEvent {
        let calendar = Calendar.current
        let weddingDate = calendar.date(byAdding: .month, value: 6, to: Date()) ?? Date()

        return MyEvent(
            type: .wedding,
            title: "Mariage de Teddy & Marie",
            eventDescription: "Nous avons le plaisir de vous inviter à notre mariage",
            date: weddingDate,
            time: calendar.date(from: DateComponents(hour: 15, minute: 0)),
            location: "Château de Versailles",
            locationAddress: "Place d'Armes, 78000 Versailles",
            maxGuests: 100,
            rsvpDeadline: calendar.date(byAdding: .month, value: -1, to: weddingDate)
        )
    }
}
