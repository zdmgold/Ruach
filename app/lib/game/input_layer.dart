import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ruach/core/logic/input_strategy.dart';
import 'package:ruach/core/models/drive_input.dart';
import 'package:ruach/core/models/settings.dart';
import 'package:ruach/theme/app_icon.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';

/// Holds what the player's fingers and phone are doing and turns it into one
/// [DriveInput] per frame through the chosen [DriveInputStrategy]. The race
/// game reads it; the [InputLayer] writes it.
final class InputController {
  InputController(this.strategy);

  DriveInputStrategy strategy;

  bool left = false;
  bool right = false;
  bool brake = false;
  bool boost = false;
  double dragSteer = 0;
  double tiltRadians = 0;

  ControlSnapshot get snapshot => ControlSnapshot(
        left: left,
        right: right,
        brake: brake,
        boost: boost,
        dragSteer: dragSteer,
        tiltRadians: tiltRadians,
      );

  DriveInput read(double dt) => strategy.read(snapshot, dt);

  /// Releases every control and forgets smoothing, for a new race or a pause.
  void reset() {
    left = false;
    right = false;
    brake = false;
    boost = false;
    dragSteer = 0;
    strategy.reset();
  }
}

/// Words spoken or shown by the controls.
final class InputLabels {
  const InputLabels({
    required this.steerLeft,
    required this.steerRight,
    required this.brake,
    required this.boost,
    required this.tiltFallback,
  });

  final String steerLeft;
  final String steerRight;
  final String brake;
  final String boost;

  /// One line shown when tilt was chosen but the phone has no sensor.
  final String tiltFallback;
}

/// The race controls: steer buttons, brake and boost, or a drag area, or tilt
/// with only brake and boost. Left always steers left and right always steers
/// right, in every language, and the cluster never mirrors with the text
/// direction; handedness moves it from one side to the other.
class InputLayer extends StatefulWidget {
  const InputLayer({
    required this.controller,
    required this.settings,
    required this.labels,
    super.key,
    this.tilt,
    this.tiltAvailable = true,
  });

  /// Smallest size of a race control, in logical pixels.
  static const double buttonSize = 80;

  /// The boost button in the touch-the-sides scheme: bigger, since it is the
  /// only button.
  static const double boostSize = 104;

  /// Space between race controls.
  static const double gap = 24;

  final InputController controller;
  final Settings settings;
  final InputLabels labels;

  /// Roll in radians from the tilt sensor; null if the scheme is not tilt.
  final Stream<double>? tilt;
  final bool tiltAvailable;

  @override
  State<InputLayer> createState() => _InputLayerState();
}

class _InputLayerState extends State<InputLayer> {
  StreamSubscription<double>? _tiltSub;
  final Map<int, double> _pointers = <int, double>{};
  bool _leftDown = false;
  bool _rightDown = false;

  ControlScheme get _scheme =>
      widget.settings.controlScheme == ControlScheme.tilt && !widget.tiltAvailable
          ? ControlScheme.buttons
          : widget.settings.controlScheme;

  @override
  void initState() {
    super.initState();
    _listenToTilt();
  }

  @override
  void didUpdateWidget(InputLayer old) {
    super.didUpdateWidget(old);
    if (old.tilt != widget.tilt) {
      _tiltSub?.cancel().ignore();
      _listenToTilt();
    }
  }

  void _listenToTilt() {
    _tiltSub = widget.tilt?.listen((double roll) => widget.controller.tiltRadians = roll);
  }

  @override
  void dispose() {
    _tiltSub?.cancel().ignore();
    widget.controller.reset();
    super.dispose();
  }

