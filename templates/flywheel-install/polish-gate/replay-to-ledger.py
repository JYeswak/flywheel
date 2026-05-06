#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import os
import sys
import tempfile
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

ZERO_HASH = "0" * 64
SCRIPT_DIR = Path(__file__).resolve().parent
SCHEMA_DIR = SCRIPT_DIR / "v1"
GRADE_SCHEMA = SCHEMA_DIR / "grade-receipt.schema.json"
REPLAY_SCHEMA = SCHEMA_DIR / "replay-output.schema.json"
DEFAULT_SOURCE = ".flywheel/polish-gate/grades.jsonl"
DEFAULT_LIVE_LEDGER = ".flywheel/wire-or-explain/ledger.jsonl"


class ReplayError(RuntimeError):
    def __init__(self, exit_code: int, message: str) -> None:
        super().__init__(message)
        self.exit_code = exit_code


@dataclass(frozen=True)
class Translation:
    identity_key: str
    source_line: int
    surface_path: str
    verdict: str
    sequence_num: int | None
    action: str


@dataclass(frozen=True)
class ReplaySummary:
    ts: str
    source_path: str
    target_path: str
    action: str
    rows_loaded: int
    rows_translated: int
    rows_skipped: dict[str, int]
    chain_verify_pre: str
    chain_verify_post: str
    errors: list[str]
    exit_code: int
    translations: list[Translation]

    def to_dict(self) -> dict[str, Any]:
        data = asdict(self)
        data["translations"] = [asdict(item) for item in self.translations]
        return data


def iso_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def canonical(obj: dict[str, Any]) -> str:
    return json.dumps(obj, sort_keys=True, separators=(",", ":"), ensure_ascii=True)


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def row_checksum(row: dict[str, Any]) -> str:
    shadow = dict(row)
    shadow.pop("checksum", None)
    return sha256_text(canonical(shadow))


def load_json(path: Path, exit_code: int) -> dict[str, Any]:
    try:
        with path.open(encoding="utf-8") as handle:
            data = json.load(handle)
    except json.JSONDecodeError as exc:
        raise ReplayError(exit_code, f"malformed JSON in {path}: {exc.msg}") from exc
    except OSError as exc:
        raise ReplayError(exit_code, f"cannot read {path}: {exc}") from exc
    if not isinstance(data, dict):
        raise ReplayError(exit_code, f"JSON document must be an object: {path}")
    return data


def validator(schema_path: Path):
    try:
        from jsonschema import Draft202012Validator
        from jsonschema.exceptions import SchemaError
    except ModuleNotFoundError as exc:
        raise ReplayError(3, "jsonschema module is required for replay validation") from exc
    schema = load_json(schema_path, 3)
    try:
        Draft202012Validator.check_schema(schema)
    except SchemaError as exc:
        raise ReplayError(3, f"schema is invalid: {schema_path}: {exc.message}") from exc
    return Draft202012Validator(schema, format_checker=Draft202012Validator.FORMAT_CHECKER)


def resolve_path(raw: str) -> Path:
    return Path(raw).expanduser()


def default_target(apply_to_live: bool) -> Path:
    if apply_to_live:
        return Path(DEFAULT_LIVE_LEDGER)
    name = f"polish-gate-replay-ledger-{os.getpid()}.jsonl"
    return Path(tempfile.gettempdir()) / name


def read_jsonl(path: Path) -> list[tuple[int, dict[str, Any]]]:
    rows: list[tuple[int, dict[str, Any]]] = []
    if not path.exists():
        return rows
    try:
        handle = path.open(encoding="utf-8")
    except OSError as exc:
        raise ReplayError(4, f"cannot read {path}: {exc}") from exc
    with handle:
        for line_no, line in enumerate(handle, 1):
            text = line.strip()
            if not text:
                continue
            try:
                value = json.loads(text)
            except json.JSONDecodeError as exc:
                raise ReplayError(4, f"{path}:{line_no}: malformed JSON: {exc.msg}") from exc
            if not isinstance(value, dict):
                raise ReplayError(4, f"{path}:{line_no}: row must be an object")
            rows.append((line_no, value))
    return rows


def verify_rows(rows: list[dict[str, Any]]) -> tuple[str, list[str]]:
    prev = ZERO_HASH
    errors: list[str] = []
    for expected_seq, row in enumerate(rows, 1):
        expected_checksum = row_checksum(row)
        if row.get("sequence_num") != expected_seq:
            errors.append(f"sequence_num row {expected_seq}")
        if row.get("prev_hash") != prev:
            errors.append(f"prev_hash row {expected_seq}")
        if row.get("checksum") != expected_checksum:
            errors.append(f"checksum row {expected_seq}")
        actual = row.get("checksum")
        prev = actual if isinstance(actual, str) else ZERO_HASH
    return ("FAIL" if errors else "PASS"), errors


