import Foundation
import WatchConnectivity
import Combine

/// Receives the signed-in user's Supabase session and a few display settings
/// from the phone app (sent via the `watch_connectivity` Flutter plugin's
/// applicationContext API) and republishes them for SwiftUI views.
final class PhoneSyncManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneSyncManager()

    @Published var accessToken: String?
    @Published var use24Hour: Bool = false
    @Published var timezoneId: String = ""

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let accessToken = "supabase_access_token"
        static let use24Hour = "use24Hour"
        static let timezoneId = "selectedTimezone"
    }

    private override init() {
        super.init()
        accessToken = defaults.string(forKey: Keys.accessToken)
        use24Hour = defaults.bool(forKey: Keys.use24Hour)
        timezoneId = defaults.string(forKey: Keys.timezoneId) ?? ""
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Pick up whatever the phone last sent, in case we launched after it.
        applyContext(session.receivedApplicationContext)
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        applyContext(applicationContext)
    }

    private func applyContext(_ context: [String: Any]) {
        DispatchQueue.main.async {
            if let token = context["accessToken"] as? String, !token.isEmpty {
                self.accessToken = token
                self.defaults.set(token, forKey: Keys.accessToken)
            }
            if let use24 = context["use24Hour"] as? Bool {
                self.use24Hour = use24
                self.defaults.set(use24, forKey: Keys.use24Hour)
            }
            if let tz = context["selectedTimezone"] as? String {
                self.timezoneId = tz
                self.defaults.set(tz, forKey: Keys.timezoneId)
            }
        }
    }
}
