import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;
import 'package:ruach/app_services.dart';
import 'package:ruach/platform/ad_service.dart';
import 'package:ruach/providers/ad_provider.dart';

/// Loads the one banner and hands menu screens the widget that draws it, but
/// only once an ad is really loaded, so no empty slot is ever shown.
final class AdBannerHost extends ChangeNotifier implements BannerHost {
  AdBannerHost(this._service, this._ads) {
    _ads.addListener(_sync);
    _sync();
  }

  static const int _maxAttempts = 6;
  static const Duration _retryAfter = Duration(seconds: 5);

  final AdService _service;
  final AdProvider _ads;

  bool _loaded = false;
  bool _loading = false;
  int _attempts = 0;
  Timer? _retry;

  @override
  Listenable get changes => this;

  @override
  Widget? get banner => _loaded && _ads.bannersAllowed ? _AdBannerView(_service) : null;

  void _sync() {
    if (!_ads.bannersAllowed) {
      _retry?.cancel();
      _attempts = 0;
      if (_loaded) {
        _loaded = false;
        notifyListeners();
        SchedulerBinding.instance.addPostFrameCallback((_) => _service.disposeBanner());
      }
      return;
    }
    if (_loaded || _loading) return;
    unawaited(_load());
  }

  Future<void> _load() async {
    _loading = true;
    final double height = await _service.bannerHeight(0);
    _loading = false;
    if (height > 0 && _ads.bannersAllowed) {
      _loaded = true;
      _attempts = 0;
      notifyListeners();
      return;
    }
    // The ad network may still be starting; try a few more times.
    if (++_attempts < _maxAttempts) {
      _retry?.cancel();
      _retry = Timer(_retryAfter, _sync);
    }
  }

  @override
  void dispose() {
    _retry?.cancel();
    _ads.removeListener(_sync);
    super.dispose();
  }
}

/// Draws the loaded banner. Menu screens stay mounted under each other, and a
/// banner may be in the tree only once, so only the screen on top draws it.
class _AdBannerView extends StatefulWidget {
  const _AdBannerView(this.service);

  final AdService service;

  @override
  State<_AdBannerView> createState() => _AdBannerViewState();
}

class _AdBannerViewState extends State<_AdBannerView> {
  bool _armed = false;

  @override
  Widget build(BuildContext context) {
    final gma.BannerAd? ad = widget.service.banner;
    final bool current = ModalRoute.of(context)?.isCurrent ?? true;
    if (ad == null || !current) {
      _armed = false;
      return const SizedBox.shrink();
    }
    if (!_armed) {
      // One frame later, so the screen that was on top has let go of it.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _armed = true);
      });
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: gma.AdWidget(ad: ad),
    );
  }
}
