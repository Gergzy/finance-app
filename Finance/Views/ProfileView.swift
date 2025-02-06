//
//  ProfileView.swift
//  Finance
//
//  Created by Samuel Goergen on 2/3/25.
//


import SwiftUI
import Charts
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var firebaseManager = FirebaseManager()
    @Binding var isSidebarOpen: Bool
    
    var body: some View {
        ZStack {
            // Main Content Layer
            VStack(spacing: 0) {
                // Use the CustomTopBar from its own file
                CustomTopBar(isSidebarOpen: $isSidebarOpen)
                
                ScrollView {
                    VStack(spacing: 16) {
                        NetWorthCard(netWorth: firebaseManager.netWorth)
                        AccountBalanceCard(income: firebaseManager.totalIncome, expenses: firebaseManager.totalExpenses)
                        BudgetCard(used: firebaseManager.totalExpenses, limit: 1000.00)
                        BillsCard(bills: [("Rent", "$1200", "Feb 10"), ("Credit Card", "$200", "Feb 15")])
                        GoalsCard(goals: [("Emergency Fund", 4000.0, 10000.0)])
                        
                        ForEach(firebaseManager.accounts) { account in
                            FinancialAccountCard(account: account)
                        }
                        
                        if firebaseManager.accounts.count > 0 {
                            InvestmentsCard()
                        }
                        
                        InsightsCard()
                        SubscriptionStatusCard(isPremiumUser: true)
                    }
                    .padding()
                    .onAppear {
                        if let user = Auth.auth().currentUser {
                            firebaseManager.fetchFinancialData(userID: user.uid)
                        } else {
                            print("No authenticated user found")
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}





struct FinancialAccountCard: View {
    var account: FinancialAccount

    var body: some View {
        VStack(alignment: .leading) {
            CardView(
                title: "\(account.institution) - \(account.name) (\(account.mask))",
                value: "Balance: \(String(format: "$%.2f", account.balance))",
                icon: "creditcard.fill"
            )

            // Display Transactions with Unique IDs
            if !account.transactions.isEmpty {
                VStack(alignment: .leading) {
                    Text("Recent Transactions")
                        .font(.headline)
                        .padding(.leading)

                    ForEach(Array(account.transactions.enumerated()), id: \.0) { index, transaction in
                        Text("- \(transaction)")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .padding(.leading)
                    }
                }
                .padding(.bottom)
            } else {
                Text("No transactions available")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .padding(.leading)
            }
        }
    }
}



struct NetWorthCard: View {
    var netWorth: Double
    var body: some View {
        CardView(title: "Net Worth", value: "\(String(format: "$%.2f", netWorth))", icon: "dollarsign.circle.fill")
    }
}

struct AccountBalanceCard: View {
    var income: Double
    var expenses: Double
    var body: some View {
        CardView(title: "Income & Expenses", value: "Income: \(String(format: "$%.2f", income)) | Expenses: \(String(format: "$%.2f", expenses))", icon: "arrow.left.arrow.right.circle.fill")
    }
}

struct BudgetCard: View {
    var used: Double
    var limit: Double
    var body: some View {
        VStack(alignment: .leading) {
            CardView(title: "Budget Usage", value: "\(String(format: "$%.2f", used)) of \(String(format: "$%.2f", limit)) used", icon: "chart.bar.fill")
            ProgressView(value: used, total: limit)
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
                .padding(.horizontal)
        }
    }
}

struct BillsCard: View {
    var bills: [(String, String, String)]
    var body: some View {
        CardView(title: "Upcoming Bills", value: bills.map { "\($0.0): \($0.1) due \($0.2)" }.joined(separator: "\n"), icon: "calendar.badge.clock")
    }
}

struct GoalsCard: View {
    var goals: [(String, Double, Double)]
    var body: some View {
        VStack(alignment: .leading) {
            CardView(title: "Financial Goals", value: "", icon: "flag.fill")
            ForEach(goals, id: \.0) { goal in
                VStack(alignment: .leading) {
                    Text(goal.0).bold()
                    ProgressView(value: goal.1, total: goal.2)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .padding(.horizontal)
                }
            }
        }
    }
}

struct InvestmentsCard: View {
    var body: some View {
        CardView(title: "Investments", value: "View portfolio performance and asset allocation", icon: "chart.pie.fill")
    }
}

struct InsightsCard: View {
    var body: some View {
        CardView(title: "Insights", value: "AI-powered financial tips and trends", icon: "lightbulb.fill")
    }
}

struct SubscriptionStatusCard: View {
    var isPremiumUser: Bool
    var body: some View {
        CardView(title: "Subscription Status", value: isPremiumUser ? "Premium Active" : "Upgrade to Premium", icon: "star.fill")
    }
}

struct CardView: View {
    var title: String
    var value: String
    var icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .imageScale(.large)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            Text(value)
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.blue.cornerRadius(10))
    }
}

