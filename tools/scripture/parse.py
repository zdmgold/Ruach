"""Parses each source file into one canonical structure:

    {osis_book: {chapter(int): {verse(int): text}}}

Only recorded, scripted corrections are applied (see CORRECTIONS), and each
one is counted so it can be logged in docs/scripture_sources.md.
"""
import json
import re
import xml.etree.ElementTree as ET
from collections import defaultdict

from common import BOOKS, osis_id

# Text elements that never belong to the verse text.
_SKIP_USFX = {'f', 'x', 'fig', 'rem', 'ide', 'id', 'h', 'toc', 'mt', 's', 's1', 'r', 'd', 'cl', 'sp'}

# Scripted corrections: (language, regex, replacement, why)
CORRECTIONS = [
    ('fr', re.compile(r"''"), "'", 'doubled apostrophe in the French mirror (none found in the pinned file)'),
    ('hi', re.compile(r' ?# ?'), ' ', 'footnote anchor # left in the Hindi mirror text'),
]
correction_counts = defaultdict(int)


def _clean(language, text):
    text = text.replace(' ', ' ')
    text = re.sub(r'\s+', ' ', text).strip()
    for lang, pattern, replacement, _why in CORRECTIONS:
        if lang == language:
            text, n = pattern.subn(replacement, text)
            correction_counts[(lang, pattern.pattern)] += n
    return text


def _put(result, book, chapter, verse, text):
    chapters = result.setdefault(book, {})
    verses = chapters.setdefault(chapter, {})
    if verse in verses:
        # A verse split over several elements: join.
        verses[verse] = (verses[verse] + ' ' + text).strip()
    else:
        verses[verse] = text


def parse_usfx(path, language):
    result = {}
    tree = ET.parse(path)
    for book_el in tree.getroot().iter('book'):
        book = osis_id(book_el.get('id', ''))
        if book is None:
            raise ValueError('unknown book id %r in %s' % (book_el.get('id'), path))
        state = {'chapter': 0, 'verse': None, 'buf': []}

        def flush():
            if state['verse'] is not None and state['chapter']:
                text = _clean(language, ''.join(state['buf']))
                if text:
                    _put(result, book, state['chapter'], state['verse'], text)
            state['verse'] = None
            state['buf'] = []

        def walk(el):
            tag = el.tag
            if tag == 'c':
                flush()
                state['chapter'] = int(el.get('id'))
            elif tag == 'v':
                flush()
                vid = el.get('id', '')
                m = re.match(r'(\d+)', vid)
                state['verse'] = int(m.group(1)) if m else None
            elif tag == 've':
                flush()
            if tag in _SKIP_USFX:
                if el.tail and state['verse'] is not None:
                    state['buf'].append(el.tail)
                return
            if el.text and state['verse'] is not None and tag not in ('c', 'v', 've'):
                state['buf'].append(el.text)
            for child in el:
                walk(child)
            if el.tail and state['verse'] is not None:
                state['buf'].append(el.tail)

        for child in book_el:
            walk(child)
        flush()
    return result


_NO_SPACE_BETWEEN_LINES = {'ja', 'zh_Hans'}


def parse_osis(path, language):
    """OSIS comes in two styles: a verse element that contains its text, and
    milestone verses (sID and eID) used in poetry. Both are handled."""
    result = {}
    tree = ET.parse(path)
    line_gap = '' if language in _NO_SPACE_BETWEEN_LINES else ' '
    state = {'ref': None, 'buf': []}

    def flush():
        ref = state['ref']
        if ref is not None:
            text = _clean(language, ''.join(state['buf']))
            if text:
                _put(result, ref[0], ref[1], ref[2], text)
        state['ref'] = None
        state['buf'] = []

    def parse_ref(oid):
        parts = oid.split()[0].split('.')
        if len(parts) != 3:
            return None
        parts = [re.split(r'[!@]', x)[0] for x in parts]
        if not (parts[1].isdigit() and parts[2].isdigit()):
            return None
        book = osis_id(parts[0])
        if book is None:
            raise ValueError('unknown book %r in %s' % (parts[0], path))
        return (book, int(parts[1]), int(parts[2]))

    def add(text):
        if state['ref'] is not None and text:
            state['buf'].append(text)

    def walk(el):
        tag = el.tag.split('}')[-1]
        if tag == 'verse':
            if el.get('sID') and not len(el) and not (el.text or '').strip():
                flush()
                state['ref'] = parse_ref(el.get('sID'))
                add(el.tail)
                return
            if el.get('eID') and not len(el):
                flush()
                return
            if el.get('osisID'):
                flush()
                state['ref'] = parse_ref(el.get('osisID'))
                add(el.text)
                for child in el:
                    walk(child)
                flush()
                add(el.tail)
                return
        if tag in ('note', 'rdg', 'title', 'header', 'catchWord'):
            add(el.tail)
            return
        add(el.text)
        for child in el:
            walk(child)
        if tag in ('l', 'lb', 'p', 'lg'):
            add(line_gap)
        add(el.tail)

    walk(tree.getroot())
    flush()
    return result


def parse_beblia(path, language):
    result = {}
    tree = ET.parse(path)
    for book_el in tree.getroot().iter('book'):
        number = int(book_el.get('number'))
        book = BOOKS[number - 1][0]
        for chapter_el in book_el.iter('chapter'):
            chapter = int(chapter_el.get('number'))
            for verse_el in chapter_el.iter('verse'):
                text = _clean(language, ''.join(verse_el.itertext()))
                if text:
                    _put(result, book, chapter, int(verse_el.get('number')), text)
    return result


def parse_scrollmapper(path, language, by_position=False):
    result = {}
    with open(path, encoding='utf-8') as f:
        data = json.load(f)
    for index, book_json in enumerate(data['books']):
        if by_position:
            book = BOOKS[index][0]
        else:
            book = osis_id(book_json['name'])
            if book is None:
                raise ValueError('unknown book name %r in %s' % (book_json['name'], path))
        for chapter_json in book_json['chapters']:
            for verse_json in chapter_json['verses']:
                text = _clean(language, verse_json['text'])
                if text:
                    _put(result, book, int(chapter_json['chapter']), int(verse_json['verse']), text)
    return result


PARSERS = {
    'usfx': parse_usfx,
    'osis': parse_osis,
    'beblia': parse_beblia,
    'scrollmapper': parse_scrollmapper,
    'scrollmapper_positional': lambda p, l: parse_scrollmapper(p, l, by_position=True),
}


def merge(parts):
    """Merges several parsed structures (Hebrew: Old Testament and New
    Testament files). A book present in two parts is an error."""
    merged = {}
    for part in parts:
        for book, chapters in part.items():
            if book in merged:
                raise ValueError('book %s appears in two parts' % book)
            merged[book] = chapters
    return merged


def parse_language(language, sources, resolver):
    """Parses every file of `language`. `resolver(source)` returns the local
    path of a fetched file."""
    parts = []
    for source in sources:
        if source['language'] != language:
            continue
        parts.append(PARSERS[source['format']](resolver(source), language))
    return merge(parts)


def verse_count(parsed):
    return sum(len(v) for chapters in parsed.values() for v in chapters.values())
