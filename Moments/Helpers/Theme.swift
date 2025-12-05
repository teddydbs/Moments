//
//  Theme.swift
//  Moments
//
//  Thème visuel cohérent avec le logo de l'application
//

import SwiftUI

/// Thème principal de l'application Moments
/// Basé sur le dégradé violet/rose du logo
struct MomentsTheme {

    // MARK: - Couleurs principales (du logo)

    /// Violet principal (côté gauche du cœur)
    static let primaryPurple = Color(red: 0.67, green: 0.51, blue: 0.95) // #AB82F2

    /// Rose principal (côté droit du cœur)
    static let primaryPink = Color(red: 0.98, green: 0.67, blue: 0.95) // #FAABF2

    /// Fond sombre du logo
    static let darkBackground = Color(red: 0.24, green: 0.25, blue: 0.32) // #3D4051

    // MARK: - Dégradés

    /// Dégradé principal du logo (violet → rose)
    static let primaryGradient = LinearGradient(
        colors: [primaryPurple, primaryPink],
        startPoint: .leading,
        endPoint: .trailing
    )

    /// Dégradé vertical (pour backgrounds)
    static let verticalGradient = LinearGradient(
        colors: [primaryPurple, primaryPink],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Dégradé diagonal (pour effets)
    static let diagonalGradient = LinearGradient(
        colors: [primaryPurple, primaryPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Dégradé subtil pour les cards
    static let cardGradient = LinearGradient(
        colors: [
            primaryPurple.opacity(0.1),
            primaryPink.opacity(0.1)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    // MARK: - Couleurs sémantiques

    /// Couleur d'accent (utilisée par SwiftUI)
    static let accent = primaryPurple

    /// Couleur pour les anniversaires
    static let birthday = primaryPink

    /// Couleur pour les événements généraux
    static let event = primaryPurple

    // MARK: - Modificateurs de vue

    /// Style pour les cartes d'événements
    struct CardStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(cardGradient)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(primaryGradient, lineWidth: 1)
                )
        }
    }

    /// Style pour les boutons principaux
    struct PrimaryButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(primaryGradient)
                .cornerRadius(12)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
        }
    }

    /// Style pour les icônes avec gradient
    struct GradientIconStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .foregroundStyle(primaryGradient)
        }
    }
}

// MARK: - Extensions pour faciliter l'utilisation

extension View {
    /// Applique le style de carte Moments
    func momentsCardStyle() -> some View {
        modifier(MomentsTheme.CardStyle())
    }

    /// Applique le gradient aux icônes
    func gradientIcon() -> some View {
        modifier(MomentsTheme.GradientIconStyle())
    }
}

// MARK: - Prévisualisation du thème

#Preview("Couleurs du thème") {
    VStack(spacing: 20) {
        // Dégradé principal
        RoundedRectangle(cornerRadius: 16)
            .fill(MomentsTheme.primaryGradient)
            .frame(height: 100)
            .overlay {
                Text("Dégradé principal")
                    .font(.headline)
                    .foregroundColor(.white)
            }

        // Couleurs individuelles
        HStack(spacing: 16) {
            VStack {
                Circle()
                    .fill(MomentsTheme.primaryPurple)
                    .frame(width: 80, height: 80)
                Text("Violet")
                    .font(.caption)
            }

            VStack {
                Circle()
                    .fill(MomentsTheme.primaryPink)
                    .frame(width: 80, height: 80)
                Text("Rose")
                    .font(.caption)
            }
        }

        // Exemple de carte
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "gift.fill")
                    .gradientIcon()
                Text("Exemple de carte")
                    .font(.headline)
            }
            Text("Avec le style Moments")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .momentsCardStyle()

        // Bouton
        Button("Bouton principal") {}
            .buttonStyle(MomentsTheme.PrimaryButtonStyle())
    }
    .padding()
}
