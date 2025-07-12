//
//  TermsOfServiceView.swift
//  Self Analytics
//
//  Created by Israel Manzo on 7/11/25.
//

import SwiftUI

struct TermsSection: Identifiable, Hashable {
    var id: String { title }
    let title: String
    let message: String
}

struct TermsOfServiceLabels {
    static let sections: [TermsSection] = [
        TermsSection(title: "1. Acceptance of Terms", message: "By using Self Analytics, you agree to these Terms of Service. If you do not agree, please do not use the app."),
        TermsSection(title: "2. Use of the App", message: "You may use Self Analytics for personal, non-commercial purposes only. You agree not to misuse the app or attempt to access it in unauthorized ways."),
        TermsSection(title: "3. Intellectual Property", message: "All content and features in Self Analytics are the property of the app developer and are protected by copyright laws."),
        TermsSection(title: "4. Disclaimer of Warranties", message: "Self Analytics is provided 'as is' without warranties of any kind. We do not guarantee the accuracy or reliability of the app's data."),
        TermsSection(title: "5. Limitation of Liability", message: "We are not liable for any damages arising from your use of Self Analytics, to the maximum extent permitted by law."),
        TermsSection(title: "6. Changes to Terms", message: "We may update these Terms of Service from time to time. Changes will be posted within the app."),
        TermsSection(title: "7. Contact Us", message: "If you have questions about these Terms, please contact us at appstore.com.")
    ]
    static let title = "Terms of Service"
    static let dateString = "Effective Date: July 11, 2025"
    
    struct Icon {
        static let xmark_circle = "xmark.circle"
    }
}

struct TermsOfServiceView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    Text(TermsOfServiceLabels.title)
                        .font(.largeTitle)
                        .bold()
                        .padding(.bottom, 10)
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: TermsOfServiceLabels.Icon.xmark_circle)
                            .font(.title)
                    }
                }
                Text(TermsOfServiceLabels.dateString)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                ForEach(TermsOfServiceLabels.sections, id: \.self) { section in
                    Group {
                        Text(section.title)
                            .font(.title2)
                            .bold()
                        Text(section.message)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(TermsOfServiceLabels.title)
    }
}

#Preview {
    TermsOfServiceView()
}
