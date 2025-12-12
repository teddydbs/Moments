//
//  CustomContactPickerView.swift
//  Moments
//
//  Description: Vue personnalisée pour sélectionner des contacts avec recherche
//  Architecture: View (SwiftUI)
//

import SwiftUI
import Contacts

/// Vue personnalisée pour sélectionner des contacts depuis le carnet d'adresses
struct CustomContactPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedContacts: [SelectedContact]

    @State private var searchText = ""
    @State private var allContacts: [CNContact] = []
    @State private var isLoading = true
    @State private var showManualAdd = false
    @State private var errorMessage: String?

    // ❓ POURQUOI computed property ?
    // Pour filtrer les contacts en temps réel quand l'utilisateur tape dans la recherche
    private var filteredContacts: [CNContact] {
        if searchText.isEmpty {
            return allContacts
        } else {
            return allContacts.filter { contact in
                let fullName = "\(contact.givenName) \(contact.familyName)".lowercased()
                return fullName.contains(searchText.lowercased())
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                if isLoading {
                    // ✅ État de chargement
                    ProgressView("Chargement des contacts...")
                        .padding()
                } else if let error = errorMessage {
                    // ❌ État d'erreur
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)

                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)

                        Button("Réessayer") {
                            Task {
                                await loadContacts()
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    // ✅ Liste des contacts
                    List {
                        ForEach(filteredContacts, id: \.identifier) { contact in
                            ContactRowButton(
                                contact: contact,
                                isSelected: isContactSelected(contact),
                                onTap: {
                                    toggleContact(contact)
                                }
                            )
                        }
                    }
                    .searchable(text: $searchText, prompt: "Rechercher un contact")
                }
            }
            .navigationTitle("Sélectionner des contacts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Ajouter manuellement") {
                        showManualAdd = true
                    }
                    .foregroundColor(MomentsTheme.primaryPurple)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Terminer") {
                        dismiss()
                    }
                    .foregroundColor(MomentsTheme.primaryPurple)
                    .bold()
                }
            }
            .sheet(isPresented: $showManualAdd) {
                AddManualContactView(selectedContacts: $selectedContacts)
            }
            .task {
                await loadContacts()
            }
        }
    }

    // MARK: - Methods

    /// Charge tous les contacts depuis le carnet d'adresses
    private func loadContacts() async {
        isLoading = true
        errorMessage = nil

        // ❓ POURQUOI CNContactStore ?
        // C'est la classe iOS qui donne accès au carnet de contacts
        let store = CNContactStore()

        // ✅ ÉTAPE 1: Demander la permission d'accès aux contacts
        do {
            let granted = try await store.requestAccess(for: .contacts)

            if !granted {
                await MainActor.run {
                    errorMessage = "Moments n'a pas la permission d'accéder à vos contacts. Veuillez activer l'accès dans Réglages > Confidentialité > Contacts."
                    isLoading = false
                }
                return
            }

            // ✅ ÉTAPE 2: Définir quelles informations récupérer
            let keysToFetch: [CNKeyDescriptor] = [
                CNContactGivenNameKey as CNKeyDescriptor,
                CNContactFamilyNameKey as CNKeyDescriptor,
                CNContactEmailAddressesKey as CNKeyDescriptor,
                CNContactPhoneNumbersKey as CNKeyDescriptor
            ]

            // ✅ ÉTAPE 3: Créer une requête pour récupérer tous les contacts
            let request = CNContactFetchRequest(keysToFetch: keysToFetch)
            request.sortOrder = .givenName

            var fetchedContacts: [CNContact] = []

            // ✅ ÉTAPE 4: Récupérer les contacts
            try store.enumerateContacts(with: request) { contact, _ in
                fetchedContacts.append(contact)
            }

            // ✅ ÉTAPE 5: Mettre à jour l'interface sur le thread principal
            await MainActor.run {
                allContacts = fetchedContacts
                isLoading = false
            }

            print("✅ \(fetchedContacts.count) contacts chargés")

        } catch {
            await MainActor.run {
                errorMessage = "Impossible de charger les contacts: \(error.localizedDescription)"
                isLoading = false
            }
            print("❌ Erreur lors du chargement des contacts: \(error)")
        }
    }

    /// Vérifie si un contact est déjà sélectionné
    /// - Parameter contact: Le contact à vérifier
    /// - Returns: true si le contact est sélectionné
    private func isContactSelected(_ contact: CNContact) -> Bool {
        selectedContacts.contains { $0.contactIdentifier == contact.identifier }
    }

    /// Ajoute ou retire un contact de la sélection
    /// - Parameter contact: Le contact à ajouter/retirer
    private func toggleContact(_ contact: CNContact) {
        let contactId = contact.identifier

        if let index = selectedContacts.firstIndex(where: { $0.contactIdentifier == contactId }) {
            // ✅ Retirer le contact
            selectedContacts.remove(at: index)
        } else {
            // ✅ Ajouter le contact
            let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
            let email = contact.emailAddresses.first?.value as String?
            let phoneNumber = contact.phoneNumbers.first?.value.stringValue

            let selectedContact = SelectedContact(
                name: name.isEmpty ? "Contact sans nom" : name,
                email: email,
                phoneNumber: phoneNumber,
                contactIdentifier: contactId
            )

            selectedContacts.append(selectedContact)
        }
    }
}

// MARK: - Contact Row Button

/// Vue pour afficher une ligne de contact dans la liste
struct ContactRowButton: View {
    let contact: CNContact
    let isSelected: Bool
    let onTap: () -> Void

    private var fullName: String {
        let name = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "Contact sans nom" : name
    }

    private var initials: String {
        let first = contact.givenName.prefix(1).uppercased()
        let last = contact.familyName.prefix(1).uppercased()

        if first.isEmpty && last.isEmpty {
            return "?"
        } else if first.isEmpty {
            return last
        } else if last.isEmpty {
            return first
        } else {
            return "\(first)\(last)"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Initiales
                ZStack {
                    Circle()
                        .fill(isSelected ? MomentsTheme.primaryPurple : Color(.systemGray5))
                        .frame(width: 40, height: 40)

                    Text(initials)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                }

                // Informations
                VStack(alignment: .leading, spacing: 4) {
                    Text(fullName)
                        .font(.body)
                        .foregroundColor(.primary)

                    if let email = contact.emailAddresses.first?.value as String? {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let phone = contact.phoneNumbers.first?.value.stringValue {
                        Text(phone)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Checkmark si sélectionné
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(MomentsTheme.primaryPurple)
                        .font(.title3)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedContacts: [SelectedContact] = []

        var body: some View {
            CustomContactPickerView(selectedContacts: $selectedContacts)
        }
    }

    return PreviewWrapper()
}
