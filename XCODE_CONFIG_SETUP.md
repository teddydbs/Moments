# Configuration Xcode - Build Configuration Files

## 🎯 Objectif

Configurer Xcode pour utiliser les fichiers `Debug.xcconfig` et `Release.xcconfig` afin de sécuriser les clés API Supabase.

## 📝 Étapes de configuration

### Étape 1 : Ajouter les fichiers .xcconfig au projet Xcode

1. Ouvre **Xcode**
2. Ouvre le projet **Moments.xcodeproj**
3. Dans le navigateur de fichiers (sidebar gauche), fais un clic droit sur le dossier "Moments"
4. Sélectionne **"Add Files to Moments..."**
5. Navigate vers `Moments/Config/`
6. Sélectionne **Debug.xcconfig** et **Release.xcconfig**
7. ⚠️ **IMPORTANT** : Décoche "Copy items if needed" (on veut garder les fichiers où ils sont)
8. Coche "Create groups"
9. Coche la target "Moments"
10. Clique sur **"Add"**

### Étape 2 : Configurer les Build Configurations

1. Dans le navigateur de projet (sidebar gauche), clique sur **"Moments"** (icône bleue du projet en haut)
2. Dans la section centrale, sélectionne le **projet "Moments"** (pas la target, le projet)
3. Sélectionne l'onglet **"Info"**
4. Défile jusqu'à la section **"Configurations"**
5. Tu devrais voir :
   ```
   Debug
   Release
   ```

6. Pour **Debug** :
   - Clique sur la colonne de droite (actuellement "None")
   - Sélectionne **"Debug"** dans le menu déroulant
   - Si "Debug" n'apparaît pas, clique sur "Other..." et sélectionne `Moments/Config/Debug.xcconfig`

7. Pour **Release** :
   - Clique sur la colonne de droite (actuellement "None")
   - Sélectionne **"Release"** dans le menu déroulant
   - Si "Release" n'apparaît pas, clique sur "Other..." et sélectionne `Moments/Config/Release.xcconfig`

### Étape 3 : Vérifier la configuration

1. Onglet "Build Settings" du projet
2. Dans la barre de recherche, tape **"SUPABASE"**
3. Tu devrais voir apparaître :
   ```
   SUPABASE_URL = https://ksbsvscfplmokacngouo.supabase.co
   SUPABASE_ANON_KEY = eyJhbGci...
   ```
4. Si tu ne vois rien, vérifie que :
   - Les fichiers `.xcconfig` sont bien dans le projet
   - Les configurations sont bien assignées dans l'onglet Info
   - Tu as bien sauvegardé les fichiers `.xcconfig`

### Étape 4 : Clean et rebuild

1. Menu **Product** > **Clean Build Folder** (⇧⌘K)
2. Menu **Product** > **Build** (⌘B)
3. Si la compilation réussit ✅, la configuration est correcte !

### Étape 5 : Tester l'app

1. Lance l'app sur le simulateur ou ton iPhone
2. Vérifie les logs dans la console Xcode
3. Tu devrais voir :
   ```
   🟢 SupabaseManager initialisé
   ```
4. Si tu vois une erreur "SUPABASE_URL manquante", retourne à l'Étape 2

## 🔍 Débogage

### Problème : "SUPABASE_URL manquante dans Info.plist"

**Solution 1** : Vérifier que les `.xcconfig` sont assignés
- Project > Info > Configurations
- Debug doit pointer vers Debug.xcconfig
- Release doit pointer vers Release.xcconfig

**Solution 2** : Vérifier le contenu des `.xcconfig`
```bash
cat Moments/Config/Debug.xcconfig
```
Doit contenir :
```
SUPABASE_URL = https://ksbsvscfplmokacngouo.supabase.co
SUPABASE_ANON_KEY = eyJhbGci...
```

**Solution 3** : Vérifier Info.plist
```bash
cat Moments/Info.plist | grep SUPABASE
```
Doit contenir :
```xml
<key>SUPABASE_URL</key>
<string>$(SUPABASE_URL)</string>
<key>SUPABASE_ANON_KEY</key>
<string>$(SUPABASE_ANON_KEY)</string>
```

**Solution 4** : Clean le DerivedData
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/Moments-*
```
Puis rebuild le projet

### Problème : Les fichiers .xcconfig n'apparaissent pas dans Xcode

**Solution** : Ajoute-les manuellement
1. Dans Xcode, Project Navigator (⌘1)
2. Fais glisser `Debug.xcconfig` et `Release.xcconfig` depuis le Finder
3. Décoche "Copy items if needed"
4. Ajoute-les au projet

## ✅ Checklist de validation

- [ ] Les fichiers `.xcconfig` sont dans le projet Xcode
- [ ] Les configurations Debug et Release pointent vers les bons `.xcconfig`
- [ ] `Info.plist` contient `$(SUPABASE_URL)` et `$(SUPABASE_ANON_KEY)`
- [ ] `SupabaseConfig.swift` lit depuis `Bundle.main.object(forInfoDictionaryKey:)`
- [ ] Le projet compile sans erreur
- [ ] L'app se lance et affiche "🟢 SupabaseManager initialisé"
- [ ] `.gitignore` ignore `Moments/Config/Debug.xcconfig` et `Release.xcconfig`

## 🎓 Ce que tu dois retenir

### Pourquoi cette approche ?

1. **Sécurité** : Les clés ne sont JAMAIS committées sur Git
2. **Flexibilité** : Chaque développeur peut avoir ses propres clés
3. **Environnements multiples** : Dev et Prod peuvent avoir des clés différentes
4. **Standard iOS** : Les fichiers `.xcconfig` sont une pratique recommandée par Apple

### Comment ça marche ?

```
┌─────────────────────────────────────────────────┐
│ Debug.xcconfig                                  │
│ SUPABASE_URL = https://xxx.supabase.co          │
│ SUPABASE_ANON_KEY = eyJhbGci...                 │
└──────────────┬──────────────────────────────────┘
               │ (Xcode Build Settings)
               ↓
┌─────────────────────────────────────────────────┐
│ Info.plist                                      │
│ <key>SUPABASE_URL</key>                         │
│ <string>$(SUPABASE_URL)</string>                │
└──────────────┬──────────────────────────────────┘
               │ (Runtime - Bundle.main)
               ↓
┌─────────────────────────────────────────────────┐
│ SupabaseConfig.swift                            │
│ Bundle.main.object(forInfoDictionaryKey:)       │
└──────────────┬──────────────────────────────────┘
               │ (Usage)
               ↓
┌─────────────────────────────────────────────────┐
│ SupabaseManager.swift                           │
│ SupabaseClient(url: config.url, key: config.key)│
└─────────────────────────────────────────────────┘
```

## 📚 Ressources

- [Xcode Build Configuration Files - NSHipster](https://nshipster.com/xcconfig/)
- [Managing API Keys in iOS - Ray Wenderlich](https://www.raywenderlich.com/10479993-managing-api-keys-in-ios)
- [Supabase Security Best Practices](https://supabase.com/docs/guides/platform/going-into-prod)

---

**Date de création** : 12 Décembre 2025
**Statut** : Guide de configuration ✅
**Prochaine étape** : Suivre les étapes ci-dessus dans Xcode
