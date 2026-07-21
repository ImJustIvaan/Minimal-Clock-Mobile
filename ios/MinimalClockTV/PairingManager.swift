import Foundation
import CoreImage.CIFilterBuiltins
import SwiftUI
import Combine

@MainActor
final class PairingManager: ObservableObject {
    @Published var code: String = ""
    @Published var qrImage: Image?
    @Published var errorMessage: String?

    private var pollTask: Task<Void, Never>?

    func start() {
        let newCode = Self.generateCode()
        code = newCode
        errorMessage = nil
        qrImage = Self.makeQRImage(for: "https://time.ivaan.cc/?pair=\(newCode)")

        pollTask?.cancel()
        pollTask = Task {
            do {
                try await SupabaseTV.createPairingCode(newCode)
            } catch {
                errorMessage = "Couldn't start pairing. Check your connection."
                return
            }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                if Task.isCancelled { return }
                if let token = try? await SupabaseTV.pollPairingCode(newCode), let token {
                    TVSessionManager.shared.setToken(token)
                    await SupabaseTV.deletePairingCode(newCode)
                    return
                }
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
    }

    private static func generateCode() -> String {
        let chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789" // no ambiguous 0/O/1/I
        return String((0..<6).map { _ in chars.randomElement()! })
    }

    private static func makeQRImage(for string: String) -> Image? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return Image(decorative: cgImage, scale: 1)
    }
}
