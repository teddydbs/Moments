//
//  AddManualParticipantView.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import SwiftUI
import SwiftData

struct AddManualParticipantView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let event: Event

    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var showingError = false
    @State private var errorMessage = ""

    private var isValid: Bool {
        !name.isEmpty && (!phone.isEmpty || !email.isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nom du participant", text: $name)
                        .textContentType(.name)
                } header: {
                    Text("Informations obligatoires")
                } footer: {
                    Text("Le nom est requis")
                        .font(.caption)
                }

                Section {
                    TextField("Numéro de téléphone", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)

                    TextField("Adresse email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                } header: {
                    Text("Contact (au moins un requis)")
                } footer: {
                    Text("Entrez au minimum un numéro de téléphone ou une adresse email")
                        .font(.caption)
                }

                Section {
                    HStack {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(isValid ? .green : .gray)

                        if isValid {
                            Text("Formulaire valide")
                                .foregroundColor(.green)
                        } else {
                            Text("Informations incomplètes")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.subheadline)
                }
            }
            .navigationTitle("Ajouter manuellement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") {
                        saveParticipant()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Erreur", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveParticipant() {
        // Validation finale
        guard !name.isEmpty else {
            errorMessage = "Le nom est obligatoire"
            showingError = true
            return
        }

        guard !phone.isEmpty || !email.isEmpty else {
            errorMessage = "Veuillez entrer au moins un téléphone ou un email"
            showingError = true
            return
        }

        // Créer le participant
        let participant = Participant(
            name: name,
            phone: phone.isEmpty ? nil : phone,
            email: email.isEmpty ? nil : email,
            source: .manual
        )

        // L'associer à l'événement
        participant.event = event
        event.participants.append(participant)

        // Insérer dans le contexte
        modelContext.insert(participant)

        // Sauvegarder
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Erreur lors de la sauvegarde: \(error.localizedDescription)"
            showingError = true
        }
    }
}
