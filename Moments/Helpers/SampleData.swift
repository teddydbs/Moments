//
//  SampleData.swift
//  Moments
//
//  Données de test pour développement et prévisualisations
//

import Foundation
import SwiftData

@MainActor
class SampleData {

    /// Crée des données de test dans un ModelContainer
    static func createSampleData(in container: ModelContainer) {
        let context = container.mainContext

        // Vérifier si on a déjà des données
        let contactDescriptor = FetchDescriptor<Contact>()
        if let existingContacts = try? context.fetch(contactDescriptor),
           !existingContacts.isEmpty {
            return // Déjà des données
        }

        // Créer des contacts avec anniversaires variés
        let contacts = [
            Contact(
                firstName: "Marie",
                lastName: "Dupont",
                birthDate: Calendar.current.date(byAdding: .day, value: 2, to: Date())!,
                email: "marie@example.com",
                phoneNumber: "06 12 34 56 78"
            ),
            Contact(
                firstName: "Thomas",
                lastName: "Martin",
                birthDate: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
                email: "thomas@example.com"
            ),
            Contact(
                firstName: "Sophie",
                lastName: "Bernard",
                birthDate: Calendar.current.date(byAdding: .day, value: 10, to: Date())!,
                email: "sophie@example.com",
                phoneNumber: "06 98 76 54 32"
            ),
            Contact(
                firstName: "Lucas",
                lastName: "Petit",
                birthDate: Calendar.current.date(byAdding: .day, value: 15, to: Date())!
            ),
            Contact(
                firstName: "Emma",
                lastName: "Robert",
                birthDate: Calendar.current.date(byAdding: .day, value: 20, to: Date())!,
                email: "emma@example.com"
            )
        ]

        for contact in contacts {
            context.insert(contact)
        }

        // Créer des événements à venir
        let events = [
            MyEvent(
                type: .wedding,
                title: "Mon mariage",
                date: Calendar.current.date(byAdding: .month, value: 2, to: Date())!,
                time: Calendar.current.date(byAdding: .month, value: 2, to: Date())!,
                location: "Château de Versailles",
                maxGuests: 150
            ),
            MyEvent(
                type: .birthday,
                title: "Mes 30 ans",
                date: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
                time: Calendar.current.date(byAdding: .month, value: 1, to: Date())!,
                location: "Chez moi",
                maxGuests: 50
            ),
            MyEvent(
                type: .babyShower,
                title: "Baby Shower",
                date: Calendar.current.date(byAdding: .day, value: 20, to: Date())!,
                location: "Restaurant Le Jardin",
                maxGuests: 30
            ),
            MyEvent(
                type: .graduation,
                title: "Remise de diplôme",
                date: Calendar.current.date(byAdding: .day, value: 45, to: Date())!,
                location: "Sorbonne",
                maxGuests: 100
            )
        ]

        for event in events {
            context.insert(event)
        }

        // Ajouter quelques wishlists pour les événements
        let wishlistItems = [
            WishlistItem(
                title: "Machine à café Nespresso",
                itemDescription: "Modèle Vertuo",
                price: 199.0,
                url: "https://www.nespresso.com",
                category: .maison,
                priority: 3,
                myEvent: events[0] // Pour le mariage
            ),
            WishlistItem(
                title: "Mixeur KitchenAid",
                price: 349.0,
                category: .maison,
                priority: 2,
                myEvent: events[0]
            ),
            WishlistItem(
                title: "PlayStation 5",
                price: 499.0,
                category: .loisirs,
                priority: 3,
                myEvent: events[1] // Pour l'anniversaire
            ),
            WishlistItem(
                title: "Livre de cuisine",
                price: 29.0,
                category: .livre,
                priority: 1,
                myEvent: events[1]
            )
        ]

        for item in wishlistItems {
            context.insert(item)
        }

        // Ajouter quelques wishlists pour les contacts
        let contactWishlists = [
            WishlistItem(
                title: "Casque Bluetooth",
                price: 89.0,
                category: .tech,
                priority: 2,
                contact: contacts[0]
            ),
            WishlistItem(
                title: "Montre connectée",
                price: 249.0,
                category: .mode,
                priority: 3,
                contact: contacts[1]
            )
        ]

        for item in contactWishlists {
            context.insert(item)
        }

        // Sauvegarder
        try? context.save()
    }
}
