//
//  BirthdaysView.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import SwiftUI
import SwiftData

struct BirthdaysView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Event.date, order: .forward) private var allEvents: [Event]

    private var birthdays: [Event] {
        allEvents.filter { $0.category == .birthday }
    }

    @State private var showingAddBirthday = false
    @State private var selectedEvent: Event?
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                if birthdays.isEmpty {
                    emptyStateView
                } else {
                    birthdaysList
                }
            }
            .navigationTitle("Anniversaires")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddBirthday = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .gradientIcon()
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }
            }
            .sheet(isPresented: $showingAddBirthday) {
                AddEditEventView(event: nil, defaultCategory: .birthday)
            }
            .sheet(item: $selectedEvent) { event in
                AddEditEventView(event: event, defaultCategory: .birthday)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "gift")
                .font(.system(size: 80))
                .gradientIcon()

            Text("Aucun anniversaire")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Ajoutez les anniversaires de vos proches\npour ne jamais les oublier")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingAddBirthday = true
            } label: {
                Label("Ajouter un anniversaire", systemImage: "plus.circle.fill")
            }
            .buttonStyle(MomentsTheme.PrimaryButtonStyle())
            .padding(.top)
        }
        .padding()
    }

    private var birthdaysList: some View {
        List {
            ForEach(birthdays) { event in
                EventRowView(event: event)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedEvent = event
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteEvent(event)
                        } label: {
                            Label("Supprimer", systemImage: "trash")
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func deleteEvent(_ event: Event) {
        if let identifier = event.notificationIdentifier {
            NotificationManager.shared.cancelNotification(identifier: identifier)
        }
        modelContext.delete(event)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Event.self, configurations: config)

    let sampleBirthdays = [
        Event(
            title: "Anniversaire de Marie",
            date: Calendar.current.date(byAdding: .day, value: 5, to: Date())!,
            category: .birthday,
            isRecurring: true
        ),
        Event(
            title: "Anniversaire de Paul",
            date: Calendar.current.date(byAdding: .day, value: 15, to: Date())!,
            category: .birthday,
            isRecurring: true
        )
    ]

    for birthday in sampleBirthdays {
        container.mainContext.insert(birthday)
    }

    return BirthdaysView()
        .modelContainer(container)
}
