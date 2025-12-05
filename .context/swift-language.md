# Swift Language - Règles et Conventions

Documentation complète des règles du langage Swift à appliquer dans le projet Moments.

## 📚 Table des matières

1. [Optionnels](#optionnels)
2. [Gestion des erreurs](#gestion-des-erreurs)
3. [Async/Await et Concurrence](#asyncawait-et-concurrence)
4. [Closures](#closures)
5. [Protocols et Extensions](#protocols-et-extensions)
6. [Property Wrappers](#property-wrappers)
7. [Collections](#collections)
8. [Naming Conventions](#naming-conventions)
9. [Pièges courants](#pièges-courants)

---

## Optionnels

### Qu'est-ce qu'un optionnel ?

Un optionnel est un type qui peut contenir **une valeur** ou **nil** (rien).

```swift
var name: String? = "Marie"  // Peut être une String ou nil
var age: Int? = nil           // Actuellement nil
```

### ✅ Unwrapping sécurisé : if let

**Utiliser quand** : Vous avez besoin de la valeur dans un scope limité

```swift
// ✅ BONNE PRATIQUE
if let user = currentUser {
    print("Bonjour \(user.name)")
    // user est utilisable seulement ici
}

// Unwrapping multiple
if let user = currentUser,
   let email = user.email,
   email.contains("@") {
    sendEmail(to: email)
}
```

### ✅ Unwrapping sécurisé : guard let

**Utiliser quand** : Vous voulez sortir tôt si la valeur est nil

```swift
// ✅ PRÉFÉRÉ dans les fonctions
func processUser() {
    guard let user = currentUser else {
        print("Pas d'utilisateur")
        return
    }

    // user est utilisable dans toute la fonction
    print(user.name)
    print(user.email)
}
```

**Règle** : Préférer `guard let` en début de fonction pour valider les conditions

### ✅ Nil-Coalescing Operator (??)

**Utiliser quand** : Vous voulez une valeur par défaut

```swift
// ✅ BONNE PRATIQUE
let displayName = user?.name ?? "Invité"
let count = events?.count ?? 0

// Chaînage
let city = user?.address?.city ?? "Paris"
```

### ❌ Force Unwrap (!)

**ÉVITER ABSOLUMENT** sauf dans ces cas précis :

```swift
// ❌ DANGEREUX - Crash si nil
let name = user!.name

// ✅ ACCEPTABLE seulement si vous êtes 100% sûr
// Exemple : IBOutlet connecté dans Interface Builder
@IBOutlet private weak var tableView: UITableView!

// ✅ ACCEPTABLE avec les assets
let image = UIImage(named: "logo")! // Asset garanti présent
```

**Règle** : Si vous utilisez `!`, ajoutez un commentaire expliquant pourquoi c'est sûr

### ✅ Optional Chaining

```swift
// ✅ Accès sécurisé aux propriétés optionnelles
let emailLength = user?.email?.count

// ✅ Appel de méthode optionnel
user?.updateProfile()

// ✅ Subscript optionnel
let firstEvent = events?[0]
```

### ✅ Implicitly Unwrapped Optionals (!)

**Utiliser UNIQUEMENT** pour :
- IBOutlets
- Propriétés initialisées après `init` mais avant utilisation

```swift
// ✅ ACCEPTABLE
class ViewController: UIViewController {
    @IBOutlet private weak var label: UILabel!

    // Initialisé dans viewDidLoad avant toute utilisation
    private var viewModel: EventViewModel!
}

// ❌ ÉVITER ailleurs
var name: String! = "Marie" // Utiliser String? à la place
```

---

## Gestion des erreurs

### Définir des erreurs

```swift
// ✅ BONNE PRATIQUE : Enum conforme à Error
enum NetworkError: Error {
    case noConnection
    case timeout
    case invalidResponse
    case serverError(code: Int)
}

// ✅ Ajouter LocalizedError pour les messages
extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noConnection:
            return "Pas de connexion internet"
        case .timeout:
            return "Délai d'attente dépassé"
        case .invalidResponse:
            return "Réponse invalide du serveur"
        case .serverError(let code):
            return "Erreur serveur (code \(code))"
        }
    }
}
```

### ✅ Do-Catch

**Utiliser quand** : Vous devez gérer différents types d'erreurs

```swift
// ✅ BONNE PRATIQUE
func loadEvents() {
    do {
        let events = try fetchEvents()
        self.events = events
    } catch NetworkError.noConnection {
        showAlert("Vérifiez votre connexion")
    } catch NetworkError.timeout {
        showAlert("Le serveur met trop de temps à répondre")
    } catch {
        // Attrape toutes les autres erreurs
        showAlert("Erreur : \(error.localizedDescription)")
    }
}
```

### ✅ Try?

**Utiliser quand** : Vous vous fichez de l'erreur et voulez nil en cas d'échec

```swift
// ✅ BON USAGE
let image = try? loadImage(from: url) // nil si échec
let data = try? JSONDecoder().decode(Event.self, from: jsonData)

// ⚠️ Ne pas abuser
// Si l'erreur est importante, utiliser do-catch
```

### ✅ Try!

**ÉVITER** sauf si vous êtes **absolument certain** qu'il n'y aura jamais d'erreur

```swift
// ❌ DANGEREUX
let data = try! loadCriticalData()

// ✅ ACCEPTABLE uniquement pour les données bundled
let jsonData = try! Data(contentsOf: Bundle.main.url(forResource: "config", withExtension: "json")!)
```

### ✅ Throwing functions

```swift
// ✅ Fonction qui peut lancer une erreur
func fetchEvents() throws -> [Event] {
    guard isConnected else {
        throw NetworkError.noConnection
    }

    // Requête réseau...
    guard let response = response else {
        throw NetworkError.invalidResponse
    }

    return events
}

// Utilisation
do {
    let events = try fetchEvents()
} catch {
    print("Erreur : \(error)")
}
```

### ✅ Result Type

**Utiliser pour** : Callbacks asynchrones (moins utilisé avec async/await)

```swift
// ✅ BONNE PRATIQUE (avant async/await)
func fetchEvents(completion: @escaping (Result<[Event], Error>) -> Void) {
    // Requête...
    if success {
        completion(.success(events))
    } else {
        completion(.failure(NetworkError.timeout))
    }
}

// Utilisation
fetchEvents { result in
    switch result {
    case .success(let events):
        print("✅ \(events.count) événements")
    case .failure(let error):
        print("❌ \(error)")
    }
}

// ⚠️ AUJOURD'HUI : Préférer async/await (voir section dédiée)
```

---

## Async/Await et Concurrence

### ✅ Async Functions

**Utiliser pour** : Toutes les opérations asynchrones (réseau, fichiers, DB)

```swift
// ✅ MODERNE (Swift 5.5+)
func fetchEvents() async throws -> [Event] {
    let response = try await apiClient.get("/events")
    let events = try JSONDecoder().decode([Event].self, from: response)
    return events
}

// Appel
Task {
    do {
        let events = try await fetchEvents()
        self.events = events
    } catch {
        print("Erreur : \(error)")
    }
}
```

### ✅ @MainActor

**Utiliser pour** : Garantir l'exécution sur le thread principal (UI)

```swift
// ✅ BONNE PRATIQUE : ViewModels sont @MainActor
@MainActor
@Observable
class EventViewModel {
    var events: [Event] = []

    // Cette fonction s'exécute automatiquement sur le main thread
    func loadEvents() async {
        do {
            // Appel réseau sur background thread
            let fetchedEvents = try await fetchEvents()

            // Retour automatique sur main thread ici
            self.events = fetchedEvents
        } catch {
            print("Erreur : \(error)")
        }
    }
}
```

### ✅ Task

**Créer une tâche asynchrone**

```swift
// ✅ Dans une View SwiftUI
Button("Charger") {
    Task {
        await viewModel.loadEvents()
    }
}

// ✅ Task avec gestion d'erreur
Task {
    do {
        try await viewModel.sync()
    } catch {
        errorMessage = error.localizedDescription
    }
}

// ✅ Task.detached pour s'exécuter hors du contexte actuel
Task.detached {
    await performBackgroundWork()
}
```

### ✅ Async Let

**Exécuter plusieurs tâches en parallèle**

```swift
// ✅ Requêtes parallèles
func loadData() async throws {
    async let events = fetchEvents()
    async let participants = fetchParticipants()
    async let gifts = fetchGiftIdeas()

    // Attend toutes les requêtes en parallèle
    let (loadedEvents, loadedParticipants, loadedGifts) = try await (events, participants, gifts)

    self.events = loadedEvents
    self.participants = loadedParticipants
    self.giftIdeas = loadedGifts
}
```

### ❌ Éviter les anti-patterns

```swift
// ❌ MAL : Mélanger async/await et completion handlers
func badExample(completion: @escaping ([Event]) -> Void) async {
    // Ne faites pas ça
}

// ✅ BIEN : Choisir l'un ou l'autre
func goodExample() async -> [Event] {
    // Async/await pur
}
```

---

## Closures

### Syntaxe de base

```swift
// ✅ Closure complète
let greeting = { (name: String) -> String in
    return "Bonjour \(name)"
}

// ✅ Type inféré
let greeting: (String) -> String = { name in
    return "Bonjour \(name)"
}

// ✅ Return implicite (une seule expression)
let greeting: (String) -> String = { name in
    "Bonjour \(name)"
}

// ✅ Paramètre raccourci
let greeting: (String) -> String = {
    "Bonjour \($0)"
}
```

### ✅ Trailing Closures

```swift
// ✅ PRÉFÉRÉ : Trailing closure
events.filter { $0.category == .birthday }

// Équivalent à :
events.filter({ $0.category == .birthday })

// ✅ Multiple trailing closures (Swift 5.3+)
UIView.animate(
    withDuration: 0.3
) {
    view.alpha = 0
} completion: { _ in
    view.removeFromSuperview()
}
```

### ✅ Capture Lists

**Éviter les retain cycles**

```swift
// ❌ RETAIN CYCLE
class EventViewModel {
    var onUpdate: (() -> Void)?

    func setupObserver() {
        onUpdate = {
            self.refresh() // ❌ Capture forte de self
        }
    }
}

// ✅ WEAK SELF
class EventViewModel {
    var onUpdate: (() -> Void)?

    func setupObserver() {
        onUpdate = { [weak self] in
            self?.refresh() // ✅ Pas de retain cycle
        }
    }
}

// ✅ UNOWNED (si vous êtes sûr que self existe toujours)
onUpdate = { [unowned self] in
    self.refresh()
}
```

### ✅ @escaping

**Marquer les closures qui s'exécutent après le retour de la fonction**

```swift
// ✅ Closure qui s'exécute plus tard
func fetchData(completion: @escaping ([Event]) -> Void) {
    DispatchQueue.global().async {
        // Requête réseau...
        completion(events) // S'exécute après le return de fetchData
    }
}

// ⚠️ Aujourd'hui : Préférer async/await
func fetchData() async -> [Event] {
    // Pas besoin de @escaping
}
```

---

## Protocols et Extensions

### ✅ Protocols

```swift
// ✅ Protocol de base
protocol Identifiable {
    var id: UUID { get }
}

// ✅ Protocol avec méthodes
protocol Syncable {
    func sync() async throws
    var needsSync: Bool { get set }
}

// ✅ Protocol avec valeurs par défaut
extension Syncable {
    var needsSync: Bool {
        get { false }
        set { }
    }
}

// ✅ Conformance
struct Event: Identifiable, Syncable {
    let id: UUID

    func sync() async throws {
        // Implémentation
    }
}
```

### ✅ Extensions

**Ajouter des fonctionnalités aux types existants**

```swift
// ✅ Extension sur String
extension String {
    var isValidEmail: Bool {
        contains("@") && contains(".")
    }

    func truncated(to length: Int) -> String {
        if count > length {
            return String(prefix(length)) + "..."
        }
        return self
    }
}

// Utilisation
let email = "test@example.com"
print(email.isValidEmail) // true
```

### ✅ Extension avec contraintes

```swift
// ✅ Extension uniquement pour les tableaux d'Event
extension Array where Element == Event {
    func upcomingEvents() -> [Event] {
        filter { $0.date > Date() }
            .sorted { $0.date < $1.date }
    }
}

// Utilisation
let upcoming = events.upcomingEvents()
```

### ✅ Protocol-Oriented Programming

```swift
// ✅ Définir un protocol
protocol EventProviding {
    func fetchEvents() async throws -> [Event]
}

// ✅ Implémentation réelle
class SupabaseEventProvider: EventProviding {
    func fetchEvents() async throws -> [Event] {
        // Vraie requête Supabase
    }
}

// ✅ Mock pour les tests
class MockEventProvider: EventProviding {
    func fetchEvents() async throws -> [Event] {
        // Données de test
        return [Event.preview]
    }
}

// ✅ ViewModel indépendant de l'implémentation
class EventViewModel {
    private let provider: EventProviding

    init(provider: EventProviding) {
        self.provider = provider
    }

    func load() async {
        let events = try? await provider.fetchEvents()
        // ...
    }
}
```

---

## Property Wrappers

### @State (SwiftUI)

```swift
// ✅ État local à la vue
struct ContentView: View {
    @State private var isShowingSheet = false
    @State private var selectedEvent: Event?

    var body: some View {
        Button("Afficher") {
            isShowingSheet = true // Déclenche une mise à jour
        }
    }
}
```

### @Binding (SwiftUI)

```swift
// ✅ Référence à un @State parent
struct ChildView: View {
    @Binding var isPresented: Bool

    var body: some View {
        Button("Fermer") {
            isPresented = false // Modifie le @State du parent
        }
    }
}

// Utilisation
struct ParentView: View {
    @State private var isShowing = false

    var body: some View {
        ChildView(isPresented: $isShowing) // $ pour créer un Binding
    }
}
```

### @Observable (iOS 17+)

```swift
// ✅ MODERNE : Remplace ObservableObject
@Observable
class EventViewModel {
    var events: [Event] = []
    var isLoading = false

    func load() async {
        isLoading = true
        // Chargement...
        isLoading = false
    }
}

// Utilisation dans une View
struct EventsView: View {
    @State private var viewModel = EventViewModel()

    var body: some View {
        List(viewModel.events) { event in
            Text(event.title)
        }
    }
}
```

### @Environment (SwiftUI)

```swift
// ✅ Accès aux valeurs d'environnement
struct MyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Button("Fermer") {
            dismiss()
        }
    }
}
```

---

## Collections

### Arrays

```swift
// ✅ Création
var events: [Event] = []
let numbers = [1, 2, 3, 4, 5]

// ✅ Accès
let first = events.first // Optional<Event>
let firstForce = events[0] // ⚠️ Crash si vide

// ✅ Méthodes utiles
events.append(newEvent)
events.insert(newEvent, at: 0)
events.remove(at: 0)
events.removeAll()

// ✅ Filter, map, reduce
let birthdays = events.filter { $0.category == .birthday }
let titles = events.map { $0.title }
let count = events.reduce(0) { $0 + 1 }

// ✅ First/Last où
let nextEvent = events.first { $0.date > Date() }

// ✅ Sorted
let sorted = events.sorted { $0.date < $1.date }
```

### Sets

```swift
// ✅ Création (éléments uniques, pas d'ordre)
var categories: Set<String> = ["birthday", "wedding"]

// ✅ Opérations
categories.insert("party")
categories.remove("birthday")
categories.contains("wedding") // true

// ✅ Opérations ensemblistes
let set1: Set = [1, 2, 3]
let set2: Set = [3, 4, 5]
let union = set1.union(set2) // [1, 2, 3, 4, 5]
let intersection = set1.intersection(set2) // [3]
```

### Dictionaries

```swift
// ✅ Création
var eventsByCategory: [String: [Event]] = [:]

// ✅ Accès (retourne Optional)
let birthdays = eventsByCategory["birthday"] // Optional<[Event]>

// ✅ Ajout/Modification
eventsByCategory["birthday"] = [event1, event2]

// ✅ Valeur par défaut
let count = eventsByCategory["birthday"]?.count ?? 0

// ✅ Itération
for (category, events) in eventsByCategory {
    print("\(category): \(events.count)")
}
```

---

## Naming Conventions

### Types

```swift
// ✅ UpperCamelCase
struct Event { }
class EventViewModel { }
enum EventCategory { }
protocol Syncable { }
```

### Variables et fonctions

```swift
// ✅ lowerCamelCase
var eventTitle: String
func fetchEvents() { }
let maxCount = 100
```

### Booléens

```swift
// ✅ Préfixes is/has/should/can
var isLoading: Bool
var hasGiftPool: Bool
var shouldSync: Bool
var canEdit: Bool
```

### Private

```swift
// ✅ Toujours marquer private ce qui ne doit pas être exposé
private var internalState = false
private func helperMethod() { }

// ✅ Private(set) pour lecture publique, écriture privée
private(set) var events: [Event] = []
```

### Constants

```swift
// ✅ lowerCamelCase (PAS de SCREAMING_CASE)
let maxEventCount = 100
let defaultCategory = "birthday"

// ✅ Static pour les constantes de classe/struct
struct Config {
    static let apiURL = "https://api.example.com"
    static let timeout: TimeInterval = 30
}
```

---

## Pièges courants

### 1. Force unwrap (!)

```swift
// ❌ CRASH GARANTI si nil
let name = user!.name

// ✅ SAFE
guard let user = user else { return }
let name = user.name
```

### 2. Mutable vs Immutable

```swift
// ❌ Utiliser var sans raison
var title = "Hello" // Ne change jamais

// ✅ Préférer let
let title = "Hello"
```

### 3. Retain Cycles

```swift
// ❌ MEMORY LEAK
class ViewController {
    var closure: (() -> Void)?

    func setup() {
        closure = {
            self.doSomething() // Retain cycle
        }
    }
}

// ✅ SAFE
closure = { [weak self] in
    self?.doSomething()
}
```

### 4. String Concatenation

```swift
// ❌ PEU PERFORMANT
var result = ""
for item in items {
    result = result + item
}

// ✅ PERFORMANT
let result = items.joined(separator: "")
```

### 5. Type Inference Ambiguë

```swift
// ❌ Compilateur confus
let value = 0.0 // Double ou Float ?

// ✅ CLAIR
let value: Double = 0.0
```

---

## Ressources officielles

- [The Swift Programming Language](https://docs.swift.org/swift-book/)
- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [Swift Evolution](https://apple.github.io/swift-evolution/)

---

**Version** : 1.0.0
**Dernière mise à jour** : 04 Décembre 2025
