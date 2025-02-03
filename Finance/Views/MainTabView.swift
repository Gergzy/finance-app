//
//  MainTabView.swift
//  Finance
//
//  Created by Samuel Goergen on 2/3/25.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            NavigationView {
                HomeView(viewModel: UserStatusViewModel())
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Home")
            }

            NavigationView {
                TransactionsView()
            }
            .tabItem {
                Image(systemName: "list.bullet.rectangle")
                Text("Transactions")
            }

            NavigationView {
                ProfileView()
            }
            .tabItem {
                Image(systemName: "person.circle.fill")
                Text("Profile")
            }
        }
    }
}
