import SwiftUI

struct PolicyView: View {
    // MARK: –– Inner “Card” Component
    private struct Card<Content: View>: View {
        let title: String
        let icon: String
        let content: Content
        
        init(title: String, icon: String, @ViewBuilder content: () -> Content) {
            self.title = title
            self.icon = icon
            self.content = content()
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                Label(title, systemImage: icon)
                    .font(.headline)
                
                content
                    .font(.body)
                    .lineSpacing(5)
                    .foregroundColor(.primary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Card(title: "Privacy Policy", icon: "hand.raised.fill") {
                    Text("""
This app does **not** collect or share any personal data. All real-time information is fetched anonymously from RIPTA’s public API and is not stored on this device or sent elsewhere.
""")
                }
                
                Card(title: "Terms of Service", icon: "doc.text.fill") {
                    Text("""
By using **RIPTA T**, you agree to use it for personal, non-commercial purposes only. All transit data is owned by RIPTA—please refer to their official terms if you wish to redistribute it.  

**Disclaimer:** This app is provided “as-is,” without warranty of any kind. We accept no responsibility for inaccurate arrival times or any consequences resulting from its use.
""")
                }
                
                Text("Last updated July 2025")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .background(Color(.secondarySystemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Privacy & Terms")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PolicyView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PolicyView()
        }
    }
}
