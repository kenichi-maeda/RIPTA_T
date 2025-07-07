// SettingsView.swift

import SwiftUI

struct SettingsView: View {
    // Read your app’s version from Info.plist
    private let appVersion = Bundle.main
        .infoDictionary?["CFBundleShortVersionString"] as? String
        ?? "1.0"

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                }

                Section {
                    NavigationLink("Privacy Policy & Terms") {
                        PolicyView()
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
