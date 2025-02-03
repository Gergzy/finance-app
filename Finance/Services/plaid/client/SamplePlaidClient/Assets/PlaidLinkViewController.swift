//
//
//  Created by Todd Kerpelman on 8/18/23.
//

import UIKit
import LinkKit
import SwiftUI
import FirebaseAuth

class PlaidLinkViewController: UIViewController {
    @IBOutlet var startLinkButton: UIButton!
    let communicator = ServerCommunicator()
    var linkToken: String?
    var handler: Handler?
    
 


    
    private func createLinkConfiguration(linkToken: String) -> LinkTokenConfiguration {
        // Create our link configuration object
        // This return type will be a LinkTokenConfiguration object
        var linkTokenConfig = LinkTokenConfiguration(token: linkToken) { success in
            print("Link was finished successfully \(success)")
            self.exchangePublicTokenForAccessToken(success.publicToken)
        }
        linkTokenConfig.onExit = {linkEvent in
            print("User Exited Link early \(linkEvent)")
        }
        linkTokenConfig.onEvent = {linkEvent in
            print("Hit an event \(linkEvent.eventName)")
        }
        return linkTokenConfig
    }
    
    @IBAction func startLinkWasPressed(_ sender: Any) {
        // Handle the button being clicked
        guard let linkToken = self.linkToken else {return}
        let config = createLinkConfiguration(linkToken: linkToken)
        let creationResult = Plaid.create(config)
        switch creationResult {
        case .success(let handler):
            self.handler = handler
            handler.open(presentUsing: .viewController(self))
        case .failure(let error):
            print("Handler creation error \(error)")
        }
    }
    
    private func exchangePublicTokenForAccessToken(_ publicToken: String) {
        // Exchange our public token for an access token
        self.communicator.callMyServer(path: "/server/swap_public_token/", httpMethod: .post, params: ["public_token": publicToken]) { (result: Result<SwapPublicTokenResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let response):
                self.navigationController?.popViewController(animated: true)
            case .failure(let error):
                print("Error exchanging public token for access token: \(error)")
            }
        }
    }


    

    
    public func fetchLinkToken() {
        self.communicator.callMyServer(path: "/server/generate_link_token", httpMethod: .post) { (result:
            Result<LinkTokenCreateResponse, ServerCommunicator.Error>) in
            switch result {
            case .success(let response):
                self.linkToken = response.linkToken
                self.startLinkButton.isEnabled = true
            case .failure(let error):
                print("Error fetching link token: \(error)")
            }
        }
        

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("Presented Modally: \(self.presentingViewController != nil)")
        self.startLinkButton.isEnabled = false
        fetchLinkToken()
    }
    

    /*

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
