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

    @State private var showingLogoutAlert = false
    @State private var showingProfile = false

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

                Section("Compte") {
                    if let user = authManager.currentUser {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(user.name)
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

                Section {
                    Link(destination: URL(string: "https://github.com")!) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.gray)
                                .frame(width: 30)
                            Text("Aide et support")
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showingLogoutAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .frame(width: 30)
                            Text("Se déconnecter")
                        }
                    }
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
                    authManager.logout()
                    dismiss()
                }
            } message: {
                Text("Êtes-vous sûr de vouloir vous déconnecter ?")
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
