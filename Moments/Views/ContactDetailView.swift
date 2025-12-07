//
//  ContactDetailView.swift
//  Moments
//
//  Vue détail d'un contact avec sa wishlist
//

import SwiftUI
import SwiftData

struct ContactDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let contact: Contact

    @State private var showingEditContact = false
    @State private var showingAddGift = false

    private var ageText: String {
        "\(contact.age) ans"
    }

    private var nextBirthdayText: String {
        let days = contact.daysUntilBirthday

        if days == 0 {
            return "C'est aujourd'hui ! 🎉"
        } else if days == 1 {
            return "C'est demain !"
        } else {
            return "Dans \(days) jours"
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // En-tête avec photo
                    VStack(spacing: 16) {
                        // Photo
                        if let photoData = contact.photo,
                           let uiImage = UIImage(data: photoData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(MomentsTheme.primaryGradient, lineWidth: 4)
                                )
                        } else {
                            Circle()
                                .fill(MomentsTheme.primaryGradient.opacity(0.2))
                                .frame(width: 120, height: 120)
                                .overlay(
                                    Text(contact.firstName.prefix(1).uppercased())
                                        .font(.system(size: 50))
                                        .fontWeight(.bold)
                                        .foregroundStyle(MomentsTheme.primaryGradient)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(MomentsTheme.primaryGradient, lineWidth: 4)
                                )
                        }

                        // Nom
                        Text(contact.fullName)
                            .font(.title)
                            .fontWeight(.bold)

                        // Âge
                        Text(ageText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // Carte anniversaire
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "gift.fill")
                                .font(.title2)
                                .gradientIcon()

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Prochain anniversaire")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text(dateFormatter.string(from: contact.nextBirthday))
                                    .font(.headline)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text(nextBirthdayText)
                                    .font(.headline)
                                    .foregroundStyle(MomentsTheme.primaryGradient)
                            }
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    )
                    .padding(.horizontal)

                    // Informations de contact
                    if contact.email != nil || contact.phoneNumber != nil {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Contact")
                                .font(.headline)
                                .padding(.horizontal)

                            VStack(spacing: 0) {
                                if let email = contact.email {
                                    HStack(spacing: 12) {
                                        Image(systemName: "envelope.fill")
                                            .frame(width: 24)
                                            .foregroundStyle(MomentsTheme.primaryGradient)

                                        Text(email)
                                            .font(.body)

                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                }

                                if let phoneNumber = contact.phoneNumber {
                                    Divider()

                                    HStack(spacing: 12) {
                                        Image(systemName: "phone.fill")
                                            .frame(width: 24)
                                            .foregroundStyle(MomentsTheme.primaryGradient)

                                        Text(phoneNumber)
                                            .font(.body)

                                        Spacer()
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                    }

                    // Notes
                    if let notes = contact.notes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Notes")
                                .font(.headline)
                                .padding(.horizontal)

                            Text(notes)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                                .padding(.horizontal)
                        }
                    }

                    // Wishlist du contact
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Sa wishlist")
                                .font(.headline)

                            Spacer()

                            Text("\(contact.wishlistItems?.count ?? 0) \(contact.wishlistItems?.count == 1 ? "cadeau" : "cadeaux")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)

                        if let wishlistItems = contact.wishlistItems, !wishlistItems.isEmpty {
                            VStack(spacing: 12) {
                                ForEach(wishlistItems) { item in
                                    WishlistItemRowView(item: item)
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 12) {
                                Image(systemName: "gift")
                                    .font(.system(size: 40))
                                    .foregroundStyle(MomentsTheme.primaryGradient.opacity(0.5))

                                Text("\(contact.firstName) n'a pas encore de wishlist")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Button {
                                    showingAddGift = true
                                } label: {
                                    Label("Ajouter un cadeau", systemImage: "plus.circle.fill")
                                }
                                .buttonStyle(MomentsTheme.PrimaryButtonStyle())
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 40)
                        }
                    }

                    Spacer()
                }
            }
            .background(
                MomentsTheme.diagonalGradient
                    .ignoresSafeArea()
                    .opacity(0.03)
            )
            .navigationTitle("Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditContact = true
                    } label: {
                        Text("Modifier")
                            .foregroundStyle(MomentsTheme.primaryGradient)
                    }
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditContact) {
                AddEditContactView(contact: contact)
            }
            .sheet(isPresented: $showingAddGift) {
                AddEditWishlistItemView(myEvent: nil, contact: contact, wishlistItem: nil)
            }
        }
    }
}

#Preview {
    @Previewable @State var contact = Contact.preview

    ContactDetailView(contact: contact)
        .modelContainer(for: [Contact.self, WishlistItem.self])
}
