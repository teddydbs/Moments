# 🎯 Configuration Table Invitations - Supabase

**Date** : 13 Décembre 2025
**Objectif** : Activer le système d'invitations multi-utilisateurs

---

## 📋 Ce Que Ce Script Fait

Le fichier `supabase-schema-invitations.sql` crée :

### ✅ Table `invitations`
- Stocke toutes les invitations à des événements
- Gère les statuts : `pending`, `accepted`, `declined`, `waiting_approval`
- Supporte les invités avec ou sans compte Moments
- Permet les accompagnants (+1, +2, etc.)

### ✅ Row Level Security (RLS)
4 politiques de sécurité :
1. **SELECT** : Voir les invitations de tes événements ou celles que tu as reçues
2. **INSERT** : Seul l'organisateur peut inviter
3. **UPDATE** : L'organisateur ou l'invité peut modifier
4. **DELETE** : Seul l'organisateur peut supprimer

### ✅ Fonctions Helper
- `generate_share_token()` : Génère un token unique pour partager
- `accept_invitation()` : Accepter une invitation
- `decline_invitation()` : Refuser une invitation
- `approve_invitation_request()` : Approuver une demande
- `reject_invitation_request()` : Rejeter une demande
- `get_event_invitation_stats()` : Stats sur les invitations d'un événement

### ✅ Triggers Automatiques
- Génération automatique du `share_token`
- Mise à jour automatique de `updated_at`

---

## 🚀 Comment Exécuter le Script

### Étape 1 : Aller dans Supabase Dashboard

1. Va sur https://supabase.com/dashboard
2. Ouvre ton projet **Moments**
3. Dans le menu de gauche, clique sur **SQL Editor**

### Étape 2 : Copier le Script

1. Ouvre le fichier `supabase-schema-invitations.sql`
2. **Copie TOUT le contenu** (Cmd+A puis Cmd+C)

### Étape 3 : Exécuter dans Supabase

1. Dans le **SQL Editor**, clique sur **New Query**
2. Colle le contenu du fichier
3. Clique sur **Run** (ou Cmd+Enter)

### Étape 4 : Vérifier le Résultat

Tu devrais voir :
```
✅ Table invitations créée avec succès !
✅ RLS activé sur invitations
✅ 4 policies créées
```

### Étape 5 : Vérifier la Table

Dans le menu de gauche, va dans **Table Editor** et vérifie que la table `invitations` apparaît.

---

## 🔍 Structure de la Table `invitations`

| Colonne | Type | Description |
|---------|------|-------------|
| `id` | UUID | ID unique de l'invitation |
| `event_id` | UUID | Événement lié (référence `my_events`) |
| `inviter_id` | UUID | Organisateur qui invite (référence `auth.users`) |
| `invitee_user_id` | UUID | Invité s'il a un compte (optionnel) |
| `guest_name` | TEXT | Nom de l'invité |
| `guest_email` | TEXT | Email de l'invité (optionnel) |
| `guest_phone_number` | TEXT | Téléphone de l'invité (optionnel) |
| `status` | TEXT | `pending`, `accepted`, `declined`, `waiting_approval` |
| `sent_at` | TIMESTAMPTZ | Date d'envoi de l'invitation |
| `responded_at` | TIMESTAMPTZ | Date de réponse (optionnel) |
| `guest_message` | TEXT | Message de l'invité (optionnel) |
| `plus_ones` | INTEGER | Nombre d'accompagnants |
| `share_token` | TEXT | Token unique pour partager (généré auto) |
| `share_url` | TEXT | URL de partage (optionnel) |
| `contact_id` | UUID | Référence au contact local (optionnel) |
| `created_at` | TIMESTAMPTZ | Date de création |
| `updated_at` | TIMESTAMPTZ | Dernière mise à jour |

---

## 🔐 Politiques RLS Détaillées

### 1. SELECT (Lecture)
**Qui peut voir une invitation ?**
- L'organisateur de l'événement (`inviter_id`)
- L'invité (`invitee_user_id`)
- Toute personne ayant le `share_token` (géré côté app)

