//
//  BirthdaysView.swift
//  Moments
//
//  Vue pour gérer les anniversaires des CONTACTS (amis/famille)
//  Utilise le modèle Contact (nouvelle architecture)
//

import SwiftUI
import SwiftData

struct BirthdaysView: View {
    @Environment(\.modelContext) private var modelContext

    // Query tous les contacts, triés par prochain anniversaire
    @Query private var allContacts: [Contact]

    // Contacts triés par proximité de leur anniversaire
    private var sortedContacts: [Contact] {
        allContacts.sorted { $0.daysUntilBirthday < $1.daysUntilBirthday }
    }

    // Anniversaires aujourd'hui
    private var birthdaysToday: [Contact] {
        sortedContacts.filter { $0.isBirthdayToday }
    }

    // Anniversaires cette semaine (mais pas aujourd'hui)
    private var birthdaysThisWeek: [Contact] {
        sortedContacts.filter { $0.isBirthdayThisWeek && !$0.isBirthdayToday }
    }

    // Autres anniversaires (plus tard)
    private var upcomingBirthdays: [Contact] {
        sortedContacts.filter { !$0.isBirthdayToday && !$0.isBirthdayThisWeek }
    }

    @State private var showingAddContact = false
    @State private var selectedContact: Contact?
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                MomentsTheme.diagonalGradient
                    .ignoresSafeArea()
                    .opacity(0.03)

                if allContacts.isEmpty {
                    emptyStateView
                } else {
                    birthdaysList
                }
            }
            .navigationTitle("Anniversaires")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddContact = true
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
            .sheet(isPresented: $showingAddContact) {
                AddEditContactView(contact: nil)
            }
            .sheet(item: $selectedContact) { contact in
                ContactDetailView(contact: contact)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "gift.fill")
                .font(.system(size: 80))
                .gradientIcon()

            Text("Aucun anniversaire")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Ajoutez vos amis et famille pour\nne jamais oublier leur anniversaire")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingAddContact = true
            } label: {
                Label("Ajouter un contact", systemImage: "plus.circle.fill")
            }
            .buttonStyle(MomentsTheme.PrimaryButtonStyle())
            .padding(.top)
        }
        .padding()
    }

    // MARK: - Birthdays List

    private var birthdaysList: some View {
        List {
            // Section: Anniversaires aujourd'hui
            if !birthdaysToday.isEmpty {
                Section {
                    ForEach(birthdaysToday) { contact in
                        ContactRowView(contact: contact)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedContact = contact
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteContact(contact)
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }

                                Button {
                                    selectedContact = contact
                                } label: {
                                    Label("Modifier", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                    }
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: "party.popper.fill")
                            .foregroundStyle(MomentsTheme.primaryGradient)
                        Text("Aujourd'hui")
                            .textCase(.uppercase)
                            .fontWeight(.semibold)
                    }
                }
            }

            // Section: Cette semaine
            if !birthdaysThisWeek.isEmpty {
                Section {
                    ForEach(birthdaysThisWeek) { contact in
                        ContactRowView(contact: contact)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedContact = contact
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteContact(contact)
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }

                                Button {
                                    selectedContact = contact
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
                        Text("Cette semaine")
                            .textCase(.uppercase)
                            .fontWeight(.semibold)
                    }
                }
            }

            // Section: À venir
            if !upcomingBirthdays.isEmpty {
                Section {
                    ForEach(upcomingBirthdays) { contact in
                        ContactRowView(contact: contact)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedContact = contact
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteContact(contact)
                                } label: {
                                    Label("Supprimer", systemImage: "trash")
                                }

                                Button {
                                    selectedContact = contact
                                } label: {
                                    Label("Modifier", systemImage: "pencil")
                                }
                                .tint(.orange)
                            }
                    }
                } header: {
                    Text("À venir")
                        .textCase(.uppercase)
                        .fontWeight(.semibold)
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Methods

    private func deleteContact(_ contact: Contact) {
        modelContext.delete(contact)

        do {
            try modelContext.save()
        } catch {
            print("❌ Erreur lors de la suppression du contact: \(error)")
        }
    }
}

// MARK: - Preview

#Preview {
    BirthdaysView()
        .modelContainer(for: [Contact.self])
}
