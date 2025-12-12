//
//  SettingsView.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var themeManager = ThemeManager.shared

    @State private var showingLogoutAlert = false
    @State private var showingProfile = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteConfirmationText = ""

    // MARK: - Delete Account

    /// Supprime définitivement le compte utilisateur et toutes ses données
    private func deleteAccount() async {
        do {
            // 1. Supprimer toutes les données Supabase
            try await authManager.deleteAccount()

            // 2. Déconnexion automatique
            await authManager.logout()

            // 3. Fermer les paramètres
            dismiss()
        } catch {
            print("❌ Erreur lors de la suppression du compte: \(error)")
            // TODO: Afficher une alert d'erreur à l'utilisateur
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("À propos") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Application")
                        Spacer()
                        Text("Moments")
                            .foregroundColor(.secondary)
                    }
                }

                Section("Notifications") {
                    NavigationLink {
                        NotificationSettingsView()
                    } label: {
                        HStack {
                            Image(systemName: "bell.fill")
                                .gradientIcon()
                                .frame(width: 30)
                            Text("Gérer les notifications")
                        }
                    }
                }

                // ✅ Section pour le choix du thème (clair/sombre/automatique)
                Section("Apparence") {
                    Picker("Thème", selection: $themeManager.currentMode) {
                        ForEach(AppThemeMode.allCases, id: \.self) { mode in
                            HStack {
                                Image(systemName: mode.icon)
                                Text(mode.rawValue)
                            }
                            .tag(mode)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Compte") {
                    if let user = authManager.currentUser {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.displayName)
                                .font(.headline)
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    Button {
                        showingProfile = true
                    } label: {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .gradientIcon()
                                .frame(width: 30)
                            Text("Modifier mon profil")
                                .foregroundColor(.primary)
                        }
                    }
                }

                Section("Données") {
                    Button {
                        // Action pour exporter les données
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .gradientIcon()
                                .frame(width: 30)
                            Text("Exporter mes données")
                                .foregroundColor(.primary)
                        }
                    }
                }

                Section("Aide et support") {
                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.gray)
                                .frame(width: 30)
                            Text("Aide et support")
                        }
                    }
                }

                Section("Informations légales") {
                    Link(destination: URL(string: "https://raw.githubusercontent.com/YOUR_USERNAME/Moments/main/docs/privacy-policy.md")!) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("Politique de confidentialité")
                        }
                    }

                    Link(destination: URL(string: "https://raw.githubusercontent.com/YOUR_USERNAME/Moments/main/docs/terms-of-service.md")!) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.blue)
                                .frame(width: 30)
                            Text("Conditions d'utilisation")
                        }
                    }
                }

                Section("Zone de danger") {
                    Button(role: .destructive) {
                        showingLogoutAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .frame(width: 30)
                            Text("Se déconnecter")
                        }
                    }

                    Button(role: .destructive) {
                        showingDeleteAccountAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                                .frame(width: 30)
                            Text("Supprimer mon compte")
                        }
                    }
                } footer: {
                    Text("La suppression de votre compte est définitive et irréversible. Toutes vos données seront supprimées sous 30 jours.")
                        .font(.caption)
                }
            }
            .navigationTitle("Paramètres")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .alert("Déconnexion", isPresented: $showingLogoutAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Se déconnecter", role: .destructive) {
                    Task {
                        await authManager.logout()
                        dismiss()
                    }
                }
            } message: {
                Text("Êtes-vous sûr de vouloir vous déconnecter ?")
            }
            .alert("Supprimer mon compte", isPresented: $showingDeleteAccountAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Continuer", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            } message: {
                Text("⚠️ Cette action est irréversible.\n\nToutes vos données seront définitivement supprimées :\n• Événements et invitations\n• Listes de cadeaux\n• Photos et fichiers\n• Profil utilisateur\n\nVoulez-vous vraiment supprimer votre compte ?")
            }
            .alert("Confirmation finale", isPresented: $showingDeleteConfirmation) {
                TextField("Tapez SUPPRIMER", text: $deleteConfirmationText)
                Button("Annuler", role: .cancel) {
                    deleteConfirmationText = ""
                }
                Button("Supprimer définitivement", role: .destructive) {
                    if deleteConfirmationText == "SUPPRIMER" {
                        Task {
                            await deleteAccount()
                        }
                    }
                    deleteConfirmationText = ""
                }
            } message: {
                Text("Pour confirmer la suppression, tapez SUPPRIMER en majuscules.")
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
        }
    }
}

struct NotificationSettingsView: View {
    var body: some View {
        Form {
            Section {
                Text("Les notifications sont programmées automatiquement pour chaque événement.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Section("Paramètres système") {
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Image(systemName: "gear")
                            .foregroundColor(.gray)
                        Text("Ouvrir les réglages iOS")
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
}
