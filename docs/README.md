# Documentation légale - Moments

Ce dossier contient les documents légaux obligatoires pour la publication sur l'App Store.

## 📄 Documents

- **[privacy-policy.md](privacy-policy.md)** - Politique de confidentialité (Privacy Policy)
- **[terms-of-service.md](terms-of-service.md)** - Conditions d'utilisation (Terms of Service)

## 🌐 Hébergement web

Ces documents **DOIVENT** être accessibles via une URL publique pour être référencés dans l'App Store Connect.

### Option 1 : GitHub Pages (GRATUIT ✅ RECOMMANDÉ)

**Étapes** :

1. **Pousse ce dossier sur GitHub** :
   ```bash
   git add docs/
   git commit -m "docs: Add Privacy Policy and Terms of Service"
   git push origin main
   ```

2. **Active GitHub Pages** :
   - Va sur https://github.com/TON_USERNAME/Moments
   - Clique sur **Settings**
   - Dans le menu de gauche, clique sur **Pages**
   - Sous "Source", sélectionne **main branch** et **/docs** folder
   - Clique sur **Save**

3. **Attends quelques minutes** (GitHub génère le site)

4. **Tes URLs seront** :
   ```
   https://TON_USERNAME.github.io/Moments/privacy-policy
   https://TON_USERNAME.github.io/Moments/terms-of-service
   ```

5. **Mets à jour SettingsView.swift** avec ces URLs réelles

### Option 2 : Hébergement sur ton propre site web

Si tu as un site web (par exemple `moments-app.com`), héberge ces fichiers à :
```
https://moments-app.com/privacy-policy.html
https://moments-app.com/terms-of-service.html
```

### Option 3 : Services gratuits

Tu peux aussi utiliser :
- **Notion** (créer une page publique)
- **Google Sites** (gratuit, facile)
- **Vercel** (gratuit pour les projets perso)

## 🔗 Intégration dans l'app

Les liens sont déjà ajoutés dans **SettingsView.swift** :

```swift
Section("Informations légales") {
    Link(destination: URL(string: "https://TON_USERNAME.github.io/Moments/privacy-policy")!) {
        Text("Politique de confidentialité")
    }

    Link(destination: URL(string: "https://TON_USERNAME.github.io/Moments/terms-of-service")!) {
        Text("Conditions d'utilisation")
    }
}
```

⚠️ **N'oublie pas de remplacer `TON_USERNAME` par ton vrai nom d'utilisateur GitHub !**

## 📱 App Store Connect

Lors de la soumission sur l'App Store, tu devras fournir ces URLs :

1. **App Privacy** (Confidentialité de l'app)
   - Privacy Policy URL: `https://TON_USERNAME.github.io/Moments/privacy-policy`

2. **App Information** (Informations sur l'app)
   - Terms of Use (EULA): `https://TON_USERNAME.github.io/Moments/terms-of-service`

## ✏️ Personnalisation

### Informations à modifier

Avant de publier, **personnalise ces documents** avec :

1. **Ton nom** : Remplace "Teddy Dubois" par ton vrai nom
2. **Ton email** : Remplace "teddydubois45@gmail.com" par ton email de contact
3. **Ton adresse** (optionnel) : Ajoute ton adresse si tu es une entreprise
4. **Tes intégrations** : Ajoute/retire les services tiers que tu utilises

### Éléments à vérifier

- [ ] Nom du développeur correct
- [ ] Email de contact correct
- [ ] Liste des données collectées à jour
- [ ] Services tiers listés (Google, Apple, Supabase)
- [ ] Droits des utilisateurs (RGPD, CCPA) inclus
- [ ] Fonctionnalité de suppression de compte mentionnée

## 🔄 Mises à jour

Si tu modifies ces documents :

1. **Mets à jour la date** "Dernière mise à jour" en haut du document
2. **Incrémente la version** (ex: 1.0 → 1.1)
3. **Commit et push** sur GitHub
4. **Notifie les utilisateurs** via une alerte in-app (recommandé pour changements majeurs)

```bash
git add docs/
git commit -m "docs: Update Privacy Policy (version 1.1)"
git push origin main
```

GitHub Pages se mettra automatiquement à jour en quelques minutes.

## ⚖️ Conformité légale

Ces documents sont conformes à :

- ✅ **RGPD** (Règlement Général sur la Protection des Données) - Union Européenne
- ✅ **CCPA** (California Consumer Privacy Act) - États-Unis
- ✅ **App Store Review Guidelines** - Apple
- ✅ **Loi Informatique et Libertés** - France

### Conseils juridiques

⚠️ **Disclaimer** : Ces documents sont des templates génériques.

Pour une protection juridique maximale :
- Consulte un avocat spécialisé en droit numérique
- Adapte les documents à ta situation spécifique
- Vérifie la conformité avec les lois de ton pays

## 📧 Contact

Si un utilisateur a une question légale :
- **Email** : teddydubois45@gmail.com (à modifier avec ton email)
- **Réponse** : Maximum 30 jours (obligation RGPD)

## 🔗 Ressources

- [RGPD - CNIL](https://www.cnil.fr/fr/reglement-europeen-protection-donnees)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Privacy Policy Generator](https://www.privacypolicygenerator.info/)
- [Terms Generator](https://www.termsfeed.com/terms-conditions-generator/)

---

**Créé le** : 12 Décembre 2025
**Langue** : Français
**Statut** : Prêt pour publication ✅
