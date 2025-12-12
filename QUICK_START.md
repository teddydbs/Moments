# 🚀 Guide rapide - Voir tes données dans Supabase

## Étape 1 : Créer les tables (2 min)

1. Va sur **https://supabase.com** et connecte-toi
2. Sélectionne ton projet (ksbsvscfplmokacngouo)
3. Menu de gauche → **"SQL Editor"**
4. Ouvre le fichier `SUPABASE_SETUP.md` (déjà créé)
5. Copie tout le SQL (lignes 18-250 environ)
6. Colle dans l'éditeur SQL
7. Clique sur **"Run"**

✅ Tu devrais voir : "Success. No rows returned"

## Étape 2 : Créer les buckets Storage (2 min)

1. Menu de gauche → **"Storage"**
2. Clique **"Create a new bucket"**
3. Crée ces 4 buckets (cocher "Public bucket") :
   - `event-covers`
   - `event-profiles`
   - `event-photos`
   - `wishlist-images`

## Étape 3 : Lier Supabase SDK dans Xcode (1 min)

**C'EST L'ÉTAPE IMPORTANTE** ⚠️

1. Ouvre **Xcode**
2. Clique sur le projet **Moments** (en haut à gauche dans le navigateur)
3. Sélectionne le target **Moments** (pas MomentsShare)
4. Onglet **"General"** →  Scroll jusqu'à **"Frameworks, Libraries, and Embedded Content"**
5. Clique sur le **"+"**
6. Cherche **"Supabase"** dans la liste des packages
7. Ajoute ces frameworks :
   - ✅ **Supabase**
   - ✅ **Auth** (optionnel mais recommandé)
   - ✅ **PostgREST**
   - ✅ **Storage** (pour les photos)

## Étape 4 : Rebuild et teste (2 min)

1. Dans Xcode → **Product** → **Clean Build Folder** (Cmd+Shift+K)
2. **Product** → **Build** (Cmd+B)
3. Lance l'app
4. Va dans l'onglet **"Test DB"** (le dernier onglet, icône disque)
5. Clique sur **"Tester la connexion"**

✅ Tu devrais voir : "✅ Base de données accessible"

## Étape 5 : Créer un événement de test

1. Dans l'app, clique sur **"Créer un événement de test"**
2. Retourne sur **Supabase Dashboard** → **Table Editor** → **my_events**
3. **TU VERRAS TON ÉVÉNEMENT** créé depuis l'app iOS ! 🎉

---

## ⚠️ Si ça ne compile pas

Si Xcode dit "Unable to find module dependency: 'Supabase'", c'est que l'**Étape 3** n'a pas été faite correctement.

**Solution** :
1. Projet Moments → Target Moments → General
2. "Frameworks, Libraries, and Embedded Content"
3. Ajouter "Supabase" depuis les Swift Packages

---

## 🎯 Prochaines étapes

Une fois que tu vois tes données dans Supabase, on pourra :
1. Adapter SupabaseManager pour MyEvent, Invitation, Wishlist
2. Implémenter la sync bidirectionnelle
3. Upload de photos vers Storage
4. Auth avec email/password

**Dis-moi quand tu arrives à l'Étape 5** ! 🚀
