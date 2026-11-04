import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/l10n.dart';
import '../widgets/sheets.dart';

/// Shows everything that links to the stores: the Rate and Share rows in
/// Settings and the review card on Scan. Off until the listings are live, so
/// nobody follows a dead link. A test build turns it on with
/// `--dart-define=STORE_LINKS=true`; going live means giving this a
/// `defaultValue: true`.
const bool kStoreLinksLive = bool.fromEnvironment('STORE_LINKS');

const String kAppStoreId = '6828234526';
const String kAppStoreUrl = 'https://apps.apple.com/app/id$kAppStoreId';
const String kAppStoreReviewUrl = '$kAppStoreUrl?action=write-review';
const String kPlayStoreUrl = 'https://play.google.com/store/apps/details?id=io.github.bigdonalds.ossia';

/// Opens this phone's store page outside the app. Says so in a toast and
/// returns false when it can't.
Future<bool> openStorePage(BuildContext context) async {
  final AppLocalizations l = context.l10n;
  final Uri page = Uri.parse(
    defaultTargetPlatform == TargetPlatform.iOS ? kAppStoreReviewUrl : kPlayStoreUrl,
  );
  bool opened = false;
  try {
    opened = await launchUrl(page, mode: LaunchMode.externalApplication);
  } catch (_) {
    // No browser or store app to open it with.
  }
  if (!opened && context.mounted) {
    showToast(context, l.storeOpenFailed, icon: Icons.error_outline_rounded);
  }
  return opened;
}

/// Opens the phone's share sheet. [context] is the row that was tapped: an
/// iPad points the sheet at it.
Future<void> shareOssia(BuildContext context) async {
  final AppLocalizations l = context.l10n;
  final RenderBox? box = context.findRenderObject() as RenderBox?;
  try {
    await SharePlus.instance.share(
      ShareParams(
        text: l.shareText(kAppStoreUrl, kPlayStoreUrl),
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  } catch (_) {
    if (context.mounted) {
      showToast(context, l.shareFailed, icon: Icons.error_outline_rounded);
    }
  }
}
