// SPDX-License-Identifier: GPL-3.0-only
import Foundation
func L(_ key: String) -> String { NSLocalizedString(key, comment: "") }

enum GestaltBrand {
    /// Maintainer of this fork; every in-app repository link points here.
    static let maintainer = "Su-cyber-art"
    /// Author of the original GestaltX, credited in About and the licenses.
    static let originalAuthor = "huamidev"
    static let developer = maintainer
    static let repositoryName = "Su-cyber-art/GestaltX"
    static let github = URL(string: "https://github.com/Su-cyber-art")!
    static let projects = URL(string: "https://github.com/Su-cyber-art/GestaltX")!
    static let releases = URL(string: "https://github.com/Su-cyber-art/GestaltX/releases")!
    static let buildDate: String = {
        guard let url = Bundle.main.url(forResource: "BuildDate", withExtension: "txt"),
              let date = try? String(contentsOf: url, encoding: .utf8) else { return "2026-11-09" }
        return date.trimmingCharacters(in: .whitespacesAndNewlines)
    }()
    static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    static let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
}
