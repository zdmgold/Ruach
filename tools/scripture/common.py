"""Shared constants for the scripture tools (blueprint section 5).

Canonical key: OSIS book id, chapter, verse. The 66 books of the Protestant
canon are the only books used, because they are common to every canon the
eleven sources contain.
"""
import hashlib
import re
import json
import os

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SOURCES_JSON = os.path.join(os.path.dirname(__file__), 'sources.json')
CURATED_JSON = os.path.join(os.path.dirname(__file__), 'curated.json')
VERSES_DIR = os.path.join(ROOT, 'app', 'assets', 'verses')
CACHE_DIR = os.environ.get('RUACH_SCRIPTURE_CACHE', os.path.join(ROOT, '.scripture_cache'))

# (OSIS id, English name, USFX id)
BOOKS = [
    ('Gen', 'Genesis', 'GEN'), ('Exod', 'Exodus', 'EXO'), ('Lev', 'Leviticus', 'LEV'),
    ('Num', 'Numbers', 'NUM'), ('Deut', 'Deuteronomy', 'DEU'), ('Josh', 'Joshua', 'JOS'),
    ('Judg', 'Judges', 'JDG'), ('Ruth', 'Ruth', 'RUT'), ('1Sam', '1 Samuel', '1SA'),
    ('2Sam', '2 Samuel', '2SA'), ('1Kgs', '1 Kings', '1KI'), ('2Kgs', '2 Kings', '2KI'),
    ('1Chr', '1 Chronicles', '1CH'), ('2Chr', '2 Chronicles', '2CH'), ('Ezra', 'Ezra', 'EZR'),
    ('Neh', 'Nehemiah', 'NEH'), ('Esth', 'Esther', 'EST'), ('Job', 'Job', 'JOB'),
    ('Ps', 'Psalms', 'PSA'), ('Prov', 'Proverbs', 'PRO'), ('Eccl', 'Ecclesiastes', 'ECC'),
    ('Song', 'Song of Solomon', 'SNG'), ('Isa', 'Isaiah', 'ISA'), ('Jer', 'Jeremiah', 'JER'),
    ('Lam', 'Lamentations', 'LAM'), ('Ezek', 'Ezekiel', 'EZK'), ('Dan', 'Daniel', 'DAN'),
    ('Hos', 'Hosea', 'HOS'), ('Joel', 'Joel', 'JOL'), ('Amos', 'Amos', 'AMO'),
    ('Obad', 'Obadiah', 'OBA'), ('Jonah', 'Jonah', 'JON'), ('Mic', 'Micah', 'MIC'),
    ('Nah', 'Nahum', 'NAM'), ('Hab', 'Habakkuk', 'HAB'), ('Zeph', 'Zephaniah', 'ZEP'),
    ('Hag', 'Haggai', 'HAG'), ('Zech', 'Zechariah', 'ZEC'), ('Mal', 'Malachi', 'MAL'),
    ('Matt', 'Matthew', 'MAT'), ('Mark', 'Mark', 'MRK'), ('Luke', 'Luke', 'LUK'),
    ('John', 'John', 'JHN'), ('Acts', 'Acts', 'ACT'), ('Rom', 'Romans', 'ROM'),
    ('1Cor', '1 Corinthians', '1CO'), ('2Cor', '2 Corinthians', '2CO'), ('Gal', 'Galatians', 'GAL'),
    ('Eph', 'Ephesians', 'EPH'), ('Phil', 'Philippians', 'PHP'), ('Col', 'Colossians', 'COL'),
    ('1Thess', '1 Thessalonians', '1TH'), ('2Thess', '2 Thessalonians', '2TH'),
    ('1Tim', '1 Timothy', '1TI'), ('2Tim', '2 Timothy', '2TI'), ('Titus', 'Titus', 'TIT'),
    ('Phlm', 'Philemon', 'PHM'), ('Heb', 'Hebrews', 'HEB'), ('Jas', 'James', 'JAS'),
    ('1Pet', '1 Peter', '1PE'), ('2Pet', '2 Peter', '2PE'), ('1John', '1 John', '1JN'),
    ('2John', '2 John', '2JN'), ('3John', '3 John', '3JN'), ('Jude', 'Jude', 'JUD'),
    ('Rev', 'Revelation', 'REV'),
]
OSIS_IDS = [b[0] for b in BOOKS]
assert len(BOOKS) == 66

_ALIASES = {}
for i, (osis, name, usfx) in enumerate(BOOKS):
    for key in (osis, name, usfx):
        _ALIASES[key.lower().replace(' ', '')] = osis
# Spellings seen in the source files.
_ALIASES.update({
    'songofsongs': 'Song', 'songofsolomon': 'Song', 'sng': 'Song', 'cant': 'Song',
    'psalm': 'Ps', 'psalms': 'Ps', 'psa': 'Ps', 'revelationofjohn': 'Rev',
    'ezekiel': 'Ezek', 'ezk': 'Ezek', 'joel': 'Joel', 'jol': 'Joel',
    'philemon': 'Phlm', 'phm': 'Phlm', 'philippians': 'Phil', 'php': 'Phil',
    'james': 'Jas', 'jas': 'Jas', 'nahum': 'Nah', 'nam': 'Nah',
    'judges': 'Judg', 'ecclesiastes': 'Eccl', 'esther': 'Esth',
    '1kings': '1Kgs', '2kings': '2Kgs', '1ki': '1Kgs', '2ki': '2Kgs',
    '1samuel': '1Sam', '2samuel': '2Sam',
})


def osis_id(name):
    """OSIS id for any spelling seen in the sources, or None."""
    name = name.strip().replace('.', '')
    m = re.match(r'^(iii|ii|i)\s+(.+)$', name, re.IGNORECASE)
    if m:
        name = {'i': '1', 'ii': '2', 'iii': '3'}[m.group(1).lower()] + m.group(2)
    return _ALIASES.get(name.lower().replace(' ', ''))


def sha256_file(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            h.update(chunk)
    return h.hexdigest()


def load_sources():
    with open(SOURCES_JSON, encoding='utf-8') as f:
        return json.load(f)


def cache_path(source):
    return os.path.join(CACHE_DIR, source['file'])
