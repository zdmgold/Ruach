import 'package:ruach/core/ports/device_ports.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// The system share sheet.
final class ShareService implements SharePort {
  @override
  Future<bool> shareText(String text) async {
    if (text.isEmpty) return false;
    try {
      final ShareResult result = await SharePlus.instance.share(ShareParams(text: text));
      return result.status != ShareResultStatus.unavailable;
    } on Object {
      return false;
    }
  }
}

/// Opens web pages and mail links outside the app.
final class UrlService implements UrlPort {
  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object {
      return false;
    }
  }
}
