//
//  AddEditInvitationView.swift
//  Moments
//
//  Vue pour ajouter ou éditer une invitation
//

import SwiftUI
import SwiftData

struct AddEditInvitationView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let myEvent: MyEvent
    let invitation: Invitation?

    @Query private var allContacts: [Contact]

    @State private var guestName: String = ""
    @State private var guestEmail: String = ""
    @State private var guestPhoneNumber: String = ""
    @State private var plusOnes: Int = 0
    @State private var selectedContact: Contact?
    @State private var useExistingContact: Bool = false

    private var isEditing: Bool {
        invitation != nil
    }

    private var titleText: String {
        isEditing ? "Modifier l'invitation" : "Nouvelle invitation"
    }

    private var saveButtonTitle: String {
        isEditing ? "Mettre à jour" : "Envoyer"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                MomentsTheme.diagonalGradient
                    .ignoresSafeArea()
                    .opacity(0.05)

                Form {
                    // Section: Pour l'événement
                    Section("Pour l'événement") {
                        HStack {
                            Image(systemName: myEvent.type.icon)
                                .foregroundStyle(MomentsTheme.primaryGradient)
                            Text(myEvent.title)
                                .font(.headline)
                        }
                    }

                    // Section: Invité
                    if !allContacts.isEmpty && !isEditing {
                        Section {
                            Toggle("Choisir depuis mes contacts", isOn: $useExistingContact)
                        }

                        if useExistingContact {
                            Section("Contact") {
                                Picker("Choisir un contact", selection: $selectedContact) {
                                    Text("Sélectionner...").tag(nil as Contact?)
                                    ForEach(allContacts) { contact in
                                        Text(contact.fullName).tag(contact as Contact?)
                                    }
                                }
                                .onChange(of: selectedContact) { _, newContact in
                                    if let contact = newContact {
                                        guestName = contact.fullName
                                        guestEmail = contact.email ?? ""
                                        guestPhoneNumber = contact.phoneNumber ?? ""
                                    }
                                }
                            }
                        }
                    }

                    if !useExistingContact || isEditing {
                        Section("Informations de l'invité") {
                            TextField("Nom complet", text: $guestName)
                                .textContentType(.name)

                            TextField("Email (optionnel)", text: $guestEmail)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .keyboardType(.emailAddress)

                            TextField("Téléphone (optionnel)", text: $guestPhoneNumber)
                                .textContentType(.telephoneNumber)
                                .keyboardType(.phonePad)
                        }
                    }

                    // Section: Accompagnants
                    Section("Accompagnants") {
                        Stepper("\(plusOnes) accompagnant\(plusOnes > 1 ? "s" : "")", value: $plusOnes, in: 0...10)
                    }

                    // Section: Total
                    Section {
                        HStack {
                            Text("Nombre total de personnes")
                                .font(.headline)
                            Spacer()
                            Text("\(1 + plusOnes)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(MomentsTheme.primaryGradient)
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
                        saveInvitation()
                    }
                    .disabled(guestName.isEmpty)
                    .foregroundColor(guestName.isEmpty ? .secondary : MomentsTheme.primaryPurple)
                }
            }
            .onAppear {
                loadInvitationData()
            }
        }
    }

    // MARK: - Methods

    private func loadInvitationData() {
        guard let invitation = invitation else { return }

        guestName = invitation.guestName
        guestEmail = invitation.guestEmail ?? ""
        guestPhoneNumber = invitation.guestPhoneNumber ?? ""
        plusOnes = invitation.plusOnes
        selectedContact = invitation.contact
    }

    private func saveInvitation() {
        if let existingInvitation = invitation {
            // Mise à jour
            existingInvitation.guestName = guestName
            existingInvitation.guestEmail = guestEmail.isEmpty ? nil : guestEmail
            existingInvitation.guestPhoneNumber = guestPhoneNumber.isEmpty ? nil : guestPhoneNumber
            existingInvitation.plusOnes = plusOnes
            existingInvitation.updatedAt = Date()
        } else {
            // Création
            let newInvitation = Invitation(
                guestName: guestName,
                guestEmail: guestEmail.isEmpty ? nil : guestEmail,
                guestPhoneNumber: guestPhoneNumber.isEmpty ? nil : guestPhoneNumber,
                status: .pending,
                plusOnes: plusOnes,
                myEvent: myEvent,
                contact: selectedContact
            )
            modelContext.insert(newInvitation)
        }

        // Sauvegarder
        do {
            try modelContext.save()
            print("✅ Invitation sauvegardée avec succès")
            dismiss()
        } catch {
            print("❌ Erreur lors de la sauvegarde de l'invitation: \(error)")
        }
    }
}

#Preview {
    @Previewable @State var event = MyEvent.preview

    AddEditInvitationView(myEvent: event, invitation: nil)
        .modelContainer(for: [MyEvent.self, Contact.self, Invitation.self])
}
