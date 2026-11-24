import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:ruach/app_scope.dart';
import 'package:ruach/core/ports/billing_port.dart';
import 'package:ruach/l10n/app_localizations.dart';
import 'package:ruach/providers/entitlement_provider.dart';
import 'package:ruach/theme/app_theme.dart';
import 'package:ruach/theme/icons.dart';
import 'package:ruach/theme/tokens.dart';
import 'package:ruach/widgets/app_row.dart';
import 'package:ruach/widgets/nav_bar.dart';
import 'package:ruach/widgets/primary_button.dart';
import 'package:ruach/widgets/screen_frame.dart';

/// The one-time Remove Ads purchase. It is reached from Settings only, never
/// as a blocking prompt, and says plainly what it does and does not change.
class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  String? _price;
  String? _message;
  bool _busy = false;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    unawaited(_loadPrice(AppScope.of(context).entitlement));
  }

  Future<void> _loadPrice(EntitlementProvider entitlement) async {
    final String? price = await entitlement.priceText();
    if (mounted) setState(() => _price = price);
  }

  Future<void> _buy(AppScope scope, AppLocalizations l) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final PurchaseResult result = await scope.entitlement.buy();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = switch (result) {
        PurchaseResult.purchased || PurchaseResult.alreadyOwned => null,
        PurchaseResult.cancelled => l.upgradeCancelled,
        PurchaseResult.pending => l.upgradePending,
        PurchaseResult.failed => l.upgradeFailed,
      };
    });
  }

  Future<void> _restore(AppScope scope, AppLocalizations l) async {
    final bool found = await scope.entitlement.restore();
    if (mounted) setState(() => _message = found ? null : l.settingsRestoreNone);
  }

  @override
  Widget build(BuildContext context) {
    final AppScope scope = AppScope.of(context);
    final AppLocalizations l = AppLocalizations.of(context);
    final AppThemeData theme = AppTheme.of(context);
    return ListenableBuilder(
      listenable: scope.entitlement,
      builder: (BuildContext context, Widget? _) {
        final bool owned = scope.entitlement.adsRemoved;
        final String? price = _price;
        TextStyle body(Color c) => theme.type.body.copyWith(color: c);
        return ScreenFrame(
          navBar: NavBar(
            title: l.upgradeTitle,
            onBack: () => unawaited(Navigator.of(context).maybePop()),
            backLabel: l.commonBack,
          ),
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(l.upgradeLead, style: body(theme.colors.textPrimary)),
                  const SizedBox(height: AppSpacing.s16),
                  Text(l.upgradeKeeps, style: body(theme.colors.textSecondary)),
                  const SizedBox(height: AppSpacing.s24),
                  if (owned)
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        l.upgradeOwned,
                        style: theme.type.title2.copyWith(color: theme.colors.success),
                      ),
                    )
                  else
                    PrimaryButton(
                      label: price == null ? l.upgradeBuy : l.upgradeBuyPrice(price),
                      onPressed: _busy ? null : () => unawaited(_buy(scope, l)),
                    ),
                  if (_message != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.s16),
                    Semantics(
                      liveRegion: true,
                      child: Text(_message!, style: body(theme.colors.textPrimary)),
                    ),
                  ],
                ],
              ),
            ),
            if (!owned)
              AppRow(
                icon: AppIcons.restorePurchase,
                label: l.settingsRestore,
                onTap: () => unawaited(_restore(scope, l)),
              ),
          ],
        );
      },
    );
  }
}
