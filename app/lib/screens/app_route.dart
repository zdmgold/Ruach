import 'package:flutter/widgets.dart';
import 'package:ruach/theme/tokens.dart';

/// The one page transition: a fade with a 20 px slide on the way in (350 ms)
/// and a 280 ms fade on the way out. With Reduce Motion it is instant.
class AppRoute<T> extends PageRouteBuilder<T> {
  AppRoute({
    required RouteSettings settings,
    required WidgetBuilder builder,
    required bool reduceMotion,
  }) : super(
          settings: settings,
          transitionDuration: reduceMotion ? AppDurations.none : AppDurations.push,
          reverseTransitionDuration: reduceMotion ? AppDurations.none : AppDurations.pop,
          pageBuilder: (BuildContext c, Animation<double> a, Animation<double> b) => builder(c),
          transitionsBuilder: (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondary,
            Widget child,
          ) {
            if (reduceMotion) return child;
            final Animation<double> eased = CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
              reverseCurve: Curves.easeInOut,
            );
            return FadeTransition(
              opacity: eased,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.025), end: Offset.zero).animate(eased),
                child: child,
              ),
            );
          },
        );
}
