import 'package:flutter/widgets.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/widgets/ad_slot.dart';
import 'package:ruach/widgets/nav_bar.dart';

/// The shape of a normal screen: the nav bar on top, a scrolling body, and an
/// optional banner slot pinned to the bottom. Race and result screens draw
/// their own layout and do not use it.
class ScreenFrame extends StatelessWidget {
  const ScreenFrame({
    required this.navBar,
    required this.children,
    super.key,
    this.banner,
    this.bannerHeight = 0,
  });

  final NavBar navBar;
  final List<Widget> children;

  /// The banner ad, or null for none. The slot collapses when it is null.
  final Widget? banner;
  final double bannerHeight;

  @override
  Widget build(BuildContext context) {
    final AppThemeData theme = AppTheme.of(context);
    final double bottom = MediaQuery.paddingOf(context).bottom;
    return ColoredBox(
      color: theme.colors.bgPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          navBar,
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottom == 0 ? 16 : bottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
          AdSlot(height: bannerHeight, ad: banner),
        ],
      ),
    );
  }
}
