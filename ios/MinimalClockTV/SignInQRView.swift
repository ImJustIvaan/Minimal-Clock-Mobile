import AuthenticationServices
import CryptoKit
import SwiftUI

struct SignInQRView: View {
    @StateObject private var pairing = PairingManager()
    @State private var appleNonce: String?
    @State private var appleError: String?

    var body: some View {
        VStack(spacing: 24) {
            Text("Sign In")
                .font(.system(size: 32, weight: .semibold))

            SignInWithAppleButton(.signIn, onRequest: configureAppleRequest, onCompletion: handleAppleResult)
                .signInWithAppleButtonStyle(.white)
                .frame(width: 280, height: 56)

            if let error = appleError {
                Text(error).foregroundColor(.red)
            }

            HStack {
                Rectangle().frame(height: 1).foregroundColor(.secondary.opacity(0.3))
                Text("or").foregroundColor(.secondary)
                Rectangle().frame(height: 1).foregroundColor(.secondary.opacity(0.3))
            }
            .frame(width: 280)

            if let qr = pairing.qrImage {
                qr
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 200, height: 200)
                    .background(Color.white)
                    .cornerRadius(12)
            }

            VStack(spacing: 8) {
                Text("Scan the QR code, or go to")
                    .foregroundColor(.secondary)
                Text("time.ivaan.cc").fontWeight(.semibold)
                Text("and enter this code:")
                    .foregroundColor(.secondary)
                Text(pairing.code)
                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                    .tracking(6)
            }

            if let error = pairing.errorMessage {
                Text(error).foregroundColor(.red)
            }
        }
        .onAppear { pairing.start() }
        .onDisappear { pairing.stop() }
    }

    /// Apple gets the SHA-256 hash of a random nonce (as a replay-attack
    /// guard on their side); Supabase gets the raw original back alongside
    /// the identity token so it can verify the hash matches, per Supabase's
    /// native Sign in with Apple flow.
    private func configureAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let raw = randomNonce()
        appleNonce = raw
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(raw)
    }

    private func handleAppleResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .failure(let error):
            let nsError = error as NSError
            // User cancellation isn't a real error worth showing.
            if nsError.code != ASAuthorizationError.canceled.rawValue {
                appleError = "Sign in with Apple failed."
            }
        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = credential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8),
                let nonce = appleNonce
            else {
                appleError = "Sign in with Apple failed."
                return
            }
            Task {
                do {
                    let accessToken = try await SupabaseTV.signInWithApple(idToken: idToken, nonce: nonce)
                    TVSessionManager.shared.setToken(accessToken)
                } catch {
                    appleError = "Sign in with Apple failed."
                }
            }
        }
    }

    private func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            var random: UInt8 = 0
            _ = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
            if random < charset.count {
                result.append(charset[Int(random)])
                remaining -= 1
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8)).map { String(format: "%02x", $0) }.joined()
    }
}
