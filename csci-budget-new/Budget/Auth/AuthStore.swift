//
//  AuthStore.swift
//  Budget
//
//  Created by Arthur Guiot on 10/30/24.
//

import SwiftUI
import Supabase

class AuthStore: ObservableObject {
    static let shared = AuthStore()
    
    // Create a Profile model
    struct Profile: Codable {
        let id: UUID
        var username: String
        var fullName: String?
        // Add other profile fields as needed
    }
    
    @Published var isAuthenticated = false
    @Published var user: User?
    @Published var profile: Profile?
    @Published var account_setup = false
    
    // Cache keys
    private let accountSetupKey = "cached_account_setup"
    private let lastFetchTimeKey = "last_fetch_time"
    private let cacheExpirationInterval: TimeInterval = 5 * 60 // 5 minutes
    
    private init() {
        // Load cached values immediately
        loadFromCache()
        
        // Check if user is already authenticated
        if let session = supabase.auth.currentSession {
            isAuthenticated = true
            user = session.user
            Task {
                await fetchProfile(useCache: true)
            }
        }
        
        // Setup auth state change listener
        Task {
            for await update in supabase.auth.authStateChanges {
                switch update.event {
                case .signedIn:
                    await MainActor.run {
                        self.isAuthenticated = true
                        self.user = update.session?.user
                    }
                    await fetchProfile(useCache: false)
                case .signedOut:
                    await MainActor.run {
                        self.isAuthenticated = false
                        self.user = nil
                        self.profile = nil
                        self.clearCache()
                    }
                default:
                    break
                }
            }
        }
    }
    
    private func loadFromCache() {
        if let cachedSetup = UserDefaults.standard.bool(forKey: accountSetupKey) as Bool? {
            self.account_setup = cachedSetup
        }
    }
    
    private func saveToCache() {
        UserDefaults.standard.set(account_setup, forKey: accountSetupKey)
        UserDefaults.standard.set(Date(), forKey: lastFetchTimeKey)
    }
    
    private func clearCache() {
        UserDefaults.standard.removeObject(forKey: accountSetupKey)
        UserDefaults.standard.removeObject(forKey: lastFetchTimeKey)
    }
    
    private func isCacheValid() -> Bool {
        guard let lastFetchTime = UserDefaults.standard.object(forKey: lastFetchTimeKey) as? Date else {
            return false
        }
        return Date().timeIntervalSince(lastFetchTime) < cacheExpirationInterval
    }
    
    @MainActor
    func fetchProfile(useCache: Bool = true) async {
        guard let userId = user?.id else { return }
        
        // Return cached data if it's still valid and useCache is true
        if useCache && isCacheValid() {
            return
        }
        
        do {
            let account_setup = try await supabase
                .from("bank_accounts")
                .select(count: .estimated)
                .eq("user", value: userId.uuidString.lowercased())
                .execute()
            
            let newAccountSetup = account_setup.count ?? 0 > 0
            
            await MainActor.run {
                self.account_setup = newAccountSetup
                self.saveToCache()
            }
        } catch {
            print("Error fetching profile: \(error)")
            // If there's an error and we're using cache, keep the cached values
            if !useCache {
                // Only clear the state if this wasn't a cache-first request
                await MainActor.run {
                    self.account_setup = false
                }
            }
        }
    }
    
    func signOut() async throws {
        try await supabase.auth.signOut()
        await MainActor.run {
            clearCache()
            isAuthenticated = false
            user = nil
            profile = nil
            account_setup = false
        }
    }
    
    // Force refresh method
    func refreshProfile() async {
        await fetchProfile(useCache: false)
    }
}
