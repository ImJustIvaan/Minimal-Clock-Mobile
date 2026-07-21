import SwiftUI

/// The TV keeps its own settings (not synced from the phone) — different
/// device, different room, no assumption you'd want the same preferences.
struct SettingsView: View {
    @AppStorage("tv_use24Hour") private var use24Hour = false
    @ObservedObject private var session = TVSessionManager.shared

    var body: some View {
        Form {
            Toggle("24-hour format", isOn: $use24Hour)

            if session.isSignedIn {
                Button("Sign Out", role: .destructive) {
                    session.signOut()
                }
            }
        }
        .frame(maxWidth: 600)
    }
}
