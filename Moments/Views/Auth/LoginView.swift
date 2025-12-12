//
//  LoginView.swift
//  Moments
//
//  Vue de connexion avec design cohérent au thème
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var showingPassword: Bool = false
    @State private var isLoading: Bool = false
    @State private var showingSignUp: Bool = false
    @State private var showingForgotPassword: Bool = false
    @State private var errorMessage: String?

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
                            .frame(height: 40)

                        // Logo et titre
                        VStack(spacing: 16) {
                            Image(systemName: "heart.circle.fill")
                                .font(.system(size: 80))
                                .gradientIcon()

                            Text("Moments")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundStyle(MomentsTheme.primaryGradient)

                            Text("Ne manquez plus aucun moment important")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.bottom, 20)

                        // Formulaire de connexion
                        VStack(spacing: 16) {
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
                                        TextField("Votre mot de passe", text: $password)
                                            .textContentType(.password)
                                    } else {
                                        SecureField("Votre mot de passe", text: $password)
                                            .textContentType(.password)
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
                            }

                            // Forgot password
                            Button {
                                showingForgotPassword = true
                            } label: {
                                Text("Mot de passe oublié ?")
                                    .font(.subheadline)
                                    .foregroundStyle(MomentsTheme.primaryGradient)
                            }
                            .frame(maxWidth: .infinity, alignment: .trailing)

                            // Error message
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.horizontal, 24)

                        // Bouton de connexion
                        VStack(spacing: 16) {
                            Button {
                                login()
                            } label: {
                                if isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Se connecter")
                                        .font(.headline)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .buttonStyle(MomentsTheme.PrimaryButtonStyle())
                            .disabled(email.isEmpty || password.isEmpty || isLoading)
                            .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1.0)
                            .padding(.horizontal, 24)

                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(height: 1)
                                Text("ou")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 24)

                            // OAuth buttons
                            VStack(spacing: 12) {
                                // Google Sign In
                                Button {
                                    loginWithGoogle()
                                } label: {
                                    HStack {
                                        Image(systemName: "globe")
                                            .font(.title3)
                                        Text("Continuer avec Google")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .disabled(isLoading)

                                // Apple Sign In
                                Button {
                                    loginWithApple()
                                } label: {
                                    HStack {
                                        Image(systemName: "apple.logo")
                                            .font(.title3)
                                        Text("Continuer avec Apple")
                                            .font(.headline)
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.black)
                                    .cornerRadius(12)
                                }
                                .disabled(isLoading)
                            }
                            .padding(.horizontal, 24)

                            // Divider
                            HStack {
                                Rectangle()
                                    .fill(Color.secondary.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.horizontal, 24)
                            .padding(.top, 8)

                            // Sign up button
                            Button {
                                showingSignUp = true
                            } label: {
                                HStack(spacing: 4) {
                                    Text("Pas encore de compte ?")
                                        .foregroundColor(.secondary)
                                    Text("Créer un compte")
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
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
            .alert("Mot de passe oublié", isPresented: $showingForgotPassword) {
                Button("Annuler", role: .cancel) { }
                Button("Envoyer") {
                    // TODO: Envoyer email de récupération
                }
            } message: {
                Text("Un email de récupération sera envoyé à \(email.isEmpty ? "votre adresse" : email)")
            }
        }
    }

    private func login() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Connexion avec Supabase
                try await SupabaseManager.shared.signIn(email: email, password: password)

                // Charger les informations utilisateur
                await authManager.loadUserFromSupabase()

                await MainActor.run {
                    isLoading = false
                    print("✅ Connexion réussie avec Supabase: \(email)")
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Erreur de connexion: \(error.localizedDescription)"
                    print("❌ Erreur de connexion: \(error)")
                }
            }
        }
    }

    private func loginWithGoogle() {
        print("🔵 BOUTON GOOGLE CLIQUÉ !")
        isLoading = true
        errorMessage = nil

        Task {
            print("🔵 Task lancée pour OAuth Google")
            do {
                print("🔵 Appel de signInWithGoogle()...")
                try await SupabaseManager.shared.signInWithGoogle()

                // ✅ Charger les informations utilisateur depuis Supabase
                await authManager.loadUserFromSupabase()

                await MainActor.run {
                    isLoading = false
                    print("✅ Connexion Google réussie")
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Erreur OAuth: \(error.localizedDescription)"
                    print("❌ Erreur Google OAuth: \(error)")
                }
            }
        }
    }

    private func loginWithApple() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await SupabaseManager.shared.signInWithApple()

                // ✅ Charger les informations utilisateur depuis Supabase
                await authManager.loadUserFromSupabase()

                await MainActor.run {
                    isLoading = false
                    print("✅ Connexion Apple réussie")
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "OAuth Apple n'est pas encore configuré"
                    print("❌ Erreur Apple OAuth: \(error)")
                }
            }
        }
    }
}

#Preview {
    LoginView()
}
