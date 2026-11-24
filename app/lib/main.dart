import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ruach/app.dart';
import 'package:ruach/app_services.dart';
import 'package:ruach/boot.dart';

Future<void> main() async {
  final AppServices services = await bootServices();
  runApp(RuachApp(services: services));
  final Future<void> Function()? start = services.onStart;
  if (start != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(start()));
  }
}
