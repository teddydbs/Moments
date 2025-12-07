//
//  ProfileView.swift
//  Moments
//
//  Vue pour créer/éditer le profil utilisateur
//  Permet de renseigner nom, prénom, date de naissance, photo
//

import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager

    @Query private var users: [AppUser]

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthDate: Date = Date()
    @State private var phoneNumber: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profilePhoto: Data?
    @State private var showingImagePicker = false

    // Computed property pour savoir si on crée ou édite
    private var existingUser: AppUser? {
        users.first
    }

    private var isEditing: Bool {
        existingUser != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                MomentsTheme.diagonalGradient
                    .ignoresSafeArea()
                    .opacity(0.05)

                ScrollView {
                    VStack(spacing: 30) {
                        // Photo de profil
                        VStack(spacing: 16) {
                            ZStack(alignment: .bottomTrailing) {
                                // Photo circle
                                if let photoData = profilePhoto,
                                   let uiImage = UIImage(data: photoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                        .overlay(
                                            Circle()
                                                .stroke(MomentsTheme.primaryGradient, lineWidth: 3)
                                        )
                                } else {
                                    Circle()
                                        .fill(MomentsTheme.primaryGradient.opacity(0.2))
                                        .frame(width: 120, height: 120)
                                        .overlay(
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 50))
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
                                        .frame(width: 36, height: 36)
                                        .overlay(
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(MomentsTheme.primaryGradient)
                                        )
                                        .shadow(radius: 2)
                                }
                            }

                            Text(isEditing ? "Modifier mon profil" : "Créer mon profil")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(MomentsTheme.primaryGradient)
                        }
                        .padding(.top, 20)

                        // Formulaire
                        VStack(spacing: 20) {
                            // Prénom
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Prénom")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                TextField("Ton prénom", text: $firstName)
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
                                Text("Nom")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                TextField("Ton nom", text: $lastName)
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
                                Text("Date de naissance")
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

                            // Numéro de téléphone (optionnel)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Téléphone (optionnel)")
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
                                            .stroke(MomentsTheme.primaryGradient, lineWidth: 1)
                                    )
                            }

                            // Email (non modifiable, vient de l'auth)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)

                                Text(authManager.currentUser?.email ?? "Non connecté")
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 24)

                        // Bouton sauvegarder
                        Button {
                            saveProfile()
                        } label: {
                            Text(isEditing ? "Mettre à jour" : "Créer mon profil")
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
            .navigationTitle("Mon Profil")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if isEditing {
                        Button("Annuler") {
                            dismiss()
                        }
                    }
                }
            }
            .onAppear {
                loadExistingProfile()
            }
            .onChange(of: selectedPhoto) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        profilePhoto = data
                    }
                }
            }
        }
    }

    // MARK: - Methods

    private func loadExistingProfile() {
        guard let user = existingUser else { return }

        firstName = user.firstName
        lastName = user.lastName
        birthDate = user.birthDate ?? Date()
        phoneNumber = user.phoneNumber ?? ""
        profilePhoto = user.profilePhoto
    }

    private func saveProfile() {
        let email = authManager.currentUser?.email ?? ""

        if let user = existingUser {
            // Mise à jour du profil existant
            user.firstName = firstName
            user.lastName = lastName
            user.birthDate = birthDate
            user.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
            user.profilePhoto = profilePhoto
            user.updatedAt = Date()
        } else {
            // Création d'un nouveau profil
            let newUser = AppUser(
                firstName: firstName,
                lastName: lastName,
                email: email,
                birthDate: birthDate,
                profilePhoto: profilePhoto,
                phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber
            )
            modelContext.insert(newUser)
        }

        // Sauvegarder le contexte
        do {
            try modelContext.save()
            print("✅ Profil sauvegardé avec succès")
            dismiss()
        } catch {
            print("❌ Erreur lors de la sauvegarde du profil: \(error)")
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager.shared)
        .modelContainer(for: [AppUser.self], inMemory: true)
}
