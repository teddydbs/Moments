//
//  OnboardingView.swift
//  Moments
//
//  Vue d'onboarding pour les nouveaux utilisateurs
//  Demande nom, prénom, date de naissance, photo de profil
//  Architecture: View Layer
//

import SwiftUI
import SwiftData
import PhotosUI
import Supabase
import Auth

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var authManager: AuthManager

    // ProfileManager pour sauvegarder le profil
    @State private var profileManager: ProfileManager?

    // État de l'onboarding
    @State private var currentStep: Int = 0
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var birthDate: Date = Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date()
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var profilePhoto: Data?

    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var onboardingCompleted: Bool = false

    // MARK: - Body

    var body: some View {
        ZStack {
            if onboardingCompleted {
                // ✅ Onboarding terminé, afficher l'app principale
                MainTabView()
                    .transition(.opacity)
            } else {
                // 📋 Afficher les étapes de l'onboarding
                onboardingSteps
            }
        }
        .onAppear {
            // Initialiser le ProfileManager
            if profileManager == nil {
                profileManager = ProfileManager(modelContext: modelContext)
            }

            // Pré-remplir avec les données OAuth si disponibles
            if let user = authManager.currentUser {
                if let fullName = user.fullName {
                    let components = fullName.components(separatedBy: " ")
                    firstName = components.first ?? ""
                    lastName = components.dropFirst().joined(separator: " ")
                }
            }
        }
    }

    // MARK: - Onboarding Steps

    private var onboardingSteps: some View {
        ZStack {
            // Background gradient
            MomentsTheme.diagonalGradient
                .ignoresSafeArea()
                .opacity(0.1)

            VStack(spacing: 0) {
                // Indicateur de progression
                progressIndicator
                    .padding(.top, 60)
                    .padding(.horizontal, 24)

                // Contenu de l'étape actuelle
                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    profileStep.tag(1)
                    photoStep.tag(2)
                    finalizationStep.tag(3)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)

                // Boutons de navigation
                navigationButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
    }

    // MARK: - Progress Indicator

    private var progressIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<4) { index in
                if index <= currentStep {
                    Capsule()
                        .fill(MomentsTheme.primaryGradient)
                        .frame(height: 4)
                } else {
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                }
            }
        }
    }

    // MARK: - Step 1: Welcome

    private var welcomeStep: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "heart.circle.fill")
                .font(.system(size: 100))
                .gradientIcon()

            Text("Bienvenue sur Moments")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(MomentsTheme.primaryGradient)
                .multilineTextAlignment(.center)

            VStack(spacing: 16) {
                FeatureRow(icon: "gift.fill", title: "Gérez vos événements", description: "Anniversaires, mariages, et plus encore")
                FeatureRow(icon: "person.3.fill", title: "Invitez vos proches", description: "Partagez vos moments importants")
                FeatureRow(icon: "heart.fill", title: "Créez des wishlists", description: "Partagez vos idées cadeaux")
                FeatureRow(icon: "dollarsign.circle.fill", title: "Cagnottes collaboratives", description: "Offrez ensemble des cadeaux")
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    // MARK: - Step 2: Profile

    private var profileStep: some View {
        ScrollView {
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 20)

                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 80))
                    .gradientIcon()

                Text("Créez votre profil")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(MomentsTheme.primaryGradient)

                Text("Ces informations nous aideront à personnaliser votre expérience")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                // Formulaire
                VStack(spacing: 16) {
                    // Prénom
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Prénom")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundStyle(MomentsTheme.primaryGradient)
                            TextField("Votre prénom", text: $firstName)
                                .textContentType(.givenName)
                                .autocapitalization(.words)
                        }
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
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: "person.fill")
                                .foregroundStyle(MomentsTheme.primaryGradient)
                            TextField("Votre nom", text: $lastName)
                                .textContentType(.familyName)
                                .autocapitalization(.words)
                        }
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
                            .foregroundColor(.secondary)

                        DatePicker("", selection: $birthDate, displayedComponents: .date)
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
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
    }

    // MARK: - Step 3: Photo

    private var photoStep: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "camera.circle.fill")
                .font(.system(size: 80))
                .gradientIcon()

            Text("Photo de profil")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(MomentsTheme.primaryGradient)

            Text("Ajoutez une photo pour personnaliser votre profil (optionnel)")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            // Photo picker
            VStack(spacing: 16) {
                if let photoData = profilePhoto,
                   let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(MomentsTheme.primaryGradient, lineWidth: 3)
                        )
                } else {
                    Circle()
                        .fill(MomentsTheme.primaryGradient.opacity(0.2))
                        .frame(width: 150, height: 150)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(MomentsTheme.primaryGradient)
                        )
                }

                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Text(profilePhoto == nil ? "Choisir une photo" : "Changer la photo")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(MomentsTheme.primaryGradient)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 24)
            }

            Spacer()
        }
        .onChange(of: selectedPhoto) { _, newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self) {
                    profilePhoto = data
                }
            }
        }
    }

    // MARK: - Step 4: Finalization

    private var finalizationStep: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 100))
                .gradientIcon()

            Text("Tout est prêt !")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(MomentsTheme.primaryGradient)

            Text("Vous pouvez maintenant profiter de toutes les fonctionnalités de Moments")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            if let errorMessage = errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 24)
            }

            Spacer()
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        HStack(spacing: 16) {
            // Bouton Précédent
            if currentStep > 0 {
                Button {
                    withAnimation {
                        currentStep -= 1
                    }
                } label: {
                    Text("Précédent")
                        .font(.headline)
                        .foregroundColor(MomentsTheme.primaryPurple)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(MomentsTheme.primaryPurple, lineWidth: 2)
                        )
                }
                .disabled(isLoading)
            }

            // Bouton Suivant / Terminer
            Button {
                handleNextButton()
            } label: {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(currentStep < 3 ? "Suivant" : "Terminer")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(MomentsTheme.PrimaryButtonStyle())
            .disabled(!canProceed || isLoading)
            .opacity(canProceed ? 1.0 : 0.6)
        }
    }

    // MARK: - Computed Properties

    /// Détermine si l'utilisateur peut passer à l'étape suivante
    private var canProceed: Bool {
        switch currentStep {
        case 0: return true // Écran de bienvenue
        case 1: return !firstName.isEmpty && !lastName.isEmpty // Profil
        case 2: return true // Photo (optionnelle)
        case 3: return true // Finalisation
        default: return false
        }
    }

    // MARK: - Methods

    /// Gère l'action du bouton Suivant/Terminer
    private func handleNextButton() {
        if currentStep < 3 {
            // Passer à l'étape suivante
            withAnimation {
                currentStep += 1
            }
        } else {
            // Terminer l'onboarding
            completeOnboarding()
        }
    }

    /// Finalise l'onboarding et sauvegarde le profil
    private func completeOnboarding() {
        guard let manager = profileManager else {
            errorMessage = "ProfileManager non initialisé"
            return
        }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                // ✅ Récupérer le profil existant (créé automatiquement lors de l'OAuth)
                guard let existingProfile = await manager.getLocalProfile() else {
                    throw ProfileError.profileNotFound
                }

                // ✅ Mettre à jour le profil existant avec les données de l'onboarding
                existingProfile.firstName = firstName
                existingProfile.lastName = lastName
                existingProfile.birthDate = birthDate
                existingProfile.profilePhotoData = profilePhoto
                existingProfile.onboardingCompleted = true
                existingProfile.updatedAt = Date()

                // Synchroniser avec Supabase
                try await manager.updateProfile(existingProfile)

                // Upload photo si présente
                if let photoData = profilePhoto {
                    try await manager.uploadProfilePhoto(photoData, for: existingProfile)
                }

                // ✅ Mettre à jour AuthManager
                await authManager.loadUserFromSupabase()

                await MainActor.run {
                    isLoading = false
                    withAnimation {
                        onboardingCompleted = true
                    }
                    print("✅ Onboarding terminé avec succès")
                }

            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Erreur: \(error.localizedDescription)"
                    print("❌ Erreur completeOnboarding: \(error)")
                }
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(MomentsTheme.primaryGradient)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    OnboardingView()
        .environmentObject(AuthManager.shared)
        .modelContainer(for: [UserProfile.self], inMemory: true)
}
