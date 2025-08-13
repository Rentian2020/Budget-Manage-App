//
//  TxForm.swift
//  Budget
//
//  Created by Arthur Guiot on 11/23/24.
//

import Gravity
import SwiftUI

struct TxForm: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @State private var merchantName: String = ""
    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var selectedCategoryId: String = ""
    @State private var selectedBankAccountId: String = ""
    @State private var pending: Bool = false
    @State private var isoCurrencyCode: String = "USD"
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    let uuid: String
    
    @RemoteObjects<BankAccountsDataDelegate>(request: .all) var bankAccounts
    @RemoteObjects<CategoryBase>(request: .all) var categories
    
    // Custom number pad states
    @State private var showCustomKeypad: Bool = true
    @State private var isEditingAmount: Bool = true
    
    // States for pickers
    @State private var showDatePicker: Bool = false
    @State private var showCurrencyPicker: Bool = false
    @State private var showCategoryPicker: Bool = false
    @State private var showBankAccountPicker: Bool = false
    
    init(selectedCategoryId: String? = "") {
        if let id = selectedCategoryId {
            _selectedCategoryId = State(initialValue: id)
        }
        // Set default bank account ID
        if let firstBankAccount = BankAccountsDataDelegate.shared.store.objects(request: .all).first {
            _selectedBankAccountId = State(initialValue: firstBankAccount.id)
        }
        uuid = UUID().uuidString
    }
    
    init(transactionToEdit: Transaction? = nil) {
        if let transaction = transactionToEdit {
            _merchantName = State(initialValue: transaction.merchantName ?? "")
            _amount = State(initialValue: String(format: "%.2f", transaction.amount))
            _date = State(initialValue: transaction.date ?? Date())
            _selectedCategoryId = State(initialValue: transaction.categoryId ?? "")
            _selectedBankAccountId = State(initialValue: transaction.accountId)
            _pending = State(initialValue: transaction.pending)
            _isoCurrencyCode = State(initialValue: transaction.isoCurrencyCode ?? "USD")
            uuid = transaction.id
        } else {
            // Set default bank account ID
            if let firstBankAccount = BankAccountsDataDelegate.shared.store.objects(request: .all).first {
                _selectedBankAccountId = State(initialValue: firstBankAccount.id)
            }
            uuid = UUID().uuidString
        }
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                HStack {
                    // Top Category Selector
                    Button(action: {
                        showCategoryPicker = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "folder")
                            Text(selectedCategoryName)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                    }
                    .padding(.top)
                    .sheet(isPresented: $showCategoryPicker) {
                        CategoryPickerView(selectedCategoryId: $selectedCategoryId, categories: categories)
                    }
                    
                    // Bank Account Selector
                    Button(action: {
                        showBankAccountPicker = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "banknote")
                            Text(selectedBankAccountName)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .cornerRadius(20)
                    }
                    .padding(.top)
                    .sheet(isPresented: $showBankAccountPicker) {
                        BankAccountPickerView(selectedBankAccountId: $selectedBankAccountId)
                    }
                }
                
                // Amount Display
                VStack(spacing: 8) {
                    Text("Expenses")
                        .foregroundColor(.gray)
                        .font(.system(size: 18))
                    
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(TxForm.currencySymbol(for: isoCurrencyCode))
                            .foregroundColor(.gray)
                            .font(.system(size: 24))
                        Text(amount.isEmpty ? "0.00" : amount)
                            .font(.system(size: 48, weight: .regular))
                    }
                }
                .padding(.vertical, 20)
                
                // Comment Field
                TextField("Name / Comment...", text: $merchantName)
                    .multilineTextAlignment(.center)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 40)
                
                Spacer()
                
                if showCustomKeypad {
                    CustomKeypad(
                        amount: $amount,
                        showDatePicker: $showDatePicker,
                        showCurrencyPicker: $showCurrencyPicker,
                        saveAction: saveTransaction,
                        isoCurrencyCode: isoCurrencyCode
                    )
                    .padding(.bottom)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.primary)
                }
            }
        }
        // Date Picker Sheet
        .sheet(isPresented: $showDatePicker) {
            DatePickerView(selectedDate: $date)
        }
        // Currency Picker Sheet
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerView(selectedCurrencyCode: $isoCurrencyCode, currencyCodes: currencyCodes)
        }
        // Error Alert
        .alert("Error", isPresented: $showError) {
            Button("OK") { showError = false }
        } message: {
            Text(errorMessage)
        }
    }
    
    var selectedCategoryName: String {
        categories.first(where: { $0.id == selectedCategoryId })?.hierarchy.last ?? "Select Category"
    }
    
    var selectedBankAccountName: String {
        bankAccounts.first(where: { $0.id == selectedBankAccountId })?.accountName ?? "Select Bank Account"
    }
    
    var currencyCodes: [String] {
        ["EUR", "CAD", "HKD", "ISK", "PHP", "DKK", "HUF", "CZK", "AUD", "RON", "SEK", "IDR", "INR", "BRL", "RUB", "HRK", "JPY", "THB", "CHF", "SGD", "PLN", "BGN", "TRY", "CNY", "NOK", "NZD", "ZAR", "USD", "MXN", "ILS", "GBP", "KRW", "MYR"]
    }
    
    static func currencySymbol(for currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        return formatter.currencySymbol ?? currencyCode
    }
    
    func saveTransaction() {
        guard let amountValue = Float(amount) else {
            errorMessage = "Invalid amount format"
            showError = true
            return
        }
        
        guard merchantName.isEmpty == false else {
            errorMessage = "Merchant name is required"
            showError = true
            return
        }
        
        guard !BankAccountsDataDelegate.shared.store.objects(request: .all).isEmpty else {
            errorMessage = "No bank account available"
            showError = true
            return
        }
        
        let newTransaction = Transaction(
            id: uuid,
            accountId: selectedBankAccountId.isEmpty ? BankAccountsDataDelegate.shared.store.objects(request: .all).first!.id : selectedBankAccountId,
            amount: amountValue,
            isoCurrencyCode: isoCurrencyCode,
            unofficialCurrencyCode: nil,
            categoryId: selectedCategoryId.isEmpty ? nil : selectedCategoryId,
            date: date,
            merchantName: merchantName,
            pending: pending,
            logoUrl: nil
        )
        
        do {
            try onSave(transaction: newTransaction)
            presentationMode.wrappedValue.dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    func onSave(transaction: Transaction) throws {
        try TransactionsBase.shared.store
            .add(transaction, with: .id(transaction.id), requestPushWithInterval: 0)
    }
}

struct BankAccountPickerView: View {
    @Binding var selectedBankAccountId: String
    @RemoteObjects<BankAccountsDataDelegate>(request: .all) var bankAccounts
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List {
                ForEach(bankAccounts) { account in
                    Button(action: {
                        selectedBankAccountId = account.id
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack {
                            Text(account.officialName ?? account.accountName ?? "Bank Account")
                            Spacer()
                            if selectedBankAccountId == account.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Bank Account")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct CategoryPickerView: View {
    @Binding var selectedCategoryId: String
    var categories: [Category]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List(categories) { category in
                Button(action: {
                    selectedCategoryId = category.id
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(category.hierarchy.last ?? "Uncategorized")
                        Spacer()
                        if selectedCategoryId == category.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .navigationTitle("Select Category")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct DatePickerView: View {
    @Binding var selectedDate: Date
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                Spacer()
            }
            .navigationTitle("Select Date")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct CurrencyPickerView: View {
    @Binding var selectedCurrencyCode: String
    let currencyCodes: [String]
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            List(currencyCodes, id: \.self) { code in
                Button(action: {
                    selectedCurrencyCode = code
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Text(code)
                        Spacer()
                        if selectedCurrencyCode == code {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .navigationTitle("Select Currency")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct CustomKeypad: View {
    @Binding var amount: String
    @Binding var showDatePicker: Bool
    @Binding var showCurrencyPicker: Bool
    var saveAction: () -> Void
    var isoCurrencyCode: String
    
    let buttons: [[KeypadButton]] = [
        [.number("1"), .number("2"), .number("3"), .delete],
        [.number("4"), .number("5"), .number("6"), .calendar],
        [.number("7"), .number("8"), .number("9"), .empty],
        [.currency, .number("0"), .decimal, .done]
    ]
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 12) {
                    ForEach(row, id: \.self) { button in
                        KeypadButtonView(
                            button: button,
                            amount: $amount,
                            showDatePicker: $showDatePicker,
                            showCurrencyPicker: $showCurrencyPicker,
                            saveAction: saveAction,
                            isoCurrencyCode: isoCurrencyCode
                        )
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

enum KeypadButton: Hashable {
    case number(String)
    case decimal
    case delete
    case currency
    case calendar
    case done
    case empty
}

struct KeypadButtonView: View {
    let button: KeypadButton
    @Binding var amount: String
    @Binding var showDatePicker: Bool
    @Binding var showCurrencyPicker: Bool
    var saveAction: () -> Void
    var isoCurrencyCode: String
    
    var body: some View {
        if case .empty = button {
            Spacer()
                .frame(width: 70, height: 70)
        } else {
            Button(action: { handleTap() }) {
                ZStack {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 70, height: 70)
                    
                    buttonContent
                }
            }
        }
    }
    
    private var backgroundColor: Color {
        switch button {
        case .done: return .black
        case .delete: return .red.opacity(0.2)
        case .calendar: return .blue.opacity(0.2)
        case .currency: return .yellow.opacity(0.3)
        default: return Color(.systemGray6)
        }
    }
    
    @ViewBuilder
    private var buttonContent: some View {
        switch button {
        case .number(let num):
            Text(num)
                .font(.title)
        case .decimal:
            Text(".")
                .font(.title)
        case .delete:
            Image(systemName: "delete.left")
                .font(.title2)
        case .currency:
            Text(TxForm.currencySymbol(for: isoCurrencyCode))
                .font(.title2)
        case .calendar:
            Image(systemName: "calendar")
                .font(.title2)
        case .done:
            Image(systemName: "checkmark")
                .font(.title2)
                .foregroundColor(.white)
        case .empty:
            Text("")
        }
    }
    
    private func handleTap() {
        switch button {
        case .number(let num):
            if amount.count < 10 {
                amount += num
            }
        case .decimal:
            if !amount.contains(".") {
                amount += "."
            }
        case .delete:
            if !amount.isEmpty {
                amount.removeLast()
            }
        case .currency:
            showCurrencyPicker = true
        case .calendar:
            showDatePicker = true
        case .done:
            saveAction()
        case .empty: break
            // Do nothing
        }
    }
}

#Preview {
    TxForm(selectedCategoryId: "")
}
