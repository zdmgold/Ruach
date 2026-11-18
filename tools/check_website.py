#!/usr/bin/env python3
"""Checks the static website: every local link resolves, every page has a
title, a lang attribute and a viewport tag, and no page links to a script.

Run from the repository root:  python3 tools/check_website.py
"""
import re
import sys
from html.parser import HTMLParser
from pathlib import Path

SITE = Path("website")


class Page(HTMLParser):
    def __init__(self):
        super().__init__()
        self.links = []
        self.has_title = False
        self.has_viewport = False
        self.has_lang = False
        self.scripts = 0

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "html" and a.get("lang"):
            self.has_lang = True
        if tag == "title":
            self.has_title = True
        if tag == "meta" and a.get("name") == "viewport":
            self.has_viewport = True
        if tag == "script":
            self.scripts += 1
        for key in ("href", "src"):
            if key in a and a[key]:
                self.links.append(a[key])


def main() -> int:
    if not SITE.is_dir():
        print("check_website: no website/ directory yet.")
        return 0

    problems = []
    pages = sorted(SITE.glob("*.html"))
    if not pages:
        problems.append("website/ has no HTML pages")

    for page in pages:
        parser = Page()
        parser.feed(page.read_text(encoding="utf-8"))
        if not parser.has_title:
            problems.append(f"{page}: missing <title>")
        if not parser.has_viewport:
            problems.append(f"{page}: missing viewport meta tag")
        if not parser.has_lang:
            problems.append(f"{page}: <html> has no lang attribute")
        if parser.scripts:
            problems.append(f"{page}: contains a <script> (the site is script-free)")
        for link in parser.links:
            if re.match(r"^(https?:|mailto:|tel:|#)", link):
                continue
            target = (page.parent / link.split("#")[0]).resolve()
            if not target.exists():
                problems.append(f"{page}: broken local link {link}")

    if problems:
        print("check_website: problems found")
        for p in problems:
            print("  " + p)
        return 1

    print(f"check_website: {len(pages)} page(s) OK.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
