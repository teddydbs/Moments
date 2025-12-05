-- ============================================
-- ROW LEVEL SECURITY (RLS) - POLICIES
-- ============================================

-- Activer RLS sur toutes les tables
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE gift_ideas ENABLE ROW LEVEL SECURITY;
ALTER TABLE contributions ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE affiliate_conversions ENABLE ROW LEVEL SECURITY;

-- ============================================
-- POLICIES: users
-- ============================================

-- Les utilisateurs peuvent voir leur propre profil
CREATE POLICY "Users can view own profile"
    ON users FOR SELECT
    USING (auth.uid() = id);

-- Les utilisateurs peuvent mettre à jour leur propre profil
CREATE POLICY "Users can update own profile"
    ON users FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Permettre l'insertion lors de la création (via trigger)
CREATE POLICY "Users can insert own profile"
    ON users FOR INSERT
    WITH CHECK (auth.uid() = id);

-- ============================================
-- POLICIES: events
-- ============================================

-- Les utilisateurs peuvent voir leurs propres événements
CREATE POLICY "Users can view own events"
    ON events FOR SELECT
    USING (
        auth.uid() = owner_id
        OR
        -- Ou si invité à l'événement (via invitations acceptées)
        EXISTS (
            SELECT 1 FROM event_invitations
            WHERE event_invitations.event_id = events.id
            AND event_invitations.invitee_id = auth.uid()
            AND event_invitations.status = 'accepted'
        )
    );

-- Les utilisateurs peuvent créer leurs propres événements
CREATE POLICY "Users can create own events"
    ON events FOR INSERT
    WITH CHECK (auth.uid() = owner_id);

-- Les utilisateurs peuvent modifier leurs propres événements
CREATE POLICY "Users can update own events"
    ON events FOR UPDATE
    USING (auth.uid() = owner_id)
    WITH CHECK (auth.uid() = owner_id);

-- Les utilisateurs peuvent supprimer leurs propres événements
CREATE POLICY "Users can delete own events"
    ON events FOR DELETE
    USING (auth.uid() = owner_id);

-- ============================================
-- POLICIES: participants
-- ============================================

-- Les utilisateurs peuvent voir les participants de leurs événements
CREATE POLICY "Users can view participants of own events"
    ON participants FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = participants.event_id
            AND (
                events.owner_id = auth.uid()
                OR
                -- Ou invité à l'événement
                EXISTS (
                    SELECT 1 FROM event_invitations
                    WHERE event_invitations.event_id = events.id
                    AND event_invitations.invitee_id = auth.uid()
                    AND event_invitations.status = 'accepted'
                )
            )
        )
    );

-- Les owners peuvent ajouter des participants
CREATE POLICY "Event owners can add participants"
    ON participants FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = participants.event_id
            AND events.owner_id = auth.uid()
        )
    );

-- Les owners peuvent modifier les participants
CREATE POLICY "Event owners can update participants"
    ON participants FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = participants.event_id
            AND events.owner_id = auth.uid()
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = participants.event_id
            AND events.owner_id = auth.uid()
        )
    );

-- Les owners peuvent supprimer les participants
CREATE POLICY "Event owners can delete participants"
    ON participants FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = participants.event_id
            AND events.owner_id = auth.uid()
        )
    );

-- ============================================
-- POLICIES: gift_ideas
-- ============================================

-- Les utilisateurs peuvent voir les idées cadeaux de leurs événements ou des événements où ils sont invités
CREATE POLICY "Users can view gift ideas of accessible events"
    ON gift_ideas FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = gift_ideas.event_id
            AND (
                events.owner_id = auth.uid()
                OR
                EXISTS (
                    SELECT 1 FROM event_invitations
                    WHERE event_invitations.event_id = events.id
                    AND event_invitations.invitee_id = auth.uid()
                    AND event_invitations.status = 'accepted'
                )
            )
        )
    );

