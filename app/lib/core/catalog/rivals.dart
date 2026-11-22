import 'package:ruach/core/models/rival.dart';

/// Fictional drivers on fictional teams. Names are invented; any resemblance
/// to a real driver or team is unintended, and the name search before store
/// submission (blueprint open item 5) covers them.
abstract final class RivalCatalog {
  static const List<Rival> all = <Rival>[
    Rival(id: 'rival_kessa', name: 'Kessa Morrow', team: 'Dustwind Racing', skill: 0.42, aggression: 0.35, consistency: 0.7),
    Rival(id: 'rival_tavi', name: 'Tavi Brandt', team: 'Harrow & Vale', skill: 0.5, aggression: 0.55, consistency: 0.6),
    Rival(id: 'rival_orin', name: 'Orin Halvek', team: 'Sablefin', skill: 0.58, aggression: 0.3, consistency: 0.8),
    Rival(id: 'rival_lio', name: 'Lio Santar', team: 'Northgate Works', skill: 0.46, aggression: 0.7, consistency: 0.5),
    Rival(id: 'rival_mara', name: 'Mara Quill', team: 'Ember Lane', skill: 0.66, aggression: 0.45, consistency: 0.75),
    Rival(id: 'rival_dax', name: 'Dax Ferrow', team: 'Kestrel Union', skill: 0.72, aggression: 0.8, consistency: 0.55),
    Rival(id: 'rival_ilya', name: 'Ilya Venn', team: 'Dustwind Racing', skill: 0.54, aggression: 0.4, consistency: 0.65),
    Rival(id: 'rival_soren', name: 'Soren Dray', team: 'Sablefin', skill: 0.8, aggression: 0.6, consistency: 0.85),
    Rival(id: 'rival_nadia', name: 'Nadia Korve', team: 'Kestrel Union', skill: 0.62, aggression: 0.5, consistency: 0.7),
    Rival(id: 'rival_bram', name: 'Bram Lowell', team: 'Harrow & Vale', skill: 0.38, aggression: 0.25, consistency: 0.6),
    Rival(id: 'rival_yuki', name: 'Yuki Arden', team: 'Ember Lane', skill: 0.76, aggression: 0.5, consistency: 0.8),
    Rival(id: 'rival_teo', name: 'Teo Marsh', team: 'Northgate Works', skill: 0.68, aggression: 0.65, consistency: 0.6),
  ];
}
