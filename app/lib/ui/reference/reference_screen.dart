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

    return Scaffold(
      backgroundColor: c.canvas,
      body: LargeTitleScrollView(
        title: l.tabAtlas,
        subtitle: l.atlasSubtitle(kBoneReference.length),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Padding(
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
            ),
          ),
          ...BoneRegion.values.where(byRegion.containsKey).expand(
                (BoneRegion region) => <Widget>[
                  SliverToBoxAdapter(child: GroupLabel(l.regionName(region))),
                  SliverToBoxAdapter(
                    child: InsetGroup(
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
                  ),
                ],
              ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }
}
