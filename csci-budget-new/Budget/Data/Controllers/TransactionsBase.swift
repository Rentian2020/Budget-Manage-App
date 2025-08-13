//
//  TransactionsBase.swift
//  Budget
//
//  Created by Arthur Guiot on 11/24/24.
//

import Gravity

@MainActor
final class TransactionsBase: @preconcurrency RemoteObjectDelegate {
    
    typealias Element = Transaction // Tells the RemoteObjectDelegate which type of object it is working with
    
    var store = try! Store<TransactionsBase>(reference: "transactions_list") // Defines the store where the data will be stored and cached
    
    func pull(request: RemoteRequest<Transaction.ID>) async throws -> [Transaction] {
        // Fetches the data from the database
        let req = supabase
            .from("transactions")
            .select()
        
        if request.isAll {
            let accountIds = BankAccountsDataDelegate.shared.store.objects(request: .all).map(\.id)
            let txs: [Transaction] = try await req
                .in("account_id", values: accountIds)
                .execute()
                .value
            
            return txs
        }
        
        let txs: [Transaction] = try await req
            .in("id", values: request.ids)
            .execute()
            .value
        
        return txs
    }
    
    func push(elements: [Transaction]) async throws {
        let query = try supabase.from("transactions")
            .upsert(elements)
        
        try await query.execute().value
    }
    
    func pop(elements: [Transaction]) async throws {
        try await supabase.from("transactions")
            .delete()
            .in("id", values: elements.map(\.id))
            .execute()
    }
    
    static var shared = TransactionsBase() // Defines the shared instance of the controller
}
