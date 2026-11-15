"""Export repository-scoped local Codex conversations without executing their tools.

Only the output directory is written. Session logs and SQLite databases are opened
read-only. Reasoning, instructions, credentials, and unrelated workspaces are not
exported. Requires Python 3.10+ and Git; no third-party dependencies.
"""

from __future__ import annotations

import argparse
import base64
import collections
from datetime import datetime, timedelta, timezone
import hashlib
import html
import json
import os
from pathlib import Path
import re
import sqlite3
import subprocess
from urllib.parse import unquote, urlparse


SINGAPORE = timezone(timedelta(hours=8), "Asia/Singapore")
UUID = re.compile(r"[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}", re.I)
MACHINE_PREFIXES = (
    "<environment_context>", "<external_ide_context>",
    "<external_codex_apps_open_page>", "<external_codex_apps_selected_page_",
    "# AGENTS.md instructions", "<permissions instructions>",
)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def normpath(value):
    value = str(value).replace("\\", "/")
    if value.startswith("//?/"):
        value = value[4:]
    return value.rstrip("/").casefold()


def dt(value):
    if isinstance(value, (int, float)):
        return datetime.fromtimestamp(value, timezone.utc)
    return datetime.fromisoformat(value.replace("Z", "+00:00"))


def stamp(value):
    return dt(value).astimezone(SINGAPORE).isoformat(sep=" ", timespec="seconds")


def record_time(record):
    metadata = record.get("payload", {}).get("internal_chat_message_metadata_passthrough") or {}
    return metadata.get("create_time") or record["timestamp"]


def fence(text, language="text"):
    longest = max((len(m.group()) for m in re.finditer(r"`+", text)), default=0)
    marker = "`" * max(3, longest + 1)
    return f"{marker}{language}\n{text}" + ("" if text.endswith("\n") else "\n") + marker + "\n"


def details(label, body):
    return f"<details>\n<summary>{html.escape(label)}</summary>\n\n{body}\n</details>\n"


def ro_database(path):
    if not path.is_file():
        return None
    uri = path.resolve().as_uri() + "?mode=ro"
    wal = Path(str(path) + "-wal")
    # A closed, checkpointed WAL database may have no coordination files.
    # Immutable mode prevents SQLite from trying to create those files next
    # to the read-only source. Never bypass a nonempty write-ahead log.
    if not wal.is_file() or wal.stat().st_size == 0:
        uri += "&immutable=1"
    connection = sqlite3.connect(uri, uri=True)
    connection.row_factory = sqlite3.Row
    return connection


def signature(payload):
    kind = payload.get("type")
    if payload.get("id"):
        return (kind, payload["id"])
    if payload.get("call_id"):
        return (kind, payload["call_id"])
    meta = payload.get("internal_chat_message_metadata_passthrough") or {}
    return (kind, payload.get("role"), meta.get("turn_id"), digest(json.dumps(
        payload.get("content", payload), ensure_ascii=False, sort_keys=True
    ).encode("utf-8")))


def plain_message(payload):
    return "\n".join(part.get("text", "") for part in payload.get("content", [])
                     if isinstance(part, dict) and part.get("type") in ("input_text", "output_text", "text"))


def visible_message(payload, background=False):
    if payload.get("type") != "message" or payload.get("role") not in ("user", "assistant"):
        return False
    if payload.get("channel") == "analysis":
        return False
    text = plain_message(payload).strip()
    if text.startswith(MACHINE_PREFIXES) or text.startswith("gAAAAA"):
        return False
    if background and payload.get("role") == "user":
        return False
    return bool(text) or any(part.get("type") == "input_image" for part in payload.get("content", []))


def relative_file(value, repo):
    value = str(value).replace("\\", "/")
    if value.startswith("//?/"):
        value = value[4:]
    base = repo.as_posix().rstrip("/")
    if value.casefold().startswith(base.casefold() + "/"):
        return value[len(base) + 1:]
    return None


def js_strings(source):
    """Read literal strings as data, including the JSON strings used by exec.

    No JavaScript or recorded shell command is evaluated.
    """
    result = []
    decoder = json.JSONDecoder()
    i = 0
    while i < len(source):
        if source[i] == '"':
            try:
                value, end = decoder.raw_decode(source, i)
                result.append(value)
                i = end
                continue
            except ValueError:
                pass
        if source[i] in ("'", "`"):
            quote, j, chars = source[i], i + 1, []
            while j < len(source):
                if source[j] == quote:
                    result.append("".join(chars))
                    i = j + 1
                    break
                if source[j] == "\\" and j + 1 < len(source):
                    j += 1
                    chars.append({"n": "\n", "r": "\r", "t": "\t"}.get(source[j], source[j]))
                else:
                    chars.append(source[j])
                j += 1
            else:
                i += 1
            continue
        i += 1
    return result


