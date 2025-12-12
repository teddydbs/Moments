//
//  EventPhoto.swift
//  Moments
//
//  Modèle représentant une photo ajoutée à un événement
//  Architecture: Model (SwiftData)
//

import Foundation
import SwiftData
import UIKit

/// Représente une photo ajoutée à un événement par l'organisateur ou un invité
@Model
class EventPhoto {
    // MARK: - Properties

    /// Identifiant unique
    var id: UUID

    /// Données de la photo (JPEG compressé)
    var imageData: Data

    /// Légende optionnelle de la photo
    var caption: String?

    /// Nom de la personne qui a ajouté la photo
    var uploadedBy: String?

    /// Date d'ajout de la photo
    var uploadedAt: Date

    /// Ordre d'affichage (pour trier les photos)
    var displayOrder: Int

    // MARK: - Relationships

    /// ✅ RELATION: L'événement auquel appartient cette photo
    var myEvent: MyEvent?

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        imageData: Data,
        caption: String? = nil,
        uploadedBy: String? = nil,
        uploadedAt: Date = Date(),
        displayOrder: Int = 0,
        myEvent: MyEvent? = nil
    ) {
        self.id = id
        self.imageData = imageData
        self.caption = caption
        self.uploadedBy = uploadedBy
        self.uploadedAt = uploadedAt
        self.displayOrder = displayOrder
        self.myEvent = myEvent
    }
}

// MARK: - Preview Helper

extension EventPhoto {
    /// Photo de preview
    static var preview: EventPhoto {
        // ❓ POURQUOI créer une image de test ?
        // Pour pouvoir tester la vue sans avoir de vraies photos
        let size = CGSize(width: 300, height: 300)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.systemPurple.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        let imageData = image.jpegData(compressionQuality: 0.8) ?? Data()

        return EventPhoto(
            imageData: imageData,
            caption: "Belle soirée ! 🎉",
            uploadedBy: "Teddy",
            uploadedAt: Date()
        )
    }
}
