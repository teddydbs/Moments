# 📱 Guide de Test - Authentification Moments

## 🎯 Ce qui a été fait

### Fichiers créés/modifiés :

1. **[AuthManager.swift](Moments/Services/AuthManager.swift)** - Service de gestion d'authentification (mode test)
2. **[LoginView.swift](Moments/Views/Auth/LoginView.swift)** - Vue de connexion
3. **[SignUpView.swift](Moments/Views/Auth/SignUpView.swift)** - Vue d'inscription
4. **[MomentsApp.swift](Moments/MomentsApp.swift)** - Point d'entrée avec routing auth
5. **[SettingsView.swift](Moments/Views/SettingsView.swift)** - Ajout bouton déconnexion

## 🧪 Comment tester sur ton iPhone

### 1. Premier lancement (nouveau)

Quand tu ouvres l'app pour la première fois :

✅ **Tu devrais voir** : LoginView avec logo violet/rose, champs email/password
✅ **Thème** : Dégradé violet/rose cohérent avec le logo

### 2. Tester l'inscription

Depuis LoginView :

1. Clique sur **"Créer un compte"**
2. Remplis le formulaire :
   - **Nom** : Ton nom (ex: Teddy)
   - **Email** : N'importe quel email valide avec @ (ex: test@moments.app)
   - **Mot de passe** : Au moins 6 caractères
   - **Confirmer** : Même mot de passe
   - ✅ Coche **"J'accepte les conditions"**

✅ **Tu devrais voir** :
- Indicateur de force du mot de passe (rouge/orange/jaune/vert)
- Message d'erreur si les mots de passe ne correspondent pas
- Bouton grisé si le formulaire est invalide

3. Clique sur **"Créer mon compte"**
4. Loader pendant 1.5 secondes
5. **→ Tu arrives sur MainTabView** (page d'accueil avec onglets)

### 3. Vérifier la persistance de session

1. Ferme complètement l'app (swipe vers le haut dans le multitâche)
2. Rouvre l'app

✅ **Tu devrais voir** : MainTabView directement (pas de LoginView)
→ La session est sauvegardée dans UserDefaults !

### 4. Tester la déconnexion

1. Va sur l'onglet **"Anniversaires"** ou **"Événements"**
2. Clique sur l'icône **engrenage** (Paramètres) en haut à gauche
3. Scroll en bas de la page
4. Tu vois une section **"Compte"** avec ton nom et email
5. Clique sur **"Se déconnecter"** (bouton rouge)
6. Alerte de confirmation
7. Clique sur **"Se déconnecter"**

✅ **Tu devrais voir** : Retour à LoginView
✅ **Session nettoyée** : Si tu fermes et rouvres l'app, tu reviens sur LoginView

### 5. Tester la connexion

Depuis LoginView :

1. Entre un email avec @ (ex: teddy@test.fr)
2. Entre un mot de passe d'au moins 6 caractères
3. Clique sur **"Se connecter"**
4. Loader pendant 1 seconde
5. **→ Tu arrives sur MainTabView**

**Validation :**
- Email sans @ → Message d'erreur
- Mot de passe < 6 caractères → Message d'erreur

### 6. Tester "Mot de passe oublié"

1. Clique sur **"Mot de passe oublié ?"**
2. Alerte avec ton email (ou "votre adresse" si vide)
3. Clique sur **"Envoyer"**

✅ **Note** : C'est un mock, rien n'est envoyé pour l'instant

### 7. Toggle "Afficher/Masquer mot de passe"

- Clique sur l'icône **œil** pour voir le mot de passe en clair
- Clique sur **œil barré** pour le masquer

## 🎨 Ce qui a été testé

✅ Thème violet/rose cohérent sur toutes les vues d'auth
✅ Gradient sur icônes et bordures
✅ Animations de boutons
✅ Validation de formulaires
✅ Indicateur de force du mot de passe
✅ Messages d'erreur
✅ Persistance de session (UserDefaults)
✅ Navigation LoginView ↔ SignUpView
✅ Navigation conditionnelle (Login → MainTabView)
✅ Déconnexion complète

## 🔒 Données en mode test

**Important** : Tout est en mode **mock/test** pour l'instant !

- Les mots de passe ne sont PAS hashés
- Les données sont stockées localement (UserDefaults)
- Pas de vraie base de données
- N'importe quel email/password valide fonctionne

**Pourquoi ?**
→ On construit d'abord toutes les pages en mode test
→ On connectera Supabase (vrai backend) plus tard

## 🚀 Prochaine étape

Une fois que tu as testé l'authentification, on peut passer à :

**Option A** : Créer les modèles User, Contact, Invitation (30 min)
**Option B** : Créer la vue de gestion des Contacts/Personnes (1h)
**Option C** : Créer le système d'invitations UI (1h30)

→ Dis-moi ce que tu veux faire ensuite !

## 🐛 Problèmes possibles

### "Je vois un écran blanc"
→ Assure-toi que le build a réussi (Build Succeeded dans Xcode)

### "L'app crash au lancement"
→ Vérifie les logs dans Xcode (Console en bas)

### "Je reste bloqué sur LoginView après signup"
→ Vérifie que tu as bien coché "J'accepte les conditions"

### "La session ne persiste pas"
→ Vérifie que tu n'as pas d'erreur dans les logs

---

**Version** : 1.0.0
**Date** : 5 décembre 2025
**Status** : ✅ Prêt à tester
