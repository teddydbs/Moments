# Référence Supabase Swift SDK

Documentation complète pour l'utilisation du Supabase Swift SDK dans le projet Moments.

## 📦 Installation

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.37.0")
]
```

## 🔧 Configuration

```swift
import Supabase

let client = SupabaseClient(
    supabaseURL: URL(string: "https://YOUR_PROJECT.supabase.co")!,
    supabaseKey: "YOUR_ANON_KEY"
)
```

---

## 🔐 Authentication

### 1. Inscription (Email/Password)

```swift
// Inscription basique
try await client.auth.signUp(
    email: "user@example.com",
    password: "password123"
)

// Inscription avec métadonnées
try await client.auth.signUp(
    email: "user@example.com",
    password: "password123",
    data: [
        "full_name": .string("John Doe"),
        "age": .number(24)
    ]
)
```

**Comportement** :
- ✅ Si confirmation email activée : retourne `user` mais `session` est null
- ✅ Si confirmation désactivée : retourne `user` ET `session`

### 2. Connexion (Email/Password)

```swift
let session = try await client.auth.signIn(
    email: "user@example.com",
    password: "password123"
)

print("User ID: \(session.user.id)")
print("Email: \(session.user.email ?? "")")
```

### 3. OAuth (Google, Apple, etc.)

```swift
// Lancer le flow OAuth
try await client.auth.signInWithOAuth(
    provider: .google,
    redirectTo: URL(string: "com.yourapp.scheme://login-callback")
)

// Après le callback, récupérer la session depuis l'URL
try await client.auth.session(from: callbackURL)
```

**Providers disponibles** :
- `.google`
- `.apple`
- `.facebook`
- `.github`
- `.twitter`
- etc.

### 4. Récupérer la session courante

```swift
do {
    let session = try await client.auth.session
    print("User ID: \(session.user.id)")
    print("Access Token: \(session.accessToken)")
} catch {
    print("Pas de session active")
}
```

### 5. Accéder aux métadonnées utilisateur

```swift
let session = try await client.auth.session

// Métadonnées utilisateur (user_metadata)
let metadata = session.user.userMetadata
let fullName = metadata["full_name"] as? String
let avatar = metadata["avatar_url"] as? String
let picture = metadata["picture"] as? String // Google/Apple

// Métadonnées applicatives (app_metadata)
let appMetadata = session.user.appMetadata
let provider = appMetadata["provider"] as? String // "google", "apple", etc.
let role = appMetadata["role"] as? String

// Informations de base
let userId = session.user.id.uuidString
let email = session.user.email ?? ""
```

**Champs courants selon le provider** :

**Google OAuth** :
- `email`
- `name` (nom complet)
- `picture` (URL photo)
- `given_name` (prénom)
- `family_name` (nom)

**Apple OAuth** :
- `email`
- `name` (si partagé)

**Email/Password** :
- `email`
- `full_name` (si fourni dans `data` lors du signUp)

### 6. Déconnexion

```swift
try await client.auth.signOut()
```

### 7. Rafraîchir la session

```swift
let refreshedSession = try await client.auth.refreshSession()
```

---

## 💾 Database (Postgrest)

### 1. Fetch (SELECT)

```swift
// Récupérer tous les événements
let events: [MyEvent] = try await client
    .from("my_events")
    .select()
    .execute()
    .value

// Avec filtres
let upcomingEvents: [MyEvent] = try await client
    .from("my_events")
    .select()
    .eq("user_id", value: userId)
    .gte("date", value: today)
    .order("date", ascending: true)
    .execute()
    .value
```

### 2. Insert

```swift
let newEvent: MyEvent = try await client
    .from("my_events")
    .insert(event.toDictionary())
    .select()
    .single()
    .execute()
    .value
```

### 3. Update

```swift
try await client
    .from("my_events")
    .update(event.toDictionary())
    .eq("id", value: eventId)
    .execute()
```

### 4. Delete

```swift
try await client
    .from("my_events")
    .delete()
    .eq("id", value: eventId)
    .execute()
```

### 5. Filtres disponibles

```swift
// Égalité
.eq("column", value: "value")

// Différent
.neq("column", value: "value")

// Comparaisons
.gt("column", value: 10)  // >
.gte("column", value: 10) // >=
.lt("column", value: 10)  // <
.lte("column", value: 10) // <=

