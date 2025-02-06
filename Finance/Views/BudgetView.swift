//
//  TransactionsView.swift
//  Finance
//
//  Created by Samuel Goergen on 2/3/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct BudgetView: View {
    @StateObject private var budgetManager = BudgetManager()
    @State private var userID: String = Auth.auth().currentUser?.uid ?? ""
    @Binding var isSidebarOpen: Bool  // Provided by MainTabView

    // State for new category inputs
    @State private var newCategoryName: String = ""
    @State private var newCategoryPlanned: String = ""

    var body: some View {
        // No extra NavigationView wrapper here—MainTabView handles navigation/offset
        VStack(spacing: 0) {
            // Top bar with sidebar toggle
            CustomTopBar(isSidebarOpen: $isSidebarOpen)
            
            // Income & Frequency input section (existing component)
            BudgetInputView(budgetManager: budgetManager)
                .padding(.horizontal)
                .padding(.top)
            
            // Spreadsheet-like table for budget categories
            VStack(spacing: 0) {
                // Header row
                HStack {
                    Text("Category")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Planned")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Text("Actual")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                
                Divider()
                
                // Data rows: one row per category
                ForEach(budgetManager.categories) { category in
                    HStack {
                        Text(category.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(String(format: "$%.2f", category.amount))
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("-") // Placeholder for actual spending
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                }
            }
            .background(Color.white)
            .cornerRadius(10)
            .shadow(radius: 5)
            .padding()
            
            // Input row for adding a new category
            HStack {
                TextField("New Category", text: $newCategoryName)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                
                TextField("Planned", text: $newCategoryPlanned)
                    .keyboardType(.decimalPad)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                
                Button(action: {
                    if let planned = Double(newCategoryPlanned), !newCategoryName.isEmpty {
                        budgetManager.addCategory(name: newCategoryName, amount: planned, isPercentage: false)
                        newCategoryName = ""
                        newCategoryPlanned = ""
                    }
                }) {
                    Text("Add")
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .onAppear {
            if !userID.isEmpty {
                budgetManager.fetchBudgetData(userID: userID)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}








struct BudgetInputView: View {
    @ObservedObject var budgetManager: BudgetManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Income & Frequency")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                TextField("Enter income", value: $budgetManager.income, formatter: NumberFormatter())
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 3)
                
                Picker("Frequency", selection: $budgetManager.frequency) {
                    ForEach(BudgetFrequency.allCases, id: \ .self) { freq in
                        Text(freq.rawValue.capitalized)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 3)
            }
            
            Button(action: {
                budgetManager.saveBudgetData()
            }) {
                Text("Save Income")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 3)
            }
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct CategoryListView: View {
    @ObservedObject var budgetManager: BudgetManager
    @State private var newCategoryName: String = ""
    @State private var newCategoryAmount: Double = 0.0
    @State private var isPercentage: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Budget Categories")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                TextField("Category Name", text: $newCategoryName)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 3)
                
                TextField("Amount", value: $newCategoryAmount, formatter: NumberFormatter())
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 3)
                
                Toggle("%", isOn: $isPercentage)
                    .labelsHidden()
            }
            
            Button(action: {
                budgetManager.addCategory(name: newCategoryName, amount: newCategoryAmount, isPercentage: isPercentage)
                newCategoryName = ""
                newCategoryAmount = 0.0
                isPercentage = false
            }) {
                Text("Add Category")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .shadow(radius: 3)
            }
            
            List {
                ForEach(budgetManager.categories) { category in
                    HStack {
                        Text(category.name)
                            .fontWeight(.bold)
                        Spacer()
                        Text(category.displayAmount(income: budgetManager.income))
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 3)
                }
                .onDelete(perform: budgetManager.removeCategory)
            }
            .listStyle(PlainListStyle())
        }
        .padding()
        .background(Color(.systemGray5))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

class BudgetManager: ObservableObject {
    @Published var income: Double = 0.0
    @Published var frequency: BudgetFrequency = .monthly
    @Published var categories: [BudgetCategory] = []
    private let db = Firestore.firestore()
    
    func fetchBudgetData(userID: String) {
        let userRef = db.collection("users").document(userID)
        
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                let data = document.data()
                DispatchQueue.main.async {
                    self.income = data?["income"] as? Double ?? 0.0
                    self.frequency = BudgetFrequency(rawValue: data?["frequency"] as? String ?? "monthly") ?? .monthly
                    self.categories = (data?["categories"] as? [[String: Any]])?.compactMap { BudgetCategory(from: $0) } ?? []
                }
            }
        }
    }
    
    func saveBudgetData() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("users").document(userID)
        
        let budgetData: [String: Any] = [
            "income": income,
            "frequency": frequency.rawValue,
            "categories": categories.map { $0.toDictionary() }
        ]
        
        userRef.setData(budgetData, merge: true)
    }
    
    func addCategory(name: String, amount: Double, isPercentage: Bool) {
        let category = BudgetCategory(name: name, amount: amount, isPercentage: isPercentage)
        categories.append(category)
        saveBudgetData()
    }
    
    func removeCategory(at offsets: IndexSet) {
        categories.remove(atOffsets: offsets)
        saveBudgetData()
    }
}

struct BudgetCategory: Identifiable {
    var id = UUID()
    var name: String
    var amount: Double
    var isPercentage: Bool

    func displayAmount(income: Double) -> String {
        if isPercentage {
            return "\(amount)% (\(String(format: "$%.2f", (amount / 100) * income)))"
        } else {
            return String(format: "$%.2f", amount)
        }
    }

    func toDictionary() -> [String: Any] {
        return ["name": name, "amount": amount, "isPercentage": isPercentage]
    }

    init(name: String, amount: Double, isPercentage: Bool) {
        self.name = name
        self.amount = amount
        self.isPercentage = isPercentage
    }

    init?(from dictionary: [String: Any]) {
        guard let name = dictionary["name"] as? String,
              let amount = dictionary["amount"] as? Double,
              let isPercentage = dictionary["isPercentage"] as? Bool else { return nil }

        self.name = name
        self.amount = amount
        self.isPercentage = isPercentage
    }
}

enum BudgetFrequency: String, CaseIterable {
    case weekly, biweekly, monthly, yearly
}

