//
//  TransactionsView.swift
//  Finance
//
//  Created by Samuel Goergen on 2/3/25.
//

import SwiftUI

struct TransactionsView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Transactions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding()

                Spacer()

                Text("Your recent transactions will appear here.")
                    .foregroundColor(.gray)
                    .padding()
            }
            .navigationBarTitle("Transactions", displayMode: .inline)
            .navigationBarBackButtonHidden(true)
        }
    }
}

struct TransactionsView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsView()
    }
}
