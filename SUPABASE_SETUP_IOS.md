# Guide d'installation Supabase pour Moments (iOS)

Ce guide vous explique comment intégrer Supabase dans votre application iOS Moments.

## 📦 Étape 1 : Installation du SDK Supabase

### Option A : Via Xcode (Recommandé)

1. Ouvrez votre projet `Moments.xcodeproj` dans Xcode
2. Allez dans **File** → **Add Package Dependencies...**
3. Collez cette URL : `https://github.com/supabase-community/supabase-swift`
4. Sélectionnez la version `2.0.0` ou supérieure
5. Cliquez sur **Add Package**
6. Sélectionnez les modules suivants :
   - `Supabase`
   - `PostgREST`
   - `Realtime`
   - `Storage`
   - `Auth`

### Option B : Via Package.swift

Si vous utilisez SPM en ligne de commande, ajoutez ceci à votre `Package.swift` :

```swift
dependencies: [
    .package(
        url: "https://github.com/supabase-community/supabase-swift",
        from: "2.0.0"
    )
],
targets: [
    .target(
        name: "Moments",
        dependencies: [
            .product(name: "Supabase", package: "supabase-swift"),
        ]
    )
]
```

## 🔧 Étape 2 : Configuration

### 1. Récupérer vos clés Supabase

Allez sur votre dashboard Supabase :
```
https://supabase.com/dashboard/project/YOUR-PROJECT/settings/api
```

Notez :
- **Project URL** : `https://xxxxxx.supabase.co`
- **Anon/Public Key** : `eyJhbGc...`

### 2. Configurer SupabaseConfig.swift

Éditez le fichier `Moments/Services/Backend/SupabaseConfig.swift` :

```swift
import Foundation

struct SupabaseConfig {
    // Remplacez avec vos vraies valeurs
    static let supabaseURL = URL(string: "https://votre-projet.supabase.co")!
    static let supabaseAnonKey = "votre-anon-key-ici"

    struct EdgeFunctions {
        static let affiliateConvert = "affiliate-convert"
        static let stripeWebhook = "stripe-webhook"
        static let eventsShare = "events-share"
    }

    struct Storage {
        static let eventImages = "event-images"
        static let avatars = "avatars"
    }
}
```

## 🔓 Étape 3 : Décommenter le code

### 1. Dans SupabaseManager.swift

Décommentez les sections suivantes :

```swift
// EN HAUT DU FICHIER (ligne ~10)
import Supabase
import PostgREST
import Realtime
import Storage

// DANS L'INIT (ligne ~25)
let client: SupabaseClient

private init() {
    self.client = SupabaseClient(
        supabaseURL: SupabaseConfig.supabaseURL,
        supabaseKey: SupabaseConfig.supabaseAnonKey
    )

    Task {
        await checkAuthStatus()
    }
}
```

Ensuite, décommentez **toutes les fonctions** marquées avec :
```swift
// TODO: Implémenter après installation du SDK
```

### 2. Dans SyncManager.swift

Le SyncManager devrait fonctionner automatiquement une fois SupabaseManager configuré.

## 🧪 Étape 4 : Tester l'intégration

### 1. Créer une vue de test d'authentification

Créez un fichier `TestSupabaseView.swift` pour tester :

```swift
import SwiftUI

struct TestSupabaseView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var message = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("Test Supabase")
                .font(.title)

            if supabase.isAuthenticated {
                Text("✅ Connecté")
                    .foregroundColor(.green)

                if let user = supabase.currentUser {
                    Text("Email: \(user.email)")
                }

                Button("Se déconnecter") {
                    Task {
                        try? await supabase.signOut()
                        message = "Déconnecté"
                    }
                }
            } else {
                TextField("Email", text: $email)
                    .textFieldStyle(.roundedBorder)
                    .textInputAutocapitalization(.never)

                SecureField("Mot de passe", text: $password)
                    .textFieldStyle(.roundedBorder)

                Button("S'inscrire") {
                    Task {
                        do {
                            try await supabase.signUp(
                                email: email,
                                password: password,
                                name: "Test User"
                            )
                            message = "✅ Inscription réussie"
                        } catch {
                            message = "❌ Erreur: \(error.localizedDescription)"
                        }
                    }
                }

                Button("Se connecter") {
                    Task {
                        do {
                            try await supabase.signIn(
                                email: email,
                                password: password
                            )
                            message = "✅ Connexion réussie"
                        } catch {
                            message = "❌ Erreur: \(error.localizedDescription)"
                        }
                    }
                }
            }

            if !message.isEmpty {
                Text(message)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding()
    }
}

#Preview {
    TestSupabaseView()
}
```

### 2. Lancer l'app et tester

1. Compilez et lancez l'app
2. Ouvrez `TestSupabaseView`
3. Essayez de créer un compte
4. Vérifiez dans le dashboard Supabase que l'utilisateur apparaît dans **Authentication**

## 🔄 Étape 5 : Intégrer la synchronisation

### Modifier MainTabView.swift

Ajoutez le SyncManager à votre vue principale :

