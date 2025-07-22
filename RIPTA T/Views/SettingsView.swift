//
//  SettingsView.swift
//  RIPTA T
//
//  Created by Kenichi Maeda on 6/22/25.
//


import SwiftUI

struct SettingsView: View {
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"

    @AppStorage("appearance") private var appearanceRaw = Appearance.system.rawValue

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Appearance")) {
                    Picker("Theme", selection: $appearanceRaw) {
                        ForEach(Appearance.allCases) { style in
                            Text(style.title).tag(style.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

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
