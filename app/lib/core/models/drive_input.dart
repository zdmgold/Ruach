/// What the player is asking the vehicle to do at one instant. Every control
/// scheme (buttons, drag-steer, tilt) produces this one value through the
/// input strategy interface (batch p2c), so the race never knows which scheme
/// was used. A ghost is a recorded list of these.
final class DriveInput {
  const DriveInput({
    this.steer = 0,
    this.throttle = 0,
    this.brake = 0,
    this.boost = false,
  })  : assert(steer >= -1 && steer <= 1, 'steer must be between -1 and 1'),
        assert(throttle >= 0 && throttle <= 1, 'throttle must be between 0 and 1'),
        assert(brake >= 0 && brake <= 1, 'brake must be between 0 and 1');

  /// Forces every value into range, for input coming from a sensor or a drag.
  factory DriveInput.clamped({
    double steer = 0,
    double throttle = 0,
    double brake = 0,
    bool boost = false,
  }) =>
      DriveInput(
        steer: steer.clamp(-1.0, 1.0).toDouble(),
        throttle: throttle.clamp(0.0, 1.0).toDouble(),
        brake: brake.clamp(0.0, 1.0).toDouble(),
        boost: boost,
      );

  /// No input at all.
  static const DriveInput idle = DriveInput();

  /// -1 is full left, 1 is full right. Left is always left, in every
  /// language: right-to-left layouts do not mirror steering.
  final double steer;

  /// 0 to 1.
  final double throttle;

  /// 0 to 1.
  final double brake;

  /// True while the player asks to spend a Ruach segment.
  final bool boost;

  @override
  bool operator ==(Object other) =>
      other is DriveInput &&
      other.steer == steer &&
      other.throttle == throttle &&
      other.brake == brake &&
      other.boost == boost;

  @override
  int get hashCode => Object.hash(steer, throttle, brake, boost);

  @override
  String toString() =>
      'DriveInput(steer: $steer, throttle: $throttle, brake: $brake, boost: $boost)';
}
