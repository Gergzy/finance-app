//
//  LoginView.swift
//  Finance
//
//  Created by Samuel Goergen on 1/28/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isLoggedIn: Bool = false

    @StateObject private var userStatusViewModel = UserStatusViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Login")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.bottom, 20)

                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)

                SecureField("Password", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal, 20)

                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }

                Button("Log In") {
                    authenticateUser()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                .padding(.horizontal, 20)

                // Register Button for New Users
                NavigationLink(destination: RegisterView()) {
                    Text("Don't have an account? Register here")
                        .foregroundColor(.blue)
                        .underline()
                }
                .padding(.top, 10)

            }
            .padding()
            .fullScreenCover(isPresented: $isLoggedIn) {
                MainTabView()
            }
        }
    }

    private func authenticateUser() {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
                isLoggedIn = false
            } else if let user = result?.user {
                let uid = user.uid // Retrieve the unique Firebase UID
                print("User logged in with UID: \(uid)")

                // Fetch additional user details from Firestore (optional)
                fetchUserDetails(uid: uid)

                userStatusViewModel.fetchUserStatus()
                isLoggedIn = true
            }
        }
    }

    private func fetchUserDetails(uid: String) {
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)

        userRef.getDocument { document, error in
            if let document = document, document.exists {
                let userData = document.data()
                print("User data retrieved: \(String(describing: userData))")
            } else {
                print("No user data found, creating a new user entry if needed.")
            }
        }
    }
}


