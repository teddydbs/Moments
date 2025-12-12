//
//  ProfileView.swift
//  Moments
//
//  Vue pour créer/éditer le profil utilisateur
//  Permet de renseigner nom, prénom, date de naissance, photo
//  Synchronise avec Supabase via ProfileManager
//

import SwiftUI
import SwiftData
import PhotosUI
import Supabase
import Auth

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager

    // ✅ Utiliser UserProfile au lieu de AppUser
    @Query private var profiles: [UserProfile]

    // ProfileManager pour la synchronisation Supabase (initialisé dans onAppear)
    @State private var profileManager: ProfileManager?

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthDate: Date = Date()
    @State private var phoneNumber: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profilePhoto: Data?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    // Computed property pour savoir si on crée ou édite
    private var existingProfile: UserProfile? {
        profiles.first
    }

    private var isEditing: Bool {
        existingProfile != nil
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

                        // Message d'erreur
                        if let errorMessage = errorMessage {
                            Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                        }

                        // Bouton sauvegarder
                        Button {
                            saveProfile()
                        } label: {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(isEditing ? "Mettre à jour" : "Créer mon profil")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(MomentsTheme.PrimaryButtonStyle())
                        .disabled(firstName.isEmpty || lastName.isEmpty || isLoading)
                        .opacity((firstName.isEmpty || lastName.isEmpty || isLoading) ? 0.6 : 1.0)
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
                        .disabled(isLoading)
                    }
                }
            }
            .onAppear {
                // ✅ Initialiser le ProfileManager avec le modelContext
                if profileManager == nil {
                    profileManager = ProfileManager(modelContext: modelContext)
                }
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

    /// Charge le profil existant depuis SwiftData
    private func loadExistingProfile() {
        guard let profile = existingProfile else {
            // Pas de profil local, essayer de charger depuis Supabase
            Task {
                await loadProfileFromSupabase()
            }
            return
        }

        // Charger les données du profil local
        firstName = profile.firstName
        lastName = profile.lastName
        birthDate = profile.birthDate ?? Date()
        phoneNumber = profile.phoneNumber ?? ""
        profilePhoto = profile.profilePhotoData
    }

    /// Charge le profil depuis Supabase
    private func loadProfileFromSupabase() async {
        guard let manager = profileManager else { return }
        isLoading = true

        do {
            try await manager.loadUserProfile()

            if let profile = manager.currentProfile {
                await MainActor.run {
                    firstName = profile.firstName
                    lastName = profile.lastName
                    birthDate = profile.birthDate ?? Date()
                    phoneNumber = profile.phoneNumber ?? ""
                    profilePhoto = profile.profilePhotoData
                }
            }

            isLoading = false
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Erreur de chargement du profil"
                print("❌ Erreur loadProfileFromSupabase: \(error)")
            }
        }
    }

    /// Sauvegarde le profil (local et distant)
    private func saveProfile() {
        guard let manager = profileManager else {
            errorMessage = "ProfileManager non initialisé"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                // ✅ Récupérer l'ID utilisateur depuis la session Supabase
                guard let userId = try? await SupabaseManager.shared.client.auth.session.user.id else {
                    throw ProfileError.notAuthenticated
                }

                if let existingProfile = existingProfile {
                    // ⚙️ MISE À JOUR du profil existant
                    print("🔄 Mise à jour du profil existant...")

                    // Mettre à jour les données locales
                    existingProfile.firstName = firstName
                    existingProfile.lastName = lastName
                    existingProfile.birthDate = birthDate
                    existingProfile.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
                    existingProfile.profilePhotoData = profilePhoto

                    // Synchroniser avec Supabase
                    try await manager.updateProfile(existingProfile)

                    // Upload photo si modifiée
                    if let photoData = profilePhoto,
                       photoData != existingProfile.profilePhotoData {
                        try await manager.uploadProfilePhoto(photoData, for: existingProfile)
                    }

                    await MainActor.run {
                        isLoading = false
                        print("✅ Profil mis à jour avec succès")
                        dismiss()
                    }

                } else {
                    // ➕ CRÉATION d'un nouveau profil
                    print("➕ Création d'un nouveau profil...")

                    let newProfile = UserProfile(
                        id: userId,
                        firstName: firstName,
                        lastName: lastName,
                        birthDate: birthDate,
                        phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                        profilePhotoData: profilePhoto,
                        onboardingCompleted: true
                    )

                    // Créer dans Supabase ET localement
                    try await manager.createProfile(newProfile)

                    // Upload photo si présente
                    if let photoData = profilePhoto {
                        try await manager.uploadProfilePhoto(photoData, for: newProfile)
                    }

                    await MainActor.run {
                        isLoading = false
                        print("✅ Profil créé avec succès")
                        dismiss()
                    }
                }

            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Erreur de sauvegarde: \(error.localizedDescription)"
                    print("❌ Erreur saveProfile: \(error)")
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager.shared)
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
