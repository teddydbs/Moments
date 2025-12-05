//
//  AddEditEventView.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import SwiftUI
import SwiftData

struct AddEditEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let event: Event?
    let defaultCategory: EventCategory?

    @State private var title: String = ""
    @State private var date: Date = Date()
    @State private var category: EventCategory = .birthday
    @State private var isRecurring: Bool = false
    @State private var notes: String = ""
    @State private var imageData: Data?
    @State private var hasGiftPool: Bool = false
    @State private var participants: [TempParticipant] = []
    @State private var showingAddParticipantOptions = false
    @State private var showingManualParticipantForm = false
    @State private var newParticipantName = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    private var isEditing: Bool {
        event != nil
    }

    private var isCategoryLocked: Bool {
        defaultCategory != nil && !isEditing
    }

    var body: some View {
        NavigationStack {
            Form {
                // SECTION: Photo
                Section {
                    HStack {
                        Spacer()
                        ImagePicker(imageData: $imageData)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                // SECTION: Informations de base
                Section("Informations") {
                    TextField("Titre de l'événement", text: $title)
                        .font(.body)

                    DatePicker(
                        "Date",
                        selection: $date,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.compact)
                }

                // SECTION: Catégorie
                Section("Catégorie") {
                    if isCategoryLocked {
                        HStack {
                            Text(category.icon)
                            Text(category.rawValue)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else {
                        Picker("Type d'événement", selection: $category) {
                            ForEach(EventCategory.allCases, id: \.self) { cat in
                                HStack {
                                    Text(cat.icon)
                                    Text(cat.rawValue)
                                }
                                .tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    Toggle("Répéter chaque année", isOn: $isRecurring)
                }

                // SECTION: Participants
                Section {
                    if participants.isEmpty {
                        Text("Aucun participant pour le moment")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(participants) { participant in
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.blue)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(participant.name)
                                        .font(.body)

                                    if let phone = participant.phone {
                                        Label(phone, systemImage: "phone.fill")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    if let email = participant.email {
                                        Label(email, systemImage: "envelope.fill")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .onDelete { indexSet in
                            participants.remove(atOffsets: indexSet)
                        }
                    }

                    Button {
                        showingAddParticipantOptions = true
                    } label: {
                        Label("Ajouter un participant", systemImage: "person.badge.plus")
                            .foregroundColor(.accentColor)
                    }
                } header: {
                    HStack {
                        Text("Participants")
                        Spacer()
                        Text("\(participants.count)")
                            .foregroundColor(.secondary)
                    }
                } footer: {
                    Text("Ajoutez les participants à cet événement. Vous pouvez les importer depuis différentes sources.")
                        .font(.caption)
                }

                // SECTION: Cagnotte (uniquement pour les événements, pas les anniversaires)
                if defaultCategory != .birthday && category != .birthday {
                    Section {
                        Toggle("Activer la cagnotte commune", isOn: $hasGiftPool)

                        if hasGiftPool {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Avec la cagnotte activée :")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                Label("Les participants pourront proposer des idées cadeaux", systemImage: "gift.fill")
                                    .font(.caption)

                                Label("Chacun pourra voir les suggestions", systemImage: "eye.fill")
                                    .font(.caption)

                                Label("Gestion des contributions à venir", systemImage: "eurosign.circle.fill")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Cagnotte")
                    } footer: {
                        if hasGiftPool {
                            Text("La gestion des paiements (Lydia, Stripe) sera ajoutée dans une future version.")
                                .font(.caption)
                        }
                    }
                }

                // SECTION: Notes
                Section("Notes (optionnel)") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }

                // SECTION: Bouton de sauvegarde
                Section {
                    Button(action: saveEvent) {
                        HStack {
                            Spacer()
                            Text(isEditing ? "Enregistrer" : "Créer l'événement")
                                .fontWeight(.semibold)
                                .foregroundStyle(MomentsTheme.primaryGradient)
                            Spacer()
                        }
                    }
                    .disabled(title.isEmpty)
                }
            }
            .navigationTitle(isEditing ? "Modifier" : "Nouvel événement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .confirmationDialog("Ajouter un participant", isPresented: $showingAddParticipantOptions) {
                Button("Depuis Contacts") {
                    addFromContacts()
                }
                Button("Depuis Facebook") {
                    addFromFacebook()
                }
                Button("Depuis Instagram") {
                    addFromInstagram()
                }
                Button("Depuis WhatsApp") {
                    addFromWhatsApp()
                }
                Button("Manuellement") {
                    showingManualParticipantForm = true
                }
                Button("Annuler", role: .cancel) { }
            } message: {
                Text("Choisissez comment ajouter un participant")
            }
            .sheet(isPresented: $showingManualParticipantForm) {
                if let event = event {
                    AddManualParticipantView(event: event)
                }
            }
            .alert("Notification", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            .onAppear {
                if let event = event {
                    title = event.title
                    date = event.date
                    category = event.category
                    isRecurring = event.isRecurring
                    notes = event.notes
                    imageData = event.imageData
                    hasGiftPool = event.hasGiftPool
                    // Charger les participants existants
                    participants = event.participants.map {
                        TempParticipant(name: $0.name, phone: $0.phone, email: $0.email)
                    }
                } else if let defaultCategory = defaultCategory {
                    category = defaultCategory
                }
            }
        }
    }

    private func saveEvent() {
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()

            if isEditing {
                // Update existing event
                if let event = event {
                    event.title = title
                    event.date = date
                    event.category = category
                    event.isRecurring = isRecurring
                    event.notes = notes
                    event.imageData = imageData
                    event.hasGiftPool = hasGiftPool

                    // Mettre à jour les participants
                    // Supprimer les anciens
                    event.participants.forEach { modelContext.delete($0) }
                    event.participants.removeAll()

                    // Ajouter les nouveaux
                    for tempParticipant in participants {
                        let participant = Participant(
                            name: tempParticipant.name,
                            phone: tempParticipant.phone,
                            email: tempParticipant.email,
                            source: .manual
                        )
                        participant.event = event
                        event.participants.append(participant)
                        modelContext.insert(participant)
                    }

                    if granted {
                        await NotificationManager.shared.scheduleNotification(for: event)
                    }
                }
            } else {
                // Create new event
                let notificationIdentifier = granted ? UUID().uuidString : nil
                let newEvent = Event(
                    title: title,
                    date: date,
                    category: category,
                    isRecurring: isRecurring,
                    notes: notes,
                    notificationIdentifier: notificationIdentifier,
                    imageData: imageData,
                    hasGiftPool: hasGiftPool
                )

                modelContext.insert(newEvent)

                // Ajouter les participants
                for tempParticipant in participants {
                    let participant = Participant(
                        name: tempParticipant.name,
                        phone: tempParticipant.phone,
                        email: tempParticipant.email,
                        source: .manual
                    )
                    participant.event = newEvent
                    newEvent.participants.append(participant)
                    modelContext.insert(participant)
                }

                // Sauvegarder explicitement
                try? modelContext.save()

                if granted {
                    await NotificationManager.shared.scheduleNotification(for: newEvent)
                }
            }

            if !granted {
                alertMessage = "Les notifications ne sont pas autorisées. Vous pouvez les activer dans les Réglages."
                showingAlert = true
                try? await Task.sleep(nanoseconds: 500_000_000)
            }

            dismiss()
        }
    }

    // MARK: - Participant Source Functions

    private func addFromContacts() {
        // TODO: Implement Contacts integration
        alertMessage = "L'importation depuis les Contacts sera disponible prochainement."
        showingAlert = true
    }

    private func addFromFacebook() {
        // TODO: Implement Facebook API integration
        alertMessage = "L'importation depuis Facebook sera disponible prochainement. Vous devez d'abord configurer l'API Facebook."
        showingAlert = true
    }

    private func addFromInstagram() {
        // TODO: Implement Instagram API integration
        alertMessage = "L'importation depuis Instagram sera disponible prochainement. Vous devez d'abord configurer l'API Instagram."
        showingAlert = true
    }

    private func addFromWhatsApp() {
        // TODO: Implement WhatsApp integration
        alertMessage = "L'importation depuis WhatsApp sera disponible prochainement."
        showingAlert = true
    }
}

// Structure temporaire pour gérer les participants avant la sauvegarde
struct TempParticipant: Identifiable {
    let id = UUID()
    let name: String
    let phone: String?
    let email: String?
}

#Preview("Nouvel événement") {
    AddEditEventView(event: nil, defaultCategory: nil)
        .modelContainer(for: [Event.self, Participant.self, GiftIdea.self], inMemory: true)
}

#Preview("Nouvel anniversaire") {
    AddEditEventView(event: nil, defaultCategory: .birthday)
        .modelContainer(for: [Event.self, Participant.self, GiftIdea.self], inMemory: true)
}
