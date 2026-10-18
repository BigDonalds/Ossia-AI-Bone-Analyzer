import 'package:flutter/material.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../data/reference_data.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../widgets/nav.dart';
import '../widgets/primitives.dart';

/// Walks the nine stages of the pipeline. Written to set expectations: which
/// stages are dependable and which are not.
class PipelineScreen extends StatelessWidget {
  const PipelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: <Widget>[
          DetailBar(title: l.howTitle),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                  20, 24, 20, 100 + MediaQuery.paddingOf(context).bottom),
              children: <Widget>[
                Reveal(
                  child: Text(
                    l.howHeading,
                    style: AppType.title1.copyWith(color: c.textPrimary),
                  ),
                ),
                const SizedBox(height: 8),
                Reveal(
                  child: Text(
                    l.howIntro,
                    style: AppType.body.copyWith(
                      color: c.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ...kPhaseDocs.asMap().entries.map(
                      (MapEntry<int, PhaseDoc> e) => Reveal(
                        delay: Motion.stagger * (e.key + 1),
                        child: _PhaseRow(
                          doc: e.value,
                          last: e.key == kPhaseDocs.length - 1,
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseRow extends StatelessWidget {
  const _PhaseRow({required this.doc, required this.last});

  final PhaseDoc doc;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final (String title, String detail) = context.l10n.phaseDoc(doc);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Numbered node with a connecting rule, so the stages read as a
          // sequence rather than a list of unrelated cards.
          Column(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.sticker(doc.number),
                  shape: BoxShape.circle,
                  border: Border.all(color: c.ink, width: 2),
                ),
                child: Text(
                  '${doc.number}',
                  style: AppType.metric.copyWith(
                    color: const Color(0xFF141414),
                    fontSize: 15,
                  ),
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(width: 2.5, color: c.ink),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 26, top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppType.headline.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    detail,
                    style: AppType.subhead.copyWith(
                      color: c.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
