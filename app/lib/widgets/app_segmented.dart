import 'package:flutter/widgets.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/app_chip.dart';

/// One choice of an [AppSegmented].
final class SegmentOption<T> {
  const SegmentOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// A short list of mutually exclusive choices shown as chips, the chosen one
/// filled. Wraps onto more lines when the labels are long (German, 200% text).
class AppSegmented<T> extends StatelessWidget {
  const AppSegmented({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: <Widget>[
        for (final SegmentOption<T> o in options)
          Semantics(
            selected: o.value == selected,
            inMutuallyExclusiveGroup: true,
            child: AppChip(
              label: o.label,
              tone: o.value == selected ? ChipTone.accent : ChipTone.neutral,
              onTap: () => onChanged(o.value),
            ),
          ),
      ],
    );
  }
}
