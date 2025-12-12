-- ============================================
-- SCHEMA SUPABASE - PROFILES
-- Table pour stocker les informations de profil utilisateur
-- ============================================

-- 1. Créer la table profiles
CREATE TABLE IF NOT EXISTS public.profiles (
    -- Clé primaire liée à auth.users
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,

    -- Informations personnelles
    first_name TEXT,
    last_name TEXT,
    birth_date DATE,
    phone_number TEXT,

    -- Photos
    profile_photo_url TEXT,

    -- Adresse
    address_street TEXT,
    address_city TEXT,
    address_postal_code TEXT,
    address_country TEXT,

    -- Préférences
    notification_enabled BOOLEAN DEFAULT true,
    theme_preference TEXT DEFAULT 'auto', -- 'light', 'dark', 'auto'

    -- Onboarding
    onboarding_completed BOOLEAN DEFAULT false,
    onboarding_step INTEGER DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Activer RLS (Row Level Security)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- 3. Policies RLS

-- Policy: Les utilisateurs peuvent voir leur propre profil
CREATE POLICY "Users can view own profile"
    ON public.profiles
    FOR SELECT
    USING (auth.uid() = id);

-- Policy: Les utilisateurs peuvent créer leur propre profil
CREATE POLICY "Users can create own profile"
    ON public.profiles
    FOR INSERT
    WITH CHECK (auth.uid() = id);

-- Policy: Les utilisateurs peuvent modifier leur propre profil
CREATE POLICY "Users can update own profile"
    ON public.profiles
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- Policy: Les utilisateurs peuvent supprimer leur propre profil
CREATE POLICY "Users can delete own profile"
    ON public.profiles
    FOR DELETE
    USING (auth.uid() = id);

-- 4. Créer une fonction pour auto-créer le profil lors de l'inscription
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, first_name, last_name)
    VALUES (
        NEW.id,
        NEW.raw_user_meta_data->>'first_name',
        NEW.raw_user_meta_data->>'last_name'
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Créer le trigger pour auto-créer le profil
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 6. Créer une fonction pour mettre à jour updated_at automatiquement
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 7. Créer le trigger pour updated_at
DROP TRIGGER IF EXISTS on_profile_updated ON public.profiles;
CREATE TRIGGER on_profile_updated
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- 8. Créer des index pour améliorer les performances
CREATE INDEX IF NOT EXISTS idx_profiles_birth_date ON public.profiles(birth_date);
CREATE INDEX IF NOT EXISTS idx_profiles_created_at ON public.profiles(created_at);

-- ============================================
-- STORAGE - Buckets pour les photos de profil
-- ============================================

-- 1. Créer le bucket pour les photos de profil (si pas déjà créé)
INSERT INTO storage.buckets (id, name, public)
VALUES ('profile-photos', 'profile-photos', true)
ON CONFLICT (id) DO NOTHING;

-- 2. Policies pour le bucket profile-photos

-- Policy: Tout le monde peut voir les photos de profil
CREATE POLICY "Public profile photos are publicly accessible"
    ON storage.objects
    FOR SELECT
    USING (bucket_id = 'profile-photos');

-- Policy: Les utilisateurs authentifiés peuvent uploader leur photo
CREATE POLICY "Users can upload own profile photo"
    ON storage.objects
    FOR INSERT
    WITH CHECK (
        bucket_id = 'profile-photos'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Policy: Les utilisateurs peuvent mettre à jour leur photo
CREATE POLICY "Users can update own profile photo"
    ON storage.objects
    FOR UPDATE
    USING (
        bucket_id = 'profile-photos'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    )
    WITH CHECK (
        bucket_id = 'profile-photos'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Policy: Les utilisateurs peuvent supprimer leur photo
CREATE POLICY "Users can delete own profile photo"
    ON storage.objects
    FOR DELETE
    USING (
        bucket_id = 'profile-photos'
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- ============================================
-- VUES UTILES
-- ============================================

-- Vue pour récupérer les profils avec les infos auth
CREATE OR REPLACE VIEW public.profiles_with_email AS
SELECT
    p.*,
    u.email,
    u.raw_user_meta_data->>'name' as oauth_name,
    u.raw_user_meta_data->>'picture' as oauth_picture
FROM public.profiles p
LEFT JOIN auth.users u ON p.id = u.id;

-- ============================================
-- DONNÉES DE TEST (optionnel)
-- ============================================

-- Commenter cette section en production
-- INSERT INTO public.profiles (id, first_name, last_name, birth_date, onboarding_completed)
-- VALUES (
--     auth.uid(),
--     'John',
--     'Doe',
--     '1990-01-01',
--     true
-- );

-- ============================================
-- NOTES
-- ============================================

-- Pour récupérer le profil d'un utilisateur :
-- SELECT * FROM profiles WHERE id = auth.uid();

-- Pour mettre à jour le profil :
-- UPDATE profiles
-- SET first_name = 'John', last_name = 'Doe', birth_date = '1990-01-01'
-- WHERE id = auth.uid();

-- Pour uploader une photo de profil :
-- 1. Upload l'image vers le bucket 'profile-photos' avec le path : {user_id}/profile.jpg
-- 2. Récupérer l'URL publique
-- 3. Mettre à jour profile_photo_url dans la table profiles
