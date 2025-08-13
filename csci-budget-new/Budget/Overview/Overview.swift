//
//  Overview.swift
//  Budget
//
//  Created by Arthur Guiot on 10/30/24.
//

import SwiftUI
import Gravity

// This view shows an overview screen
struct OverviewScreen: View {
    @RemoteObjects<BankAccountsDataDelegate>(request: .all) var bankAccounts
    @RemoteObjects<TransactionsBase>(request: .all) var transactions
    @RemoteObjects<CategoryBase>(request: .all) var categories
    
    @State var showSettings = false
    @State private var isPresentingTxForm = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Carousel with Donut Chart and Transactions Graph
                    TabView {
                        // Donut Chart View
                        VStack {
                            Spacer()
                                .frame(height: 50)
                            SpendingDonutChart(overview: bankAccounts.monthlyOverview)
                            Spacer()
                                .frame(height: 50)
                        }.tag(0)
                        
                        // Transactions Graph View
                        VStack {
                            Spacer()
                                .frame(height: 50)
                            TransactionsGraphView(transactions: transactions)
                            Spacer()
                                .frame(height: 50)
                        }.tag(1)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
                    .frame(height: 320) // Adjust the height as needed
                    
                    SpendingCategoriesList(categories: allCategories)
                    
                    HStack(spacing: 12) {
                        Image(systemName: "plus")
                            .frame(width: 12, height: 12)
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Record a transaction")
                                    .font(.subheadline)
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.vertical, 10)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .onTapGesture {
                        isPresentingTxForm.toggle()
                    }
                    .sheet(isPresented: $isPresentingTxForm) {
                        TxForm(selectedCategoryId: nil)
                    }
                }
                .padding()
                .navigationTitle("Overview")
            }
            .refreshable {
                _bankAccounts.revalidate()
                _transactions.revalidate()
                _categories.revalidate()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showSettings.toggle()
                    }) {
                        Image(systemName: "person.crop.circle")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
    
    var allCategories: [SpendingCategory] {
        // Create a set to store unique categories
        var uniqueCategories = Set<SpendingCategory>()
        
        // Add categories from the existing categories object
        uniqueCategories.formUnion(categories.map { category in
            let sc = bankAccounts.globalOverview.categories.first(where: { $0.id == category.id })
            return sc ?? category.spendingCategory
        })
        
        // Add all categories from bank accounts
        uniqueCategories.formUnion(bankAccounts.globalOverview.categories)
        
        let monthlyOverview = bankAccounts.monthlyOverview
        // Merge with monthly goals
        let uc = uniqueCategories.map { _category in
            let category = monthlyOverview.categories.first(where: { $0.id == _category.id })
            
            return SpendingCategory(
                id: category?.id ?? _category.id,
                name: category?.name ?? _category.name,
                amount: category?.amount ?? 0,
                globalAmount: _category.globalAmount,
                color: category?.color ?? _category.color,
                goal: category?.goal ?? 0
            )
        }
        
        // Convert back to array, sort by amount and filter positive amounts
        return Array(uc)
            .sorted { $0.amount > $1.amount }
            .filter { $0.globalAmount > 0 }
    }

}

struct OverviewScreen_Previews: PreviewProvider {
    static var previews: some View {
        OverviewScreen()
    }
}
