import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:ruach/core/ports/verse_source.dart';

/// Reads a language's curated verses from the app's bundled assets
/// (`assets/verses/<language>.json.gz`) and decodes them.
final class AssetVerseSource implements VerseDataSource {
  AssetVerseSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<Object?> load(String language) async {
    final ByteData data;
    try {
      data = await _bundle.load('assets/verses/$language.json.gz');
    } on FlutterError {
      return null;
    }
    final Uint8List bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    return jsonDecode(utf8.decode(gzip.decode(bytes)));
  }
}
