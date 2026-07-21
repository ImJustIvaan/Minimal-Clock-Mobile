import Foundation

struct TVCountdown: Identifiable, Decodable {
    let id: String
    let title: String
    let targetDate: Date

    enum CodingKeys: String, CodingKey {
        case id, title
        case targetDate = "target_date"
    }
}

private struct FollowRow: Decodable {
    let notify: Bool
    let countdowns: TVCountdown?
}

private struct PairingRow: Decodable {
    let code: String
    let accessToken: String?
    let refreshToken: String?

    enum CodingKeys: String, CodingKey {
        case code
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
    }
}

enum SupabaseTV {
    static let url = "https://mdnabqsrlsxioerlqeiw.supabase.co"
    static let anonKey =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kbmFicXNybHN4aW9lcmxxZWl3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI4ODI3NDIsImV4cCI6MjA5ODQ1ODc0Mn0.6hQ3RrCfG8Fm_fcnU1WKcMscApnNKTuOLx4LPmVjosA"

    static func fetchNotifiedCountdowns(accessToken: String) async throws -> [TVCountdown] {
        var components = URLComponents(string: "\(url)/rest/v1/countdown_follows")!
        components.queryItems = [
            URLQueryItem(name: "select", value: "notify,countdowns(id,title,target_date)"),
            URLQueryItem(name: "notify", value: "eq.true"),
        ]
        var request = URLRequest(url: components.url!)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let rows = try decoder.decode([FollowRow].self, from: data)
        return rows.compactMap { $0.countdowns }
    }

    /// Creates a fresh pairing row for this code. Anonymous insert is
    /// allowed by RLS (see supabase/schema.sql) — the random code itself is
    /// the capability/secret, same trust model as a password-reset link.
    static func createPairingCode(_ code: String) async throws {
        let request = try jsonRequest(
            path: "/rest/v1/tv_pairing_codes",
            method: "POST",
            body: ["code": code]
        )
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    /// Returns the access token once the phone/computer has confirmed
    /// pairing for this code, or nil if still pending.
    static func pollPairingCode(_ code: String) async throws -> String? {
        var components = URLComponents(string: "\(url)/rest/v1/tv_pairing_codes")!
        components.queryItems = [
            URLQueryItem(name: "select", value: "code,access_token,refresh_token"),
            URLQueryItem(name: "code", value: "eq.\(code)"),
        ]
        var request = URLRequest(url: components.url!)
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let rows = try JSONDecoder().decode([PairingRow].self, from: data)
        return rows.first?.accessToken
    }

    static func deletePairingCode(_ code: String) async {
        guard var request = try? jsonRequest(path: "/rest/v1/tv_pairing_codes?code=eq.\(code)", method: "DELETE", body: nil) else { return }
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        _ = try? await URLSession.shared.data(for: request)
    }

    private static func jsonRequest(path: String, method: String, body: [String: Any]?) throws -> URLRequest {
        var request = URLRequest(url: URL(string: "\(url)\(path)")!)
        request.httpMethod = method
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        return request
    }
}
