# 🎨 Design System - Moments

Ce document décrit le système de design de l'application Moments, basé sur le logo violet/rose.

## 📱 Logo et Identité

Le logo Moments représente un **cœur avec une épingle de localisation**, symbolisant les moments importants et les personnes qui les entourent. Le dégradé violet → rose crée une ambiance chaleureuse et moderne.

### Fichiers du logo
- **AppIcon** : `/Moments/Assets.xcassets/AppIcon.appiconset/logo-Moments.jpg`
- Résolution : 1024x1024px
- Format : JPG avec fond sombre

## 🎨 Palette de Couleurs

### Couleurs Principales

```swift
// Violet principal (côté gauche du cœur)
MomentsTheme.primaryPurple
RGB: (171, 130, 242) / #AB82F2
Hex: 0.67, 0.51, 0.95

// Rose principal (côté droit du cœur)
MomentsTheme.primaryPink
RGB: (250, 171, 242) / #FAABF2
Hex: 0.98, 0.67, 0.95

// Fond sombre du logo
MomentsTheme.darkBackground
RGB: (61, 64, 81) / #3D4051
Hex: 0.24, 0.25, 0.32
```

### Dégradés Disponibles

```swift
// Dégradé horizontal (principal)
MomentsTheme.primaryGradient
Violet → Rose (gauche → droite)

// Dégradé vertical
MomentsTheme.verticalGradient
Violet → Rose (haut → bas)

// Dégradé diagonal
MomentsTheme.diagonalGradient
Violet → Rose (haut-gauche → bas-droite)

// Dégradé subtil pour cartes
MomentsTheme.cardGradient
Violet transparent → Rose transparent
```

## 🎯 Utilisation dans l'App

### 1. Icônes avec Gradient

```swift
Image(systemName: "gift.fill")
    .gradientIcon()  // Applique le dégradé violet/rose
```

**Où c'est utilisé :**
- Boutons "+" dans la toolbar
- Icônes dans les empty states
- Icônes de notifications (cloche)
- Icônes dans les paramètres

### 2. Boutons Principaux

```swift
Button("Action") { }
    .buttonStyle(MomentsTheme.PrimaryButtonStyle())
```

**Style appliqué :**
- Background : Dégradé violet/rose
- Texte : Blanc
- Police : Headline (semibold)
- Animation : Scale au tap (0.95)
- Coins arrondis : 12pt

**Où c'est utilisé :**
- "Ajouter un anniversaire" (empty state)
- "Créer un événement" (empty state)
- Boutons de sauvegarde dans les formulaires

### 3. Couleurs de Catégories

```swift
// Anniversaires
EventCategory.birthday → MomentsTheme.primaryPink

// Événements (mariages, EVG/EVJF, etc.)
EventCategory.* → MomentsTheme.primaryPurple
```

### 4. Accent Color Globale

L'AccentColor de l'app est configurée sur le violet principal :
- Fichier : `/Assets.xcassets/AccentColor.colorset/`
- Valeur : `#AB82F2` (primaryPurple)
- Utilisée automatiquement par SwiftUI pour les toggles, pickers, etc.

### 5. Tab Bar

```swift
TabView { }
    .tint(MomentsTheme.primaryPurple)
```

Les icônes sélectionnées dans la TabBar utilisent le violet principal.

## 📐 Composants Stylisés

### Cartes d'Événements

```swift
VStack { }
    .momentsCardStyle()
```

**Style appliqué :**
- Background : Dégradé subtil transparent
- Bordure : Dégradé violet/rose (1pt)
- Coins arrondis : 16pt

### Compteurs de Jours

Les compteurs "Dans X jours" utilisent :
- Couleur normale : `MomentsTheme.primaryPurple`
- Aujourd'hui : Vert
- Demain : Orange
- Passé : Gris

### Images et Avatars

Les cercles d'avatar/images ont une bordure avec :
- Couleur : `categoryColor.opacity(0.5)`
- Pour birthdays : Rose transparent
- Pour events : Violet transparent

## 🌗 Dark Mode

Les couleurs sont identiques en Light et Dark Mode pour maintenir l'identité forte du logo.

Le dégradé violet/rose fonctionne bien sur :
- Fond clair (blanc iOS)
- Fond sombre (noir iOS)

## ✨ Animations

### Boutons
- Transition : `easeInOut(duration: 0.2)`
- Scale : 0.95 au tap

### Gradients
Les gradients sont statiques (pas d'animation) pour maintenir les performances.

## 📱 Icônes SF Symbols

### Icônes Principales (avec gradient)
- `gift.fill` - Anniversaires
- `calendar` - Événements
- `plus.circle.fill` - Ajouter
- `bell.fill` - Notifications
- `gearshape.fill` - Paramètres
- `square.and.arrow.up` - Export

### Icônes Secondaires (couleur système)
- `trash` - Supprimer (rouge destructif)
- `pencil` - Modifier (bleu système)
- `person.2.fill` - Participants
- `lightbulb.fill` - Idées cadeaux

## 🎨 Fichier Theme.swift

Le fichier central du design system :
```
/Moments/Helpers/Theme.swift
```

**Contient :**
- Définitions de toutes les couleurs
- Tous les dégradés
- ViewModifiers personnalisés
- ButtonStyles
- Extensions View pour faciliter l'usage
- Previews du thème

## 📋 Checklist d'Utilisation

Quand tu ajoutes une nouvelle vue, assure-toi de :

- [ ] Utiliser `.gradientIcon()` sur les icônes importantes
- [ ] Utiliser `MomentsTheme.PrimaryButtonStyle()` pour les boutons d'action
- [ ] Utiliser `MomentsTheme.primaryPink` pour les éléments liés aux anniversaires
- [ ] Utiliser `MomentsTheme.primaryPurple` pour les éléments liés aux événements
- [ ] Utiliser `.momentsCardStyle()` pour les cartes personnalisées
- [ ] Tester en Light et Dark Mode

## 🔄 Évolutions Futures

### Phase 1 (Actuel)
✅ Logo installé
✅ Palette de couleurs définie
✅ Dégradés appliqués aux vues principales
✅ ButtonStyle personnalisé
✅ Icônes avec gradient

### Phase 2 (À venir)
- [ ] Animations de gradient sur certains éléments
- [ ] Mode "celebration" avec confettis lors des anniversaires
- [ ] Haptic feedback coordonné avec le thème
- [ ] Widgets iOS avec le design system

### Phase 3 (Plus tard)
- [ ] Thèmes alternatifs (garde le violet/rose par défaut)
- [ ] Mode "high contrast" pour accessibilité
- [ ] Animation du logo au lancement

## 💡 Conseils de Design

1. **Cohérence** : Toujours utiliser le thème plutôt que des couleurs hardcodées
2. **Contraste** : Le dégradé est lisible sur fond clair ET sombre
3. **Accessibilité** : Les textes sur gradient utilisent toujours du blanc pour le contraste
4. **Performance** : Les gradients sont légers, pas d'impact sur les performances
5. **Évolutivité** : Modifier `Theme.swift` propage les changements partout

## 📚 Références

- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- Palette générée depuis le logo : `/Assets.xcassets/AppIcon.appiconset/logo-Moments.jpg`

---

**Dernière mise à jour** : 5 décembre 2025
**Version** : 1.0.0
**Maintenu par** : Teddy Dubois