def receipt_identity(receipt: dict[str, Any]) -> str:
    stable = {
        "ts": receipt["ts"],
        "surface_path": receipt["surface_path"],
        "mode": receipt["mode"],
        "composite": receipt["composite"],
        "verdict": receipt["verdict"],
        "mission_anchor_hash": receipt["mission_anchor_hash"],
    }
    return "polish-gate-replay:" + sha256_text(canonical(stable))[:32]


def translate(receipt: dict[str, Any], identity: str, target: Path) -> dict[str, Any]:
    evidence_hash = sha256_text(canonical(receipt))
    surface = str(receipt["surface_path"])
    grader = str(receipt["grader"])
    return {
        "schema_name": "flywheel.wire-or-explain.v1",
        "schema_version": "wire-or-explain-ledger/v1",
        "identity_key": identity,
        "timestamp": receipt["ts"],
        "session_id": "polish-gate",
        "event_type": "polish_gate_grade_replayed",
        "actor": grader,
        "target": surface,
        "payload": {
            "surface_path": surface,
            "surface_name": receipt["surface_name"],
            "mode": receipt["mode"],
            "composite": receipt["composite"],
            "verdict": receipt["verdict"],
            "evidence_paths": receipt["evidence_paths"],
            "mission_anchor_hash": receipt["mission_anchor_hash"],
            "evidence_payload": receipt["skills"],
            "agent": grader,
            "evidence_output_hash": evidence_hash,
        },
        "metadata": {
            "replay_adapter": "polish-gate/replay-to-ledger/v1",
            "source_schema_version": receipt["schema_version"],
            "source_ts": receipt["ts"],
            "agent": grader,
        },
        "prev_hash": ZERO_HASH,
        "checksum": ZERO_HASH,
        "sequence_num": 1,
        "state": "wired",
        "producer": "polish-gate",
        "owner": "flywheel",
        "consumer": "wire-or-explain-ledger",
        "blocking_scope": "none",
        "owning_orch": "flywheel:pane-1",
        "ship_repo": str(Path.cwd().resolve()),
        "ship_actor": grader,
        "artifact_class": "other",
        "subject": surface,
        "predicate": "has_polish_gate_grade_receipt",
        "branch_ref": None,
        "git_ref": None,
        "reset_intent_hash": None,
        "deferral_owner": None,
        "deferral_until": None,
        "auto_fire_trigger": "none",
        "drain_receipt_shape": "chain_verifier_pass",
        "verification_probe": f"bash .flywheel/scripts/wire-or-explain-chain-verifier.sh --ledger {target} --json",
        "tick_status_consequence": "polish-gate grade receipt is replayed into ledger stock",
        "stock": "polish-gate-ledger-replay",
        "inflow": "grade_receipt_replayed",
        "action_ledger": str(target),
    }


def fsync_dir(path: Path) -> None:
    try:
        fd = os.open(path, os.O_RDONLY)
    except OSError:
        return
    try:
        os.fsync(fd)
    finally:
        os.close(fd)


def atomic_write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp_name = tempfile.mkstemp(prefix=f".{path.name}.", suffix=".tmp", dir=path.parent)
    tmp_path = Path(tmp_name)
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as handle:
            handle.write(content)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(tmp_path, path)
        fsync_dir(path.parent)
    except Exception:
        try:
            tmp_path.unlink()
        except OSError:
            pass
        raise


def build_content(path: Path, appended: list[dict[str, Any]]) -> str:
    existing = path.read_text(encoding="utf-8") if path.exists() else ""
    if existing and not existing.endswith("\n"):
        existing += "\n"
    return existing + "".join(canonical(row) + "\n" for row in appended)


