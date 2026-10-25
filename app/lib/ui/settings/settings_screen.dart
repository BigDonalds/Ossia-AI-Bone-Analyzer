import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../core/util/formatting.dart';
import '../../core/util/haptics.dart';
import '../../data/history_store.dart';
import '../../data/on_device/on_device_model.dart';
import '../../data/server_monitor.dart';
import '../../data/settings_controller.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../language/language_picker.dart';
import '../reference/pipeline_screen.dart';
import '../status/link_pill.dart';
import '../widgets/engine_toggle.dart';
import '../widgets/inset_group.dart';
import '../widgets/nav.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';
import '../widgets/wide.dart';
import 'about_screen.dart';
import 'privacy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final SettingsController s = context.watch<SettingsController>();
    final HistoryStore history = context.watch<HistoryStore>();
    final AppLanguage current = s.language;

    final List<Widget> language = <Widget>[
      GroupLabel(l.languageTitle),
      InsetGroup(
        children: <Widget>[
          InsetRow(
            leading: LanguageBadge(language: current, size: 34),
            title: l.settingsAppLanguage,
            value: s.followsPhone
                ? l.languageFollowingPhone(current.nameIn(l))
                : current.nativeName,
            chevron: true,
            onTap: () => showLanguageSheet(context),
          ),
        ],
      ),
      GroupFooter(l.settingsLanguageFooter),
    ];

    final List<Widget> appearance = <Widget>[
      GroupLabel(l.settingsAppearance),
      InsetGroup(
        children: <Widget>[
          _StackedRow(
            title: l.settingsTheme,
            child: SegmentedControl<ThemeMode>(
              value: s.themeMode,
              onChanged: (ThemeMode v) {
                Haptics.tap();
                s.setThemeMode(v);
              },
              segments: <ThemeMode, String>{
                ThemeMode.system: l.themeSystem,
                ThemeMode.light: l.themeLight,
                ThemeMode.dark: l.themeDark,
              },
            ),
          ),
          _StackedRow(
            title: l.settingsAccent,
            trailingText: l.accentName(s.accent),
            child: _AccentPicker(
              value: s.accent,
              onChanged: (AccentTone t) {
                Haptics.tap();
                s.setAccent(t);
              },
            ),
          ),
        ],
      ),
    ];

    final List<Widget> analysis = <Widget>[
      GroupLabel(l.settingsAnalysis),
      InsetGroup(
        children: <Widget>[
          _StackedRow(
            title: l.engineAnalyzeOn,
            description: s.onDevice
                ? l.settingsOnDeviceBody
                : l.settingsOnlineBody,
            child: EngineToggle(value: s.engine, onChanged: s.setEngine),
          ),
          if (!s.onDevice)
            InsetRow(
              title: l.settingsOnlineAddress,
              value: s.serverUrl,
              chevron: true,
              onTap: () async {
                final String? url = await promptForText(
                  context,
                  title: l.settingsOnlineAddress,
                  message: l.settingsOnlineAddressBody,
                  initial: s.serverUrl,
                  placeholder: 'https://…',
                  keyboard: TextInputType.url,
                );
                if (url != null && url.trim().isNotEmpty) {
                  s.setServerUrl(url);
                }
              },
            ),
          InsetRow(
            leading: const LinkDot(size: 11),
            title: l.settingsStatus,
            subtitle: l.settingsStatusSub,
            value: linkLook(context, context.watch<ServerMonitor>()).$2,
            chevron: true,
            onTap: () => openModelStatus(context),
          ),
        ],
      ),
      InsetGroup(
        margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        children: <Widget>[
          _StackedRow(
            title: l.settingsCutoff,
            trailingText: percent(s.confidenceFloor),
            description: l.settingsCutoffBody,
            child: _FloorSlider(
              value: s.confidenceFloor,
              onChanged: s.setConfidenceFloor,
            ),
          ),
          InsetSwitchRow(
            title: l.settingsHideUnlikely,
            subtitle: l.settingsHideUnlikelyBody,
            value: s.hideLowConfidence,
            onChanged: s.setHideLowConfidence,
          ),
        ],
      ),
    ];

    final List<Widget> capture = <Widget>[
      GroupLabel(l.settingsCapture),
      InsetGroup(
        children: <Widget>[
          InsetSwitchRow(
            title: l.settingsAutoSave,
            subtitle: l.settingsAutoSaveBody,
            value: s.autoSave,
            onChanged: s.setAutoSave,
          ),
          if (OnDeviceModel.supported)
            InsetSwitchRow(
              title: l.settingsAutoSnap,
              subtitle: l.settingsAutoSnapBody,
              value: s.autoSnap,
              onChanged: s.setAutoSnap,
            ),
          _StackedRow(
            title: l.settingsUnits,
            child: SegmentedControl<LengthUnit>(
              value: s.unit,
              onChanged: (LengthUnit v) {
                Haptics.tap();
                s.setUnit(v);
              },
              segments: <LengthUnit, String>{
                for (final LengthUnit u in LengthUnit.values)
                  u: l.unitName(u),
              },
            ),
          ),
          InsetSwitchRow(
            title: l.settingsHaptics,
            value: s.haptics,
            onChanged: s.setHaptics,
          ),
        ],
      ),
    ];

    final List<Widget> library = <Widget>[
      GroupLabel(l.settingsLibrary),
      InsetGroup(
        children: <Widget>[
          InsetRow(
            title: l.settingsSavedCount,
            value: '${history.records.length}',
          ),
          InsetRow(
            title: l.settingsCopyAll,
            chevron: true,
            onTap: history.isEmpty
                ? null
                : () async {
                    await Clipboard.setData(
                      ClipboardData(text: history.exportJson()),
                    );
                    if (!context.mounted) return;
                    Haptics.light();
                    showToast(
                      context,
                      l.settingsCopiedCount(history.records.length),
                      icon: Icons.check_rounded,
                    );
                  },
          ),
          InsetRow(
            title: l.settingsDeleteAll,
            tint: history.isEmpty ? c.textTertiary : c.critical,
            onTap: history.isEmpty
                ? null
                : () async {
                    final bool ok = await confirm(
                      context,
                      title: l.settingsDeleteAllTitle,
                      message: l.settingsDeleteAllBody(
                        history.records.length,
                      ),
                      confirmLabel: l.settingsDeleteAllConfirm,
                      destructive: true,
                    );
                    if (!ok) return;
                    await history.clear();
                    if (!context.mounted) return;
                    showToast(context, l.settingsLibraryCleared);
                  },
          ),
        ],
      ),
      GroupFooter(l.settingsPrivacyFooter),
    ];

    final List<Widget> about = <Widget>[
      GroupLabel(l.settingsAbout),
      InsetGroup(
        children: <Widget>[
          InsetRow(
            title: l.howTitle,
            chevron: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PipelineScreen(),
              ),
            ),
          ),
          InsetRow(
            title: l.settingsAboutOssia,
            chevron: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const AboutScreen(),
              ),
            ),
          ),
          InsetRow(
            title: l.settingsPrivacyPolicy,
            chevron: true,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const PrivacyScreen(),
              ),
            ),
          ),
          InsetRow(title: l.settingsVersion, value: kAppVersion),
        ],
      ),
    ];

    final Widget disclaimer = Padding(
      padding: const EdgeInsets.fromLTRB(20, 34, 20, 0),
      child: Text(
        l.settingsDisclaimer,
        textAlign: TextAlign.center,
        style: AppType.caption.copyWith(color: c.textTertiary, height: 1.45),
      ),
    );

    return Scaffold(
      backgroundColor: c.canvas,
      body: LargeTitleScrollView(
        title: l.tabSettings,
        slivers: <Widget>[
          // On a tablet the first three sections sit beside the last three.
          if (Wide.of(context))
            SliverToBoxAdapter(
              child: TwoColumns(
                start: <Widget>[...language, ...appearance, ...analysis],
                end: <Widget>[...capture, ...library, ...about],
              ),
            )
          else
            SliverList.list(
              children: <Widget>[
                ...language,
                ...appearance,
                ...analysis,
                ...capture,
                ...library,
                ...about,
              ],
            ),
          SliverToBoxAdapter(child: disclaimer),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

/// A row whose control sits beneath the label rather than beside it — used
/// where the control needs the full width.
class _StackedRow extends StatelessWidget {
  const _StackedRow({
    required this.title,
    required this.child,
    this.trailingText,
    this.description,
  });

  final String title;

  /// Short value shown at the far end of the title's line.
  final String? trailingText;

  /// Longer explanation on its own line under the title.
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: AppType.body.copyWith(color: c.textPrimary),
                ),
              ),
              if (trailingText != null) ...<Widget>[
                const SizedBox(width: 8),
                Text(
                  trailingText!,
                  style: AppType.subhead.copyWith(color: c.textSecondary),
                ),
              ],
            ],
          ),
          if (description != null) ...<Widget>[
            const SizedBox(height: 3),
            Text(
              description!,
              style: AppType.footnote
                  .copyWith(color: c.textSecondary, height: 1.35),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AccentPicker extends StatelessWidget {
  const _AccentPicker({required this.value, required this.onChanged});

  final AccentTone value;
  final ValueChanged<AccentTone> onChanged;

  @override
  Widget build(BuildContext context) {
    final Brightness b = Theme.of(context).brightness;
    return Row(
      children: AccentTone.values.map((AccentTone t) {
        final bool active = t == value;
        final Color colour = t.resolve(b);
        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 14),
          child: Pressable(
            scale: 0.86,
            onTap: () => onChanged(t),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: colour,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colors.ink,
                  width: active ? 3 : 1.6,
                ),
                boxShadow: <BoxShadow>[
                  if (active)
                    BoxShadow(
                      color: context.colors.shadow,
                      offset: const Offset(2, 2),
                    ),
                ],
              ),
              child: active
                  ? const Icon(Icons.check_rounded,
                      size: 18, color: Color(0xFF141414))
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FloorSlider extends StatelessWidget {
  const _FloorSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 8,
        activeTrackColor: c.accent,
        inactiveTrackColor: c.fill,
        thumbColor: c.ink,
        overlayShape: SliderComponentShape.noOverlay,
        // iOS sliders have a plain track; the Material division ticks would
        // read as a different control entirely.
        tickMarkShape: SliderTickMarkShape.noTickMark,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 11,
          elevation: 2,
        ),
      ),
      child: Slider(
        value: value,
        min: 0.1,
        max: 0.8,
        divisions: 14,
        onChanged: onChanged,
      ),
    );
  }
}
