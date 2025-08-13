//
//  BankAccounts.swift
//  Budget
//
//  Created by Arthur Guiot on 11/13/24.
//

import Foundation
import Gravity
import SwiftUICore

enum AccountType: String, Codable {
    case checking = "checking"
    case savings = "savings"
    case credit = "credit"
    case other
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        switch value.lowercased() {
        case "checking": self = .checking
        case "savings": self = .savings
        case "credit": self = .credit
        default: self = .other
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .checking, .savings, .credit:
            try container.encode(rawValue)
        case .other:
            try container.encode("other")
        }
    }
}

@MainActor
struct BankAccount: RemoteRepresentable {
    let user: UUID
    let id: String
    let availableBalance: Double?
    let currentBalance: Double?
    let isoCurrencyCode: String?
    let unofficialCurrencyCode: String?
    let mask: String?
    let accountName: String?
    let officialName: String?
    let type: AccountType
    let subtype: String?
    
    var transactions: [Transaction] {
        TransactionsBase.shared.store.objects(request: .all).filter { $0.accountId == id }
    }
    
    enum CodingKeys: String, CodingKey {
        case user
        case id = "accountId"
        case availableBalance
        case currentBalance
        case isoCurrencyCode
        case unofficialCurrencyCode
        case mask
        case accountName = "account_name"
        case officialName
        case type
        case subtype
    }
}


@MainActor
extension BankAccount {
    var monthlySpending: Double {
        transactions.sumInUSD
    }
    
    var spendingMonthlyCategories: [SpendingCategory] {
        // First group transactions by category
        let groupedTransactions = Dictionary(grouping: transactions.filteredTransactions) { transaction in
            transaction.categoryId ?? "uncategorized"
        }
        
        // Convert grouped transactions into SpendingCategory objects
        return groupedTransactions.map { categoryId, transactions in
            let totalAmount = transactions.sumInUSD
            
            // You could maintain a mapping of category IDs to names and colors
            let categoryInfo = Category.getCategoryInfo(categoryId)
            
            return SpendingCategory(
                id: categoryId,
                name: categoryInfo.name,
                amount: Double(totalAmount),
                globalAmount: spendingGloballyCategories.first(where: { $0.id == categoryId })?.amount ?? 0.0,
                color: categoryInfo.color,
                goal: categoryInfo.monthlyGoal // You'll need to store/retrieve goals somewhere
            )
        }
        .sorted { $0.amount > $1.amount } // Sort by amount descending
    }
    
    var spendingGloballyCategories: [SpendingCategory] {
        // First group transactions by category
        let groupedTransactions = Dictionary(grouping: transactions) { transaction in
            transaction.categoryId ?? "uncategorized"
        }
        
        // Convert grouped transactions into SpendingCategory objects
        return groupedTransactions.map { categoryId, transactions in
            let totalAmount = transactions.sumInUSD
            
            // You could maintain a mapping of category IDs to names and colors
            let categoryInfo = Category.getCategoryInfo(categoryId)
            
            return SpendingCategory(
                id: categoryId,
                name: categoryInfo.name,
                amount: Double(totalAmount),
                globalAmount: Double(totalAmount),
                color: categoryInfo.color,
                goal: categoryInfo.monthlyGoal // You'll need to store/retrieve goals somewhere
            )
        }
        .sorted { $0.amount > $1.amount } // Sort by amount descending
    }
}

@MainActor
extension Array<BankAccount> {
    var monthlyOverview: SpendingOverview {
        // First collect all spending categories from all accounts
        let allCategories = self.flatMap { $0.spendingMonthlyCategories }
        
        // Group categories by name and combine their amounts
        let mergedCategories = Dictionary(grouping: allCategories) { $0.name }
            .map { name, categories in
                // Sum up amounts and goals for each category
                let totalAmount = categories.reduce(0.0) { $0 + $1.amount }
                let totalGoal = categories.reduce(0.0) { $0 + $1.goal }
                // Use the color from the first category (assuming same categories have same colors)
                let color = categories.first?.color ?? .gray
                let id = categories.first?.id ?? "0"
                return SpendingCategory(
                    id: id,
                    name: name,
                    amount: totalAmount,
                    globalAmount: globalOverview.categories.first(where: { $0.id == id })?.globalAmount ?? totalAmount,
                    color: color,
                    goal: totalGoal
                )
            }
            .sorted { $0.amount > $1.amount }
        
        return SpendingOverview(
            categories: mergedCategories
        )
    }
    
    var globalOverview: SpendingOverview {
        // First collect all spending categories from all accounts
        let allCategories = self.flatMap { $0.spendingGloballyCategories }
        
        // Group categories by name and combine their amounts
        let mergedCategories = Dictionary(grouping: allCategories) { $0.name }
            .map { name, categories in
                // Sum up amounts and goals for each category
                let totalAmount = categories.reduce(0.0) { $0 + $1.amount }
                let totalGoal = categories.reduce(0.0) { $0 + $1.goal }
                // Use the color from the first category (assuming same categories have same colors)
                let color = categories.first?.color ?? .gray
                let id = categories.first?.id ?? "0"
                return SpendingCategory(
                    id: id,
                    name: name,
                    amount: totalAmount,
                    globalAmount: totalAmount,
                    color: color,
                    goal: totalGoal
                )
            }
            .sorted { $0.amount > $1.amount }
        
        return SpendingOverview(
            categories: mergedCategories
        )
    }
}
