//
//  InvitationReceivedView.swift
//  Moments
//
//  Vue affichée quand un utilisateur clique sur un lien d'invitation
//  Permet d'accepter ou refuser l'invitation
//

import SwiftUI
import SwiftData

struct InvitationReceivedView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager

    let invitationToken: String

    @State private var invitation: RemoteInvitation?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var responseMessage = ""
    @State private var showingSuccessAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                MomentsTheme.diagonalGradient
                    .ignoresSafeArea()
                    .opacity(0.03)

                if isLoading {
                    loadingView
                } else if let error = errorMessage {
                    errorView(message: error)
                } else if let invitation = invitation {
                    invitationContent(invitation)
                }
            }
            .navigationTitle("Invitation reçue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadInvitation()
            }
            .alert("Invitation acceptée !", isPresented: $showingSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Vous avez accepté l'invitation. Vous retrouverez cet événement dans l'onglet Anniversaires.")
            }
        }
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Chargement de l'invitation...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Error View

    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("Erreur")
                .font(.title)
                .fontWeight(.bold)

            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button {
                Task {
                    await loadInvitation()
                }
            } label: {
                Label("Réessayer", systemImage: "arrow.clockwise")
            }
            .buttonStyle(MomentsTheme.PrimaryButtonStyle())
        }
        .padding()
    }

    // MARK: - Invitation Content

    @ViewBuilder
    private func invitationContent(_ invitation: RemoteInvitation) -> some View {
        ScrollView {
            VStack(spacing: 24) {
                // En-tête avec icône
                VStack(spacing: 12) {
                    Image(systemName: "envelope.open.fill")
                        .font(.system(size: 80))
                        .gradientIcon()

                    Text("Vous êtes invité !")
                        .font(.title)
                        .fontWeight(.bold)
                }
                .padding(.top, 32)

                // Informations de l'événement
                VStack(alignment: .leading, spacing: 16) {
                    // TODO: Récupérer le titre de l'événement depuis Supabase
                    infoRow(icon: "calendar", label: "Événement", value: "Chargement...")

                    infoRow(icon: "person.fill", label: "Invité par", value: invitation.guestName)

                    if let email = invitation.guestEmail {
                        infoRow(icon: "envelope.fill", label: "Email", value: email)
                    }

                    infoRow(icon: "clock.fill", label: "Envoyée le", value: formatDate(invitation.sentAt))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                )

                // Message optionnel
                VStack(alignment: .leading, spacing: 12) {
                    Text("Votre réponse (optionnel)")
                        .font(.headline)

                    TextField("Laissez un message...", text: $responseMessage, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
                )

                // Boutons d'action
                VStack(spacing: 12) {
                    Button {
                        Task {
                            await acceptInvitation()
                        }
                    } label: {
                        Label("Accepter l'invitation", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(MomentsTheme.PrimaryButtonStyle())

                    Button(role: .destructive) {
                        Task {
                            await declineInvitation()
                        }
                    } label: {
                        Label("Refuser", systemImage: "xmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }

    // MARK: - Helper Views

    private func infoRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(MomentsTheme.primaryGradient)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(value)
                    .font(.body)
                    .fontWeight(.medium)
            }

            Spacer()
        }
    }

    // MARK: - Methods

    private func loadInvitation() async {
        isLoading = true
        errorMessage = nil

        let invitationManager = InvitationManager(modelContext: modelContext)

        do {
            let remoteInvitation = try await invitationManager.fetchInvitation(by: invitationToken)
            self.invitation = remoteInvitation
            isLoading = false

        } catch {
            errorMessage = "Impossible de charger l'invitation. Vérifiez que le lien est valide."
            isLoading = false
            print("❌ Erreur lors du chargement de l'invitation: \(error)")
        }
    }

    private func acceptInvitation() async {
        guard let invitation = invitation else { return }

        let invitationManager = InvitationManager(modelContext: modelContext)

        do {
            // Créer une invitation locale depuis la remote
            // TODO: Récupérer l'événement correspondant
            let localInvitation = invitation.toLocalInvitation(myEvent: nil)
            localInvitation.inviteeUserId = authManager.currentUser?.id.flatMap { UUID(uuidString: $0) }

            try await invitationManager.acceptInvitation(
                localInvitation,
                message: responseMessage.isEmpty ? nil : responseMessage
            )

            showingSuccessAlert = true

        } catch {
            errorMessage = "Impossible d'accepter l'invitation. Veuillez réessayer."
            print("❌ Erreur lors de l'acceptation: \(error)")
        }
    }

    private func declineInvitation() async {
        guard let invitation = invitation else { return }

        let invitationManager = InvitationManager(modelContext: modelContext)

        do {
            let localInvitation = invitation.toLocalInvitation(myEvent: nil)
            localInvitation.inviteeUserId = authManager.currentUser?.id.flatMap { UUID(uuidString: $0) }

            try await invitationManager.declineInvitation(
                localInvitation,
                message: responseMessage.isEmpty ? nil : responseMessage
            )

            // Fermer la vue après le refus
            dismiss()

        } catch {
            errorMessage = "Impossible de refuser l'invitation. Veuillez réessayer."
            print("❌ Erreur lors du refus: \(error)")
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
}

#Preview {
    InvitationReceivedView(invitationToken: "test_token_123")
        .environmentObject(AuthManager.shared)
        .modelContainer(for: [Invitation.self, MyEvent.self])
}
