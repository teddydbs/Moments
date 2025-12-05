-- ============================================
-- MOMENTS APP - SUPABASE DATABASE SCHEMA
-- Migration initiale
-- ============================================

-- Extension pour UUID (normalement déjà activée sur Supabase)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLE: users (profils utilisateurs)
-- ============================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index pour recherche par email
CREATE INDEX idx_users_email ON users(email);

-- ============================================
-- TABLE: events (événements)
-- ============================================
CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    date DATE NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('birthday', 'wedding', 'bar_mitzvah', 'bachelor_party', 'bachelorette_party', 'party', 'other')),
    notes TEXT DEFAULT '',
    has_gift_pool BOOLEAN DEFAULT FALSE,
    image_url TEXT,
    is_recurring BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index pour recherche par owner
CREATE INDEX idx_events_owner_id ON events(owner_id);
-- Index pour recherche par date
CREATE INDEX idx_events_date ON events(date);
-- Index composite pour queries fréquentes
CREATE INDEX idx_events_owner_date ON events(owner_id, date DESC);

-- ============================================
-- TABLE: participants
-- ============================================
CREATE TABLE participants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    source TEXT NOT NULL CHECK (source IN ('manual', 'contacts', 'facebook', 'instagram', 'whatsapp')),
    contact_identifier TEXT,
    social_media_id TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index pour recherche par événement
CREATE INDEX idx_participants_event_id ON participants(event_id);
-- Index pour recherche par source
CREATE INDEX idx_participants_source ON participants(source);

-- ============================================
-- TABLE: gift_ideas (idées cadeaux)
-- ============================================
CREATE TABLE gift_ideas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    product_url TEXT,
    affiliate_url TEXT,
    product_image_url TEXT,
    price NUMERIC(10,2),
    contributor_id UUID REFERENCES users(id) ON DELETE SET NULL,
    proposed_by TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index pour recherche par événement
CREATE INDEX idx_gift_ideas_event_id ON gift_ideas(event_id);
-- Index pour recherche par contributeur
CREATE INDEX idx_gift_ideas_contributor_id ON gift_ideas(contributor_id);

-- ============================================
-- TABLE: contributions (cagnottes)
-- ============================================
CREATE TABLE contributions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    amount NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    status TEXT NOT NULL CHECK (status IN ('pledged', 'pending', 'paid', 'refunded')) DEFAULT 'pledged',
    stripe_payment_intent_id TEXT,
    payment_method TEXT,
    message TEXT,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index pour recherche par événement
CREATE INDEX idx_contributions_event_id ON contributions(event_id);
-- Index pour recherche par utilisateur
CREATE INDEX idx_contributions_user_id ON contributions(user_id);
-- Index pour recherche par statut
CREATE INDEX idx_contributions_status ON contributions(status);
-- Index pour Stripe payment intent
CREATE INDEX idx_contributions_stripe_payment_intent ON contributions(stripe_payment_intent_id);

-- ============================================
-- TABLE: event_invitations (invitations futures)
-- ============================================
CREATE TABLE event_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    inviter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    invitee_email TEXT NOT NULL,
    invitee_id UUID REFERENCES users(id) ON DELETE SET NULL,
    status TEXT NOT NULL CHECK (status IN ('pending', 'accepted', 'declined')) DEFAULT 'pending',
    share_token TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Index pour recherche par événement
CREATE INDEX idx_event_invitations_event_id ON event_invitations(event_id);
-- Index pour recherche par token
CREATE INDEX idx_event_invitations_share_token ON event_invitations(share_token);
-- Index pour recherche par invité
CREATE INDEX idx_event_invitations_invitee_id ON event_invitations(invitee_id);

-- ============================================
-- TABLE: affiliate_conversions (tracking affiliation)
-- ============================================
CREATE TABLE affiliate_conversions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    original_url TEXT NOT NULL,
    affiliate_url TEXT NOT NULL,
    affiliate_tag TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX idx_affiliate_conversions_user_id ON affiliate_conversions(user_id);

-- ============================================
-- FUNCTIONS: Trigger pour updated_at
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Appliquer le trigger à toutes les tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_events_updated_at BEFORE UPDATE ON events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_participants_updated_at BEFORE UPDATE ON participants FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_gift_ideas_updated_at BEFORE UPDATE ON gift_ideas FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_contributions_updated_at BEFORE UPDATE ON contributions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_event_invitations_updated_at BEFORE UPDATE ON event_invitations FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- FUNCTION: Créer un profil user automatiquement après signup
-- ============================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.users (id, email, name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1))
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pour créer automatiquement un profil user
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- VIEWS: Vues utiles pour requêtes complexes
-- ============================================

-- Vue: événements avec compteurs
CREATE VIEW events_with_stats AS
SELECT
    e.*,
    COUNT(DISTINCT p.id) as participant_count,
    COUNT(DISTINCT g.id) as gift_idea_count,
    COALESCE(SUM(c.amount), 0) as total_contributions
FROM events e
LEFT JOIN participants p ON e.id = p.event_id
LEFT JOIN gift_ideas g ON e.id = g.event_id
LEFT JOIN contributions c ON e.id = c.event_id AND c.status = 'paid'
GROUP BY e.id;
