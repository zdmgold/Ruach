import 'package:flutter/widgets.dart';
import 'package:ruach/theme/tokens.dart';

/// The shared press behaviour of every tappable component: no ripple, only a
/// fade (and, for buttons, a slight scale) while the finger is down. The hit
/// area is never smaller than [AppHit.min] in either direction, whatever the
/// visible size. Under Reduce Motion the change is instant.
///
/// Components use this; screens do not.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.builder,
    super.key,
    this.onTap,
    this.semanticLabel,
    this.pressedScale = 1,
    this.fadeWhenPressed = true,
    this.minSize = AppHit.min,
  });

  /// Draws the content. [pressed] is true while the finger is down, for
  /// components that tint their background instead of fading.
  final Widget Function(BuildContext context, bool pressed) builder;

  /// Null makes the component inert and drawn at the disabled opacity.
  final VoidCallback? onTap;

  /// Replaces the text inside as the spoken label, if given.
  final String? semanticLabel;

  /// 1 for no scale; buttons use 0.97.
  final double pressedScale;

  /// Fade to the pressed opacity. Rows turn this off and tint instead.
  final bool fadeWhenPressed;

  /// Smallest hit area, in logical pixels.
  final double minSize;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  bool get _enabled => widget.onTap != null;

  void _set(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final Duration duration = reduceMotion ? AppDurations.none : AppDurations.press;
    final double opacity = !_enabled
        ? AppOpacity.disabled
        : (_pressed && widget.fadeWhenPressed ? AppOpacity.pressed : 1);
    final double scale = _pressed && _enabled && !reduceMotion ? widget.pressedScale : 1;

    Widget content = AnimatedOpacity(
      opacity: opacity,
      duration: duration,
      curve: Curves.easeOut,
      child: AnimatedScale(
        scale: scale,
        duration: duration,
        curve: Curves.easeOut,
        child: widget.builder(context, _pressed && _enabled),
      ),
    );

    content = ConstrainedBox(
      constraints: BoxConstraints(minWidth: widget.minSize, minHeight: widget.minSize),
      child: Center(widthFactor: 1, heightFactor: 1, child: content),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      container: widget.semanticLabel != null,
      excludeSemantics: widget.semanticLabel != null,
      onTap: widget.onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: _enabled ? (TapDownDetails _) => _set(true) : null,
        onTapUp: _enabled ? (TapUpDetails _) => _set(false) : null,
        onTapCancel: _enabled ? () => _set(false) : null,
        onTap: widget.onTap,
        child: content,
      ),
    );
  }
}
