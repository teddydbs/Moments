//
//  AddEditMyEventView.swift
//  Moments
//
//  Vue pour ajouter ou éditer un de MES événements
//

import SwiftUI
import SwiftData

struct AddEditMyEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Événement à éditer (nil = création)
    let myEvent: MyEvent?

    @State private var type: MyEventType = .birthday
    @State private var title: String = ""
    @State private var eventDescription: String = ""
    @State private var date: Date = Date()
    @State private var hasTime: Bool = false
    @State private var time: Date = Date()
    @State private var location: String = ""
    @State private var locationAddress: String = ""
    @State private var maxGuests: String = ""
    @State private var hasRSVPDeadline: Bool = false
    @State private var rsvpDeadline: Date = Date()

    private var isEditing: Bool {
        myEvent != nil
    }

    private var titleText: String {
        isEditing ? "Modifier l'événement" : "Nouvel événement"
    }

    private var saveButtonTitle: String {
        isEditing ? "Mettre à jour" : "Créer"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                MomentsTheme.diagonalGradient
                    .ignoresSafeArea()
                    .opacity(0.05)

                Form {
                    // Section: Type & Titre
                    Section("Informations générales") {
                        Picker("Type d'événement", selection: $type) {
                            ForEach(MyEventType.allCases, id: \.self) { eventType in
                                HStack {
                                    Image(systemName: eventType.icon)
                                    Text(eventType.rawValue)
                                }
                                .tag(eventType)
                            }
                        }

                        TextField("Titre de l'événement", text: $title)
                            .textContentType(.name)

                        TextEditor(text: $eventDescription)
                            .frame(height: 80)
                            .overlay(
                                VStack {
                                    HStack {
                                        if eventDescription.isEmpty {
                                            Text("Description (optionnel)")
                                                .foregroundColor(.secondary)
                                                .padding(.top, 8)
                                                .padding(.leading, 4)
                                        }
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            )
                    }

                    // Section: Date & Heure
                    Section("Date et heure") {
                        DatePicker(
                            "Date",
                            selection: $date,
                            displayedComponents: [.date]
                        )

                        Toggle("Ajouter une heure", isOn: $hasTime)

                        if hasTime {
                            DatePicker(
                                "Heure",
                                selection: $time,
                                displayedComponents: [.hourAndMinute]
                            )
                            .datePickerStyle(.compact)
                        }
                    }

                    // Section: Lieu
                    Section("Lieu (optionnel)") {
                        TextField("Nom du lieu", text: $location)
                            .textContentType(.location)

                        TextField("Adresse", text: $locationAddress)
                            .textContentType(.fullStreetAddress)
                    }

                    // Section: Invitations
                    Section("Gestion des invitations") {
                        HStack {
                            Text("Nombre max d'invités")
                            Spacer()
                            TextField("Illimité", text: $maxGuests)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 100)
                        }

                        Toggle("Date limite de confirmation", isOn: $hasRSVPDeadline)

                        if hasRSVPDeadline {
                            DatePicker(
                                "Date limite",
                                selection: $rsvpDeadline,
                                in: ...date,
                                displayedComponents: [.date]
                            )
                        }
                    }
                }
            }
            .navigationTitle(titleText)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(saveButtonTitle) {
                        saveEvent()
                    }
                    .disabled(title.isEmpty)
                    .foregroundColor(title.isEmpty ? .secondary : MomentsTheme.primaryPurple)
                }
            }
            .onAppear {
                loadEventData()
            }
        }
    }

    // MARK: - Methods

    private func loadEventData() {
        guard let event = myEvent else { return }

        type = event.type
        title = event.title
        eventDescription = event.eventDescription ?? ""
        date = event.date
        hasTime = event.time != nil
        time = event.time ?? Date()
        location = event.location ?? ""
        locationAddress = event.locationAddress ?? ""
        maxGuests = event.maxGuests != nil ? "\(event.maxGuests!)" : ""
        hasRSVPDeadline = event.rsvpDeadline != nil
        rsvpDeadline = event.rsvpDeadline ?? Date()
    }

    private func saveEvent() {
        let maxGuestsInt = Int(maxGuests)

        if let existingEvent = myEvent {
            // Mise à jour de l'événement existant
            existingEvent.type = type
            existingEvent.title = title
            existingEvent.eventDescription = eventDescription.isEmpty ? nil : eventDescription
            existingEvent.date = date
            existingEvent.time = hasTime ? time : nil
            existingEvent.location = location.isEmpty ? nil : location
            existingEvent.locationAddress = locationAddress.isEmpty ? nil : locationAddress
            existingEvent.maxGuests = maxGuestsInt
            existingEvent.rsvpDeadline = hasRSVPDeadline ? rsvpDeadline : nil
            existingEvent.updatedAt = Date()
        } else {
            // Création d'un nouvel événement
            let newEvent = MyEvent(
                type: type,
                title: title,
                eventDescription: eventDescription.isEmpty ? nil : eventDescription,
                date: date,
                time: hasTime ? time : nil,
                location: location.isEmpty ? nil : location,
                locationAddress: locationAddress.isEmpty ? nil : locationAddress,
                maxGuests: maxGuestsInt,
                rsvpDeadline: hasRSVPDeadline ? rsvpDeadline : nil
            )
            modelContext.insert(newEvent)
        }

        // Sauvegarder le contexte
        do {
            try modelContext.save()
            print("✅ Événement sauvegardé avec succès")
            dismiss()
        } catch {
            print("❌ Erreur lors de la sauvegarde de l'événement: \(error)")
        }
    }
}

#Preview("Nouvel événement") {
    AddEditMyEventView(myEvent: nil)
        .modelContainer(for: [MyEvent.self], inMemory: true)
}

#Preview("Éditer événement") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MyEvent.self, configurations: config)
    let event = MyEvent.preview
    container.mainContext.insert(event)

    return AddEditMyEventView(myEvent: event)
        .modelContainer(container)
}
