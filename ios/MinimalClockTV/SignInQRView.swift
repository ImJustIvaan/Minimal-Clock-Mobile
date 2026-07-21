import SwiftUI

struct SignInQRView: View {
    @StateObject private var pairing = PairingManager()

    var body: some View {
        VStack(spacing: 24) {
            Text("Sign In")
                .font(.system(size: 32, weight: .semibold))

            if let qr = pairing.qrImage {
                qr
                    .interpolation(.none)
                    .resizable()
                    .frame(width: 280, height: 280)
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
                    .font(.system(size: 40, weight: .bold, design: .monospaced))
                    .tracking(6)
            }

            if let error = pairing.errorMessage {
                Text(error).foregroundColor(.red)
            }
        }
        .onAppear { pairing.start() }
        .onDisappear { pairing.stop() }
    }
}
