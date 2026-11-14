// SPDX-License-Identifier: GPL-3.0-only
import Foundation

@MainActor @main struct DeviceModificationStatusTests {
    struct Failure: Error { let message: String }
    static func expect(_ condition: Bool, _ message: String) throws {
        if !condition { throw Failure(message: message) }
    }

    static func fixture() throws -> GestaltDocument {
        let layout = MobileGestaltCacheLayout.originalProfile
        var data = Data(count: layout.byteCount)
        data[layout.greenTeaOffset] = 1
        data[layout.wapiOffset!] = 1
        for index in [layout.greenTeaIndex, layout.notGreenTeaIndex, layout.wapiIndex!] {
            data[layout.validityOffset(for: index)] = 1
        }
        let root: [String: Any] = [
            "CacheUUID": layout.uuid, "CacheVersion": "fixture", "CacheData": data,
            "CacheExtra": [GestaltKeys.regionCode: "CH", GestaltKeys.legacyRegionInfo: "CH/A",
                           "A62OafQ85EJAiiqKn4agtg": NSNumber(value: false),
                           "unrelated": "original"],
        ]
        return try GestaltDocument(data: PropertyListSerialization.data(fromPropertyList: root, format: .binary, options: 0))
    }

    static func main() async throws {
        let original = try fixture()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let device = directory.appendingPathComponent("device.plist")
        try original.encoded().write(to: device)
        let store = GestaltFileStore(deviceURL: device, backupDirectory: directory.appendingPathComponent("backups"),
                                     deviceID: "fixture", acquire: { 0 }, release: { _ in })
        let initial = try await store.loadDevice()
        let model = DeviceStatusHarness(snapshot: initial, files: store)
        try expect(!model.deviceStatus!.report.hasRecordedOriginals && model.deviceStatus!.report.changes.isEmpty,
                   "A first reading does not invent original values or modifications")
        try expect(model.deviceStatus!.report.unlockConfigured == false, "The current cache has not been configured")
        let initialRead = model.deviceStatus!.readAt
        try expect(model.stageOneClickUnlock(), "Stage the unlock bundle")
        try expect(model.changeCount == 9 && model.deviceStatus!.report.changes.isEmpty,
                   "Nine pending changes do not appear as applied device changes")
        try expect(model.deviceStatus!.readAt == initialRead, "Staging does not change the last device-read time")
        await model.apply()
        try expect(model.lastError == nil && model.changeCount == 0 && model.deviceStatus!.report.changes.count == 9,
                   "Verified application immediately publishes nine applied changes")
        try expect(model.deviceStatus!.report.unlockConfigured == true, "The current device configuration is complete")
        let ids = Set(model.deviceStatus!.report.changes.map(\.id))
        try expect(ids.contains("CacheData/green-tea") && ids.contains("CacheData/not-green-tea"),
                   "Both decoded binary flags appear with current values")

        for capability in Capability.all where Capability.oneClickUnlockIDs.contains(capability.id) {
            await model.restoreCapability(capability)
        }
        try expect(model.deviceStatus!.report.changes.count == 3, "Restoring six capabilities updates status immediately")
        model.regionCodeID = "CN"
        await model.apply()
        await model.restoreCacheOption()
        try expect(model.lastError == nil && model.deviceStatus!.report.changes.isEmpty &&
                   model.deviceStatus!.report.hasRecordedOriginals,
                   "Restored values are not reported as modified merely because a journal exists")
        try expect(model.snapshot!.document.matches(original), "The complete original configuration is restored")

        // A failed write can leave an original-value entry. Its absent current key is not a change.
        var failedWriteRecord = initial
        failedWriteRecord.originals["never-written"] = OriginalField(value: nil)
        try expect(DeviceModificationReport(snapshot: failedWriteRecord).changes.isEmpty,
                   "A pre-write record does not prove that the write happened")
        var typedCurrent = original
        typedCurrent.set(NSNumber(value: 0), for: "A62OafQ85EJAiiqKn4agtg")
        typedCurrent.set(nil, for: "unrelated")
        let typed = DocumentSnapshot(data: try typedCurrent.encoded(), document: typedCurrent, source: .device, name: "fixture",
                                     originals: ["A62OafQ85EJAiiqKn4agtg": OriginalField(value: NSNumber(value: false)),
                                                 "unrelated": OriginalField(value: "original")])
        let typedReport = DeviceModificationReport(snapshot: typed)
        try expect(typedReport.changes.count == 2 && typedReport.changes.contains { $0.key == "unrelated" && $0.current == nil },
                   "Type-only differences and deleted parameters remain visible")

        let baseline = try await store.loadDevice()
        let editing = DeviceStatusHarness(snapshot: baseline, files: store)
        editing.choices["pencil"] = .enable
        editing.working!.set("pending", for: "unrelated")
        let pendingDocument = editing.working!
        let pendingChoices = editing.choices
        let pendingCount = editing.changeCount
        let external = DeviceStatusHarness(snapshot: baseline, files: store)
        try expect(external.stageOneClickUnlock(), "Prepare an external device change")
        await external.apply()
        let bytesBeforeRefresh = try Data(contentsOf: device)
        await editing.refreshDeviceStatus()
        try expect(editing.deviceStatus!.report.changes.count == 9 && editing.deviceStatus!.report.unlockConfigured == true,
                   "Refreshing reports the actual file even while edits are pending")
        try expect(editing.working!.matches(pendingDocument) && editing.choices == pendingChoices &&
                   editing.changeCount == pendingCount && editing.snapshot!.document.matches(baseline.document),
                   "Refresh preserves pending edits and their original conflict-detection baseline")
        try expect(Data(contentsOf: device) == bytesBeforeRefresh, "Status refresh never writes the device cache")
        let observedAt = editing.deviceStatus!.readAt
        editing.clearStaged()
        try expect(editing.deviceStatus!.readAt == observedAt && editing.deviceStatus!.report.changes.count == 9,
                   "Discarding edits does not replace a fresh device reading with an old editing snapshot")
        await editing.refreshDeviceStatus()
        try expect(editing.snapshot!.document.matches(baseline.document) && editing.deviceStatus!.report.changes.count == 9,
                   "Background status reads leave the editing baseline intact even without staged changes")

        let lastSuccessfulRead = editing.deviceStatus!.readAt
        try Data("invalid plist".utf8).write(to: device)
        editing.isBusy = true
        await editing.refreshDeviceStatus()
        try expect(editing.deviceStatusError == nil && editing.deviceStatus!.readAt == lastSuccessfulRead,
                   "Polling waits for an active operation instead of interleaving reads and writes")
        editing.isBusy = false
        await editing.refreshDeviceStatus()
        try expect(editing.deviceStatusError != nil && !editing.deviceAccessible && !editing.isBusy,
                   "A failed read is exposed and releases the busy state")
        try expect(editing.deviceStatus!.readAt == lastSuccessfulRead && editing.deviceStatus!.report.changes.count == 9,
                   "A failed read retains the dated last result instead of reporting false freshness or no changes")
        try bytesBeforeRefresh.write(to: device)
        await editing.refreshDeviceStatus()
        try expect(editing.deviceStatusError == nil && editing.deviceAccessible,
                   "A later successful reading clears the read failure")

        let beforeCancellation = editing.deviceStatus!.readAt
        let task = Task { @MainActor in await editing.refreshDeviceStatus() }
        task.cancel()
        await task.value
        try expect(editing.deviceStatus!.readAt == beforeCancellation && !editing.isBusy,
                   "A cancelled background refresh does not publish a new reading")
        let local = try await store.loadLocal(data: original.encoded(), name: "local.plist")
        editing.snapshot = local
        editing.working = local.document
        editing.observe(local)
        await editing.refreshDeviceStatus()
        try expect(editing.deviceStatus!.readAt == beforeCancellation,
                   "A local document is never presented as a fresh device observation")

        var unknownRoot = original.root
        unknownRoot["CacheUUID"] = "00000000-0000-0000-0000-000000000001"
        let unknown = try GestaltDocument(data: PropertyListSerialization.data(fromPropertyList: unknownRoot, format: .binary, options: 0))
        let unknownSnapshot = DocumentSnapshot(data: try unknown.encoded(), document: unknown, source: .device, name: "unknown",
                                               originals: [GestaltKeys.regionCode: OriginalField(value: "LL")],
                                               cachedOptionsOriginal: try CachedOptionsOriginal(document: original))
        let unknownReport = DeviceModificationReport(snapshot: unknownSnapshot)
        try expect(unknownReport.unlockConfigured == nil && !unknownReport.issues.isEmpty && unknownReport.changes.count == 1,
                   "An unknown binary layout stays unavailable while readable field differences are retained")
        print("PASS: live changes, pending isolation, apply/restore updates, journal accuracy, type/removal diffs, external changes, read failures, cancellation and local-file isolation.")
    }
}