```swift
import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var syncManager: SyncManager

    init() {
        // Récupérer le modelContext via l'initializer n'est pas possible directement
        // On va créer le SyncManager dans .task
    }

    var body: some View {
        TabView {
            BirthdaysView()
                .tabItem {
                    Label("Anniversaires", systemImage: "gift.fill")
                }

            EventsView()
                .tabItem {
                    Label("Événements", systemImage: "calendar")
                }
        }
        .task {
            // Synchronisation au démarrage
            let syncManager = SyncManager(modelContext: modelContext)
            do {
                try await syncManager.performFullSync()
            } catch {
                print("Erreur de sync: \(error)")
            }
        }
        .refreshable {
            // Pull-to-refresh
            let syncManager = SyncManager(modelContext: modelContext)
            try? await syncManager.performFullSync()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Sync quand l'app revient au premier plan
                Task {
                    let syncManager = SyncManager(modelContext: modelContext)
                    try? await syncManager.performFullSync()
                }
            }
        }
    }
}
```

### Marquer les événements pour la sync

Quand vous créez ou modifiez un événement, marquez-le pour synchronisation :

```swift
// Dans AddEditEventView.swift, après avoir sauvegardé un événement
private func saveEvent() {
    Task {
        // ... votre code existant ...

        // Marquer pour synchronisation
        let syncManager = SyncManager(modelContext: modelContext)
        syncManager.markEventForSync(newEvent)

        // Synchroniser immédiatement (optionnel)
        await syncManager.quickSync()
    }
}
```

## 🎨 Étape 6 : Ajouter un indicateur de sync

Créez une vue pour montrer l'état de synchronisation :

```swift
struct SyncStatusView: View {
    @ObservedObject var syncManager: SyncManager

    var body: some View {
        HStack(spacing: 8) {
            if syncManager.isSyncing {
                ProgressView()
                    .controlSize(.small)
                Text("Synchronisation...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let lastSync = syncManager.lastSyncDate {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Sync: \(lastSync, style: .relative)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}
```

## ⚠️ Erreurs courantes

### "Module 'Supabase' not found"
→ Le package n'est pas correctement installé. Relancez l'ajout via Xcode.

### "Cannot find type 'SupabaseClient'"
→ Vérifiez que vous avez bien importé `import Supabase` en haut du fichier.

### "Invalid JWT"
→ Votre clé Anon est incorrecte ou expirée. Vérifiez dans le dashboard Supabase.

### "Permission denied" lors de la création d'événement
→ Les Row Level Security policies ne permettent pas l'insertion. Vérifiez que vous êtes authentifié et que les policies sont correctes.

### La synchronisation ne fonctionne pas
→ Vérifiez que :
1. L'utilisateur est authentifié (`SupabaseManager.shared.isAuthenticated`)
2. Les migrations SQL ont été exécutées
3. Les RLS policies sont actives
4. Le modelContext est bien passé au SyncManager

## 📱 Étape 7 : Configuration du deep linking (optionnel)

Pour gérer les invitations à des événements :

1. Ajoutez dans `Info.plist` :

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>moments</string>
        </array>
    </dict>
</array>
```

2. Gérez les URLs dans `MomentsApp.swift` :

```swift
import SwiftUI

@main
struct MomentsApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
        .modelContainer(for: [Event.self, Participant.self, GiftIdea.self])
    }

    func handleDeepLink(_ url: URL) {
        // Exemple: moments://invite?token=xxx
        if url.scheme == "moments", url.host == "invite" {
            if let token = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first(where: { $0.name == "token" })?
                .value {
                print("Invitation token: \(token)")
                // TODO: Accepter l'invitation
            }
        }
    }
}
```

## ✅ Checklist finale

- [ ] SDK Supabase installé via Xcode
- [ ] SupabaseConfig.swift configuré avec les bonnes clés
- [ ] Imports décommentés dans SupabaseManager.swift
- [ ] Toutes les fonctions décommentées dans SupabaseManager.swift
- [ ] Test de l'authentification réussi
- [ ] Migrations SQL exécutées dans Supabase
- [ ] Edge Functions déployées (optionnel pour le début)
- [ ] SyncManager intégré dans MainTabView
- [ ] Premier événement créé et synchronisé

## 🚀 Prochaines étapes

Une fois l'installation terminée :

1. **Testez l'authentification** complète (inscription, connexion, déconnexion)
2. **Créez un événement** et vérifiez qu'il apparaît dans Supabase
3. **Testez la synchronisation** en créant un événement dans le dashboard Supabase
4. **Ajoutez des participants** et des idées cadeaux
5. **Configurez Stripe** pour les cagnottes (plus tard)
6. **Déployez les Edge Functions** pour l'affiliation Amazon

## 📚 Ressources utiles

- [Documentation Supabase Swift](https://github.com/supabase-community/supabase-swift)
- [Exemples de code](https://github.com/supabase-community/supabase-swift/tree/main/Examples)
- [Discord Supabase](https://discord.supabase.com)

---

**Besoin d'aide ?** Consultez le README dans `supabase/README.md` ou la documentation officielle Supabase.