  /// Touch-the-sides steering: a finger on the left half turns left, on the
  /// right half turns right, both at once goes straight. The car speeds up on
  /// its own; the only button is the big boost.
  Widget _halves(BuildContext context) {
    final InputController c = widget.controller;
    final double bottom = (MediaQuery.maybePaddingOf(context)?.bottom ?? 0) + AppSpacing.s24;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          void update() {
            final double mid = box.maxWidth / 2;
            final bool left = _pointers.values.any((double x) => x < mid);
            final bool right = _pointers.values.any((double x) => x >= mid);
            c.left = left;
            c.right = right;
            if (left != _leftDown || right != _rightDown) {
              setState(() {
                _leftDown = left;
                _rightDown = right;
              });
            }
          }

          return Stack(
            children: <Widget>[
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (PointerDownEvent e) {
                    _pointers[e.pointer] = e.localPosition.dx;
                    update();
                  },
                  onPointerMove: (PointerMoveEvent e) {
                    _pointers[e.pointer] = e.localPosition.dx;
                    update();
                  },
                  onPointerUp: (PointerUpEvent e) {
                    _pointers.remove(e.pointer);
                    update();
                  },
                  onPointerCancel: (PointerCancelEvent e) {
                    _pointers.remove(e.pointer);
                    update();
                  },
                  child: Row(
                    children: <Widget>[
                      Expanded(child: _SideHint(icon: AppIcons.steerLeft, pressed: _leftDown)),
                      Expanded(child: _SideHint(icon: AppIcons.steerRight, pressed: _rightDown)),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: bottom,
                child: Center(
                  child: _RaceButton(
                    label: widget.labels.boost,
                    onChanged: (bool v) => c.boost = v,
                    icon: AppIcons.boost,
                    size: InputLayer.boostSize,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_scheme == ControlScheme.halves) return _halves(context);
    final Settings s = widget.settings;
    final InputController c = widget.controller;
    final InputLabels l = widget.labels;
    final double bottom = (MediaQuery.maybePaddingOf(context)?.bottom ?? 0) + AppSpacing.s16;
    final bool dominantRight = s.handedness == Handedness.right;
    final bool steerButtons = _scheme == ControlScheme.buttons;

    final Widget brakeButton =
        _RaceButton(label: l.brake, onChanged: (bool v) => c.brake = v, child: const _StopGlyph());
    final Widget boostButton =
        _RaceButton(label: l.boost, onChanged: (bool v) => c.boost = v, icon: AppIcons.boost);
    // Two buttons wide for the one-handed stack; one column wide beside the
    // steering, because four 80-wide controls do not fit across a 360 phone.
    final Widget pedalsRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[brakeButton, const SizedBox(width: InputLayer.gap), boostButton],
    );
    final Widget pedalsColumn = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[boostButton, const SizedBox(height: InputLayer.gap), brakeButton],
    );
    final Widget steering = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _RaceButton(label: l.steerLeft, onChanged: (bool v) => c.left = v, icon: AppIcons.steerLeft),
        const SizedBox(width: InputLayer.gap),
        _RaceButton(label: l.steerRight, onChanged: (bool v) => c.right = v, icon: AppIcons.steerRight),
      ],
    );

    Widget cluster(Widget content) => Positioned(
          bottom: bottom,
          left: dominantRight ? null : AppSpacing.s16,
          right: dominantRight ? AppSpacing.s16 : null,
          child: content,
        );
    Widget opposite(Widget content) => Positioned(
          bottom: bottom,
          left: dominantRight ? AppSpacing.s16 : null,
          right: dominantRight ? null : AppSpacing.s16,
          child: content,
        );

    final List<Widget> children = <Widget>[];
    if (_scheme == ControlScheme.dragSteer) {
      children.add(
        Positioned.fill(
          top: 160,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints box) {
              void steerTo(double dx) => c.dragSteer = ((dx - box.maxWidth / 2) / (box.maxWidth / 2)).clamp(-1, 1).toDouble();
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (DragStartDetails d) => steerTo(d.localPosition.dx),
                onPanUpdate: (DragUpdateDetails d) => steerTo(d.localPosition.dx),
                onPanEnd: (DragEndDetails _) => c.dragSteer = 0,
                onPanCancel: () => c.dragSteer = 0,
              );
            },
          ),
        ),
      );
    }
    if (s.oneHandedLayout) {
      children.add(
        cluster(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: dominantRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: <Widget>[
              pedalsRow,
              if (steerButtons) ...<Widget>[const SizedBox(height: InputLayer.gap), steering],
            ],
          ),
        ),
      );
    } else {
      children.add(cluster(pedalsColumn));
      if (steerButtons) children.add(opposite(steering));
    }
    if (widget.settings.controlScheme == ControlScheme.tilt && !widget.tiltAvailable) {
      final AppThemeData theme = AppTheme.of(context);
      children.add(
        Positioned(
          left: AppSpacing.s16,
          right: AppSpacing.s16,
          bottom: bottom + InputLayer.buttonSize * 2 + InputLayer.gap * 2,
          child: Text(l.tiltFallback, textAlign: TextAlign.center, style: theme.type.footnote),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(children: children),
    );
  }
}

/// A big round control that reacts the instant a finger lands (not when it
/// lifts) and releases when the finger leaves or the touch is cancelled.
class _RaceButton extends StatefulWidget {
  const _RaceButton({
    required this.label,
    required this.onChanged,
    this.icon,
    this.child,
    this.size = InputLayer.buttonSize,
  });

  final double size;

  final String label;
  final ValueChanged<bool> onChanged;
  final IconData? icon;
  final Widget? child;

  @override
  State<_RaceButton> createState() => _RaceButtonState();
}

class _RaceButtonState extends State<_RaceButton> {
  bool _down = false;

  void _set(bool value) {
    if (_down == value) return;
    setState(() => _down = value);
    widget.onChanged(value);
  }

  @override
  void dispose() {
    if (_down) widget.onChanged(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final Color ink = _down ? theme.colors.onAccent : theme.colors.textPrimary;
    return Semantics(
      button: true,
      label: widget.label,
      excludeSemantics: true,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (PointerDownEvent _) => _set(true),
        onPointerUp: (PointerUpEvent _) => _set(false),
        onPointerCancel: (PointerCancelEvent _) => _set(false),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _down ? theme.colors.accent : theme.colors.bgSecondary.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(AppRadii.hero),
            border: Border.all(color: theme.colors.border, width: AppStroke.hairline),
          ),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Center(
              child: widget.child == null
                  ? AppIcon(widget.icon!, size: AppIconSizes.hero, color: ink)
                  : IconTheme(data: IconThemeData(color: ink), child: widget.child!),
            ),
          ),
        ),
      ),
    );
  }
}

/// A filled rounded square: the universal "stop" mark for the brake.
class _StopGlyph extends StatelessWidget {
  const _StopGlyph();

  @override
  Widget build(BuildContext context) {
    final Color color = IconTheme.of(context).color ?? AppTheme.of(context).colors.textPrimary;
    return DecoratedBox(
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      child: const SizedBox(width: 26, height: 26),
    );
  }
}

/// A big soft arrow on one half of the screen so it is clear where to touch;
/// the half lights up while a finger is on it.
class _SideHint extends StatelessWidget {
  const _SideHint({required this.icon, required this.pressed});

  final IconData icon;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: pressed ? const Color(0x24FFFFFF) : const Color(0x00000000),
      child: Align(
        alignment: const Alignment(0, 0.55),
        child: AppIcon(
          icon,
          size: 72,
          color: pressed ? const Color(0xCCFFFFFF) : const Color(0x66FFFFFF),
        ),
      ),
    );
  }
}
