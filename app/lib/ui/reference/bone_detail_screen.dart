import 'package:flutter/material.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../data/reference_data.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../widgets/bone_sketch.dart';
import '../widgets/nav.dart';
import '../widgets/primitives.dart';
import '../widgets/skeleton_map.dart';
import '../widgets/text_fit.dart';

class BoneDetailScreen extends StatelessWidget {
  const BoneDetailScreen({super.key, required this.entry});

  final BoneEntry entry;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final AtlasText text = l.atlas(entry);

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: <Widget>[
          DetailBar(title: text.name),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.fromLTRB(
                  20, 24, 20, 100 + MediaQuery.paddingOf(context).bottom),
              children: <Widget>[
                Reveal(
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints box) {
                      const double sketch = 76;
                      final Widget info = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            text.name,
                            style: AppType.title1.copyWith(color: c.textPrimary),
                          ),
                          const SizedBox(height: 6),
                          // Side by side when they fit, else one under the
                          // other; German names are long.
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: <Widget>[
                              StatusPill(l.regionName(entry.region),
                                  color: c.accent, filled: true, maxLines: 2),
                              if (text.aka != null) StatusPill(text.aka!, maxLines: 2),
                            ],
                          ),
                        ],
                      );
                      // The sketch moves above the name when a word of it is
                      // too long to sit beside it ("Lendenwirbel" in large text).
                      if (TextFit.longestWord(context, text.name, AppType.title1) >
                          box.maxWidth - sketch - 14) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            BoneSketch(entry: entry, size: sketch),
                            const SizedBox(height: 14),
                            info,
                          ],
                        );
                      }
                      return Row(
                        children: <Widget>[
                          BoneSketch(entry: entry, size: sketch),
                          const SizedBox(width: 14),
                          Expanded(child: info),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 22),
                Reveal(
                  delay: Motion.stagger,
                  child: Text(
                    text.summary,
                    style: AppType.body.copyWith(
                      color: c.textPrimary,
                      height: 1.52,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Reveal(
                  delay: Motion.stagger * 2,
                  child: _Section(
                    title: l.atlasMapTitle,
                    child: SkeletonMap(
                      bone: entry.key,
                      label: l.atlasMapLabel(text.name),
                      delay: Motion.stagger * 2,
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Reveal(
                  delay: Motion.stagger * 3,
                  child: _Section(
                    title: l.atlasLookFor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: text.landmarks
                          .map((String line) => _Bullet(text: line))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 26),
                Reveal(
                  delay: Motion.stagger * 4,
                  child: _Section(
                    title: l.atlasSidingTitle,
                    child: Text(
                      text.siding,
                      style: AppType.subhead.copyWith(
                        color: c.textPrimary,
                        height: 1.55,
                      ),
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

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: AppType.groupHeader.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: 10),
        Chunk(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
          child: child,
        ),
      ],
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(top: 7.5),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: c.accent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              text,
              style: AppType.subhead.copyWith(
                color: c.textPrimary,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
