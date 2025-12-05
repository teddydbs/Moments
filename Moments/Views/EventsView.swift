//
//  EventsView.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import SwiftUI
import SwiftData

struct EventsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Event.date, order: .forward) private var allEvents: [Event]

    private var events: [Event] {
        allEvents.filter { $0.category != .birthday }
    }

    @State private var showingAddEvent = false
    @State private var selectedEvent: Event?
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                if events.isEmpty {
                    emptyStateView
                } else {
                    eventsList
                }
            }
            .navigationTitle("Événements")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddEvent = true
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
            .sheet(isPresented: $showingAddEvent) {
                AddEditEventView(event: nil, defaultCategory: nil)
            }
            .sheet(item: $selectedEvent) { event in
                EventDetailView(event: event)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 80))
                .gradientIcon()

            Text("Aucun événement")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Ajoutez vos événements importants\n(mariages, soirées, EVG/EVJF...)")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingAddEvent = true
            } label: {
                Label("Créer un événement", systemImage: "plus.circle.fill")
            }
            .buttonStyle(MomentsTheme.PrimaryButtonStyle())
            .padding(.top)
        }
        .padding()
    }

    private var eventsList: some View {
        List {
            ForEach(events) { event in
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

    let sampleEvents = [
        Event(
            title: "Mariage de Sophie",
            date: Calendar.current.date(byAdding: .day, value: 30, to: Date())!,
            category: .wedding,
            notes: "À Paris"
        ),
        Event(
            title: "EVG de Thomas",
            date: Calendar.current.date(byAdding: .day, value: 15, to: Date())!,
            category: .bachelorParty
        ),
        Event(
            title: "Soirée d'entreprise",
            date: Calendar.current.date(byAdding: .day, value: 7, to: Date())!,
            category: .party
        )
    ]

    for event in sampleEvents {
        container.mainContext.insert(event)
    }

    return EventsView()
        .modelContainer(container)
}
