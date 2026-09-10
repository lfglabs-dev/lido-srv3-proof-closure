"""Strict pinned-span identities and their consumer-visible annotations."""

SPAN_FIELDS = {"repository", "source_sha", "path", "function", "start_line", "end_line", "permalink"}
DISPLAY_FIELDS = ("path", "function", "start_line", "end_line", "source_sha", "permalink")


def span_identity(span, identifier, require):
    require(set(span) in (SPAN_FIELDS, SPAN_FIELDS | {"provenance_status"}),
            f"{identifier}: malformed source span")
    if "provenance_status" in span:
        require(isinstance(span["provenance_status"], str) and span["provenance_status"].strip(),
                f"{identifier}: provenance status must be nonempty text")
    # Changing only an annotation cannot evade duplicate-source detection.
    return tuple((field, span[field]) for field in sorted(SPAN_FIELDS))


def display_span(span):
    row = {key: span[key] for key in DISPLAY_FIELDS}
    if "provenance_status" in span:
        row["provenance_status"] = span["provenance_status"]
    return row


def span_rows(source_map, identifier, fail):
    targets = [target for target in source_map["targets"] if target["id"] == identifier]
    if len(targets) != 1:
        fail(f"{identifier}: expected one source-map target, found {len(targets)}")
    return [display_span(span) for span in targets[0]["spans"]]
