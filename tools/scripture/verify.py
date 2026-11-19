"""The data gate. Re-reads the pinned source files and checks:

1. every source file matches its recorded SHA-256;
2. each language has 66 books and no empty verse, and counts are in a sane range;
3. every bundled curated verse equals the source text byte for byte;
4. the bundles hold exactly the references in curated.json, with the right
   moment counts (blueprint section 5).

    python3 tools/scripture/fetch.py && python3 tools/scripture/verify.py
"""
import gzip
import json
import os
import sys

import common
import curate
import parse

EXPECTED_MOMENTS = {
    'upgrade': 6, 'track-intro': 16, 'welcome-back': 20, 'milestone': 30,
    'win': 40, 'podium': 40, 'encouragement': 60, 'daily': 120,
}


def main():
    problems = []
    sources = common.load_sources()
    for source in sources:
        path = common.cache_path(source)
        if not os.path.exists(path):
            problems.append('missing source file ' + source['file'])
        elif common.sha256_file(path) != source.get('sha256'):
            problems.append('checksum differs for ' + source['file'])
    if problems:
        print('\n'.join(problems))
        sys.exit(1)

    parsed = curate.parse_all(common.cache_path)
    for lang, books in parsed.items():
        if len(books) != 66:
            problems.append('%s: %d books, expected 66' % (lang, len(books)))
        total = parse.verse_count(books)
        if not 30500 <= total <= 31500:
            problems.append('%s: %d verses is outside the expected range' % (lang, total))

    with open(common.CURATED_JSON, encoding='utf-8') as f:
        curated = json.load(f)
    for moment, count in EXPECTED_MOMENTS.items():
        if len(curated.get(moment, [])) != count:
            problems.append('curated %s has %d, expected %d' % (moment, len(curated.get(moment, [])), count))
    refs = {r for refs in curated.values() for r in refs}

    for lang in curate.LANGUAGE_ORDER:
        path = os.path.join(common.VERSES_DIR, lang + '.json.gz')
        if not os.path.exists(path):
            problems.append('missing bundle ' + path)
            continue
        with gzip.open(path, 'rb') as f:
            bundle = json.loads(f.read().decode('utf-8'))
        if {v['ref'] for v in bundle['verses']} != refs:
            problems.append('%s: bundle references differ from curated.json' % lang)
        for verse in bundle['verses']:
            book, chapter, number = verse['ref'].split('.')
            source_text = parsed[lang].get(book, {}).get(int(chapter), {}).get(int(number))
            if source_text != verse['text']:
                problems.append('%s %s differs from its source' % (lang, verse['ref']))
            if not verse['text'].strip():
                problems.append('%s %s is empty' % (lang, verse['ref']))

    if problems:
        print('\n'.join(problems[:50]))
        sys.exit(1)
    print('Scripture data verified: %d languages, %d curated verses each.' % (len(parsed), len(refs)))


if __name__ == '__main__':
    main()
