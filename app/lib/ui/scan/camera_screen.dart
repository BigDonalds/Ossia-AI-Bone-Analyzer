import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../core/util/haptics.dart';
import '../../data/analysis_engine.dart';
import '../../data/on_device/on_device_model.dart';
import '../../data/settings_controller.dart';
import '../../l10n/l10n.dart';
import '../widgets/bone_buddy.dart';
import '../widgets/primitives.dart';
import 'auto_snap_fx.dart';
import 'bone_guide.dart';
import 'bone_spotter.dart';
import 'review_screen.dart';

/// Opens the in-app camera on the root navigator, so it covers the tab bar.
Future<void> openBoneCamera(BuildContext context) =>
    Navigator.of(context, rootNavigator: true).push(_cameraRoute<void>(const CameraScreen()));

/// Opens the camera for one more angle of the bone under review and returns
/// the new photo, or photos when the user picks from the library instead.
/// [room] is how many more photos fit.
Future<List<File>?> captureAnotherAngle(BuildContext context,
        {required int angle, required int room}) =>
    Navigator.of(context, rootNavigator: true)
        .push(_cameraRoute<List<File>>(CameraScreen(angle: angle, room: room)));

PageRouteBuilder<T> _cameraRoute<T>(Widget screen) => PageRouteBuilder<T>(
      transitionDuration: Motion.base,
      reverseTransitionDuration: Motion.quick,
      pageBuilder: (_, _, _) => screen,
      transitionsBuilder: (_, Animation<double> a, _, Widget child) =>
          FadeTransition(
        opacity: a,
        child: ScaleTransition(
          scale: Tween<double>(begin: 1.06, end: 1)
              .animate(CurvedAnimation(parent: a, curve: Motion.standard)),
          child: child,
        ),
      ),
    );

/// Library photos for more angles of the same bone, at most [room] of them.
Future<List<File>> pickMoreAngles(int room) async {
  try {
    if (room <= 1) {
      final XFile? file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );
      return <File>[if (file != null) File(file.path)];
    }
    final List<XFile> files = await ImagePicker().pickMultiImage(
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
      limit: room,
    );
    return <File>[for (final XFile f in files.take(room)) File(f.path)];
  } catch (_) {
    return <File>[];
  }
}

/// Pick a photo from the library and go straight to review.
Future<void> pickBoneFromLibrary(BuildContext context, {bool replace = false}) async {
  final NavigatorState nav = Navigator.of(context, rootNavigator: true);
  try {
    final XFile? file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      // Large enough for the model's input with room to crop, small enough to
      // upload quickly over a field connection.
      maxWidth: 1600,
      maxHeight: 1600,
      imageQuality: 90,
    );
    if (file == null) return;
    final Route<void> route = MaterialPageRoute<void>(
      builder: (_) => ReviewScreen(images: <File>[File(file.path)]),
    );
    if (replace) {
      await nav.pushReplacement(route);
    } else {
      await nav.push(route);
    }
  } catch (_) {
    // Picker unavailable (permission denied, no gallery) — nothing to do but
    // stay put; the caller's screen is still usable.
  }
}

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, this.angle, this.room = kMaxPhotos});

  /// Set when adding another angle to a bone under review: the shot goes back
  /// to the review instead of opening a new one.
  final int? angle;

  /// How many more photos fit, for picking from the library in that mode.
  final int room;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

enum _CamStatus { starting, ready, denied, unavailable }

