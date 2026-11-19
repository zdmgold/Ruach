"""Selects the curated verses and writes the per-language bundles.

Reads candidates.json (a human-ordered list of references per moment tag),
keeps a reference only if it exists with text in all 11 languages and its
chapter has the same verse count in every language (so versification
differences cannot put the wrong verse on a card), fills each moment's quota
in priority order without using a verse twice, writes curated.json, and writes
app/assets/verses/<language>.json.gz.

    python3 tools/scripture/curate.py
"""
import gzip
import json
import os
import sys

import common
import parse
from common import BOOKS, VERSES_DIR, load_sources

QUOTAS = [
    ('upgrade', 6), ('track-intro', 16), ('welcome-back', 20), ('milestone', 30),
    ('win', 40), ('podium', 40), ('encouragement', 60), ('daily', 120),
]
LANGUAGE_ORDER = ['en', 'es', 'fr', 'de', 'pt_BR', 'ar', 'hi', 'ja', 'ko', 'zh_Hans', 'he']
SOURCE_NAMES = {s['language']: s['name'] for s in load_sources()}


def parse_all(resolver):
    sources = load_sources()
    return {lang: parse.parse_language(lang, sources, resolver) for lang in LANGUAGE_ORDER}


def ref_ok(parsed, ref, exceptions=()):
    book, chapter, verse = ref.split('.')
    chapter, verse = int(chapter), int(verse)
    counts = set()
    for lang in LANGUAGE_ORDER:
        verses = parsed[lang].get(book, {}).get(chapter, {})
        if not verses.get(verse):
            return 'missing in ' + lang
        counts.add(len(verses))
    if len(counts) != 1 and ref not in exceptions:
        return 'chapter verse counts differ'
    return None


def select(parsed, candidates):
    exceptions = set(candidates.get('verified_exceptions', {}))
    used = set()
    chosen = {}
    problems = []
    for moment, quota in QUOTAS:
        picked = []
        for ref in candidates[moment]:
            if len(picked) == quota:
                break
            if ref in used:
                continue
            why = ref_ok(parsed, ref, exceptions)
            if why:
                problems.append('%s %s skipped: %s' % (moment, ref, why))
                continue
            used.add(ref)
            picked.append(ref)
        if len(picked) < quota:
            problems.append('SHORT %s: %d of %d' % (moment, len(picked), quota))
        chosen[moment] = picked
    return chosen, problems


def write_bundles(parsed, chosen):
    os.makedirs(VERSES_DIR, exist_ok=True)
    moments_of = {}
    for moment, refs in chosen.items():
        for ref in refs:
            moments_of.setdefault(ref, []).append(moment)
    order = {b[0]: i for i, b in enumerate(BOOKS)}

    def key(ref):
        b, c, v = ref.split('.')
        return (order[b], int(c), int(v))

    refs = sorted(moments_of, key=key)
    for lang in LANGUAGE_ORDER:
        verses = []
        for ref in refs:
            b, c, v = ref.split('.')
            verses.append({'ref': ref, 'moments': moments_of[ref], 'text': parsed[lang][b][int(c)][int(v)]})
        bundle = {'schema': 1, 'language': lang, 'source': SOURCE_NAMES[lang], 'verses': verses}
        data = json.dumps(bundle, ensure_ascii=False, separators=(',', ':'), sort_keys=True).encode('utf-8')
        # mtime=0 so the same data always gives the same bytes.
        with gzip.GzipFile(os.path.join(VERSES_DIR, lang + '.json.gz'), 'wb', compresslevel=9, mtime=0) as f:
            f.write(data)
    return refs


def main():
    resolver = lambda s: common.cache_path(s)
    parsed = parse_all(resolver)
    with open(os.path.join(os.path.dirname(__file__), 'candidates.json'), encoding='utf-8') as f:
        candidates = json.load(f)
    chosen, problems = select(parsed, candidates)
    for p in problems:
        print(p)
    if any(p.startswith('SHORT') for p in problems):
        sys.exit(1)
    with open(common.CURATED_JSON, 'w', encoding='utf-8') as f:
        json.dump(chosen, f, ensure_ascii=False, indent=1)
        f.write('\n')
    refs = write_bundles(parsed, chosen)
    print('curated verses: %d' % len(refs))


if __name__ == '__main__':
    main()
