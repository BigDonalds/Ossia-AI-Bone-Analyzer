import 'package:flutter/material.dart';

import '../core/util/haptics.dart';
import '../l10n/l10n.dart';
import 'library/library_screen.dart';
import 'reference/reference_screen.dart';
import 'scan/scan_screen.dart';
import 'settings/settings_screen.dart';
import 'widgets/nav.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  /// Each tab keeps its own navigator so pushing a detail screen does not
  /// hide the tab bar or reset the other tabs.
  final List<GlobalKey<NavigatorState>> _navigators =
      List<GlobalKey<NavigatorState>>.generate(
          4, (_) => GlobalKey<NavigatorState>());

  void _select(int i) {
    if (i == _index) {
      // Tapping the active tab pops it back to root, as iOS does.
      _navigators[i].currentState?.popUntil((Route<dynamic> r) => r.isFirst);
      return;
    }
    Haptics.tap();
    setState(() => _index = i);
  }

  Widget _tab(int i, Widget child) => Navigator(
        key: _navigators[i],
        onGenerateRoute: (RouteSettings _) =>
            MaterialPageRoute<void>(builder: (_) => child),
      );

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = context.l10n;
    final List<TabDestination> destinations = <TabDestination>[
      TabDestination(Icons.camera_alt_outlined, Icons.camera_alt_rounded, l.tabScan),
      TabDestination(Icons.grid_view_outlined, Icons.grid_view_rounded, l.tabStash),
      TabDestination(Icons.auto_stories_outlined, Icons.auto_stories_rounded, l.tabBones),
      TabDestination(Icons.tune_outlined, Icons.tune_rounded, l.tabSettings),
    ];

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? _) {
        if (didPop) return;
        final NavigatorState? nav = _navigators[_index].currentState;
        if (nav != null && nav.canPop()) {
          nav.pop();
        } else if (_index != 0) {
          setState(() => _index = 0);
        }
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _index,
          children: <Widget>[
            _tab(0, const ScanScreen()),
            _tab(1, const LibraryScreen()),
            _tab(2, const ReferenceScreen()),
            _tab(3, const SettingsScreen()),
          ],
        ),
        bottomNavigationBar: AppTabBar(
          destinations: destinations,
          index: _index,
          onChanged: _select,
        ),
      ),
    );
  }
}
