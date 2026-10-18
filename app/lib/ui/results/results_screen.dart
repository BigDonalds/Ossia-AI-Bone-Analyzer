import 'package:flutter/material.dart';

import '../../data/models/analysis.dart';
import '../../l10n/l10n.dart';
import 'report_page.dart';

/// The report as it appears immediately after an analysis.
class ResultsScreen extends StatelessWidget {
  const ResultsScreen({super.key, required this.record, required this.saved});

  final AnalysisRecord record;
  final bool saved;

  @override
  Widget build(BuildContext context) => ReportPage(
        record: record,
        saved: saved,
        backLabel: context.l10n.tabScan,
        showAnalyzeAnother: true,
      );
}
