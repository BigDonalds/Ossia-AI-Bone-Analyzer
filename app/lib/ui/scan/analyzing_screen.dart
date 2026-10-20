import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../core/util/haptics.dart';
import '../../data/analysis_engine.dart';
import '../../data/history_store.dart';
import '../../data/models/analysis.dart';
import '../../data/on_device/on_device_model.dart';
import '../../data/server_monitor.dart';
import '../../data/settings_controller.dart';
import '../../l10n/l10n.dart';
import '../../l10n/labels.dart';
import '../results/results_screen.dart';
import '../widgets/bone_buddy.dart';
import '../widgets/phone_icon.dart';
import '../widgets/primitives.dart';
import '../widgets/specimen_image.dart';
import 'specimen_frame.dart';

class AnalyzingScreen extends StatefulWidget {
  const AnalyzingScreen({
    super.key,
    required this.images,
    this.lengthCm,
    this.revising,
  });

  /// Photos of the same bone, read together.
  final List<File> images;

  /// The user's own measurement, passed through to the engine and the record.
  final double? lengthCm;

  /// The analysis this one replaces, when the user added angles to it.
  final AnalysisRecord? revising;

  @override
  State<AnalyzingScreen> createState() => _AnalyzingScreenState();
}

class _AnalyzingScreenState extends State<AnalyzingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  )..repeat();

  StreamSubscription<AnalysisEvent>? _sub;
  LocalText? _error;

  /// The stage on screen. It follows the engine one step at a time, so a fast
  /// phone still shows the whole walk-through instead of a flash.
  int _phase = 0;

  /// The furthest stage the engine has reached.
  int _reached = 0;

  /// The finished report, held back until the walk-through catches up.
  AnalysisResult? _result;

  Timer? _pacer;
  final Stopwatch _onStage = Stopwatch();

  /// Each stage stays up at least this long, and the last one a little longer
  /// before the report opens.
  static const Duration _stageTime = Duration(milliseconds: 300);
  static const Duration _lastHold = Duration(milliseconds: 600);

  /// The server couldn't be reached, so offer the phone's own model.
  bool _offerLocal = false;

  /// The user took that offer for this analysis (Settings stay as they are).
  bool _forceLocal = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  void _run() {
    final SettingsController settings = context.read<SettingsController>();
    final bool local = settings.onDevice || _forceLocal;
    final AnalysisEngine engine = local
        ? LocalEngine(context.read<OnDeviceModel>())
        : RemoteEngine(settings.serverUrl);

    setState(() {
      _error = null;
      _offerLocal = false;
      _phase = 0;
    });
    _reached = 0;
    _result = null;
    _onStage
      ..reset()
      ..start();
    _pacer?.cancel();
    _pacer = Timer.periodic(const Duration(milliseconds: 50), _tick);

    _sub?.cancel();
    _sub = engine
        .analyze(widget.images, lengthCm: widget.lengthCm)
        .listen((AnalysisEvent event) {
      if (!mounted) return;
      switch (event) {
        case PhaseStarted(:final int index):
          if (index > _reached) _reached = index;
        case AnalysisSucceeded(:final AnalysisResult result):
          _reached = kPhaseCount - 1;
          _result = result;
        case AnalysisFailed(:final LocalText message, :final bool serverUnreachable):
          _pacer?.cancel();
          Haptics.medium();
          if (!local) context.read<ServerMonitor>().quickCheck();
          setState(() {
            _error = message;
            _offerLocal = !local && serverUnreachable && OnDeviceModel.supported;
          });
      }
    });
  }

  void _tick(Timer _) {
    if (!mounted) return;
    if (_phase < _reached) {
      if (_onStage.elapsed < _stageTime) return;
      _onStage.reset();
      setState(() => _phase++);
    } else if (_result != null && _onStage.elapsed >= _lastHold) {
      _pacer?.cancel();
      _finish(_result!);
    }
  }

  void _runLocally() {
    Haptics.medium();
    _forceLocal = true;
    _run();
  }

  Future<void> _finish(AnalysisResult result) async {
    final HistoryStore history = context.read<HistoryStore>();
    final SettingsController settings = context.read<SettingsController>();
    final AnalysisRecord? old = widget.revising;

    // A saved report stays saved when angles are added to it.
    final bool keep = old != null ? history.contains(old.id) : settings.autoSave;
    final String id = old?.id ?? DateTime.now().microsecondsSinceEpoch.toString();
    List<String> paths = <String>[for (final File f in widget.images) f.path];
    if (keep) {
      try {
        paths = await history.archiveImages(widget.images, id);
      } catch (_) {
        // Fall back to the temporary paths; the result is still shown.
      }
    }

    final AnalysisRecord record = AnalysisRecord(
      id: id,
      imagePath: paths.first,
      extraImagePaths: paths.sublist(1),
      createdAt: old?.createdAt ?? DateTime.now(),
      result: result,
      label: old?.label,
      note: old?.note,
      measuredLengthCm: widget.lengthCm,
    );

    if (keep) {
      await (old != null ? history.update(record) : history.add(record));
    }

    if (!mounted) return;
    Haptics.success();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => ResultsScreen(record: record, saved: keep),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pacer?.cancel();
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final bool failed = _error != null;

    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  RoundButton(
                    icon: Icons.close_rounded,
                    tooltip: l.cancel,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  if (!failed)
                    StatusPill(
                      l.analyzingStep(_phase + 1, kPhaseCount),
                      color: c.accent,
                      filled: true,
                    ),
                  const SizedBox(width: 4),
                ],
              ),
              const Spacer(flex: 2),
              _Specimen(images: widget.images, sweep: _sweep, failed: failed),
              const SizedBox(height: 26),
              if (!failed)
                _Progress(phase: _phase)
              else
                _Failure(
                  message: _error!(l),
                  onRetry: _run,
                  onLocal: _offerLocal ? _runLocally : null,
                ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}

