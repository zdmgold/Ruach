import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/tokens.dart';

/// A horizontal slider from [min] to [max], optionally in [divisions] equal
/// steps. Dragging or tapping the track sets the value; the platform's
/// increase and decrease actions step it. [labelOf] is the spoken value.
class AppSlider extends StatelessWidget {
  const AppSlider({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    required this.labelOf,
    super.key,
    this.min = 0,
    this.max = 1,
    this.divisions,
  });

  final double value;
  final ValueChanged<double>? onChanged;
  final double min;
  final double max;
  final int? divisions;
  final String semanticLabel;
  /// The spoken (and shown) text for a value, for example `40%` or `07:15`.
  /// Also used for the values the increase and decrease actions lead to.
  final String Function(double value) labelOf;

  static const double trackHeight = 6;
  static const double knob = 24;

  double get _fraction => max == min ? 0 : ((value - min) / (max - min)).clamp(0.0, 1.0).toDouble();

  double _snap(double raw) {
    final double clamped = raw.clamp(min, max).toDouble();
    final int? n = divisions;
    if (n == null || n <= 0) return clamped;
    final double step = (max - min) / n;
    return min + (((clamped - min) / step).round() * step);
  }

  void _set(double dx, double width, TextDirection dir) {
    final ValueChanged<double>? change = onChanged;
    if (change == null || width <= knob) return;
    double f = ((dx - knob / 2) / (width - knob)).clamp(0.0, 1.0).toDouble();
    if (dir == TextDirection.rtl) f = 1 - f;
    change(_snap(min + f * (max - min)));
  }

  double _stepped(int direction) {
    final double step = divisions == null ? (max - min) / 10 : (max - min) / divisions!;
    return _snap(value + direction * step);
  }

  void _step(int direction) => onChanged?.call(_stepped(direction));

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final TextDirection dir = Directionality.of(context);
    final bool enabled = onChanged != null;
    return Semantics(
      slider: true,
      label: semanticLabel,
      value: labelOf(value),
      increasedValue: labelOf(_stepped(1)),
      decreasedValue: labelOf(_stepped(-1)),
      onIncrease: enabled ? () => _step(1) : null,
      onDecrease: enabled ? () => _step(-1) : null,
      child: ExcludeSemantics(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) {
            final double width = box.maxWidth.isFinite ? box.maxWidth : 240;
            final double travel = math.max(0, width - knob);
            final double f = dir == TextDirection.rtl ? 1 - _fraction : _fraction;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (TapDownDetails d) => _set(d.localPosition.dx, width, dir),
              onHorizontalDragStart: (DragStartDetails d) => _set(d.localPosition.dx, width, dir),
              onHorizontalDragUpdate: (DragUpdateDetails d) => _set(d.localPosition.dx, width, dir),
              child: Opacity(
                opacity: enabled ? 1 : AppOpacity.disabled,
                child: SizedBox(
                  height: AppHit.min,
                  width: width,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: <Widget>[
                      Positioned(
                        left: knob / 2,
                        right: knob / 2,
                        child: SizedBox(
                          height: trackHeight,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.colors.bgTertiary,
                              borderRadius: BorderRadius.circular(trackHeight / 2),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: travel * f,
                        child: SizedBox(
                          width: knob,
                          height: knob,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: theme.colors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