def run(args: argparse.Namespace) -> ReplaySummary:
    if args.apply and args.dry_run:
        raise ReplayError(3, "--apply and --dry-run are mutually exclusive")
    if args.apply_to_live and not args.apply:
        raise ReplayError(3, "--apply-to-live requires --apply")

    source = resolve_path(args.source)
    target = resolve_path(args.target_ledger) if args.target_ledger else default_target(args.apply_to_live)
    action = "apply-to-live" if args.apply_to_live else ("apply" if args.apply else "dry-run")
    errors: list[str] = []
    skipped = {"schema-fail": 0, "dup": 0, "pre-from-ts": 0}
    translations: list[Translation] = []

    grade_validator = validator(GRADE_SCHEMA)
    ledger_schema_path = Path(".flywheel/validation-schema/v1/wire-or-explain-ledger.schema.json")
    ledger_validator = validator(ledger_schema_path) if ledger_schema_path.exists() else None

    source_rows = read_jsonl(source)
    target_pairs = read_jsonl(target)
    target_rows = [row for _, row in target_pairs]
    existing_ids = {str(row.get("identity_key")) for row in target_rows if row.get("identity_key")}

    chain_pre, pre_errors = ("N/A", [])
    if args.apply_to_live:
        chain_pre, pre_errors = verify_rows(target_rows)
        if chain_pre == "FAIL":
            return ReplaySummary(
                iso_now(), str(source), str(target), action, len(source_rows), 0, skipped,
                chain_pre, "N/A", pre_errors, 1, translations
            )

    appended: list[dict[str, Any]] = []
    planned_ids = set(existing_ids)
    last = target_rows[-1] if target_rows else None
    next_sequence = int(last.get("sequence_num", 0)) + 1 if last else 1
    prev_hash = str(last.get("checksum", ZERO_HASH)) if last else ZERO_HASH

    for line_no, receipt in source_rows:
        try:
            grade_validator.validate(receipt)
        except Exception as exc:
            skipped["schema-fail"] += 1
            errors.append(f"{source}:{line_no}: schema-fail: {getattr(exc, 'message', str(exc))}")
            continue
        if args.from_ts and str(receipt["ts"]) <= args.from_ts:
            skipped["pre-from-ts"] += 1
            continue
        identity = receipt_identity(receipt)
        if identity in planned_ids:
            skipped["dup"] += 1
            translations.append(Translation(identity, line_no, str(receipt["surface_path"]), str(receipt["verdict"]), None, "duplicate"))
            continue
        row = translate(receipt, identity, target)
        row["sequence_num"] = next_sequence
        row["prev_hash"] = prev_hash
        row["checksum"] = row_checksum(row)
        if ledger_validator is not None:
            ledger_validator.validate(row)
        appended.append(row)
        planned_ids.add(identity)
        translations.append(Translation(identity, line_no, str(receipt["surface_path"]), str(receipt["verdict"]), next_sequence, "translated"))
        next_sequence += 1
        prev_hash = str(row["checksum"])

    simulated_rows = target_rows + appended
    chain_post, post_errors = verify_rows(simulated_rows)
    if chain_post == "FAIL":
        return ReplaySummary(
            iso_now(), str(source), str(target), action, len(source_rows), len(appended), skipped,
            chain_pre, chain_post, errors + post_errors, 2, translations
        )

    if args.apply and appended:
        atomic_write(target, build_content(target, appended))
        persisted_rows = [row for _, row in read_jsonl(target)]
        chain_post, post_errors = verify_rows(persisted_rows)
        if chain_post == "FAIL":
            return ReplaySummary(
                iso_now(), str(source), str(target), action, len(source_rows), len(appended), skipped,
                chain_pre, chain_post, errors + post_errors, 2, translations
            )

    return ReplaySummary(
        iso_now(), str(source), str(target), action, len(source_rows), len(appended), skipped,
        chain_pre, chain_post, errors, 0, translations if args.explain else []
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Replay polish-gate grade receipts into Zest Ledger row format.")
    parser.add_argument("--source", default=DEFAULT_SOURCE, help=f"source grades.jsonl path (default: {DEFAULT_SOURCE})")
    parser.add_argument("--target-ledger", help="target Zest Ledger JSONL path (default: temp file, or live ledger with --apply-to-live)")
    parser.add_argument("--apply-to-live", action="store_true", help=f"append to the live ledger ({DEFAULT_LIVE_LEDGER}); requires --apply")
    parser.add_argument("--from-ts", help="only replay receipts after this ISO8601 timestamp")
    parser.add_argument("--dry-run", action="store_true", help="print intended translations and chain simulation; no writes (default)")
    parser.add_argument("--apply", action="store_true", help="write translated rows atomically")
    parser.add_argument("--json", action="store_true", help="emit JSON output")
    parser.add_argument("--schema", action="store_true", help="emit replay-output JSON Schema and exit")
    parser.add_argument("--explain", action="store_true", help="include per-receipt translation trace")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.schema:
        print(json.dumps(load_json(REPLAY_SCHEMA, 3), indent=2, sort_keys=True))
        return 0
    try:
        summary = run(args)
    except ReplayError as exc:
        target = resolve_path(args.target_ledger) if args.target_ledger else default_target(args.apply_to_live)
        action = "apply-to-live" if args.apply_to_live else ("apply" if args.apply else "dry-run")
        summary = ReplaySummary(
            iso_now(), str(resolve_path(args.source)), str(target), action, 0, 0,
            {"schema-fail": 0, "dup": 0, "pre-from-ts": 0}, "N/A", "N/A",
            [str(exc)], exc.exit_code, []
        )
    payload = summary.to_dict()
    validator(REPLAY_SCHEMA).validate(payload)
    if args.explain and not args.json:
        for item in summary.translations:
            print(f"{item.action} line={item.source_line} identity={item.identity_key} surface={item.surface_path}")
        print(json.dumps(payload, indent=2, sort_keys=True))
    else:
        print(json.dumps(payload, indent=2, sort_keys=True))
    return summary.exit_code


if __name__ == "__main__":
    sys.exit(main())
