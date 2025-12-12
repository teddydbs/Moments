# 🚀 Guide de configuration Supabase pour Moments

Ce guide t'explique comment connecter l'app **Moments** à Supabase pour la synchronisation cloud.

## 📋 État actuel

✅ **SDK Supabase installé** : v2.37.0
✅ **Credentials configurés** : SupabaseConfig.swift
✅ **SupabaseManager** : Créé mais commenté (anciens modèles)
✅ **SyncManager** : Créé mais commenté (anciens modèles)

## 🎯 Ce qu'il faut faire

### Étape 1 : Créer les tables Supabase

Va sur [supabase.com](https://supabase.com) → Ton projet → SQL Editor et exécute le script suivant :

```sql
-- ============================================
-- SCHÉMA SUPABASE POUR MOMENTS
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLE: app_users
-- Utilisateurs de l'app
-- ============================================
CREATE TABLE IF NOT EXISTS app_users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================
-- TABLE: my_events
-- Événements créés par l'utilisateur
-- ============================================
CREATE TABLE IF NOT EXISTS my_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    owner_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Informations de base
    type TEXT NOT NULL, -- 'birthday', 'wedding', 'babyShower', etc.
    title TEXT NOT NULL,
    event_description TEXT,

    -- Date et heure
    date DATE NOT NULL,
    time TIME,

    -- Lieu
    location TEXT,
    location_address TEXT,

    -- Photos (URLs vers Storage)
    cover_photo_url TEXT,
    profile_photo_url TEXT,

    -- Configuration
    max_guests INTEGER,
    rsvp_deadline DATE,

    -- Métadonnées
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index pour les requêtes
CREATE INDEX idx_my_events_owner_id ON my_events(owner_id);
CREATE INDEX idx_my_events_date ON my_events(date);

-- ============================================
-- TABLE: invitations
-- Invitations envoyées pour un événement
-- ============================================
CREATE TABLE IF NOT EXISTS invitations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    my_event_id UUID REFERENCES my_events(id) ON DELETE CASCADE,

    -- Informations de l'invité
    guest_name TEXT NOT NULL,
    guest_email TEXT,
    guest_phone_number TEXT,

    -- Statut de l'invitation
    status TEXT DEFAULT 'pending', -- 'pending', 'accepted', 'declined', 'waitingApproval'
    plus_ones INTEGER DEFAULT 0,

    -- Dates
    sent_at TIMESTAMPTZ,
    responded_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_invitations_event_id ON invitations(my_event_id);

-- ============================================
-- TABLE: wishlist_items
-- Cadeaux souhaités pour un événement
-- ============================================
CREATE TABLE IF NOT EXISTS wishlist_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    my_event_id UUID REFERENCES my_events(id) ON DELETE CASCADE,

    -- Informations du produit
    title TEXT NOT NULL,
    product_description TEXT,
    product_url TEXT,
    product_image_url TEXT,
    price DECIMAL(10,2),
    currency TEXT DEFAULT 'EUR',

    -- Statut
    is_reserved BOOLEAN DEFAULT FALSE,
    reserved_by_name TEXT,
    reserved_at TIMESTAMPTZ,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_wishlist_items_event_id ON wishlist_items(my_event_id);

-- ============================================
-- TABLE: event_photos
-- Photos de l'album d'un événement
-- ============================================
CREATE TABLE IF NOT EXISTS event_photos (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    my_event_id UUID REFERENCES my_events(id) ON DELETE CASCADE,

    -- URL de l'image (dans Supabase Storage)
    image_url TEXT NOT NULL,

    -- Métadonnées
    caption TEXT,
    uploaded_by TEXT,
    display_order INTEGER DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_event_photos_event_id ON event_photos(my_event_id);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Activer RLS sur toutes les tables
ALTER TABLE my_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE wishlist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_photos ENABLE ROW LEVEL SECURITY;

-- Policies pour my_events
CREATE POLICY "Users can view their own events"
    ON my_events FOR SELECT
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can create their own events"
    ON my_events FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update their own events"
    ON my_events FOR UPDATE
    USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete their own events"
    ON my_events FOR DELETE
    USING (auth.uid() = owner_id);

-- Policies pour invitations (accessible via l'événement)
CREATE POLICY "Users can view invitations for their events"
    ON invitations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM my_events
            WHERE my_events.id = invitations.my_event_id
            AND my_events.owner_id = auth.uid()
        )
    );

CREATE POLICY "Users can manage invitations for their events"
    ON invitations FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM my_events
            WHERE my_events.id = invitations.my_event_id
            AND my_events.owner_id = auth.uid()
        )
    );

-- Policies pour wishlist_items
CREATE POLICY "Users can manage wishlist items for their events"
    ON wishlist_items FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM my_events
            WHERE my_events.id = wishlist_items.my_event_id
            AND my_events.owner_id = auth.uid()
        )
    );

-- Policies pour event_photos
CREATE POLICY "Users can manage photos for their events"
    ON event_photos FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM my_events
            WHERE my_events.id = event_photos.my_event_id
            AND my_events.owner_id = auth.uid()
        )
    );

-- ============================================
-- TRIGGERS pour updated_at
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_my_events_updated_at BEFORE UPDATE ON my_events
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invitations_updated_at BEFORE UPDATE ON invitations
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wishlist_items_updated_at BEFORE UPDATE ON wishlist_items
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_event_photos_updated_at BEFORE UPDATE ON event_photos
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- VUES UTILES (optionnel)
-- ============================================

-- Vue pour avoir le compte d'invitations par événement
CREATE OR REPLACE VIEW event_invitation_stats AS
SELECT
    my_event_id,
    COUNT(*) as total_invitations,
    COUNT(*) FILTER (WHERE status = 'accepted') as accepted_count,
    COUNT(*) FILTER (WHERE status = 'declined') as declined_count,
    COUNT(*) FILTER (WHERE status = 'pending') as pending_count
FROM invitations
GROUP BY my_event_id;

-- Vue pour avoir le compte de photos par événement
CREATE OR REPLACE VIEW event_photo_counts AS
SELECT
    my_event_id,
    COUNT(*) as photo_count
FROM event_photos
GROUP BY my_event_id;
```

### Étape 2 : Créer les Storage Buckets

Dans Supabase Dashboard → Storage, crée ces buckets :

1. **event-covers** (public)
2. **event-profiles** (public)
3. **event-photos** (public)
4. **wishlist-images** (public)

Pour chaque bucket, configure les permissions :
- Politique d'upload : Authentifié seulement
- Politique de lecture : Public

### Étape 3 : Activer l'authentification Email

Dans Supabase Dashboard → Authentication → Providers :
- ✅ Activer "Email"
- (Optionnel) Activer "Google", "Apple" pour OAuth

### Étape 4 : Code à décommenter

Une fois les tables créées, je vais te montrer comment adapter le code pour utiliser les **nouveaux modèles** (MyEvent, Invitation, WishlistItem, EventPhoto).

## 🔧 Prochaines étapes techniques

1. ✅ Créer les tables SQL (ci-dessus)
2. ✅ Créer les buckets Storage
3. Adapter SupabaseManager pour nouveaux modèles
4. Adapter SyncManager pour nouveaux modèles
5. Décommenter les imports Supabase
6. Tester la connexion
7. Implémenter l'upload de photos
8. Ajouter la sync auto au lancement

## 📝 Notes importantes

- **Row Level Security (RLS)** est activé : Chaque utilisateur ne voit que SES données
- **Triggers** : `updated_at` est automatiquement mis à jour
- **Photos** : Stockées dans Storage, pas en base (URLs seulement)
- **Offline-first** : L'app fonctionne SANS connexion, sync quand possible

---

**Dis-moi quand tu as créé les tables**, et je t'aiderai à adapter le code Swift ! 🚀
