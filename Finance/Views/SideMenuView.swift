//
//  SideMenuView.swift
//  Finance
//
//  Created by Samuel Goergen on 2/5/25.
//

import SwiftUI
import FirebaseAuth

struct SideMenuView: View {
    @Binding var isSidebarOpen: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            // Sidebar Content
            VStack(alignment: .leading, spacing: 16) {
                // Header with a close button and a title
                HStack {
                    Button(action: {
                        withAnimation {
                            isSidebarOpen = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .foregroundColor(.gray)
                    }
                    Text("Menu")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .padding(.leading, 8)
                }
                .padding(.top, 40)
                .padding(.horizontal)

                Divider()

                // Connect Bank Account button
                Button(action: {
                    print("Connect Bank Account button tapped")
                    openInitViewController()
                }) {
                    HStack {
                        Image(systemName: "link")
                            .frame(width: 24)
                        Text("Connect Bank Account")
                    }
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.gray.opacity(0.3), radius: 3, x: 0, y: 2)
                }
                .padding(.horizontal)

                Divider()

                // Log Out button
                Button(action: {
                    print("Log Out button tapped")
                    logOutUser()
                }) {
                    HStack {
                        Image(systemName: "arrow.left.square.fill")
                            .frame(width: 24)
                        Text("Log Out")
                    }
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white)
                    .cornerRadius(8)
                    .shadow(color: Color.gray.opacity(0.3), radius: 3, x: 0, y: 2)
                }
                .padding(.horizontal)

                Spacer()
            }
            .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.height)
            .background(Color(.systemGray5))
            .edgesIgnoringSafeArea(.vertical)
            .shadow(radius: 5)
            // Drag gesture to close the sidebar
            .gesture(
                DragGesture()
                    .onEnded { value in
                        if value.translation.width < -100 {
                            withAnimation {
                                isSidebarOpen = false
                            }
                        }
                    }
            )
        }
    }
    
    // Function to log out the user
    private func logOutUser() {
        do {
            try Auth.auth().signOut()
            print("User logged out successfully")
            
            // Redirect to SwiftUI-based LoginView after logout
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else { return }
            
            window.rootViewController = UIHostingController(rootView: LoginView())
            window.makeKeyAndVisible()
        } catch {
            print("Error logging out: \(error.localizedDescription)")
        }
    }
    
    // Function to open the bank connection screen
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




