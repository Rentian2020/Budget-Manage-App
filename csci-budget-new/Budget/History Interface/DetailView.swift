//
//  DetailView.swift
//  Budget
//
//  Created by Arthur Guiot on 11/29/24.
//

import SwiftUI
import Gravity

struct TransactionDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showEditView: Bool = false
    @State private var showDeleteAlert: Bool = false
    @State private var isDeleted: Bool = false
    
    let transaction: Transaction
    let category: SpendingCategory?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with merchant logo or default icon
            ZStack(alignment: .bottom) {
                Rectangle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [category?.color ?? .blue, category?.color.mix(with: .white, by: 0.5) ?? .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(height: 200)
                
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
                            } else {
                                Image(systemName: "banknote")
                                    .resizable()
                                    .scaledToFit()
                                    .padding(20)
                                    .foregroundColor(.gray)
                            }
                        }
                    )
                    .offset(y: 50)
            }
            .padding(.bottom, 50)
            
            // Transaction Details
            VStack(alignment: .leading, spacing: 16) {
                Text(transaction.merchantName ?? "Unknown Merchant")
                    .font(.title)
                    .fontWeight(.bold)
                
                HStack {
                    Text(formattedAmount)
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    Text(formattedDate)
                        .foregroundColor(.gray)
                }
                
                if let categoryName = categoryName {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.gray)
                        Text(categoryName)
                    }
                }
                
                if transaction.pending {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                        Text("Pending")
                            .foregroundColor(.orange)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal)
            .padding(.top)
            
            // Action Buttons
            HStack {
                Spacer()
                Button(action: {
                    showEditView = true
                }) {
                    HStack {
                        Image(systemName: "pencil")
                        Text("Edit")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                }
                .sheet(isPresented: $showEditView) {
                    TxForm(transactionToEdit: transaction)
                }
                
                Spacer()
                
                Button(action: {
                    showDeleteAlert = true
                }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Delete")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(10)
                }
                .alert(isPresented: $showDeleteAlert) {
                    Alert(
                        title: Text("Delete Transaction"),
                        message: Text("Are you sure you want to delete this transaction?"),
                        primaryButton: .destructive(Text("Delete")) {
                            deleteTransaction()
                        },
                        secondaryButton: .cancel()
                    )
                }
                
                Spacer()
            }
            .padding()
            
            Spacer()
        }
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            if isDeleted {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = transaction.isoCurrencyCode ?? "USD"
        let amountNumber = NSNumber(value: transaction.amount)
        return formatter.string(from: amountNumber) ?? "\(transaction.amount)"
    }
    
    var formattedDate: String {
        guard let date = transaction.date else { return "Unknown Date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var categoryName: String? {
        return category?.name
    }
    
    func deleteTransaction() {
        do {
            try TransactionsBase.shared.store.delete(element: transaction, requestPopWithInterval: 0)
            isDeleted = true
            presentationMode.wrappedValue.dismiss()
        } catch {
            // Handle error (e.g., show an alert)
        }
    }
}
