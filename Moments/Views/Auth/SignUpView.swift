//
//  SignUpView.swift
//  Moments
//
//  Vue d'inscription avec design cohérent au thème
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showingPassword: Bool = false
    @State private var showingConfirmPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var acceptedTerms: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                MomentsTheme.diagonalGradient
                    .ignoresSafeArea()
                    .opacity(0.1)

                ScrollView {
                    VStack(spacing: 30) {
                        Spacer()
                            .frame(height: 20)

                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "person.crop.circle.fill.badge.plus")
                                .font(.system(size: 60))
                                .gradientIcon()

                            Text("Créer un compte")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(MomentsTheme.primaryGradient)

                            Text("Rejoignez Moments et ne manquez plus aucun événement important")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.bottom, 10)

                        // Formulaire d'inscription
                        VStack(spacing: 16) {
                            // Nom
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Nom complet")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                HStack {
                                    Image(systemName: "person.fill")
                                        .foregroundStyle(MomentsTheme.primaryGradient)
                                    TextField("Votre nom", text: $name)
                                        .textContentType(.name)
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

                            // Email
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundStyle(MomentsTheme.primaryGradient)
                                    TextField("votre@email.com", text: $email)
                                        .textContentType(.emailAddress)
                                        .autocapitalization(.none)
                                        .keyboardType(.emailAddress)
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(MomentsTheme.primaryGradient, lineWidth: 1)
                                )
                            }

                            // Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Mot de passe")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(MomentsTheme.primaryGradient)

                                    if showingPassword {
                                        TextField("Au moins 6 caractères", text: $password)
                                            .textContentType(.newPassword)
                                    } else {
                                        SecureField("Au moins 6 caractères", text: $password)
                                            .textContentType(.newPassword)
                                    }

                                    Button {
                                        showingPassword.toggle()
                                    } label: {
                                        Image(systemName: showingPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(MomentsTheme.primaryGradient, lineWidth: 1)
                                )

                                // Password strength indicator
                                if !password.isEmpty {
                                    HStack(spacing: 4) {
                                        ForEach(0..<3) { index in
                                            Rectangle()
                                                .fill(passwordStrength > index ? strengthColor : Color.gray.opacity(0.3))
                                                .frame(height: 4)
                                        }
                                    }
                                    .frame(maxWidth: .infinity)
                                    .animation(.easeInOut, value: passwordStrength)

                                    Text(passwordStrengthText)
                                        .font(.caption)
                                        .foregroundColor(strengthColor)
                                }
                            }

                            // Confirm Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirmer le mot de passe")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(MomentsTheme.primaryGradient)

                                    if showingConfirmPassword {
                                        TextField("Retapez votre mot de passe", text: $confirmPassword)
                                            .textContentType(.newPassword)
                                    } else {
                                        SecureField("Retapez votre mot de passe", text: $confirmPassword)
                                            .textContentType(.newPassword)
                                    }

                                    Button {
                                        showingConfirmPassword.toggle()
                                    } label: {
                                        Image(systemName: showingConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.systemBackground))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            !confirmPassword.isEmpty && password != confirmPassword ?
                                            Color.red : MomentsTheme.primaryPurple,
                                            lineWidth: 1
                                        )
                                )

                                if !confirmPassword.isEmpty && password != confirmPassword {
                                    Label("Les mots de passe ne correspondent pas", systemImage: "xmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                }
                            }

                            // Terms and conditions
                            Toggle(isOn: $acceptedTerms) {
                                HStack(spacing: 4) {
                                    Text("J'accepte les")
                                        .font(.caption)
                                    Text("conditions d'utilisation")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(MomentsTheme.primaryGradient)
                                }
                            }
                            .tint(MomentsTheme.primaryPurple)

                            // Error message
                            if let errorMessage = errorMessage {
                                Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                        .padding(.horizontal, 24)

                        // Bouton d'inscription
                        VStack(spacing: 16) {
                            Button {
                                signUp()
                            } label: {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Créer mon compte")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(MomentsTheme.PrimaryButtonStyle())
                            .disabled(!isFormValid || isLoading)
                            .opacity(isFormValid ? 1.0 : 0.6)
                            .padding(.horizontal, 24)

                            // Already have account
                            Button {
                                dismiss()
                            } label: {
                                HStack(spacing: 4) {
                                    Text("Déjà un compte ?")
                                        .foregroundColor(.secondary)
                                    Text("Se connecter")
                                        .fontWeight(.semibold)
                                        .foregroundStyle(MomentsTheme.primaryGradient)
                                }
                                .font(.subheadline)
                            }
                        }

                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        password.count >= 6 &&
        password == confirmPassword &&
        acceptedTerms
    }

    private var passwordStrength: Int {
        let length = password.count
        let hasNumbers = password.rangeOfCharacter(from: .decimalDigits) != nil
        let hasSpecialChars = password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:,.<>?")) != nil

        if length < 6 { return 0 }
        if length < 8 && !hasNumbers { return 1 }
        if length >= 8 && (hasNumbers || hasSpecialChars) { return 2 }
        if length >= 10 && hasNumbers && hasSpecialChars { return 3 }
        return 1
    }

    private var passwordStrengthText: String {
        switch passwordStrength {
        case 0: return "Trop court"
        case 1: return "Faible"
        case 2: return "Moyen"
        case 3: return "Fort"
        default: return ""
        }
    }

    private var strengthColor: Color {
        switch passwordStrength {
        case 0: return .red
        case 1: return .orange
        case 2: return .yellow
        case 3: return .green
        default: return .gray
        }
    }

    // MARK: - Methods

    private func signUp() {
        isLoading = true
        errorMessage = nil

        // Simulation d'un délai réseau
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false

            // Validation
            guard isFormValid else {
                errorMessage = "Veuillez remplir tous les champs correctement"
                return
            }

            // Utiliser AuthManager pour l'inscription
            let success = authManager.signUp(name: name, email: email, password: password)

            if success {
                print("✅ Inscription simulée avec succès:")
                print("   Nom: \(name)")
                print("   Email: \(email)")
                // L'authentification réussie déclenche automatiquement la navigation vers MainTabView
                dismiss()
            } else {
                errorMessage = "Erreur lors de l'inscription"
            }
        }
    }
}

#Preview {
    SignUpView()
}
