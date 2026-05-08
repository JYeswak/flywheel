#!/usr/bin/env python3
"""Detect cancelled MCP tools/call requests that never received a response."""
from __future__ import annotations

import argparse
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


SCHEMA_VERSION = "orphaned-mcp-tool-call-doctor/v1"
DEFAULT_LOG = Path.home() / ".local/state/flywheel/mcp-tool-calls.jsonl"


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def load_jsonl(path: Path) -> tuple[list[dict[str, Any]], list[dict[str, Any]]]:
    rows: list[dict[str, Any]] = []
    malformed: list[dict[str, Any]] = []
    if not path.exists():
        return rows, malformed
    with path.open("r", encoding="utf-8") as fh:
        for line_no, line in enumerate(fh, 1):
            text = line.strip()
            if not text:
                continue
            try:
                value = json.loads(text)
            except json.JSONDecodeError as exc:
                malformed.append({"line": line_no, "error": str(exc)})
                continue
            if isinstance(value, dict):
                value["_line"] = line_no
                rows.append(value)
            else:
                malformed.append({"line": line_no, "error": "row_not_object"})
    return rows, malformed


def pick_id(value: Any) -> str | None:
    if value is None:
        return None
    if isinstance(value, (str, int)):
        return str(value)
    return None


def request_id_for_cancel(row: dict[str, Any]) -> str | None:
    params = row.get("params") if isinstance(row.get("params"), dict) else {}
    candidates = [
        params.get("requestId"),
        params.get("request_id"),
        params.get("id"),
        row.get("requestId"),
        row.get("request_id"),
        row.get("cancelled_request_id"),
        row.get("id"),
    ]
    for candidate in candidates:
        request_id = pick_id(candidate)
        if request_id:
            return request_id
    return None


def method_for(row: dict[str, Any]) -> str:
    for key in ("method", "jsonrpc_method", "mcp_method"):
        value = row.get(key)
        if isinstance(value, str):
            return value
    return ""


def classify(rows: list[dict[str, Any]]) -> dict[str, Any]:
    requests: dict[str, dict[str, Any]] = {}
    cancels: dict[str, list[dict[str, Any]]] = {}
    responses: dict[str, dict[str, Any]] = {}

    for row in rows:
        method = method_for(row)
        row_id = pick_id(row.get("id"))
        if method == "tools/call" and row_id:
            requests[row_id] = row
            continue
        if method == "notifications/cancelled":
            cancel_id = request_id_for_cancel(row)
            if cancel_id:
                cancels.setdefault(cancel_id, []).append(row)
            continue
        if row_id and ("result" in row or "error" in row):
            responses[row_id] = row

    evidence_refs: list[dict[str, Any]] = []
    resolved_after_cancel = 0
    for request_id, cancel_rows in sorted(cancels.items()):
        request = requests.get(request_id)
        if not request:
            continue
        response = responses.get(request_id)
        if response:
            resolved_after_cancel += 1
            continue
        evidence_refs.append(
            {
                "request_id": request_id,
                "request_line": request.get("_line"),
                "cancel_line": cancel_rows[0].get("_line"),
                "response_line": None,
                "method": "tools/call",
                "cancel_method": "notifications/cancelled",
                "runtime_cancel_notification_seen": True,
                "original_tools_call_unresolved": True,
            }
        )

    return {
        "orphaned_mcp_tool_call_count": len(evidence_refs),
        "resolved_after_cancel_count": resolved_after_cancel,
        "cancelled_tools_call_count": sum(1 for request_id in cancels if request_id in requests),
        "evidence_refs": evidence_refs,
    }


def build_payload(path: Path) -> dict[str, Any]:
    rows, malformed = load_jsonl(path)
    classified = classify(rows)
    count = classified["orphaned_mcp_tool_call_count"]
    status = "fail" if count > 0 else "pass"
    return {
        "schema_version": SCHEMA_VERSION,
        "status": status,
        "checked_at": utc_now(),
        "source": str(path),
        "source_exists": path.exists(),
        "rows_scanned": len(rows),
        "malformed_rows_count": len(malformed),
        "malformed_rows": malformed[:20],
        "orphaned_mcp_tool_call_count": count,
        "resolved_after_cancel_count": classified["resolved_after_cancel_count"],
        "cancelled_tools_call_count": classified["cancelled_tools_call_count"],
        "evidence_refs": classified["evidence_refs"][:50],
        "producer": ".flywheel/scripts/orphaned-mcp-tool-call-probe.py",
        "measurement": "JSON-RPC lifecycle join over tools/call, notifications/cancelled, and response id rows",
        "consumer": "flywheel-loop doctor --json; doctor-signal-bead-promotion.sh",
        "promotion_path": "orphaned_mcp_tool_call_count>0 -> [auto-doctor:orphaned_mcp_tool_call] repair bead",
        "errors": [
            {
                "code": "orphaned_mcp_tool_call_count",
                "message": f"{count} cancelled MCP tools/call request(s) never resolved",
                "detail": {"evidence_refs": classified["evidence_refs"][:10]},
            }
        ]
        if count > 0
        else [],
        "warnings": [],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--doctor", action="store_true")
    parser.add_argument("--json", action="store_true", dest="json_out")
    parser.add_argument("--schema", action="store_true")
    parser.add_argument("--repo", default=None)
    parser.add_argument("--log", default=os.environ.get("FLYWHEEL_MCP_TOOL_CALL_LOG", str(DEFAULT_LOG)))
    args = parser.parse_args()

    if args.schema:
        print(
            json.dumps(
                {
                    "schema_version": SCHEMA_VERSION,
                    "required": [
                        "source",
                        "checked_at",
                        "orphaned_mcp_tool_call_count",
                        "evidence_refs",
                    ],
                },
                sort_keys=True,
            )
        )
        return 0

    payload = build_payload(Path(args.log).expanduser())
    if args.json_out or args.doctor:
        print(json.dumps(payload, sort_keys=True))
    else:
        print(f"orphaned_mcp_tool_call_count={payload['orphaned_mcp_tool_call_count']}")
    return 0 if payload["status"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())
