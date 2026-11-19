/// A fictional rival driver on a fictional team. No real driver, team, brand,
/// league or vehicle appears anywhere in Ruach (blueprint section 2).
///
/// Names are invented proper names and are not translated, so they live in the
/// data rather than in the language files. Two rivals are equal when their
/// [id] is equal.
final class Rival {
  const Rival({
    required this.id,
    required this.name,
    required this.team,
    required this.skill,
    required this.aggression,
    required this.consistency,
  })  : assert(skill >= 0 && skill <= 1, 'skill must be between 0 and 1'),
        assert(aggression >= 0 && aggression <= 1, 'aggression must be between 0 and 1'),
        assert(consistency >= 0 && consistency <= 1, 'consistency must be between 0 and 1');

  /// Stable id, for example `rival_adah`.
  final String id;

  /// The driver's invented name.
  final String name;

  /// The invented team name.
  final String team;

  /// How close to the ideal line and braking the rival drives, 0 to 1.
  final double skill;

  /// How willing the rival is to overtake and defend, 0 to 1.
  final double aggression;

  /// How little the rival's lap times vary, 0 to 1.
  final double consistency;

  @override
  bool operator ==(Object other) => other is Rival && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Rival($id)';
}
