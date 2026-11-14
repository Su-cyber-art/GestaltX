// SPDX-License-Identifier: GPL-3.0-only
import Foundation

struct ModifiedParameter: Identifiable {
    let id: String
    let title: String
    let key: String
    let original: Any?
    let current: Any?
}

struct ParameterComparisonIssue: Identifiable {
    let title: String
    let message: String
    var id: String { title }
}

struct DeviceStatusReading {
    let readAt: Date
    let report: DeviceModificationReport
}

struct DeviceModificationReport {
    let changes: [ModifiedParameter]
    let issues: [ParameterComparisonIssue]
    let hasRecordedOriginals: Bool
    let unlockConfigured: Bool?

    init(snapshot: DocumentSnapshot) {
        let document = snapshot.document
        var changes: [ModifiedParameter] = []
        var issues: [ParameterComparisonIssue] = []
        var configured: Bool?

        func append(_ id: String, title: String, key: String, before: Any?, after: Any?) {
            switch (before, after) {
            case (nil, nil): return
            case (let a?, let b?) where GestaltDocument.valuesEqual(a, b): return
            default:
                changes.append(ModifiedParameter(id: id, title: title, key: key,
                                                  original: before, current: after))
            }
        }

        // Journals are written before the device file. Only a difference in the
        // freshly read document establishes a current modification.
        for (key, original) in snapshot.originals {
            append("CacheExtra/" + key, title: Self.title(for: key), key: key,
                   before: original.value, after: document.extra[key])
        }

        do {
            let current = try DeviceCacheOptions.flags(in: document)
            let capabilities = Capability.all.filter { Capability.oneClickUnlockIDs.contains($0.id) }
            configured = document.extra[GestaltKeys.regionCode] as? String == "LL"
                && current == .enabled
                && capabilities.allSatisfy { capability in
                    capability.keys.allSatisfy { key in
                        guard let value = document.extra[key] else { return false }
                        return GestaltDocument.valuesEqual(value, capability.enabled)
                    }
                }
            if let recorded = snapshot.cachedOptionsOriginal {
                let original = try recorded.flags(in: document)
                append("CacheData/green-tea", title: "Additional Options", key: "green-tea",
                       before: NSNumber(value: original.greenTea), after: NSNumber(value: current.greenTea))
                append("CacheData/not-green-tea", title: "Additional Options", key: "not-green-tea",
                       before: NSNumber(value: original.notGreenTea), after: NSNumber(value: current.notGreenTea))
            }
        } catch {
            issues.append(ParameterComparisonIssue(title: "Additional Options", message: error.localizedDescription))
        }
        if let recorded = snapshot.wapiOriginal {
            do {
                let original = try recorded.value(in: document)
                let current = try DeviceCacheOptions.wapi(in: document)
                append("CacheData/wapi", title: "WAPI", key: "wapi",
                       before: NSNumber(value: original), after: NSNumber(value: current))
            } catch {
                issues.append(ParameterComparisonIssue(title: "WAPI", message: error.localizedDescription))
            }
        }

        self.changes = changes.sorted { ($0.title, $0.id) < ($1.title, $1.id) }
        self.issues = issues
        hasRecordedOriginals = !snapshot.originals.isEmpty || snapshot.cachedOptionsOriginal != nil || snapshot.wapiOriginal != nil
        unlockConfigured = configured
    }

    private static func title(for key: String) -> String {
        switch key {
        case GestaltKeys.regionCode: "Region Code"
        case GestaltKeys.regionInfo, GestaltKeys.legacyRegionInfo: "Sales Region"
        case GestaltKeys.modelNumber: "Model Number"
        default: Capability.all.first { $0.keys.contains(key) }?.title ?? key
        }
    }
}
