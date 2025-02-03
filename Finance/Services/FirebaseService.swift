//
//  FirebaseService.swift
//  Finance
//
//  Created by Samuel Goergen on 2/3/25.
//

import FirebaseFirestore
import FirebaseAuth

class FirebaseService {
    private let db = Firestore.firestore()

    func saveBankAccountsToFirestore(bankAccounts: [BankAccount]) {
        guard let user = Auth.auth().currentUser else {
            print("Error: No authenticated user")
            return
        }

        let userID = user.uid
        let userRef = db.collection("users").document(userID)

        let bankData: [[String: Any]] = bankAccounts.map { account in
            return [
                "institutionName": account.institutionName,
                "accountName": account.accountName,
                "accountType": account.accountType,
                "accountMask": account.accountMask,
                "accountBalance": account.accountBalance,
                "accountTransactions": account.accountTransactions
            ]
        }

        userRef.setData(["bankAccounts": bankData], merge: true) { error in
            if let error = error {
                print("Error saving bank accounts: \(error.localizedDescription)")
            } else {
                print("Successfully saved bank accounts to Firestore")
            }
        }
    }
}
