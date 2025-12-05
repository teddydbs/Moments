# iOS Guidelines - Conventions et Bonnes Pratiques

Guide des conventions iOS, UX, accessibilité et ressources pour le projet Moments.

## 📚 Table des matières

1. [Human Interface Guidelines](#human-interface-guidelines)
2. [Accessibilité](#accessibilité)
3. [SF Symbols](#sf-symbols)
4. [Colors et Theming](#colors-et-theming)
5. [Typography](#typography)
6. [Layout et Spacing](#layout-et-spacing)
7. [Navigation Patterns](#navigation-patterns)
8. [Forms et Input](#forms-et-input)
9. [Feedback Utilisateur](#feedback-utilisateur)
10. [Assets et Resources](#assets-et-resources)

---

## Human Interface Guidelines

### Principes fondamentaux Apple

✅ **Clarity (Clarté)** : L'interface doit être claire et compréhensible
✅ **Deference (Déférence)** : Le contenu prime sur l'interface
✅ **Depth (Profondeur)** : Utiliser la hiérarchie visuelle et le mouvement

### Appliquer dans Moments

```swift
// ✅ CLARTÉ : Textes lisibles, icônes reconnaissables
Text("Anniversaire de Marie")
    .font(.headline)

// ✅ DÉFÉRENCE : Le contenu (événements) est au centre
NavigationStack {
    List(events) { event in
        EventRow(event: event)
    }
    .navigationTitle("Événements") // Titre discret
}

// ✅ PROFONDEUR : Navigation claire, transitions fluides
NavigationLink(value: event) {
    EventRow(event: event)
}
```

---

## Accessibilité

### VoiceOver

**Toujours fournir des labels pour VoiceOver**

```swift
// ✅ ACCESSIBLE
Button {
    addEvent()
} label: {
    Image(systemName: "plus")
}
.accessibilityLabel("Ajouter un événement")

// ❌ PAS ACCESSIBLE
Button {
    addEvent()
} label: {
    Image(systemName: "plus")
}
// VoiceOver dira juste "bouton" sans contexte
```

### Accessibility Hints

```swift
// ✅ HINT pour clarifier l'action
Button("Partager") {
    shareEvent()
}
.accessibilityLabel("Partager l'événement")
.accessibilityHint("Ouvre le menu de partage")
```

### Dynamic Type

**Supporter les tailles de texte dynamiques**

```swift
// ✅ BONNE PRATIQUE : Utiliser les styles système
Text("Titre")
    .font(.headline) // S'adapte automatiquement à la taille de texte

// ❌ ÉVITER : Tailles fixes
Text("Titre")
    .font(.system(size: 18)) // Ne s'adapte pas
```

### Grouping pour VoiceOver

```swift
// ✅ GROUPER les éléments liés
HStack {
    Image(systemName: "calendar")
    Text("12 Décembre 2025")
}
.accessibilityElement(children: .combine)
// VoiceOver lira : "calendrier, 12 Décembre 2025"
```

### Contrast et Lisibilité

```swift
// ✅ CONTRASTE suffisant
Text("Important")
    .foregroundColor(.white)
    .background(Color.blue) // ✅ Bon contraste

// ⚠️ VÉRIFIER le contraste
Text("Important")
    .foregroundColor(.gray)
    .background(Color.white) // ⚠️ Faible contraste
```

---

## SF Symbols

### Utilisation des symboles système

```swift
// ✅ UTILISER SF Symbols pour la cohérence
Image(systemName: "calendar")
Image(systemName: "gift.fill")
Image(systemName: "person.2.fill")

// ✅ TAILLE adaptative
Image(systemName: "heart.fill")
    .imageScale(.small)  // Petite
    .imageScale(.medium) // Moyenne (défaut)
    .imageScale(.large)  // Grande

// ✅ FONT-based sizing
Image(systemName: "star.fill")
    .font(.title)
    .font(.headline)
    .font(.caption)
```

### Symboles par catégorie pour Moments

```swift
// ✅ ÉVÉNEMENTS
let eventIcons = [
    "birthday": "gift.fill",
    "wedding": "heart.fill",
    "party": "party.popper.fill",
    "other": "calendar"
]

// ✅ ACTIONS
let actionIcons = [
    "add": "plus",
    "edit": "pencil",
    "delete": "trash",
    "share": "square.and.arrow.up",
    "search": "magnifyingglass"
]

// ✅ NAVIGATION
let navIcons = [
    "home": "house.fill",
    "settings": "gearshape.fill",
    "profile": "person.fill"
]
```

### Rendre les symboles multicolores

```swift
// ✅ SYMBOLES MULTICOLORES (iOS 15+)
Image(systemName: "calendar")
    .symbolRenderingMode(.multicolor)

// ✅ PALETTE personnalisée
Image(systemName: "heart.fill")
    .symbolRenderingMode(.palette)
    .foregroundStyle(.red, .pink)
```

---

## Colors et Theming

### Couleurs système (Dynamic Colors)

```swift
// ✅ UTILISER les couleurs système (s'adaptent au Dark Mode)
Color.primary       // Texte principal
Color.secondary     // Texte secondaire
Color.blue          // Bleu système
Color.red           // Rouge système
Color.green         // Vert système

// ✅ COULEURS SÉMANTIQUES
Color(uiColor: .systemBackground)  // Background principal
Color(uiColor: .secondarySystemBackground) // Background secondaire
Color(uiColor: .label)             // Label principal
Color(uiColor: .secondaryLabel)    // Label secondaire
```

### Asset Catalog Colors

**Créer vos couleurs dans Assets.xcassets**

```swift
// 1. Dans Xcode: Assets.xcassets → Clic droit → New Color Set
// 2. Nommer : "AccentColor", "PrimaryColor", etc.
// 3. Configurer : Any Appearance + Dark Appearance

// Utilisation dans le code :
Color("AccentColor")
Color("PrimaryColor")
```

### Dark Mode

```swift
// ✅ ADAPTATION AUTOMATIQUE avec couleurs système
struct ContentView: View {
    var body: some View {
        VStack {
            Text("Hello")
                .foregroundColor(.primary) // ✅ Adaptatif
                .background(Color(uiColor: .systemBackground)) // ✅ Adaptatif
        }
    }
}

// ✅ COULEURS PERSONNALISÉES adaptatives
extension Color {
    static let customBackground = Color("CustomBackground")
    // Défini dans Assets avec une variante Dark
}

// ✅ FORCER un color scheme (pour preview/test)
#Preview("Dark") {
    ContentView()
        .preferredColorScheme(.dark)
}
```

### Gradients

```swift
// ✅ GRADIENT LINÉAIRE
LinearGradient(
    colors: [.blue, .purple],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)

// ✅ GRADIENT RADIAL
RadialGradient(
    colors: [.white, .blue],
    center: .center,
    startRadius: 0,
    endRadius: 200
)
```

---

## Typography

### Text Styles système

```swift
// ✅ HIÉRARCHIE TYPOGRAPHIQUE
Text("Titre principal")
    .font(.largeTitle)

Text("Titre de section")
    .font(.title)

Text("Sous-titre")
    .font(.title2)

Text("Headline")
    .font(.headline)

Text("Corps de texte")
    .font(.body)

Text("Caption")
    .font(.caption)

Text("Footnote")
    .font(.footnote)
```

### Custom Fonts

```swift
// ✅ POLICE PERSONNALISÉE (si ajoutée au projet)
Text("Hello")
    .font(.custom("CustomFont-Bold", size: 24))

// ✅ AVEC Dynamic Type
Text("Hello")
    .font(.custom("CustomFont-Regular", size: 17, relativeTo: .body))
```

### Weight et Style

```swift
// ✅ FONT WEIGHT
Text("Important")
    .fontWeight(.bold)
    .fontWeight(.semibold)
    .fontWeight(.regular)

// ✅ ITALIC
Text("Emphasis")
    .italic()

// ✅ DESIGN
Text("Rounded")
    .font(.system(.body, design: .rounded))
    .font(.system(.body, design: .serif))
    .font(.system(.body, design: .monospaced))
```

---

## Layout et Spacing

### Spacing Standards

```swift
// ✅ SPACING STANDARDS iOS
let spacing: CGFloat = 8    // Petit
let spacing: CGFloat = 16   // Moyen (défaut)
let spacing: CGFloat = 24   // Grand
let spacing: CGFloat = 32   // Très grand

// Utilisation
VStack(spacing: 16) {
    Text("Hello")
    Text("World")
}

// ✅ PADDING
Text("Hello")
    .padding()           // 16 par défaut
    .padding(.horizontal, 20)
    .padding(.vertical, 12)
```

### Safe Area

```swift
// ✅ RESPECTER la Safe Area
VStack {
    Text("Content")
}
.padding() // ✅ Respecte automatiquement la safe area

// ❌ IGNORER seulement si nécessaire
Color.blue
    .ignoresSafeArea() // Pour un background plein écran
```

### Layout Priorities

```swift
// ✅ LAYOUT PRIORITY
HStack {
    Text("Texte long qui peut être tronqué...")
        .lineLimit(1)
        .layoutPriority(0) // ✅ Peut être compressé

    Spacer()

    Button("Action") { }
        .layoutPriority(1) // ✅ Garde sa taille
}
```

---

## Navigation Patterns

### Tab Bar

**Maximum 5 tabs**

```swift
// ✅ TAB BAR (2-5 tabs)
TabView {
    BirthdaysView()
        .tabItem {
            Label("Anniversaires", systemImage: "gift.fill")
        }

    EventsView()
        .tabItem {
            Label("Événements", systemImage: "calendar")
        }

    SettingsView()
        .tabItem {
            Label("Réglages", systemImage: "gearshape.fill")
        }
}
```

### Navigation Bar

```swift
// ✅ NAVIGATION TITLE
.navigationTitle("Événements")

// ✅ LARGE TITLE (défile avec le contenu)
.navigationBarTitleDisplayMode(.large)

// ✅ INLINE (toujours petit)
.navigationBarTitleDisplayMode(.inline)

// ✅ TOOLBAR
.toolbar {
    ToolbarItem(placement: .primaryAction) {
        Button("Ajouter") { }
    }

    ToolbarItem(placement: .navigationBarLeading) {
        Button("Annuler") { }
    }
}
```

### Modals et Sheets

```swift
// ✅ SHEET (modal avec barre de glissement)
.sheet(isPresented: $isShowing) {
    DetailView()
}

// ✅ FULL SCREEN COVER (plein écran)
.fullScreenCover(isPresented: $isShowing) {
    OnboardingView()
}

// ✅ PRESENTATION DETENTS (iOS 16+)
.sheet(isPresented: $isShowing) {
    DetailView()
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
}
```

---

## Forms et Input

### TextField

```swift
// ✅ TEXTFIELD SIMPLE
TextField("Nom", text: $name)
    .textFieldStyle(.roundedBorder)

// ✅ AVEC PROMPT
TextField("Email", text: $email, prompt: Text("exemple@mail.com"))
    .textInputAutocapitalization(.never)
    .keyboardType(.emailAddress)
    .autocorrectionDisabled()

// ✅ SECURE FIELD
SecureField("Mot de passe", text: $password)
```

### Validation visuelle

```swift
// ✅ FEEDBACK VISUEL
TextField("Email", text: $email)
    .textFieldStyle(.roundedBorder)
    .overlay(alignment: .trailing) {
        if isValidEmail {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        }
    }

// ✅ MESSAGE D'ERREUR
VStack(alignment: .leading) {
    TextField("Email", text: $email)
        .textFieldStyle(.roundedBorder)

    if !errorMessage.isEmpty {
        Text(errorMessage)
            .font(.caption)
            .foregroundColor(.red)
    }
}
```

### Pickers

```swift
// ✅ PICKER STANDARD
Picker("Catégorie", selection: $category) {
    ForEach(EventCategory.allCases, id: \.self) { category in
        Text(category.rawValue).tag(category)
    }
}
.pickerStyle(.menu)      // Menu déroulant
.pickerStyle(.segmented) // Segments
.pickerStyle(.wheel)     // Roue
```

### DatePicker

```swift
// ✅ DATE PICKER
DatePicker(
    "Date",
    selection: $date,
    displayedComponents: [.date, .hourAndMinute]
)
.datePickerStyle(.compact)  // Compact
.datePickerStyle(.graphical) // Calendrier
.datePickerStyle(.wheel)     // Roue
```

---

## Feedback Utilisateur

### Alerts

```swift
// ✅ ALERT SIMPLE
.alert("Titre", isPresented: $showingAlert) {
    Button("OK", role: .cancel) { }
} message: {
    Text("Message détaillé")
}

// ✅ ALERT AVEC ACTIONS
.alert("Supprimer ?", isPresented: $showingAlert) {
    Button("Annuler", role: .cancel) { }
    Button("Supprimer", role: .destructive) {
        delete()
    }
}
```

### Toast / Snackbar (SwiftUI custom)

```swift
// ✅ TOAST CUSTOM
@State private var showToast = false
@State private var toastMessage = ""

var body: some View {
    ZStack {
        // Contenu principal

        if showToast {
            VStack {
                Spacer()

                Text(toastMessage)
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(.bottom, 50)
            }
            .transition(.move(edge: .bottom))
            .animation(.spring(), value: showToast)
        }
    }
}

func showToast(_ message: String) {
    toastMessage = message
    withAnimation {
        showToast = true
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        withAnimation {
            showToast = false
        }
    }
}
```

### ProgressView

```swift
// ✅ LOADING INDÉTERMINÉ
ProgressView()

// ✅ AVEC LABEL
ProgressView("Chargement...")

// ✅ PROGRESS DÉTERMINÉ
ProgressView(value: 0.6)

// ✅ AVEC MIN/MAX
ProgressView(value: currentValue, total: maxValue)
```

### Haptic Feedback

```swift
// ✅ FEEDBACK HAPTIQUE
import UIKit

// Impact
UIImpactFeedbackGenerator(style: .light).impactOccurred()
UIImpactFeedbackGenerator(style: .medium).impactOccurred()
UIImpactFeedbackGenerator(style: .heavy).impactOccurred()

// Notification
UINotificationFeedbackGenerator().notificationOccurred(.success)
UINotificationFeedbackGenerator().notificationOccurred(.warning)
UINotificationFeedbackGenerator().notificationOccurred(.error)

// Selection
UISelectionFeedbackGenerator().selectionChanged()

// Utilisation dans SwiftUI
Button("Delete") {
    UINotificationFeedbackGenerator().notificationOccurred(.warning)
    delete()
}
```

---

## Assets et Resources

### Organisation des Assets

```
Assets.xcassets/
├── AppIcon.appiconset/
├── AccentColor.colorset/
├── Colors/
│   ├── PrimaryColor.colorset
│   ├── SecondaryColor.colorset
│   └── BackgroundColor.colorset
├── Images/
│   ├── logo.imageset
│   └── placeholder.imageset
└── Symbols/
    └── custom-icon.symbolset
```

### App Icon

**Tailles requises** (selon iOS version) :
- 1024x1024 (App Store)
- 180x180 (iPhone)
- 167x167 (iPad Pro)
- 152x152 (iPad)
- 120x120 (iPhone)
- Etc.

**⚠️ Utiliser un outil** : [AppIcon.co](https://www.appicon.co/) pour générer toutes les tailles

### Images

```swift
// ✅ IMAGE DEPUIS ASSETS
Image("logo")
    .resizable()
    .scaledToFit()
    .frame(width: 100, height: 100)

// ✅ IMAGE SYSTÈME (SF Symbol)
Image(systemName: "heart.fill")
    .foregroundColor(.red)

// ✅ IMAGE ASYNCHRONE
AsyncImage(url: URL(string: imageURL)) { image in
    image
        .resizable()
        .scaledToFill()
} placeholder: {
    ProgressView()
}
.frame(width: 200, height: 200)
.clipped()
```

### Localisation

**Fichier Localizable.strings**

```
// fr.lproj/Localizable.strings
"welcome_message" = "Bienvenue sur Moments";
"add_event" = "Ajouter un événement";
"delete_confirmation" = "Êtes-vous sûr de vouloir supprimer ?";

// en.lproj/Localizable.strings
"welcome_message" = "Welcome to Moments";
"add_event" = "Add event";
"delete_confirmation" = "Are you sure you want to delete?";
```

**Utilisation**

```swift
// ✅ LOCALISATION
Text(NSLocalizedString("welcome_message", comment: ""))

// ✅ AVEC EXTENSION
extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
}

Text("welcome_message".localized)

// ✅ AVEC INTERPOLATION
Text("hello_user \(userName)")
// Localizable.strings: "hello_user" = "Bonjour %@";
```

---

## Checklist UX/UI

### ✅ Avant de publier

- [ ] **Accessibilité** : Tous les boutons ont un `.accessibilityLabel`
- [ ] **VoiceOver** : Navigation fluide avec VoiceOver activé
- [ ] **Dynamic Type** : Utilisation des text styles système
- [ ] **Dark Mode** : Tous les écrans sont lisibles en dark mode
- [ ] **Landscape** : L'app fonctionne en mode paysage (si applicable)
- [ ] **iPad** : L'app s'adapte sur iPad (si universal)
- [ ] **Localisation** : Textes traduits (au moins EN + FR)
- [ ] **Safe Area** : Respect des safe areas sur tous les écrans
- [ ] **Loading States** : Indicateurs de chargement visibles
- [ ] **Error States** : Messages d'erreur clairs
- [ ] **Empty States** : ContentUnavailableView quand pas de données
- [ ] **Haptic Feedback** : Retour haptique sur les actions importantes
- [ ] **SF Symbols** : Utilisation cohérente des icônes système
- [ ] **App Icon** : Toutes les tailles générées
- [ ] **Launch Screen** : Écran de lancement configuré

---

## Ressources officielles

- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SF Symbols App](https://developer.apple.com/sf-symbols/)
- [Accessibility Documentation](https://developer.apple.com/accessibility/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)

---

**Version** : 1.0.0
**Dernière mise à jour** : 04 Décembre 2025
