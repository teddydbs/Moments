//
//  EventsView.swift
//  Moments
//
//  Vue pour gérer MES événements (où TU invites des gens)
//  Utilise le modèle MyEvent (nouvelle architecture)
//

import SwiftUI
import SwiftData

struct EventsView: View {
    @Environment(\.modelContext) private var modelContext

    // Query tous les événements
    @Query(sort: \MyEvent.date, order: .forward) private var allMyEvents: [MyEvent]

    // Événements à venir (pas encore passés)
    private var upcomingEvents: [MyEvent] {
        allMyEvents.filter { !$0.isPast }
    }

    // Événements passés
    private var pastEvents: [MyEvent] {
        allMyEvents.filter { $0.isPast }
    }

    @State private var showingAddEvent = false
    @State private var selectedEvent: MyEvent?
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                MomentsTheme.diagonalGradient
                    .ignoresSafeArea()
                    .opacity(0.03)

                if allMyEvents.isEmpty {
                    emptyStateView
                } else {
                    eventsList
                }
            }
            .navigationTitle("Mes Événements")
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
                AddEditMyEventView(myEvent: nil)
            }
            .sheet(item: $selectedEvent) { event in
                MyEventDetailView(myEvent: event)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 80))
                .gradientIcon()

            Text("Aucun événement")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Créez vos événements et invitez\nvos amis et famille")
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

    // MARK: - Events List

    private var eventsList: some View {
        List {
            // Section: À venir
            if !upcomingEvents.isEmpty {
                Section {
                    ForEach(upcomingEvents) { event in
                        MyEventRowView(event: event)
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

                                Button {
                                    selectedEvent = event
                                } label: {
                                    Label("Modifier", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                    }
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundStyle(MomentsTheme.primaryGradient)
                        Text("À venir")
                            .textCase(.uppercase)
                            .fontWeight(.semibold)
                    }
                }
            }

            // Section: Passés
            if !pastEvents.isEmpty {
                Section {
                    ForEach(pastEvents) { event in
                        MyEventRowView(event: event)
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
                } header: {
                    Text("Passés")
                        .textCase(.uppercase)
                        .fontWeight(.semibold)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Methods

    private func deleteEvent(_ event: MyEvent) {
        modelContext.delete(event)

        do {
            try modelContext.save()
        } catch {
            print("❌ Erreur lors de la suppression de l'événement: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    EventsView()
        .modelContainer(for: [MyEvent.self])
}