// IN
.in("column", values: ["a", "b", "c"])

// LIKE / ILIKE
.like("column", pattern: "%search%")
.ilike("column", pattern: "%search%") // case insensitive

// IS NULL
.is("column", value: "null")
.not("column", operator: "is", value: "null")

// Logique
.or("column1.eq.value1,column2.eq.value2")
```

### 6. Tri et pagination

```swift
// Tri
.order("date", ascending: true)
.order("created_at", ascending: false)

// Limite
.limit(10)

// Range (pagination)
.range(from: 0, to: 9) // premiers 10 résultats
.range(from: 10, to: 19) // résultats 11-20
```

---

## 📁 Storage

### 1. Upload un fichier

```swift
try await client.storage
    .from("bucket-name")
    .upload(
        path: "folder/filename.jpg",
        file: imageData,
        options: FileOptions(contentType: "image/jpeg")
    )
```

### 2. Récupérer l'URL publique

```swift
let publicURL = try client.storage
    .from("bucket-name")
    .getPublicURL(path: "folder/filename.jpg")

print(publicURL.absoluteString)
```

### 3. Télécharger un fichier

```swift
let fileData = try await client.storage
    .from("bucket-name")
    .download(path: "folder/filename.jpg")
```

### 4. Supprimer un fichier

```swift
try await client.storage
    .from("bucket-name")
    .remove(paths: ["folder/filename.jpg"])
```

### 5. Créer une URL signée (temporaire)

```swift
let signedURL = try await client.storage
    .from("bucket-name")
    .createSignedURL(path: "folder/filename.jpg", expiresIn: 3600) // 1 heure
```

---

## 🔄 Real-time

### 1. S'abonner à des changements

```swift
let channel = await client.channel("my-channel")

await channel.on(.postgresChanges(
    InsertAction(schema: "public", table: "my_events")
)) { (payload: InsertAction.Payload) in
    print("Nouvel événement créé: \(payload.record)")
}

await channel.subscribe()
```

### 2. Se désabonner

```swift
await channel.unsubscribe()
```

---

## ⚡️ Edge Functions

```swift
let response = try await client.functions.invoke(
    "function-name",
    options: FunctionInvokeOptions(
        body: ["key": "value"]
    )
)
```

---

## 🎯 Bonnes pratiques

### 1. Gestion des erreurs

```swift
do {
    let events = try await client
        .from("my_events")
        .select()
        .execute()
        .value
} catch {
    print("Erreur Supabase: \(error)")
    // Gérer l'erreur
}
```

### 2. Types personnalisés

```swift
struct MyEvent: Codable {
    let id: UUID
    let title: String
    let date: String

    func toDictionary() -> [String: AnyJSON] {
        [
            "id": .string(id.uuidString),
            "title": .string(title),
            "date": .string(date)
        ]
    }
}
```

### 3. Authentification requise

```swift
func fetchMyEvents() async throws -> [MyEvent] {
    guard let session = try? await client.auth.session else {
        throw SupabaseError.notAuthenticated
    }

    return try await client
        .from("my_events")
        .select()
        .eq("user_id", value: session.user.id.uuidString)
        .execute()
        .value
}
```

---

## 🐛 Debugging

### Activer les logs

```swift
// Ajouter dans la console Xcode
print("Session: \(try? await client.auth.session)")
print("User metadata: \(session.user.userMetadata)")
print("App metadata: \(session.user.appMetadata)")
```

### Erreurs courantes

| Erreur | Cause | Solution |
|--------|-------|----------|
| `notAuthenticated` | Pas de session active | Vérifier `client.auth.session` |
| `invalidRow` | Structure de données incorrecte | Vérifier le schéma Postgrest |
| `missingRequiredParameter` | Paramètre manquant | Vérifier la documentation |
| `rateLimitExceeded` | Trop de requêtes | Implémenter un throttling |

---

## 📚 Ressources

- [Documentation officielle](https://supabase.com/docs/reference/swift)
- [GitHub Supabase Swift](https://github.com/supabase/supabase-swift)
- [Exemples](https://github.com/supabase/supabase-swift/tree/main/Examples)

---

**Version** : 2.37.0
**Dernière mise à jour** : 11 Décembre 2025
