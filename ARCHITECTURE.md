# Architecture Backend Moments

Ce document décrit l'architecture complète de l'application Moments avec Supabase.

## 📊 Vue d'ensemble

```
┌─────────────────────────────────────────────────────────────────┐
│                     iOS App (SwiftUI + SwiftData)               │
│                                                                   │
│  ┌────────────────┐          ┌────────────────┐                │
│  │   UI Layer     │          │  Data Layer    │                │
│  │                │          │                │                │
│  │ - BirthdaysView│◄────────►│  SwiftData     │                │
│  │ - EventsView   │          │  ModelContext  │                │
│  │ - EventDetail  │          │                │                │
│  └────────────────┘          └───────┬────────┘                │
│                                      │                          │
│                              ┌───────▼────────┐                 │
│                              │  SyncManager   │                 │
│                              │  (Hybrid Sync) │                 │
│                              └───────┬────────┘                 │
│                                      │                          │
│                              ┌───────▼────────┐                 │
│                              │ SupabaseManager│                 │
│                              │ (Swift SDK)    │                 │
│                              └───────┬────────┘                 │
└──────────────────────────────────────┼──────────────────────────┘
                                       │
                                       │ HTTPS / JWT Auth
                                       │
┌──────────────────────────────────────▼──────────────────────────┐
│                         SUPABASE CLOUD                          │
│                                                                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐         │
│  │     Auth     │  │   Database   │  │   Storage    │         │
│  │              │  │              │  │              │         │
│  │ - Email/Pass │  │  PostgreSQL  │  │ - Images     │         │
│  │ - JWT Tokens │  │  + RLS       │  │ - Avatars    │         │
│  │ - Sessions   │  │              │  │              │         │
│  └──────────────┘  └──────┬───────┘  └──────────────┘         │
│                            │                                     │
│                    ┌───────▼───────┐                           │
│                    │  Edge         │                           │
│                    │  Functions    │                           │
│                    │               │                           │
│                    │ - Affiliate   │                           │
│                    │ - Stripe      │                           │
│                    │ - Share       │                           │
│                    └───────┬───────┘                           │
└────────────────────────────┼─────────────────────────────────────┘
                             │
                    ┌────────┼────────┐
                    │        │        │
                    ▼        ▼        ▼
              ┌─────────┐ ┌──────┐ ┌──────┐
              │ Amazon  │ │Stripe│ │Email │
              │Affiliate│ │  API │ │ SMTP │
              └─────────┘ └──────┘ └──────┘
```

## 🗃️ Modèle de données

### Base de données Supabase (PostgreSQL)

```sql
┌──────────────────────────────────────────────────────┐
│ users                                                │
├──────────────────────────────────────────────────────┤
│ id (UUID, PK)                                        │
│ email (TEXT, UNIQUE)                                 │
│ name (TEXT)                                          │
│ avatar_url (TEXT)                                    │
│ created_at / updated_at (TIMESTAMPTZ)                │
└──────────────────┬───────────────────────────────────┘
                   │
                   │ owner_id (FK)
                   │
┌──────────────────▼───────────────────────────────────┐
│ events                                               │
├──────────────────────────────────────────────────────┤
│ id (UUID, PK)                                        │
│ owner_id (UUID, FK → users.id)                       │
│ title (TEXT)                                         │
│ date (DATE)                                          │
│ category (TEXT: birthday, wedding, etc.)             │
│ notes (TEXT)                                         │
│ has_gift_pool (BOOLEAN)                              │
│ image_url (TEXT)                                     │
│ is_recurring (BOOLEAN)                               │
│ created_at / updated_at (TIMESTAMPTZ)                │
└──────────────────┬────────────────┬──────────────────┘
                   │                │
      event_id (FK)│                │event_id (FK)
                   │                │
┌──────────────────▼────────┐  ┌───▼──────────────────┐
│ participants              │  │ gift_ideas           │
├───────────────────────────┤  ├──────────────────────┤
│ id (UUID, PK)             │  │ id (UUID, PK)        │
│ event_id (UUID, FK)       │  │ event_id (UUID, FK)  │
│ name (TEXT)               │  │ title (TEXT)         │
│ phone (TEXT)              │  │ description (TEXT)   │
│ email (TEXT)              │  │ product_url (TEXT)   │
│ source (TEXT)             │  │ affiliate_url (TEXT) │
│ contact_identifier (TEXT) │  │ price (NUMERIC)      │
│ social_media_id (TEXT)    │  │ proposed_by (TEXT)   │
│ created_at / updated_at   │  │ created_at / updated │
└───────────────────────────┘  └──────────────────────┘

┌──────────────────────────────────────────────────────┐
│ contributions (pour cagnottes)                       │
├──────────────────────────────────────────────────────┤
│ id (UUID, PK)                                        │
│ event_id (UUID, FK → events.id)                      │
│ user_id (UUID, FK → users.id)                        │
│ amount (NUMERIC)                                     │
│ status (TEXT: pledged, pending, paid, refunded)      │
│ stripe_payment_intent_id (TEXT)                      │
│ payment_method (TEXT)                                │
│ message (TEXT)                                       │
│ created_at / updated_at (TIMESTAMPTZ)                │
└──────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────┐
│ event_invitations                                    │
├──────────────────────────────────────────────────────┤
│ id (UUID, PK)                                        │
│ event_id (UUID, FK → events.id)                      │
│ inviter_id (UUID, FK → users.id)                     │
│ invitee_email (TEXT)                                 │
│ invitee_id (UUID, FK → users.id, nullable)           │
│ status (TEXT: pending, accepted, declined)           │
│ share_token (TEXT, UNIQUE)                           │
│ created_at / updated_at (TIMESTAMPTZ)                │
└──────────────────────────────────────────────────────┘
```

