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
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Accueil", systemImage: "house.fill")
            }

            NavigationStack {
                BirthdaysView()
            }
            .tabItem {
                Label("Anniversaires", systemImage: "gift.fill")
            }

            NavigationStack {
                EventsView()
            }
            .tabItem {
                Label("Événements", systemImage: "calendar")
            }

            NavigationStack {
                MyWishlistView()
            }
            .tabItem {
                Label("Wishlists", systemImage: "heart.text.square.fill")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Profil", systemImage: "person.fill")
            }
        }
        .tint(MomentsTheme.primaryPurple)
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: Event.self, inMemory: true)
}
