import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../core/util/formatting.dart';
import '../../core/util/haptics.dart';
import '../../data/analysis_engine.dart';
import '../../data/models/analysis.dart';
import '../../data/on_device/on_device_model.dart';
import '../../data/settings_controller.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../widgets/inset_group.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';
import '../widgets/specimen_image.dart';
import 'analyzing_screen.dart';
import 'camera_screen.dart';
import 'length_ruler.dart';

/// Between capture and analysis: check the shot, add more angles of the same
/// bone if you like, optionally say how long it is, then send it off.
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.images,
    this.fromCamera = false,
    this.lengthCm,
    this.revising,
  });

  final List<File> images;

  /// Changes the back action's wording — "retake" only makes sense after the
  /// camera.
  final bool fromCamera;
  final double? lengthCm;

  /// A finished analysis the user is adding angles to; re-analysing replaces
  /// it, keeping its name and note.
  final AnalysisRecord? revising;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late final List<File> _images = List<File>.of(widget.images);
  late double? _lengthCm = widget.lengthCm;
  int _shown = 0;

  /// Photos were added or dropped, so leaving would throw that away.
  bool get _changed =>
      _images.length != widget.images.length ||
      <int>[for (int i = 0; i < _images.length; i++) i]
          .any((int i) => _images[i].path != widget.images[i].path);

  int get _room => kMaxPhotos - _images.length;

  @override
  void initState() {
    super.initState();
    // Wake the phone's model while the user looks the shot over, so the
    // analysis itself starts straight away.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.read<SettingsController>().onDevice) return;
      unawaited(context.read<OnDeviceModel>().ensureLoaded().catchError((Object _) {}));
    });
  }

  void _analyze() {
    Haptics.medium();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => AnalyzingScreen(
          images: List<File>.of(_images),
          lengthCm: _lengthCm,
          revising: widget.revising,
        ),
      ),
      (Route<dynamic> r) => r.isFirst,
    );
  }

  Future<void> _leave() async {
    if (_changed) {
      final AppLocalizations l = context.l10n;
      final bool ok = await confirm(
        context,
        title: l.reviewDropTitle,
        message: widget.revising == null
            ? l.reviewDropNew(_images.length)
            : l.reviewDropRevising,
        confirmLabel: l.reviewDropConfirm,
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    Navigator.of(context).pop();
  }

  void _add(List<File> files) {
    if (files.isEmpty || !mounted) return;
    Haptics.light();
    setState(() {
      _shown = _images.length;
      _images.addAll(files.take(_room));
    });
  }

  Future<void> _snap() async {
    final List<File>? shots =
        await captureAnotherAngle(context, angle: _images.length + 1, room: _room);
    _add(shots ?? const <File>[]);
  }

  Future<void> _upload() async => _add(await pickMoreAngles(_room));

  void _remove(int i) {
    Haptics.tap();
    setState(() {
      _images.removeAt(i);
      if (_shown >= _images.length || _shown > i) {
        _shown = (_shown - 1).clamp(0, _images.length - 1);
      }
    });
  }

  Future<void> _typeLength(LengthUnit unit) async {
    final AppLocalizations l = context.l10n;
    final bool inches = unit == LengthUnit.inches;
    final String? raw = await promptForText(
      context,
      title: l.reviewTypeLength,
      message: inches ? l.reviewTypeLengthIn : l.reviewTypeLengthCm,
      initial: _lengthCm == null ? '' : fixed(unit.from(_lengthCm!), 1),
      placeholder: l.reviewExample(fixed(inches ? 7.5 : 23.5, 1)),
      keyboard: const TextInputType.numberWithOptions(decimal: true),
      actionLabel: l.reviewSetLength,
    );
    if (raw == null) return;
    final double? v = double.tryParse(raw.replaceAll(',', '.').trim());
    if (v == null || v <= 0) return;
    final double cm = unit == LengthUnit.inches ? v * 2.54 : v;
    setState(() => _lengthCm = cm.clamp(0.1, LengthRuler.maxCm));
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final SettingsController settings = context.watch<SettingsController>();
    final LengthUnit unit = settings.unit;
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    final int n = _images.length;
    final bool retake = widget.fromCamera && !_changed;

    return PopScope(
      canPop: !_changed,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (!didPop) _leave();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: context.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: c.canvas,
          body: Column(
            children: <Widget>[
              SizedBox(height: safe.top + 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: <Widget>[
                    RoundButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: retake ? l.reviewRetake : l.back,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.revising != null
                            ? l.reviewTitleRevising
                            : n > 1
                                ? l.reviewTitleAngles(n)
                                : widget.fromCamera
                                    ? l.reviewNiceShot
                                    : l.reviewLookingGood,
                        style: AppType.title2.copyWith(color: c.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 18, 12, 24),
                  children: <Widget>[
                    Reveal(
                      child: _Polaroid(
                        image: _images[_shown],
                        caption: widget.revising != null
                            ? l.recordTitle(widget.revising!)
                            : l.reviewMysteryBone(
                                (_images.first.path.hashCode % 900 + 100).abs(),
                              ),
                        counter: n > 1 ? '${_shown + 1}/$n' : null,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Reveal(
                      delay: const Duration(milliseconds: 60),
                      child: _AnglesCard(
                        images: _images,
                        shown: _shown,
                        onShow: (int i) => setState(() => _shown = i),
                        onRemove: _remove,
                        onSnap: _snap,
                        onUpload: _upload,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Reveal(
                      delay: const Duration(milliseconds: 120),
                      child: _LengthCard(
                        lengthCm: _lengthCm,
                        unit: unit,
                        onChanged: (double v) => setState(() => _lengthCm = v),
                        onClear: () {
                          Haptics.tap();
                          setState(() => _lengthCm = null);
                        },
                        onType: () => _typeLength(unit),
                        onUnit: (LengthUnit u) {
                          Haptics.tap();
                          settings.setUnit(u);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(16, 14, 12, safe.bottom + 12),
                decoration: BoxDecoration(
                  color: c.canvas,
                  border: Border(top: BorderSide(color: c.ink, width: Chunky.border)),
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      flex: 2,
                      child: SecondaryButton(
                        label: retake ? l.reviewRetake : l.back,
                        icon: retake ? Icons.refresh_rounded : null,
                        onTap: _leave,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 3,
                      child: PrimaryButton(
                        label: n > 1
                            ? l.reviewAnalyzeCount(n)
                            : _lengthCm == null
                                ? l.reviewSkipAnalyze
                                : l.reviewAnalyzeIt,
                        icon: Icons.auto_awesome_rounded,
                        onTap: _analyze,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Polaroid extends StatelessWidget {
  const _Polaroid({required this.image, required this.caption, this.counter});

  final File image;
  final String caption;

  /// "2/3" when there are several angles.
  final String? counter;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final double h = (MediaQuery.sizeOf(context).height * 0.36).clamp(220.0, 380.0);
    return Center(
      child: Transform.rotate(
        angle: -0.03,
        child: Chunk(
          color: Colors.white,
          radius: 10,
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: h,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      AnimatedSwitcher(
                        duration: Motion.quick,
                        child: SpecimenImage(
                          key: ValueKey<String>(image.path),
                          path: image.path,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (counter != null)
                        PositionedDirectional(
                          top: 10,
                          end: 10,
                          child: StatusPill(counter!, color: c.accent, filled: true),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 42,
                child: Center(
                  child: Text(
                    caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.title3.copyWith(
                      color: const Color(0xFF141414),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The tray of photos of this bone, with buttons to add another angle.
class _AnglesCard extends StatelessWidget {
  const _AnglesCard({
    required this.images,
    required this.shown,
    required this.onShow,
    required this.onRemove,
    required this.onSnap,
    required this.onUpload,
  });

  final List<File> images;
  final int shown;
  final ValueChanged<int> onShow;
  final ValueChanged<int> onRemove;
  final VoidCallback onSnap;
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final int n = images.length;
    final bool full = n >= kMaxPhotos;

    return Chunk(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  n == 1 ? l.reviewMoreAnglesQ : l.reviewAngles,
                  style: AppType.title2.copyWith(color: c.textPrimary),
                ),
              ),
              Transform.rotate(
                angle: -0.05,
                child: StatusPill(
                  n == 1 ? l.reviewOptional : l.reviewAnglesOf(n, kMaxPhotos),
                  color: c.stickers[1],
                  filled: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            n == 1 ? l.reviewAnglesBodyOne : l.reviewAnglesBodyMany(n),
            style: AppType.subhead.copyWith(color: c.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 88,
            child: ListView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              children: <Widget>[
                for (int i = 0; i < n; i++)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(end: 8),
                    child: _Thumb(
                      image: images[i],
                      number: i + 1,
                      selected: i == shown,
                      onTap: () => onShow(i),
                      onRemove: n > 1 ? () => onRemove(i) : null,
                    ),
                  ),
                if (!full) ...<Widget>[
                  _AddTile(
                    icon: Icons.camera_alt_rounded,
                    label: l.reviewSnap,
                    hint: l.reviewSnapHint,
                    color: c.accent,
                    onTap: onSnap,
                  ),
                  const SizedBox(width: 6),
                  _AddTile(
                    icon: Icons.photo_library_rounded,
                    label: l.reviewUpload,
                    hint: l.reviewUploadHint,
                    color: c.sticker(2),
                    onTap: onUpload,
                  ),
                ],
              ],
            ),
          ),
          if (full)
            Text(
              l.reviewMaxPhotos,
              style: AppType.caption.copyWith(color: c.textTertiary),
            ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.image,
    required this.number,
    required this.selected,
    required this.onTap,
    this.onRemove,
  });

  final File image;
  final int number;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  static const double _side = 72;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return SizedBox(
      width: _side + 8,
      height: 88,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          PositionedDirectional(
            start: 0,
            top: 8,
            child: Pressable(
              onTap: onTap,
              child: AnimatedContainer(
                duration: Motion.quick,
                curve: Motion.standard,
                width: _side,
                height: _side,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? c.accent : c.ink,
                    width: selected ? 3.4 : Chunky.border,
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: c.shadow,
                      offset: selected ? const Offset(3, 3) : Offset.zero,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(selected ? 10.6 : 11.8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      SpecimenImage(path: image.path, iconSize: 20),
                      PositionedDirectional(
                        start: 4,
                        bottom: 4,
                        child: Container(
                          width: 20,
                          height: 20,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF141414), width: 1.6),
                          ),
                          child: Text(
                            '$number',
                            style: AppType.caption.copyWith(
                              color: const Color(0xFF141414),
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (onRemove != null)
            PositionedDirectional(
              end: 0,
              top: 0,
              child: Semantics(
                label: context.l10n.reviewRemovePhoto(number),
                button: true,
                child: Pressable(
                  onTap: onRemove,
                  scale: 0.86,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: c.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.ink, width: 1.8),
                    ),
                    child: Icon(Icons.close_rounded, size: 14, color: c.textPrimary),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;

  /// What a screen reader says for the tile; the one word on it is too terse.
  final String hint;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const Color ink = Color(0xFF141414);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Semantics(
        label: hint,
        button: true,
        child: Chunk(
          width: 72,
          height: 72,
          radius: 14,
          shadow: 3,
          color: color,
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, size: 22, color: ink),
              const SizedBox(height: 3),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: AppType.caption.copyWith(color: ink, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LengthCard extends StatelessWidget {
  const _LengthCard({
    required this.lengthCm,
    required this.unit,
    required this.onChanged,
    required this.onClear,
    required this.onType,
    required this.onUnit,
  });

  final double? lengthCm;
  final LengthUnit unit;
  final ValueChanged<double> onChanged;
  final VoidCallback onClear;
  final VoidCallback onType;
  final ValueChanged<LengthUnit> onUnit;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final bool set = lengthCm != null;
    final String number = set ? fixed(unit.from(lengthCm!), 1) : '--';

    return Chunk(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  l.reviewHowLong,
                  style: AppType.title2.copyWith(color: c.textPrimary),
                ),
              ),
              Transform.rotate(
                angle: 0.06,
                child: StatusPill(l.reviewOptional, color: c.stickers[2], filled: true),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            l.reviewLengthBody,
            style: AppType.subhead.copyWith(color: c.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),
          StretchyBone(
            valueCm: lengthCm,
            caption: set ? l.reviewEndToEnd : l.reviewWaitingNumber,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Pressable(
                  onTap: onType,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: <Widget>[
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            number,
                            style: AppType.mega.copyWith(
                              color: set ? c.textPrimary : c.textTertiary,
                              fontSize: 52,
                              fontFeatures: const <FontFeature>[
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l.unitSymbol(unit),
                        style: AppType.title2.copyWith(color: c.textSecondary),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.edit_rounded, size: 16, color: c.textTertiary),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 108,
                child: SegmentedControl<LengthUnit>(
                  value: unit,
                  onChanged: onUnit,
                  segments: <LengthUnit, String>{
                    for (final LengthUnit u in LengthUnit.values) u: l.unitSymbol(u),
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LengthRuler(unit: unit, valueCm: lengthCm, onChanged: onChanged),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Icon(Icons.swipe_rounded, size: 16, color: c.textTertiary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  set ? l.reviewTapToType : l.reviewFlickTape,
                  style: AppType.caption.copyWith(color: c.textTertiary),
                ),
              ),
              if (set)
                Pressable(
                  onTap: onClear,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: c.ink, width: 1.6),
                    ),
                    child: Text(
                      l.reviewClear,
                      style: AppType.caption.copyWith(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
