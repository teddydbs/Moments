//
//  ContactRowView.swift
//  Moments
//
//  Vue en ligne pour afficher un contact (anniversaire)
//

import SwiftUI
import SwiftData

struct ContactRowView: View {
    let contact: Contact

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: contact.birthDate)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Photo ou initiales
            if let photoData = contact.photo,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                ZStack {
                    Circle()
                        .fill(MomentsTheme.primaryGradient.opacity(0.15))
                        .frame(width: 60, height: 60)

                    Text(contact.initials)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .gradientIcon()
                }
            }

            // Informations
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(contact.fullName)
                        .font(.headline)

                    if contact.isBirthdayToday {
                        Text("AUJOURD'HUI !")
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

                HStack(spacing: 8) {
                    Label(formattedDate, systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .foregroundColor(.secondary)
                    Text("\(contact.age) ans")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Badge jours restants
            if !contact.isBirthdayToday {
                VStack(spacing: 4) {
                    Text("\(contact.daysUntilBirthday)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(MomentsTheme.primaryGradient)

                    Text(contact.daysUntilBirthday <= 1 ? "jour" : "jours")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else {
                Image(systemName: "gift.fill")
                    .font(.title)
                    .gradientIcon()
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
    @Previewable @State var contact = Contact.preview

    ContactRowView(contact: contact)
        .modelContainer(for: [Contact.self])
        .padding()
}
