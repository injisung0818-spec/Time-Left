import Foundation
import SwiftUI

enum UpdateCheckStatus {
    case checking, upToDate, outdated, failed

    var title: String {
        switch self {
        case .checking: return "확인 중…"
        case .upToDate: return "최신 버전입니다"
        case .outdated: return "최신 버전이 아닙니다"
        case .failed: return "업데이트 확인 실패"
        }
    }

    var color: Color {
        switch self {
        case .checking: return .secondary
        case .upToDate: return .green
        case .outdated: return .orange
        case .failed: return .red
        }
    }
}

@MainActor
final class GitHubReleaseChecker: ObservableObject {
    @Published private(set) var status: UpdateCheckStatus = .checking
    @Published private(set) var latestVersion: String?

    private let releasesURL = URL(string: "https://api.github.com/repos/injisung0818-spec/Time-Left/releases/latest")!

    init() { checkForLatestRelease() }

    func checkForLatestRelease() {
        status = .checking
        Task {
            do {
                var request = URLRequest(url: releasesURL)
                request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
                request.timeoutInterval = 10
                let (data, response) = try await URLSession.shared.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
                let version = release.tagName.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
                guard !version.isEmpty else { throw URLError(.cannotParseResponse) }
                latestVersion = version
                status = Self.isVersion(version, newerThan: currentVersion) ? .outdated : .upToDate
            } catch {
                status = .failed
            }
        }
    }

    private var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    }

    private static func isVersion(_ lhs: String, newerThan rhs: String) -> Bool {
        let left = lhs.split(separator: ".").map { Int($0) ?? 0 }
        let right = rhs.split(separator: ".").map { Int($0) ?? 0 }
        for index in 0..<max(left.count, right.count) {
            let a = index < left.count ? left[index] : 0
            let b = index < right.count ? right[index] : 0
            if a != b { return a > b }
        }
        return false
    }

    private struct GitHubRelease: Decodable {
        let tagName: String
        enum CodingKeys: String, CodingKey { case tagName = "tag_name" }
    }
}
