# 🗺️ Roadmap - Moments App

**Dernière mise à jour** : 5 décembre 2025
**Version actuelle** : 0.3.5 (35% complète)

---

## 📊 État d'Avancement Global

### ✅ Déjà Implémenté (35%)
- ✅ Gestion d'événements (CRUD complet)
- ✅ Catégories d'événements (anniversaires, mariages, EVG/EVJF, soirées)
- ✅ Participants (ajout manuel, suppression)
- ✅ Idées cadeaux / Wishlist (avec scraping de produits)
- ✅ Notifications locales (rappels le jour J à 9h)
- ✅ Design System (thème violet/rose cohérent)
- ✅ Images pour événements
- ✅ Infrastructure backend Supabase (prête, non activée)
- ✅ Base de données PostgreSQL complète (7 tables, RLS, triggers)
- ✅ Edge Functions (partage, affiliation, Stripe webhook)

### 🚧 Partiellement Implémenté (15%)
- 🚧 Import de participants (UI existe, API manquante)
- 🚧 Scraping de produits (basique, sans affiliation)
- 🚧 Synchronisation backend (code prêt, SDK pas installé)
- 🚧 Paramètres (écran existe, fonctionnalités minimales)

### ❌ Manquant (50%)
- ❌ **Authentification utilisateur** (critique)
- ❌ **Système d'invitations** (critique)
- ❌ **Gestion des contacts/personnes** (critique)
- ❌ **Localisation & heure des événements** (critique)
- ❌ **Partage social** (SMS, WhatsApp, Instagram)
- ❌ **Approbation des invités** (organisateur only)
- ❌ **Collaboration multi-utilisateurs**
- ❌ **Intégration calendrier iOS**
- ❌ **Paiements / Cagnotte** (Stripe/Lydia)
- ❌ **Programme d'affiliation Amazon**

---

## 🎯 Vision Complète

### L'App Doit Permettre De :

1. **Ne plus oublier les dates importantes**
   - ✅ Calendrier chronologique
   - ✅ Notifications automatiques
   - ❌ Sync avec calendrier iOS
   - ❌ Rappels personnalisables

2. **Organiser des événements**
   - ✅ Création/édition/suppression
   - ✅ Catégorisation
   - ❌ Localisation + carte
   - ❌ Heure précise
   - ❌ Description enrichie

3. **Gérer les invités avec validation**
   - 🚧 Ajout de participants
   - ❌ Système d'invitations
   - ❌ Approbation par l'organisateur
   - ❌ Statuts (en attente/accepté/refusé)
   - ❌ RSVP

4. **Proposer des idées cadeaux**
   - ✅ Wishlist par événement
   - ✅ Scraping de produits
   - ❌ Affiliation Amazon
   - ❌ Suggestions IA (futur)

5. **Partager les infos importantes**
   - ❌ Partage via SMS
   - ❌ Partage via WhatsApp
   - ❌ Partage via Instagram/Messenger
   - ❌ Deep links pour rejoindre
   - ❌ Page événement publique

---

## 📋 Plan d'Action Détaillé

## 🚀 PHASE 1 : MVP Fonctionnel (3-4 semaines)

### Sprint 1 : Infrastructure Critique (1 semaine)

#### 1.1 Installation Supabase SDK ⚡ PRIORITÉ ABSOLUE
**Durée** : 1 jour
**Fichiers** :
- `Moments.xcodeproj/project.pbxproj`
- Tous les fichiers dans `/Services/Backend/`

**Actions** :
```swift
// Décommenter dans SupabaseManager.swift :
import Supabase
import PostgREST
import Realtime
import Storage

// Activer le client
let client = SupabaseClient(
    supabaseURL: SupabaseConfig.supabaseURL,
    supabaseKey: SupabaseConfig.supabaseAnonKey
)
```

**Tests** :
- [ ] Connection à Supabase réussie
- [ ] Requête basique fonctionne
- [ ] Auth fonctionne

---

#### 1.2 Authentification Utilisateur 👤
**Durée** : 3-4 jours
**Nouveaux fichiers** :
- `Views/Auth/LoginView.swift`
- `Views/Auth/SignUpView.swift`
- `Views/Auth/ProfileView.swift`
- `Models/User.swift` (SwiftData)