class Export:
    def __init__(self, args):
        self.args = args
        self.repo = args.repo.resolve()
        self.output = args.output.resolve()
        if not self.output.is_relative_to(self.repo):
            raise ValueError("The export directory must be inside the repository")
        self.output.mkdir(parents=True, exist_ok=True)
        self.generated = datetime.now(timezone.utc).isoformat()
        self.sources, self.groups, self.skipped, self.warnings = [], {}, [], []
        self.attachments = {}
        self.git_cache = {}
        self.thread_metadata = {}
        self.projected_edits = collections.defaultdict(list)
        self.vscode_inventory = []

    def git(self, *arguments, allow_failure=False):
        key = tuple(arguments)
        if key not in self.git_cache:
            process = subprocess.run(
                ["git", "-c", "core.quotepath=false", *arguments], cwd=self.repo,
                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                env={**os.environ, "GIT_OPTIONAL_LOCKS": "0"},
            )
            if process.returncode and not allow_failure:
                raise RuntimeError(process.stderr.decode("utf-8", errors="replace"))
            self.git_cache[key] = process.stdout.decode("utf-8", errors="replace") if not process.returncode else ""
        return self.git_cache[key]

    def source(self, path, kind, data=None):
        data = path.read_bytes() if data is None else data
        info = {"kind": kind, "path": str(path), "bytes": len(data), "sha256": digest(data)}
        self.sources.append(info)
        return data

    def load(self):
        state = ro_database(self.args.codex_home / "state_5.sqlite")
        if state:
            for row in state.execute("SELECT id,title,cwd,source,rollout_path FROM threads"):
                if normpath(row["cwd"]) == normpath(self.repo):
                    self.thread_metadata[row["id"]] = dict(row)
            state.close()

        paths = sorted((self.args.codex_home / "sessions").rglob("*.jsonl"))
        archive = self.args.codex_home / "archived_sessions"
        if archive.is_dir():
            paths += sorted(archive.rglob("*.jsonl"))
        for path in paths:
            data = path.read_bytes()
            records = []
            for number, line in enumerate(data.splitlines(), 1):
                if not line.strip():
                    continue
                try:
                    records.append(json.loads(line))
                except ValueError:
                    self.warnings.append(f"Invalid or incomplete record: {path.name}:{number}")
            meta = next((r["payload"] for r in records if r.get("type") == "session_meta"), {})
            if normpath(meta.get("cwd", "")) != normpath(self.repo):
                continue
            self.source(path, "rollout", data)
            thread_id = meta.get("id") or meta.get("session_id")
            group = self.groups.setdefault(thread_id, {"id": thread_id, "logs": [], "records": [],
                "projection_ids": set(), "children": [], "edits": [], "messages": [], "operations": []})
            group["logs"].append(path.name)
            group["projection_ids"].update(UUID.findall(path.name))
            group["projection_ids"].add(thread_id)
            group.setdefault("meta", meta)
            group["records"].extend(records)
            source = meta.get("source")
            if isinstance(source, dict):
                group["parent"] = source.get("subagent", {}).get("thread_spawn", {}).get("parent_thread_id")
            else:
                group["parent"] = None

        history = ro_database(self.args.codex_home / "thread_history_1.sqlite")
        if history:
            for group in self.groups.values():
                for tid in sorted(group["projection_ids"]):
                    for row in history.execute(
                        "SELECT item_id,created_at_ms,item_json FROM thread_items "
                        "WHERE thread_id=? AND item_type='fileChange' ORDER BY rollout_ordinal", (tid,)
                    ):
                        value = json.loads(row["item_json"])
                        edit = {"id": row["item_id"], "timestamp": row["created_at_ms"] / 1000,
                                "thread_id": tid, "status": value.get("status", "unknown"),
                                "changes": value.get("changes", [])}
                        group["edits"].append(edit)
            history.close()
        else:
            self.warnings.append("Structured edit history database is unavailable; raw tool inputs remain in the transcripts.")

        # A migrated thread can have an older projection ID in a continuation filename.
        # The groups are keyed by session_meta.id, so continuations remain one chat.
        for group in self.groups.values():
            if group["parent"] in self.groups:
                self.groups[group["parent"]]["children"].append(group)
        for group in self.groups.values():
            if group["parent"]:
                continue
            seen = set()
            self.prepare(group, seen)
            for child in group["children"]:
                self.prepare(child, seen, background=True)
                group["edits"].extend(child["edits"])
            group["edits"].sort(key=lambda x: x["timestamp"])
            group["title"] = self.thread_metadata.get(group["id"], {}).get("title") or "Repository conversation"

        for tid, meta in self.thread_metadata.items():
            if tid not in self.groups:
                self.warnings.append(f"Thread metadata exists without a local rollout: {tid} ({meta['title']})")

    def prepare(self, group, seen, background=False):
        unique = []
        for record in group["records"]:
            if record.get("type") != "response_item":
                continue
            payload = record["payload"]
            kind = payload.get("type")
            if kind not in ("message", "custom_tool_call", "function_call",
                            "custom_tool_call_output", "function_call_output"):
                continue
            key = signature(payload)
            if key in seen:
                continue
            seen.add(key)
            if kind == "message" and not visible_message(payload, background):
                continue
            unique.append(record)
            if kind == "message":
                group["messages"].append(record)
            elif kind in ("custom_tool_call", "function_call"):
                group["operations"].append(record)
        group["visible_records"] = unique

    def inspect_vscode(self):
        appdata = os.environ.get("APPDATA")
        if not appdata:
            return
        storage = Path(appdata) / "Code" / "User" / "workspaceStorage"
        if not storage.is_dir():
            return
        for workspace in storage.glob("*/workspace.json"):
            try:
                value = json.loads(workspace.read_text(encoding="utf-8"))
                uri = value.get("folder", "")
                folder = unquote(urlparse(uri).path).lstrip("/")
            except (ValueError, OSError):
                continue
            if normpath(folder) != normpath(self.repo):
                continue
            for path in sorted((workspace.parent / "chatSessions").glob("*.jsonl")):
                data = self.source(path, "vscode_chat_journal")
                state = {}
                for line in data.splitlines():
                    item = json.loads(line)
                    if item["kind"] == 0:
                        state = item["v"]
                    else:
                        target = state
                        for key in item["k"][:-1]:
                            target = target[key]
                        key = item["k"][-1]
                        if item["kind"] == 1:
                            target[key] = item["v"]
                        elif item["kind"] == 2:
                            target.setdefault(key, []).extend(item["v"])
                requests = state.get("requests", [])
                empty = not requests
                setup_only = bool(requests) and all(
                    "You need to set up GitHub Copilot" in json.dumps(r.get("response", [])) for r in requests)
                reason = "Empty chat" if empty else "Copilot setup response only; no code changes" if setup_only else "Requires export"
                self.vscode_inventory.append({"id": path.stem, "requests": len(requests), "reason": reason})
                if not empty and not setup_only:
                    self.warnings.append(f"Additional substantive VS Code chat needs review: {path.name}")

    def image(self, url):
        if isinstance(url, dict):
            url = url.get("url") or url.get("image_url")
        if not isinstance(url, str):
            return "[Image attachment reference unavailable in the saved record]"
        if not url.startswith("data:"):
            return f"[Image attachment reference]({url})"
        header, encoded = url.split(",", 1)
        mime = header[5:].split(";", 1)[0]
        if ";base64" not in header:
            return "[Non-base64 image data retained in the source log]"
        data = base64.b64decode(encoded, validate=True)
        suffix = {"image/png": "png", "image/jpeg": "jpg", "image/webp": "webp", "image/gif": "gif"}.get(mime, "bin")
        name = f"attachments/{digest(data)}.{suffix}"
        target = self.output / name
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        self.attachments[name] = {"file": name, "bytes": len(data), "sha256": digest(data), "mime": mime}
        return f"![Saved chat attachment]({name})"

    def message(self, payload):
        parts = []
        for content in payload.get("content", []):
            kind = content.get("type")
            if kind in ("input_text", "output_text", "text"):
                parts.append(content.get("text", ""))
            elif kind == "input_image":
                parts.append(self.image(content.get("image_url") or content.get("url")))
            else:
                parts.append(f"[Saved attachment: {kind}]")
        return "\n\n".join(parts)

    def readable_output(self, value):
        if isinstance(value, list):
            return "\n\n".join(self.readable_output(part) for part in value)
        if isinstance(value, dict):
            if value.get("type") in ("input_text", "output_text", "text"):
                return self.readable_output(value.get("text", ""))
            if value.get("type") in ("image", "input_image"):
                if value.get("data"):
                    return self.image(f"data:{value.get('mimeType', 'image/png')};base64,{value['data']}")
                return self.image(value.get("image_url"))
            if "output" in value:
                trailer = f"\n[Recorded exit code: {value['exit_code']}]" if "exit_code" in value else ""
                return self.readable_output(value["output"]) + trailer
            return json.dumps(value, indent=2, ensure_ascii=False)
        if isinstance(value, str):
            stripped = value.strip()
            if stripped.startswith(("{", "[")):
                try:
                    decoded = json.loads(stripped)
                    if isinstance(decoded, (dict, list)):
                        return self.readable_output(decoded)
                except ValueError:
                    pass
            return value
        return str(value)

    def operations_and_messages(self, group, background=False):
        result, message_number, operation_number = [], 0, 0
        outputs = collections.defaultdict(list)
        for record in group["visible_records"]:
            payload = record["payload"]
            if payload.get("type") in ("custom_tool_call_output", "function_call_output"):
                outputs[payload.get("call_id")].append(payload.get("output", ""))
        for record in group["visible_records"]:
            payload = record["payload"]
            kind = payload.get("type")
            time = stamp(record_time(record))
            if kind == "message":
                message_number += 1
                who = "User" if payload["role"] == "user" else "Assistant"
                phase = payload.get("phase") or payload.get("channel")
                if phase == "commentary":
                    who += " — progress update"
                prefix = "Background " if background else ""
                result.append(f"### {prefix}message {message_number} — {who}\n\n{time}\n\n{self.message(payload)}\n")
            elif kind in ("custom_tool_call", "function_call"):
                operation_number += 1
                source = payload.get("input") or payload.get("arguments") or ""
                output = self.readable_output(outputs.get(payload.get("call_id"), []))
                body = f"Time: {time}  \nCall ID: `{payload.get('call_id', '')}`\n\n"
                body += "Input:\n\n" + fence(source, "javascript" if payload.get("name") == "exec" else "text")
                body += "\nRecorded output:\n\n" + fence(output or "[No output record was saved]")
                result.append(details(f"Tool {operation_number}: {payload.get('name', kind)} — {time}", body))
        return "\n".join(result)

    def classify(self):
        included = []
        for group in self.groups.values():
            if group["parent"]:
                continue
            user_count = sum(r["payload"].get("role") == "user" for r in group["messages"])
            proposed = sum(len(m.group(1)) for r in group["messages"] if r["payload"].get("role") == "assistant"
                           for m in re.finditer(r"```(?:gml|json|powershell|python|javascript)?\n(.*?)```", plain_message(r["payload"]), re.S))
            if group["id"] in self.args.exclude_thread:
                reason = "Current export conversation; still in progress at the export snapshot"
            elif not group["edits"] and user_count <= 1 and proposed < 300:
                reason = "Brief code lookup/explanation; no recorded edits or substantial code proposal"
            elif not user_count:
                reason = "No substantive user messages in the available record"
            else:
                included.append(group)
                continue
            self.skipped.append({"id": group["id"], "title": group["title"], "reason": reason,
                                 "logs": group["logs"]})
        return sorted(included, key=lambda x: min(dt(record_time(r)) for r in x["messages"]))

    def edit_paths(self, group):
        paths = set()
        for edit in group["edits"]:
            for change in edit["changes"]:
                rel = relative_file(change["path"], self.repo)
                if rel:
                    paths.add(rel)
        # Shell edits do not always produce structured fileChange records.
        for owner in [group, *group["children"]]:
            for record in owner["operations"]:
                source = record["payload"].get("input") or record["payload"].get("arguments") or ""
                if not re.search(r"WriteAllText|Set-Content|write_text|writeFile|apply_patch", source):
                    continue
                for value in js_strings(source):
                    for match in re.finditer(r"(?:scripts|objects|tools|datafiles|options|rooms|sequences|shaders)/[A-Za-z0-9_./-]+\.(?:gml|yy|json|cjs|ps1|py|yyp)", value.replace("\\", "/")):
                        paths.add(match.group())
        return sorted(paths)

    def shell_edits(self, group):
        result = []
        for owner in [group, *group["children"]]:
            for record in owner["operations"]:
                payload = record["payload"]
                source = payload.get("input") or payload.get("arguments") or ""
                if "apply_patch" in source or not re.search(r"WriteAllText|Set-Content|write_text|writeFile", source):
                    continue
                commands = [s for s in js_strings(source) if re.search(r"WriteAllText|Set-Content|write_text|writeFile", s)]
                result.append({"timestamp": record_time(record), "call_id": payload.get("call_id"),
                               "thread_id": owner["id"], "commands": commands or [source]})
        return sorted(result, key=lambda x: dt(x["timestamp"]))

    def load_git(self, included):
        all_paths = sorted({p for group in included for p in self.edit_paths(group)})
        log = self.git("log", "--all", "--no-merges", "--format=%H%x09%aI%x09%s", "--", *all_paths)
        self.commits = []
        for line in log.splitlines():
            sha, time, subject = line.split("\t", 2)
            self.commits.append({"sha": sha, "time": time, "subject": subject})
        self.commits.sort(key=lambda c: dt(c["time"]))
        self.patches = {}
        for commit in self.commits:
            patch = self.git("show", "--format=", "--no-ext-diff", "--no-textconv", "--no-renames", commit["sha"], "--", *all_paths)
            sections = {}
            current = None
            for line in patch.splitlines():
                if line.startswith("diff --git a/"):
                    current = line.split(" b/", 1)[1]
                    sections[current] = []
                elif current:
                    sections[current].append(line)
            self.patches[commit["sha"]] = sections

    @staticmethod
    def change_lines(lines, prefix):
        return {line[1:].strip() for line in lines if line.startswith(prefix)
                and not line.startswith(prefix * 3) and len(line[1:].strip()) >= 12
                and not line[1:].strip().startswith(("//", "/*", "*"))}

    def matching_commits(self, group):
        matches = collections.defaultdict(list)
        possible_paths = self.edit_paths(group)
        for number, edit in enumerate(group["edits"], 1):
            if edit["status"] != "completed":
                continue
            for change in edit["changes"]:
                path = relative_file(change["path"], self.repo)
                if not path:
                    continue
                lines = change.get("diff", "").splitlines()
                adds, removes = self.change_lines(lines, "+"), self.change_lines(lines, "-")
                if not adds and not removes:
                    continue
                options = []
                for commit in self.commits:
                    age = (dt(commit["time"]) - dt(edit["timestamp"])).total_seconds()
                    if not -300 <= age <= 21 * 86400:
                        continue
                    for commit_path in possible_paths:
                        if commit_path != path:
                            same_event = Path(commit_path).name == Path(path).name and path.startswith("objects/")
                            different_draw_event = (Path(commit_path).parent == Path(path).parent
                                and re.fullmatch(r"Draw_(?:0|64)\.gml", Path(path).name)
                                and re.fullmatch(r"Draw_(?:0|64)\.gml", Path(commit_path).name))
                            if not same_event and not different_draw_event:
                                continue
                        git_lines = self.patches[commit["sha"]].get(commit_path, [])
                        matched_add = adds & self.change_lines(git_lines, "+")
                        matched_remove = removes & self.change_lines(git_lines, "-")
                        count = len(matched_add) + len(matched_remove)
                        total = len(adds) + len(removes)
                        ratio = count / total
                        added_ratio = len(matched_add) / len(adds) if adds else 0
                        same_path = commit_path == path
                        normal_match = same_path and (
                            (count >= 2 and ratio >= 0.55)
                            or (len(matched_add) >= 3 and added_ratio >= 0.85)
                            or (count == total == 1 and len(next(iter(adds or removes))) >= 24))
                        # Moving code between Draw events and renaming an object can
                        # put an exact added block in a different file in Git.
                        moved_match = not same_path and len(matched_add) >= 5 and added_ratio >= 0.85
                        if normal_match or moved_match:
                            score = max(ratio, added_ratio if len(matched_add) >= 3 else 0)
                            options.append((score, int(same_path), -max(age, 0), commit, count, total, commit_path))
                if options:
                    # Prefer highest overlap, then original path, then earliest commit.
                    _, _, _, commit, count, total, commit_path = max(options, key=lambda x: x[:3])
                    matches[commit["sha"]].append({"edit": number, "path": path, "commit_path": commit_path,
                        "matched_lines": count, "signature_lines": total,
                        "basis": "matching added/deleted lines" if path == commit_path else "matching added block in another file involved in this chat"})

        references = set()
        for record in group["messages"]:
            for candidate in re.findall(r"(?<![A-Za-z0-9])([0-9a-f]{7,40})(?![A-Za-z0-9])", plain_message(record["payload"])):
                resolved = self.git("rev-parse", "--verify", candidate + "^{commit}", allow_failure=True).strip()
                if resolved:
                    references.add(resolved)
        return matches, references

    def code_changes(self, group):
        if not group["edits"]:
            return ("No applied file edits are recorded for this chat. Its implementation examples are preserved "
                    "as suggested code in the conversation below; they are not attributed as repository edits.\n")
        result = ["These are the per-operation diffs saved by the editor, in completion order. "
                  "They preserve intermediate edits, later corrections, deletions, and new files. "
                  "They are historical changes, not a patch against today's HEAD. "
                  "Raw patch requests and failed attempts remain with the tool records in the transcript.\n"]
        for number, edit in enumerate(group["edits"], 1):
            body = f"Completed/recorded: {stamp(edit['timestamp'])}  \nStatus: `{edit['status']}`  \nSource thread: `{edit['thread_id']}`  \nRecord ID: `{edit['id']}`\n\n"
            for change in edit["changes"]:
                path = relative_file(change["path"], self.repo)
                label = path or change["path"]
                kind = change.get("kind", {}).get("type", "unknown")
                scope = "repository" if path else "external diagnostic artifact"
                body += f"#### `{label}`\n\nOperation: {kind}; {scope}.\n\n"
                body += fence(change.get("diff", "[No diff saved]"), "diff") + "\n"
            result.append(f"### Edit {number} — {stamp(edit['timestamp'])}\n\n" + body)
        shell = self.shell_edits(group)
        if shell:
            result += ["### Shell edits without structured patch records\n",
                       "The following write operations were recorded as shell commands rather than editor patches. "
                       "Their original commands are preserved below. Recovered Git diffs follow where matching text "
                       "establishes a connection. These operations are additional to the structured edit count.\n"]
            for number, operation in enumerate(shell, 1):
                body = f"Time: {stamp(operation['timestamp'])}  \nCall ID: `{operation['call_id']}`\n\n"
                for command in operation["commands"]:
                    body += fence(command, "powershell") + "\n"
                result.append(details(f"Shell edit {number} — {stamp(operation['timestamp'])}", body))
        return "\n".join(result)

    def git_changes(self, group, matches, references):
        if not matches and not references:
            return "No commit was confidently linked to this chat's recorded edits or explicitly cited in its messages.\n"
        result = ["Edit attribution comes from the recorded diffs above. Git commits below are supporting repository history: "
                  "a matching commit can also contain manual edits or work from other conversations. "
                  "Matching uses literal added/deleted lines and a bounded later commit date. "
                  "When a matching block appears in another object/event file involved in the chat, both paths are shown; "
                  "dates alone are never treated as proof.\n"]
        paths = self.edit_paths(group)
        recovered = []
        for sha in sorted(set(matches) | references, key=lambda x: self.git("show", "-s", "--format=%aI", x)):
            subject = self.git("show", "-s", "--format=%s", sha).strip()
            parents = self.git("show", "-s", "--format=%P", sha).split()
            reasons = []
            if sha in matches:
                reasons.append("Contains text matching recorded edits")
            if sha in references:
                reasons.append("Explicitly discussed/cited in the conversation")
            body = "; ".join(reasons) + ".\n\n"
            if sha in matches:
                body += "| Edit | Recorded file | Git file | Matching distinct lines |\n| --- | --- | --- | --- |\n"
                for match in matches[sha]:
                    body += f"| {match['edit']} | `{match['path']}` | `{match['commit_path']}` | {match['matched_lines']}/{match['signature_lines']} |\n"
                body += "\n"
            if len(parents) > 1:
                scope = "Merge metadata and change summary; constituent commits contain the code diffs."
                patch = self.git("show", "--format=fuller", "--stat", "--no-patch", sha)
            else:
                if sha in references:
                    scope = "Full textual commit diff; Git reports binary assets by filename."
                    selected = []
                else:
                    scope = "Commit diff restricted to files edited in this chat (including shell edits)."
                    selected = ["--", *paths]
                patch = self.git("show", "--format=fuller", "--stat", "--patch", "--no-ext-diff", "--no-textconv", "--no-renames", sha, *selected)
            body += scope + "\n\n" + fence(patch, "diff")
            result.append(f"### `{sha[:12]}` — {subject}\n\n" + details("Show recovered Git changes", body))
            recovered.append({"sha": sha, "subject": subject, "reasons": reasons, "scope": scope, "matches": matches.get(sha, [])})
        group["git_commits"] = recovered
        return "\n".join(result)

    def export_chat(self, group):
        first = min(dt(record_time(r)) for r in group["messages"])
        last = max(dt(record_time(r)) for r in group["messages"])
        slug = re.sub(r"[^a-z0-9]+", "-", group["title"].lower()).strip("-")
        name = f"{first.astimezone(SINGAPORE):%Y-%m-%d}-{slug}-{group['id'][:8]}.md"
        group["file"] = name
        matches, references = self.matching_commits(group)
        counts = collections.Counter(r["payload"]["role"] for r in group["messages"])
        paths = self.edit_paths(group)
        group["counts"] = {"user_messages": counts["user"], "assistant_messages": counts["assistant"],
                           "tool_calls": len(group["operations"]), "edit_operations": len(group["edits"]),
                           "shell_write_operations": len(self.shell_edits(group)), "repository_files": len(paths)}
        parts = [f"# {group['title']}\n", "[Back to archive index](README.md)\n",
                 f"Chat ID: `{group['id']}`  \nConversation: {stamp(first.isoformat())} to {stamp(last.isoformat())}  \n"
                 f"Timezone: Asia/Singapore (UTC+08:00)  \nExported: {stamp(self.generated)}  \n"
                 f"Messages: {counts['user']} user, {counts['assistant']} assistant; "
                 f"{len(group['edits'])} recorded edit operations.\n",
                 "This file preserves user and assistant messages, including progress updates and code examples. "
                 "Tool inputs and saved outputs are expandable beside the messages where they occurred. "
                 "Instructions, internal reasoning, token telemetry, and empty UI context records are excluded. "
                 "Any truncation already present in a tool result is preserved; it is not reconstructed.\n",
                 "## Contents\n\n- [Recorded code changes](#recorded-code-changes)\n"
                 "- [Recovered Git changes](#recovered-git-changes)\n- [Conversation](#conversation)\n"
                 "- [Source records](#source-records)\n",
                 "## Recorded code changes\n", self.code_changes(group)]
        if paths:
            parts += ["### Repository files involved\n", "\n".join(f"- `{path}`" for path in paths) + "\n"]
        parts += ["## Recovered Git changes\n", self.git_changes(group, matches, references),
                  "## Conversation\n", self.operations_and_messages(group)]
        if group["children"]:
            parts += ["## Supporting background work\n",
                      "These historical background threads belong to this conversation. Their inherited parent messages "
                      "and tool calls have been deduplicated; their own assistant reports and tool records follow. "
                      "Their file edits are included in the edit list above.\n"]
            for child in group["children"]:
                parts += [f"### Background thread `{child['id']}`\n", self.operations_and_messages(child, background=True)]
        parts += ["## Source records\n", "Rollout files:\n",
                  "\n".join(f"- `{name}`" for owner in [group, *group["children"]] for name in owner["logs"]) + "\n",
                  "Structured edit diffs: local `thread_history_1.sqlite`, `thread_items` records with "
                  "`item_type = fileChange`. Titles/workspace identity: local `state_5.sqlite`. "
                  "Databases were opened read-only. Source hashes and the export scope are in [manifest.json](manifest.json).\n"]
        content = "\n".join(parts)
        (self.output / name).write_text(content, encoding="utf-8", newline="\n")
        group["output_sha256"] = digest(content.encode("utf-8"))
        group["output_bytes"] = len(content.encode("utf-8"))
        group["first"] = first.isoformat()
        group["last"] = last.isoformat()

    def validate(self, included):
        checked_messages = checked_diffs = checked_tools = checked_background = 0
        for group in included:
            data = (self.output / group["file"]).read_bytes()
            text = data.decode("utf-8")
            assert digest(data) == group["output_sha256"], group["file"]
            assert len(re.findall(r"^### message \d+ ", text, re.M)) == len(group["messages"]), group["file"]
            assert len(re.findall(r"^### Edit \d+ ", text, re.M)) == len(group["edits"]), group["file"]
            for owner in [group, *group["children"]]:
                for record in owner["messages"]:
                    for part in record["payload"].get("content", []):
                        if part.get("type") in ("input_text", "output_text", "text"):
                            assert part.get("text", "") in text, f"Missing message: {group['file']}"
                    checked_messages += 1
                    if owner is not group:
                        checked_background += 1
                for record in owner["operations"]:
                    payload = record["payload"]
                    assert (payload.get("input") or payload.get("arguments") or "") in text
                    checked_tools += 1
            for edit in group["edits"]:
                for change in edit["changes"]:
                    assert change.get("diff", "") in text, f"Missing edit: {group['file']}"
                    checked_diffs += 1
            # Our generated outer fences must be balanced even when tool output
            # itself contains Markdown or source-code fences.
            opened = None
            for line in text.splitlines():
                match = re.match(r"^(`{3,})(.*)$", line)
                if not match:
                    continue
                marker, remainder = match.groups()
                if opened is None:
                    opened = len(marker)
                elif len(marker) >= opened and not remainder.strip():
                    opened = None
            assert opened is None, f"Unclosed Markdown fence: {group['file']}"
        for attachment in self.attachments.values():
            assert digest((self.output / attachment["file"]).read_bytes()) == attachment["sha256"]
        return {"passed": True, "chat_files_checked": len(included),
                "messages_checked": checked_messages, "supporting_background_messages": checked_background,
                "structured_file_diffs_checked": checked_diffs, "tool_inputs_checked": checked_tools,
                "attachment_hashes_checked": len(self.attachments), "markdown_fences_balanced": True}

    def write_index(self, included):
        counts = {key: sum(g["counts"][key] for g in included) for key in (
            "user_messages", "assistant_messages", "tool_calls", "edit_operations", "shell_write_operations")}
        head = self.git("rev-parse", "HEAD").strip()
        lines = ["# Repository chat archive\n",
                 f"Exported {stamp(self.generated)} (Asia/Singapore, UTC+08:00), from locally available Codex "
                 f"and repository-specific VS Code records. Repository HEAD: `{head}`.\n",
                 f"**{len(included)} substantive chats**, {counts['user_messages']} user messages, "
                 f"{counts['assistant_messages']} assistant messages, {counts['tool_calls']} main-chat tool calls, "
                 f"**{counts['edit_operations']} recorded edit operations**, and {counts['shell_write_operations']} shell write operations. "
                 "Edit counts include supporting diagnostic work.\n",
                 "## Chats\n",
                 "| First message (Singapore) | Chat | User / assistant messages | Recorded edits |\n"
                 "| --- | --- | --- | --- |"]
        for group in included:
            c = group["counts"]
            lines.append(f"| {stamp(group['first'])[:19]} | [{group['title']}]({group['file']}) | "
                         f"{c['user_messages']} / {c['assistant_messages']} | {c['edit_operations']} |")
        lines += ["\n## What is preserved\n",
                  "- User and assistant messages, including IDE context supplied with actual requests, follow-ups, "
                  "code proposals, and progress updates. Messages retain their original wording.\n"
                  "- Exact structured edit diffs, including new/deleted files, intermediate fixes, tests, "
                  "and diagnostic scripts. Edits outside the repository are labeled as external diagnostic artifacts.\n"
                  "- Recorded tool inputs and outputs in expandable blocks. Original truncation and failure messages remain visible.\n"
                  "- Relevant Git diffs, with explicit evidence connecting matched edits to commits. Commits discussed as "
                  "earlier work are distinguished from edits actually recorded in a chat. A whole Git commit is not "
                  "assumed to have been authored entirely in that chat.\n"
                  "- Embedded image attachments saved under `attachments/`. Historical local-file links in message text "
                  "retain their original destinations and line references.\n"
                  "- Continued rollouts combined into their original chat; historical background work attached to its parent "
                  "without repeating inherited history. The original repeated user request at a continuation boundary is retained.\n",
                  "## Coverage and limits\n",
                  "This is an export of the records present on this machine, not a claim that every conversation ever "
                  "held about the project is recoverable. The oldest available repository chat began on **22 October 2026** "
                  "in Singapore time; the latest completed local chat was on **15 November 2026**. "
                  "No earlier local repository chats, archived rollouts, or separate cloud-chat transcript source were found. "
                  "Earlier code or cloud-agent work can appear in Git history, but Git cannot reconstruct missing dialogue.\n",
                  "System/developer instructions, internal reasoning, model/token telemetry, account identifiers from session "
                  "metadata, and empty UI context markers are excluded. Credential/configuration files were not used as "
                  "chat sources. The active export conversation is excluded because it was still running at the snapshot.\n",
                  "Structured diffs represent historical operations and may no longer apply to current files. "
                  "Some diagnostic artifacts and deleted/renamed files no longer exist in today's tree; their saved diffs "
                  "are still included. Shell-based edits may have no structured diff: their exact commands remain in the "
                  "transcript, and relevant committed versions are recovered where text matching supports it. "
                  "Binary assets are identified by Git; the export does not duplicate the entire repository's binary history.\n",
                  "## Omitted brief chats\n",
                  "| Chat | Reason |\n| --- | --- |"]
        for item in self.skipped:
            lines.append(f"| {item['title']} (`{item['id']}`) | {item['reason']} |")
        empty_count = sum(x["reason"] == "Empty chat" for x in self.vscode_inventory)
        setup_count = sum(x["reason"].startswith("Copilot setup") for x in self.vscode_inventory)
        lines += [f"\nAlso inspected repository-specific VS Code chat storage: {empty_count} empty sessions and "
                  f"{setup_count} setup-only Copilot session were omitted. The setup-only prompt was later handled "
                  "in the included **Check branch commit history** conversation. Unrelated-workspace conversations "
                  "were excluded before exporting.\n",
                  "## Reproduce\n",
                  "The exporter reads local source logs and databases without modifying them and writes only inside "
                  "this repository. It never runs commands contained in old chats.\n",
                  fence("python tools/export-chat-history.py" + "".join(f" --exclude-thread {tid}" for tid in self.args.exclude_thread), "powershell"),
                  "Source file hashes, included/skipped thread IDs, per-chat counts, recovered commit IDs, attachment "
                  "hashes, and validation results are recorded in [manifest.json](manifest.json).\n"]
        if self.warnings:
            lines += ["## Source limitations detected\n", "\n".join(f"- {x}" for x in self.warnings) + "\n"]
        (self.output / "README.md").write_text("\n".join(lines), encoding="utf-8", newline="\n")
        manifest = {"exported_at_utc": self.generated, "display_timezone": "Asia/Singapore", "repository": str(self.repo),
                    "git_head": head, "scope": "locally available repository conversations", "counts": counts,
                    "chats": [{k: g[k] for k in ("id", "title", "file", "first", "last", "logs", "counts", "git_commits", "output_sha256", "output_bytes") if k in g} for g in included],
                    "skipped": self.skipped, "vscode_sessions": self.vscode_inventory,
                    "sources": self.sources, "attachments": list(self.attachments.values()), "warnings": self.warnings,
                    "validation": self.validation}
        (self.output / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
        return manifest

    def run(self):
        self.load()
        self.inspect_vscode()
        included = self.classify()
        self.load_git(included)
        for group in included:
            self.export_chat(group)
        self.validation = self.validate(included)
        return self.write_index(included)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--codex-home", type=Path, default=Path.home() / ".codex")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--exclude-thread", action="append", default=[])
    args = parser.parse_args()
    args.output = args.output or args.repo / "notes" / "chat-history"
    manifest = Export(args).run()
    print(json.dumps({"chats": len(manifest["chats"]), "counts": manifest["counts"],
                      "attachments": len(manifest["attachments"]), "warnings": manifest["warnings"],
                      "output": str(args.output)}, indent=2))


if __name__ == "__main__":
    main()
