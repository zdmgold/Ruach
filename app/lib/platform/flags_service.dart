import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ruach/core/config/app_config.dart';
import 'package:ruach/core/ports/flags_port.dart';

/// Downloads the text at a URL, or throws.
typedef TextFetcher = Future<String> Function(Uri url);

/// Fetches `flags.json` from the website. With no site address yet, or on any
/// failure, the safe defaults apply (everything on).
final class FlagsService implements FlagsPort {
  FlagsService({String? url, TextFetcher? fetcher, this.timeout = const Duration(seconds: 5)})
      : _url = url ?? AppConfig.flagsUrl,
        _fetcher = fetcher ?? _httpGet;

  final String _url;
  final TextFetcher _fetcher;
  final Duration timeout;

  @override
  Future<RemoteFlags> fetch() async {
    if (_url.isEmpty) return RemoteFlags.defaults;
    final Uri? uri = Uri.tryParse(_url);
    if (uri == null || !uri.hasScheme) return RemoteFlags.defaults;
    try {
      final String text = await _fetcher(uri).timeout(timeout);
      return RemoteFlags.fromJson(jsonDecode(text));
    } on Object {
      return RemoteFlags.defaults;
    }
  }

  static Future<String> _httpGet(Uri url) async {
    final HttpClient client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final HttpClientRequest request = await client.getUrl(url);
      final HttpClientResponse response = await request.close();
      if (response.statusCode != 200) {
        throw HttpException('status ${response.statusCode}', uri: url);
      }
      return await response.transform(utf8.decoder).join();
    } finally {
      client.close(force: true);
    }
  }
}
