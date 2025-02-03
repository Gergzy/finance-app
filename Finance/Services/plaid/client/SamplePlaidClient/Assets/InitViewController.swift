//
//  
//
//  Created by Todd Kerpelman on 8/17/23.
//

import UIKit
import SwiftUI

class InitViewController: UIViewController {
    
    @IBOutlet var userLabel: UILabel!
    @IBOutlet var statusLabel: UILabel!
    @IBOutlet var simpleCallResults: UILabel!
    
    @IBOutlet var connectToPlaid: UIButton!
    @IBOutlet var simpleCallButton: UIButton!
    let communicator = ServerCommunicator()
    
    let userStatusViewModel = UserStatusViewModel() //ViewModel to track user status

    @IBAction func makeSimpleCallWasPressed(_ sender: Any) {
        self.communicator.callMyServer(
            path: "/server/simple_auth",
            httpMethod: .get
        ) { (result: Result<SimpleAuthResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let decodedResponse):
                let bankAccounts = decodedResponse.bankAccounts
                
                let firebaseService = FirebaseService()
                firebaseService.saveBankAccountsToFirestore(bankAccounts: bankAccounts)

                print("Successfully saved all accounts to Firebase!")

            case .failure(let error):
                print("Error fetching Plaid data: \(error)")
            }
        }

    }

    
    @IBAction func returnToHomeView(_ sender: Any) {
        print("Button Clicked - Navigating to HomeView")

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return }

        let homeView = HomeView(viewModel: UserStatusViewModel())
        let homeViewController = UIHostingController(rootView: homeView)

        window.rootViewController = homeViewController
        window.makeKeyAndVisible()
    }
    @IBAction func connectToPlaidWasPressed(_ sender: Any) {
        userStatusViewModel.fetchUserStatus() // Fetch the latest status
        
        let homeView = HomeView(viewModel: userStatusViewModel)
        let hostingController = UIHostingController(rootView: homeView)
        
        hostingController.modalPresentationStyle = .fullScreen
        present(hostingController, animated: true, completion: nil)
    }
    
    private func determineUserStatus() {
        self.communicator.callMyServer(path: "/server/get_user_info", httpMethod: .get) {
            (result: Result<UserStatusResponse, ServerCommunicator.Error>) in
            
            DispatchQueue.main.async {
                switch result {
                case .success(let serverResponse):
                    self.userLabel.text = "Hello user \(serverResponse.userId)!"
                    self.userStatusViewModel.userId = serverResponse.userId
                    self.userStatusViewModel.userStatus = serverResponse.userStatus == .connected ? "Connected to Bank" : "Disconnected"

                    switch serverResponse.userStatus {
                    case .connected:
                        self.statusLabel.text = "You are connected to your bank via Plaid. Make a call!"
                        self.connectToPlaid.setTitle("Make a new connection", for: .normal)
                        self.simpleCallButton.isEnabled = true
                    case .disconnected:
                        self.statusLabel.text = "You should connect to a bank"
                        self.connectToPlaid.setTitle("Connect", for: .normal)
                        self.simpleCallButton.isEnabled = false
                    }
                    self.connectToPlaid.isEnabled = true
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        determineUserStatus()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
