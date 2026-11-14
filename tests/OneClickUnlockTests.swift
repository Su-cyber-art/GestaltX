// SPDX-License-Identifier: GPL-3.0-only
import Foundation

@MainActor @main struct OneClickUnlockTests {
    struct Failure: Error { let message: String }
    static func expect(_ condition: Bool, _ message: String) throws {
        if !condition { throw Failure(message: message) }
    }

    static let keys = [
        "A62OafQ85EJAiiqKn4agtg", "rb2tKZxlj0Gm2tBmUQSLqQ", "M1n2sAqf33NAOgZRGxQYBA",
        "XNCjqOupLM/S8fNyxRNQTA", "YgYIIViDt1kgzyIsIV61vA", "TusANsf9Lfe3P/9fIXXSrQ",
    ]

    static func fixture(uuid: String? = nil) throws -> GestaltDocument {
        let layout = MobileGestaltCacheLayout.originalProfile
        var cache = Data(count: layout.byteCount)
        cache[layout.greenTeaOffset] = 1
        cache[layout.wapiOffset!] = 1
        for index in [layout.greenTeaIndex, layout.notGreenTeaIndex, layout.wapiIndex!] {
            cache[layout.validityOffset(for: index)] = 1
        }
        let extra: [String: Any] = [
            GestaltKeys.regionCode: "CH", GestaltKeys.legacyRegionInfo: "CH/A",
            GestaltKeys.productType: "iPhone19,7", GestaltKeys.hardwareModel: "V64sAP",
            GestaltKeys.cpu: "t8160", GestaltKeys.modelNumber: "A3718",
            GestaltKeys.siriMode: NSNumber(value: 3),
            "K/R1GfGfCkXvEhaPS2Vrng": NSNumber(value: 4),
            keys[0]: NSNumber(value: false), keys[1]: NSNumber(value: 0),
            "unrelated": Data([1, 3, 5]),
            GestaltKeys.artwork: ["ArtworkDeviceSubType": 2868, "ArtworkDeviceProductDescription": "Fixture"],
        ]
        let root: [String: Any] = ["CacheExtra": extra, "CacheData": cache,
                                  "CacheUUID": uuid ?? layout.uuid, "CacheVersion": "fixture"]
        return try GestaltDocument(data: PropertyListSerialization.data(fromPropertyList: root, format: .binary, options: 0))
    }

    static func manager(_ document: GestaltDocument) throws -> UnlockManagerHarness {
        UnlockManagerHarness(snapshot: DocumentSnapshot(data: try document.encoded(), document: document,
                                                        source: .local, name: "fixture"))
    }

    static func main() async throws {
        let original = try fixture()
        let model = try manager(original)
        try expect(model.stageOneClickUnlock(), "Unlock can be staged on a supported cache")
        let edited = model.preview!
        try expect(Set(model.changeKeys) == Set(keys + [GestaltKeys.regionCode]),
                   "The bundle changes exactly six capability fields and the region code")
        for key in keys {
            try expect(GestaltDocument.valuesEqual(edited.extra[key]!, NSNumber(value: 1)),
                       "Each capability is an integer override of 1")
        }
        try expect(edited.extra[GestaltKeys.regionCode] as? String == "LL", "The region code becomes US")
        try expect(try DeviceCacheOptions.flags(in: edited) == .enabled, "The two additional-option flags are enabled")
        try expect(try DeviceCacheOptions.wapi(in: edited), "WAPI is preserved")
        try expect(model.cacheDataChanges.count == 2 && model.changeCount == 9, "Review includes both binary changes")
        var restored = edited
        for key in keys + [GestaltKeys.regionCode] { restored.set(original.extra[key], for: key) }
        try restored.setCacheOptions(.restricted)
        try expect(restored.matches(original), "All hardware, sales region, Siri mode, and unrelated bytes are preserved")
        try expect(model.snapshot!.document.matches(original), "Staging does not change the loaded baseline")
        try expect(model.stageOneClickUnlock() && model.preview!.matches(edited), "Repeated staging is idempotent")
        let alreadyApplied = try manager(edited)
        try expect(alreadyApplied.stageOneClickUnlock() && alreadyApplied.changeCount == 0,
                   "An already configured device does not produce changes")

        let pending = try manager(original)
        pending.working!.set("edited", for: "unrelated")
        pending.choices["aod"] = .enable
        pending.choices["ai"] = .removeAdded
        pending.regionID = "HK"
        pending.regionCodeID = "JP"
        try expect(pending.stageOneClickUnlock(), "The bundle can be combined with staged edits")
        try expect(pending.preview!.extra[GestaltKeys.legacyRegionInfo] as? String == "ZA/A",
                   "A separately staged sales-region edit is retained for review")
        try expect(pending.preview!.extra[GestaltKeys.regionCode] as? String == "LL",
                   "The bundle supersedes a conflicting region-code choice")
        try expect(pending.preview!.extra["unrelated"] as? String == "edited" && pending.choices["aod"] == .enable,
                   "Unrelated edits and preset choices survive staging")
        try expect(pending.choices["ai"] == .enable, "Conflicting bundle choices are replaced")

        let unsupported = try manager(fixture(uuid: "00000000-0000-0000-0000-000000000001"))
        unsupported.regionCodeID = "JP"
        unsupported.choices["ai"] = .disable
        let previous = unsupported.working!
        try expect(!unsupported.stageOneClickUnlock() && unsupported.lastError != nil,
                   "An unknown cache layout returns an explicit error")
        try expect(unsupported.working!.matches(previous) && unsupported.regionCodeID == "JP" &&
                   unsupported.choices == ["ai": .disable] && unsupported.cacheOptionChoice == .keep,
                   "A failed cache read leaves the whole staged state intact")
        let busy = try manager(original)
        busy.isBusy = true
        try expect(!busy.stageOneClickUnlock() && busy.preview!.matches(original), "An active operation cannot be edited")

        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let device = directory.appendingPathComponent("device.plist")
        let backups = directory.appendingPathComponent("backups")
        try original.encoded().write(to: device)
        let store = GestaltFileStore(deviceURL: device, backupDirectory: backups, deviceID: "fixture",
                                     acquire: { 0 }, release: { _ in })
        let loaded = try await store.loadDevice()
        let staged = UnlockManagerHarness(snapshot: loaded)
        try expect(staged.stageOneClickUnlock(), "The device snapshot accepts the same preset")
        try expect(GestaltDocument(data: Data(contentsOf: device)).matches(original), "Staging performs no device write")
        let committed = try await store.commit(staged.preview!, expected: loaded)
        try expect(GestaltDocument(data: Data(contentsOf: device)).matches(committed.document), "Normal commit verifies readback")
        let records = try await store.backups()
        try expect(records.contains { $0.reason == "Before applying" }, "Normal commit creates a pre-write backup")
        let reopened = GestaltFileStore(deviceURL: device, backupDirectory: backups, deviceID: "fixture",
                                        acquire: { 0 }, release: { _ in })
        let saved = try await reopened.loadDevice()
        var recovery = saved.document
        for key in keys + [GestaltKeys.regionCode] { recovery.set(saved.originalValue(for: key), for: key) }
        try recovery.setCacheOptions(saved.originalCachedOptionFlags())
        try expect(recovery.matches(original), "Persisted originals restore absent fields, typed values, and cache flags")
        _ = try await reopened.commit(recovery, expected: saved)
        try expect(GestaltDocument(data: Data(contentsOf: device)).matches(original), "Restoration recovers the original file")
        print("PASS: exact unlock bundle, idempotence, pending edits, atomic failure, backup, readback and original restoration.")
    }
}
