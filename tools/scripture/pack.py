"""Writes one full-Bible pack per language (gzip JSON), its SHA-256, and the
manifest. Used in batch p8a; written now so the parsers are exercised once.

    python3 tools/scripture/pack.py OUT_DIR
"""
import gzip
import json
import os
import sys

import common
import curate
from common import BOOKS


def main():
    out_dir = sys.argv[1]
    os.makedirs(out_dir, exist_ok=True)
    sources = common.load_sources()
    parsed = curate.parse_all(common.cache_path)
    manifest = {'schema': 1, 'packs': []}
    for lang in curate.LANGUAGE_ORDER:
        books = {}
        for osis, _name, _usfx in BOOKS:
            chapters = parsed[lang][osis]
            top = max(chapters)
            books[osis] = [[chapters.get(c, {}).get(v, '') for v in range(1, (max(chapters[c]) if c in chapters else 0) + 1)] for c in range(1, top + 1)]
        pack = {'schema': 1, 'language': lang, 'source': [s['name'] for s in sources if s['language'] == lang], 'books': books}
        data = json.dumps(pack, ensure_ascii=False, separators=(',', ':'), sort_keys=True).encode('utf-8')
        path = os.path.join(out_dir, lang + '.json.gz')
        with gzip.GzipFile(path, 'wb', compresslevel=9, mtime=0) as f:
            f.write(data)
        manifest['packs'].append({'language': lang, 'file': lang + '.json.gz', 'bytes': os.path.getsize(path), 'sha256': common.sha256_file(path)})
    with open(os.path.join(out_dir, 'manifest.json'), 'w', encoding='utf-8') as f:
        json.dump(manifest, f, indent=1)
        f.write('\n')


if __name__ == '__main__':
    main()
