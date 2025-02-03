//
//  RegisterView.swift
//  Finance
//
//  Created by Samuel Goergen on 1/28/25.
//

import SwiftUI
import FirebaseAuth

struct RegisterView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String?
    @State private var showSuccessPopup: Bool = false
    @State private var navigateToLogin: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Create Account")
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
            
            SecureField("Confirm Password", text: $confirmPassword)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal, 20)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding(.horizontal, 20)
            }
            
            Button("Sign Up") {
                registerUser()
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .padding(.horizontal, 20)
        }
        .padding()
        .alert("Account Created Successfully!", isPresented: $showSuccessPopup) {
            Button("OK") {
                navigateToLogin = true
            }
        }
        .background(
            NavigationLink(destination: LoginView(), isActive: $navigateToLogin) {
                EmptyView()
            }
            .hidden()
        )
    }
    
    private func registerUser() {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                errorMessage = error.localizedDescription
            } else {
                showSuccessPopup = true
            }
        }
    }
}