### Modèle SwiftData (Local)

```swift
@Model
class Event {
    var id: UUID
    var title: String
    var date: Date
    var category: EventCategory
    var isRecurring: Bool
    var notes: String
    var notificationIdentifier: String?
    @Attribute(.externalStorage) var imageData: Data?
    var hasGiftPool: Bool
    @Relationship(deleteRule: .cascade) var participants: [Participant]
    @Relationship(deleteRule: .cascade) var giftIdeas: [GiftIdea]

    // Propriétés de synchronisation
    @Transient var needsSync: Bool
    @Transient var existsOnServer: Bool
    @Transient var updatedAt: Date?
}

@Model
class Participant {
    var id: UUID
    var name: String
    var phone: String?
    var email: String?
    var source: ParticipantSource
    var contactIdentifier: String?
    var socialMediaId: String?
    var event: Event?
}

@Model
class GiftIdea {
    var id: UUID
    var title: String
    var productURL: String?
    var productImageURL: String?
    var price: Double?
    var proposedBy: String
    var event: Event?
}
```

## 🔄 Flux de synchronisation

### Synchronisation complète (Full Sync)

```
┌─────────────────────────────────────────────────────────────┐
│ 1. PULL (Supabase → SwiftData)                             │
└─────────────────────────────────────────────────────────────┘

iOS App                          Supabase
   │                                │
   ├─── fetchEvents() ─────────────►│
   │                                │ SELECT * FROM events
   │                                │ WHERE owner_id = user.id
   │◄──────── [RemoteEvent[]] ──────┤
   │                                │
   ├─ Comparer avec événements locaux
   │                                │
   ├─ Si remote.updatedAt > local.updatedAt:
   │   └─ Mettre à jour l'événement local
   │                                │
   ├─ Si événement n'existe pas localement:
   │   └─ Créer un nouvel événement local
   │                                │
   ├─ Si événement local n'existe plus sur serveur:
   │   └─ Supprimer l'événement local
   │                                │

┌─────────────────────────────────────────────────────────────┐
│ 2. PUSH (SwiftData → Supabase)                             │
└─────────────────────────────────────────────────────────────┘

iOS App                          Supabase
   │                                │
   ├─ Pour chaque événement où needsSync = true:
   │                                │
   ├─ Si existsOnServer = true:
   │   ├─── updateEvent() ─────────►│
   │   │                            │ UPDATE events SET ...
   │   │                            │ WHERE id = event.id
   │   │◄──────── success ──────────┤
   │                                │
   ├─ Si existsOnServer = false:
   │   ├─── createEvent() ─────────►│
   │   │                            │ INSERT INTO events ...
   │   │◄──────── event.id ─────────┤
   │   └─ Mettre à jour l'ID local
   │                                │
   ├─ Marquer needsSync = false
   │                                │
```

### Stratégie de résolution de conflits

**Last-Write-Wins (LWW)** :
- Chaque modification est timestampée avec `updated_at`
- Lors du pull, si `remote.updatedAt > local.updatedAt`, on prend la version distante
- Lors du push, on écrase toujours la version serveur (on suppose que la version locale est plus récente)

**Amélioration future** : Synchronisation opérationnelle (OT) ou CRDT pour une résolution plus fine.

## 🔐 Sécurité : Row Level Security (RLS)

### Exemple de policy pour `events`

```sql
-- Les utilisateurs voient leurs propres événements
CREATE POLICY "Users can view own events"
    ON events FOR SELECT
    USING (
        auth.uid() = owner_id
        OR
        EXISTS (
            SELECT 1 FROM event_invitations
            WHERE event_invitations.event_id = events.id
            AND event_invitations.invitee_id = auth.uid()
            AND event_invitations.status = 'accepted'
        )
    );

-- Les utilisateurs peuvent créer leurs événements
CREATE POLICY "Users can create own events"
    ON events FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

-- Les utilisateurs peuvent modifier leurs événements
CREATE POLICY "Users can update own events"
    ON events FOR UPDATE
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);
```

