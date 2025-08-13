//
//  Category.swift
//  Budget
//
//  Created by Arthur Guiot on 11/13/24.
//
import Gravity
import SwiftUI

struct Category: RemoteRepresentable {
    let id: String
    let group: String
    let hierarchy: [String]
    
    enum CodingKeys: String, CodingKey {
        case id = "category_id"
        case group
        case hierarchy
    }
}

@MainActor
extension Category {
    var spendingCategory: SpendingCategory {
        // You could maintain a mapping of category IDs to names and colors
        let categoryInfo = Category.getCategoryInfo(id)
        
        return SpendingCategory(
            id: id,
            name: categoryInfo.name,
            amount: 0,
            globalAmount: 0,
            color: categoryInfo.color,
            goal: categoryInfo.monthlyGoal // You'll need to store/retrieve goals somewhere
        )
    }
    
    // Helper function to map category IDs to display info
    static func getCategoryInfo(_ categoryId: String) -> (name: String, color: Color, monthlyGoal: Double) {
        let categories = CategoryBase.shared.store.objects(request: .all)
        // Find the matching category
        let category = categories.first { $0.id == categoryId }
        
        // Get the most specific category name from the hierarchy
        let name = category?.hierarchy.last ?? "Uncategorized"
        
        // Generate a consistent color based on the category ID
        let color: Color = name.toColor
        
        // For now, return a default monthly goal of 0
        // You could implement a proper budgeting system later
        let monthlyGoal: Double = 0.0
        
        return (name: name, color: color, monthlyGoal: monthlyGoal)
    }
}
