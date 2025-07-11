//
//  PrivacyPolicyView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/11/25.
//

import SwiftUI

struct Privacy: Identifiable, Hashable {
    var id: String {UUID().uuidString }
    let title: String
    let message: String
}

struct PrivacyPolicyLabels {
    static let policies: [Privacy] = [
        Privacy(title: "1. Introduction", message: "Your privacy is important to us. This Privacy Policy explains how Self Analytics collects, uses, and protects your information."),
        Privacy(title: "2. Information We Collect", message: "We may collect information about your device metrics, usage data, and any information you provide directly within the app."),
        Privacy(title: "3. How We Use Your Information", message: "Collected information is used to provide analytics, improve app performance, and enhance your experience. We do not sell your data to third parties."),
        Privacy(title: "4. Data Security", message: "We implement security measures to protect your data. However, no method of transmission over the internet or electronic storage is 100% secure."),
        Privacy(title: "5. Changes to This Policy", message: "We may update this Privacy Policy from time to time. Changes will be posted within the app."),
        Privacy(title: "6. Contact Us", message: "If you have any questions about this Privacy Policy, please contact us at appstore.com.")
    ]
    
    static let privacyPolicy = "Privacy Policy"
    static let dateString = "Effective Date: July 11, 2025"
    
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.largeTitle)
                    .bold()
                    .padding(.bottom, 10)
                
                Text("Effective Date: July 11, 2025")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ForEach(PrivacyPolicyLabels.policies, id: \.self) { text in
                    Group {
                        Text(text.title)
                            .font(.title2)
                            .bold()
                        Text(text.message)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
    }
}

#Preview {
    PrivacyPolicyView()
}
