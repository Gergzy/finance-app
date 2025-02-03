//
//  UserStatusViewModel.swift
//  Finance
//
//  Created by Samuel Goergen on 1/29/25.
//

import Foundation
import Combine

class UserStatusViewModel: ObservableObject {
    @Published var userId: String = ""
    @Published var userStatus: String = "Disconnected"

    func fetchUserStatus() {
        let communicator = ServerCommunicator()
        communicator.callMyServer(path: "/server/get_user_info", httpMethod: .get) { (result: Result<UserStatusResponse, ServerCommunicator.Error>) in
            DispatchQueue.main.async {
                switch result {
                case .success(let serverResponse):
                    self.userId = serverResponse.userId
                    self.userStatus = serverResponse.userStatus == .connected ? "Connected to Bank" : "Disconnected"
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
}
