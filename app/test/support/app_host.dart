import 'package:ruach/app_services.dart';
import 'package:ruach/utils/error_handler.dart';

import 'fakes.dart';
import 'scope_host.dart';

/// Whole-app services on fakes, for tests that run [RuachApp] itself.
AppServices testServices(TestScope s, {FakeUrl? url, FakeLog? log}) => AppServices(
      settings: s.settings,
      theme: s.theme,
      locale: s.locale,
      progress: s.progress,
      garage: s.garage,
      entitlement: s.entitlement,
      race: s.race,
      consent: s.consent,
      ads: s.ads,
      daily: s.daily,
      verses: s.verses,
      flags: s.flags,
      ports: ShellPorts(
        share: FakeShare(),
        url: url ?? FakeUrl(),
        tilt: FakeTilt(),
        log: log ?? FakeLog(),
        review: FakeReview(),
      ),
      errors: AppErrorHandler((Object e, StackTrace? st, {required bool fatal}) {}),
    );
