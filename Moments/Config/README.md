# Configuration sécurisée des clés API

Ce dossier contient les fichiers de configuration Xcode qui stockent de manière sécurisée les clés API Supabase.

## 🔒 Sécurité

**IMPORTANT** : Les fichiers `Debug.xcconfig` et `Release.xcconfig` contiennent vos clés secrètes Supabase et **NE DOIVENT JAMAIS** être committés sur Git.

Ils sont automatiquement ignorés par `.gitignore` :
```gitignore
Moments/Config/Debug.xcconfig
Moments/Config/Release.xcconfig
```

## 📁 Structure des fichiers

```
Config/
├── Debug.xcconfig              ❌ NE PAS COMMITTER (contient les secrets)
├── Release.xcconfig            ❌ NE PAS COMMITTER (contient les secrets)
├── Debug.xcconfig.template     ✅ À committer (template sans secrets)
├── Release.xcconfig.template   ✅ À committer (template sans secrets)
└── README.md                   ✅ À committer (ce fichier)
```

## 🚀 Configuration initiale

### 1. Copier les templates

Si les fichiers `Debug.xcconfig` et `Release.xcconfig` n'existent pas :

```bash
cd Moments/Config
cp Debug.xcconfig.template Debug.xcconfig
cp Release.xcconfig.template Release.xcconfig
```

### 2. Ajouter vos clés Supabase

Éditez `Debug.xcconfig` et remplacez les placeholders :

```xcconfig
SUPABASE_URL = https:/$()/VOTRE_PROJECT_REF.supabase.co
SUPABASE_ANON_KEY = VOTRE_ANON_KEY_ICI
```

Les clés se trouvent sur :
👉 [Supabase Dashboard](https://supabase.com/dashboard) → Settings → API

### 3. Configurer Xcode

**Importante** : Il faut configurer Xcode pour utiliser les fichiers `.xcconfig` :

1. Ouvrir `Moments.xcodeproj` dans Xcode
2. Sélectionner le projet "Moments" dans la sidebar
3. Onglet "Info"
4. Section "Configurations"
5. Pour "Debug" : Sélectionner `Debug.xcconfig`
6. Pour "Release" : Sélectionner `Release.xcconfig`

## 🔍 Comment ça marche ?

### Flux de données

```
Debug.xcconfig
    ↓ (variables d'environnement Xcode)
Info.plist
    ↓ (lecture via Bundle.main)
SupabaseConfig.swift
    ↓ (utilisation)
SupabaseManager.swift
```

### Code dans Info.plist

```xml
<key>SUPABASE_URL</key>
<string>$(SUPABASE_URL)</string>
<key>SUPABASE_ANON_KEY</key>
<string>$(SUPABASE_ANON_KEY)</string>
```

### Code dans SupabaseConfig.swift

```swift
static var supabaseURL: URL {
    guard let urlString = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
          let url = URL(string: urlString) else {
        fatalError("SUPABASE_URL manquante dans Info.plist")
    }
    return url
}
```

## ⚠️ Erreurs courantes

### Erreur : "SUPABASE_URL manquante dans Info.plist"

**Cause** : Les fichiers `.xcconfig` ne sont pas configurés dans Xcode

**Solution** :
1. Vérifier que `Debug.xcconfig` et `Release.xcconfig` existent
2. Vérifier qu'ils sont bien configurés dans Project > Info > Configurations
3. Clean le projet (Cmd+Shift+K) et rebuild

### Erreur : "fatalError() SUPABASE_URL manquante"

**Cause** : Les variables ne sont pas correctement injectées depuis `.xcconfig`

**Solution** :
1. Vérifier la syntaxe dans `.xcconfig` (pas de guillemets autour des valeurs)
2. Vérifier que les variables sont bien définies dans Info.plist avec `$(VARIABLE_NAME)`
3. Rebuild le projet

## 🌍 Environnements multiples

Tu peux avoir des projets Supabase différents pour Dev et Prod :

**Debug.xcconfig** (développement)
```xcconfig
SUPABASE_URL = https:/$()/dev-project.supabase.co
SUPABASE_ANON_KEY = dev_anon_key_here
```

**Release.xcconfig** (production)
```xcconfig
SUPABASE_URL = https:/$()/prod-project.supabase.co
SUPABASE_ANON_KEY = prod_anon_key_here
```

## 📦 Partage avec l'équipe

Quand tu partages le projet avec d'autres développeurs :

1. ✅ Committer les `.template` files
2. ✅ Committer le `.gitignore` qui ignore les `.xcconfig`
3. ✅ Committer ce README.md
4. ❌ **NE JAMAIS** committer `Debug.xcconfig` ou `Release.xcconfig`

Chaque développeur devra :
1. Copier les `.template` vers `.xcconfig`
2. Ajouter ses propres clés Supabase
3. Configurer Xcode pour utiliser les `.xcconfig`

## 🔗 Ressources

- [Xcode Build Configuration Files](https://nshipster.com/xcconfig/)
- [Supabase API Keys](https://supabase.com/docs/guides/api/api-keys)
- [iOS Security Best Practices](https://developer.apple.com/documentation/security)

---

**Date de création** : 12 Décembre 2025
**Statut** : Configuration sécurisée active ✅
