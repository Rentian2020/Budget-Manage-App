//
//  BankAccountsDataDelegate.swift
//  Budget
//
//  Created by Arthur Guiot on 11/13/24.
//

import Gravity

@MainActor
final class BankAccountsDataDelegate: @preconcurrency RemoteObjectDelegate {
    
    typealias Element = BankAccount // Tells the RemoteObjectDelegate which type of object it is working with
    
    var store = try! Store<BankAccountsDataDelegate>(reference: "transactions") // Defines the store where the data will be stored and cached
    
    func pull(request: RemoteRequest<BankAccount.ID>) async throws -> [BankAccount] {
        // Fetches the data from the database
        let req = supabase
            .from("bank_accounts")
            .select()
            .eq("user", value: AuthStore.shared.user?.id)
        
        if request.isAll {
            let banks: [BankAccount] = try await req
                .execute()
                .value
            
            return banks
        }
        
        let banks: [BankAccount] = try await req
            .in("accountId", values: request.ids)
            .execute()
            .value
        
        return banks
    }
    
    func pop(elements: [BankAccount]) async throws {
        // Delete transactions
        try await supabase.from("transactions")
            .delete()
            .in("account_id", values: elements.map(\.id))
            .execute()
        // Delete account
        try await supabase.from("bank_accounts")
            .delete()
            .in("accountId", values: elements.map(\.id))
            .execute()
    }
    
    static var shared = BankAccountsDataDelegate() // Defines the shared instance of the controller
}
