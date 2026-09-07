#!/usr/bin/env python3
"""Read one known durable remote job once; never submit, poll, or change credentials."""
import argparse
import json
import os
from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("job")
    parser.add_argument("--node", default="old-agent")
    args = parser.parse_args()
    query = urlencode({"mission_id": os.environ["REMOTE_BUILD_MISSION_ID"], "node_id": args.node})
    request = Request(
        os.environ["REMOTE_BUILD_URL"].rstrip("/") + "/" + args.job + "?" + query,
        headers={"Authorization": "Bearer " + os.environ["REMOTE_BUILD_TOKEN"]},
    )
    with urlopen(request, timeout=20) as response:
        data = json.load(response)
    safe = {k: data.get(k) for k in (
        "job_id", "node_id", "state", "receipt_state", "exit_code", "created_at",
        "started_at", "finished_at", "error", "log_tail", "validation", "artifacts",
    )}
    if safe["job_id"] != args.job:
        raise RuntimeError("response does not identify the requested job")
    if safe["state"] in {"succeeded", "failed", "cancelled", "lost"}:
        path = Path(__file__).parent / ("receipt-" + args.job + ".json")
        path.write_text(json.dumps(safe, indent=2) + "\n")
        print(path)
    print(json.dumps({k: safe[k] for k in ("job_id", "state", "exit_code", "error")}))
    print(safe["log_tail"] or "")


if __name__ == "__main__":
    main()
