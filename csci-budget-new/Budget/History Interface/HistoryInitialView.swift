//
//  HistoryInitialView.swift
//  Budget
//
//  Created by Jason Yu on 11/15/24.
//

import SwiftUI
import Gravity

struct HistoryInitialView: View {
    @RemoteObjects<TransactionsBase>(request: .all) var transactions
    @State private var isPresentingTxForm = false
    
    let category: SpendingCategory?
    
    init(category: SpendingCategory? = nil) {
        self.category = category
    }
    
    var body: some View {
        NavigationView {
            VStack {
                List {
                    ForEach(txData) { transaction in
                        TransactionRow(title: transaction.merchantName ?? "unknown", transaction: transaction, category: category)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    _transactions.revalidate()
                }
            }
            .background(Color.gray.opacity(0.1))
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isPresentingTxForm = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingTxForm) {
                TxForm(selectedCategoryId: category?.id)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    var txData: [Transaction] {
        return transactions.filter { tx in
            guard let category = category else { return true }
            if category.id != "uncategorized" {
                return tx.categoryId == category.id
            }
            return tx.categoryId == nil
        }.sorted { $0.date ?? Date() > $1.date ?? Date() }
    }
}

struct TransactionRow: View {
    let title: String
    let transaction: Transaction
    let category: SpendingCategory?
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationLink(destination: TransactionDetailView(transaction: transaction, category: category)) {
            HStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Group {
                            if let logoUrl = transaction.logoUrl, let url = URL(string: logoUrl) {
                                AsyncImage(url: url) { image in
                                    image.resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    ProgressView()
                                }
                                .clipShape(Circle())
                            } else {
                                Image(systemName: "banknote")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(20)
                                    .foregroundColor(.gray)
                            }
                        }
                    )
                Text(title)
                    .font(.body)
                Spacer()
                Text(formattedAmount)
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteTransaction()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
        }
        .padding(.vertical, 8)
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func deleteTransaction() {
        do {
            // Remove from TransactionsBase
            try TransactionsBase.shared.store.delete(element: transaction, requestPopWithInterval: 0)
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = transaction.isoCurrencyCode ?? "USD"
        let amountNumber = NSNumber(value: transaction.amount)
        return formatter.string(from: amountNumber) ?? "\(transaction.amount)"
    }
}


#Preview {
    HistoryInitialView()
}
