//
//  EventRowView.swift
//  Moments
//
//  Created by Teddy Dubois on 04/12/2025.
//

import SwiftUI
import SwiftData

struct EventRowView: View {
    let event: Event

    private var daysUntil: Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let eventDate = calendar.startOfDay(for: event.date)
        let components = calendar.dateComponents([.day], from: today, to: eventDate)
        return components.day ?? 0
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
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

    private var countdownText: String {
        if daysUntil == 0 {
            return "Aujourd'hui !"
        } else if daysUntil == 1 {
            return "Demain"
        } else if daysUntil < 0 {
            return "Passé"
        } else {
            return "Dans \(daysUntil) jours"
        }
    }

    private var countdownColor: Color {
        if daysUntil == 0 {
            return .green
        } else if daysUntil == 1 {
            return .orange
        } else if daysUntil < 0 {
            return .gray
        } else {
            return MomentsTheme.primaryPurple
        }
    }

    var body: some View {
        HStack(spacing: 15) {
            // Event image or category icon
            if let imageData = event.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(categoryColor.opacity(0.5), lineWidth: 2)
                    )
            } else {
                // Category icon fallback
                Text(event.category.icon)
                    .font(.system(size: 40))
                    .frame(width: 60, height: 60)
                    .background(categoryColor.opacity(0.2))
                    .clipShape(Circle())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 6) {
                    Text(event.category.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    if event.isRecurring {
                        Image(systemName: "repeat")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text(dateText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let time = event.time {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(timeText(time))
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                if let location = event.location {
                    HStack(spacing: 4) {
                        Image(systemName: "mappin")
                            .font(.caption2)
                        Text(location)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(countdownText)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(countdownColor)

                Image(systemName: "bell.fill")
                    .font(.caption)
                    .foregroundStyle(MomentsTheme.primaryGradient)
            }
        }
        .padding(.vertical, 8)
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
