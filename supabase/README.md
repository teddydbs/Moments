# Configuration Supabase pour Moments

Ce dossier contient toute la configuration backend pour l'application Moments utilisant Supabase.

## 📋 Table des matières

1. [Prérequis](#prérequis)
2. [Installation initiale](#installation-initiale)
3. [Configuration de la base de données](#configuration-de-la-base-de-données)
4. [Déploiement des Edge Functions](#déploiement-des-edge-functions)
5. [Configuration iOS](#configuration-ios)
6. [Variables d'environnement](#variables-denvironnement)
7. [Tests](#tests)

## 🎯 Prérequis

- Un compte Supabase (https://supabase.com)
- Supabase CLI installé : `npm install -g supabase`
- Xcode 15+
- Swift 5.9+

## 🚀 Installation initiale

### 1. Créer un projet Supabase

1. Allez sur https://supabase.com/dashboard
2. Créez un nouveau projet
3. Notez votre **Project URL** et votre **anon key**

### 2. Initialiser Supabase localement

```bash
cd /Users/teddy/Desktop/Moments
supabase init
```

### 3. Lier votre projet

```bash
supabase link --project-ref your-project-ref
```

## 🗄️ Configuration de la base de données

### Exécuter les migrations

Les migrations se trouvent dans `supabase/migrations/`. Pour les appliquer :

```bash
# Se connecter à votre projet
supabase db push

# Ou manuellement dans le dashboard Supabase:
# 1. Allez dans SQL Editor
# 2. Copiez le contenu de 20250101000000_initial_schema.sql
# 3. Exécutez le script
# 4. Répétez pour 20250101000001_rls_policies.sql
```

### Vérifier les tables

Après l'exécution, vous devriez avoir ces tables :
- `users`
- `events`
- `participants`
- `gift_ideas`
- `contributions`
- `event_invitations`
- `affiliate_conversions`

## ⚡ Déploiement des Edge Functions

### 1. Fonction de conversion d'affiliation Amazon

```bash
supabase functions deploy affiliate-convert
```

### 2. Fonction webhook Stripe

```bash
supabase functions deploy stripe-webhook
```

### 3. Fonction de partage d'événements

```bash
supabase functions deploy events-share
```

### Configurer les secrets

```bash
# Tag d'affiliation Amazon
supabase secrets set AMAZON_AFFILIATE_TAG=moments-21

# Clés Stripe (à configurer plus tard)
supabase secrets set STRIPE_SECRET_KEY=sk_test_...
supabase secrets set STRIPE_WEBHOOK_SECRET=whsec_...

# URL de base de l'app
supabase secrets set APP_BASE_URL=moments://invite
```

## 📱 Configuration iOS

### 1. Installer le SDK Supabase

Ajoutez le package Swift via Xcode :
```
https://github.com/supabase-community/supabase-swift
```

Ou via Package.swift :
```swift
dependencies: [
    .package(url: "https://github.com/supabase-community/supabase-swift", from: "2.0.0")
]
```

### 2. Configurer SupabaseConfig.swift

Éditez le fichier `Moments/Services/Backend/SupabaseConfig.swift` :

```swift
struct SupabaseConfig {
    static let supabaseURL = URL(string: "https://YOUR-PROJECT.supabase.co")!
    static let supabaseAnonKey = "YOUR-ANON-KEY"
}
```

### 3. Décommenter le code dans SupabaseManager.swift

Une fois le SDK installé, décommentez :
- Les imports en haut du fichier
- Toutes les implémentations marquées `// TODO: Implémenter après installation du SDK`

## 🔐 Variables d'environnement

### Variables nécessaires dans Supabase

| Variable | Description | Exemple |
|----------|-------------|---------|
| `AMAZON_AFFILIATE_TAG` | Tag d'affiliation Amazon | `moments-21` |
| `STRIPE_SECRET_KEY` | Clé secrète Stripe | `sk_test_...` |
| `STRIPE_WEBHOOK_SECRET` | Secret webhook Stripe | `whsec_...` |
| `APP_BASE_URL` | URL de deep link de l'app | `moments://invite` |

### Configurer les variables

```bash
supabase secrets set VARIABLE_NAME=value
```

## 🧪 Tests

### Tester la base de données

```bash
# Vérifier que toutes les tables existent
supabase db remote status

# Tester une requête
supabase db remote execute "SELECT * FROM events LIMIT 1;"
```

### Tester les Edge Functions localement

```bash
# Démarrer Supabase en local
supabase start

# Tester une fonction
supabase functions serve affiliate-convert

# Dans un autre terminal
curl -X POST http://localhost:54321/functions/v1/affiliate-convert \
  -H "Content-Type: application/json" \
  -d '{"url": "https://amazon.fr/product/123"}'
```

## 📊 Structure de la base de données

```
users
├── id (UUID, PK)
├── email (TEXT, UNIQUE)
├── name (TEXT)
├── avatar_url (TEXT)
└── created_at / updated_at

events
├── id (UUID, PK)
├── owner_id (UUID, FK → users)
├── title (TEXT)
├── date (DATE)
├── category (TEXT)
├── notes (TEXT)
├── has_gift_pool (BOOLEAN)
├── image_url (TEXT)
├── is_recurring (BOOLEAN)
└── created_at / updated_at

participants
├── id (UUID, PK)
├── event_id (UUID, FK → events)
├── name (TEXT)
├── phone (TEXT)
├── email (TEXT)
├── source (TEXT)
└── created_at / updated_at

gift_ideas
├── id (UUID, PK)
├── event_id (UUID, FK → events)
├── title (TEXT)
├── description (TEXT)
├── product_url (TEXT)
├── affiliate_url (TEXT)
├── price (NUMERIC)
└── created_at / updated_at

contributions (pour les cagnottes)
├── id (UUID, PK)
├── event_id (UUID, FK → events)
├── user_id (UUID, FK → users)
├── amount (NUMERIC)
├── status (TEXT)
└── stripe_payment_intent_id (TEXT)
```

## 🔒 Row Level Security (RLS)

Toutes les tables ont des policies RLS actives :
- Les utilisateurs ne voient que leurs propres données
- Les événements sont visibles par leur propriétaire et les invités
- Les participants et idées cadeaux sont protégés par événement
- Les contributions sont visibles par le contributeur et le propriétaire de l'événement

## 🚨 Troubleshooting

### Erreur : "relation does not exist"
→ Les migrations n'ont pas été exécutées. Lancez `supabase db push`

### Erreur : "JWT expired"
→ Reconnectez-vous dans l'app iOS

### Erreur Edge Function : "Missing authorization header"
→ Assurez-vous que le token JWT est inclus dans les headers

### Les données ne se synchronisent pas
→ Vérifiez que l'utilisateur est bien authentifié et que les RLS policies sont correctes

## 📚 Ressources

- [Documentation Supabase](https://supabase.com/docs)
- [SDK Swift Supabase](https://github.com/supabase-community/supabase-swift)
- [Documentation Edge Functions](https://supabase.com/docs/guides/functions)
- [Documentation RLS](https://supabase.com/docs/guides/auth/row-level-security)

## 🔄 Workflow de synchronisation

```
┌─────────────┐
│   iOS App   │
│  SwiftData  │
└──────┬──────┘
       │
       │ SyncManager.performFullSync()
       │
       ├─── Pull ────► Supabase (fetch events, participants, gifts)
       │
       └─── Push ────► Supabase (create/update local changes)
```

## 🎯 Prochaines étapes

1. ✅ Créer le projet Supabase
2. ✅ Exécuter les migrations SQL
3. ✅ Déployer les Edge Functions
4. ⬜ Installer le SDK Swift
5. ⬜ Configurer SupabaseConfig.swift
6. ⬜ Décommenter le code dans SupabaseManager.swift
7. ⬜ Tester l'authentification
8. ⬜ Tester la synchronisation

---

**Dernière mise à jour:** 04 Décembre 2025
