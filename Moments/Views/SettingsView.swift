//
//  SettingsView.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

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
