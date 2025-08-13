//
//  ConnectBank.swift
//  Budget
//
//  Created by Arthur Guiot on 10/30/24.
//


import LinkKit
import SwiftUI
import Functions
import Combine

class LinkControllerManager: ObservableObject {
    @Published var linkController: LinkController?
    
    static let shared = LinkControllerManager()
}

// This view works to let the user connect their bank account
struct ConnectBank: View {
    
    @State private var isPresentingLink = false
    @StateObject private var authStore = AuthStore.shared
    @StateObject private var linkControllerManager = LinkControllerManager.shared
    
//    init(isPresentingLink: Bool = false, linkController: LinkController? = nil) {
//        self.isPresentingLink = isPresentingLink
//        
//        let createResult = self.createHandler()
//        switch createResult {
//        case .failure(let createError):
//            print("Link Creation Error: \(createError.localizedDescription)")
//        case .success(let handler):
//            self.linkController = LinkController(handler: handler)
//            print("Link is defined")
//        }
//        print("Link is: \(String(describing: self.linkController))");
//    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Title
                Text("Connect your Bank")
                    .font(.system(size: 32, weight: .bold))
                    .padding(.top, 40)
                
                // Illustration Area
                HStack(spacing: 20) {
                    // Custom illustration can be added here using Image
                    // For this example, we'll use a placeholder
                    Image("connectbank")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
                
                // Warning Message
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.black)
                    
                    Text("The Budget App uses Plaid to securely connect your bank account. We do not sell or save any transaction data associated with your bank account")
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                }
                .padding(16)
                .background(Color(.systemYellow).opacity(0.3))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Spacer()
                
                // Connect Button
                Button(action: {
                    guard let _ = linkControllerManager.linkController else { return }
                    isPresentingLink = true
                }) {
                    Text("Connect Plaid")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    Task {
                        do {
                            try await authStore.signOut()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }) {
                    Text("Sign Out")
                        .foregroundColor(.blue)
                }
            )
            .navigationBarTitle("Bank Account", displayMode: .inline)
        }
        .sheet(
            isPresented: $isPresentingLink,
            onDismiss: { isPresentingLink = false },
            content: {
                if let linkController = linkControllerManager.linkController {
                    linkController
                        .ignoresSafeArea(.all)
                } else {
                    Text("Link is not initialized")
                }
            }
        )
        .task {
            do {
                try await initializeLinkController()
            } catch {
                print("Link error: \(error.localizedDescription)")
            }
        }
    }
    
    private let plaidBlue: Color = Color(
        red: 0,
        green: 191 / 256,
        blue: 250 / 256,
        opacity: 1
    )
    
    private func initializeLinkController() async throws {
        let createResult = try await self.createHandler()
        switch createResult {
        case .failure(let createError):
            print("Link Creation Error: \(createError.localizedDescription)")
        case .success(let handler):
            self.linkControllerManager.linkController = LinkController(handler: handler)
            print("Link is defined")
        }
        print("Link is: \(String(describing: self.linkControllerManager.linkController))")
    }
    
    private func versionInformation() -> some View {
        let linkKitBundle  = Bundle(for: PLKPlaid.self)
        let linkKitVersion = linkKitBundle.object(forInfoDictionaryKey: "CFBundleShortVersionString")!
        let linkKitBuild   = linkKitBundle.object(forInfoDictionaryKey: kCFBundleVersionKey as String)!
        let linkKitName    = linkKitBundle.object(forInfoDictionaryKey: kCFBundleNameKey as String)!
        let versionText = "\(linkKitName) \(linkKitVersion)+\(linkKitBuild)"
        
        return Text(versionText)
            .foregroundColor(.gray)
            .font(.system(size: 12))
    }
    
    private func createHandler() async throws -> Result<Handler, Plaid.CreateError> {
        let configuration = try await createLinkTokenConfiguration()
        
        // This only results in an error if the token is malformed.
        return Plaid.create(configuration)
    }
    
    private func createLinkTokenConfiguration() async throws -> LinkTokenConfiguration {
        // Steps to acquire a Link Token:
        //
        // 1. Sign up for a Plaid account to get an API key.
        //      Ref - https://dashboard.plaid.com/signup
        // 2. Make a request to our API using your API key.
        //      Ref - https://plaid.com/docs/quickstart/#introduction
        //      Ref - https://plaid.com/docs/api/tokens/#linktokencreate

        let linkToken = try await getPlaidToken()
        
        // In your production application replace the hardcoded linkToken above with code that fetches a linkToken
        // from your backend server which in turn retrieves it securely from Plaid, for details please refer to
        // https://plaid.com/docs/api/tokens/#linktokencreate
        
        var linkConfiguration = LinkTokenConfiguration(token: linkToken) { success in
            // Closure is called when a user successfully links an Item. It should take a single LinkSuccess argument,
            // containing the publicToken String and a metadata of type SuccessMetadata.
            // Ref - https://plaid.com/docs/link/ios/#onsuccess
            print("public-token: \(success.publicToken) metadata: \(success.metadata)")
            
            Task {
                let requestBody = [
                    "publicToken": success.publicToken
                ]
                
                do {
                    try await supabase.functions.invoke(
                        "upgrade-token",
                        options: FunctionInvokeOptions(body: requestBody)
                    ) { data, response in
                        // Print
                        
                        print(data, response)
                        Task {
                            await AuthStore.shared.refreshProfile();
                        }
                    }
                } catch {
                    print(error)
                }
            }
            
            isPresentingLink = false
        }
        
        // Optional closure is called when a user exits Link without successfully linking an Item,
        // or when an error occurs during Link initialization. It should take a single LinkExit argument,
        // containing an optional error and a metadata of type ExitMetadata.
        // Ref - https://plaid.com/docs/link/ios/#onexit
        linkConfiguration.onExit = { exit in
            if let error = exit.error {
                print("exit with \(error)\n\(exit.metadata)")
            } else {
                // User exited the flow without an error.
                print("exit with \(exit.metadata)")
            }
            isPresentingLink = false
        }
        
        // Optional closure is called when certain events in the Plaid Link flow have occurred, for example,
        // when the user selected an institution. This enables your application to gain further insight into
        // what is going on as the user goes through the Plaid Link flow.
        // Ref - https://plaid.com/docs/link/ios/#onevent
        linkConfiguration.onEvent = { event in
            print("Link Event: \(event)")
        }
        
        return linkConfiguration
    }
    
    struct TokenResponse: Codable {
        let token: String
        // Add other fields if needed
    }
    
    private func getPlaidToken() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    try await supabase.functions.invoke("plaid-token") { data, response in
                        //                    guard let data = data else {
                        //                        continuation.resume(throwing: NSError(domain: "TokenError",
                        //                                                              code: 404,
                        //                                                              userInfo: [NSLocalizedDescriptionKey: "No data received"]))
                        //                        return
                        //                    }
                        
                        do {
                            let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                            continuation.resume(returning: tokenResponse.token)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

struct ConnectBank_Previews: PreviewProvider {
    static var previews: some View {
        ConnectBank()
    }
}

#Preview {
    ConnectBank()
        .modelContainer(for: Item.self, inMemory: true)
}
