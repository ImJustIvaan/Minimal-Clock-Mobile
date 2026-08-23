import Foundation

struct WatchCountdown: Identifiable, Decodable {
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
    let countdowns: WatchCountdown?
}

enum SupabaseWatch {
    static let url = "https://mdnabqsrlsxioerlqeiw.supabase.co"
    static let anonKey =
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1kbmFicXNybHN4aW9lcmxxZWl3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI4ODI3NDIsImV4cCI6MjA5ODQ1ODc0Mn0.6hQ3RrCfG8Fm_fcnU1WKcMscApnNKTuOLx4LPmVjosA"

    /// Fetches the countdowns the signed-in user has notifications turned on
    /// for, using their session token synced from the phone. RLS resolves
    /// the user from that token, so no explicit user_id filter is needed.
    static func fetchNotifiedCountdowns(accessToken: String) async throws -> [WatchCountdown] {
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

    /// Removes the signed-in user's own follow row for a countdown — RLS
    /// scopes this to rows where auth.uid() = user_id, so filtering by
    /// countdown_id alone (authenticated as that user) is sufficient,
    /// mirroring the phone app's CountdownRepository.unfollow.
    static func unfollowCountdown(accessToken: String, countdownId: String) async throws {
        var request = URLRequest(
            url: URL(string: "\(url)/rest/v1/countdown_follows?countdown_id=eq.\(countdownId)")!
        )
        request.httpMethod = "DELETE"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }
}