-- Les utilisateurs authentifiés peuvent ajouter des idées cadeaux aux événements accessibles
CREATE POLICY "Users can add gift ideas to accessible events"
    ON gift_ideas FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = gift_ideas.event_id
            AND (
                events.owner_id = auth.uid()
                OR
                EXISTS (
                    SELECT 1 FROM event_invitations
                    WHERE event_invitations.event_id = events.id
                    AND event_invitations.invitee_id = auth.uid()
                    AND event_invitations.status = 'accepted'
                )
            )
        )
    );

-- Les owners ou contributeurs peuvent modifier leurs idées
CREATE POLICY "Users can update own gift ideas or event owner can update"
    ON gift_ideas FOR UPDATE
    USING (
        auth.uid() = contributor_id
        OR
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = gift_ideas.event_id
            AND events.owner_id = auth.uid()
        )
    )
    WITH CHECK (
        auth.uid() = contributor_id
        OR
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = gift_ideas.event_id
            AND events.owner_id = auth.uid()
        )
    );

-- Les owners ou contributeurs peuvent supprimer
CREATE POLICY "Users can delete own gift ideas or event owner can delete"
    ON gift_ideas FOR DELETE
    USING (
        auth.uid() = contributor_id
        OR
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = gift_ideas.event_id
            AND events.owner_id = auth.uid()
        )
    );

-- ============================================
-- POLICIES: contributions
-- ============================================

-- Les utilisateurs peuvent voir leurs propres contributions et celles de leurs événements
CREATE POLICY "Users can view own contributions and event contributions"
    ON contributions FOR SELECT
    USING (
        auth.uid() = user_id
        OR
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = contributions.event_id
            AND events.owner_id = auth.uid()
        )
    );

-- Les utilisateurs peuvent créer leurs propres contributions
CREATE POLICY "Users can create own contributions"
    ON contributions FOR INSERT
    WITH CHECK (
        auth.uid() = user_id
        AND
        -- Vérifier que l'événement existe et a une cagnotte activée
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = contributions.event_id
            AND events.has_gift_pool = true
        )
    );

-- Les utilisateurs peuvent modifier leurs propres contributions (statut pending seulement)
CREATE POLICY "Users can update own pending contributions"
    ON contributions FOR UPDATE
    USING (
        auth.uid() = user_id
        AND status = 'pending'
    )
    WITH CHECK (
        auth.uid() = user_id
    );

-- Les event owners peuvent modifier les contributions (pour gérer les remboursements)
CREATE POLICY "Event owners can update contributions"
    ON contributions FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = contributions.event_id
            AND events.owner_id = auth.uid()
        )
    );

-- ============================================
-- POLICIES: event_invitations
-- ============================================

-- Les event owners peuvent voir leurs invitations
CREATE POLICY "Event owners can view invitations"
    ON event_invitations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = event_invitations.event_id
            AND events.owner_id = auth.uid()
        )
        OR
        -- Les invités peuvent voir leurs invitations
        invitee_id = auth.uid()
        OR
        invitee_email = auth.email()
    );

-- Les event owners peuvent créer des invitations
CREATE POLICY "Event owners can create invitations"
    ON event_invitations FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = event_invitations.event_id
            AND events.owner_id = auth.uid()
        )
        AND inviter_id = auth.uid()
    );

-- Les invités peuvent mettre à jour le statut de leurs invitations
CREATE POLICY "Invitees can update invitation status"
    ON event_invitations FOR UPDATE
    USING (
        invitee_id = auth.uid()
        OR
        invitee_email = auth.email()
    )
    WITH CHECK (
        invitee_id = auth.uid()
        OR
        invitee_email = auth.email()
    );

-- Les event owners peuvent supprimer des invitations
CREATE POLICY "Event owners can delete invitations"
    ON event_invitations FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM events
            WHERE events.id = event_invitations.event_id
            AND events.owner_id = auth.uid()
        )
    );

-- ============================================
-- POLICIES: affiliate_conversions
-- ============================================

-- Les utilisateurs peuvent voir leurs propres conversions
CREATE POLICY "Users can view own conversions"
    ON affiliate_conversions FOR SELECT
    USING (auth.uid() = user_id);

-- Les utilisateurs peuvent créer leurs propres conversions
CREATE POLICY "Users can create own conversions"
    ON affiliate_conversions FOR INSERT
    WITH CHECK (auth.uid() = user_id);