### 2. INSERT (Création)
**Qui peut créer une invitation ?**
- Seul l'organisateur de l'événement (`owner_id` dans `my_events`)

### 3. UPDATE (Modification)
**Qui peut modifier une invitation ?**
- L'organisateur (pour approuver/rejeter)
- L'invité (pour accepter/refuser)

### 4. DELETE (Suppression)
**Qui peut supprimer une invitation ?**
- Seul l'organisateur

---

## 🧪 Tests à Faire

### Test 1 : Créer une invitation

```sql
-- Remplace YOUR_EVENT_ID par l'ID d'un de tes événements
INSERT INTO invitations (
    event_id,
    inviter_id,
    guest_name,
    guest_email,
    status
) VALUES (
    'YOUR_EVENT_ID',
    auth.uid(),
    'Marie Dupont',
    'marie@example.com',
    'pending'
);
```

### Test 2 : Vérifier le share_token

```sql
SELECT id, guest_name, share_token FROM invitations;
```

Le `share_token` doit être généré automatiquement.

### Test 3 : Accepter une invitation

```sql
SELECT accept_invitation('INVITATION_ID', 'Merci, j''ai hâte !');
```

### Test 4 : Voir les stats d'un événement

```sql
SELECT * FROM get_event_invitation_stats('YOUR_EVENT_ID');
```

---

## ⚠️ Migration depuis l'Ancienne Table

Si tu avais l'ancienne table `event_invitations` :

### Option A : Migration Automatique (recommandé)

Le script **supprime automatiquement** l'ancienne table car elle n'était pas utilisée par l'app iOS.

### Option B : Migration des Données (si tu as des données)

Si tu veux conserver les anciennes données :

```sql
-- Migrer les données de event_invitations vers invitations
INSERT INTO invitations (
    event_id,
    inviter_id,
    invitee_user_id,
    guest_name,
    guest_email,
    status,
    share_token,
    created_at,
    updated_at
)
SELECT
    event_id,
    inviter_id,
    invitee_id,
    COALESCE(invitee_email, 'Invité'),
    invitee_email,
    status,
    share_token,
    created_at,
    updated_at
FROM event_invitations;

-- Puis supprimer l'ancienne table
DROP TABLE event_invitations;
```

---

## 🎯 Prochaines Étapes

Une fois ce script exécuté avec succès :

1. ✅ **ÉTAPE 1 COMPLÉTÉE** : Table `invitations` créée
2. ⏭️ **ÉTAPE 2** : Migrer le modèle Swift `Invitation.swift`
3. ⏭️ **ÉTAPE 3** : Implémenter le système de partage
4. ⏭️ **ÉTAPE 4** : Créer les deep links
5. ⏭️ **ÉTAPE 5** : Ajouter l'UI de partage
6. ⏭️ **ÉTAPE 6** : Flow d'acceptation/refus
7. ⏭️ **ÉTAPE 7** : Tests multi-utilisateurs

---

## 🆘 En Cas d'Erreur

### Erreur : "relation my_events does not exist"
**Cause** : La table `my_events` n'existe pas encore.
**Solution** : Exécute d'abord le script de création de `my_events`.

### Erreur : "function update_updated_at_column does not exist"
**Cause** : La fonction trigger n'a pas été créée.
**Solution** : Exécute le script `supabase/migrations/20250101000000_initial_schema.sql` en premier.

### Erreur : "permission denied for schema auth"
**Cause** : Tu n'as pas les permissions admin.
**Solution** : Vérifie que tu es connecté au bon projet Supabase.

---

## 📞 Support

Si tu as un problème :
1. Regarde les erreurs dans le **SQL Editor**
2. Vérifie que tu es sur le bon projet Supabase
3. Vérifie que la table `my_events` existe
4. Reviens me voir avec le message d'erreur complet

---

**Prêt ?** Va sur Supabase et exécute le script ! 🚀

Une fois fait, dis-moi **"Étape 1 terminée"** et on passe à l'ÉTAPE 2 : Migration du modèle Swift.
