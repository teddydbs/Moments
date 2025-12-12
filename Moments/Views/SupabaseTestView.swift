//
//  SupabaseTestView.swift
//  Moments
//
//  Vue de test pour Supabase
//

import SwiftUI

struct SupabaseTestView: View {
    @StateObject private var tester = SupabaseQuickTest.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Status
                VStack(spacing: 12) {
                    Image(systemName: tester.isConnected ? "checkmark.circle.fill" : "antenna.radiowaves.left.and.right")
                        .font(.system(size: 60))
                        .foregroundColor(tester.isConnected ? .green : .orange)

                    Text(tester.testMessage)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()

                // Boutons de test
                VStack(spacing: 16) {
                    Button {
                        Task {
                            await tester.testConnection()
                        }
                    } label: {
                        Label("Tester la connexion", systemImage: "bolt.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(tester.isConnected)

                    if tester.isConnected {
                        Button {
                            Task {
                                do {
                                    try await tester.createTestEvent()
                                } catch {
                                    print("❌ Erreur: \(error)")
                                }
                            }
                        } label: {
                            Label("Créer un événement de test", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()

                Spacer()

                // Instructions
                VStack(alignment: .leading, spacing: 8) {
                    Text("📝 Instructions:")
                        .font(.headline)

                    Text("1. Exécute le script SQL dans Supabase")
                    Text("2. Crée les buckets Storage")
                    Text("3. Clique sur 'Tester la connexion'")
                    Text("4. Vérifie tes données dans le Dashboard")
                }
                .font(.caption)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding()
            }
            .navigationTitle("Test Supabase")
        }
    }
}

#Preview {
    SupabaseTestView()
}
