//
//  MainTabView.swift
//  Finance
//
//  Created by Samuel Goergen on 2/3/25.
//
import SwiftUI

struct MainTabView: View {
    @State private var isSidebarOpen: Bool = false
    @State private var selectedTab: Int = 0

    var body: some View {
        ZStack(alignment: .leading) {
            // Sidebar Layer – conditionally present
            if isSidebarOpen {
                SideMenuView(isSidebarOpen: $isSidebarOpen)
                    .frame(width: UIScreen.main.bounds.width * 0.7, height: UIScreen.main.bounds.height)
                    .transition(.move(edge: .leading))
                    .animation(.easeInOut(duration: 0.3), value: isSidebarOpen)
                    .zIndex(2)
            }
            
            // An overlay to close the sidebar when tapped outside
            if isSidebarOpen {
                Color.black.opacity(0.3)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        withAnimation { isSidebarOpen = false }
                    }
                    .zIndex(1)
            }
            
            // Main Content: the TabView with child views
            TabView(selection: $selectedTab) {
                HomeView(viewModel: UserStatusViewModel(), isSidebarOpen: $isSidebarOpen)
                    .tag(0)
                    .tabItem {
                        Image(systemName: "house.fill")
                        Text("Home")
                    }
                
                BudgetView(isSidebarOpen: $isSidebarOpen)
                    .tag(1)
                    .tabItem {
                        Image(systemName: "list.bullet.rectangle")
                        Text("Transactions")
                    }
                
                ProfileView(isSidebarOpen: $isSidebarOpen)
                    .tag(2)
                    .tabItem {
                        Image(systemName: "person.circle.fill")
                        Text("Profile")
                    }
            }
            .offset(x: isSidebarOpen ? UIScreen.main.bounds.width * 0.7 : 0)
            .animation(.easeInOut(duration: 0.3), value: isSidebarOpen)
            .zIndex(0)
            // Reset the sidebar when the selected tab changes:
            .onChange(of: selectedTab) { newValue, oldValue in
                withAnimation {
                    isSidebarOpen = false
                }
            }
        }
    }
}


