import 'dart:async';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/gym_themes.dart';
import '../theme/study_widgets.dart';
import 'menu_screen.dart';

/// SINGLE launch splash, two moments:
/// 1. Company moment — the official WAJIHA logo (copied unchanged), fading
///    in and out.
/// 2. Game splash — game logo + name + animated loading line + the
///    "Credits: WAJIHA" line with the company logo.
class SplashScreen extends StatefulWidget {
  final BrainAudio audio;
  final GymSettings settings;
  final StoreService store;
  const SplashScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _loader;
  late final AnimationController _companyFade;
  bool _companyMoment = true;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _companyFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio while the splash shows, then start menu music.
    unawaited(widget.audio.prewarm());
    unawaited(widget.audio.startMenuMusic());
    // Company moment: hold the logo, then fade it out…
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    await _companyFade.reverse();
    if (!mounted) return;
    // …and reveal the game splash.
    setState(() => _companyMoment = false);
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: widget.store,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    _companyFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = GymThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    return Scaffold(
      backgroundColor: theme.woodDeep,
      body: _companyMoment ? _company(theme) : _game(theme),
    );
  }

  /// Moment 1: the official WAJIHA company logo, shown unchanged.
  Widget _company(GymThemeDef theme) {
    return FadeTransition(
      opacity: _companyFade,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/wajiha_logo.png',
              width: 130,
              height: 130,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 18),
            Text('WAJIHA', style: Study.label(22, theme: theme)),
          ],
        ),
      ),
    );
  }

  /// Moment 2: game splash — logo, name, animated loading line, credits.
  Widget _game(GymThemeDef theme) {
    return WoodBackdrop(
      theme: theme,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: theme.accent, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    offset: const Offset(0, 10),
                    blurRadius: 24,
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/braingym_logo.png',
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 22),
            Text('Brain Gym', style: Study.display(52, theme: theme)),
            const SizedBox(height: 6),
            Text(
              'TRAIN YOUR MIND',
              style: Study.label(13, theme: theme),
            ),
            const SizedBox(height: 30),
            // Animated loading line.
            SizedBox(
              width: 220,
              child: AnimatedBuilder(
                animation: _loader,
                builder: (_, _) => Column(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: Colors.black.withValues(alpha: 0.45),
                        border: Border.all(
                          color: theme.accent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _loader.value.clamp(0.02, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(3),
                            gradient: LinearGradient(
                              colors: [
                                theme.accentLight,
                                theme.accent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _loader.value < 1
                          ? 'Sharpening pencils…'
                          : 'Ready!',
                      style: Study.body(
                        13,
                        theme: theme,
                        color: theme.ink.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 44),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/wajiha_logo.png',
                  width: 30,
                  height: 30,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Text(
                  'Credits: WAJIHA',
                  style: Study.label(14, theme: theme),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
