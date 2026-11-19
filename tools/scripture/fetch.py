"""Downloads every source file at its recorded commit into the cache folder
and checks its SHA-256 against sources.json.

    python3 tools/scripture/fetch.py            # download missing, verify all
    python3 tools/scripture/fetch.py --record   # write the checksums (first run only)
"""
import json
import os
import sys
import urllib.request

import common


def url(source):
    return 'https://raw.githubusercontent.com/%s/%s/%s' % (source['repo'], source['commit'], source['path'])


def main():
    record = '--record' in sys.argv
    sources = common.load_sources()
    os.makedirs(common.CACHE_DIR, exist_ok=True)
    failed = False
    for source in sources:
        path = common.cache_path(source)
        if not os.path.exists(path):
            print('downloading', source['file'])
            with urllib.request.urlopen(url(source), timeout=120) as response, open(path, 'wb') as out:
                out.write(response.read())
        digest = common.sha256_file(path)
        if record:
            source['sha256'] = digest
        elif source.get('sha256') != digest:
            print('CHECKSUM MISMATCH', source['file'], digest)
            failed = True
        else:
            print('ok', source['file'])
    if record:
        with open(common.SOURCES_JSON, 'w', encoding='utf-8') as f:
            json.dump(sources, f, ensure_ascii=False, indent=2)
            f.write('\n')
    if failed:
        sys.exit(1)


if __name__ == '__main__':
    main()
