-- ============================================
-- MOMENTS APP - TABLE INVITATIONS V2
-- Gestion des invitations multi-utilisateurs
-- Version: Migration sûre (vérifie si la table existe)
-- ============================================

-- ============================================
-- ÉTAPE 1: Vérifier et sauvegarder les données existantes
-- ============================================

-- Créer une table temporaire pour sauvegarder les données si elles existent
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'invitations') THEN
        RAISE NOTICE 'Table invitations existe déjà - sauvegarde des données...';

        -- Créer une table de backup
        CREATE TABLE IF NOT EXISTS invitations_backup AS SELECT * FROM invitations;

        RAISE NOTICE 'Backup créé dans invitations_backup';
    ELSE
        RAISE NOTICE 'Table invitations n''existe pas - création...';
    END IF;
END $$;

-- ============================================
-- ÉTAPE 2: Supprimer l'ancienne table invitations
-- ============================================

DROP TABLE IF EXISTS invitations CASCADE;
DROP TABLE IF EXISTS event_invitations CASCADE;

-- ============================================
-- ÉTAPE 3: Créer la nouvelle table invitations
-- ============================================

CREATE TABLE invitations (
    -- Identifiants
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Relations
    event_id UUID NOT NULL REFERENCES my_events(id) ON DELETE CASCADE,
    inviter_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE, -- Celui qui invite
    invitee_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,    -- Invité s'il a un compte

    -- Informations invité (si pas encore de compte)
    guest_name TEXT NOT NULL,
    guest_email TEXT,
    guest_phone_number TEXT,

    -- Statut de l'invitation
    -- pending: Invitation envoyée, pas de réponse
    -- accepted: Invité a accepté
    -- declined: Invité a refusé
    -- waiting_approval: Invité demande à venir, organisateur doit approuver
    status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'declined', 'waiting_approval')) DEFAULT 'pending',

    -- Dates
    sent_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    responded_at TIMESTAMPTZ,

    -- Messages
    guest_message TEXT, -- Message de l'invité lors de sa réponse

    -- Accompagnants (+1, famille, etc.)
    plus_ones INTEGER NOT NULL DEFAULT 0 CHECK (plus_ones >= 0),

    -- Partage
    share_token TEXT UNIQUE NOT NULL, -- Token unique pour partager l'invitation
    share_url TEXT, -- URL de partage générée

    -- Contact lié (optionnel)
    contact_id UUID, -- Référence au contact local (pas de FK car local)

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================
-- ÉTAPE 4: Créer les indexes
-- ============================================

-- Index pour recherche par événement
CREATE INDEX idx_invitations_event_id ON invitations(event_id);

-- Index pour recherche par inviter
CREATE INDEX idx_invitations_inviter_id ON invitations(inviter_id);

-- Index pour recherche par invitee
CREATE INDEX idx_invitations_invitee_user_id ON invitations(invitee_user_id);

-- Index pour recherche par statut
CREATE INDEX idx_invitations_status ON invitations(status);

-- Index pour recherche par share_token (utilisé pour les deep links)
CREATE INDEX idx_invitations_share_token ON invitations(share_token);

-- Index composite pour queries fréquentes
CREATE INDEX idx_invitations_event_status ON invitations(event_id, status);

-- ============================================
-- ÉTAPE 5: Créer les fonctions et triggers
-- ============================================

-- TRIGGER: Updated_at automatique
CREATE TRIGGER update_invitations_updated_at
    BEFORE UPDATE ON invitations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- FUNCTION: Générer un share_token unique
CREATE OR REPLACE FUNCTION generate_share_token()
RETURNS TEXT AS $$
DECLARE
    token TEXT;
    exists BOOLEAN;
BEGIN
    LOOP
        -- Générer un token aléatoire de 16 caractères
        token := encode(gen_random_bytes(12), 'base64');
        token := replace(token, '/', '_');
        token := replace(token, '+', '-');
        token := substring(token, 1, 16);

        -- Vérifier que le token n'existe pas déjà
        SELECT EXISTS(SELECT 1 FROM invitations WHERE share_token = token) INTO exists;

        EXIT WHEN NOT exists;
    END LOOP;

    RETURN token;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER: Générer share_token automatiquement
