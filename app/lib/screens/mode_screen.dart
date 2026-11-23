import 'package:flutter/widgets.dart';
import 'package:ruach/core/models/race_config.dart';
import 'package:ruach/screens/track_list_screen.dart';
import 'package:ruach/screens/weekly_screen.dart';

/// The entry screen of a mode: the Weekly Circuit has its own, every other
/// mode picks a track from a list. (The Daily Run goes straight to its
/// track intro and never comes here.)
class ModeScreen extends StatelessWidget {
  const ModeScreen({required this.mode, super.key, this.banner});

  final RaceMode mode;
  final Widget? banner;

  @override
  Widget build(BuildContext context) => switch (mode) {
        RaceMode.weeklyCircuit => WeeklyScreen(banner: banner),
        _ => TrackListScreen(mode: mode, banner: banner),
      };
}
