//
//  SettingsView.swift
//  todo-list
//
//  Created by 井上京佳 on 2026/04/01.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("soundEnabled") private var soundEnabled = true
    @AppStorage("hapticEnabled") private var hapticEnabled = true

    var body: some View {
        Form {
            Section {
                Toggle("Sound", isOn: $soundEnabled)
                Toggle("Haptic Feedback", isOn: $hapticEnabled)
            }

            Section("Widget") {
                NavigationLink("Widget Themes") {
                    WidgetThemeListView()
                }
            }

            Section("About") {
                LabeledContent("Version") {
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
