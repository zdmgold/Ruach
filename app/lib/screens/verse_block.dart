import 'package:flutter/widgets.dart';
import 'package:ruach/core/models/verse.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/l10n/names.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/verse_card.dart';

/// Shares text through the system share sheet. Supplied by the app shell.
typedef ShareText = Future<bool> Function(String text);

/// A verse card for a verse that is loaded once. Nothing is shown while it
/// loads or when there is no verse, so a missing verse never leaves a hole.
class VerseBlock extends StatefulWidget {
  const VerseBlock({required this.load, super.key, this.onShare});

  final Future<Verse?> Function() load;
  final ShareText? onShare;

  @override
  State<VerseBlock> createState() => _VerseBlockState();
}

class _VerseBlockState extends State<VerseBlock> {
  late final Future<Verse?> _future = widget.load();

  static String reference(AppLocalizations l, VerseRef ref) {
    final String book = bookName(l, ref.book);
    return ref.isRange
        ? l.verseRefRange(book, ref.chapter, ref.verse, ref.endVerse)
        : l.verseRef(book, ref.chapter, ref.verse);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return FutureBuilder<Verse?>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<Verse?> snapshot) {
        final Verse? verse = snapshot.data;
        if (verse == null) return const SizedBox.shrink();
        final String ref = reference(l, verse.ref);
        final ShareText? share = widget.onShare;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
          child: VerseCard(
            text: verse.text,
            reference: ref,
            onShare: share == null ? null : () => share(l.verseShareText(verse.text, ref)),
            shareLabel: share == null ? null : l.verseShare,
          ),
        );
      },
    );
  }
}
