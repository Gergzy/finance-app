//
//  FirebaseManager.swift
//  Finance
//
//  Created by Samuel Goergen on 2/4/25.
//
import Foundation
import Firebase
import FirebaseFirestore

// New structure specifically for DashboardView
struct FinancialAccount: Identifiable, Decodable {
    var id = UUID()
    var balance: Double
    var mask: String
    var name: String
    var type: String
    var institution: String
    var transactions: [String] = []

    private enum CodingKeys: String, CodingKey {
        case balance = "accountBalance"
        case mask = "accountMask"
        case name = "accountName"
        case type = "accountType"
        case institution = "institutionName"
        case transactions = "accountTransactions"
    }
    
    
    
    
}

class FirebaseManager: ObservableObject {
    @Published var netWorth: Double = 0.0
    @Published var totalIncome: Double = 0.0
    @Published var totalExpenses: Double = 0.0
    @Published var accounts: [FinancialAccount] = []
    
    private var db = Firestore.firestore()
    
    func fetchFinancialData(userID: String) {
        let userRef = self.db.collection("users").document(userID)
        
        userRef.getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching user document:", error.localizedDescription)
                return
            }
            
            guard let document = document, document.exists, let data = document.data() else {
                print("User document does not exist or contains no data.")
                return
            }
            
            // Extract bankAccounts array from document
            guard let bankAccountsArray = data["bankAccounts"] as? [[String: Any]] else {
                print("No bank accounts found in user document.")
                return
            }
            
            print("Found \(bankAccountsArray.count) bank accounts for user:", userID)
            
            DispatchQueue.main.async {
                var totalNetWorth = 0.0
                var totalIncome = 0.0
                var totalExpenses = 0.0
                var fetchedAccounts: [FinancialAccount] = []
                
                for bankData in bankAccountsArray {
                    if let balance = bankData["accountBalance"] as? Double,
                       let mask = bankData["accountMask"] as? String,
                       let name = bankData["accountName"] as? String,
                       let type = bankData["accountType"] as? String,
                       let institution = bankData["institutionName"] as? String {
                        
                        let transactions = bankData["accountTransactions"] as? [String] ?? []

                        let account = FinancialAccount(
                            balance: balance,
                            mask: mask,
                            name: name,
                            type: type,
                            institution: institution,
                            transactions: transactions
                        )

                        fetchedAccounts.append(account)
                        totalNetWorth += balance

                        if type.lowercased() == "income" {
                            totalIncome += balance
                        } else if type.lowercased() == "expense" {
                            totalExpenses += balance
                        }
                    } else {
                        print("❌ Error parsing bank account data:", bankData)
                    }
                }

                
                self.accounts = fetchedAccounts
                self.netWorth = totalNetWorth
                self.totalIncome = totalIncome
                self.totalExpenses = totalExpenses
                
                print("✅ Successfully updated financial data with transactions.")
            }
        }
    }
}
