-- =============================================
-- TABLE: wishlist_items
-- Description: Stocke les items de wishlist personnelle des utilisateurs
-- ⚠️ IMPORTANT: Cette table stocke UNIQUEMENT la wishlist personnelle
--              (les cadeaux que l'utilisateur souhaite recevoir)
-- =============================================

-- Supprime la table si elle existe déjà (ATTENTION: perte de données!)
DROP TABLE IF EXISTS public.wishlist_items CASCADE;

-- Crée la table wishlist_items
CREATE TABLE public.wishlist_items (
    -- ✅ Clé primaire
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- ✅ Clé étrangère vers auth.users (propriétaire de la wishlist)
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

    -- 📦 Informations du produit
    title TEXT NOT NULL,
    description TEXT,
    price_in_cents INTEGER, -- Prix en centimes (2999 = 29.99€)
    url TEXT, -- Lien vers le produit

    -- 🏷️ Catégorie du cadeau
    -- Valeurs possibles: "Mode", "Tech", "Maison", "Beauté", "Sport",
    --                    "Loisirs", "Livre", "Expérience", "Argent", "Autre"
    category TEXT NOT NULL DEFAULT 'Autre',

    -- 📊 Statut du cadeau
    -- Valeurs possibles: "Souhaité", "Réservé", "Acheté", "Reçu"
    status TEXT NOT NULL DEFAULT 'Souhaité',

    -- ⭐ Priorité (1 = faible, 2 = moyenne, 3 = haute)
    priority INTEGER NOT NULL DEFAULT 2 CHECK (priority BETWEEN 1 AND 3),

    -- 👤 Personne ayant réservé le cadeau (optionnel)
    reserved_by TEXT,

    -- 📅 Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- =============================================
-- INDEX pour améliorer les performances
-- =============================================

-- Index sur user_id pour récupérer rapidement la wishlist d'un utilisateur
CREATE INDEX idx_wishlist_items_user_id ON public.wishlist_items(user_id);

-- Index sur status pour filtrer par statut
CREATE INDEX idx_wishlist_items_status ON public.wishlist_items(status);

-- Index sur category pour filtrer par catégorie
CREATE INDEX idx_wishlist_items_category ON public.wishlist_items(category);

-- Index composite pour trier par priorité et date
CREATE INDEX idx_wishlist_items_priority_created ON public.wishlist_items(user_id, priority DESC, created_at DESC);

-- =============================================
-- FONCTION: Mettre à jour automatiquement updated_at
-- =============================================

CREATE OR REPLACE FUNCTION public.update_wishlist_items_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger pour appeler la fonction avant chaque UPDATE
CREATE TRIGGER trigger_update_wishlist_items_updated_at
    BEFORE UPDATE ON public.wishlist_items
    FOR EACH ROW
    EXECUTE FUNCTION public.update_wishlist_items_updated_at();

-- =============================================
-- ROW LEVEL SECURITY (RLS)
-- =============================================

-- Active RLS sur la table
ALTER TABLE public.wishlist_items ENABLE ROW LEVEL SECURITY;

-- ✅ POLICY: Les utilisateurs peuvent voir UNIQUEMENT leur propre wishlist
CREATE POLICY "Users can view their own wishlist"
    ON public.wishlist_items
    FOR SELECT
    USING (auth.uid() = user_id);

-- ✅ POLICY: Les utilisateurs peuvent ajouter des items à leur wishlist
CREATE POLICY "Users can insert their own wishlist items"
    ON public.wishlist_items
    FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ✅ POLICY: Les utilisateurs peuvent modifier leur propre wishlist
CREATE POLICY "Users can update their own wishlist items"
    ON public.wishlist_items
    FOR UPDATE
    USING (auth.uid() = user_id);

-- ✅ POLICY: Les utilisateurs peuvent supprimer des items de leur wishlist
CREATE POLICY "Users can delete their own wishlist items"
    ON public.wishlist_items
    FOR DELETE
    USING (auth.uid() = user_id);

-- =============================================
-- COMMENTAIRES sur les colonnes (documentation)
-- =============================================

COMMENT ON TABLE public.wishlist_items IS 'Stocke les items de wishlist personnelle des utilisateurs';
COMMENT ON COLUMN public.wishlist_items.id IS 'Identifiant unique de l''item';
COMMENT ON COLUMN public.wishlist_items.user_id IS 'ID de l''utilisateur propriétaire de la wishlist';
COMMENT ON COLUMN public.wishlist_items.title IS 'Titre du produit souhaité';
COMMENT ON COLUMN public.wishlist_items.description IS 'Description détaillée du produit';
COMMENT ON COLUMN public.wishlist_items.price_in_cents IS 'Prix estimé en centimes (ex: 2999 = 29.99€)';
COMMENT ON COLUMN public.wishlist_items.url IS 'URL du produit (Amazon, etc.)';
COMMENT ON COLUMN public.wishlist_items.category IS 'Catégorie du cadeau (Mode, Tech, Maison, etc.)';
COMMENT ON COLUMN public.wishlist_items.status IS 'Statut du cadeau (Souhaité, Réservé, Acheté, Reçu)';
COMMENT ON COLUMN public.wishlist_items.priority IS 'Priorité: 1 (faible), 2 (moyenne), 3 (haute)';
COMMENT ON COLUMN public.wishlist_items.reserved_by IS 'Nom de la personne ayant réservé le cadeau';
COMMENT ON COLUMN public.wishlist_items.created_at IS 'Date de création de l''item';
COMMENT ON COLUMN public.wishlist_items.updated_at IS 'Date de dernière modification';

-- =============================================
-- DONNÉES DE TEST (optionnel, pour le développement)
-- =============================================

-- ⚠️ Décommenter les lignes ci-dessous pour insérer des données de test
-- IMPORTANT: Remplacer '00000000-0000-0000-0000-000000000000' par un vrai UUID d'utilisateur

/*
INSERT INTO public.wishlist_items (user_id, title, description, price_in_cents, url, category, status, priority)
VALUES
    ('00000000-0000-0000-0000-000000000000', 'AirPods Pro 2', 'Écouteurs sans fil avec réduction de bruit active', 27999, 'https://www.apple.com/fr/airpods-pro/', 'Tech', 'Souhaité', 3),
    ('00000000-0000-0000-0000-000000000000', 'Machine à café Nespresso', 'Modèle Vertuo avec mousseur de lait', 19900, 'https://www.nespresso.com', 'Maison', 'Souhaité', 2),
    ('00000000-0000-0000-0000-000000000000', 'Parfum Chanel N°5', 'Classique indémodable', 12000, NULL, 'Beauté', 'Réservé', 3);
*/

-- =============================================
-- VÉRIFICATION
-- =============================================

-- Vérifie que la table a bien été créée
SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename = 'wishlist_items';

-- Vérifie les policies RLS
SELECT schemaname, tablename, policyname FROM pg_policies WHERE tablename = 'wishlist_items';
