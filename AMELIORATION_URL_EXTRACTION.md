# ✅ AMÉLIORATION : Extraction intelligente de titre depuis URL

## 📝 Ce qui a été fait

J'ai amélioré le système de fallback dans `WishlistManager.fetchAndUpdateMetadata()` pour extraire un titre lisible depuis l'URL quand les métadonnées ne peuvent pas être extraites.

## 🎯 Problème résolu

**Avant** :
- URL FNAC : "Produit sur www.fnac.com" ❌
- Pas d'information utile pour l'utilisateur

**Après** :
- URL FNAC : "Fabien Olicard Les Entrailles Du Temps..." ✅
- Titre extrait intelligemment depuis le slug de l'URL

## 🔧 Comment ça marche

### 1. Nouvelle fonction `extractTitleFromURL()`

Cette fonction analyse l'URL et extrait un titre en 3 étapes :

**Cas 1 : Amazon**
```
https://www.amazon.fr/dp/B08X6F1234
→ "Produit Amazon"
```

**Cas 2 : URL avec slug produit (FNAC, etc.)**
```
https://www.fnac.com/a21720092/Fabien-Olicard-Les-entrailles-du-temps
→ "Fabien Olicard Les Entrailles Du Temps"
```

La fonction :
1. Découpe l'URL en segments (séparés par `/`)
2. Trouve le segment le plus long (généralement le slug produit)
3. Ignore les segments courts comme `a21720092`
4. Remplace les tirets `-` et underscores `_` par des espaces
5. Capitalise chaque mot
6. Limite à 60 caractères max

**Cas 3 : Fallback - nom de domaine**
```
https://example.com/abc
→ "Produit sur example.com"
```

## 📊 Résultats attendus

Pour l'URL FNAC de test :
```
https://www.fnac.com/a21720092/Fabien-Olicard-Les-entrailles-du-temps-Decidez-de-votre-destin-La-Saga-de-Dagda
```

**Nouvelle version** :
- Titre : "Fabien Olicard Les Entrailles Du Temps Decidez De Votre Dest..."
- Même si les métadonnées ne sont pas extraites, l'utilisateur voit un titre pertinent !

## 📝 Fichiers modifiés

- `Moments/Services/WishlistManager.swift` :
  - Fonction `fetchAndUpdateMetadata()` améliorée
  - Nouvelle fonction `extractTitleFromURL()` ajoutée

---

✅ Compilation réussie
✅ Logique testée avec plusieurs exemples
✅ Prêt à tester dans l'app !
