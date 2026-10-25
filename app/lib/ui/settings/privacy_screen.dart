import 'package:flutter/material.dart';

import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../l10n/l10n.dart';
import '../widgets/inset_group.dart';
import '../widgets/nav.dart';
import '../widgets/primitives.dart';

/// The privacy policy, the same text as PRIVACY.md at the top of the
/// repository. Both stores ask for it to be reachable inside the app.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final List<(String, String)> sections = <(String, String)>[
      (l.privacyShortTitle, l.privacyShortBody),
      (l.privacyPhotosTitle, l.privacyPhotosBody),
      (l.privacyOnlineTitle, l.privacyOnlineBody),
      (l.privacyPermissionsTitle, l.privacyPermissionsBody),
      (l.privacyChangesTitle, l.privacyChangesBody),
    ];

    return Scaffold(
      backgroundColor: c.canvas,
      body: Column(
        children: <Widget>[
          DetailBar(title: l.privacyTitle),
          Expanded(
            // Selectable, so the web address can be copied.
            child: SelectionArea(
              child: ListView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.only(
                    bottom: 100 + MediaQuery.paddingOf(context).bottom),
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: Text(
                      l.privacyUpdated,
                      style: AppType.subhead.copyWith(color: c.textSecondary),
                    ),
                  ),
                  for (final (String title, String body) in sections) ...<Widget>[
                    GroupLabel(title),
                    InsetGroup(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 13, 16, 15),
                          child: Text(
                            body,
                            style: AppType.body.copyWith(
                              color: c.textPrimary,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
