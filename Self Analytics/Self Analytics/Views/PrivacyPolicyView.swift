//
//  PrivacyPolicyView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/11/25.
//

import SwiftUI

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

                Group {
                    Text("1. Introduction")
                        .font(.title2)
                        .bold()
                    Text("Your privacy is important to us. This Privacy Policy explains how Self Analytics collects, uses, and protects your information.")
                }

                Group {
                    Text("2. Information We Collect")
                        .font(.title2)
                        .bold()
                    Text("We may collect information about your device metrics, usage data, and any information you provide directly within the app.")
                }

                Group {
                    Text("3. How We Use Your Information")
                        .font(.title2)
                        .bold()
                    Text("Collected information is used to provide analytics, improve app performance, and enhance your experience. We do not sell your data to third parties.")
                }

                Group {
                    Text("4. Data Security")
                        .font(.title2)
                        .bold()
                    Text("We implement security measures to protect your data. However, no method of transmission over the internet or electronic storage is 100% secure.")
                }

                Group {
                    Text("5. Changes to This Policy")
                        .font(.title2)
                        .bold()
                    Text("We may update this Privacy Policy from time to time. Changes will be posted within the app.")
                }

                Group {
                    Text("6. Contact Us")
                        .font(.title2)
                        .bold()
                    Text("If you have any questions about this Privacy Policy, please contact us at support@selfanalytics.com.")
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