CREATE OR REPLACE FUNCTION set_invitation_share_token()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.share_token IS NULL OR NEW.share_token = '' THEN
        NEW.share_token := generate_share_token();
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_invitations_share_token
    BEFORE INSERT ON invitations
    FOR EACH ROW
    EXECUTE FUNCTION set_invitation_share_token();

-- ============================================
-- ÉTAPE 6: Activer Row Level Security (RLS)
-- ============================================

ALTER TABLE invitations ENABLE ROW LEVEL SECURITY;

-- ✅ POLITIQUE 1: SELECT
-- Un utilisateur peut voir les invitations :
-- - Des événements qu'il organise (inviter_id)
-- - Des événements auxquels il est invité (invitee_user_id)
-- - Ou via le share_token (pour les invités sans compte)
CREATE POLICY "invitations_select_policy" ON invitations
    FOR SELECT
    USING (
        (select auth.uid()) = inviter_id OR
        (select auth.uid()) = invitee_user_id OR
        share_token IS NOT NULL -- Permet l'accès via share_token (géré côté app)
    );

-- ✅ POLITIQUE 2: INSERT
-- Seul l'organisateur de l'événement peut créer des invitations
CREATE POLICY "invitations_insert_policy" ON invitations
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM my_events
            WHERE my_events.id = event_id
            AND my_events.owner_id = (select auth.uid())
        )
    );

-- ✅ POLITIQUE 3: UPDATE
-- Un utilisateur peut modifier une invitation si :
-- - Il est l'organisateur (pour approuver/rejeter)
-- - Il est l'invité (pour accepter/refuser)
CREATE POLICY "invitations_update_policy" ON invitations
    FOR UPDATE
    USING (
        (select auth.uid()) = inviter_id OR
        (select auth.uid()) = invitee_user_id
    )
    WITH CHECK (
        (select auth.uid()) = inviter_id OR
        (select auth.uid()) = invitee_user_id
    );

-- ✅ POLITIQUE 4: DELETE
-- Seul l'organisateur peut supprimer une invitation
CREATE POLICY "invitations_delete_policy" ON invitations
    FOR DELETE
    USING (
        (select auth.uid()) = inviter_id
    );

-- ============================================
-- ÉTAPE 7: Créer les fonctions helper
-- ============================================

-- FUNCTION: Statistiques des invitations
CREATE OR REPLACE FUNCTION get_event_invitation_stats(event_uuid UUID)
RETURNS TABLE (
    total_invitations INTEGER,
    accepted_count INTEGER,
    pending_count INTEGER,
    declined_count INTEGER,
    waiting_approval_count INTEGER,
    total_guests INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*)::INTEGER AS total_invitations,
        COUNT(*) FILTER (WHERE status = 'accepted')::INTEGER AS accepted_count,
        COUNT(*) FILTER (WHERE status = 'pending')::INTEGER AS pending_count,
        COUNT(*) FILTER (WHERE status = 'declined')::INTEGER AS declined_count,
        COUNT(*) FILTER (WHERE status = 'waiting_approval')::INTEGER AS waiting_approval_count,
        (COUNT(*) FILTER (WHERE status = 'accepted') +
         SUM(CASE WHEN status = 'accepted' THEN plus_ones ELSE 0 END))::INTEGER AS total_guests
    FROM invitations
    WHERE event_id = event_uuid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- FUNCTION: Accepter une invitation
