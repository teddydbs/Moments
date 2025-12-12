//
//  EventPhotosGalleryView.swift
//  Moments
//
//  Vue pour afficher et gérer l'album photo d'un événement
//  Architecture: View (SwiftUI)
//

import SwiftUI
import SwiftData
import PhotosUI

/// Vue pour afficher l'album photo d'un événement
struct EventPhotosGalleryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let myEvent: MyEvent

    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingFullScreen: EventPhoto?
    @State private var currentUserName: String = "Moi"

    // ❓ POURQUOI computed property ?
    // Pour trier les photos par ordre d'ajout (plus récentes en premier)
    private var sortedPhotos: [EventPhoto] {
        (myEvent.eventPhotos ?? []).sorted { $0.uploadedAt > $1.uploadedAt }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                MomentsTheme.diagonalGradient
                    .ignoresSafeArea()
                    .opacity(0.03)

                if sortedPhotos.isEmpty {
                    // ✅ État vide
                    VStack(spacing: 24) {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 70))
                            .foregroundStyle(MomentsTheme.primaryGradient.opacity(0.5))

                        VStack(spacing: 8) {
                            Text("Aucune photo")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("Ajoutez des photos pour créer un album de cet événement")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: 10,
                            matching: .images
                        ) {
                            Label("Ajouter des photos", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                        .buttonStyle(MomentsTheme.PrimaryButtonStyle())
                        .padding(.horizontal)
                    }
                } else {
                    // ✅ Grille de photos
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 4),
                            GridItem(.flexible(), spacing: 4),
                            GridItem(.flexible(), spacing: 4)
                        ], spacing: 4) {
                            ForEach(sortedPhotos) { photo in
                                PhotoGridItem(photo: photo)
                                    .onTapGesture {
                                        showingFullScreen = photo
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deletePhoto(photo)
                                        } label: {
                                            Label("Supprimer", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Album photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") {
                        dismiss()
                    }
                }

                if !sortedPhotos.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        PhotosPicker(
                            selection: $selectedPhotos,
                            maxSelectionCount: 10,
                            matching: .images
                        ) {
                            Image(systemName: "plus.circle.fill")
                                .gradientIcon()
                        }
                    }
                }
            }
            .onChange(of: selectedPhotos) { _, newPhotos in
                Task {
                    await addPhotos(newPhotos)
                }
            }
            .fullScreenCover(item: $showingFullScreen) { photo in
                FullScreenPhotoView(photo: photo, allPhotos: sortedPhotos)
            }
        }
    }

    // MARK: - Methods

    /// Ajoute les photos sélectionnées à l'album
    /// - Parameter photos: Les PhotosPickerItem sélectionnés
    private func addPhotos(_ photos: [PhotosPickerItem]) async {
        for photo in photos {
            // ✅ ÉTAPE 1: Charger l'image
            if let data = try? await photo.loadTransferable(type: Data.self) {
                // ✅ ÉTAPE 2: Compresser l'image pour économiser de l'espace
                if let uiImage = UIImage(data: data),
                   let compressedData = uiImage.jpegData(compressionQuality: 0.7) {

                    await MainActor.run {
                        // ✅ ÉTAPE 3: Créer l'EventPhoto
                        let eventPhoto = EventPhoto(
                            imageData: compressedData,
                            uploadedBy: currentUserName,
                            myEvent: myEvent
                        )

                        modelContext.insert(eventPhoto)
                    }
                }
            }
        }

        // ✅ ÉTAPE 4: Sauvegarder le contexte
        await MainActor.run {
            do {
                try modelContext.save()
                print("✅ \(photos.count) photo(s) ajoutée(s) à l'album")

                // ✅ Réinitialiser la sélection
                selectedPhotos = []
            } catch {
                print("❌ Erreur lors de l'ajout des photos: \(error)")
            }
        }
    }

    /// Supprime une photo de l'album
    /// - Parameter photo: La photo à supprimer
    private func deletePhoto(_ photo: EventPhoto) {
        modelContext.delete(photo)

        do {
            try modelContext.save()
            print("✅ Photo supprimée")
        } catch {
            print("❌ Erreur lors de la suppression: \(error)")
        }
    }
}

// MARK: - Photo Grid Item

/// Vue pour afficher une photo dans la grille
struct PhotoGridItem: View {
    let photo: EventPhoto

    var body: some View {
        GeometryReader { geometry in
            if let uiImage = UIImage(data: photo.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.width)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .frame(width: geometry.size.width, height: geometry.size.width)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(4)
    }
}

// MARK: - Full Screen Photo View

/// Vue pour afficher une photo en plein écran
struct FullScreenPhotoView: View {
    @Environment(\.dismiss) private var dismiss

    let photo: EventPhoto
    let allPhotos: [EventPhoto]

    @State private var currentIndex: Int = 0

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $currentIndex) {
                ForEach(Array(allPhotos.enumerated()), id: \.element.id) { index, photo in
                    VStack(spacing: 0) {
                        // ✅ Image
                        if let uiImage = UIImage(data: photo.imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .ignoresSafeArea()
                        }

                        // ✅ Légende et infos
                        VStack(alignment: .leading, spacing: 8) {
                            if let caption = photo.caption, !caption.isEmpty {
                                Text(caption)
                                    .font(.body)
                                    .foregroundColor(.white)
                            }

                            HStack {
                                if let uploadedBy = photo.uploadedBy {
                                    Text("Par \(uploadedBy)")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))
                                }

                                Spacer()

                                Text(photo.uploadedAt, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding()
                        .background(Color.black.opacity(0.3))
                    }
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // ✅ Bouton fermer
            VStack {
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(radius: 4)
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .onAppear {
            // ✅ Démarrer à la photo sélectionnée
            if let index = allPhotos.firstIndex(where: { $0.id == photo.id }) {
                currentIndex = index
            }
        }
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: MyEvent.self, EventPhoto.self, configurations: config)
    let event = MyEvent.preview
    container.mainContext.insert(event)

    // Ajouter des photos de test
    let photo1 = EventPhoto.preview
    let photo2 = EventPhoto.preview
    photo1.myEvent = event
    photo2.myEvent = event
    container.mainContext.insert(photo1)
    container.mainContext.insert(photo2)

    return EventPhotosGalleryView(myEvent: event)
        .modelContainer(container)
}
