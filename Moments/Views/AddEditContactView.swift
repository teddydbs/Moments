//
//  AddEditContactView.swift
//  Moments
//
//  Vue pour ajouter ou éditer un contact (ami/famille)
//

import SwiftUI
import SwiftData
import PhotosUI

struct AddEditContactView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // Contact à éditer (nil = création)
    let contact: Contact?

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthDate: Date = Date()
    @State private var email: String = ""
    @State private var phoneNumber: String = ""
    @State private var notes: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoData: Data?

    private var isEditing: Bool {
        contact != nil
    }

    private var title: String {
        isEditing ? "Modifier le contact" : "Ajouter un contact"
    }

    private var saveButtonTitle: String {
        isEditing ? "Mettre à jour" : "Ajouter"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                MomentsTheme.diagonalGradient
                    .ignoresSafeArea()
                    .opacity(0.05)

                ScrollView {
                    VStack(spacing: 24) {
                        // Photo de profil
                        VStack(spacing: 16) {
                            ZStack(alignment: .bottomTrailing) {
                                // Photo circle
                                if let data = photoData,
                                   let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(MomentsTheme.primaryGradient, lineWidth: 3)
                                        )
                                } else {
                                    Circle()
                                        .fill(MomentsTheme.primaryGradient.opacity(0.2))
                                        .frame(width: 100, height: 100)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 40))
                                                .foregroundStyle(MomentsTheme.primaryGradient)
                                        )
                                        .overlay(
                                            Circle()
                                                .stroke(MomentsTheme.primaryGradient, lineWidth: 3)
                                        )
                                }

                                // Bouton pour changer la photo
                                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                    Circle()
                                        .fill(.white)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 14))
                                                .foregroundStyle(MomentsTheme.primaryGradient)
                                        )
                                        .shadow(radius: 2)
                                }
                            }

                            Text("Photo (optionnel)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)

                        // Formulaire
                        VStack(spacing: 20) {
                            // Prénom
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Prénom", systemImage: "person.fill")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                TextField("Prénom", text: $firstName)
                                    .textContentType(.givenName)
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(MomentsTheme.primaryGradient, lineWidth: 1)
                                    )
                            }

                            // Nom
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Nom", systemImage: "person.fill")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                TextField("Nom", text: $lastName)
                                    .textContentType(.familyName)
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(MomentsTheme.primaryGradient, lineWidth: 1)
                                    )
                            }

                            // Date de naissance
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Date de naissance", systemImage: "gift.fill")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                DatePicker(
                                    "",
                                    selection: $birthDate,
                                    in: ...Date(),
                                    displayedComponents: [.date]
                                )
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(MomentsTheme.primaryGradient, lineWidth: 1)
                                )
                            }

                            // Email (optionnel)
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Email (optionnel)", systemImage: "envelope.fill")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                TextField("email@example.com", text: $email)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .keyboardType(.emailAddress)
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                            }

                            // Téléphone (optionnel)
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Téléphone (optionnel)", systemImage: "phone.fill")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                TextField("+33 6 12 34 56 78", text: $phoneNumber)
                                    .textContentType(.telephoneNumber)
                                    .keyboardType(.phonePad)
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                            }

                            // Notes (optionnel)
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Notes (optionnel)", systemImage: "note.text")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                TextEditor(text: $notes)
                                    .frame(height: 80)
                                    .padding(8)
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                            }
                        }
                        .padding(.horizontal, 24)

                        // Bouton sauvegarder
                        Button {
                            saveContact()
                        } label: {
                            Text(saveButtonTitle)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(MomentsTheme.PrimaryButtonStyle())
                        .disabled(firstName.isEmpty || lastName.isEmpty)
                        .opacity((firstName.isEmpty || lastName.isEmpty) ? 0.6 : 1.0)
                        .padding(.horizontal, 24)

                        Spacer()
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadContactData()
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        photoData = data
                    }
                }
            }
        }
    }

    // MARK: - Methods

    private func loadContactData() {
        guard let contact = contact else { return }

        firstName = contact.firstName
        lastName = contact.lastName
        birthDate = contact.birthDate
        email = contact.email ?? ""
        phoneNumber = contact.phoneNumber ?? ""
        notes = contact.notes ?? ""
        photoData = contact.photo
    }

    private func saveContact() {
        if let existingContact = contact {
            // Mise à jour du contact existant
            existingContact.firstName = firstName
            existingContact.lastName = lastName
            existingContact.birthDate = birthDate
            existingContact.email = email.isEmpty ? nil : email
            existingContact.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
            existingContact.notes = notes.isEmpty ? nil : notes
            existingContact.photo = photoData
            existingContact.updatedAt = Date()
        } else {
            // Création d'un nouveau contact
            let newContact = Contact(
                firstName: firstName,
                lastName: lastName,
                birthDate: birthDate,
                photo: photoData,
                email: email.isEmpty ? nil : email,
                phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                notes: notes.isEmpty ? nil : notes
            )
            modelContext.insert(newContact)
        }

        // Sauvegarder le contexte
        do {
            try modelContext.save()
            print("✅ Contact sauvegardé avec succès")
            dismiss()
        } catch {
            print("❌ Erreur lors de la sauvegarde du contact: \(error)")
        }
    }
}

#Preview("Nouveau contact") {
    AddEditContactView(contact: nil)
        .modelContainer(for: [Contact.self], inMemory: true)
}

#Preview("Éditer contact") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Contact.self, configurations: config)
    let contact = Contact.preview
    container.mainContext.insert(contact)

    return AddEditContactView(contact: contact)
        .modelContainer(container)
}
