import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../core/util/formatting.dart';
import '../../data/history_store.dart';
import '../../data/models/analysis.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../results/result_sections.dart';
import '../scan/camera_screen.dart';
import '../widgets/bone_buddy.dart';
import '../widgets/inset_group.dart';
import '../widgets/nav.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';
import '../widgets/specimen_image.dart';
import 'record_detail_screen.dart';

enum LibraryFilter { all, human, faunal, flagged }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  LibraryFilter _filter = LibraryFilter.all;
  String _query = '';
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Search looks at the words on screen in the app's language, and at the
  /// English names too, so "femur" still finds a Femur in German.
  bool _matches(AppLocalizations l, AnalysisRecord r) {
    switch (_filter) {
      case LibraryFilter.human:
        if (!r.result.isHuman) return false;
      case LibraryFilter.faunal:
        if (r.result.isHuman) return false;
      case LibraryFilter.flagged:
        if (r.result.damage.flagged.isEmpty) return false;
      case LibraryFilter.all:
        break;
    }
    final String q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    bool has(String s) => s.toLowerCase().contains(q);
    return has(l.recordTitle(r)) ||
        has(l.resultHeadline(r.result)) ||
        has(r.displayTitle) ||
        has(r.note ?? '') ||
        r.result.boneTypes
            .any((Scored s) => has(l.boneName(s.label)) || has(s.display));
  }

  /// Newest first, bucketed by recency the way Photos and Files do.
  Map<String, List<AnalysisRecord>> _grouped(
    AppLocalizations l,
    List<AnalysisRecord> records,
  ) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final Map<String, List<AnalysisRecord>> out =
        <String, List<AnalysisRecord>>{};

    for (final AnalysisRecord r in records) {
      final Duration age = today.difference(
        DateTime(r.createdAt.year, r.createdAt.month, r.createdAt.day),
      );
      final String bucket = age.inDays <= 0
          ? l.libToday
          : age.inDays == 1
              ? l.yesterday
              : age.inDays < 7
                  ? l.libThisWeek
                  : age.inDays < 30
                      ? l.libThisMonth
                      : l.libEarlier;
      out.putIfAbsent(bucket, () => <AnalysisRecord>[]).add(r);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final HistoryStore history = context.watch<HistoryStore>();
    final List<AnalysisRecord> all = history.records;
    final List<AnalysisRecord> shown =
        all.where((AnalysisRecord r) => _matches(l, r)).toList();
    final Map<String, List<AnalysisRecord>> groups = _grouped(l, shown);

    return Scaffold(
      backgroundColor: c.canvas,
      body: LargeTitleScrollView(
        title: l.libTitle,
        subtitle: all.isEmpty
            ? l.libEmptySubtitle
            : '${l.libBonesCollected(all.length)} · '
                '${l.libHumanCount(history.humanCount)}',
        slivers: <Widget>[
          if (all.isNotEmpty) ...<Widget>[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _SearchField(
                  controller: _search,
                  onChanged: (String v) => setState(() => _query = v),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SegmentedControl<LibraryFilter>(
                  value: _filter,
                  onChanged: (LibraryFilter v) => setState(() => _filter = v),
                  segments: <LibraryFilter, String>{
                    LibraryFilter.all: l.libFilterAll,
                    LibraryFilter.human: l.libFilterHuman,
                    LibraryFilter.faunal: l.libFilterAnimal,
                    LibraryFilter.flagged: l.libFilterFlagged,
                  },
                ),
              ),
            ),
          ],
          if (all.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 120),
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  mood: BuddyMood.sad,
                  title: l.libEmptyTitle,
                  message: l.libEmptyBody,
                  action: PrimaryButton(
                    label: l.scanSnap,
                    icon: Icons.camera_alt_rounded,
                    expand: false,
                    onTap: () => openBoneCamera(context),
                  ),
                ),
              ),
            )
          else if (shown.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 120),
                child: EmptyState(
                  icon: Icons.filter_list_off_rounded,
                  mood: BuddyMood.thinking,
                  title: l.libNoMatchTitle,
                  message: l.libNoMatchBody,
                ),
              ),
            )
          else
            ...groups.entries.expand(
              (MapEntry<String, List<AnalysisRecord>> g) => <Widget>[
                SliverToBoxAdapter(child: GroupLabel(g.key)),
                SliverToBoxAdapter(
                  child: InsetGroup(
                    separatorIndent: 84,
                    children: g.value
                        .map((AnalysisRecord r) => _RecordRow(record: r))
                        .toList(),
                  ),
                ),
              ],
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.ink, width: 2),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.search_rounded, size: 18, color: c.textTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              cursorColor: c.accent,
              style: AppType.callout.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                hintText: context.l10n.libSearchHint,
                hintStyle: AppType.callout.copyWith(color: c.textTertiary),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            Semantics(
              button: true,
              label: context.l10n.libClearSearch,
              child: Pressable(
                scale: 0.85,
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: Icon(Icons.cancel, size: 17, color: c.textTertiary),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.record});

  final AnalysisRecord record;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final AnalysisResult r = record.result;
    final List<String> flags = r.damage.flagged;

    return Dismissible(
      key: ValueKey<String>(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: c.critical,
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: 22),
        child: const Icon(Icons.delete_outline_rounded,
            color: Colors.white, size: 22),
      ),
      confirmDismiss: (_) => confirm(
        context,
        title: l.reportDeleteTitle,
        message: l.reportDeleteBody(record.imagePaths.length),
        confirmLabel: l.delete,
        destructive: true,
      ),
      onDismissed: (_) => context.read<HistoryStore>().remove(record.id),
      child: InsetRow(
        minHeight: 76,
        chevron: true,
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RecordDetailScreen(recordId: record.id),
          ),
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SpecimenImage(path: record.imagePath, width: 56, height: 56),
        ),
        title: l.recordTitle(record),
        subtitle: record.label == null
            ? l.relativeTime(record.createdAt)
            : '${l.resultHeadline(r)} · ${l.relativeTime(record.createdAt)}',
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Tone as a sticker fill with ink type: lime or yellow text on
            // white would be unreadable.
            StatusPill(
              percent(r.overallConfidence),
              color: confidenceTone(context, r.overallConfidence),
              filled: true,
            ),
            if (flags.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4),
              Icon(Icons.warning_amber_rounded, size: 15, color: c.caution),
            ],
          ],
        ),
      ),
    );
  }
}