CREATE OR REPLACE FUNCTION accept_invitation(
    invitation_id UUID,
    user_message TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    current_user_id UUID;
BEGIN
    current_user_id := auth.uid();

    -- Vérifier que l'utilisateur est bien l'invité
    IF NOT EXISTS (
        SELECT 1 FROM invitations
        WHERE id = invitation_id
        AND invitee_user_id = current_user_id
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Not the invitee';
    END IF;

    -- Mettre à jour l'invitation
    UPDATE invitations
    SET
        status = 'accepted',
        responded_at = now(),
        guest_message = user_message,
        updated_at = now()
    WHERE id = invitation_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- FUNCTION: Refuser une invitation
CREATE OR REPLACE FUNCTION decline_invitation(
    invitation_id UUID,
    user_message TEXT DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
    current_user_id UUID;
BEGIN
    current_user_id := auth.uid();

    -- Vérifier que l'utilisateur est bien l'invité
    IF NOT EXISTS (
        SELECT 1 FROM invitations
        WHERE id = invitation_id
        AND invitee_user_id = current_user_id
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Not the invitee';
    END IF;

    -- Mettre à jour l'invitation
    UPDATE invitations
    SET
        status = 'declined',
        responded_at = now(),
        guest_message = user_message,
        updated_at = now()
    WHERE id = invitation_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- FUNCTION: Approuver une demande
CREATE OR REPLACE FUNCTION approve_invitation_request(
    invitation_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    current_user_id UUID;
BEGIN
    current_user_id := auth.uid();

    -- Vérifier que l'utilisateur est bien l'organisateur
    IF NOT EXISTS (
        SELECT 1 FROM invitations
        WHERE id = invitation_id
        AND inviter_id = current_user_id
        AND status = 'waiting_approval'
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Not the organizer or invalid status';
    END IF;

    -- Approuver la demande
    UPDATE invitations
    SET
        status = 'accepted',
        updated_at = now()
    WHERE id = invitation_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- FUNCTION: Rejeter une demande
CREATE OR REPLACE FUNCTION reject_invitation_request(
    invitation_id UUID
)
RETURNS BOOLEAN AS $$
DECLARE
    current_user_id UUID;
BEGIN
    current_user_id := auth.uid();

    -- Vérifier que l'utilisateur est bien l'organisateur
    IF NOT EXISTS (
        SELECT 1 FROM invitations
        WHERE id = invitation_id
        AND inviter_id = current_user_id
        AND status = 'waiting_approval'
    ) THEN
        RAISE EXCEPTION 'Unauthorized: Not the organizer or invalid status';
    END IF;

    -- Rejeter la demande
    UPDATE invitations
    SET
        status = 'declined',
        updated_at = now()
    WHERE id = invitation_id;

    RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================
-- ÉTAPE 8: Restaurer les données de backup (si besoin)
-- ============================================

-- Note: Cette section est commentée par défaut
-- Décommenter si tu veux restaurer les anciennes données

/*
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE schemaname = 'public' AND tablename = 'invitations_backup') THEN
        RAISE NOTICE 'Restauration des données depuis invitations_backup...';

        -- Insérer les données de backup dans la nouvelle table
        INSERT INTO invitations (
            id,
            event_id,
            inviter_id,
            invitee_user_id,
            guest_name,
            guest_email,
            guest_phone_number,
            status,
            sent_at,
            responded_at,
            guest_message,
            plus_ones,
            share_token,
            created_at,
            updated_at
        )
        SELECT
            id,
            event_id,
            inviter_id,
            invitee_user_id,
            guest_name,
            guest_email,
            guest_phone_number,
            status,
            sent_at,
            responded_at,
            guest_message,
            plus_ones,
            COALESCE(share_token, generate_share_token()), -- Générer token si NULL
            created_at,
            updated_at
        FROM invitations_backup;

        RAISE NOTICE 'Données restaurées avec succès !';

        -- Optionnel: Supprimer le backup
        -- DROP TABLE invitations_backup;
    ELSE
        RAISE NOTICE 'Pas de backup trouvé - table fraîche créée';
    END IF;
END $$;
*/

-- ============================================
-- ÉTAPE 9: Vérification finale
-- ============================================

SELECT 'Table invitations créée avec succès !' AS message;
SELECT 'RLS activé sur invitations' AS security;
SELECT COUNT(*) AS policies_count FROM pg_policies WHERE tablename = 'invitations';

-- Afficher les colonnes de la table
SELECT
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns
WHERE table_name = 'invitations'
ORDER BY ordinal_position;
