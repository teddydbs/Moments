# 🚀 Quick Start - Backend Supabase pour Moments

Guide rapide pour démarrer avec Supabase en 15 minutes.

## ⏱️ Setup en 5 étapes (15 minutes)

### 1️⃣ Créer le projet Supabase (3 min)

```bash
# 1. Allez sur https://supabase.com/dashboard
# 2. Cliquez sur "New Project"
# 3. Nom: moments-dev
# 4. Database Password: (générez-en un fort)
# 5. Region: Europe (Paris) ou proche de vous
# 6. Attendez ~2 minutes que le projet soit créé
```

**✅ Vous avez maintenant** :
- Project URL: `https://xxxxxx.supabase.co`
- Anon Key: `eyJhbGc...`

### 2️⃣ Exécuter les migrations SQL (2 min)

```bash
# Ouvrez le SQL Editor dans Supabase
# https://supabase.com/dashboard/project/YOUR-PROJECT/sql

# Copiez-collez et exécutez dans l'ordre :
# 1. Le contenu de: supabase/migrations/20250101000000_initial_schema.sql
# 2. Le contenu de: supabase/migrations/20250101000001_rls_policies.sql
```

**✅ Vérification** :
Allez dans Table Editor, vous devriez voir 7 tables :
- users
- events
- participants
- gift_ideas
- contributions
- event_invitations
- affiliate_conversions

### 3️⃣ Installer le SDK Supabase dans Xcode (3 min)

```bash
# 1. Ouvrez Moments.xcodeproj dans Xcode
# 2. File → Add Package Dependencies...
# 3. URL: https://github.com/supabase-community/supabase-swift
# 4. Version: 2.0.0 (ou plus récente)
# 5. Sélectionnez: Supabase, PostgREST, Realtime, Storage, Auth
# 6. Add Package
```

### 4️⃣ Configurer les clés (2 min)

Éditez `Moments/Services/Backend/SupabaseConfig.swift` :

```swift
struct SupabaseConfig {
    // REMPLACEZ AVEC VOS VRAIES VALEURS ↓
    static let supabaseURL = URL(string: "https://xxxxxx.supabase.co")!
    static let supabaseAnonKey = "eyJhbGc..."
}
```

### 5️⃣ Décommenter le code (5 min)

Dans `Moments/Services/Backend/SupabaseManager.swift` :

**A. Décommenter les imports (ligne ~10)** :
```swift
import Supabase
import PostgREST
import Realtime
import Storage
```

**B. Décommenter l'init (ligne ~25)** :
```swift
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

**C. Rechercher et remplacer** :
```
Cherchez: // TODO: Implémenter après installation du SDK
Remplacez: // (supprimez simplement cette ligne)
```

Puis décommentez toutes les sections marquées `/*  ... */`.

**Astuce** : Utilisez `Cmd+F` dans Xcode pour chercher `TODO: Implémenter`

## ✅ Vérification rapide

```bash
# Compiler le projet
# Dans Xcode: Cmd+B

# Si ça compile ✅ → Vous êtes prêt !
# Si erreur ❌ → Vérifiez que tous les imports sont décommentés
```

## 🧪 Test rapide (5 min bonus)

### Créer une vue de test

Créez `TestSupabaseView.swift` :

```swift
import SwiftUI

struct TestSupabaseView: View {
    @StateObject private var supabase = SupabaseManager.shared
    @State private var email = "test@example.com"
    @State private var password = "password123"
    @State private var message = ""

    var body: some View {
        VStack(spacing: 20) {
            Text("🧪 Test Supabase")
                .font(.title)

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
                        message = "✅ Inscription réussie !"
                    } catch {
                        message = "❌ \(error.localizedDescription)"
                    }
                }
            }
            .buttonStyle(.borderedProminent)

            Text(message)
                .foregroundColor(message.contains("✅") ? .green : .red)
        }
        .padding()
    }
}
```

### Modifier MomentsApp.swift temporairement

```swift
@main
struct MomentsApp: App {
    var body: some Scene {
        WindowGroup {
            // Commentez temporairement:
            // MainTabView()

            // Décommentez pour tester:
            TestSupabaseView()
        }
        .modelContainer(for: [Event.self, Participant.self, GiftIdea.self])
    }
}
```

### Lancer le test

1. `Cmd+R` pour lancer l'app
2. Entrez un email et mot de passe
3. Cliquez "S'inscrire"
4. Si vous voyez "✅ Inscription réussie !" → **Tout fonctionne !**

### Vérifier dans Supabase

Allez sur :
```
https://supabase.com/dashboard/project/YOUR-PROJECT/auth/users
```

Vous devriez voir votre utilisateur de test !

## 🎯 Utilisation dans l'app

### Ajouter la synchronisation dans MainTabView

```swift
import SwiftUI
import SwiftData

