import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../data/reference_data.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../widgets/bone_buddy.dart';
import '../widgets/bone_sketch.dart';
import '../widgets/inset_group.dart';
import '../widgets/nav.dart';
import '../widgets/primitives.dart';
import '../widgets/wide.dart';
import 'bone_detail_screen.dart';
import 'pipeline_screen.dart';

/// Field reference for the sixteen classes the model knows, grouped by region.
class ReferenceScreen extends StatelessWidget {
  const ReferenceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;

    final Map<BoneRegion, List<BoneEntry>> byRegion =
        <BoneRegion, List<BoneEntry>>{};
    for (final BoneEntry e in kBoneReference) {
      byRegion.putIfAbsent(e.region, () => <BoneEntry>[]).add(e);
    }

    final List<BoneRegion> regions = BoneRegion.values.where(byRegion.containsKey).toList();
    List<Widget> section(BoneRegion region) => <Widget>[
          GroupLabel(l.regionName(region)),
          InsetGroup(
            separatorIndent: 80,
            children: byRegion[region]!
                .map(
                  (BoneEntry e) => InsetRow(
                    minHeight: 62,
                    leading: BoneSketch(entry: e),
                    title: l.atlas(e).name,
                    subtitle: l.atlas(e).blurb,
                    chevron: true,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => BoneDetailScreen(entry: e),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ];

    final Widget how = Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Chunk(
        color: c.sticker(3),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PipelineScreen(),
          ),
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(18, 16, 12, 16),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l.atlasHowCardTitle,
                    style: AppType.title2
                        .copyWith(color: const Color(0xFF141414)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.atlasHowCardBody,
                    style: AppType.subhead.copyWith(
                      color: const Color(0xFF141414)
                          .withValues(alpha: 0.75),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const BoneBuddy(
              size: 92,
              mood: BuddyMood.thinking,
              tilt: 0.2,
            ),
          ],
        ),
      ),
    );

    // On a tablet the regions fill two columns of about the same length, in
    // their usual order.
    final bool wide = Wide.of(context);
    int split = regions.length;
    if (wide) {
      final List<int> rows = <int>[for (final BoneRegion r in regions) byRegion[r]!.length + 1];
      final int total = rows.fold(0, (int a, int b) => a + b);
      int run = 0;
      int best = total;
      for (int k = 0; k < rows.length; k++) {
        run += rows[k];
        final int gap = (total - 2 * run).abs();
        if (gap < best) {
          best = gap;
          split = k + 1;
        }
      }
    }

    return Scaffold(
      backgroundColor: c.canvas,
      body: LargeTitleScrollView(
        title: l.tabBones,
        subtitle: l.atlasSubtitle(kBoneReference.length),
        slivers: <Widget>[
          SliverToBoxAdapter(child: how),
          if (wide)
            SliverToBoxAdapter(
              child: TwoColumns(
                start: <Widget>[for (final BoneRegion r in regions.take(split)) ...section(r)],
                end: <Widget>[for (final BoneRegion r in regions.skip(split)) ...section(r)],
              ),
            )
          else
            SliverList.list(
              children: <Widget>[for (final BoneRegion r in regions) ...section(r)],
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
