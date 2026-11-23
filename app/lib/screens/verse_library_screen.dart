import 'package:flutter/widgets.dart';
import 'package:ruach/app_scope.dart';
import 'package:ruach/core/models/verse.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/screens/verse_block.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/empty_state.dart';
import 'package:ruach/widgets/nav_bar.dart';
import 'package:ruach/widgets/screen_frame.dart';
import 'package:ruach/widgets/section_header.dart';
import 'package:ruach/widgets/verse_card.dart';

/// Every verse the player has met while racing, in Bible order. It only
/// lists; verses are collected by playing.
class VerseLibraryScreen extends StatefulWidget {
  const VerseLibraryScreen({super.key, this.onShare, this.onReadChapter});

  final ShareText? onShare;

  /// Opens the chapter in the Bible reader. Null until the reader ships.
  final void Function(VerseRef ref)? onReadChapter;

  @override
  State<VerseLibraryScreen> createState() => _VerseLibraryScreenState();
}

class _VerseLibraryScreenState extends State<VerseLibraryScreen> {
  Future<List<Verse>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AppScope.of(context).verses.library();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return FutureBuilder<List<Verse>>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<List<Verse>> snapshot) {
        final List<Verse> verses = snapshot.data ?? const <Verse>[];
        final bool loading = snapshot.connectionState != ConnectionState.done;
        return ScreenFrame(
          navBar: NavBar(
            title: l.libraryTitle,
            onBack: () => Navigator.of(context).maybePop(),
            backLabel: l.commonBack,
          ),
          children: <Widget>[
            if (!loading && verses.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s48),
                child: EmptyState(
                  icon: AppIcons.verse,
                  title: l.libraryEmptyTitle,
                  subtitle: l.libraryEmptyBody,
                ),
              ),
            if (verses.isNotEmpty) SectionHeader(l.libraryCount(verses.length)),
            for (final Verse v in verses)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  0,
                  AppSpacing.s16,
                  AppSpacing.s8,
                ),
                child: _card(l, v),
              ),
          ],
        );
      },
    );
  }

  Widget _card(AppLocalizations l, Verse v) {
    final ShareText? share = widget.onShare;
    final void Function(VerseRef ref)? read = widget.onReadChapter;
    final String ref = VerseText.reference(l, v.ref);
    return VerseCard(
      text: v.text,
      reference: ref,
      onShare: share == null ? null : () => share(l.verseShareText(v.text, ref)),
      shareLabel: share == null ? null : l.verseShare,
      onReadChapter: read == null ? null : () => read(v.ref),
      readLabel: read == null ? null : l.verseReadChapter,
    );
  }
}
