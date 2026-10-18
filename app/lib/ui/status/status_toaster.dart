import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/palette.dart';
import '../../data/server_monitor.dart';
import '../../l10n/l10n.dart';
import '../widgets/sheets.dart';

/// Pops a toast, wherever the user is in the app, when the model goes offline
/// or comes back.
class StatusToaster extends StatefulWidget {
  const StatusToaster({super.key, required this.messengerKey, required this.child});

  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final Widget child;

  @override
  State<StatusToaster> createState() => _StatusToasterState();
}

class _StatusToasterState extends State<StatusToaster> {
  ServerMonitor? _monitor;

  /// Last settled state (online or offline); in-between states are ignored.
  LinkState? _settled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ServerMonitor m = context.read<ServerMonitor>();
    if (m != _monitor) {
      _monitor?.removeListener(_onChange);
      _monitor = m..addListener(_onChange);
    }
  }

  void _onChange() {
    final ServerMonitor m = _monitor!;
    final LinkState s = m.state;
    if (s == LinkState.onDevice) {
      _settled = null;
      return;
    }
    if (s != LinkState.online && s != LinkState.offline) return;
    final LinkState? before = _settled;
    _settled = s;
    // No toast for the very first result, or while the status page is
    // already showing the full check.
    if (before == null || before == s || m.fullCheckRunning) return;

    final ScaffoldMessengerState? messenger = widget.messengerKey.currentState;
    if (messenger == null || !mounted) return;
    final AppColors c = context.colors;
    if (s == LinkState.offline) {
      showToast(context, context.l10n.toastLostConnection,
          icon: Icons.cloud_off_rounded, messenger: messenger, color: c.critical);
    } else {
      showToast(context, context.l10n.toastBackOnline,
          icon: Icons.cloud_done_rounded, messenger: messenger, color: c.positive);
    }
  }

  @override
  void dispose() {
    _monitor?.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
