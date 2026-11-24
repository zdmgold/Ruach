import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruach/platform/asset_verse_source.dart';

final class _MemoryBundle extends CachingAssetBundle {
  _MemoryBundle(this.files);

  final Map<String, List<int>> files;

  @override
  Future<ByteData> load(String key) async {
    final List<int>? bytes = files[key];
    if (bytes == null) throw FlutterError('Unable to load asset: $key');
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}

void main() {
  test('decodes a gzipped verse file and returns null for a missing language', () async {
    final List<int> gz = gzip.encode(utf8.encode(jsonEncode(<String, Object?>{'verses': <Object?>[]})));
    final AssetVerseSource source = AssetVerseSource(
      bundle: _MemoryBundle(<String, List<int>>{'assets/verses/en.json.gz': gz}),
    );
    expect(await source.load('en'), <String, Object?>{'verses': <Object?>[]});
    expect(await source.load('xx'), isNull);
  });
}
