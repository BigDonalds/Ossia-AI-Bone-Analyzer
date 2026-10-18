import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/motion.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/typography.dart';
import '../../core/util/haptics.dart';
import '../../data/settings_controller.dart';
import '../../l10n/l10n.dart';
import '../widgets/bone_buddy.dart';
import '../widgets/primitives.dart';
import 'language_picker.dart';

/// First launch: which language should Ossia speak?
///
/// The phone's language is picked already when the app speaks it. Tapping a
/// card switches the whole screen into that language on the spot, so the
/// person sees what they're getting, but nothing is saved until "Let's go".
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  /// The phone's language, when the app speaks it.
  final String? _phone = phoneMatch();

  /// Until a card is tapped the buddy says hello in every language in turn;
  /// after that it greets in the picked one.
  Timer? _cycle;
  int _hello = 0;
  bool _picked = false;

  Timer? _settle;
  BuddyMood _mood = BuddyMood.happy;

  /// Bumped on every pick, to make the floating letters hop.
  int _hops = 0;

  @override
  void initState() {
    super.initState();
    _cycle = Timer.periodic(const Duration(milliseconds: 1600), (_) {
      if (mounted) setState(() => _hello = (_hello + 1) % kLanguages.length);
    });
  }

  @override
  void dispose() {
    _cycle?.cancel();
    _settle?.cancel();
    super.dispose();
  }

  void _pick(String code) {
    _cycle?.cancel();
    _settle?.cancel();
    setState(() {
      _picked = true;
      _mood = BuddyMood.wow;
      _hops++;
    });
    _settle = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _mood = BuddyMood.happy);
    });
    context.read<SettingsController>().previewLocale(code);
  }

  void _go(String code) {
    Haptics.success();
    // Picking the phone's own language means "follow the phone", so the app
    // keeps up if the phone's language changes later. Any other pick sticks.
    context
        .read<SettingsController>()
        .setLocale(code == _phone ? SettingsController.followPhone : code);
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final AppLocalizations l = context.l10n;
    final String selected = context.watch<SettingsController>().localeCode;
    final AppLanguage greeting = _picked ? languageFor(selected) : kLanguages[_hello];
    const List<double> tilts = <double>[-1.4, 1.1, -0.7];

    return Scaffold(
      backgroundColor: c.canvas,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                // The cards' hard shadow sits on their right in every
                // language, so the right edge is 4 short to look even.
                padding: const EdgeInsets.fromLTRB(20, 4, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    _Stage(greeting: greeting, mood: _mood, hops: _hops),
                    const SizedBox(height: 6),
                    _Swap(
                      code: selected,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            l.welcomeTitle,
                            style: AppType.title1.copyWith(color: c.textPrimary),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _phone == null ? l.welcomeSubtitleNoMatch : l.welcomeSubtitle,
                            style: AppType.subhead.copyWith(color: c.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    for (int i = 0; i < kLanguages.length; i++)
                      Reveal(
                        delay: Motion.stagger * (i + 3),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _card(kLanguages[i], selected, tilts[i % tilts.length]),
                        ),
                      ),
                    const Spacer(),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: l.welcomeContinue,
                      icon: Icons.arrow_forward_rounded,
                      onTap: () => _go(selected),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(AppLanguage language, String selected, double tilt) {
    // Each card speaks its own language, whatever the screen is in, so anyone
    // can find theirs.
    final AppLocalizations own = lookupAppLocalizations(language.locale);
    return LanguageChoice(
      big: true,
      leading: LanguageBadge(language: language, size: 50),
      language: language,
      title: language.nativeName,
      subtitle: own.languageCardLine,
      tag: language.code == _phone ? own.languageFromPhone : null,
      selected: selected == language.code,
      tilt: tilt,
      onTap: () => _pick(language.code),
    );
  }
}

/// Cross-fades its child whenever the language changes, so a switch reads as
/// the words turning over rather than jumping.
class _Swap extends StatelessWidget {
  const _Swap({required this.code, required this.child});

  final String code;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Motion.base,
      switchInCurve: Motion.emphasized,
      switchOutCurve: Motion.exit,
      layoutBuilder: (Widget? current, List<Widget> previous) => Stack(
        alignment: AlignmentDirectional.topStart,
        children: <Widget>[...previous, ?current],
      ),
      transitionBuilder: (Widget child, Animation<double> a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(a),
          child: child,
        ),
      ),
      child: KeyedSubtree(key: ValueKey<String>(code), child: child),
    );
  }
}

