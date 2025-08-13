//
//  DonutChart.swift
//  Budget
//
//  Created by Arthur Guiot on 10/30/24.
//

import SwiftUI

struct SpendingDonutChart: View {
    let overview: SpendingOverview
    
    var body: some View {
        VStack {
            Text("Monthly Spending")
                .font(.headline)
                .padding(.bottom, 8)
            
            // Create the pie chart for the spending overview.
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 20)
                
                ForEach(overview.categories.indices, id: \.self) { index in
                    let startAngle = self.startAngle(for: index)
                    let endAngle = self.endAngle(for: index)
                    
                    Circle()
                        .trim(from: startAngle, to: endAngle)
                        .stroke(overview.categories[index].color, lineWidth: 20)
                        .rotationEffect(.degrees(-90))
                }
                
                Text("$\(Int(overview.totalSpending))")
                    .font(.title2)
                    .bold()
            }
        }
    }
    
    private func startAngle(for index: Int) -> Double {
        let prior = overview.categories.prefix(index)
        return prior.reduce(0) { $0 + ($1.amount / overview.totalSpending) }
    }
    
    private func endAngle(for index: Int) -> Double {
        startAngle(for: index) + (overview.categories[index].amount / overview.totalSpending)
    }
}
