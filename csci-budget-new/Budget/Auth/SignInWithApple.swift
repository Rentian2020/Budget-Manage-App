//
//  SignInWithApple.swift
//  Budget
//
//  Created by Arthur Guiot on 10/21/24.
//

import AuthenticationServices
import SwiftUI

// This view allows an Apple sign-in.
struct SignInWithApple: View {
    @StateObject private var authStore = AuthStore.shared
    @State private var actionState = ActionState<Void, Error>.idle
    
    var body: some View {
        VStack {
            SignInWithAppleButton { request in
                request.requestedScopes = [.email]
            } onCompletion: { result in
                switch result {
                case let .failure(error):
                    debug("signInWithApple failed: \(error)")
                    
                case let .success(authorization):
                    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential
                    else {
                        debug(
                            "Invalid credential, expected \(ASAuthorizationAppleIDCredential.self) but got a \(type(of: authorization.credential))"
                        )
                        return
                    }
                    
                    guard let identityToken = credential.identityToken.flatMap({ String(
                        data: $0,
                        encoding: .utf8
                    ) }) else {
                        debug("Invalid identity token")
                        return
                    }
                    
                    Task {
                        await signInWithApple(using: identityToken)
                    }
                }
            }
            .cornerRadius(18)
            .controlSize(.extraLarge)
            
            switch actionState {
            case .idle, .result(.success), .inFlight:
                EmptyView()
            case let .result(.failure(error)):
                ErrorText(error)
            }
        }
    }
    
    private func signInWithApple(using idToken: String) async {
        actionState = .inFlight
        let result = await Result {
            _ = try await supabase.auth.signInWithIdToken(credentials: .init(
                provider: .apple,
                idToken: idToken
            ))
        }
        actionState = .result(result)
    }
}

#Preview {
    SignInWithApple()
}