/// The top of the welcome screen: the buddy saying hello, with letters from
/// all three languages floating round it.
class _Stage extends StatelessWidget {
  const _Stage({required this.greeting, required this.mood, required this.hops});

  final AppLanguage greeting;
  final BuddyMood mood;
  final int hops;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return SizedBox(
      height: 214,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(child: _FloatingLetters(hops: hops)),
          Align(
            alignment: const Alignment(0, 0.08),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                BoneBuddy(size: 124, mood: mood, look: const Offset(0.8, -0.2)),
                const SizedBox(width: 2),
                SpeechBubble(
                  child: AnimatedSize(
                    duration: Motion.quick,
                    curve: Motion.standard,
                    child: AnimatedSwitcher(
                      duration: Motion.quick,
                      switchInCurve: Curves.easeOutBack,
                      transitionBuilder: (Widget child, Animation<double> a) => FadeTransition(
                        opacity: a,
                        child: ScaleTransition(scale: a, child: child),
                      ),
                      child: Text(
                        greeting.hello,
                        key: ValueKey<String>(greeting.code),
                        textDirection: greeting.direction,
                        style: AppType.scaleFor(greeting.code).title2.copyWith(color: c.textPrimary),
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

/// Letter stickers from the three alphabets, bobbing gently. They hop when a
/// language is picked.
class _FloatingLetters extends StatefulWidget {
  const _FloatingLetters({required this.hops});

  final int hops;

  @override
  State<_FloatingLetters> createState() => _FloatingLettersState();
}

class _FloatingLettersState extends State<_FloatingLetters> with TickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  late final AnimationController _hop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );

  // (letter, script, x, y, size, tilt in degrees, phase). Placed round the
  // edges, clear of the buddy and its bubble in the middle band.
  static const List<(String, String, double, double, double, double, double)> _letters =
      <(String, String, double, double, double, double, double)>[
    ('Aa', 'en', 0.03, 0.03, 46, -10, 0.0),
    ('ß', 'de', 0.40, 0.0, 38, 8, 0.35),
    ('ع', 'ar', 0.80, 0.06, 44, 12, 0.7),
    ('Ü', 'de', 0.06, 0.72, 40, 9, 0.5),
    ('ض', 'ar', 0.50, 0.80, 38, -8, 0.15),
    ('Ä', 'de', 0.86, 0.72, 40, -12, 0.85),
  ];

  @override
  void didUpdateWidget(_FloatingLetters old) {
    super.didUpdateWidget(old);
    if (widget.hops != old.hops) _hop.forward(from: 0);
  }

  @override
  void dispose() {
    _float.dispose();
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final bool still = MediaQuery.disableAnimationsOf(context);
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) => AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_float, _hop]),
          builder: (BuildContext context, _) => Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              for (int i = 0; i < _letters.length; i++) _letter(c, box, i, still),
            ],
          ),
        ),
      ),
    );
  }

  Widget _letter(AppColors c, BoxConstraints box, int i, bool still) {
    final (String text, String script, double x, double y, double size, double tilt, double phase) =
        _letters[i];
    final double t = still ? 0 : _float.value;
    final double bob = math.sin((t + phase) * 2 * math.pi) * 5;
    final double sway = math.sin((t * 2 + phase) * 2 * math.pi) * 3;
    // One quick hop each, staggered across the letters.
    final double h = (_hop.value * 1.6 - i * 0.1).clamp(0.0, 1.0);
    final double hop = still ? 0 : -math.sin(h * math.pi) * 14;
    return Positioned(
      left: x * (box.maxWidth - size),
      top: y * (box.maxHeight - size),
      child: Transform.translate(
        offset: Offset(0, bob + hop),
        child: Transform.rotate(
          angle: (tilt + sway) * math.pi / 180,
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.sticker(i),
              borderRadius: BorderRadius.circular(size * 0.3),
              border: Border.all(color: c.ink, width: 1.8),
              boxShadow: <BoxShadow>[BoxShadow(color: c.shadow, offset: const Offset(2.5, 2.5))],
            ),
            child: Text(
              text,
              textDirection: languageFor(script).direction,
              style: AppType.scaleFor(script).title3.copyWith(
                    color: const Color(0xFF141414),
                    fontSize: size * (text.length > 1 ? 0.42 : 0.5),
                    height: 1,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
