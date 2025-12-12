//
//  AddManualContactView.swift
//  Moments
//
//  Description: Vue pour ajouter manuellement un participant (sans passer par les contacts)
//  Architecture: View (SwiftUI)
//

import SwiftUI

/// Vue pour ajouter manuellement un participant à un événement
struct AddManualContactView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedContacts: [SelectedContact]

    @State private var name = ""
    @State private var email = ""
    @State private var phoneNumber = ""

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Nom complet", text: $name)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                } header: {
                    Text("Informations obligatoires")
                } footer: {
                    Text("Le nom est obligatoire pour ajouter un participant")
                }

                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()

                    TextField("Téléphone", text: $phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                } header: {
                    Text("Informations optionnelles")
                } footer: {
                    Text("Ajoutez au moins un email ou un téléphone pour pouvoir contacter cette personne")
                }
            }
            .navigationTitle("Ajouter un participant")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter") {
                        addManualContact()
                    }
                    .disabled(!isFormValid)
                    .foregroundColor(isFormValid ? MomentsTheme.primaryPurple : .secondary)
                }
            }
        }
    }

    // MARK: - Methods

    /// Ajoute un contact manuel à la liste des sélectionnés
    private func addManualContact() {
        // ✅ ÉTAPE 1: Nettoyer les données
        let cleanedName = name.trimmingCharacters(in: .whitespaces)
        let cleanedEmail = email.trimmingCharacters(in: .whitespaces)
        let cleanedPhone = phoneNumber.trimmingCharacters(in: .whitespaces)

        // ✅ ÉTAPE 2: Créer un SelectedContact avec un identifiant unique
        let contact = SelectedContact(
            name: cleanedName,
            email: cleanedEmail.isEmpty ? nil : cleanedEmail,
            phoneNumber: cleanedPhone.isEmpty ? nil : cleanedPhone,
            contactIdentifier: UUID().uuidString // ⚠️ Générer un UUID unique pour les contacts manuels
        )

        // ✅ ÉTAPE 3: Vérifier les doublons (même nom)
        if !selectedContacts.contains(where: { $0.name.lowercased() == cleanedName.lowercased() }) {
            selectedContacts.append(contact)
            print("✅ Contact manuel ajouté: \(cleanedName)")
        } else {
            print("⚠️ Un contact avec ce nom existe déjà")
        }

        // ✅ ÉTAPE 4: Fermer la vue
        dismiss()
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedContacts: [SelectedContact] = []

        var body: some View {
            AddManualContactView(selectedContacts: $selectedContacts)
        }
    }

    return PreviewWrapper()
}
