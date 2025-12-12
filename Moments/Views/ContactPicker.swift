//
//  ContactPicker.swift
//  Moments
//
//  Description: Picker natif iOS pour sélectionner des contacts
//  Architecture: View (SwiftUI bridge to UIKit)
//

import SwiftUI
import ContactsUI

/// Structure représentant un contact sélectionné de manière simple
struct SelectedContact: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let email: String?
    let phoneNumber: String?
    let contactIdentifier: String // ✅ CNContact identifier pour éviter les doublons

    static func == (lhs: SelectedContact, rhs: SelectedContact) -> Bool {
        lhs.contactIdentifier == rhs.contactIdentifier
    }
}

/// ❓ POURQUOI UIViewControllerRepresentable ?
/// SwiftUI ne supporte pas nativement le picker de contacts iOS.
/// On doit donc utiliser UIKit (CNContactPickerViewController) et le "wrapper" dans SwiftUI.
struct ContactPicker: UIViewControllerRepresentable {

    // ✅ BINDING: Pour retourner les contacts sélectionnés à la vue parent
    @Binding var selectedContacts: [SelectedContact]

    // ✅ BINDING: Pour fermer le picker quand c'est terminé
    @Environment(\.dismiss) private var dismiss

    // MARK: - UIViewControllerRepresentable Protocol

    /// Crée le controller UIKit
    /// - Parameter context: Contexte fourni par SwiftUI
    /// - Returns: Le picker de contacts configuré
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()

        // ❓ POURQUOI delegate ?
        // Le delegate permet de recevoir les événements du picker (sélection, annulation)
        picker.delegate = context.coordinator

        // ✅ CONFIGURATION: Permettre la sélection multiple
        // Si tu veux limiter à 1 seul contact, retire cette ligne
        // picker.predicateForEnablingContact = NSPredicate(value: true)

        return picker
    }

    /// Met à jour le controller (pas nécessaire ici)
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {
        // Rien à faire car le picker ne change pas dynamiquement
    }

    /// Crée le coordinateur qui va gérer les événements du picker
    /// - Returns: Instance du coordinateur
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    /// ❓ POURQUOI un Coordinator ?
    /// Le Coordinator fait le pont entre UIKit (delegate pattern) et SwiftUI (binding)
    /// Il reçoit les événements du picker et met à jour le @Binding
    class Coordinator: NSObject, CNContactPickerDelegate {
        let parent: ContactPicker

        init(_ parent: ContactPicker) {
            self.parent = parent
        }

        /// ✅ ÉVÉNEMENT: L'utilisateur a sélectionné un contact
        /// - Parameters:
        ///   - picker: Le picker de contacts
        ///   - contact: Le contact sélectionné
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
            // ✅ ÉTAPE 1: Extraire les informations du contact
            let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            let email = contact.emailAddresses.first?.value as String?
            let phoneNumber = contact.phoneNumbers.first?.value.stringValue

            // ✅ ÉTAPE 2: Créer un SelectedContact
            let selectedContact = SelectedContact(
                name: name,
                email: email,
                phoneNumber: phoneNumber,
                contactIdentifier: contact.identifier
            )

            // ✅ ÉTAPE 3: Ajouter à la liste (éviter les doublons)
            if !parent.selectedContacts.contains(selectedContact) {
                parent.selectedContacts.append(selectedContact)
            }

            print("✅ Contact sélectionné: \(name)")
        }

        /// ✅ ÉVÉNEMENT: L'utilisateur a sélectionné plusieurs contacts
        /// - Parameters:
        ///   - picker: Le picker de contacts
        ///   - contacts: Les contacts sélectionnés
        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            // ✅ Traiter chaque contact sélectionné
            for contact in contacts {
                let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                let email = contact.emailAddresses.first?.value as String?
                let phoneNumber = contact.phoneNumbers.first?.value.stringValue

                let selectedContact = SelectedContact(
                    name: name,
                    email: email,
                    phoneNumber: phoneNumber,
                    contactIdentifier: contact.identifier
                )

                // ✅ Éviter les doublons
                if !parent.selectedContacts.contains(selectedContact) {
                    parent.selectedContacts.append(selectedContact)
                }
            }

            print("✅ \(contacts.count) contact(s) sélectionné(s)")
        }

        /// ✅ ÉVÉNEMENT: L'utilisateur a annulé
        func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
            print("❌ Sélection de contacts annulée")
        }
    }
}

// MARK: - Preview

#Preview {
    struct ContactPickerPreview: View {
        @State private var selectedContacts: [SelectedContact] = []
        @State private var showPicker = false

        var body: some View {
            NavigationStack {
                VStack {
                    Button("Sélectionner des contacts") {
                        showPicker = true
                    }

                    List(selectedContacts) { contact in
                        VStack(alignment: .leading) {
                            Text(contact.name)
                                .font(.headline)
                            if let email = contact.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .sheet(isPresented: $showPicker) {
                    ContactPicker(selectedContacts: $selectedContacts)
                }
            }
        }
    }

    return ContactPickerPreview()
}
