#!/usr/bin/env python3
"""Usage summary for Claude Code and OpenCode as one JSON object on stdout.

Run on demand by AgentsPanel.qml when it opens, never on a timer.
Claude's plan limits come from the same OAuth endpoint Claude Code's /usage
uses (undocumented, may change); token counts are summed from the local
session logs. OpenCode is read straight from its sqlite database.
"""
import json
import os
import sqlite3
import time
import urllib.error
import urllib.request
from datetime import datetime, timedelta

HOME = os.path.expanduser("~")
now = datetime.now().astimezone()
today = now.replace(hour=0, minute=0, second=0, microsecond=0)
week = today - timedelta(days=6)


CACHE = f"{HOME}/.cache/quickshell-claude-limits.json"


def claude_limits():
    # The endpoint rate-limits (429) quickly, so reuse a recent answer and
    # fall back to the last good one when it refuses.
    cached = {}
    try:
        with open(CACHE) as f:
            cached = json.load(f)
    except Exception:
        pass
    now_ts = time.time()
    good = cached.get("data")
    if good and now_ts - cached.get("at", 0) < 60:
        return good
    # Don't poke the endpoint again before its Retry-After has passed.
    wait = cached.get("blocked_until", 0) - now_ts
    if wait > 0:
        return good or {"error": "rate limited", "retry_in": int(wait)}
    data = claude_limits_fetch()
    if "error" in data:
        if "retry_in" in data:
            cached["blocked_until"] = now_ts + data["retry_in"]
            save(cached)
        return good or data
    save({"at": now_ts, "data": data})
    return data


def save(obj):
    os.makedirs(os.path.dirname(CACHE), exist_ok=True)
    with open(CACHE, "w") as f:
        json.dump(obj, f)


def claude_limits_fetch():
    try:
        with open(f"{HOME}/.claude/.credentials.json") as f:
            creds = json.load(f)["claudeAiOauth"]
        token = creds["accessToken"]
        req = urllib.request.Request(
            "https://api.anthropic.com/api/oauth/usage",
            headers={"Authorization": f"Bearer {token}", "anthropic-beta": "oauth-2025-04-20"},
        )
        data = json.load(urllib.request.urlopen(req, timeout=6))
        out = {"plan": creds.get("subscriptionType")}
        for key in ("five_hour", "seven_day"):
            w = data.get(key)
            if w:
                out[key] = {"percent": w["utilization"], "resets_at": w["resets_at"]}
        return out
    except urllib.error.HTTPError as e:
        out = {"error": str(e)}
        if e.code == 429:
            out["retry_in"] = int(e.headers.get("Retry-After", 120))
        return out
    except Exception as e:
        return {"error": str(e)}


def claude_tokens():
    totals = {"today": 0, "week": 0}
    seen = set()
    root = f"{HOME}/.claude/projects"
    cutoff = week.timestamp()
    for dirpath, _, files in os.walk(root):
        for name in files:
            path = os.path.join(dirpath, name)
            if not name.endswith(".jsonl") or os.path.getmtime(path) < cutoff:
                continue
            with open(path, errors="ignore") as f:
                for line in f:
                    if '"usage"' not in line:
                        continue
                    try:
                        d = json.loads(line)
                        msg = d["message"]
                        u = msg["usage"]
                        ts = datetime.fromisoformat(d["timestamp"].replace("Z", "+00:00"))
                    except Exception:
                        continue
                    # The same assistant message is logged once per content block.
                    key = msg.get("id")
                    if key in seen or ts < week:
                        continue
                    seen.add(key)
                    n = (u.get("input_tokens", 0) + u.get("output_tokens", 0)
                         + u.get("cache_creation_input_tokens", 0))
                    totals["week"] += n
                    if ts >= today:
                        totals["today"] += n
    return totals


def opencode():
    out = {"today": {"tokens": 0, "cost": 0.0}, "week": {"tokens": 0, "cost": 0.0}}
    try:
        db = sqlite3.connect(f"file:{HOME}/.local/share/opencode/opencode.db?mode=ro", uri=True)
        rows = db.execute(
            "select time_created, json_extract(data,'$.tokens.input'),"
            " json_extract(data,'$.tokens.output'), json_extract(data,'$.tokens.cache.write'),"
            " json_extract(data,'$.cost') from message"
            " where json_extract(data,'$.role')='assistant' and time_created >= ?",
            (int(week.timestamp() * 1000),),
        )
        for created, i, o, cw, cost in rows:
            n = (i or 0) + (o or 0) + (cw or 0)
            for k in ("week",) + (("today",) if created / 1000 >= today.timestamp() else ()):
                out[k]["tokens"] += n
                out[k]["cost"] += cost or 0
    except Exception as e:
        out["error"] = str(e)
    return out


print(json.dumps({
    "claude": {"limits": claude_limits(), "tokens": claude_tokens()},
    "opencode": opencode(),
}))