**Fonctionnalités** :
- [ ] Écran de login (email + password)
- [ ] Écran d'inscription (nom, email, password)
- [ ] Gestion de session (AppStorage + Keychain)
- [ ] Écran de profil utilisateur
- [ ] Logout
- [ ] Récupération de mot de passe

**UI Flow** :
```
App Launch
    ↓
Si non connecté → LoginView
    ↓
Si connecté → MainTabView
```

**Modifications** :
```swift
// MomentsApp.swift
@main
struct MomentsApp: App {
    @AppStorage("isLoggedIn") var isLoggedIn = false

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .modelContainer(...)
    }
}
```

---

#### 1.3 Localisation & Heure des Événements 📍
**Durée** : 2-3 jours
**Fichiers à modifier** :
- `Models/Event.swift`
- `Views/AddEditEventView.swift`
- `Views/EventDetailView.swift`
- `supabase/migrations/` (nouvelle migration)

**Nouveaux champs Event** :
```swift
@Model
final class Event {
    // ... existing fields
    var time: Date?              // Nouvelle
    var location: String?         // Nouvelle
    var locationAddress: String?  // Nouvelle
    var locationLatitude: Double? // Nouvelle
    var locationLongitude: Double? // Nouvelle
}
```

**Fonctionnalités** :
- [ ] Picker de temps (heure)
- [ ] Recherche d'adresse (MapKit)
- [ ] Affichage carte dans EventDetailView
- [ ] Bouton "Ouvrir dans Plans"
- [ ] Geocoding d'adresse

**UI** :
```swift
// Dans AddEditEventView
Section("Date et heure") {
    DatePicker("Date", selection: $date, displayedComponents: [.date])
    DatePicker("Heure", selection: $time, displayedComponents: [.hourAndMinute])
}

Section("Lieu") {
    TextField("Adresse", text: $locationAddress)
    // Map preview si adresse remplie
    if !locationAddress.isEmpty {
        Map(...)
    }
}
```

---

### Sprint 2 : Gestion des Contacts (1 semaine)

#### 2.1 Modèle Contact/Personne 👥
**Durée** : 2 jours
**Nouveaux fichiers** :
- `Models/Contact.swift`
- `Views/ContactsView.swift`
- `Views/ContactDetailView.swift`

**Modèle** :
```swift
@Model
final class Contact {
    var id: UUID
    var name: String
    var birthday: Date?
    var relationship: ContactRelationship // ami, famille, collègue
    var phone: String?
    var email: String?
    var photo: Data?
    var contactIdentifier: String? // iOS Contacts ID
    var notes: String

    @Relationship(deleteRule: .nullify) var events: [Event]
    @Relationship(deleteRule: .nullify) var participations: [Participant]
}

enum ContactRelationship: String, Codable, CaseIterable {
    case family = "Famille"
    case friend = "Ami"
    case colleague = "Collègue"
    case partner = "Conjoint(e)"
    case other = "Autre"
}
```

**Fonctionnalités** :
- [ ] CRUD complet des contacts
- [ ] Onglet "Contacts" dans MainTabView
- [ ] Anniversaires automatiques depuis contacts
- [ ] Photo de contact

---

#### 2.2 Import depuis iOS Contacts 📱
**Durée** : 2-3 jours
**Fichiers à modifier** :
- `Views/AddEditEventView.swift`
- Nouveau : `Helpers/ContactsManager.swift`

**Fonctionnalités** :
- [ ] Demande de permission Contacts
- [ ] Picker de contacts natif iOS
- [ ] Import nom + phone + email + photo
- [ ] Détection automatique des anniversaires
- [ ] Sync bidirectionnel (optionnel)

**Code** :
```swift
import Contacts

class ContactsManager {
    func requestAccess() async -> Bool
    func fetchContacts() async -> [CNContact]
    func importContact(_ cnContact: CNContact) -> Contact
    func syncBirthdays() async
}
```

---

### Sprint 3 : Système d'Invitations (1 semaine)

#### 3.1 Modèle Invitation ✉️
**Durée** : 1 jour
**Nouveaux fichiers** :
- `Models/Invitation.swift`

