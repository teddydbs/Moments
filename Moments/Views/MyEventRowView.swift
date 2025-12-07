//
//  MyEventRowView.swift
//  Moments
//
//  Vue en ligne pour afficher un événement
//

import SwiftUI
import SwiftData

struct MyEventRowView: View {
    let event: MyEvent

    private var isToday: Bool {
        Calendar.current.isDateInToday(event.date)
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: event.date)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Icône du type d'événement
            ZStack {
                Circle()
                    .fill(MomentsTheme.primaryGradient.opacity(0.15))
                    .frame(width: 60, height: 60)

                Image(systemName: event.type.icon)
                    .font(.title2)
                    .gradientIcon()
            }

            // Informations
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(event.title)
                        .font(.headline)

                    if isToday {
                        Text("AUJOURD'HUI")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(MomentsTheme.primaryGradient)
                            )
                    }
                }

                Text(event.type.rawValue)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    Label(formattedDate, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if event.totalInvitations > 0 {
                        Label("\(event.acceptedCount)/\(event.totalInvitations)", systemImage: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Badge jours restants
            if event.daysUntilEvent >= 0 {
                VStack(spacing: 4) {
                    Text("\(event.daysUntilEvent)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(MomentsTheme.primaryGradient)

                    Text(event.daysUntilEvent <= 1 ? "jour" : "jours")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

#Preview {
    @Previewable @State var event = MyEvent.preview

    MyEventRowView(event: event)
        .modelContainer(for: [MyEvent.self])
        .padding()
}
