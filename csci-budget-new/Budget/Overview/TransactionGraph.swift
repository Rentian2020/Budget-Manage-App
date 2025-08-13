//
//  TransactionEntry.swift
//  Budget
//
//  Created by Arthur Guiot on 11/29/24.
//
import SwiftUI
import Charts

struct TransactionsGraphView: View {
    let transactions: [Transaction]
    let calendar = Calendar.current
    let currentDate = Date()
    
    var body: some View {
        Chart {
            LinePlot(
                transactions.filteredPreviousMonthTransactions,
                x: .value("Day", \.dayOfMonth),
                y: .value("Amount", \.amountInUSD)
            )
            .foregroundStyle(by: .value("period", "Previous Month"))
            .opacity(0.5)
            LinePlot(
                transactions.filteredTransactions,
                x: .value("Day", \.dayOfMonth),
                y: .value("Amount", \.amountInUSD)
            )
            .foregroundStyle(by: .value("period", "Current Month"))
        }
        .chartYAxis {
            AxisMarks(position: .leading)
        }
        .chartXAxis {
            AxisMarks(values: Array(stride(from: 1, through: 31, by: 5))) { value in
                AxisValueLabel("\(value.as(Int.self) ?? 0)")
            }
        }
        .chartForegroundStyleScale([
            "Previous Month": .gray, "Current Month": .blue
        ])
        .padding()
    }
    
    // Helper function to convert transaction amount to USD
    func transactionAmountInUSD(_ transaction: Transaction) -> Float {
        let currencyCode = transaction.isoCurrencyCode ?? "USD"
        let exchangeRate = ExchangeRate.shared.rates[currencyCode] ?? 1.0
        return transaction.amount / Float(exchangeRate)
    }
}

extension Transaction {
    var dayOfMonth: Int {
        let calendar = Calendar.current
        
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: date ?? Date()))!
        if let date = date {
            let day = calendar.dateComponents([.day], from: startOfMonth, to: date).day ?? 0
            return day + 1 // Adding 1 because day components are zero-based
        }
        return 0
    }
    
    var amountInUSD: Double {
        let currencyCode = isoCurrencyCode ?? "USD"
        let exchangeRate = ExchangeRate.shared.rates[currencyCode] ?? 1.0
        return abs(Double(amount) / exchangeRate)
    }
}

extension Array<Transaction> {
    fileprivate var currentDate: Date {
        Date()
    }
    fileprivate var calendar: Calendar {
        .current
    }
    // Computed properties for the start of the current and previous months
    var startOfCurrentMonth: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate))!
    }
    
    var startOfPreviousMonth: Date {
        calendar.date(byAdding: .month, value: -1, to: startOfCurrentMonth)!
    }
    
    // Function to extract the day of the month from a date
    func dayOfMonth(_ date: Date?, startOfMonth: Date) -> Int {
        if let date = date {
            let day = calendar.dateComponents([.day], from: startOfMonth, to: date).day ?? 0
            return day + 1 // Adding 1 because day components are zero-based
        }
        return 0
    }
    
    // Filter transactions for the current month
    var filteredTransactions: [Transaction] {
        return self.filter { transaction in
            if let date = transaction.date {
                return date >= startOfCurrentMonth && date <= currentDate
            }
            return false
        }
        .sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }
    }
    
    // Filter transactions for the previous month
    var filteredPreviousMonthTransactions: [Transaction] {
        return self.filter { transaction in
            if let date = transaction.date {
                return date >= startOfPreviousMonth && date < startOfCurrentMonth
            }
            return false
        }
        .sorted { ($0.date ?? Date()) < ($1.date ?? Date()) }
    }
}
