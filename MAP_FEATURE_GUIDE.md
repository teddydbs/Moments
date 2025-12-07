# 🗺️ Guide de la Fonctionnalité Carte Interactive

## 📱 Fonctionnalité ajoutée

L'application **Moments** intègre maintenant **MapKit** pour afficher des cartes interactives lors de la création et consultation d'événements.

## ✨ Ce qui a été ajouté

### 1️⃣ Lors de la création/modification d'un événement

**Fichier modifié** : [AddEditMyEventView.swift](Moments/Views/AddEditMyEventView.swift)

Quand tu crées un événement :
1. Tu entres le **nom du lieu** (ex: "Chez moi", "Restaurant Le Bouquet")
2. Tu entres l'**adresse complète** (ex: "12 rue de la Joie, 75001 Paris")
3. 🪄 **Magie** : L'app géocode automatiquement l'adresse
4. Une **carte interactive** apparaît sous l'adresse avec un marqueur

**Technologie** :
- `CLGeocoder` : Convertit l'adresse en coordonnées GPS (latitude/longitude)
- `Map` (SwiftUI) : Affiche la carte Apple Maps
- `Marker` : Place un point sur la carte avec le nom du lieu

### 2️⃣ Lors de la consultation d'un événement

**Fichier modifié** : [MyEventDetailView.swift](Moments/Views/MyEventDetailView.swift)

Quand tu ouvres un événement avec un lieu :
1. Le nom du lieu s'affiche avec une icône 📍
2. L'adresse s'affiche en dessous
3. Une **carte interactive** s'affiche automatiquement
4. Tu peux zoomer, déplacer la carte, et l'ouvrir dans Apple Maps

## 🔧 Comment ça marche techniquement ?

### Architecture

```
Utilisateur entre une adresse
    ↓
CLGeocoder (API d'Apple)
    ↓
Récupération des coordonnées GPS
    ↓
Mise à jour de locationCoordinate
    ↓
Affichage de la carte Map + Marker
```

### Code clé

#### 1. Import de MapKit
```swift
import MapKit
```

#### 2. Variables d'état
```swift
@State private var mapPosition: MapCameraPosition = .automatic
@State private var locationCoordinate: CLLocationCoordinate2D?
@State private var isGeocodingAddress: Bool = false
```

#### 3. Fonction de géocodage
```swift
/// Géocode une adresse pour obtenir les coordonnées GPS
private func geocodeAddress(_ address: String) async {
    isGeocodingAddress = true
    let geocoder = CLGeocoder()

    do {
        let placemarks = try await geocoder.geocodeAddressString(address)

        if let coordinate = placemarks.first?.location?.coordinate {
            await MainActor.run {
                locationCoordinate = coordinate
                mapPosition = .region(MKCoordinateRegion(
                    center: coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                ))
            }
        }
    } catch {
        print("❌ Erreur de géocodage: \(error.localizedDescription)")
        locationCoordinate = nil
    }

    await MainActor.run {
        isGeocodingAddress = false
    }
}
```

#### 4. Affichage de la carte
```swift
if let coordinate = locationCoordinate {
    Map(position: $mapPosition) {
        Marker(location.isEmpty ? "Lieu" : location, coordinate: coordinate)
    }
    .frame(height: 200)
    .cornerRadius(12)
}
```

## 🎯 Cas d'usage

### Exemple 1 : Créer un événement anniversaire
1. Type : "Mon anniversaire"
2. Titre : "Mes 30 ans 🎉"
3. Date : 15 juin 2025
4. **Lieu** : Chez moi
5. **Adresse** : 12 rue de la Joie, 75001 Paris
6. → Une carte s'affiche automatiquement avec un marqueur à Paris

### Exemple 2 : Mariage
1. Type : "Mon mariage"
2. Titre : "Mariage de Teddy & Marie"
3. Date : 20 août 2025
4. **Lieu** : Château de Versailles
5. **Adresse** : Place d'Armes, 78000 Versailles
6. → La carte affiche le Château de Versailles

## 💡 Avantages

### Pour l'utilisateur
- ✅ **Visuel** : Voir immédiatement où se trouve le lieu
- ✅ **Interactif** : Zoomer, déplacer la carte
- ✅ **Automatique** : Pas besoin de chercher manuellement
- ✅ **Précis** : Utilise l'API officielle d'Apple Maps
- ✅ **Intégré** : Ouvre directement dans Apple Maps si besoin

### Pour les invités
- ✅ **Clarté** : Pas de doute sur le lieu
- ✅ **Navigation** : Clic direct pour ouvrir dans Maps
- ✅ **Contexte** : Voir le quartier, les alentours

