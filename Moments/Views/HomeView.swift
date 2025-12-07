//
//  HomeView.swift
//  Moments
//
//  Page d'accueil avec aperçu des anniversaires et événements à venir
//

import SwiftUI
import SwiftData

struct HomeView: View {
    // MARK: - Properties

    @Query(sort: \Contact.birthDate) private var allContacts: [Contact]
    @Query(sort: \MyEvent.date) private var allEvents: [MyEvent]
    @EnvironmentObject var authManager: AuthManager

    @State private var searchText: String = ""
    @State private var showingNotifications = false

    // MARK: - Computed Properties

    /// Anniversaires dans les 30 prochains jours
    private var upcomingBirthdays: [Contact] {
        let sortedByDaysUntil = allContacts.sorted { $0.daysUntilBirthday < $1.daysUntilBirthday }
        return Array(sortedByDaysUntil.prefix(8))
    }

    /// Événements à venir (non passés)
    private var upcomingEvents: [MyEvent] {
        allEvents
            .filter { !$0.isPast }
            .sorted { $0.date < $1.date }
            .prefix(5)
            .map { $0 }
    }

    private var userName: String {
        authManager.currentUser?.name.components(separatedBy: " ").first ?? "Utilisateur"
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Top App Bar
                topBar

                // Search Bar
                searchBar
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                // Upcoming Birthdays Section
                if !upcomingBirthdays.isEmpty {
                    birthdaysSection
                }

                // Upcoming Events Section
                if !upcomingEvents.isEmpty {
                    eventsSection
                }

                Spacer(minLength: 100)
            }
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingNotifications) {
            NotificationsPlaceholderView()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Profile Picture
                ZStack {
                    Circle()
                        .fill(MomentsTheme.primaryGradient.opacity(0.2))
                        .frame(width: 40, height: 40)

                    Text(userName.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(MomentsTheme.primaryGradient)
                }

                Spacer()

                // Notifications Button
                Button {
                    showingNotifications = true
                } label: {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.primary)
                }
            }

            // Greeting
            Text("Bonjour, \(userName)")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)

            TextField("Rechercher moments, personnes...", text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
        )
    }

    // MARK: - Birthdays Section

    private var birthdaysSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Text("Anniversaires à venir")
                    .font(.system(size: 22, weight: .bold))

                Spacer()

                NavigationLink {
                    BirthdaysView()
                } label: {
                    Text("Voir tout")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MomentsTheme.primaryGradient)
                }
            }
            .padding(.horizontal, 16)

            // Horizontal Carousel
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(upcomingBirthdays) { contact in
                        NavigationLink {
                            ContactDetailView(contact: contact)
                        } label: {
                            BirthdayCard(contact: contact)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Events Section

    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section Header
            HStack {
                Text("Événements à venir")
                    .font(.system(size: 22, weight: .bold))

                Spacer()

                NavigationLink {
                    EventsView()
                } label: {
                    Text("Voir tout")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(MomentsTheme.primaryGradient)
                }
            }
            .padding(.horizontal, 16)

            // Vertical List
            VStack(spacing: 12) {
                ForEach(upcomingEvents) { event in
                    NavigationLink {
                        MyEventDetailView(myEvent: event)
                    } label: {
                        EventCard(event: event)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 24)
    }
}

// MARK: - Birthday Card

struct BirthdayCard: View {
    let contact: Contact

    private var daysText: String {
        let days = contact.daysUntilBirthday
        if days == 0 {
            return "Aujourd'hui !"
        } else if days == 1 {
            return "Demain"
        } else if days <= 7 {
            return "dans \(days) jours"
        } else if days <= 14 {
            return "dans \(days / 7) semaine\(days / 7 > 1 ? "s" : "")"
        } else {
            return "dans \(days) jours"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Photo ou initiales
            ZStack {
                if let photoData = contact.photo,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(MomentsTheme.primaryGradient.opacity(0.15))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(contact.initials)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(MomentsTheme.primaryGradient)
                        )
                }

                // Badge si anniversaire aujourd'hui
                if contact.isBirthdayToday {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "gift.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(MomentsTheme.primaryGradient)
                                )
                                .offset(x: 10, y: 10)
                        }
                    }
                    .frame(width: 100, height: 100)
                }
            }

            // Info
            VStack(spacing: 2) {
                Text(contact.firstName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(daysText)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: 120)
    }
}

// MARK: - Event Card

struct EventCard: View {
    let event: MyEvent

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, d MMM"
        if let time = event.time {
            formatter.dateFormat = "EEE, d MMM, HH:mm"
            return formatter.string(from: time)
        } else {
            return formatter.string(from: event.date)
        }
    }

    private var iconColor: Color {
        switch event.type {
        case .birthday: return .pink
        case .wedding: return .orange
        case .babyShower: return .blue
        case .bachelorParty: return .purple
        case .houseWarming: return .cyan
        case .graduation: return .green
        case .christmas: return .red
        case .newYear: return .yellow
        case .other: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 48, height: 48)

                Image(systemName: event.type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Text(formattedDate)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Notifications Placeholder

struct NotificationsPlaceholderView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(MomentsTheme.primaryGradient)

                Text("Notifications")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Les notifications apparaîtront ici")
                    .foregroundColor(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AuthManager.shared)
    }
    .modelContainer(for: [Contact.self, MyEvent.self])
}
