//
//  MomentsApp.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import SwiftUI
import SwiftData

@main
struct MomentsApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: [Event.self, Participant.self, GiftIdea.self])
    }
}
