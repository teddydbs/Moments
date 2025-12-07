# 🏗️ Nouvelle Architecture Moments

## 📋 Résumé du changement

L'architecture a été **complètement refaite** pour correspondre à ta vision de l'application.

### ❌ Avant (Architecture confuse)

```
Event (tout mélangé)
├── Anniversaires
└── Événements
```

### ✅ Maintenant (Architecture claire)

```
1. AppUser → TON profil
2. Contact → Les anniversaires de TES AMIS
3. MyEvent → TES événements où TU invites des gens
4. WishlistItem → Les cadeaux (toi OU tes amis)
5. Invitation → Les invités à TES événements
```

---

## 🎯 Les 3 espaces de l'application

### 1️⃣ **Mon Profil** (AppUser)

**C'est TOI**

Champs :
- Prénom, Nom
- Email (synchronisé avec l'authentification)
- Date de naissance
- Photo de profil
- Téléphone (optionnel)

Fichier : `Models/User.swift` (classe `AppUser`)
Vue : `Views/ProfileView.swift`

Accès : **Paramètres** → "Modifier mon profil"

---

### 2️⃣ **Anniversaires** (Contact)

**Les anniversaires de TES AMIS/FAMILLE**

Champs :
- Prénom, Nom
- Date de naissance (**OBLIGATOIRE** - c'est un anniversaire)
- Photo (optionnel)
- Email, Téléphone (optionnel)
- Notes personnelles

Relations :
- **Contact.wishlistItems** → Leur wishlist (ce qu'ILS veulent)

Fichier : `Models/Contact.swift`
Vue : `Views/BirthdaysView.swift` (**à refaire**)

Exemple d'usage :
```
Contact(
    firstName: "Marie",
    lastName: "Dupont",
    birthDate: 20/03/1998
)
→ wishlistItems: [AirPods Pro, Parfum Chanel]
```

**Tu vois :**
- Tous tes amis/famille
- Leur prochain anniversaire
- Combien de jours restants
- LEUR wishlist (pour savoir quoi leur offrir)

---

### 3️⃣ **Mes Événements** (MyEvent)

**TES propres événements où TU invites des gens**

Types d'événements :
- Mon anniversaire
- Mon mariage
- Mon EVG/EVJF
- Ma pendaison de crémaillère
- Noël, Nouvel An
- Autre

Champs :
- Type d'événement
- Titre personnalisé (ex: "Mes 30 ans 🎉")
- Description
- Date + Heure (optionnel)
- Lieu + Adresse (optionnel)
- Photo de couverture
- Nombre max d'invités
- Date limite RSVP

Relations :
- **MyEvent.invitations** → Liste des invités avec statut
- **MyEvent.wishlistItems** → TA wishlist pour cet événement

Fichier : `Models/MyEvent.swift`
Vue : `Views/EventsView.swift` (**à refaire**)

Exemple d'usage :
```
MyEvent(
    type: .birthday,
    title: "Mes 30 ans",
    date: 15/06/2025,
    time: 20h00,
    location: "Chez moi",
    locationAddress: "12 rue de la Joie, 75001 Paris"
)
→ invitations: [Marie (accepté), Thomas (refusé), Sophie (en attente)]
→ wishlistItems: [Machine à café, Livre de cuisine, Bon cadeau Fnac]
```

**Tu vois :**
- Tous tes événements
- Nombre d'invités (acceptés/refusés/en attente)
- TA wishlist pour chaque événement
- Gérer les invitations (envoyer, approuver, refuser)

---

## 🎁 WishlistItem (Cadeaux)

**Les cadeaux peuvent appartenir à DEUX types d'entités**

### Option A : Wishlist d'un Contact

```swift
WishlistItem(
    title: "AirPods Pro",
    itemDescription: "Écouteurs sans fil",
    price: 279.0,
    category: .tech,
    contact: marie  // ← Ce que MARIE veut
)
```

→ Tu vois cette wishlist dans `BirthdaysView` pour savoir quoi offrir à Marie

### Option B : Wishlist pour TON événement

```swift
WishlistItem(
    title: "Machine à café",
    itemDescription: "Nespresso Vertuo",
    price: 199.0,
    category: .maison,
    myEvent: monAnniversaire  // ← Ce que TU veux pour ton anniversaire
)
```

→ Tes invités voient cette wishlist pour savoir quoi t'offrir

### Champs d'un cadeau :

- Titre
- Description (renommée `itemDescription` pour éviter conflit)
- Prix estimé (optionnel)
- URL du produit (Amazon, etc.)
- Image
- Catégorie (Mode, Tech, Maison, Beauté, Sport, etc.)
- Statut (Souhaité, Réservé, Acheté, Reçu)
- Priorité (1 = faible, 2 = moyenne, 3 = haute)
- Réservé par (nom de la personne)

Fichier : `Models/WishlistItem.swift`

---

## 👥 Invitation (Invités à TES événements)

**Gère les invitations avec statut et approbation**

Statuts possibles :
- **Pending** (En attente) - Invitation envoyée, pas de réponse
- **Accepted** (Accepté) - L'invité a accepté
- **Declined** (Refusé) - L'invité a refusé
- **WaitingApproval** (En attente d'approbation) - L'invité demande à venir, TU dois approuver

Champs :
- Nom de l'invité
- Email, Téléphone (optionnel)
- Statut
- Date d'envoi
- Date de réponse
- Message de l'invité
- Nombre de +1 (accompagnants)
- Événement lié
- Contact lié (optionnel - si c'est un ami dans tes contacts)

Méthodes :
```swift
invitation.accept(message: "J'ai hâte !")
invitation.decline(message: "Désolé, je ne peux pas")
invitation.requestToJoin(message: "Je peux venir avec ma copine ?")
invitation.approve()  // Par l'organisateur (toi)
invitation.reject()   // Par l'organisateur (toi)
```

Fichier : `Models/Invitation.swift`

Exemple d'usage :
```
Invitation(
    guestName: "Marie Dupont",
    guestEmail: "marie@example.com",
    status: .accepted,
    myEvent: monAnniversaire,
    contact: marie,  // Lié à mon contact "Marie"
    plusOnes: 0
)
```

---

## 📊 Schéma des relations

```
AppUser (TOI)
    └── (aucune relation directe, c'est juste ton profil)

Contact (Ami/Famille)
    └── wishlistItems: [WishlistItem]  // Ce qu'ILS veulent

MyEvent (Ton événement)
    ├── invitations: [Invitation]      // Tes invités
    └── wishlistItems: [WishlistItem]  // Ce que TU veux

WishlistItem (Cadeau)
    ├── contact: Contact?              // OU pour un contact
    └── myEvent: MyEvent?              // OU pour ton événement

Invitation (Invité)
    ├── myEvent: MyEvent               // Événement lié
    └── contact: Contact?              // Optionnel: si l'invité est dans tes contacts
```

---

## 🎨 Interface utilisateur

### Onglet 1 : **Anniversaires** (BirthdaysView - À REFAIRE)

Affiche :
- Liste de tous tes **Contacts**
- Prochain anniversaire de chaque contact
- Jours restants
- Badge si anniversaire aujourd'hui ou cette semaine
- Accès à leur wishlist

Actions :
- Ajouter un contact (prénom, nom, date de naissance)
- Voir la wishlist d'un contact
- Éditer/Supprimer un contact

### Onglet 2 : **Événements** (EventsView - À REFAIRE)

Affiche :
- Liste de tous **TES événements** (MyEvent)
- Date, lieu, nombre d'invités
- Statut des invitations (X acceptés, Y refusés, Z en attente)
- Badge si événement proche

Actions :
- Créer un événement (type, titre, date, lieu, etc.)
- Gérer les invitations (envoyer, voir statuts, approuver demandes)
- Créer TA wishlist pour cet événement
- Éditer/Supprimer un événement

### Onglet 3 : **Ma Wishlist** (MyWishlistView - À CRÉER)

Affiche :
- Toutes **TES wishlists** groupées par événement
  - Wishlist pour "Mon anniversaire 2025"
  - Wishlist pour "Mon mariage"
  - Wishlist pour "Noël 2025"
  - Etc.

Actions :
- Ajouter un cadeau à une wishlist
- Éditer/Supprimer un cadeau
- Voir qui a réservé quel cadeau
- Partager la wishlist (URL, QR code)

### Paramètres (SettingsView)

Nouveau bouton :
- **"Modifier mon profil"** → Ouvre `ProfileView`

Dans ProfileView :
- Renseigner prénom, nom, date de naissance, photo, téléphone
- L'email vient de l'authentification (non modifiable)

---

## 🔧 Fichiers créés/modifiés

### Nouveaux modèles :

✅ `Models/User.swift` (classe `AppUser`)
✅ `Models/Contact.swift`
✅ `Models/MyEvent.swift`
✅ `Models/WishlistItem.swift`
✅ `Models/Invitation.swift`

### Nouvelles vues :

✅ `Views/ProfileView.swift` - Créer/éditer ton profil
🔄 `Views/BirthdaysView.swift` - **À REFAIRE** pour utiliser Contact
🔄 `Views/EventsView.swift` - **À REFAIRE** pour utiliser MyEvent
❌ `Views/MyWishlistView.swift` - **À CRÉER**

### Vues d'authentification :

✅ `Views/Auth/LoginView.swift`
✅ `Views/Auth/SignUpView.swift`
✅ `Services/AuthManager.swift`

### Mis à jour :

✅ `MomentsApp.swift` - Ajout des nouveaux modèles au modelContainer
✅ `SettingsView.swift` - Ajout bouton "Modifier mon profil"

---

## 📱 Comment tester sur ton iPhone

### 1. Build et Run

Le build compile sans erreurs ✅

### 2. Première utilisation

1. **Connexion** : LoginView s'affiche, crée un compte ou connecte-toi
2. **Profil** : Va dans Paramètres → "Modifier mon profil"
3. **Remplis ton profil** :
   - Prénom : Teddy
   - Nom : Dubois
   - Date de naissance : 15/06/1995
   - Photo : Sélectionne une photo de ta galerie
   - Téléphone : +33 6 12 34 56 78
4. **Sauvegarde** : Clique sur "Créer mon profil"

### 3. Prochaines étapes

Une fois ton profil créé, tu pourras :

**Option A** : Refaire **BirthdaysView** pour ajouter tes amis/famille
- Ajouter des contacts (Marie, Thomas, etc.)
- Voir leurs anniversaires
- Créer leur wishlist

**Option B** : Refaire **EventsView** pour créer tes événements
- Créer "Mon anniversaire 2025"
- Inviter des gens
- Créer ta wishlist pour cet événement

**Option C** : Créer **MyWishlistView** pour gérer toutes tes wishlists
- Vue centralisée de tous les cadeaux que tu veux
- Groupés par événement

---

## 🎯 État actuel

### ✅ Terminé (Mode test/mock)

- [x] Modèle AppUser (profil utilisateur)
- [x] Modèle Contact (amis/famille)
- [x] Modèle MyEvent (mes événements)
- [x] Modèle WishlistItem (cadeaux)
- [x] Modèle Invitation (invités)
- [x] ProfileView (créer/éditer mon profil)
- [x] LoginView + SignUpView (authentification mock)
- [x] AuthManager (gestion session UserDefaults)

### 🔄 À refaire

- [ ] BirthdaysView → Utiliser `Contact` au lieu de `Event`
- [ ] EventsView → Utiliser `MyEvent` au lieu de `Event`
- [ ] AddEditEventView → Adapter pour `MyEvent`

### ❌ À créer

- [ ] MyWishlistView → Gérer toutes mes wishlists
- [ ] ContactDetailView → Voir détails d'un contact + sa wishlist
- [ ] MyEventDetailView → Voir détails d'un événement + invitations
- [ ] InvitationManagementView → Gérer les invitations
- [ ] WishlistItemDetailView → Détails d'un cadeau

---

## 💡 Concepts importants

### Pourquoi "AppUser" et pas "User" ?

Il y avait un **conflit de nom** avec `Supabase.User`. En SwiftData, on ne peut pas avoir deux classes avec le même nom, donc j'ai renommé en `AppUser`.

### Pourquoi "itemDescription" et pas "description" ?

`description` est un mot réservé en Swift (hérité de `NSObject`). SwiftData ne permet pas d'utiliser ce nom pour une propriété.

### Pourquoi Contact.wishlistItems ET MyEvent.wishlistItems ?

Parce qu'il y a **DEUX types de wishlists** :

1. **Wishlist d'un contact** : Ce que TES AMIS veulent (pour savoir quoi leur offrir)
2. **Wishlist de ton événement** : Ce que TU veux recevoir (pour que tes invités sachent quoi t'offrir)

Un `WishlistItem` a soit un `contact`, soit un `myEvent`, mais **jamais les deux**.

---

## 🚀 Prochaine étape

Dis-moi ce que tu veux faire en priorité :

**A** - Refaire **BirthdaysView** pour ajouter tes amis (1h)
**B** - Refaire **EventsView** pour créer tes événements (1h)
**C** - Créer **MyWishlistView** pour gérer tes wishlists (1h30)

Je te recommande **A → B → C** pour avoir un parcours complet cohérent.

---

**Version** : 1.0.0
**Date** : 5 décembre 2025
**Status** : Architecture complète ✅, Vues en cours de création 🔄
