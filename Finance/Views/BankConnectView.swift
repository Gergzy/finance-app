//
//  
//  Finance
//
//  Created by Samuel Goergen on 1/29/25.
//
import SwiftUI

struct BankConnectView: View {
    var body: some View {
        VStack {
            Text("Welcome to Your Finance App")
                .font(.largeTitle)
                .padding()
            
            Button("Connect to Bank") {
                openInitViewController()  // Calls function to load the Storyboard
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding()
        }
    }

    private func openInitViewController() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)  // Load Storyboard
        if let initVC = storyboard.instantiateViewController(withIdentifier: "InitViewController") as? InitViewController {
            window.rootViewController = UINavigationController(rootViewController: initVC)  // Set as Root View Controller
            window.makeKeyAndVisible()
        }
    }
}

