//
//  CustomTopBarView.swift
//  Finance
//
//  Created by Samuel Goergen on 2/5/25.
//

import SwiftUI

struct CustomTopBar: View {
    @Binding var isSidebarOpen: Bool

    var body: some View {
        HStack {
            Button(action: {
                withAnimation {
                    isSidebarOpen.toggle()
                }
            }) {
                Image(systemName: "person.circle")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            Text("MyFinanceApp")
                .font(.title2)
                .fontWeight(.bold)
            
            Spacer()
        }
        .padding()
        .background(Color.white)
        .shadow(radius: 3)
    }
}
