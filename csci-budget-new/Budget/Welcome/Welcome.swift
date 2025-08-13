//
//  Welcome.swift
//  Budget
//
//  Created by Arthur Guiot on 10/30/24.
//

import SwiftUI

// This view constructs the front welcome page of the app. It has a welcome message and a place to sign in to your account.
struct Welcome: View {
    @StateObject private var authStore = AuthStore.shared
    
    var body: some View {
        ZStack(alignment: .leading) {
            
            VStack(alignment: .center, spacing: 12) {
                Spacer()
                    .frame(height: 100)
                Text("Welcome to")
                    .fontWeight(.bold)
                    .foregroundColor(.mint)
                    .font(.custom("Snell Roundhand", size: 36))
                
                Text("The Budget App")
                    .font(.system(size: 36, weight: .bold))
                
                
                Spacer()
                
                VStack(alignment: .center) {
                    SignInWithApple()
                }
                .frame(height: 54)
            }
            .padding(EdgeInsets(top: 16, leading: 32, bottom: 0, trailing: 32))
        }
        .sheet(isPresented: $authStore.isAuthenticated) {
            ConnectBank()
//                .interactiveDismissDisabled(true)
        }
    }
}

#Preview {
    Welcome()
}
