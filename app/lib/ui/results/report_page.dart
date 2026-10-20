import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../core/util/haptics.dart';
import '../../data/history_store.dart';
import '../../data/models/analysis.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../scan/review_screen.dart';
import '../widgets/inset_group.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';
import '../widgets/specimen_image.dart';
import 'result_sections.dart';
import 'specimen_header.dart';

/// The full analysis report. Shown straight after an analysis and again when
/// a record is opened from the Library — same page either way, so the two
/// never drift apart.
class ReportPage extends StatefulWidget {
  const ReportPage({
    super.key,
    required this.record,
    required this.saved,
    this.backLabel,
    this.showAnalyzeAnother = false,
  });

  final AnalysisRecord record;

  /// False when auto-save is off and this result is not yet in the Library.
  final bool saved;

  /// What a screen reader calls the back button; "Back" when null.
  final String? backLabel;
  final bool showAnalyzeAnother;

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  late AnalysisRecord _record = widget.record;
  late bool _saved = widget.saved;

  /// Width over height of the first photo, once it has loaded, so the header
  /// can be sized to show all of it.
  double? _aspect;
  String? _measured;
  VoidCallback _stopMeasuring = () {};

  HistoryStore get _history => context.read<HistoryStore>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _measurePhoto();
  }

  @override
  void dispose() {
    _stopMeasuring();
    super.dispose();
  }

  void _measurePhoto() {
    if (_record.imagePath == _measured) return;
    _measured = _record.imagePath;
    _stopMeasuring();
    _stopMeasuring = SpecimenImage.measure(context, _record.imagePath, (double aspect) {
      if (mounted && aspect != _aspect) setState(() => _aspect = aspect);
    });
  }

  Future<void> _persist(AnalysisRecord next) async {
    setState(() => _record = next);
    if (_saved) await _history.update(next);
  }

  Future<void> _rename() async {
    final AppLocalizations l = context.l10n;
    final String? name = await promptForText(
      context,
      title: l.reportNameTitle,
      message: l.reportNameBody,
      initial: _record.label ?? '',
      placeholder: l.reportNameExample,
    );
    if (name == null) return;
    await _persist(_record.copyWith(label: name));
  }

  Future<void> _editNote() async {
    final AppLocalizations l = context.l10n;
    final String? note = await promptForText(
      context,
      title: _record.note == null ? l.reportAddNote : l.reportEditNote,
      message: l.reportNoteBody,
      initial: _record.note ?? '',
      placeholder: l.reportNotePlaceholder,
      actionLabel: l.done,
    );
    if (note == null) return;
    await _persist(_record.copyWith(note: note));
  }

  Future<void> _copyJson() async {
    await Clipboard.setData(ClipboardData(text: _record.toPrettyJson()));
    if (!mounted) return;
    Haptics.light();
    showToast(context, context.l10n.reportCopied, icon: Icons.check_rounded);
  }

  Future<void> _save() async {
    // The picker leaves photos in a cache directory the system may clear, so
    // archiving copies them somewhere permanent before the record is stored.
    final List<String> paths = await _history.archiveImages(
        <File>[for (final String p in _record.imagePaths) File(p)], _record.id);
    final AnalysisRecord next = AnalysisRecord(
      id: _record.id,
      imagePath: paths.first,
      extraImagePaths: paths.sublist(1),
      createdAt: _record.createdAt,
      result: _record.result,
      label: _record.label,
      note: _record.note,
      measuredLengthCm: _record.measuredLengthCm,
    );
    await _history.add(next);
    if (!mounted) return;
    setState(() {
      _record = next;
      _saved = true;
    });
    Haptics.success();
    showToast(context, context.l10n.reportSavedToast, icon: Icons.inventory_2_outlined);
  }

  /// Back to review with this bone's photos, to add angles and analyse again.
  /// The new report replaces this one.
  void _addAngles() {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute<void>(
        builder: (_) => ReviewScreen(
          images: <File>[for (final String p in _record.imagePaths) File(p)],
          lengthCm: _record.measuredLengthCm,
          revising: _record,
        ),
      ),
    );
  }

  Future<void> _delete() async {
    final bool ok = await confirm(
      context,
      title: context.l10n.reportDeleteTitle,
      message: context.l10n.reportDeleteBody(_record.imagePaths.length),
      confirmLabel: context.l10n.delete,
      destructive: true,
    );
    if (!ok) return;
    await _history.remove(_record.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _openActions() {
    final AppLocalizations l = context.l10n;
    showAppSheet<void>(
      context,
      title: l.reportSheetTitle,
      builder: (BuildContext sheetContext) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            InsetGroup(
              children: <Widget>[
                InsetRow(
                  title: _record.label == null ? l.reportNameTitle : l.reportRename,
                  leading: const Icon(Icons.label_outline_rounded, size: 21),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _rename();
                  },
                ),
                InsetRow(
                  title: _record.note == null ? l.reportAddNote : l.reportEditNote,
                  leading: const Icon(Icons.notes_rounded, size: 21),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _editNote();
                  },
                ),
                InsetRow(
                  title: l.reportAddAngle,
                  leading: const Icon(Icons.add_a_photo_outlined, size: 21),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _addAngles();
                  },
                ),
                InsetRow(
                  title: l.reportCopy,
                  leading: const Icon(Icons.data_object_rounded, size: 21),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _copyJson();
                  },
                ),
              ],
            ),
            if (_saved) ...<Widget>[
              const SizedBox(height: 14),
              InsetGroup(
                children: <Widget>[
                  InsetRow(
                    title: l.reportDelete,
                    tint: context.colors.critical,
                    leading: Icon(Icons.delete_outline_rounded,
                        size: 21, color: context.colors.critical),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _delete();
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final Size screen = MediaQuery.sizeOf(context);
    final double top = MediaQuery.paddingOf(context).top;
    final double photo =
        SpecimenHeader.photoHeight(screen, _aspect, several: _record.imagePaths.length > 1);

    return Scaffold(
      backgroundColor: c.canvas,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: <Widget>[
          SliverPersistentHeader(
            pinned: true,
            delegate: SpecimenHeader(
              imagePaths: _record.imagePaths,
              title: l.recordTitle(_record),
              colors: c,
              backLabel: widget.backLabel ?? l.back,
              topPadding: top,
              expandedHeight: SpecimenHeader.photoTop(top) + photo,
              actions: (double t) => <Widget>[
                HeaderAction(
                  icon: Icons.more_horiz_rounded,
                  tooltip: l.reportOptions,
                  t: t,
                  colors: c,
                  onTap: _openActions,
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(child: VerdictBlock(record: _record)),
          SliverToBoxAdapter(child: ResultSections(record: _record)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
              child: Column(
                children: <Widget>[
                  if (!_saved)
                    PrimaryButton(
                      label: l.reportSave,
                      icon: Icons.inventory_2_outlined,
                      onTap: _save,
                    ),
                  if (!_saved) const SizedBox(height: 10),
                  SecondaryButton(
                    label: l.reportAddAngle,
                    icon: Icons.add_a_photo_outlined,
                    onTap: _addAngles,
                  ),
                  if (widget.showAnalyzeAnother) const SizedBox(height: 10),
                  if (widget.showAnalyzeAnother)
                    SecondaryButton(
                      label: l.reportAnalyzeAnother,
                      icon: Icons.camera_alt_outlined,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: ResultDisclaimer()),
          SliverToBoxAdapter(
            child: SizedBox(height: 40 + MediaQuery.paddingOf(context).bottom),
          ),
        ],
      ),
    );
  }
}