## ⚙️ Optimisations appliquées

### 1. Géocodage intelligent
- Le géocodage se fait **à la volée** quand tu tapes l'adresse
- Un indicateur de chargement (`ProgressView`) s'affiche pendant le géocodage
- Si l'adresse est vide, la carte ne s'affiche pas

### 2. Gestion d'erreurs
- Si l'adresse n'est **pas trouvée**, aucune alerte n'est affichée (pour ne pas déranger)
- La carte n'apparaît simplement pas
- L'utilisateur peut quand même sauvegarder l'événement

### 3. Performance
- Utilisation de `async/await` pour ne pas bloquer l'interface
- `@MainActor` pour garantir les mises à jour UI sur le bon thread
- Zoom automatique sur la position (0.01° de latitude/longitude = ~1km)

### 4. UX soignée
- **Carte ronde** avec `cornerRadius(12)`
- **Hauteur fixe** de 200 points pour une bonne visibilité
- **Interaction activée** avec `allowsHitTesting(true)` (dans MyEventDetailView)
- **Marqueur personnalisé** avec le nom du lieu

## 🧪 Comment tester

### Test 1 : Créer un événement avec lieu
1. Ouvre l'app → Onglet **Événements**
2. Clique sur **+** pour créer un événement
3. Entre les informations de base
4. Section "Lieu (optionnel)" :
   - Entre "Restaurant Le Bouquet"
   - Entre "15 rue de Rivoli, 75001 Paris"
5. → Une carte devrait apparaître automatiquement

### Test 2 : Modifier un événement existant
1. Ouvre un événement existant
2. Clique sur **Modifier**
3. Modifie l'adresse
4. → La carte se met à jour automatiquement

### Test 3 : Consulter un événement avec lieu
1. Ouvre un événement qui a une adresse
2. Scrolle jusqu'à la section "Lieu"
3. → La carte s'affiche avec le marqueur

## 🚀 Prochaines améliorations possibles

### Court terme
- [ ] Ajouter un bouton "Ouvrir dans Maps" pour navigation GPS
- [ ] Ajouter un bouton "Copier l'adresse"
- [ ] Permettre de placer manuellement le marqueur sur la carte

### Moyen terme
- [ ] Afficher la distance entre ma position et le lieu
- [ ] Calculer le temps de trajet estimé
- [ ] Proposer les transports en commun à proximité

### Long terme
- [ ] Partager la localisation via lien
- [ ] Notifications de départ basées sur le trajet
- [ ] Vue 3D du lieu (si disponible)

## 📚 Concepts SwiftUI/Swift utilisés

### MapKit
- `Map` : Composant SwiftUI pour afficher une carte
- `Marker` : Épingle sur la carte
- `MapCameraPosition` : Position et zoom de la caméra
- `MKCoordinateRegion` : Région géographique à afficher

### CoreLocation
- `CLGeocoder` : Service de géocodage d'Apple
- `CLLocationCoordinate2D` : Structure représentant latitude/longitude
- `CLPlacemark` : Résultat du géocodage (adresse → coordonnées)

### SwiftUI
- `@State` : État local de la vue
- `.task { }` : Tâche asynchrone au chargement de la vue
- `.onChange(of:)` : Réagir aux changements de valeur
- `async/await` : Programmation asynchrone moderne

### Bonnes pratiques
- ✅ **Séparation des responsabilités** : La fonction `geocodeAddress` est isolée
- ✅ **Gestion d'erreurs** : Try/catch avec messages de log
- ✅ **Thread safety** : `@MainActor.run` pour les mises à jour UI
- ✅ **UX** : Indicateur de chargement pendant le géocodage
- ✅ **Optionnalité** : Le lieu reste optionnel, pas obligatoire

## 🎓 Apprentissages clés

### 1. MapKit dans SwiftUI
MapKit s'intègre nativement dans SwiftUI depuis iOS 17. Plus besoin de `UIViewRepresentable` !

### 2. Géocodage
Le géocodage convertit une adresse textuelle en coordonnées GPS. C'est gratuit avec l'API d'Apple (limitée à quelques requêtes par minute).

### 3. Async/await
Les appels réseau (géocodage) sont asynchrones. On utilise `async/await` pour ne pas bloquer l'interface.

### 4. State Management
Quand `locationCoordinate` change, SwiftUI redessine automatiquement la carte.

---

**Version** : 1.0.0
**Dernière mise à jour** : 07 Décembre 2025
**Framework** : MapKit (iOS 17+)
**API** : CLGeocoder (Apple)
