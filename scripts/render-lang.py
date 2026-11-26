#!/usr/bin/env python3
"""Render src/<appid>.lang from tosapp.json.

The .lang file is what the App Center shows to users, and it used to be edited by
hand next to tosapp.json. That drift is exactly what the 1.30.4-3 review caught:
`tosapp.json.help` pointed at the privacy policy while the packaged `config.ini`
(and `release_note`) still carried the old text, so C5 "privacy policy is not
accessible" and F5 "declared functionality is not usable" were raised again.

This script makes tosapp.json the single source of truth: the build calls it
before staging, so a packaged .lang can only ever contain the spec's text.
Untranslated languages fall back to English (allowed by the official guide).

Usage: python3 scripts/render-lang.py [project-dir]
"""
from __future__ import annotations

import json
import os
import re
import sys

LANG_CODES = ["en-us", "zh-cn", "zh-hk", "fr-fr", "de-de", "it-it", "es-es",
              "hu-hu", "ja-jp", "ko-kr", "pl-pl", "ru-ru", "tr-tr", "pt-pt",
              "ar-sa", "cs-cz", "he-il", "id-id", "nb-no", "nl-nl", "sv-se",
              "th-th", "vi-vn"]

HEADER = """# ===========================================================================
# Multilingual file for the TOS 7 Docker application "{appid}".
# File name MUST be: <appid>.lang.  23-language superset (14 required by TOS).
# The App Center picks the text matching the user's device language;
# untranslated nodes fall back to English, which the official guide allows.
# Fields: name (app title), auth (upstream author), descript (up to 512
# chars), release_note, important (up to 512 chars).
# GENERATED FILE - do not edit by hand. The text lives in tosapp.json
# ("descript", "release_note", "important", "translations") and
# scripts/render-lang.py renders this file during the build.
# ===========================================================================
"""


def esc(text: object) -> str:
    """Make a string safe inside a double-quoted .lang value (single line).

    The store parser treats ';' as an INI comment start, so an ASCII semicolon
    would truncate the description and leave a stray quote. It is rejected here
    instead of silently shipping a broken description.
    """
    s = " ".join(str(text).split())
    if ";" in s:
        raise SystemExit("FATAL: ASCII ';' is not allowed in .lang values "
                         "(the store parser treats it as a comment): " + s[:120])
    return s.replace("\\", "\\\\").replace('"', "'")


def main() -> int:
    project = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else ".")
    spec = json.loads(open(os.path.join(project, "tosapp.json"), encoding="utf-8").read())
    appid = spec["app_id"]
    tr = spec.get("translations") or {}

    out = [HEADER.format(appid=appid)]
    for code in LANG_CODES:
        t = tr.get(code) or {}
        name = t.get("name") or spec["title"]
        out.append(
            f"[{code}]\n"
            f'name         = "{esc(name)}"\n'
            f'auth         = "{esc(spec["auth"])}"\n'
            f'version      = "@@VERSION@@"\n'
            f'descript     = "{esc(t.get("descript") or spec["descript"])}"\n'
            f'release_note = "{esc(t.get("release_note") or spec["release_note"])}"\n'
            f'important    = "{esc(t.get("important") or spec["important"])}"\n\n')

    path = os.path.join(project, "src", f"{appid}.lang")
    with open(path, "w", encoding="utf-8") as fh:
        fh.write("".join(out))

    # Fail fast on the limits the platform enforces.
    for field, limit in (("descript", 512), ("important", 512),
                         ("release_note", 2048), ("name", 64)):
        val = esc(spec.get(field) or "")
        if len(val) > limit:
            raise SystemExit(f"FATAL: [en-us] {field} is {len(val)} chars (limit {limit})")
        for code in LANG_CODES:
            t = tr.get(code) or {}
            if t.get(field) and len(esc(t[field])) > limit:
                raise SystemExit(f"FATAL: [{code}] {field} is {len(esc(t[field]))} chars "
                                 f"(limit {limit})")
    print(f"rendered {os.path.relpath(path, project)} "
          f"({len(LANG_CODES)} languages, version token @@VERSION@@)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
