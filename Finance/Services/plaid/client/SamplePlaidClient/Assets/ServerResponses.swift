//
// 
//
//  Created by Dave Troupe on 8/30/23.
//

import Foundation

enum UserConnectionStatus: String, Codable {
    case connected
    case disconnected
}

struct UserStatusResponse: Codable {
    let userStatus: UserConnectionStatus
    let userId: String
}

 struct LinkTokenCreateResponse: Codable {
    let linkToken: String
    let expiration: String
}
 
struct SwapPublicTokenResponse: Codable {
    let success: Bool
}

struct SimpleAuthResponse: Codable {
    let bankAccounts: [BankAccount]
}

struct BankAccount: Codable {
    let institutionName: String
    let accountName: String
    let accountType: String
    let accountMask: String
    let accountBalance: Double
    let accountTransactions: [String]

    enum CodingKeys: String, CodingKey {
        case institutionName
        case accountName
        case accountType
        case accountMask
        case accountBalance
        case accountTransactions = "transactions"
    }
}
 
