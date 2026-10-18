import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../core/util/haptics.dart';
import '../../data/settings_controller.dart';
import '../../l10n/l10n.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';

/// A language's badge ("EN", "DE", "ع") on a round sticker.
class LanguageBadge extends StatelessWidget {
  const LanguageBadge({super.key, required this.language, this.size = 46});

  final AppLanguage language;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: c.sticker(kLanguages.indexOf(language) + 1),
        shape: BoxShape.circle,
        border: Border.all(color: c.ink, width: 1.8),
      ),
      alignment: Alignment.center,
      child: Text(
        language.badge,
        textDirection: language.direction,
        style: AppType.scaleFor(language.code).button.copyWith(
              // Stickers stay pastel in dark mode too, so the ink stays dark.
              color: const Color(0xFF141414),
              fontSize: size * (language.rtl ? 0.5 : 0.34),
              height: 1,
            ),
      ),
    );
  }
}

/// One language to pick: a sticker card with a title, a line under it, an
/// optional tag and a tick. Used by the first-run picker ([big]) and the
/// globe's sheet.
class LanguageChoice extends StatelessWidget {
  const LanguageChoice({
    super.key,
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.language,
    this.tag,
    this.big = false,
    this.tilt = 0,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  /// The language [title], [subtitle] and [tag] are written in, when it isn't
  /// necessarily the app's own. The card then reads in that language's
  /// direction and fonts.
  final AppLanguage? language;
  final String? tag;
  final bool big;

  /// Resting tilt in degrees; a picked card straightens up.
  final double tilt;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final TypeScale type = language == null ? AppType.current : AppType.scaleFor(language!.code);
    final Color fg = selected ? c.onAccent : c.textPrimary;

    Widget content = Row(
      children: <Widget>[
        leading,
        SizedBox(width: big ? 14 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(title, style: (big ? type.title2 : type.headline).copyWith(color: fg)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: type.footnote.copyWith(
                  color: selected ? c.onAccent.withValues(alpha: 0.75) : c.textSecondary,
                ),
              ),
              if (tag != null) ...<Widget>[
                const SizedBox(height: 7),
                Container(
                  padding: const EdgeInsetsDirectional.fromSTEB(7, 3, 10, 3.5),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: c.ink, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.smartphone_rounded, size: 13, color: c.textPrimary),
                      const SizedBox(width: 4),
                      Text(
                        tag!,
                        style: type.caption.copyWith(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 10),
        _Tick(selected: selected),
      ],
    );
    if (language != null) {
      content = Directionality(textDirection: language!.direction, child: content);
    }

    return AnimatedRotation(
      turns: selected ? 0 : tilt / 360,
      duration: Motion.base,
      curve: Curves.easeOutBack,
      child: AnimatedScale(
        scale: selected && big ? 1.03 : 1,
        duration: Motion.base,
        curve: Curves.easeOutBack,
        child: Chunk(
          onTap: onTap,
          color: selected ? c.accent : c.surface,
          radius: big ? 24 : 18,
          shadow: big ? Chunky.shadow : 3,
          padding: big
              ? const EdgeInsets.all(14)
              : const EdgeInsetsDirectional.fromSTEB(12, 10, 14, 10),
          child: content,
        ),
      ),
    );
  }
}

class _Tick extends StatelessWidget {
  const _Tick({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return AnimatedContainer(
      duration: Motion.quick,
      curve: Motion.standard,
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: selected ? c.ink : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: selected ? c.ink : c.textTertiary, width: 2),
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: Motion.quick,
        curve: Curves.easeOutBack,
        child: Icon(Icons.check_rounded, size: 18, color: selected ? c.accent : c.surface),
      ),
    );
  }
}

/// The globe in the screen headers. Wears the app's language as a badge and
/// opens the language sheet; it spins whenever the language changes,
/// wherever it was changed from.
class GlobeButton extends StatefulWidget {
  const GlobeButton({super.key, this.size = 44});

  final double size;

  @override
  State<GlobeButton> createState() => _GlobeButtonState();
}

class _GlobeButtonState extends State<GlobeButton> {
  double _turns = 0;
  String? _code;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLanguage language = context.watch<SettingsController>().language;
    if (_code != null && _code != language.code) _turns += 1;
    _code = language.code;
    final double s = widget.size;
    void open() => showLanguageSheet(context);

    return Semantics(
      button: true,
      label: context.l10n.globeTooltip,
      value: language.nativeName,
      onTap: open,
      excludeSemantics: true,
      child: SizedBox(
        // Room for the shadow, plus the badge poking out past the edge.
        width: s + 3 + 5,
        height: s + 3 + 3,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            Chunk(
              onTap: open,
              radius: s / 2,
              shadow: 3,
              width: s,
              height: s,
              child: Center(
                child: AnimatedRotation(
                  turns: _turns,
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutBack,
                  child: Icon(Icons.language_rounded, size: s * 0.52, color: c.textPrimary),
                ),
              ),
            ),
            PositionedDirectional(
              end: 0,
              bottom: 0,
              child: IgnorePointer(
                child: AnimatedSwitcher(
                  duration: Motion.base,
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Motion.exit,
                  transitionBuilder: (Widget child, Animation<double> a) =>
                      ScaleTransition(scale: a, child: child),
                  child: Container(
                    key: ValueKey<String>(language.code),
                    constraints: const BoxConstraints(minWidth: 22, minHeight: 18),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: c.ink, width: 1.5),
                    ),
                    child: Text(
                      language.badge,
                      textDirection: language.direction,
                      style: AppType.scaleFor(language.code).caption2.copyWith(
                            color: c.onAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: language.rtl ? 12 : 9.5,
                            height: 1.1,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The language sheet: follow the phone, or pick one of the app's languages.
/// Each language is offered in its own words, so it can be found from any
/// other.
Future<void> showLanguageSheet(BuildContext context) {
  final AppLocalizations l = context.l10n;
  return showAppSheet<void>(
    context,
    title: l.languageSheetTitle,
    message: l.languageSheetMessage,
    builder: (BuildContext sheet) => _LanguageList(host: context),
  );
}

class _LanguageList extends StatelessWidget {
  const _LanguageList({required this.host});

  /// The screen the sheet was opened from, for the toast once it's closed.
  final BuildContext host;

  void _choose(BuildContext context, String code) {
    final SettingsController s = context.read<SettingsController>();
    final String before = s.localeCode;
    final ModalRoute<Object?>? sheet = ModalRoute.of(context);
    Navigator.pop(context);
    // Switch once the sheet has slid away, so it never shows two languages at
    // once on its way out (its title was worded when it opened).
    (sheet?.completed ?? Future<Object?>.value()).then((_) {
      s.setLocale(code);
      if (s.localeCode == before || !host.mounted) return;
      Haptics.success();
      // In the new language: the first words the person sees after switching
      // say it worked.
      showToast(
        host,
        lookupAppLocalizations(s.language.locale).languageNowSpeaking,
        icon: Icons.language_rounded,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = context.l10n;
    final SettingsController s = context.watch<SettingsController>();
    final AppColors c = context.colors;
    final AppLanguage phone = languageFor(s.phoneLocaleCode);

    return SingleChildScrollView(
      // The cards' shadow is on their right in every language.
      padding: const EdgeInsets.fromLTRB(16, 0, 13, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          LanguageChoice(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.surfaceSunken,
                shape: BoxShape.circle,
                border: Border.all(color: c.ink, width: 1.8),
              ),
              child: Icon(Icons.smartphone_rounded, size: 21, color: c.textPrimary),
            ),
            title: l.languageMatchPhone,
            subtitle: l.languageMatchPhoneHint(phone.nameIn(l)),
            selected: s.followsPhone,
            onTap: () => _choose(context, SettingsController.followPhone),
          ),
          const SizedBox(height: 8),
          for (final AppLanguage language in kLanguages) ...<Widget>[
            LanguageChoice(
              leading: LanguageBadge(language: language, size: 40),
              language: language,
              title: language.nativeName,
              subtitle: lookupAppLocalizations(language.locale).languageCardLine,
              selected: !s.followsPhone && s.localeCode == language.code,
              onTap: () => _choose(context, language.code),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
