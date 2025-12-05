# SwiftUI Patterns - Guide Complet

Documentation des patterns, conventions et bonnes pratiques SwiftUI pour le projet Moments.

## 📚 Table des matières

1. [State Management](#state-management)
2. [Navigation](#navigation)
3. [Lists et Performance](#lists-et-performance)
4. [Styles et Modifiers](#styles-et-modifiers)
5. [Lifecycle](#lifecycle)
6. [Previews](#previews)
7. [Environment](#environment)
8. [Bindings](#bindings)
9. [ViewBuilder](#viewbuilder)
10. [Animations](#animations)

---

## State Management

### @State - État local

**Utiliser pour** : Données simples, locales à une vue

```swift
// ✅ BONNE PRATIQUE
struct CounterView: View {
    @State private var count = 0
    @State private var isShowingAlert = false

    var body: some View {
        VStack {
            Text("Count: \(count)")

            Button("Increment") {
                count += 1 // ✅ Modifie @State, UI se met à jour
            }
        }
    }
}
```

**Règles** :
- ✅ Toujours `private` sauf si passé via `$binding`
- ✅ Pour les types valeur (Int, String, Bool, struct)
- ❌ Jamais pour la logique métier complexe

### @Binding - Référence partagée

**Utiliser pour** : Partager l'état entre parent et enfant

```swift
// ✅ PARENT : Possède le @State
struct ParentView: View {
    @State private var isOn = false

    var body: some View {
        ToggleView(isOn: $isOn) // $ crée un Binding
    }
}

// ✅ ENFANT : Reçoit le @Binding
struct ToggleView: View {
    @Binding var isOn: Bool

    var body: some View {
        Toggle("Option", isOn: $isOn)
            .onChange(of: isOn) { oldValue, newValue in
                print("Changed from \(oldValue) to \(newValue)")
            }
    }
}
```

**Pattern courant : Validation de formulaire**

```swift
struct FormView: View {
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack {
            EmailField(email: $email)
            PasswordField(password: $password)

            Button("Submit") {
                submit()
            }
            .disabled(!isValid)
        }
    }

    private var isValid: Bool {
        !email.isEmpty && !password.isEmpty
    }
}

struct EmailField: View {
    @Binding var email: String

    var body: some View {
        TextField("Email", text: $email)
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
    }
}
```

### @Observable - ViewModel (iOS 17+)

**Utiliser pour** : ViewModels, logique métier partagée

```swift
// ✅ MODERNE (iOS 17+)
@Observable
class EventViewModel {
    var events: [Event] = []
    var isLoading = false
    var errorMessage: String?

    func loadEvents() async {
        isLoading = true
        defer { isLoading = false }

        do {
            events = try await fetchEvents()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// Utilisation dans la View
struct EventsView: View {
    @State private var viewModel = EventViewModel()

    var body: some View {
        List(viewModel.events) { event in
            EventRow(event: event)
        }
        .task {
            await viewModel.loadEvents()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
    }
}
```

**⚠️ iOS 16 et antérieur : ObservableObject**

```swift
// ⚠️ ANCIEN (avant iOS 17)
class EventViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
}

// Utilisation
struct EventsView: View {
    @StateObject private var viewModel = EventViewModel()
    // ou @ObservedObject si créé ailleurs
}
```

### @Query - SwiftData

**Utiliser pour** : Accès direct à SwiftData

```swift
// ✅ QUERY SIMPLE
struct EventsView: View {
    @Query(sort: \Event.date) private var events: [Event]

    var body: some View {
        List(events) { event in
            Text(event.title)
        }
    }
}

// ✅ QUERY AVEC FILTRE
@Query(
    filter: #Predicate<Event> { event in
        event.category == .birthday
    },
    sort: \Event.date
) private var birthdays: [Event]

// ✅ QUERY DYNAMIQUE
struct EventsView: View {
    let category: EventCategory

    @Query private var events: [Event]

    init(category: EventCategory) {
        self.category = category

        // Filtrer par catégorie passée en paramètre
        let predicate = #Predicate<Event> { event in
            event.category == category
        }

        _events = Query(
            filter: predicate,
            sort: \Event.date
        )
    }
}
```

**Règle** : Utiliser `@Query` directement dans les Views pour les lectures simples

---

## Navigation

### NavigationStack (iOS 16+)

**Stack-based navigation moderne**

```swift
// ✅ MODERNE
struct ContentView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            List(events) { event in
                NavigationLink(value: event) {
                    EventRow(event: event)
                }
            }
            .navigationDestination(for: Event.self) { event in
                EventDetailView(event: event)
            }
            .navigationTitle("Événements")
        }
    }
}
```

**Navigation programmatique**

```swift
struct EventsView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            Button("Aller aux détails") {
                path.append(selectedEvent) // ✅ Navigation programmatique
            }
            .navigationDestination(for: Event.self) { event in
                EventDetailView(event: event)
            }
        }
    }

    func navigateToEvent(_ event: Event) {
        path.append(event)
    }

    func popToRoot() {
        path.removeLast(path.count) // ✅ Retour à la racine
    }
}
```

### Sheets

**Modal presentation**

```swift
// ✅ SHEET BASIQUE
struct EventsView: View {
    @State private var isShowingAddEvent = false

    var body: some View {
        List {
            // ...
        }
        .toolbar {
            Button("Ajouter") {
                isShowingAddEvent = true
            }
        }
        .sheet(isPresented: $isShowingAddEvent) {
            AddEventView()
        }
    }
}

// ✅ SHEET AVEC ITEM
struct EventsView: View {
    @State private var selectedEvent: Event?

    var body: some View {
        List(events) { event in
            Button(event.title) {
                selectedEvent = event
            }
        }
        .sheet(item: $selectedEvent) { event in
            EventDetailView(event: event)
        }
    }
}

// ✅ FERMER UN SHEET (depuis l'intérieur)
struct AddEventView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button("Annuler") {
            dismiss()
        }
    }
}
```

### Full Screen Cover

**Presentation plein écran**

```swift
.fullScreenCover(isPresented: $isShowing) {
    OnboardingView()
}
```

### Alerts

```swift
// ✅ ALERT SIMPLE
struct ContentView: View {
    @State private var isShowingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        Button("Show Alert") {
            alertMessage = "Erreur de connexion"
            isShowingAlert = true
        }
        .alert("Attention", isPresented: $isShowingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

// ✅ ALERT AVEC ACTIONS
.alert("Supprimer ?", isPresented: $isShowingDeleteAlert) {
    Button("Annuler", role: .cancel) { }
    Button("Supprimer", role: .destructive) {
        deleteEvent()
    }
} message: {
    Text("Cette action est irréversible")
}
```

### Confirmation Dialog

```swift
// ✅ ACTION SHEET
.confirmationDialog("Choisir une source", isPresented: $isShowingOptions) {
    Button("Depuis Contacts") {
        addFromContacts()
    }
    Button("Depuis Facebook") {
        addFromFacebook()
    }
    Button("Manuellement") {
        addManually()
    }
    Button("Annuler", role: .cancel) { }
}
```

---

## Lists et Performance

### List de base

```swift
// ✅ LIST SIMPLE
struct EventsView: View {
    @Query private var events: [Event]

    var body: some View {
        List(events) { event in
            EventRow(event: event)
        }
    }
}
```

### List avec sections

```swift
// ✅ SECTIONS
struct EventsView: View {
    var eventsByCategory: [EventCategory: [Event]] {
        Dictionary(grouping: events, by: \.category)
    }

    var body: some View {
        List {
            ForEach(EventCategory.allCases, id: \.self) { category in
                if let events = eventsByCategory[category], !events.isEmpty {
                    Section(category.rawValue) {
                        ForEach(events) { event in
                            EventRow(event: event)
                        }
                    }
                }
            }
        }
    }
}
```

### Swipe Actions

```swift
// ✅ SWIPE ACTIONS
List(events) { event in
    EventRow(event: event)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteEvent(event)
            } label: {
                Label("Supprimer", systemImage: "trash")
            }

            Button {
                editEvent(event)
            } label: {
                Label("Modifier", systemImage: "pencil")
            }
            .tint(.blue)
        }
}
```

### Pull to Refresh

```swift
// ✅ REFRESHABLE
List(events) { event in
    EventRow(event: event)
}
.refreshable {
    await viewModel.refresh()
}
```

### Search

```swift
// ✅ SEARCHABLE
struct EventsView: View {
    @Query private var allEvents: [Event]
    @State private var searchText = ""

    var filteredEvents: [Event] {
        if searchText.isEmpty {
            return allEvents
        }
        return allEvents.filter {
            $0.title.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List(filteredEvents) { event in
            EventRow(event: event)
        }
        .searchable(text: $searchText, prompt: "Rechercher")
    }
}
```

### Performance : LazyVStack

```swift
// ✅ LAZY LOADING pour grandes listes
ScrollView {
    LazyVStack {
        ForEach(events) { event in
            EventRow(event: event)
        }
    }
}

// ⚠️ List est déjà lazy par défaut
// Utiliser LazyVStack seulement avec ScrollView
```

### Performance : identifiants stables

```swift
// ✅ ID STABLE (UUID, ID unique)
struct Event: Identifiable {
    let id: UUID // ✅ Identifiant stable
}

// ❌ ÉVITER les index comme ID
ForEach(Array(events.enumerated()), id: \.offset) { index, event in
    // ❌ Problèmes de performance
}

// ✅ PRÉFÉRER
ForEach(events) { event in
    // ✅ Utilise l'id automatiquement
}
```

---

## Styles et Modifiers

### Ordre des modifiers

**Règle** : L'ordre des modifiers compte !

```swift
// ✅ CORRECT
Text("Hello")
    .padding()
    .background(Color.blue) // Background s'applique AU padding

// ❌ DIFFÉRENT
Text("Hello")
    .background(Color.blue)
    .padding() // Background seulement sur le texte, pas le padding
```

### Modifiers réutilisables

```swift
// ✅ VIEW MODIFIER PERSONNALISÉ
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 4)
    }
}

// Extension pour faciliter l'usage
extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}

// Utilisation
Text("Hello")
    .cardStyle()
```

### Button Styles

```swift
// ✅ STYLES DE BOUTONS
Button("Connexion") {
    login()
}
.buttonStyle(.borderedProminent) // Style iOS standard

// ✅ STYLE PERSONNALISÉ
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(
                configuration.isPressed ? Color.blue.opacity(0.7) : Color.blue
            )
            .cornerRadius(12)
    }
}

Button("Action") {
    doSomething()
}
.buttonStyle(PrimaryButtonStyle())
```

### Conditional Modifiers

```swift
// ✅ MODIFIER CONDITIONNEL
extension View {
    @ViewBuilder
    func `if`<Transform: View>(
        _ condition: Bool,
        transform: (Self) -> Transform
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// Utilisation
Text("Hello")
    .if(isHighlighted) { view in
        view.foregroundColor(.red)
    }
```

---

## Lifecycle

### onAppear / onDisappear

```swift
// ✅ LIFECYCLE BASIQUE
struct ContentView: View {
    var body: some View {
        Text("Hello")
            .onAppear {
                print("Vue apparue")
                // ⚠️ S'exécute à chaque apparition
            }
            .onDisappear {
                print("Vue disparue")
            }
    }
}
```

### task - Async/Await

```swift
// ✅ PRÉFÉRÉ pour async/await
struct EventsView: View {
    @State private var viewModel = EventViewModel()

    var body: some View {
        List(viewModel.events) { event in
            EventRow(event: event)
        }
        .task {
            // S'exécute une fois au démarrage
            await viewModel.loadEvents()
        }

        // ✅ Task avec id (reexécute si l'id change)
        .task(id: selectedCategory) {
            await viewModel.loadEvents(for: selectedCategory)
        }
    }
}
```

### onChange

```swift
// ✅ RÉAGIR AUX CHANGEMENTS
struct SearchView: View {
    @State private var searchText = ""

    var body: some View {
        TextField("Search", text: $searchText)
            .onChange(of: searchText) { oldValue, newValue in
                print("Recherche changée : \(oldValue) → \(newValue)")
                performSearch(newValue)
            }
    }
}
```

### ScenePhase

```swift
// ✅ DÉTECTER L'ÉTAT DE L'APP
@main
struct MomentsApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                print("App active")
            case .inactive:
                print("App inactive")
            case .background:
                print("App en background")
            @unknown default:
                break
            }
        }
    }
}
```

---

## Previews

### Preview de base

```swift
// ✅ PREVIEW SIMPLE
#Preview {
    ContentView()
}

// ✅ PREVIEW AVEC MODELCONTAINER
#Preview {
    EventsView()
        .modelContainer(for: Event.self, inMemory: true)
}
```

### Previews multiples

```swift
// ✅ PLUSIEURS PREVIEWS
#Preview("Mode clair") {
    ContentView()
        .preferredColorScheme(.light)
}

#Preview("Mode sombre") {
    ContentView()
        .preferredColorScheme(.dark)
}

#Preview("iPhone 15 Pro") {
    ContentView()
        .previewDevice("iPhone 15 Pro")
}

#Preview("iPad") {
    ContentView()
        .previewDevice("iPad Pro (12.9-inch)")
}
```

### Preview avec données

```swift
// ✅ DONNÉES DE PREVIEW
extension Event {
    static var preview: Event {
        Event(
            title: "Anniversaire de Marie",
            date: Date(),
            category: .birthday,
            isRecurring: true,
            notes: "Ne pas oublier le gâteau !",
            imageData: nil,
            hasGiftPool: true
        )
    }

    static var previews: [Event] {
        [
            Event(title: "Anniversaire", date: Date(), category: .birthday),
            Event(title: "Mariage", date: Date().addingTimeInterval(86400), category: .wedding),
            Event(title: "Soirée", date: Date().addingTimeInterval(172800), category: .party)
        ]
    }
}

#Preview {
    EventRow(event: .preview)
}

#Preview {
    List(Event.previews) { event in
        EventRow(event: event)
    }
}
```

---

## Environment

### Accès aux valeurs d'environnement

```swift
// ✅ ENVIRONMENT VALUES
struct MyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Text("Mode : \(colorScheme == .dark ? "Sombre" : "Clair")")
    }
}
```

### Créer ses propres Environment Keys

```swift
// ✅ CUSTOM ENVIRONMENT KEY
private struct IsPreviewKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isPreview: Bool {
        get { self[IsPreviewKey.self] }
        set { self[IsPreviewKey.self] = newValue }
    }
}

// Utilisation
#Preview {
    ContentView()
        .environment(\.isPreview, true)
}

struct ContentView: View {
    @Environment(\.isPreview) private var isPreview

    var body: some View {
        if isPreview {
            Text("Mode Preview")
        }
    }
}
```

---

## Bindings

### Créer des Bindings personnalisés

```swift
// ✅ BINDING CALCULÉ
struct TemperatureView: View {
    @State private var celsius: Double = 20

    private var fahrenheit: Binding<Double> {
        Binding(
            get: { celsius * 9/5 + 32 },
            set: { celsius = ($0 - 32) * 5/9 }
        )
    }

    var body: some View {
        VStack {
            TextField("Celsius", value: $celsius, format: .number)
            TextField("Fahrenheit", value: fahrenheit, format: .number)
        }
    }
}
```

### Constant Binding

```swift
// ✅ BINDING CONSTANT (pour previews)
#Preview {
    ToggleView(isOn: .constant(true))
}
```

---

## ViewBuilder

### Conditional Content

```swift
// ✅ VIEWBUILDER
@ViewBuilder
func makeContent() -> some View {
    if isLoading {
        ProgressView()
    } else if events.isEmpty {
        ContentUnavailableView("Aucun événement", systemImage: "calendar")
    } else {
        List(events) { event in
            EventRow(event: event)
        }
    }
}

var body: some View {
    makeContent()
}
```

### @ViewBuilder Parameter

```swift
// ✅ COMPOSANT AVEC VIEWBUILDER
struct Card<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)

            content()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

// Utilisation
Card(title: "Événements") {
    Text("5 événements à venir")
    Button("Voir plus") { }
}
```

---

## Animations

### Animations implicites

```swift
// ✅ ANIMATION SIMPLE
struct ContentView: View {
    @State private var scale: CGFloat = 1.0

    var body: some View {
        Circle()
            .scaleEffect(scale)
            .animation(.easeInOut, value: scale) // ✅ Anime quand scale change

        Button("Animer") {
            scale = scale == 1.0 ? 1.5 : 1.0
        }
    }
}
```

### Animations explicites

```swift
// ✅ WITH ANIMATION
Button("Animer") {
    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
        isExpanded.toggle()
    }
}
```

### Transitions

```swift
// ✅ TRANSITIONS
struct ContentView: View {
    @State private var isShowing = false

    var body: some View {
        VStack {
            if isShowing {
                Text("Hello")
                    .transition(.scale.combined(with: .opacity))
            }

            Button("Toggle") {
                withAnimation {
                    isShowing.toggle()
                }
            }
        }
    }
}
```

### Animations personnalisées

```swift
// ✅ CUSTOM ANIMATION
extension Animation {
    static var smooth: Animation {
        .spring(response: 0.3, dampingFraction: 0.7)
    }
}

// Utilisation
withAnimation(.smooth) {
    // ...
}
```

---

## Bonnes pratiques générales

### 1. Décomposer les Views

```swift
// ❌ VIEW TROP LONGUE
struct EventsView: View {
    var body: some View {
        VStack {
            // 200 lignes de code...
        }
    }
}

// ✅ VIEWS DÉCOMPOSÉES
struct EventsView: View {
    var body: some View {
        VStack {
            HeaderView()
            EventsList()
            FooterView()
        }
    }
}
```

### 2. Extraction de computed properties

```swift
// ✅ COMPUTED PROPERTIES pour la lisibilité
var body: some View {
    VStack {
        headerSection
        contentSection
        footerSection
    }
}

private var headerSection: some View {
    HStack {
        Text("Événements")
        Spacer()
        addButton
    }
}

private var addButton: some View {
    Button("Ajouter") {
        // ...
    }
}
```

### 3. Préférer les let aux var

```swift
// ✅ LET si possible
let title = "Hello"

// ✅ VAR seulement si nécessaire
var isExpanded = false
```

---

## Ressources

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [WWDC SwiftUI Sessions](https://developer.apple.com/videos/)

---

**Version** : 1.0.0
**Dernière mise à jour** : 04 Décembre 2025
