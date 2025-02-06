//
//  HomeView.swift
//  Finance
//
//  Created by Samuel Goergen on 1/28/25.
import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: UserStatusViewModel
    @Binding var isSidebarOpen: Bool
    
    var body: some View {
        // No local offset here—the TabView in MainTabView is handling the shift
        ZStack {
            VStack(spacing: 0) {
                CustomTopBar(isSidebarOpen: $isSidebarOpen)
                
                Spacer()
                
                VStack {
                    Text("Welcome to Your Finance Dashboard")
                        .font(.largeTitle)
                        .padding()
                    
                    Button("Connect Bank Account") {
                        openInitViewController()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding()
                }
                .frame(maxHeight: .infinity)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
    
    private func openInitViewController() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let initVC = storyboard.instantiateViewController(withIdentifier: "InitViewController") as? InitViewController {
            window.rootViewController = UINavigationController(rootViewController: initVC)
            window.makeKeyAndVisible()
        }
    }
}





