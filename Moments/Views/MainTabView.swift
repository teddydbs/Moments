//
//  MainTabView.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import SwiftUI
import SwiftData

struct MainTabView: View {
    var body: some View {
        TabView {
            BirthdaysView()
                .tabItem {
                    Label("Anniversaires", systemImage: "gift.fill")
                }

            EventsView()
                .tabItem {
                    Label("Événements", systemImage: "calendar")
                }
        }
        .tint(MomentsTheme.primaryPurple)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Event.self, inMemory: true)
}