**Principe** :
- Toutes les opérations SQL passent par les policies RLS
- Si une policy n'autorise pas l'opération, elle échoue silencieusement
- Le JWT contient l'`user.id`, accessible via `auth.uid()`

## ⚡ Edge Functions

### 1. Conversion d'affiliation Amazon

```
POST https://xxx.supabase.co/functions/v1/affiliate-convert
Authorization: Bearer <jwt>

{
  "url": "https://amazon.fr/product/B08X123"
}

→ Retourne :
{
  "success": true,
  "affiliateUrl": "https://amazon.fr/product/B08X123?tag=moments-21"
}
```

**Cas d'usage** :
- Quand un utilisateur ajoute une idée cadeau avec un lien Amazon
- L'Edge Function injecte le tag d'affiliation automatiquement
- Le lien converti est stocké dans `gift_ideas.affiliate_url`

### 2. Webhook Stripe

```
POST https://xxx.supabase.co/functions/v1/stripe-webhook
Stripe-Signature: <signature>

{
  "type": "payment_intent.succeeded",
  "data": {
    "object": {
      "id": "pi_123",
      "amount": 5000,
      ...
    }
  }
}

→ Retourne :
{
  "received": true
}
```

**Cas d'usage** :
- Stripe envoie un webhook après chaque paiement
- L'Edge Function vérifie la signature
- Met à jour `contributions.status` de `pending` à `paid`
- Notifie l'organisateur de l'événement (futur)

### 3. Partage d'événement

```
POST https://xxx.supabase.co/functions/v1/events-share
Authorization: Bearer <jwt>

{
  "eventId": "uuid-event",
  "inviteeEmail": "ami@example.com"
}

→ Retourne :
{
  "success": true,
  "shareUrl": "moments://invite?token=xxx",
  "invitationId": "uuid-invitation"
}
```

**Cas d'usage** :
- Quand un utilisateur veut partager un événement
- Génère un token unique
- Crée une entrée dans `event_invitations`
- Retourne un deep link pour l'app iOS
- Envoie un email d'invitation (futur)

## 📱 Cycle de vie de l'app

### Démarrage de l'app

```
MomentsApp.swift
    │
    ├─ Créer le ModelContainer (SwiftData)
    │
    ├─ Lancer MainTabView
    │
    └─ .task { }
        │
        ├─ Vérifier auth status
        │
        └─ Si authentifié:
            └─ performFullSync()
```

### Création d'un événement

```
1. Utilisateur remplit le formulaire (AddEditEventView)
2. Sauvegarder dans SwiftData
3. Marquer needsSync = true
4. (Optionnel) Lancer quickSync() pour push immédiat
5. Prochain fullSync() enverra l'événement à Supabase
```

### Pull-to-refresh

```
1. Utilisateur tire vers le bas
2. Déclencher .refreshable { }
3. SyncManager.performFullSync()
4. UI se met à jour automatiquement (grâce à @Query)
```

### Retour au premier plan

```
1. App passe de .background à .active
2. .onChange(of: scenePhase)
3. Lancer performFullSync()
```

## 🚀 Déploiement

### Environnement de développement

```
Supabase Project: moments-dev
URL: https://moments-dev.supabase.co
```

### Environnement de production

```
Supabase Project: moments-prod
URL: https://moments-prod.supabase.co
```

**Configuration** :
- Utiliser des variables d'environnement ou des schemes Xcode
- Séparer les clés API dev/prod

## 📊 Performance

### Optimisations appliquées

1. **Indexes SQL** :
   - `idx_events_owner_id` pour les queries par owner
   - `idx_events_date` pour trier par date
   - `idx_participants_event_id` pour charger les participants

2. **Pagination** (à implémenter) :
   - Charger les événements par lot (20 à la fois)
   - Utiliser `.range(from, to)` dans les queries Supabase

3. **Caching local** :
   - SwiftData conserve les données localement
   - Sync uniquement quand nécessaire

4. **Sync différentielle** :
   - Ne push que les événements modifiés (`needsSync = true`)
   - Ne pull que les événements plus récents (`updatedAt`)

## 🔮 Évolutions futures

### Phase 2 : Invitations collaboratives
- [ ] Accepter/refuser des invitations
- [ ] Notifications push pour les invitations
- [ ] Vue partagée avec les invités

### Phase 3 : Cagnottes Stripe
- [ ] Créer un Payment Intent
- [ ] Interface de paiement (Stripe Elements)
- [ ] Suivi des contributions
- [ ] Remboursements

### Phase 4 : Affiliation Amazon
- [ ] Scraping automatique des produits
- [ ] Commission tracking
- [ ] Statistiques des clics

### Phase 5 : Notifications push
- [ ] Firebase Cloud Messaging
- [ ] Rappels d'événements
- [ ] Notifications de contributions

---

**Date de création** : 04 Décembre 2025
**Dernière mise à jour** : 04 Décembre 2025
