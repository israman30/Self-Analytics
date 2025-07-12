//
//  ContactSupport.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/11/25.
//

import SwiftUI

struct ContactSupport: View {
    private let supportEmail = "israelmanzo814@gmail.com" 
    @State private var showCopiedAlert = false
    
    private var emailSupport: String {
        "mailto:\(supportEmail)?subject=Support%20Request"
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text(ContactSupportLabel.contactSupport)
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
            
            Text(ContactSupportLabel.contactMessage)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            HStack {
                Image(systemName: ContactSupportLabel.Icon.envelope)
                Text(supportEmail)
                    .foregroundColor(.blue)
                    .onTapGesture {
                        UIPasteboard.general.string = supportEmail
                        showCopiedAlert = true
                    }
                Spacer()
                Button(action: {
                    if let url = URL(string: emailSupport) {
                        UIApplication.shared.open(url)
                    }
                }) {
                    Image(systemName: ContactSupportLabel.Icon.square_and_pencil)
                        .foregroundColor(.blue)
                }
                .accessibilityLabel(ContactSupportLabel.emailSupport)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            Spacer()
        }
        .alert(isPresented: $showCopiedAlert) {
            Alert(
                title: Text(ContactSupportLabel.alertTitle),
                message: Text(ContactSupportLabel.alertMessage),
                dismissButton: .default(Text(ContactSupportLabel.ok))
            )
        }
    }
    
    private func openEmail(urlString: String) {
        let url = URL(string: urlString)
        if let url = url {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

#Preview {
    ContactSupport()
}