**Modèle** :
```swift
@Model
final class Invitation {
    var id: UUID
    var eventId: UUID
    var inviteeEmail: String?
    var inviteePhone: String?
    var inviteeName: String?
    var status: InvitationStatus
    var shareToken: String
    var sentAt: Date
    var respondedAt: Date?
    var message: String?

    @Relationship var event: Event?
}

enum InvitationStatus: String, Codable {
    case pending = "En attente"
    case accepted = "Acceptée"
    case declined = "Refusée"
    case expired = "Expirée"
}
```

---

#### 3.2 UI d'Invitation 📨
**Durée** : 2 jours
**Nouveaux fichiers** :
- `Views/InviteGuestsView.swift`
- `Views/InvitationListView.swift` (pour organisateur)
- `Views/InvitationResponseView.swift` (pour invité)

**Flow Organisateur** :
```
EventDetailView
    ↓
Bouton "Inviter des personnes"
    ↓
InviteGuestsView
    ├─ Sélection depuis Contacts
    ├─ Ajout manuel (email/phone)
    └─ Message personnalisé
    ↓
Envoi invitations (SMS/WhatsApp/Email)
    ↓
InvitationListView (voir statuts)
```

**Flow Invité** :
```
Reçoit lien : moments://invite?token=abc123
    ↓
App s'ouvre sur InvitationResponseView
    ↓
Affiche infos événement
    ↓
Boutons : Accepter / Refuser
    ↓
Mise à jour statut → notif organisateur
```

---

#### 3.3 Partage Social 📲
**Durée** : 2-3 jours
**Fichiers à modifier** :
- `Views/EventDetailView.swift`
- Nouveau : `Helpers/ShareManager.swift`

**Canaux de partage** :
- [ ] SMS (avec lien)
- [ ] WhatsApp (via URL scheme)
- [ ] Instagram Story
- [ ] Messenger
- [ ] Email
- [ ] Copier le lien

**Code** :
```swift
class ShareManager {
    func shareEventViaSMS(event: Event, invitations: [Invitation])
    func shareEventViaWhatsApp(event: Event, shareURL: URL)
    func shareEventViaEmail(event: Event, shareURL: URL)
    func generateShareURL(eventId: UUID, token: String) -> URL
}
```

**UI** :
```swift
// Dans EventDetailView
Button("Inviter des personnes") {
    showingInviteSheet = true
}
.sheet(isPresented: $showingInviteSheet) {
    InviteGuestsView(event: event)
}
```

---

#### 3.4 Approbation des Invités ✅
**Durée** : 1-2 jours
**Nouveaux fichiers** :
- `Views/GuestApprovalView.swift`

**Fonctionnalités** :
- [ ] Liste des demandes en attente
- [ ] Boutons Accepter/Refuser
- [ ] Notification à l'invité
- [ ] Mise à jour du statut Participant
- [ ] Affichage du statut dans EventDetailView

**UI** :
```
EventDetailView (si organisateur)
    ↓
Badge notification si demandes en attente
    ↓
Bouton "Gérer les demandes" (X en attente)
    ↓
GuestApprovalView
    ├─ Photo, nom, source
    ├─ Boutons : ✅ Accepter | ❌ Refuser
    └─ Message optionnel
```

---

### Sprint 4 : Sync Multi-Utilisateurs (4-5 jours)

#### 4.1 Activation SyncManager 🔄
**Durée** : 2 jours
**Fichiers à modifier** :
- `Services/Backend/SyncManager.swift`
- `Views/EventsView.swift`
- `Views/BirthdaysView.swift`

**Fonctionnalités** :
- [ ] Pull-to-refresh
- [ ] Sync automatique au lancement
- [ ] Sync en arrière-plan (périodique)
- [ ] Indicateur de sync visuel
- [ ] Gestion des conflits (last-write-wins)

**UI** :
```swift
// Dans EventsView et BirthdaysView
.refreshable {
    await syncManager.performFullSync()
}

.task {
    // Sync au lancement
    try? await syncManager.performFullSync()
}
```

---

#### 4.2 Collaboration Temps Réel 🤝
**Durée** : 2-3 jours
**Fichiers à créer** :
- `Services/RealtimeManager.swift`

**Fonctionnalités** :
- [ ] WebSocket connection (Supabase Realtime)
- [ ] Écoute des changements sur events
- [ ] Écoute des changements sur participants
- [ ] Notifications push pour nouveaux invités
- [ ] Badge "Nouveau" sur événements modifiés