struct MainTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TabView {
            BirthdaysView()
                .tabItem { Label("Anniversaires", systemImage: "gift.fill") }

            EventsView()
                .tabItem { Label("Événements", systemImage: "calendar") }
        }
        .task {
            // Sync au démarrage
            let syncManager = SyncManager(modelContext: modelContext)
            try? await syncManager.performFullSync()
        }
        .refreshable {
            // Pull-to-refresh
            let syncManager = SyncManager(modelContext: modelContext)
            try? await syncManager.performFullSync()
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            if newPhase == .active {
                // Sync au retour au premier plan
                Task {
                    let syncManager = SyncManager(modelContext: modelContext)
                    try? await syncManager.performFullSync()
                }
            }
        }
    }
}
```

## 📋 Checklist finale

- [ ] Projet Supabase créé
- [ ] Migrations SQL exécutées (7 tables créées)
- [ ] SDK Supabase installé via Xcode
- [ ] `SupabaseConfig.swift` configuré
- [ ] Imports décommentés dans `SupabaseManager.swift`
- [ ] Code décommenté dans `SupabaseManager.swift`
- [ ] Projet compile sans erreur (`Cmd+B`)
- [ ] Test d'inscription réussi
- [ ] Utilisateur visible dans dashboard Supabase

## 🎉 C'est terminé !

Vous avez maintenant :
- ✅ Un backend Supabase fonctionnel
- ✅ Une base de données avec RLS
- ✅ L'authentification opérationnelle
- ✅ La synchronisation automatique
- ✅ Un système offline-first

**Vous pouvez maintenant utiliser l'app normalement !**

Chaque événement créé sera automatiquement synchronisé avec Supabase.

## 🆘 Problèmes ?

### Erreur "Module 'Supabase' not found"
```bash
# Solution:
# 1. Fermez Xcode
# 2. Supprimez DerivedData:
rm -rf ~/Library/Developer/Xcode/DerivedData
# 3. Rouvrez le projet
# 4. File → Packages → Resolve Package Versions
```

### Erreur "Invalid JWT"
```bash
# Vérifiez que votre Anon Key est correcte:
# Dashboard → Settings → API → anon/public
# Copiez la clé complète (commence par "eyJ...")
```

### Erreur "Permission denied"
```bash
# Vérifiez que les RLS policies sont bien créées:
# Dashboard → Table Editor → events → RLS enabled ✅
# Si RLS n'est pas activé, réexécutez le script rls_policies.sql
```

## 📚 Documentation complète

- [ARCHITECTURE.md](./ARCHITECTURE.md) - Architecture détaillée
- [SUPABASE_SETUP_IOS.md](./SUPABASE_SETUP_IOS.md) - Guide complet iOS
- [supabase/README.md](./supabase/README.md) - Documentation backend
- [BACKEND_SETUP_COMPLETE.md](./BACKEND_SETUP_COMPLETE.md) - Récapitulatif

## 💡 Prochaines étapes recommandées

1. **Tester la synchronisation** :
   - Créez un événement dans l'app
   - Vérifiez qu'il apparaît dans Supabase (Table Editor → events)

2. **Tester le mode offline** :
   - Activez le mode Avion
   - Créez un événement
   - Désactivez le mode Avion
   - Faites un pull-to-refresh → L'événement se synchronise !

3. **Déployer les Edge Functions** (optionnel) :
   ```bash
   supabase functions deploy affiliate-convert
   supabase functions deploy events-share
   ```

4. **Configurer Stripe** (pour les cagnottes, plus tard)

---

**Temps total** : ~15-20 minutes
**Difficulté** : Facile
**Support** : Consultez la doc ou ouvrez une issue sur GitHub

🚀 **Bon développement avec Moments !**
