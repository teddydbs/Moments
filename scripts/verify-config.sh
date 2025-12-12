#!/bin/bash

# Script de vérification de la configuration sécurisée des clés API
# Ce script vérifie que les fichiers .xcconfig existent et sont correctement configurés

set -e

echo "🔍 Vérification de la configuration sécurisée..."
echo ""

# Couleurs pour les messages
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variables
CONFIG_DIR="Moments/Config"
DEBUG_CONFIG="$CONFIG_DIR/Debug.xcconfig"
RELEASE_CONFIG="$CONFIG_DIR/Release.xcconfig"
INFO_PLIST="Moments/Info.plist"
GITIGNORE=".gitignore"

# Compteur d'erreurs
ERRORS=0

echo "1. Vérification des fichiers .xcconfig..."

if [ -f "$DEBUG_CONFIG" ]; then
    echo -e "${GREEN}✅${NC} Debug.xcconfig existe"

    # Vérifier que le fichier contient bien les variables
    if grep -q "SUPABASE_URL" "$DEBUG_CONFIG" && grep -q "SUPABASE_ANON_KEY" "$DEBUG_CONFIG"; then
        echo -e "${GREEN}✅${NC} Debug.xcconfig contient SUPABASE_URL et SUPABASE_ANON_KEY"
    else
        echo -e "${RED}❌${NC} Debug.xcconfig ne contient pas les variables requises"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${RED}❌${NC} Debug.xcconfig est manquant"
    echo -e "${YELLOW}⚠️${NC}  Copier depuis: cp $CONFIG_DIR/Debug.xcconfig.template $DEBUG_CONFIG"
    ERRORS=$((ERRORS + 1))
fi

if [ -f "$RELEASE_CONFIG" ]; then
    echo -e "${GREEN}✅${NC} Release.xcconfig existe"

    # Vérifier que le fichier contient bien les variables
    if grep -q "SUPABASE_URL" "$RELEASE_CONFIG" && grep -q "SUPABASE_ANON_KEY" "$RELEASE_CONFIG"; then
        echo -e "${GREEN}✅${NC} Release.xcconfig contient SUPABASE_URL et SUPABASE_ANON_KEY"
    else
        echo -e "${RED}❌${NC} Release.xcconfig ne contient pas les variables requises"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${RED}❌${NC} Release.xcconfig est manquant"
    echo -e "${YELLOW}⚠️${NC}  Copier depuis: cp $CONFIG_DIR/Release.xcconfig.template $RELEASE_CONFIG"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "2. Vérification de Info.plist..."

if [ -f "$INFO_PLIST" ]; then
    echo -e "${GREEN}✅${NC} Info.plist existe"

    # Vérifier que Info.plist contient les références aux variables
    if grep -q "SUPABASE_URL" "$INFO_PLIST" && grep -q "SUPABASE_ANON_KEY" "$INFO_PLIST"; then
        echo -e "${GREEN}✅${NC} Info.plist référence SUPABASE_URL et SUPABASE_ANON_KEY"

        # Vérifier qu'on utilise bien les variables $(SUPABASE_URL) et pas les valeurs en dur
        if grep -q "\$(SUPABASE_URL)" "$INFO_PLIST" && grep -q "\$(SUPABASE_ANON_KEY)" "$INFO_PLIST"; then
            echo -e "${GREEN}✅${NC} Info.plist utilise les variables d'environnement"
        else
            echo -e "${RED}❌${NC} Info.plist contient des valeurs en dur au lieu de variables"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo -e "${RED}❌${NC} Info.plist ne référence pas les variables Supabase"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${RED}❌${NC} Info.plist est manquant"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "3. Vérification de .gitignore..."

if [ -f "$GITIGNORE" ]; then
    echo -e "${GREEN}✅${NC} .gitignore existe"

    # Vérifier que .gitignore ignore bien les fichiers .xcconfig
    if grep -q "Debug.xcconfig" "$GITIGNORE" && grep -q "Release.xcconfig" "$GITIGNORE"; then
        echo -e "${GREEN}✅${NC} .gitignore ignore les fichiers .xcconfig"
    else
        echo -e "${RED}❌${NC} .gitignore n'ignore pas les fichiers .xcconfig"
        echo -e "${YELLOW}⚠️${NC}  Ajouter: Moments/Config/Debug.xcconfig et Moments/Config/Release.xcconfig"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "${RED}❌${NC} .gitignore est manquant"
    ERRORS=$((ERRORS + 1))
fi

echo ""
echo "4. Vérification que les .xcconfig ne sont pas trackés par Git..."

# Vérifier si les fichiers .xcconfig sont trackés par Git
if git ls-files --error-unmatch "$DEBUG_CONFIG" 2>/dev/null; then
    echo -e "${RED}❌${NC} Debug.xcconfig est tracké par Git (DANGEREUX!)"
    echo -e "${YELLOW}⚠️${NC}  Exécuter: git rm --cached $DEBUG_CONFIG"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✅${NC} Debug.xcconfig n'est pas tracké par Git"
fi

if git ls-files --error-unmatch "$RELEASE_CONFIG" 2>/dev/null; then
    echo -e "${RED}❌${NC} Release.xcconfig est tracké par Git (DANGEREUX!)"
    echo -e "${YELLOW}⚠️${NC}  Exécuter: git rm --cached $RELEASE_CONFIG"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✅${NC} Release.xcconfig n'est pas tracké par Git"
fi

echo ""
echo "5. Vérification que les templates existent..."

if [ -f "$CONFIG_DIR/Debug.xcconfig.template" ]; then
    echo -e "${GREEN}✅${NC} Debug.xcconfig.template existe"
else
    echo -e "${YELLOW}⚠️${NC}  Debug.xcconfig.template est manquant (pas critique)"
fi

if [ -f "$CONFIG_DIR/Release.xcconfig.template" ]; then
    echo -e "${GREEN}✅${NC} Release.xcconfig.template existe"
else
    echo -e "${YELLOW}⚠️${NC}  Release.xcconfig.template est manquant (pas critique)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ Configuration sécurisée OK !${NC}"
    echo ""
    echo "Prochaines étapes:"
    echo "1. Configurer Xcode: Voir XCODE_CONFIG_SETUP.md"
    echo "2. Clean et rebuild le projet"
    echo "3. Tester l'app"
    exit 0
else
    echo -e "${RED}❌ $ERRORS erreur(s) trouvée(s)${NC}"
    echo ""
    echo "Consulter XCODE_CONFIG_SETUP.md pour les instructions de configuration"
    exit 1
fi