/// One line of banter per pipeline stage. The real stage name sits under it.
List<String> _quips(AppLocalizations l) => <String>[
      l.quipFinding,
      l.quipHumanOrAnimal,
      l.quipWhichBone,
      l.quipWhichEnd,
      l.quipMissingBits,
      l.quipMarks,
      l.quipWhose,
      l.quipAgeSex,
      l.quipWriting,
    ];

class _Specimen extends StatelessWidget {
  const _Specimen({
    required this.images,
    required this.sweep,
    required this.failed,
  });

  final List<File> images;
  final AnimationController sweep;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final double side =
        (MediaQuery.sizeOf(context).height * 0.34).clamp(200.0, 320.0);

    return Center(
      child: SizedBox(
        width: side + 44,
        height: side + 30,
        child: Stack(
          clipBehavior: Clip.none,
          children: <Widget>[
            // The other angles, fanned out behind the first.
            for (int k = (images.length - 1).clamp(0, 2); k >= 1; k--)
              Positioned(
                left: 12 + 9.0 * k,
                top: 6.0 * k,
                child: Transform.rotate(
                  angle: 0.025 - 0.07 * k,
                  child: Chunk(
                    width: side,
                    height: side,
                    radius: 26,
                    child: SpecimenImage(path: images[k].path, fit: BoxFit.cover),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              top: 0,
              child: Transform.rotate(
                angle: 0.025,
                child: Chunk(
                  width: side,
                  height: side,
                  radius: 26,
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      SpecimenImage(path: images.first.path, fit: BoxFit.cover),
                      Container(
                        color: Colors.black
                            .withValues(alpha: failed ? 0.5 : 0.18),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: failed
                            ? SpecimenFrame(
                                accent: c.critical,
                                grid: Colors.white.withValues(alpha: 0.12),
                              )
                            : AnimatedBuilder(
                                animation: sweep,
                                builder: (BuildContext context, _) =>
                                    SpecimenFrame(
                                  accent: c.accent,
                                  grid: Colors.white.withValues(alpha: 0.2),
                                  sweep: Curves.easeInOut.transform(
                                    // Ping-pong so the line sweeps down then up.
                                    sweep.value < 0.5
                                        ? sweep.value * 2
                                        : (1 - sweep.value) * 2,
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (images.length > 1)
              Positioned(
                left: 0,
                top: -10,
                child: Transform.rotate(
                  angle: -0.08,
                  child: StatusPill(
                    context.l10n.analyzingPhotos(images.length),
                    color: c.accent,
                    filled: true,
                  ),
                ),
              ),
            Positioned(
              right: -8,
              bottom: -10,
              child: BoneBuddy(
                size: 116,
                tilt: -0.3,
                mood: failed ? BuddyMood.sad : BuddyMood.thinking,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.phase});

  final int phase;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;

    return Column(
      children: <Widget>[
        SizedBox(
          height: 60,
          child: AnimatedSwitcher(
            duration: Motion.quick,
            switchOutCurve: Motion.exit,
            transitionBuilder: (Widget child, Animation<double> a) =>
                FadeTransition(
              opacity: a,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.9, end: 1).animate(
                    CurvedAnimation(parent: a, curve: Curves.easeOutBack)),
                child: child,
              ),
            ),
            layoutBuilder: (Widget? current, List<Widget> previous) => Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[...previous, ?current],
            ),
            child: Padding(
              key: ValueKey<int>(phase),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                _quips(l)[phase],
                textAlign: TextAlign.center,
                maxLines: 2,
                style: AppType.title2.copyWith(color: c.textPrimary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l.phaseLabel(phase),
          style: AppType.footnote.copyWith(
            color: c.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Container(
          height: 24,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.ink, width: Chunky.border),
          ),
          child: Row(
            children: List<Widget>.generate(kPhaseCount, (int i) {
              final bool done = i <= phase;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: AnimatedContainer(
                    duration: Motion.base,
                    curve: Curves.easeOutBack,
                    decoration: BoxDecoration(
                      color: done ? c.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border:
                          done ? Border.all(color: c.ink, width: 1.4) : null,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.onRetry, this.onLocal});

  final String message;
  final VoidCallback onRetry;

  /// Offered when the server is out of reach: run the phone's model instead.
  final VoidCallback? onLocal;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    return Column(
      children: <Widget>[
        Text(
          l.analyzingFailedTitle,
          textAlign: TextAlign.center,
          style: AppType.title1.copyWith(color: c.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppType.subhead.copyWith(color: c.textSecondary, height: 1.42),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: l.tryAgain,
          icon: Icons.refresh_rounded,
          onTap: onRetry,
        ),
        if (onLocal != null) ...<Widget>[
          const SizedBox(height: 8),
          SecondaryButton(
            label: l.analyzingOnPhone,
            leading: const PhoneIcon(),
            onTap: onLocal,
          ),
        ],
      ],
    );
  }
}
