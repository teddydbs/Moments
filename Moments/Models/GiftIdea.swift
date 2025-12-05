//
//  GiftIdea.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import Foundation
import SwiftData

@Model
final class GiftIdea {
    var id: UUID
    var title: String
    var productURL: String?
    var productImageURL: String?
    var price: Double?
    var proposedBy: String // Nom du participant qui a proposé
    var event: Event?

    init(
        id: UUID = UUID(),
        title: String,
        productURL: String? = nil,
        productImageURL: String? = nil,
        price: Double? = nil,
        proposedBy: String
    ) {
        self.id = id
        self.title = title
        self.productURL = productURL
        self.productImageURL = productImageURL
        self.price = price
        self.proposedBy = proposedBy
    }
}
