//
//  ParticipantsManagementView.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import SwiftUI
import SwiftData
import Contacts

struct ParticipantsManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let event: Event

    @State private var showingAddParticipant = false
    @State private var showingContactPicker = false
    @State private var newParticipantName = ""

    var body: some View {
        NavigationStack {
            List {
                if event.participants.isEmpty {
                    ContentUnavailableView(
                        "Aucun participant",
                        systemImage: "person.2",
                        description: Text("Ajoutez des participants à cet événement")
                    )
                } else {
                    ForEach(event.participants) { participant in
                        HStack {
                            Image(systemName: participant.source.icon)
                                .foregroundColor(.blue)
                                .frame(width: 30)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(participant.name)
                                    .font(.headline)

                                Text(participant.source.rawValue)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .onDelete(perform: deleteParticipants)
                }

                Section {
                    Button {
                        showingAddParticipant = true
                    } label: {
                        Label("Ajouter manuellement", systemImage: "person.badge.plus")
                    }

                    Button {
                        requestContactsAccess()
                    } label: {
                        Label("Importer des contacts", systemImage: "person.crop.circle.badge.plus")
                    }

                    Button {
                        // Futur: intégration Facebook
                    } label: {
                        HStack {
                            Label("Depuis Facebook", systemImage: "f.circle.fill")
                            Spacer()
                            Text("Bientôt")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(true)

                    Button {
                        // Futur: intégration Instagram
                    } label: {
                        HStack {
                            Label("Depuis Instagram", systemImage: "camera.circle.fill")
                            Spacer()
                            Text("Bientôt")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .disabled(true)
                }
            }
            .navigationTitle("Participants")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .alert("Ajouter un participant", isPresented: $showingAddParticipant) {
                TextField("Nom du participant", text: $newParticipantName)
                Button("Annuler", role: .cancel) {
                    newParticipantName = ""
                }
                Button("Ajouter") {
                    addManualParticipant()
                }
            } message: {
                Text("Entrez le nom de la personne à ajouter")
            }
        }
    }

    private func addManualParticipant() {
        guard !newParticipantName.isEmpty else { return }

        let participant = Participant(
            name: newParticipantName,
            source: .manual
        )
        participant.event = event
        event.participants.append(participant)
        modelContext.insert(participant)

        newParticipantName = ""
    }

    private func deleteParticipants(at offsets: IndexSet) {
        for index in offsets {
            let participant = event.participants[index]
            modelContext.delete(participant)
        }
    }

    private func requestContactsAccess() {
        let store = CNContactStore()

        store.requestAccess(for: .contacts) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    showingContactPicker = true
                }
            } else {
                // Gérer le refus d'accès
                print("Accès aux contacts refusé")
            }
        }
    }
}
