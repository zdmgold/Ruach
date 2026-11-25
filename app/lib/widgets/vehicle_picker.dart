import 'package:flutter/widgets.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/app_chip.dart';
import 'package:ruach/widgets/pressable.dart';

/// One choice in a [VehiclePicker].
final class VehicleChoice {
  const VehicleChoice({required this.id, required this.label});

  final String id;
  final String label;
}

/// The player's vehicles as a row of chips; the chosen one is highlighted.
/// The chosen one also carries a check, so colour is not the only signal.
class VehiclePicker extends StatelessWidget {
  const VehiclePicker({
    required this.choices,
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  final List<VehicleChoice> choices;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: <Widget>[
        for (final VehicleChoice c in choices)
          Pressable(
            onTap: () => onSelected(c.id),
            semanticLabel: c.label,
            builder: (BuildContext context, bool pressed) => AppChip(
              label: c.label,
              icon: c.id == selectedId ? AppIcons.check : null,
              tone: c.id == selectedId ? ChipTone.accent : ChipTone.neutral,
            ),
          ),
      ],
    );
  }
}
