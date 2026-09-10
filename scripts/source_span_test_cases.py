"""Mutation cases shared by the metadata and consumer artifact suites."""

import copy
import json
import subprocess


def check_invalid_annotations(source, path, fixture, write, invoke):
    for invalid in (None, False, 1, [], {}, "", " \n\t"):
        changed = copy.deepcopy(source)
        changed["targets"][0]["spans"][0]["provenance_status"] = invalid
        write(path, changed)
        invoke(fixture, False, "provenance status must be nonempty text")
    changed = copy.deepcopy(source)
    changed["targets"][0]["spans"][0]["provenance_statu"] = "OPEN"
    write(path, changed)
    invoke(fixture, False, "malformed source span")
    changed = copy.deepcopy(source)
    del changed["targets"][0]["spans"][0]["function"]
    write(path, changed)
    invoke(fixture, False, "malformed source span")
    changed = copy.deepcopy(source)
    duplicate = copy.deepcopy(changed["targets"][0]["spans"][0])
    duplicate["provenance_status"] = "Different annotation, identical pinned span"
    changed["targets"][0]["spans"].append(duplicate)
    write(path, changed)
    invoke(fixture, False, "duplicate source span")
    write(path, source)


def check_annotation_projection(fixture, expect):
    source = json.loads((fixture / "audit/source-map.yaml").read_text())
    topup = next(target for target in source["targets"] if target["id"] == "P-TOPUP-1")
    annotation = next(span["provenance_status"] for span in topup["spans"]
                      if "provenance_status" in span)
    record = fixture / "audit/ux2/P-TOPUP-1.json"
    original = record.read_text()
    value = json.loads(original)
    annotated = next(span for span in value["source_spans"] if "provenance_status" in span)
    assert annotated["provenance_status"] == annotation
    del annotated["provenance_status"]
    record.write_text(json.dumps(value, indent=2) + "\n")
    expect(fixture, "check", False, "differs from the registry and Lean sources")
    record.write_text(original)


def write(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")
def invoke(root, ok, needle=None, command="generate"):
    result = subprocess.run(
        ["python3", "scripts/audit_metadata.py", command], cwd=root,
        text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
    )
    if (result.returncode == 0) != ok:
        raise AssertionError(f"unexpected rc={result.returncode}:\n{result.stdout}")
    if needle and needle not in result.stdout:
        raise AssertionError(f"missing {needle!r}:\n{result.stdout}")


def check_artifact_drift(fixture, expect, rewrite) -> None:
    check_annotation_projection(fixture, expect)
    record = fixture / "audit/ux2/P-ALLOC-1.json"
    original = rewrite(record, '"position": 1', '"position": 11')
    expect(fixture, "check", False, "differs from the registry and Lean sources")
    record.write_text(original, encoding="utf-8")

    bogus = fixture / "audit/ux2/P-BOGUS.json"
    bogus.write_text("{}\n", encoding="utf-8")
    expect(fixture, "check", False, "artifacts no registry row derives")
    expect(fixture, "generate", True, "generated 12 files")
    if bogus.exists():
        raise SystemExit("generation left a stale UX2 JSON artifact behind")

    record.unlink()
    expect(fixture, "check", False, "P-ALLOC-1.json is missing")
    expect(fixture, "generate", True, "generated 12 files")
    expect(fixture, "check", True, "11 guarantee records match")


