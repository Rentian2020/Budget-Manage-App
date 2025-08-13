//
//  CategoryBase.swift
//  Budget
//
//  Created by Arthur Guiot on 11/13/24.
//

import Gravity
import Foundation

struct CategoriesResponse: Codable {
    let categories: [Category]
}

@MainActor
struct CategoryBase: @preconcurrency RemoteObjectDelegate {
    
    
    typealias Element = Category
    
    var store = try! Store<CategoryBase>(reference: "spending_categories") // Defines the store where the data will be stored and cached
    
    
    static var shared = CategoryBase()
    
    func pull(request: Gravity.RemoteRequest<Category.ID>) async throws -> [Category] {
        guard request.isAll else { fatalError("Not implemented") }
        let url = URL(string: "https://production.plaid.com/categories/get")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Empty body as per the curl example
        request.httpBody = "{}".data(using: .utf8)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(CategoriesResponse.self, from: data)
        return response.categories
    }
}
