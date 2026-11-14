#!/usr/bin/env python3
"""Exercise the production unlock staging and preview with the real file store."""

from pathlib import Path
import subprocess
import tempfile

from run_field_manager_regression import CORE, extract_member


ROOT = Path(__file__).resolve().parents[1]
source = (ROOT / "GestaltX/GestaltManager.swift").read_text()
members = [extract_member(source, signature) for signature in [
    "var preview:", "var changeKeys:", "var cacheDataChanges:", "var changeCount:",
    "func stageOneClickUnlock(",
]]
harness = """import Foundation
@MainActor final class UnlockManagerHarness {
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
    var isBusy = false
    var lastError: Error?
    init(snapshot: DocumentSnapshot) {
        self.snapshot = snapshot
        self.working = snapshot.document
    }
    private func failed(_ error: Error) { lastError = error }
""" + "\n".join(members) + "\n}\n"

with tempfile.TemporaryDirectory(prefix="gestaltx-unlock-") as temporary:
    directory = Path(temporary)
    generated = directory / "UnlockManagerHarness.swift"
    generated.write_text(harness)
    binary = directory / "one-click-unlock"
    subprocess.run([
        "swiftc", "-swift-version", "5", "-parse-as-library",
        *[str(ROOT / path) for path in CORE], str(generated),
        str(ROOT / "tests/OneClickUnlockTests.swift"), "-o", str(binary),
    ], check=True, timeout=180)
    subprocess.run([str(binary)], check=True, timeout=60)
