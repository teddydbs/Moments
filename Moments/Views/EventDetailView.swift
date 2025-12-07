//
//  EventDetailView.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import SwiftUI
import SwiftData

struct EventDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let event: Event

    @State private var showingParticipantsView = false
    @State private var showingGiftIdeasView = false
    @State private var showingEditEvent = false

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: event.date)
    }

    private func timeText(_ time: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: time)
    }

    private var daysUntil: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let eventDate = calendar.startOfDay(for: event.date)
        let components = calendar.dateComponents([.day], from: today, to: eventDate)
        return components.day ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Image de l'événement
                    if let imageData = event.imageData,
                       let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 250)
                            .clipped()
                    } else {
                        ZStack {
                            Rectangle()
                                .fill(categoryColor.opacity(0.2))
                                .frame(height: 250)

                            Text(event.category.icon)
                                .font(.system(size: 100))
                        }
                    }

                    VStack(spacing: 16) {
                        // Titre et catégorie
                        VStack(spacing: 8) {
                            Text(event.title)
                                .font(.title)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)

                            HStack {
                                Text(event.category.icon)
                                Text(event.category.rawValue)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(categoryColor.opacity(0.2))
                            .cornerRadius(8)
                        }

                        // Date, heure et compte à rebours
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "calendar")
                                    .foregroundColor(categoryColor)
                                Text(dateText)
                                    .font(.headline)
                            }

                            if let time = event.time {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(categoryColor)
                                    Text(timeText(time))
                                        .font(.subheadline)
                                }
                            }

                            if daysUntil >= 0 {
                                Text(daysUntil == 0 ? "Aujourd'hui !" : "Dans \(daysUntil) jour\(daysUntil > 1 ? "s" : "")")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        // Lieu
                        if let location = event.location {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "mappin.circle.fill")
                                        .foregroundColor(categoryColor)
                                    Text("Lieu")
                                        .font(.headline)
                                }

                                Text(location)
                                    .font(.body)

                                if let address = event.locationAddress, !address.isEmpty {
                                    Text(address)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Button {
                                    // TODO: Ouvrir dans Plans
                                } label: {
                                    Label("Ouvrir dans Plans", systemImage: "map")
                                        .font(.subheadline)
                                }
                                .buttonStyle(MomentsTheme.PrimaryButtonStyle())
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }

                        // Participants
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .foregroundColor(categoryColor)
                                Text("Participants")
                                    .font(.headline)
                                Spacer()
                                Text("\(event.participants.count)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Button {
                                showingParticipantsView = true
                            } label: {
                                HStack {
                                    Text(event.participants.isEmpty ? "Ajouter des participants" : "Gérer les participants")
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                }
                                .foregroundColor(.primary)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        // Cagnotte et idées cadeaux
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "gift.fill")
                                    .foregroundColor(categoryColor)
                                Text("Cagnotte")
                                    .font(.headline)
                                Spacer()
                                Text(event.hasGiftPool ? "Activée" : "Désactivée")
                                    .font(.subheadline)
                                    .foregroundColor(event.hasGiftPool ? .green : .secondary)
                            }

                            if event.hasGiftPool {
                                Button {
                                    showingGiftIdeasView = true
                                } label: {
                                    HStack {
                                        Text(event.giftIdeas.isEmpty ? "Proposer une idée cadeau" : "Voir les idées cadeaux (\(event.giftIdeas.count))")
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                    }
                                    .foregroundColor(.primary)
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)

                        // Notes
                        if !event.notes.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "note.text")
                                        .foregroundColor(categoryColor)
                                    Text("Notes")
                                        .font(.headline)
                                }

                                Text(event.notes)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditEvent = true
                    } label: {
                        Text("Modifier")
                    }
                }
            }
            .sheet(isPresented: $showingParticipantsView) {
                ParticipantsManagementView(event: event)
            }
            .sheet(isPresented: $showingGiftIdeasView) {
                GiftIdeasManagementView(event: event)
            }
            .sheet(isPresented: $showingEditEvent) {
                AddEditEventView(event: event, defaultCategory: nil)
            }
        }
    }

    private var categoryColor: Color {
        switch event.category.color {
        case "pink": return MomentsTheme.primaryPink
        case "purple": return MomentsTheme.primaryPurple
        case "blue": return .blue
        case "orange": return .orange
        case "mint": return .mint
        case "yellow": return .yellow
        default: return .gray
        }
    }
}
