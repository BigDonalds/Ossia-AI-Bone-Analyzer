import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/history_store.dart';
import '../../data/models/analysis.dart';
import '../../l10n/l10n.dart';
import '../results/report_page.dart';

/// Opens a stored analysis by id, so edits made here stay in step with the
/// Library list behind it.
class RecordDetailScreen extends StatelessWidget {
  const RecordDetailScreen({super.key, required this.recordId});

  final String recordId;

  @override
  Widget build(BuildContext context) {
    final HistoryStore history = context.watch<HistoryStore>();
    final AnalysisRecord? record = history.records
        .cast<AnalysisRecord?>()
        .firstWhere((AnalysisRecord? r) => r?.id == recordId,
            orElse: () => null);

    if (record == null) {
      // The record was deleted from underneath this route.
      return const Scaffold(body: SizedBox.shrink());
    }

    return ReportPage(
      key: ValueKey<String>(record.id),
      record: record,
      saved: true,
      backLabel: context.l10n.tabStash,
    );
  }
}
