//
//  AddEditMyEventView.swift
//  Moments
//
//  Vue pour ajouter ou éditer un de MES événements
//

import SwiftUI
import SwiftData
import MapKit
import PhotosUI

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

    // Pour la carte
    @State private var mapPosition: MapCameraPosition = .automatic
    @State private var locationCoordinate: CLLocationCoordinate2D?
    @State private var isGeocodingAddress: Bool = false

    // Pour les photos
    @State private var selectedCoverPhoto: PhotosPickerItem?
    @State private var coverPhotoData: Data?
    @State private var selectedProfilePhoto: PhotosPickerItem?
    @State private var profilePhotoData: Data?

    // Pour les participants
    @State private var selectedContacts: [SelectedContact] = []
    @State private var showContactPicker = false
    @State private var showManualAdd = false

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
                    // Section: Photos
                    Section("Photos de l'événement") {
                        // Photo de couverture
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Photo de couverture")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            PhotosPicker(selection: $selectedCoverPhoto, matching: .images) {
                                if let coverData = coverPhotoData,
                                   let uiImage = UIImage(data: coverData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 150)
                                        .frame(maxWidth: .infinity)
                                        .clipped()
                                        .cornerRadius(12)
                                } else {
                                    HStack {
                                        Image(systemName: "photo.fill")
                                            .font(.title2)
                                        Text("Ajouter une photo de couverture")
                                    }
                                    .frame(height: 150)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                            }
                        }

                        // Photo de profil
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Photo de profil")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            HStack {
                                PhotosPicker(selection: $selectedProfilePhoto, matching: .images) {
                                    if let profileData = profilePhotoData,
                                       let uiImage = UIImage(data: profileData) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 80, height: 80)
                                            .clipShape(Circle())
                                    } else {
                                        ZStack {
                                            Circle()
                                                .fill(Color(.systemGray6))
                                                .frame(width: 80, height: 80)

                                            Image(systemName: "person.fill")
                                                .font(.title)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }

                                Text("Photo circulaire affichée sur l'événement")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

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

                        HStack {
                            TextField("Adresse", text: $locationAddress)
                                .textContentType(.fullStreetAddress)
                                .onChange(of: locationAddress) { oldValue, newValue in
                                    // ✅ Géocoder l'adresse quand elle change
                                    if !newValue.isEmpty {
                                        Task {
                                            await geocodeAddress(newValue)
                                        }
                                    } else {
                                        locationCoordinate = nil
                                    }
                                }

                            if isGeocodingAddress {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }

                        // ✅ Carte interactive si on a une adresse
                        if let coordinate = locationCoordinate {
                            Map(position: $mapPosition, interactionModes: []) {
                                Marker(location.isEmpty ? "Lieu" : location, coordinate: coordinate)
                            }
                            .frame(height: 200)
                            .cornerRadius(12)
                            .onAppear {
                                // Centrer la carte sur la position
                                mapPosition = .region(MKCoordinateRegion(
                                    center: coordinate,
                                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                ))
                            }
                            .onTapGesture {
                                // Ouvrir Apple Maps avec les coordonnées
                                openInMaps(coordinate: coordinate)
                            }
                        }
                    }

                    // Section: Participants
                    Section {
                        // ✅ Bouton pour ajouter depuis les contacts
                        Button {
                            showContactPicker = true
                        } label: {
                            HStack {
                                Image(systemName: "person.crop.circle.badge.plus")
                                    .foregroundColor(MomentsTheme.primaryPurple)
                                Text("Inviter depuis les contacts")
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }

                        // ✅ Bouton pour ajouter manuellement
                        Button {
                            showManualAdd = true
                        } label: {
                            HStack {
                                Image(systemName: "person.badge.plus")
                                    .foregroundColor(MomentsTheme.primaryPurple)
                                Text("Ajouter manuellement")
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }

                        // ✅ Liste des participants sélectionnés
                        if !selectedContacts.isEmpty {
                            ForEach(selectedContacts) { contact in
                                HStack {
                                    // Icône de personne
                                    ZStack {
                                        Circle()
                                            .fill(MomentsTheme.primaryPurple.opacity(0.1))
                                            .frame(width: 40, height: 40)

                                        Text(contact.name.prefix(1).uppercased())
                                            .font(.headline)
                                            .foregroundColor(MomentsTheme.primaryPurple)
                                    }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(contact.name)
                                            .font(.body)

                                        if let email = contact.email {
                                            Text(email)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        } else if let phone = contact.phoneNumber {
                                            Text(phone)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }

                                    Spacer()
                                }
                            }
                            .onDelete { indexSet in
                                selectedContacts.remove(atOffsets: indexSet)
                            }
                        }
                    } header: {
                        Text("Participants (\(selectedContacts.count))")
                    } footer: {
                        if selectedContacts.isEmpty {
                            Text("Invite tes amis en sélectionnant des contacts depuis ton téléphone")
                        } else {
                            Text("Glisse vers la gauche pour retirer un participant")
                        }
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
                                in: Date()...date,
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
            .onChange(of: selectedCoverPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        coverPhotoData = data
                    }
                }
            }
            .onChange(of: selectedProfilePhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        profilePhotoData = data
                    }
                }
            }
            .sheet(isPresented: $showContactPicker) {
                CustomContactPickerView(selectedContacts: $selectedContacts)
            }
            .sheet(isPresented: $showManualAdd) {
                AddManualContactView(selectedContacts: $selectedContacts)
            }
        }
    }

    // MARK: - Methods

    /// Ouvre Apple Maps avec les coordonnées du lieu
    /// - Parameter coordinate: Les coordonnées GPS du lieu
    private func openInMaps(coordinate: CLLocationCoordinate2D) {
        // ❓ POURQUOI: MKMapItem permet d'ouvrir Apple Maps avec un lieu précis
        let placemark = MKPlacemark(coordinate: coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = location.isEmpty ? "Lieu de l'événement" : location

        // ✅ Ouvrir dans Apple Maps
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving
        ])
    }

    /// Géocode une adresse pour obtenir les coordonnées GPS
    /// - Parameter address: L'adresse à géocoder
    private func geocodeAddress(_ address: String) async {
        isGeocodingAddress = true

        // ❓ POURQUOI: CLGeocoder permet de convertir une adresse en coordonnées GPS
        let geocoder = CLGeocoder()

        do {
            // ✅ ÉTAPE 1: Demander les coordonnées à Apple Maps
            let placemarks = try await geocoder.geocodeAddressString(address)

            // ✅ ÉTAPE 2: Récupérer la première position trouvée
            if let coordinate = placemarks.first?.location?.coordinate {
                await MainActor.run {
                    locationCoordinate = coordinate
                    // Mettre à jour la position de la carte
                    mapPosition = .region(MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    ))
                }
            }
        } catch {
            print("❌ Erreur de géocodage: \(error.localizedDescription)")
            // Si l'adresse n'est pas trouvée, on ne fait rien (pas d'alerte pour ne pas déranger)
            await MainActor.run {
                locationCoordinate = nil
            }
        }

        await MainActor.run {
            isGeocodingAddress = false
        }
    }

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
        coverPhotoData = event.coverPhoto
        profilePhotoData = event.profilePhoto

        // ✅ Charger les participants existants (invitations)
        if let invitations = event.invitations {
            selectedContacts = invitations.map { invitation in
                SelectedContact(
                    name: invitation.guestName,
                    email: invitation.guestEmail,
                    phoneNumber: invitation.guestPhoneNumber,
                    contactIdentifier: invitation.id.uuidString // ⚠️ Utiliser l'ID de l'invitation comme identifier
                )
            }
        }

        // ✅ Géocoder l'adresse si elle existe
        if !locationAddress.isEmpty {
            Task {
                await geocodeAddress(locationAddress)
            }
        }
    }

    private func saveEvent() {
        let maxGuestsInt = Int(maxGuests)

        let eventToSave: MyEvent

        if let existingEvent = myEvent {
            // Mise à jour de l'événement existant
            existingEvent.type = type
            existingEvent.title = title
            existingEvent.eventDescription = eventDescription.isEmpty ? nil : eventDescription
            existingEvent.date = date
            existingEvent.time = hasTime ? time : nil
            existingEvent.location = location.isEmpty ? nil : location
            existingEvent.locationAddress = locationAddress.isEmpty ? nil : locationAddress
            existingEvent.coverPhoto = coverPhotoData
            existingEvent.profilePhoto = profilePhotoData
            existingEvent.maxGuests = maxGuestsInt
            existingEvent.rsvpDeadline = hasRSVPDeadline ? rsvpDeadline : nil
            existingEvent.updatedAt = Date()
            eventToSave = existingEvent

            // ✅ ÉTAPE 1: Supprimer les invitations existantes qui ne sont plus dans la sélection
            if let existingInvitations = existingEvent.invitations {
                let selectedIdentifiers = Set(selectedContacts.map { $0.contactIdentifier })

                for invitation in existingInvitations {
                    // Si l'invitation n'est plus dans les contacts sélectionnés, la supprimer
                    if !selectedIdentifiers.contains(invitation.id.uuidString) {
                        modelContext.delete(invitation)
                    }
                }
            }
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
                coverPhoto: coverPhotoData,
                profilePhoto: profilePhotoData,
                maxGuests: maxGuestsInt,
                rsvpDeadline: hasRSVPDeadline ? rsvpDeadline : nil
            )
            modelContext.insert(newEvent)
            eventToSave = newEvent
        }

        // ✅ ÉTAPE 2: Créer les invitations pour les nouveaux participants
        createInvitationsForParticipants(event: eventToSave)

        // Sauvegarder le contexte
        do {
            try modelContext.save()
            print("✅ Événement sauvegardé avec succès avec \(selectedContacts.count) participant(s)")
            dismiss()
        } catch {
            print("❌ Erreur lors de la sauvegarde de l'événement: \(error)")
        }
    }

    /// Crée des invitations pour tous les participants sélectionnés
    /// - Parameter event: L'événement auquel ajouter les invitations
    private func createInvitationsForParticipants(event: MyEvent) {
        // ❓ POURQUOI vérifier les invitations existantes ?
        // Pour éviter de créer des doublons si on édite un événement
        let existingInvitations = event.invitations ?? []
        let existingIdentifiers = Set(existingInvitations.map { $0.id.uuidString })

        for contact in selectedContacts {
            // ✅ VÉRIFICATION: Ne créer l'invitation que si elle n'existe pas déjà
            if !existingIdentifiers.contains(contact.contactIdentifier) {
                let invitation = Invitation(
                    guestName: contact.name,
                    guestEmail: contact.email,
                    guestPhoneNumber: contact.phoneNumber,
                    status: .pending,
                    sentAt: Date(),
                    myEvent: event
                )
                modelContext.insert(invitation)
                print("✅ Invitation créée pour \(contact.name)")
            }
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