**Code** :
```swift
class RealtimeManager {
    func subscribeToEvent(eventId: UUID)
    func subscribeToUserEvents(userId: UUID)
    func handleEventUpdate(payload: [String: Any])
}
```

---

## 🎨 PHASE 2 : Fonctionnalités Avancées (2-3 semaines)

### 5. Calendrier iOS (2-3 jours)
- [ ] Import événements depuis Calendrier iOS
- [ ] Export événements vers Calendrier iOS
- [ ] Sync bidirectionnelle
- [ ] Détection de conflits

### 6. Recherche & Filtres (2-3 jours)
- [ ] Barre de recherche (événements + contacts)
- [ ] Filtres par catégorie
- [ ] Filtres par date
- [ ] Tri personnalisé

### 7. Notifications Avancées (2 jours)
- [ ] Rappels personnalisables (3j, 1 semaine, 1 mois avant)
- [ ] Notifications push serveur (via Supabase)
- [ ] Notification "Un ami a accepté l'invitation"
- [ ] Notification "Nouvelle idée cadeau proposée"

### 8. Amélioration Wishlist (3 jours)
- [ ] Scraping amélioré (Amazon, Fnac, etc.)
- [ ] Conversion liens affiliés (edge function)
- [ ] Tracking des clics
- [ ] Suggestions IA (GPT-4)

---

## 💰 PHASE 3 : Monétisation (2-3 semaines)

### 9. Cagnotte / Paiements (7-10 jours)
**Stack** : Stripe + Lydia
- [ ] Intégration Stripe SDK
- [ ] Création d'une cagnotte
- [ ] UI de contribution
- [ ] Historique des contributions
- [ ] Remboursements
- [ ] Webhook Stripe activé

### 10. Affiliation Amazon (3-4 jours)
- [ ] Compte Amazon Associates
- [ ] Conversion automatique des liens
- [ ] Tracking des commissions
- [ ] Dashboard revenus

### 11. Abonnement Premium (optionnel)
- [ ] Événements illimités (vs 10 max)
- [ ] Photos HD
- [ ] Support prioritaire
- [ ] Statistiques avancées

---

## 🚧 PHASE 4 : Polish & Launch (2 semaines)

### 12. Tests & Debug
- [ ] Tests unitaires
- [ ] Tests d'intégration
- [ ] TestFlight Beta
- [ ] Correction bugs

### 13. App Store
- [ ] Screenshots
- [ ] Vidéo promo
- [ ] Description
- [ ] Politique de confidentialité
- [ ] CGU
- [ ] Soumission App Store

---

## 📊 Métriques de Succès

### MVP (Phase 1)
- [ ] Authentification fonctionne
- [ ] Créer événement avec lieu + heure
- [ ] Inviter 3 personnes minimum
- [ ] Système approbation opérationnel
- [ ] Partage via SMS/WhatsApp
- [ ] Sync multi-device

### V1.0 (Phase 2)
- [ ] 100 utilisateurs actifs
- [ ] 50 événements créés
- [ ] Taux d'acceptation invitations > 70%
- [ ] 10+ contacts importés/utilisateur

### V2.0 (Phase 3)
- [ ] Première transaction cagnotte
- [ ] Premier revenu affiliation
- [ ] 500 utilisateurs actifs

---

## 🎯 Prochaine Session

**Objectif** : Démarrer Phase 1, Sprint 1

**Actions prioritaires** :
1. ✅ Installer Supabase Swift SDK
2. ✅ Activer SupabaseManager
3. ✅ Créer LoginView + SignUpView
4. ✅ Tester auth complète

**Durée estimée** : 1 semaine

---

## 📝 Notes

- Backend Supabase **déjà 100% prêt** (énorme gain de temps)
- Design system **terminé** (UI cohérente garantie)
- Architecture MVVM **bien structurée**
- SwiftData **bien maîtrisé**

**Point fort** : Excellente base technique, il "suffit" de connecter les morceaux et d'ajouter les features sociales.

**Point de vigilance** : Ne pas sous-estimer le système d'invitations (partie la plus complexe).

---

**Auteur** : Claude + Teddy
**Date de création** : 5 décembre 2025
**Prochaine révision** : Fin Sprint 1
