//
//  ProfileView.swift
//  Finance
//
//  Created by Samuel Goergen on 2/3/25.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Profile")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                Spacer()

                Text("User profile settings will appear here.")
                    .foregroundColor(.gray)
                    .padding()
            }
            .navigationBarTitle("Profile", displayMode: .inline)
            .navigationBarBackButtonHidden(true)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
