//
//  Spending.swift
//  Budget
//
//  Created by Arthur Guiot on 10/30/24.
//

import SwiftUI

struct SpendingCategory: Identifiable, Hashable {
    let id: String
    let name: String
    let amount: Double
    let globalAmount: Double
    let color: Color
    let goal: Double
    
    var progress: Double {
        min(amount / goal, 1.0)
    }
}

struct SpendingOverview {
    var totalSpending: Double {
        categories.reduce(0) { partialResult, category in
            category.amount + partialResult
        }
    }
    let categories: [SpendingCategory]
}

struct SpendingCategoriesList: View {
    let categories: [SpendingCategory]
    
    var body: some View {
        VStack(spacing: 16) {
            ForEach(categories) { category in
                NavigationLink(destination: HistoryInitialView(category: category)) {
                    SpendingCategoryRow(category: category)
                }
            }
        }
    }
}

struct SpendingCategoryRow: View {
    let category: SpendingCategory
    
    var body: some View {
        
        HStack(spacing: 12) {
            Circle()
                .fill(category.color)
                .frame(width: 12, height: 12)
            VStack(alignment: .leading) {
                HStack {
                    Text(category.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text("$\(Int(category.amount))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.systemGray5))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(category.color)
                            .frame(width: geometry.size.width * category.progress)
                    }
                }
                .frame(height: 8)
            }
            .padding(.vertical, 10)
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
//        .frame(height: 52)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}
