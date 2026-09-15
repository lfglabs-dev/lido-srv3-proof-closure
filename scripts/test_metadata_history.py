"""Build mutation-test history from frozen R1 inputs, without reclassifying it."""
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parent.parent


def preserve_historical_inputs(fixture):
    names = ("audit/guarantees.yaml", "audit/source-map.yaml",
             "audit/trust-native-decide-allowlist.txt")
    current = {name: (fixture / name).read_bytes() for name in names}
    for name in names:
        (fixture / name).write_bytes(subprocess.check_output(
            ["git", "show", f"e8a597f742433475c89382e2eaf96b8475baa214:{name}"], cwd=ROOT))
    return current


def restore_candidate_inputs(fixture, current):
    for name, data in current.items():
        (fixture / name).write_bytes(data)
