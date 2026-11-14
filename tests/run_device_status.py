#!/usr/bin/env python3
"""Test the actual status refresh, apply and restore methods with a file-backed device."""

from pathlib import Path
import subprocess
import tempfile

from run_field_manager_regression import CORE, extract_member


ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "GestaltX/GestaltManager.swift").read_text()
members = [extract_member(source, signature) for signature in [
    "var preview:", "var changeKeys:", "var cacheDataChanges:", "var changeCount:",
    "var sourceIsDevice:", "var artworkEditingError:", "private func accept(",
    "func clearStaged(", "func stageOneClickUnlock(", "private func recordDeviceReading(",
    "func refreshDeviceStatus(", "func apply(", "func restoreCapability(",
    "func restoreCacheOption(", "func reloadBackups(",
]]
harness = """import Foundation
func L(_ key: String) -> String { key }
@MainActor final class DeviceStatusHarness {
    var snapshot: DocumentSnapshot?
    var working: GestaltDocument?
    var choices: [String: PresetChoice] = [:]
    var regionID = "keep"
    var regionCodeID = "keep"
    var modelID = "keep"
    var changesName = false
    var modelName = ""
    var subtype = 0
    var cacheOptionChoice: CacheOptionChoice = .keep
    var wapiChoice: WAPIChoice = .keep
    var isBusy = false
    var lastError: Error?
    var deviceStatus: DeviceStatusReading?
    var deviceStatusError: String?
    var deviceAccessible = false
    var needsRespring = false
    var status = ""
    var message: String?
    var backups: [BackupRecord] = []
    let files: GestaltFileStore
    init(snapshot: DocumentSnapshot, files: GestaltFileStore) {
        self.files = files
        accept(snapshot)
        recordDeviceReading(snapshot)
    }
    func observe(_ loaded: DocumentSnapshot) { recordDeviceReading(loaded) }
    private func failed(_ error: Error) { lastError = error }
    private func log(_ text: String) {}
    private func logChanges(from: GestaltDocument, to: GestaltDocument, prefix: String) {}
    private func diffLines(_ before: [String: Any], _ after: [String: Any]) -> [String] { [] }
""" + "\n".join(members) + "\n}\n"

with tempfile.TemporaryDirectory(prefix="gestaltx-status-") as temporary:
    directory = Path(temporary)
    generated = directory / "DeviceStatusHarness.swift"
    generated.write_text(harness)
    binary = directory / "device-status"
    subprocess.run([
        "swiftc", "-swift-version", "5", "-parse-as-library",
        *[str(ROOT / path) for path in CORE],
        str(ROOT / "GestaltX/DeviceModificationStatus.swift"), str(generated),
        str(ROOT / "tests/DeviceModificationStatusTests.swift"), "-o", str(binary),
    ], check=True, timeout=180)
    subprocess.run([str(binary)], check=True, timeout=60)
