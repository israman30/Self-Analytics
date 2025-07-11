//
//  ContactSupport.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/11/25.
//

import SwiftUI

struct ContactSupport: View {
    let supportEmail = "israelmanzo814@gmail.com" // Replace with your real support email
    @State private var showCopiedAlert = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Contact Support")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            Text("If you have any questions, issues, or feedback, please reach out to our support team. We're here to help!")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack {
                Image(systemName: "envelope")
                Text(supportEmail)
                    .foregroundColor(.blue)
                    .onTapGesture {
                        UIPasteboard.general.string = supportEmail
                        showCopiedAlert = true
                    }
                Spacer()
                Button(action: {
                    let email = "mailto:\(supportEmail)?subject=Support%20Request"
                    if let url = URL(string: email) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Image(systemName: "square.and.pencil")
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("Email Support")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            Spacer()
        }
        .alert(isPresented: $showCopiedAlert) {
            Alert(title: Text("Copied!"), message: Text("Support email copied to clipboard."), dismissButton: .default(Text("OK")))
        }
    }
}

#Preview {
    ContactSupport()
}
