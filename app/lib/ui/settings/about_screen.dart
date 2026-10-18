import 'package:flutter/material.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../data/reference_data.dart';
import '../../l10n/l10n.dart';
import '../widgets/inset_group.dart';
import '../widgets/nav.dart';
import '../widgets/primitives.dart';

const String kAppVersion = '1.0.0';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: <Widget>[
          DetailBar(title: l.settingsAbout),
          Expanded(
            child: ListView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              padding: EdgeInsets.only(
                  bottom: 100 + MediaQuery.paddingOf(context).bottom),
              children: <Widget>[
                Reveal(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
                    child: Column(
                      children: <Widget>[
                        const _Mark(),
                        const SizedBox(height: 18),
                        Text(
                          l.appName,
                          style: AppType.largeTitle
                              .copyWith(color: c.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.aboutVersion(kAppVersion),
                          style: AppType.subhead
                              .copyWith(color: c.textSecondary),
                        ),
                        const SizedBox(height: 22),
                        Text(
                          l.aboutIntro,
                          textAlign: TextAlign.center,
                          style: AppType.body.copyWith(
                            color: c.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Reveal(
                  delay: Motion.stagger,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      GroupLabel(l.aboutKnows),
                      InsetGroup(
                        children: <Widget>[
                          InsetRow(
                            title: l.aboutKindsOfBone,
                            value: '${kBoneReference.length}',
                          ),
                          InsetRow(title: l.aboutAnimalGroups, value: '13'),
                          InsetRow(title: l.aboutQuestions, value: '9'),
                        ],
                      ),
                      GroupFooter(l.aboutKnowsFooter),
                    ],
                  ),
                ),
                Reveal(
                  delay: Motion.stagger * 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      GroupLabel(l.aboutPrivacy),
                      InsetGroup(
                        children: <Widget>[
                          InsetRow(
                            title: l.aboutPhotos,
                            subtitle: l.aboutPhotosBody,
                          ),
                          InsetRow(
                            title: l.aboutAnalytics,
                            subtitle: l.aboutAnalyticsBody,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Reveal(
                  delay: Motion.stagger * 3,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 34, 20, 0),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
                      decoration: BoxDecoration(
                        color: c.caution.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(Icons.warning_amber_rounded,
                              size: 18, color: c.caution),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Text(
                              l.aboutWarning,
                              style: AppType.footnote.copyWith(
                                color: c.textPrimary,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
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

/// App mark: concentric measuring rings around a centred point, echoing the
/// viewfinder on the capture screen.
class _Mark extends StatelessWidget {
  const _Mark();

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return SizedBox(
      width: 76,
      height: 76,
      child: CustomPaint(painter: _MarkPainter(c.accent)),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.accent);

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset centre = size.center(Offset.zero);
    final Paint ring = Paint()
      ..style = PaintingStyle.stroke
      ..color = accent
      ..strokeWidth = 1.5;

    canvas.drawCircle(centre, size.width * 0.46, ring..color = accent.withValues(alpha: 0.28));
    canvas.drawCircle(centre, size.width * 0.32, ring..color = accent.withValues(alpha: 0.55));
    canvas.drawCircle(
      centre,
      size.width * 0.17,
      Paint()..color = accent,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.accent != accent;
}