/// Where the auto snap is: watching for a bone, seen one while the phone
/// moves, counting down while it is still, taking the photo, or waiting for
/// the phone to move after coming back from one.
enum _Snap { looking, found, holding, firing, rearm }

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = <CameraDescription>[];
  int _cameraIndex = 0;
  _CamStatus _status = _CamStatus.starting;

  GuideShape _shape = GuideShape.longBone;
  FlashMode _flash = FlashMode.off;
  bool _capturing = false;

  double _zoom = 1;
  double _minZoom = 1;
  double _maxZoom = 1;
  double _zoomAtPinchStart = 1;

  Offset? _focusPoint;

  late final AnimationController _ants = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..value = 1;

  late final AnimationController _flashFx = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );

  late final AnimationController _focusFx = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  // ── Auto snap ──────────────────────────────────────────────────────────
  // The model checks recent preview frames for a bone while small grey
  // thumbnails tell a still phone from a moving one. A bone held still for
  // the length of [_hold] takes the photo.

  /// Picture change ([frameChange]) below which the phone counts as still,
  /// and above which a countdown already running is dropped. About 13 and 25
  /// pixels of drift between looks on a 1080p frame.
  static const double _steady = 4.5;
  static const double _shaky = 8;

  bool _auto = false;
  _Snap _snap = _Snap.looking;
  double _motion = 0;
  int _boneHits = 0;
  int _boneMisses = 0;
  bool _boneSeen = false;

  /// After a photo, the next one waits until the phone or bone has moved,
  /// so coming back to retake doesn't fire straight away.
  bool _needsMove = false;

  /// Shown in the tip bubble for a moment after the toggle: on or off.
  bool? _toggleTip;
  Timer? _toggleTipTimer;

  /// The guide box from the last layout, for the burst.
  Rect _guide = Rect.zero;
  List<SnapParticle> _pieces = const <SnapParticle>[];

  late final BoneSpotter _spotter;

  late final AnimationController _scan = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  late final AnimationController _seenFx = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    reverseDuration: Motion.base,
  );

  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..addStatusListener(_onHoldStatus);

  late final AnimationController _burst = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final OnDeviceModel model = context.read<OnDeviceModel>();
    _spotter = BoneSpotter(model, onMotion: _onMotion, onBone: _onBone);
    _auto = OnDeviceModel.supported && context.read<SettingsController>().autoSnap;
    if (_auto) unawaited(model.ensureLoaded().catchError((Object _) {}));
    _start();
  }

  /// True while a start is in flight. The permission prompt backgrounds the
  /// app mid-start, and resuming must not kick off a second, racing start.
  bool _starting = false;

  Future<void> _start() async {
    if (_starting) return;
    _starting = true;
    setState(() => _status = _CamStatus.starting);
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
        final int back = _cameras.indexWhere(
            (CameraDescription c) => c.lensDirection == CameraLensDirection.back);
        _cameraIndex = back < 0 ? 0 : back;
      }
      if (_cameras.isEmpty) {
        if (mounted) setState(() => _status = _CamStatus.unavailable);
        return;
      }
      await _bind(_cameras[_cameraIndex]);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() => _status = e.code.contains('Denied') || e.code.contains('denied')
          ? _CamStatus.denied
          : _CamStatus.unavailable);
    } catch (_) {
      if (mounted) setState(() => _status = _CamStatus.unavailable);
    } finally {
      _starting = false;
    }
  }

  Future<void> _bind(CameraDescription description) async {
    final CameraController? old = _controller;
    _controller = null;
    _spotter.forget();
    await old?.dispose();

    final CameraController next = CameraController(
      description,
      ResolutionPreset.veryHigh,
      enableAudio: false,
      // The format the auto snap reads preview frames in; photos are JPEG
      // either way.
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    await next.initialize();
    if (!mounted) {
      await next.dispose();
      return;
    }
    try {
      await next.lockCaptureOrientation(DeviceOrientation.portraitUp);
    } catch (_) {}
    try {
      await next.setFlashMode(_flash);
    } catch (_) {}
    double minZ = 1;
    double maxZ = 1;
    try {
      minZ = await next.getMinZoomLevel();
      maxZ = await next.getMaxZoomLevel();
    } catch (_) {}

    setState(() {
      _controller = next;
      _minZoom = minZ;
      _maxZoom = maxZ.clamp(minZ, 8.0);
      _zoom = minZ;
      _status = _CamStatus.ready;
    });
    _resetSnap();
    _startSpotter();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? c = _controller;
    if (state == AppLifecycleState.inactive) {
      if (c == null || !c.value.isInitialized) return;
      _controller = null;
      _spotter.forget();
      c.dispose();
      if (mounted) setState(() => _status = _CamStatus.starting);
    } else if (state == AppLifecycleState.resumed &&
        _controller == null &&
        !_starting) {
      _start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _spotter.forget();
    _controller?.dispose();
    _toggleTipTimer?.cancel();
    _ants.dispose();
    _pop.dispose();
    _flashFx.dispose();
    _focusFx.dispose();
    _scan.dispose();
    _seenFx.dispose();
    _hold.dispose();
    _burst.dispose();
    super.dispose();
  }

  void _pickShape(GuideShape s) {
    if (s == _shape) return;
    Haptics.tap();
    setState(() => _shape = s);
    _pop.forward(from: 0);
  }

  Future<void> _cycleFlash() async {
    const List<FlashMode> order = <FlashMode>[
      FlashMode.off,
      FlashMode.auto,
      FlashMode.always,
    ];
    final FlashMode next = order[(order.indexOf(_flash) + 1) % order.length];
    setState(() => _flash = next);
    try {
      await _controller?.setFlashMode(next);
    } catch (_) {}
  }

  Future<void> _flip() async {
    if (_cameras.length < 2 || _capturing) return;
    Haptics.light();
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    setState(() => _status = _CamStatus.starting);
    try {
      await _bind(_cameras[_cameraIndex]);
    } catch (_) {
      if (mounted) setState(() => _status = _CamStatus.unavailable);
    }
  }

  Future<void> _focusAt(TapUpDetails d, Size area) async {
    final CameraController? c = _controller;
    if (c == null || !c.value.isInitialized) return;
    setState(() => _focusPoint = d.localPosition);
    _focusFx.forward(from: 0);
    final Offset p = Offset(
      (d.localPosition.dx / area.width).clamp(0.0, 1.0),
      (d.localPosition.dy / area.height).clamp(0.0, 1.0),
    );
    try {
      await c.setFocusPoint(p);
      await c.setExposurePoint(p);
    } catch (_) {
      // Fixed-focus lens; the ring still acknowledges the tap.
    }
  }

  Future<void> _setZoom(double z) async {
    final double clamped = z.clamp(_minZoom, _maxZoom);
    if ((clamped - _zoom).abs() < 0.01) return;
    setState(() => _zoom = clamped);
    try {
      await _controller?.setZoomLevel(clamped);
    } catch (_) {}
  }

  void _toggleAuto() {
    final bool on = !_auto;
    Haptics.tap();
    context.read<SettingsController>().setAutoSnap(on);
    _toggleTipTimer?.cancel();
    _toggleTipTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => _toggleTip = null);
    });
    setState(() {
      _auto = on;
      _toggleTip = on;
    });
    _resetSnap();
    if (on) {
      unawaited(context.read<OnDeviceModel>().ensureLoaded().catchError((Object _) {}));
      _startSpotter();
    } else {
      unawaited(_spotter.stop());
    }
  }

  void _startSpotter() {
    final CameraController? c = _controller;
    if (!_auto || c == null || !c.value.isInitialized || _status != _CamStatus.ready) {
      return;
    }
    unawaited(_spotter.start(c));
  }

  /// Back to watching from scratch; [needsMove] after a photo.
  void _resetSnap({bool needsMove = false}) {
    _snap = needsMove ? _Snap.rearm : _Snap.looking;
    _needsMove = needsMove;
    _boneSeen = false;
    _boneHits = 0;
    _boneMisses = 0;
    _motion = 0;
    _hold.value = 0;
    _seenFx.value = 0;
    if (mounted) setState(() {});
  }

  void _onMotion(double change) {
    _motion = _motion * 0.5 + change * 0.5;
    if (_needsMove && _motion > _shaky) _needsMove = false;
    _updateSnap();
  }

  void _onBone(double p) {
    if (p > 0.5) {
      _boneHits++;
      _boneMisses = 0;
    } else {
      _boneMisses++;
      _boneHits = 0;
    }
    // One very sure look or two in a row to see a bone; two misses in a row
    // to lose it, so a single odd frame changes nothing.
    if (!_boneSeen && (p >= 0.85 || _boneHits >= 2)) {
      _boneSeen = true;
    } else if (_boneMisses >= 2) {
      _boneSeen = false;
      _needsMove = false;
    }
    _updateSnap();
  }

  void _updateSnap() {
    if (!mounted ||
        !_auto ||
        _capturing ||
        _snap == _Snap.firing ||
        _status != _CamStatus.ready) {
      return;
    }
    final _Snap next = _needsMove
        ? _Snap.rearm
        : !_boneSeen
            ? _Snap.looking
            : _motion < (_snap == _Snap.holding ? _shaky : _steady)
                ? _Snap.holding
                : _Snap.found;
    if (next == _snap) return;
    final _Snap was = _snap;
    setState(() => _snap = next);
    switch (next) {
      case _Snap.found:
      case _Snap.holding:
        if (was == _Snap.looking || was == _Snap.rearm) Haptics.light();
        _seenFx.forward();
        if (next == _Snap.holding) {
          _hold.forward();
        } else {
          _hold.animateBack(0, duration: Motion.quick);
        }
      case _Snap.looking:
      case _Snap.rearm:
        _seenFx.reverse();
        _hold.animateBack(0, duration: Motion.quick);
      case _Snap.firing:
        break;
    }
  }

  void _onHoldStatus(AnimationStatus status) {
    // Not while the camera is being swapped or paused: the spotter is off then.
    if (status != AnimationStatus.completed ||
        _snap != _Snap.holding ||
        _capturing ||
        !_spotter.running) {
      return;
    }
    _pieces = snapParticles(DateTime.now().microsecondsSinceEpoch);
    setState(() => _snap = _Snap.firing);
    _burst.forward(from: 0);
    _shoot(auto: true);
  }

  Future<void> _shoot({bool auto = false}) async {
    final CameraController? c = _controller;
    if (c == null || !c.value.isInitialized || _capturing || c.value.isTakingPicture) {
      if (auto) _resetSnap();
      return;
    }
    setState(() => _capturing = true);
    if (auto) {
      Haptics.success();
    } else {
      Haptics.medium();
      _flashFx.forward(from: 0);
      _hold.stop();
    }
    // Give the burst a moment on screen before the review covers it.
    final Future<void> show = auto
        ? Future<void>.delayed(const Duration(milliseconds: 650))
        : Future<void>.value();
    bool leaving = false;
    bool shot = false;
    try {
      await _spotter.stop();
      final XFile file = await c.takePicture();
      shot = true;
      await show;
      if (!mounted) return;
      if (widget.angle != null) {
        leaving = true;
        Navigator.of(context).pop(<File>[File(file.path)]);
        return;
      }
      try {
        await c.pausePreview();
      } catch (_) {}
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ReviewScreen(images: <File>[File(file.path)], fromCamera: true),
        ),
      );
      // Back from review means "retake".
      if (!mounted) return;
      try {
        await _controller?.resumePreview();
      } catch (_) {}
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.camShotFailed)),
        );
      }
    } finally {
      if (mounted && !leaving) {
        setState(() => _capturing = false);
        _resetSnap(needsMove: shot);
        _startSpotter();
      }
    }
  }

  Future<void> _openLibrary() async {
    await _spotter.stop();
    _resetSnap();
    try {
      await _controller?.pausePreview();
    } catch (_) {}
    if (!mounted) return;
    if (widget.angle != null) {
      final List<File> picked = await pickMoreAngles(widget.room);
      if (!mounted) return;
      if (picked.isNotEmpty) {
        Navigator.of(context).pop(picked);
        return;
      }
    } else {
      await pickBoneFromLibrary(context);
    }
    try {
      await _controller?.resumePreview();
    } catch (_) {}
    if (mounted) _startSpotter();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final EdgeInsets safe = MediaQuery.paddingOf(context);
    // The auto snap shows only while it can actually work.
    final bool autoLive = _auto &&
        _status == _CamStatus.ready &&
        context.select<OnDeviceModel, OnDeviceStatus>((OnDeviceModel m) => m.status) !=
            OnDeviceStatus.failed;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.black,
      ),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            _preview(),

            // Guide overlay. The scrim spans the whole screen; the guide box
            // sits in the band between the top and bottom controls.
            Positioned.fill(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints box) {
                  final Size screen = box.biggest;
                  final Rect band = Rect.fromLTRB(
                    0,
                    safe.top + 116,
                    screen.width,
                    screen.height - safe.bottom - 214,
                  );
                  final Rect guide = _guideRect(band);
                  _guide = guide;
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (TapUpDetails d) => _focusAt(d, screen),
                    onScaleStart: (_) => _zoomAtPinchStart = _zoom,
                    onScaleUpdate: (ScaleUpdateDetails d) {
                      if (d.pointerCount > 1) _setZoom(_zoomAtPinchStart * d.scale);
                    },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: Listenable.merge(<Listenable>[_ants, _pop]),
                            builder: (BuildContext context, _) => CustomPaint(
                              painter: BoneGuidePainter(
                                shape: _shape,
                                box: guide,
                                phase: _ants.value,
                                accent: c.accent,
                                pop: _pop.value,
                              ),
                            ),
                          ),
                        ),
                        if (autoLive)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation:
                                    Listenable.merge(<Listenable>[_scan, _seenFx, _hold]),
                                builder: (BuildContext context, _) => CustomPaint(
                                  painter: AutoSnapPainter(
                                    box: guide,
                                    scan: _scan.value,
                                    sweep: _snap == _Snap.rearm || _snap == _Snap.firing
                                        ? 0
                                        : 1 - _seenFx.value,
                                    seen: _seenFx.value,
                                    hold: _hold.value,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (_focusPoint != null) _focusRing(_focusPoint!),
                        if (autoLive)
                          Positioned(
                            top: guide.top - 16,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: Center(
                                child: SpottedBadge(
                                  show: _seenFx,
                                  label: context.l10n.camAutoSpotted,
                                ),
                              ),
                            ),
                          ),
                        // Distance cue, pinned under the guide.
                        Positioned(
                          left: 0,
                          right: 0,
                          top: guide.bottom + 12,
                          child: Center(child: _distanceChip(c)),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Top: close, title sticker, auto snap and flash.
            Positioned(
              top: safe.top + 8,
              left: 14,
              right: 14,
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 96,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: RoundButton(
                        icon: Icons.close_rounded,
                        tooltip: context.l10n.camClose,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Transform.rotate(
                          angle: -0.04,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 7),
                            decoration: BoxDecoration(
                              color: c.accent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF141414), width: 2),
                            ),
                            child: Text(
                              widget.angle == null
                                  ? context.l10n.camTitle
                                  : context.l10n.camAngle(widget.angle!),
                              style: AppType.button.copyWith(
                                color: c.onAccent,
                                fontSize: 14,
                                letterSpacing: AppType.tracking(1.2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 96,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        if (OnDeviceModel.supported) ...<Widget>[
                          RoundButton(
                            icon: Icons.motion_photos_auto_rounded,
                            color: _auto ? c.accent : null,
                            iconColor: _auto ? c.onAccent : null,
                            tooltip: context.l10n.camAuto,
                            onTap: _toggleAuto,
                          ),
                          const SizedBox(width: 8),
                        ],
                        RoundButton(
                          icon: switch (_flash) {
                            FlashMode.auto => Icons.flash_auto_rounded,
                            FlashMode.always => Icons.flash_on_rounded,
                            _ => Icons.flash_off_rounded,
                          },
                          color: _flash == FlashMode.off ? null : c.accent,
                          iconColor: _flash == FlashMode.off ? null : c.onAccent,
                          tooltip: context.l10n.camFlash,
                          onTap: _status == _CamStatus.ready ? _cycleFlash : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Shape picker.
            Positioned(
              top: safe.top + 64,
              left: 0,
              right: 0,
              height: 48,
              child: _ShapePicker(value: _shape, onChanged: _pickShape),
            ),

            // Bottom: mascot tip, zoom, controls.
            Positioned(
              left: 0,
              right: 0,
              bottom: safe.bottom + 12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _status == _CamStatus.denied || _status == _CamStatus.unavailable
                      ? _problemCard(c)
                      : _tipRow(autoLive),
                  const SizedBox(height: 16),
                  _controls(c, autoLive),
                ],
              ),
            ),

            // Shutter flash.
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _flashFx,
                builder: (BuildContext context, _) => Container(
                  color: Colors.white.withValues(
                    alpha: _flashFx.isAnimating
                        ? (1 - Curves.easeOut.transform(_flashFx.value)) * 0.85
                        : 0,
                  ),
                ),
              ),
            ),

            // The auto snap's burst and stamp.
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _burst,
                builder: (BuildContext context, _) {
                  if (!_burst.isAnimating) return const SizedBox.shrink();
                  return Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      CustomPaint(
                        painter: SnapBurstPainter(
                          t: _burst.value,
                          box: _guide,
                          pieces: _pieces,
                        ),
                      ),
                      Positioned.fromRect(
                        rect: _guide,
                        child: Center(
                          child: SnapStamp(
                            t: _burst.value,
                            label: context.l10n.camAutoSnapped,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Largest box of the current shape's aspect that fits [band], leaving room
  /// underneath for the distance chip.
  Rect _guideRect(Rect band) {
    final double maxW = band.width * 0.78;
    final double maxH = (band.height - 44) * 0.94;
    double w = maxW;
    double h = w / _shape.aspect;
    if (h > maxH) {
      h = maxH;
      w = h * _shape.aspect;
    }
    return Rect.fromCenter(
      center: Offset(band.center.dx, band.top + (band.height - 44) / 2),
      width: w,
      height: h,
    );
  }

  Widget _preview() {
    final CameraController? ctrl = _controller;
    if (ctrl == null || !ctrl.value.isInitialized) {
      // Placeholder "table top" so the overlay still reads while starting.
      return const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.2),
            radius: 1.1,
            colors: <Color>[Color(0xFF2C2940), Color(0xFF0C0B12)],
          ),
        ),
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        // The sensor reports a landscape aspect; in portrait the preview is its
        // inverse. Cover the screen and crop the overflow.
        final double sensor = ctrl.value.aspectRatio;
        return ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: box.maxWidth,
              height: box.maxWidth * sensor,
              child: CameraPreview(ctrl),
            ),
          ),
        );
      },
    );
  }

  Widget _focusRing(Offset at) {
    return Positioned(
      left: at.dx - 36,
      top: at.dy - 36,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _focusFx,
          builder: (BuildContext context, _) {
            final double t = _focusFx.value;
            return Opacity(
              opacity: t < 0.7 ? 1 : (1 - (t - 0.7) / 0.3),
              child: Transform.scale(
                scale: 1.4 - 0.4 * Curves.easeOutBack.transform(t.clamp(0, 1)),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colors.accent, width: 3.5),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _distanceChip(AppColors c) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 12, 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: const Color(0xFF141414), width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0xFF141414), offset: Offset(2, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.straighten_rounded, size: 16, color: Color(0xFF141414)),
          const SizedBox(width: 6),
          Text(
            context.l10n.camHold(_shape.distanceCm),
            style: AppType.caption.copyWith(
              color: const Color(0xFF141414),
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tipRow(bool autoLive) {
    final AppLocalizations l = context.l10n;
    final String usual = widget.angle != null ? l.camAnotherAngleTip : _shape.tip(l);
    final bool locked = autoLive &&
        (_snap == _Snap.found || _snap == _Snap.holding || _snap == _Snap.firing);
    final (String text, BuddyMood mood) = _status == _CamStatus.starting
        ? (l.camWarmingUp, BuddyMood.thinking)
        : _toggleTip != null
            ? (_toggleTip! ? l.camAutoOnTip : l.camAutoOffTip, BuddyMood.happy)
            : !autoLive
                ? (usual, BuddyMood.happy)
                : switch (_snap) {
                    _Snap.found => (l.camAutoFound, BuddyMood.wow),
                    _Snap.holding => (l.camAutoHolding, BuddyMood.wink),
                    _Snap.firing => (l.camAutoHolding, BuddyMood.wow),
                    _Snap.rearm => (l.camAutoRearm, BuddyMood.happy),
                    _Snap.looking => (usual, BuddyMood.happy),
                  };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          BoneBuddy(
            size: 72,
            mood: mood,
            look: const Offset(0.7, -0.3),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: SpeechBubble(
              color: locked ? kLockGreen : null,
              child: AnimatedSwitcher(
                duration: Motion.quick,
                child: Text(
                  text,
                  key: ValueKey<String>(text),
                  style: AppType.footnote.copyWith(
                    color: locked ? const Color(0xFF141414) : context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _problemCard(AppColors c) {
    final bool denied = _status == _CamStatus.denied;
    final AppLocalizations l = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Chunk(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 12, 12),
        child: Row(
          children: <Widget>[
            const BoneBuddy(size: 64, mood: BuddyMood.sad, animate: false),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    denied ? l.camNoAccess : l.camNapping,
                    style: AppType.headline.copyWith(color: c.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    denied ? l.camNoAccessBody : l.camNappingBody,
                    style: AppType.caption.copyWith(color: c.textSecondary, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            RoundButton(
              icon: Icons.refresh_rounded,
              size: 40,
              tooltip: l.tryAgain,
              onTap: _start,
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls(AppColors c, bool autoLive) {
    final bool ready = _status == _CamStatus.ready;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: <Widget>[
          RoundButton(
            icon: Icons.photo_library_rounded,
            size: 56,
            tooltip: context.l10n.camUploadFromLibrary,
            onTap: _openLibrary,
          ),
          Expanded(
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  _Shutter(
                    enabled: ready && !_capturing,
                    busy: _capturing,
                    onTap: _shoot,
                  ),
                  if (autoLive)
                    Positioned(
                      left: -11,
                      top: -11,
                      right: -11,
                      bottom: -11,
                      child: IgnorePointer(
                        child: AnimatedBuilder(
                          animation: Listenable.merge(<Listenable>[_scan, _hold]),
                          builder: (BuildContext context, _) => CustomPaint(
                            painter: ShutterRingPainter(
                              spin: _scan.value,
                              hold: _hold.value,
                              armed: switch (_snap) {
                                _Snap.rearm => 0.35,
                                _Snap.firing => 0,
                                _ => (1 - _hold.value * 1.5).clamp(0.0, 1.0),
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (_maxZoom > _minZoom + 0.1 && ready)
            RoundButton(
              icon: Icons.zoom_in_rounded,
              size: 56,
              tooltip: context.l10n.camZoom,
              color: _zoom > _minZoom + 0.05 ? c.accent : null,
              iconColor: _zoom > _minZoom + 0.05 ? c.onAccent : null,
              onTap: () => _setZoom(_zoom < 1.9 ? 2.0 : _minZoom),
            )
          else
            RoundButton(
              icon: Icons.cameraswitch_rounded,
              size: 56,
              tooltip: context.l10n.camSwitch,
              onTap: _cameras.length > 1 && ready ? _flip : null,
            ),
        ],
      ),
    );
  }
}

class _ShapePicker extends StatelessWidget {
  const _ShapePicker({required this.value, required this.onChanged});

  final GuideShape value;
  final ValueChanged<GuideShape> onChanged;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      physics: const BouncingScrollPhysics(),
      children: GuideShape.values.map((GuideShape s) {
        final bool active = s == value;
        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: Center(
            child: Pressable(
              scale: 0.92,
              haptic: false,
              onTap: () => onChanged(s),
              child: AnimatedContainer(
                duration: Motion.quick,
                curve: Curves.easeOutBack,
                padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 13, 6),
                decoration: BoxDecoration(
                  color: active ? c.accent : Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0xFF141414), width: 2),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: const Color(0xFF141414),
                      offset: active ? const Offset(2.5, 2.5) : Offset.zero,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    GuideGlyph(shape: s, color: const Color(0xFF141414), size: 20),
                    const SizedBox(width: 6),
                    Text(
                      s.label(context.l10n),
                      style: AppType.footnote.copyWith(
                        color: const Color(0xFF141414),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Big chunky shutter: white ring, accent button inside that squishes.
class _Shutter extends StatefulWidget {
  const _Shutter({required this.enabled, required this.busy, required this.onTap});

  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  @override
  State<_Shutter> createState() => _ShutterState();
}

class _ShutterState extends State<_Shutter> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Semantics(
      button: true,
      label: context.l10n.camTakePhoto,
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: widget.enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: () => setState(() => _down = false),
        onTap: widget.enabled ? widget.onTap : null,
        child: Container(
          width: 92,
          height: 92,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: const Color(0xFF141414), width: 2.5),
          ),
          child: AnimatedScale(
            scale: _down ? 0.84 : 1,
            duration: Motion.micro,
            curve: Curves.easeOutBack,
            child: AnimatedContainer(
              duration: Motion.quick,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.enabled || widget.busy
                    ? c.accent
                    : c.accent.withValues(alpha: 0.4),
                border: Border.all(color: const Color(0xFF141414), width: 2.5),
              ),
              child: Center(
                child: widget.busy
                    ? const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFF141414),
                        ),
                      )
                    : const Icon(Icons.camera_alt_rounded,
                        size: 32, color: Color(0xFF141414)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
