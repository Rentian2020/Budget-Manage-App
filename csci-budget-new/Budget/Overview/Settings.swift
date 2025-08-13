import SwiftUI
import Gravity

struct SettingsView: View {
    @RemoteObjects<BankAccountsDataDelegate>(request: .all) var bankAccounts
    @State private var errorMessage: String = ""
    @State private var showAlert: Bool = false
    @State private var connectBank: Bool = false
    var body: some View {
        NavigationView {
            Form {
                Section("Banks") {
                    List {
                        ForEach(bankAccounts) { bank in
                            BankRow(bank: bank, deleteAction: deleteBank)
                        }
                        .onDelete(perform: deleteBanks)
                        
                        HStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Image(systemName: "link.badge.plus")
                                        .resizable()
                                        .scaledToFit()
                                        .padding(20)
                                        .foregroundColor(.gray)
                                )
                            Text("Connect a new Bank Account")
                                .font(.body)
                            Spacer()
                        }
                        .onTapGesture {
                            connectBank.toggle()
                        }
                        .sheet(isPresented: $connectBank) {
                            ConnectBank()
                        }
                    }
                }
                // Log Out & Remove Data button
                Button(action: {
                    Task {
                        do {
                            try await AuthStore.shared.signOut()
                        } catch {
                            DispatchQueue.main.async {
                                errorMessage = error.localizedDescription
                                showAlert = true
                            }
                        }
                    }
                }) {
                    Text("Log Out & Remove Data")
                        .font(.headline)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                EditButton()
            }
        }
    }
    
    func deleteBanks(at offsets: IndexSet) {
        for index in offsets {
            let bank = bankAccounts[index]
            do {
                try BankAccountsDataDelegate.shared.store.delete(element: bank, requestPopWithInterval: 0)
            } catch {
                errorMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
    
    func deleteBank(bank: BankAccount) {
        do {
            try BankAccountsDataDelegate.shared.store.delete(element: bank, requestPopWithInterval: 0)
        } catch {
            errorMessage = error.localizedDescription
            showAlert = true
        }
    }
}

struct BankRow: View {
    let bank: BankAccount
    let deleteAction: (BankAccount) -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(Color.white)
                .frame(width: 100, height: 100)
                .overlay(
                    Image(systemName: "building.columns")
                        .resizable()
                        .scaledToFit()
                        .padding(20)
                        .foregroundColor(.gray)
                )
            Text(bank.officialName ?? bank.accountName ?? "Bank Account")
                .font(.body)
            Spacer()
            Text(bank.currentBalance?.formatted(.currency(code: "USD")) ?? "$0.00")
        }
        .swipeActions {
            Button(role: .destructive) {
                deleteAction(bank)
            } label: {
                Label("Disconnect", systemImage: "xmark")
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
