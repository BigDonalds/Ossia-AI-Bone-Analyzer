import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../l10n/l10n.dart';
import 'bone_buddy.dart';
import 'primitives.dart';

/// Bottom sheet with a chunky grabber and an outlined top edge.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required String title,
  String? message,
  required Widget Function(BuildContext) builder,
}) {
  final AppColors c = context.colors;
  return showModalBottomSheet<T>(
    context: context,
    // Above the tab bar, which floats over each tab's own navigator and
    // would otherwise cover the bottom of the sheet.
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    barrierColor: c.scrim,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return Container(
        decoration: BoxDecoration(
          color: c.canvas,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border(
            top: BorderSide(color: c.ink, width: Chunky.border),
            left: BorderSide(color: c.ink, width: Chunky.border),
            right: BorderSide(color: c.ink, width: Chunky.border),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom +
              MediaQuery.paddingOf(context).bottom +
              12,
        ),
        child: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 6,
                decoration: BoxDecoration(
                  color: c.ink,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppType.title2.copyWith(color: c.textPrimary),
                ),
              ),
              if (message != null) ...<Widget>[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppType.subhead.copyWith(
                      color: c.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Flexible(child: builder(context)),
            ],
          ),
        ),
      );
    },
  );
}

/// Confirmation dialog with a cancel and a single confirming action.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String? confirmLabel,
  bool destructive = false,
}) async {
  final AppColors c = context.colors;
  final bool? r = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: context.l10n.dismiss,
    barrierColor: c.scrim,
    transitionDuration: const Duration(milliseconds: 260),
    transitionBuilder: (BuildContext context, Animation<double> a, _, Widget child) =>
        ScaleTransition(
      scale: CurvedAnimation(parent: a, curve: Curves.easeOutBack),
      child: FadeTransition(opacity: a, child: child),
    ),
    // No wider than a phone's, even on a tablet.
    pageBuilder: (BuildContext context, _, _) => Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Material(
            type: MaterialType.transparency,
            child: Chunk(
              padding: const EdgeInsets.fromLTRB(20, 22, 16, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  BoneBuddy(
                    size: 92,
                    mood: destructive ? BuddyMood.wow : BuddyMood.thinking,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppType.title2.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: AppType.subhead.copyWith(
                      color: c.textSecondary,
                      height: 1.42,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ButtonPair(
                    secondary: SecondaryButton(
                      label: context.l10n.nah,
                      height: 52,
                      onTap: () => Navigator.pop(context, false),
                    ),
                    primary: PrimaryButton(
                      label: confirmLabel ?? context.l10n.confirm,
                      height: 52,
                      tone: destructive ? c.critical : null,
                      onTap: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return r ?? false;
}

/// Single-field text entry sheet, used for naming a specimen and for the
/// server address.
Future<String?> promptForText(
  BuildContext context, {
  required String title,
  String? message,
  String initial = '',
  String placeholder = '',
  String? actionLabel,
  TextInputType keyboard = TextInputType.text,
}) {
  final TextEditingController controller =
      TextEditingController(text: initial);
  final AppColors c = context.colors;

  return showAppSheet<String>(
    context,
    title: title,
    message: message,
    builder: (BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 12, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Chunk(
            radius: 16,
            shadow: 3,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: keyboard,
              autocorrect: false,
              style: AppType.body.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: placeholder,
                hintStyle: AppType.body.copyWith(color: c.textTertiary),
              ),
              onSubmitted: (String v) => Navigator.pop(context, v),
            ),
          ),
          const SizedBox(height: 14),
          PrimaryButton(
            label: actionLabel ?? context.l10n.save,
            onTap: () => Navigator.pop(context, controller.text),
          ),
        ],
      ),
    ),
  ).whenComplete(controller.dispose);
}

/// Sticker toast near the bottom of the screen. Inside the tabs the scaffold
/// already sets it just above the tab bar; a page of its own may have buttons
/// along the bottom, so there it sits higher, about where the tab bar's top
/// would be. [overTabs] says which, for a caller outside both.
void showToast(
  BuildContext context,
  String message, {
  IconData? icon,
  ScaffoldMessengerState? messenger,
  Color? color,
  bool? overTabs,
}) {
  final AppColors c = context.colors;
  messenger ??= ScaffoldMessenger.of(context);
  overTabs ??=
      context.findRootAncestorStateOfType<ScaffoldState>()?.widget.bottomNavigationBar != null;
  messenger.clearSnackBars();
  messenger.showSnackBar(
    // The bar itself is see-through and the sticker is drawn inside it, so
    // on a tablet the sticker can stay phone-wide in the middle.
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      padding: EdgeInsets.zero,
      duration: const Duration(seconds: 2),
      margin: EdgeInsets.fromLTRB(16, 0, 16, overTabs ? 12 : 96),
      shape: const RoundedRectangleBorder(),
      content: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              color: color ?? c.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: c.ink, width: Chunky.border),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: <Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: 20, color: c.onAccent),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      message,
                      style: AppType.headline.copyWith(color: c.onAccent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
