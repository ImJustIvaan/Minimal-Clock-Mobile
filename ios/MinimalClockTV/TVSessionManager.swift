import Foundation
import Combine

/// Holds the Supabase session token obtained via the QR pairing flow.
/// tvOS has no keyboard-friendly way to type an email/password, so sign-in
/// only happens by confirming a pairing code on a phone/computer (see
/// PairingManager) — there's no username/password entry on the TV itself.
final class TVSessionManager: ObservableObject {
    static let shared = TVSessionManager()

    @Published private(set) var accessToken: String?

    private let defaults = UserDefaults.standard
    private let key = "supabase_access_token"

    private init() {
        accessToken = defaults.string(forKey: key)
    }

    var isSignedIn: Bool { accessToken != nil }

    func setToken(_ token: String) {
        accessToken = token
        defaults.set(token, forKey: key)
    }

    func signOut() {
        accessToken = nil
        defaults.removeObject(forKey: key)
    }
}
