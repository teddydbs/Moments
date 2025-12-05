# Architecture MVVM pour SwiftUI

Guide complet de l'architecture MVVM (Model-View-ViewModel) adaptée à SwiftUI et appliquée au projet Moments.

## 📚 Table des matières

1. [Qu'est-ce que MVVM ?](#quest-ce-que-mvvm-)
2. [MVVM adapté à SwiftUI](#mvvm-adapté-à-swiftui)
3. [Layer Model](#layer-model)
4. [Layer ViewModel](#layer-viewmodel)
5. [Layer View](#layer-view)
6. [Layer Service](#layer-service)
7. [Flux de données](#flux-de-données)
8. [Exemples complets](#exemples-complets)
9. [Anti-patterns à éviter](#anti-patterns-à-éviter)

---

## Qu'est-ce que MVVM ?

### Définition

**MVVM** = **Model-View-ViewModel**

C'est un pattern architectural qui sépare l'application en 3 couches :

```
┌─────────────────────────────────────────────────┐
│  VIEW (SwiftUI)                                 │
│  - Interface utilisateur                        │
│  - Déclarative, sans logique                    │
│  - Observe le ViewModel                         │
└───────────────┬─────────────────────────────────┘
                │ Binding / @Observable
                ▼
┌─────────────────────────────────────────────────┐
│  VIEWMODEL (@Observable)                        │
│  - Logique de présentation                      │
│  - State management                             │
│  - Transforme les données du Model              │
│  - Appelle les Services                         │
└───────────────┬─────────────────────────────────┘
                │ Utilise
                ▼
┌─────────────────────────────────────────────────┐
│  MODEL (@Model SwiftData)                       │
│  - Données pures                                │
│  - Business logic (très limitée)                │
│  - Pas de référence à la View ou ViewModel      │
└─────────────────────────────────────────────────┘
```

### Objectifs

✅ **Séparation des responsabilités** : Chaque couche a un rôle précis
✅ **Testabilité** : Le ViewModel peut être testé sans UI
✅ **Réutilisabilité** : Le même ViewModel peut servir plusieurs Views
✅ **Maintenabilité** : Code organisé et facile à modifier

---

## MVVM adapté à SwiftUI

### Différence avec UIKit

En **UIKit** (ancien) :
- View : UIViewController (impératif)
- ViewModel : ObservableObject
- Binding manuel avec Combine

En **SwiftUI** (moderne) :
- View : struct View (déclaratif)
- ViewModel : @Observable (iOS 17+) ou ObservableObject (iOS 16-)
- Binding automatique avec @State/@Binding

### Architecture dans Moments

```
Moments/
├── Models/              # @Model SwiftData - Données
│   ├── Event.swift
│   ├── Participant.swift
│   └── GiftIdea.swift
│
├── ViewModels/          # @Observable - Logique métier
│   ├── EventViewModel.swift
│   ├── ParticipantViewModel.swift
│   └── GiftIdeaViewModel.swift
│
├── Views/               # SwiftUI - Interface
│   ├── EventsView.swift
│   ├── EventDetailView.swift
│   ├── AddEditEventView.swift
│   └── Components/
│       └── EventRowView.swift
│
└── Services/            # Services externes
    ├── Backend/
    │   ├── SupabaseManager.swift
    │   └── SyncManager.swift
    └── NotificationManager.swift
```

---

## Layer Model

### Responsabilités

Le **Model** représente :
- ✅ Les **données** de l'application
- ✅ Les **relations** entre entités
- ❌ **Aucune logique métier complexe**
- ❌ **Aucune référence** à View ou ViewModel

### Exemple : Event Model

```swift
//
//  Event.swift
//  Moments
//
//  Model: Représente un événement
//

import Foundation
import SwiftData

// ✅ BONNE PRATIQUE: @Model pour SwiftData
@Model
final class Event {
    // MARK: - Properties

    var id: UUID
    var title: String
    var date: Date
    var category: EventCategory
    var isRecurring: Bool
    var notes: String
    var notificationIdentifier: String?

    @Attribute(.externalStorage)
    var imageData: Data?

    var hasGiftPool: Bool

    // MARK: - Relationships

    @Relationship(deleteRule: .cascade)
    var participants: [Participant] = []

    @Relationship(deleteRule: .cascade)
    var giftIdeas: [GiftIdea] = []

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        date: Date,
        category: EventCategory,
        isRecurring: Bool = false,
        notes: String = "",
        imageData: Data? = nil,
        hasGiftPool: Bool = false
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.category = category
        self.isRecurring = isRecurring
        self.notes = notes
        self.imageData = imageData
        self.hasGiftPool = hasGiftPool
    }
}

// MARK: - Computed Properties (OK dans le Model)

extension Event {
    /// Nombre de jours avant l'événement
    /// ✅ ACCEPTABLE: Propriété calculée simple, sans effet de bord
    var daysUntil: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
    }

    /// L'événement est-il passé ?
    /// ✅ ACCEPTABLE: Propriété calculée simple
    var isPast: Bool {
        date < Date()
    }
}

// MARK: - Preview Data

extension Event {
    /// Données de preview pour SwiftUI
    /// ✅ BONNE PRATIQUE: Données statiques pour les previews
    static var preview: Event {
        Event(
            title: "Anniversaire de Marie",
            date: Date().addingTimeInterval(86400 * 7),
            category: .birthday,
            notes: "Ne pas oublier le gâteau au chocolat"
        )
    }
}

// ✅ ENUM simple dans le Model
enum EventCategory: String, Codable, CaseIterable {
    case birthday = "Anniversaire"
    case wedding = "Mariage"
    case barMitzvah = "Bar/Bat Mitsva"
    case bachelorParty = "EVG"
    case bacheloretteParty = "EVJF"
    case party = "Soirée/Fête"
    case other = "Autre"

    var icon: String {
        switch self {
        case .birthday: return "gift.fill"
        case .wedding: return "heart.fill"
        case .barMitzvah: return "star.fill"
        case .bachelorParty: return "figure.walk"
        case .bacheloretteParty: return "figure.dress.line.vertical.figure"
        case .party: return "party.popper.fill"
        case .other: return "calendar"
        }
    }
}
```

### ❌ Ce qu'il NE faut PAS faire dans le Model

```swift
// ❌ MAL: Logique métier complexe dans le Model
@Model
final class Event {
    func sendNotification() { // ❌ Devrait être dans un Service
        // ...
    }

    func syncToServer() { // ❌ Devrait être dans un Service
        // ...
    }

    func loadParticipantsFromAPI() { // ❌ Devrait être dans un ViewModel/Service
        // ...
    }
}

// ❌ MAL: Référence au ViewModel
@Model
final class Event {
    var viewModel: EventViewModel? // ❌ JAMAIS
}
```

---

## Layer ViewModel

### Responsabilités

Le **ViewModel** gère :
- ✅ La **logique de présentation**
- ✅ Le **state management** (loading, error, etc.)
- ✅ La **transformation des données** (Model → View)
- ✅ Les **appels aux Services**
- ✅ La **validation** des formulaires
- ❌ **Aucune référence** directe aux composants UI (Button, Text, etc.)

### Exemple : EventViewModel

```swift
//
//  EventViewModel.swift
//  Moments
//
//  ViewModel: Gestion des événements
//

import Foundation
import SwiftUI
import SwiftData

// ✅ MODERNE: @Observable (iOS 17+)
// ⚠️ Pour iOS 16: utiliser ObservableObject + @Published
@MainActor
@Observable
final class EventViewModel {
    // MARK: - Properties

    /// Liste des événements (chargée depuis le Service ou SwiftData)
    var events: [Event] = []

    /// État de chargement
    var isLoading = false

    /// Message d'erreur (optionnel)
    var errorMessage: String?

    /// Filtre de catégorie actuel
    var selectedCategory: EventCategory?

    // MARK: - Dependencies

    private let supabase: SupabaseManager
    private let sync: SyncManager
    private let notifications: NotificationManager

    // MARK: - Initialization

    /// ✅ BONNE PRATIQUE: Injection de dépendances
    init(
        supabase: SupabaseManager = .shared,
        sync: SyncManager,
        notifications: NotificationManager = .shared
    ) {
        self.supabase = supabase
        self.sync = sync
        self.notifications = notifications
    }

    // MARK: - Public Methods

    /// Charger tous les événements
    func loadEvents() async {
        isLoading = true
        errorMessage = nil

        defer { isLoading = false }

        do {
            // ✅ Appel au Service
            try await sync.performFullSync()

            // ✅ Pas de gestion directe de SwiftData ici
            // La View utilisera @Query directement
        } catch {
            // ✅ Transformation de l'erreur pour la View
            errorMessage = "Impossible de charger les événements: \(error.localizedDescription)"
        }
    }

    /// Créer un événement
    func createEvent(
        title: String,
        date: Date,
        category: EventCategory,
        notes: String,
        modelContext: ModelContext
    ) async {
        // ✅ VALIDATION dans le ViewModel
        guard !title.isEmpty else {
            errorMessage = "Le titre est requis"
            return
        }

        isLoading = true
        defer { isLoading = false }

        // ✅ Création du Model
        let event = Event(
            title: title,
            date: date,
            category: category,
            notes: notes
        )

        // ✅ Sauvegarde via ModelContext (passé en paramètre)
        modelContext.insert(event)

        do {
            try modelContext.save()

            // ✅ Planifier la notification
            await notifications.scheduleNotification(for: event)

            // ✅ Marquer pour sync
            sync.markEventForSync(event)
        } catch {
            errorMessage = "Erreur lors de la création: \(error.localizedDescription)"
        }
    }

    /// Supprimer un événement
    func deleteEvent(_ event: Event, modelContext: ModelContext) {
        // ✅ Annuler la notification
        notifications.cancelNotification(for: event)

        // ✅ Suppression via ModelContext
        modelContext.delete(event)

        do {
            try modelContext.save()
        } catch {
            errorMessage = "Erreur lors de la suppression"
        }
    }

    // MARK: - Computed Properties

    /// Événements filtrés par catégorie
    /// ✅ TRANSFORMATION des données pour la View
    func filteredEvents(from allEvents: [Event]) -> [Event] {
        guard let category = selectedCategory else {
            return allEvents
        }

        return allEvents.filter { $0.category == category }
    }

    /// Nombre d'événements à venir
    /// ✅ LOGIQUE DE PRÉSENTATION
    func upcomingCount(from events: [Event]) -> Int {
        events.filter { !$0.isPast }.count
    }

    // MARK: - Validation

    /// Valider les données d'un événement
    /// ✅ VALIDATION dans le ViewModel
    func validate(title: String, date: Date) -> ValidationResult {
        if title.isEmpty {
            return .failure("Le titre est requis")
        }

        if title.count < 3 {
            return .failure("Le titre doit contenir au moins 3 caractères")
        }

        return .success
    }
}

// MARK: - Helper Types

enum ValidationResult {
    case success
    case failure(String)

    var isValid: Bool {
        if case .success = self {
            return true
        }
        return false
    }

    var errorMessage: String? {
        if case .failure(let message) = self {
            return message
        }
        return nil
    }
}
```

### ✅ Ce qu'un ViewModel DOIT faire

```swift
// ✅ Gérer l'état de chargement
var isLoading = false

// ✅ Gérer les erreurs
var errorMessage: String?

// ✅ Transformer les données
func upcomingEvents() -> [Event] {
    events.filter { $0.date > Date() }
}

// ✅ Valider les formulaires
func isValid(email: String) -> Bool {
    email.contains("@")
}

// ✅ Appeler les Services
func sync() async {
    try? await syncManager.performFullSync()
}
```

### ❌ Ce qu'un ViewModel NE doit PAS faire

```swift
// ❌ MAL: Référence à des composants UI
var button: Button? // ❌ JAMAIS

// ❌ MAL: Logique UI (couleurs, fonts, etc.)
var titleColor: Color // ❌ Devrait être dans la View

// ❌ MAL: Créer des Views
func makeButton() -> some View { // ❌ JAMAIS
    Button("Test") { }
}
```

---

## Layer View

### Responsabilités

La **View** gère :
- ✅ L'**affichage** des données
- ✅ La **mise en page** (layout)
- ✅ La **gestion des événements UI** (tap, swipe, etc.)
- ✅ Le **binding** avec le ViewModel
- ❌ **Aucune logique métier**
- ❌ **Aucun accès direct** aux Services (sauf exceptions)

### Exemple : EventsView

```swift
//
//  EventsView.swift
//  Moments
//
//  View: Liste des événements
//

import SwiftUI
import SwiftData

struct EventsView: View {
    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext

    // MARK: - State

    /// ✅ ViewModel pour la logique
    @State private var viewModel: EventViewModel

    /// ✅ @Query pour accéder à SwiftData
    @Query(sort: \Event.date, order: .forward) private var allEvents: [Event]

    /// ✅ État UI local
    @State private var isShowingAddEvent = false
    @State private var selectedEvent: Event?

    // MARK: - Initialization

    init() {
        // ✅ Créer le ViewModel avec les dépendances
        let modelContext = ModelContext(/* ... */) // Récupéré via Environment
        let syncManager = SyncManager(modelContext: modelContext)

        _viewModel = State(initialValue: EventViewModel(
            sync: syncManager
        ))
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                // ✅ Contenu principal
                contentView

                // ✅ Overlay de chargement
                if viewModel.isLoading {
                    loadingOverlay
                }
            }
            .navigationTitle("Événements")
            .toolbar {
                toolbarContent
            }
            .sheet(isPresented: $isShowingAddEvent) {
                AddEditEventView(event: nil, defaultCategory: nil)
            }
            .task {
                // ✅ Chargement au démarrage
                await viewModel.loadEvents()
            }
            .refreshable {
                // ✅ Pull-to-refresh
                await viewModel.loadEvents()
            }
            .alert("Erreur", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }

    // MARK: - Subviews

    /// ✅ BONNE PRATIQUE: Extraction des sous-vues
    @ViewBuilder
    private var contentView: some View {
        if filteredEvents.isEmpty {
            emptyStateView
        } else {
            eventsList
        }
    }

    private var eventsList: some View {
        List {
            ForEach(filteredEvents) { event in
                // ✅ Composant réutilisable
                EventRowView(event: event)
                    .onTapGesture {
                        selectedEvent = event
                    }
            }
            .onDelete(perform: deleteEvents)
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "Aucun événement",
            systemImage: "calendar",
            description: Text("Créez votre premier événement")
        )
    }

    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            ProgressView()
                .tint(.white)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                isShowingAddEvent = true
            } label: {
                Label("Ajouter", systemImage: "plus")
            }
        }
    }

    // MARK: - Computed Properties

    /// ✅ Filtrage via le ViewModel
    private var filteredEvents: [Event] {
        viewModel.filteredEvents(from: allEvents)
    }

    // MARK: - Methods

    /// ✅ Délégation au ViewModel
    private func deleteEvents(at offsets: IndexSet) {
        for index in offsets {
            let event = filteredEvents[index]
            viewModel.deleteEvent(event, modelContext: modelContext)
        }
    }
}

// MARK: - Preview

#Preview {
    EventsView()
        .modelContainer(for: Event.self, inMemory: true)
}
```

### ✅ Ce qu'une View DOIT faire

```swift
// ✅ Afficher les données
Text(event.title)

// ✅ Réagir aux actions utilisateur
Button("Delete") {
    viewModel.delete(event)
}

// ✅ Utiliser @Query pour SwiftData
@Query private var events: [Event]

// ✅ Passer le ModelContext au ViewModel
viewModel.save(event, modelContext: modelContext)
```

### ❌ Ce qu'une View NE doit PAS faire

```swift
// ❌ MAL: Logique métier dans la View
Button("Save") {
    // Validation compliquée
    if title.count > 3 && email.contains("@") && date > Date() {
        // Appel API
        // Transformation de données
    }
}

// ✅ BIEN: Déléguer au ViewModel
Button("Save") {
    viewModel.save(title: title, email: email, date: date)
}
```

---

## Layer Service

### Responsabilités

Les **Services** gèrent :
- ✅ Les **appels réseau** (API, Supabase)
- ✅ La **persistance** (fichiers, UserDefaults)
- ✅ Les **notifications**
- ✅ La **synchronisation**
- ✅ Toute **logique technique** réutilisable

### Exemple : SupabaseManager (Service)

```swift
//
//  SupabaseManager.swift
//  Moments
//
//  Service: Gestion des interactions avec Supabase
//

import Foundation

@MainActor
class SupabaseManager: ObservableObject {
    // ✅ Singleton
    static let shared = SupabaseManager()

    @Published var isAuthenticated = false
    @Published var currentUser: User?

    private init() { }

    // MARK: - Public Methods

    func signIn(email: String, password: String) async throws {
        // Logique d'authentification...
        isAuthenticated = true
    }

    func fetchEvents() async throws -> [RemoteEvent] {
        // Requête Supabase...
        return []
    }

    func createEvent(/* ... */) async throws -> RemoteEvent {
        // Création sur Supabase...
        return RemoteEvent(/* ... */)
    }
}
```

### Utilisation depuis le ViewModel

```swift
// ✅ ViewModel utilise les Services
@Observable
class EventViewModel {
    private let supabase: SupabaseManager

    init(supabase: SupabaseManager = .shared) {
        self.supabase = supabase
    }

    func syncEvents() async {
        do {
            let remoteEvents = try await supabase.fetchEvents()
            // Transformation et stockage...
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
```

---

## Flux de données

### Flux complet : Création d'un événement

```
┌─────────────────────────────────────────────────────────────┐
│ 1. USER ACTION                                              │
│    AddEventView - L'utilisateur clique "Sauvegarder"        │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. VIEW → VIEWMODEL                                         │
│    Button("Sauvegarder") {                                  │
│        viewModel.createEvent(title, date, category)         │
│    }                                                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. VIEWMODEL - Validation + Logique                         │
│    func createEvent() {                                     │
│        // Validation                                         │
│        guard !title.isEmpty else { return }                 │
│                                                              │
│        // Création du Model                                 │
│        let event = Event(title, date, category)             │
│                                                              │
│        // Appel au Service                                  │
│        await supabase.createEvent(event)                    │
│    }                                                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. SERVICE - Opération technique                            │
│    func createEvent(event) {                                │
│        // POST vers Supabase                                │
│        let response = try await client.post(...)            │
│        return response                                       │
│    }                                                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. VIEWMODEL - Mise à jour de l'état                        │
│    events.append(newEvent)                                  │
│    isLoading = false                                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ 6. VIEW - UI se met à jour automatiquement                  │
│    List(viewModel.events) { event in                        │
│        EventRow(event: event)                               │
│    }                                                         │
│    // ✅ Nouvel événement apparaît dans la liste            │
└─────────────────────────────────────────────────────────────┘
```

---

## Exemples complets

### Exemple 1 : Liste d'événements

**Model**
```swift
@Model
final class Event {
    var title: String
    var date: Date
}
```

**ViewModel**
```swift
@Observable
class EventViewModel {
    var isLoading = false

    func loadEvents() async {
        isLoading = true
        // Chargement...
        isLoading = false
    }
}
```

**View**
```swift
struct EventsView: View {
    @State private var viewModel = EventViewModel()
    @Query private var events: [Event]

    var body: some View {
        List(events) { event in
            Text(event.title)
        }
        .task {
            await viewModel.loadEvents()
        }
    }
}
```

### Exemple 2 : Formulaire de création

**ViewModel**
```swift
@Observable
class AddEventViewModel {
    var title = ""
    var date = Date()
    var errorMessage: String?

    func validate() -> Bool {
        if title.isEmpty {
            errorMessage = "Le titre est requis"
            return false
        }
        return true
    }

    func save(modelContext: ModelContext) {
        guard validate() else { return }

        let event = Event(title: title, date: date)
        modelContext.insert(event)
        try? modelContext.save()
    }
}
```

**View**
```swift
struct AddEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AddEventViewModel()

    var body: some View {
        Form {
            TextField("Titre", text: $viewModel.title)
            DatePicker("Date", selection: $viewModel.date)

            if let error = viewModel.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }

            Button("Sauvegarder") {
                viewModel.save(modelContext: modelContext)
                dismiss()
            }
        }
    }
}
```

---

## Anti-patterns à éviter

### ❌ 1. Logique métier dans la View

```swift
// ❌ MAL
struct EventsView: View {
    var body: some View {
        Button("Create") {
            // ❌ Validation dans la View
            if title.count > 3 {
                // ❌ Appel API dans la View
                supabase.createEvent(...)
            }
        }
    }
}

// ✅ BIEN
struct EventsView: View {
    var body: some View {
        Button("Create") {
            viewModel.createEvent(title)
        }
    }
}
```

### ❌ 2. View référencée dans le ViewModel

```swift
// ❌ MAL
class EventViewModel {
    var view: EventsView? // ❌ JAMAIS
}
```

### ❌ 3. ViewModel accède directement à SwiftData

```swift
// ❌ MAL (sauf exceptions)
class EventViewModel {
    @Query private var events: [Event] // ❌ @Query dans ViewModel
}

// ✅ BIEN
struct EventsView: View {
    @Query private var events: [Event] // ✅ @Query dans la View
}
```

### ❌ 4. Model avec logique UI

```swift
// ❌ MAL
@Model
class Event {
    func displayTitle() -> String { // ❌ Logique de présentation
        title.uppercased()
    }

    var titleColor: Color // ❌ Propriété UI
}
```

---

## Résumé : Qui fait quoi ?

| Couche | Responsabilités | Ne doit PAS |
|--------|----------------|-------------|
| **Model** | Données, relations | Logique métier, UI, Services |
| **ViewModel** | Logique métier, validation, état | UI, composants SwiftUI |
| **View** | Affichage, layout, bindings | Logique métier, appels API |
| **Service** | API, réseau, notifications | UI, logique de présentation |

---

**Version** : 1.0.0
**Dernière mise à jour** : 04 Décembre 2025
