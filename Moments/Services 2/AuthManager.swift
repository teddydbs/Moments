//
//  AuthManager.swift
//  Moments
//
//  Service de gestion de l'authentification (mode test)
//

import SwiftUI
import Combine

class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: MockUser?

    // Mock user structure
    struct MockUser {
        let id: String
        let name: String
        let email: String
    }

    // Singleton
    static let shared = AuthManager()

    private init() {
        // Check if user was previously logged in (UserDefaults for test mode)
        if let email = UserDefaults.standard.string(forKey: "mockUserEmail"),
           let name = UserDefaults.standard.string(forKey: "mockUserName") {
            self.currentUser = MockUser(id: UUID().uuidString, name: name, email: email)
            self.isAuthenticated = true
        }
    }

    // Login (mock)
    func login(email: String, password: String) -> Bool {
        // Validation basique
        guard email.contains("@"), password.count >= 6 else {
            return false
        }

        // Simuler une connexion réussie
        let mockUser = MockUser(
            id: UUID().uuidString,
            name: "Utilisateur Test",
            email: email
        )

        self.currentUser = mockUser
        self.isAuthenticated = true

        // Sauvegarder dans UserDefaults pour persister la session
        UserDefaults.standard.set(email, forKey: "mockUserEmail")
        UserDefaults.standard.set(mockUser.name, forKey: "mockUserName")

        return true
    }

    // Sign up (mock)
    func signUp(name: String, email: String, password: String) -> Bool {
        // Validation basique
        guard !name.isEmpty,
              email.contains("@"),
              password.count >= 6 else {
            return false
        }

        // Simuler une inscription réussie
        let mockUser = MockUser(
            id: UUID().uuidString,
            name: name,
            email: email
        )

        self.currentUser = mockUser
        self.isAuthenticated = true

        // Sauvegarder dans UserDefaults
        UserDefaults.standard.set(email, forKey: "mockUserEmail")
        UserDefaults.standard.set(name, forKey: "mockUserName")

        return true
    }

    // Logout
    func logout() {
        self.currentUser = nil
        self.isAuthenticated = false

        // Nettoyer UserDefaults
        UserDefaults.standard.removeObject(forKey: "mockUserEmail")
        UserDefaults.standard.removeObject(forKey: "mockUserName")
    }

    // Reset password (mock)
    func resetPassword(email: String) -> Bool {
        // Simuler l'envoi d'un email de réinitialisation
        return email.contains("@")
    }
}
