//
//  InvitationManagementView.swift
//  Moments
//
//  Vue pour gérer les invitations d'un événement
//

import SwiftUI
import SwiftData

struct InvitationManagementView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let myEvent: MyEvent

    @State private var showingAddInvitation = false
    @State private var selectedInvitation: Invitation?

    // Invitations groupées par statut
    private var pendingInvitations: [Invitation] {
        myEvent.invitations?.filter { $0.status == .pending } ?? []
    }

    private var waitingApprovalInvitations: [Invitation] {
        myEvent.invitations?.filter { $0.status == .waitingApproval } ?? []
    }

    private var acceptedInvitations: [Invitation] {
        myEvent.invitations?.filter { $0.status == .accepted } ?? []
    }

    private var declinedInvitations: [Invitation] {
        myEvent.invitations?.filter { $0.status == .declined } ?? []
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                MomentsTheme.diagonalGradient
                    .ignoresSafeArea()
                    .opacity(0.03)

                if myEvent.totalInvitations == 0 {
                    emptyStateView
                } else {
                    invitationsList
                }
            }
            .navigationTitle("Invitations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddInvitation = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .gradientIcon()
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddInvitation) {
                AddEditInvitationView(myEvent: myEvent, invitation: nil)
            }
            .sheet(item: $selectedInvitation) { invitation in
                AddEditInvitationView(myEvent: myEvent, invitation: invitation)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 80))
                .gradientIcon()

            Text("Aucune invitation")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Invitez vos amis et famille\nà votre événement")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                showingAddInvitation = true
            } label: {
                Label("Inviter quelqu'un", systemImage: "plus.circle.fill")
            }
            .buttonStyle(MomentsTheme.PrimaryButtonStyle())
            .padding(.top)
        }
        .padding()
    }

    // MARK: - Invitations List

    private var invitationsList: some View {
        List {
            // Stats globales
            Section {
                HStack(spacing: 16) {
                    StatBadge(
                        count: myEvent.acceptedCount,
                        label: "Accepté\(myEvent.acceptedCount > 1 ? "s" : "")",
                        color: .green
                    )

                    StatBadge(
                        count: myEvent.pendingCount,
                        label: "En attente",
                        color: .orange
                    )

                    StatBadge(
                        count: myEvent.declinedCount,
                        label: "Refusé\(myEvent.declinedCount > 1 ? "s" : "")",
                        color: .red
                    )
                }
                .padding(.vertical, 8)
            }

            // En attente d'approbation (priorité)
            if !waitingApprovalInvitations.isEmpty {
                Section {
                    ForEach(waitingApprovalInvitations) { invitation in
                        InvitationManagementRowView(
                            invitation: invitation,
                            onApprove: { approveInvitation(invitation) },
                            onReject: { rejectInvitation(invitation) },
                            onEdit: { selectedInvitation = invitation },
                            onDelete: { deleteInvitation(invitation) }
                        )
                    }
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: "hourglass")
                            .foregroundStyle(MomentsTheme.primaryGradient)
                        Text("En attente d'approbation")
                            .textCase(.uppercase)
                            .fontWeight(.semibold)
                    }
                }
            }

            // Acceptés
            if !acceptedInvitations.isEmpty {
                Section {
                    ForEach(acceptedInvitations) { invitation in
                        InvitationManagementRowView(
                            invitation: invitation,
                            onEdit: { selectedInvitation = invitation },
                            onDelete: { deleteInvitation(invitation) }
                        )
                    }
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Acceptés (\(acceptedInvitations.count))")
                            .textCase(.uppercase)
                            .fontWeight(.semibold)
                    }
                }
            }

            // En attente de réponse
            if !pendingInvitations.isEmpty {
                Section {
                    ForEach(pendingInvitations) { invitation in
                        InvitationManagementRowView(
                            invitation: invitation,
                            onEdit: { selectedInvitation = invitation },
                            onDelete: { deleteInvitation(invitation) }
                        )
                    }
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        Text("En attente de réponse (\(pendingInvitations.count))")
                            .textCase(.uppercase)
                            .fontWeight(.semibold)
                    }
                }
            }

            // Refusés
            if !declinedInvitations.isEmpty {
                Section {
                    ForEach(declinedInvitations) { invitation in
                        InvitationManagementRowView(
                            invitation: invitation,
                            onEdit: { selectedInvitation = invitation },
                            onDelete: { deleteInvitation(invitation) }
                        )
                    }
                } header: {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Refusés (\(declinedInvitations.count))")
                            .textCase(.uppercase)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    // MARK: - Methods

    private func approveInvitation(_ invitation: Invitation) {
        invitation.approve()

        do {
            try modelContext.save()
            print("✅ Invitation approuvée")
        } catch {
            print("❌ Erreur: \(error)")
        }
    }

    private func rejectInvitation(_ invitation: Invitation) {
        invitation.reject()

        do {
            try modelContext.save()
            print("✅ Invitation rejetée")
        } catch {
            print("❌ Erreur: \(error)")
        }
    }

    private func deleteInvitation(_ invitation: Invitation) {
        modelContext.delete(invitation)

        do {
            try modelContext.save()
        } catch {
            print("❌ Erreur: \(error)")
        }
    }
}

// MARK: - Invitation Management Row

struct InvitationManagementRowView: View {
    let invitation: Invitation
    var onApprove: (() -> Void)? = nil
    var onReject: (() -> Void)? = nil
    var onEdit: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(invitation.guestName)
                        .font(.headline)

                    if let email = invitation.guestEmail {
                        Text(email)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if invitation.plusOnes > 0 {
                    Text("+\(invitation.plusOnes)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(MomentsTheme.primaryGradient.opacity(0.2))
                        )
                        .foregroundStyle(MomentsTheme.primaryGradient)
                }
            }

            // Message de l'invité si présent
            if let message = invitation.guestMessage, !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .italic()
                    .foregroundColor(.secondary)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray6))
                    )
            }

            // Actions pour demandes en attente d'approbation
            if invitation.status == .waitingApproval {
                HStack(spacing: 12) {
                    Button {
                        onApprove?()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark")
                            Text("Approuver")
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }

                    Button {
                        onReject?()
                    } label: {
                        HStack {
                            Image(systemName: "xmark")
                            Text("Refuser")
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if let onDelete = onDelete {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Supprimer", systemImage: "trash")
                }
            }

            if let onEdit = onEdit {
                Button {
                    onEdit()
                } label: {
                    Label("Modifier", systemImage: "pencil")
                }
                .tint(.orange)
            }
        }
    }
}

#Preview {
    @Previewable @State var event = MyEvent.preview

    InvitationManagementView(myEvent: event)
        .modelContainer(for: [MyEvent.self, Invitation.self])
}
