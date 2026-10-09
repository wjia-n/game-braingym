import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/braingym_engine.dart';
import '../engine/workout_types.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/gym_themes.dart';
import '../theme/study_widgets.dart';

/// The workout arena: renders engine state, nothing else. All phases,
/// timers and transitions are owned by [BrainGymEngine]; every reveal,
/// tap and result is animated visibly — nothing pops in instantly.
class WorkoutScreen extends StatefulWidget {
  final BrainAudio audio;
  final GymSettings settings;
  final StoreService store;
  final WorkoutSetup setup;
  const WorkoutScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
    required this.setup,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen>
    with WidgetsBindingObserver {
  late final BrainGymEngine _engine;
  bool _reviewAsked = false;
  // True while the explicit pause menu is open: a lifecycle resume must NOT
  // auto-unpause then — only the player pressing Resume may do that.
  bool _pauseDialogOpen = false;

  GymThemeDef get _t => GymThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _engine = BrainGymEngine(settings: widget.settings);
    _engine.onEvent = _onEvent;
    _engine.start(widget.setup);
  }

  void _onEvent(GymEvent e) {
    final a = widget.audio;
    switch (e) {
      case GymEvent.click:
        a.click();
      case GymEvent.flip:
        a.flip();
      case GymEvent.reveal:
        a.reveal();
      case GymEvent.correct:
        a.correct();
      case GymEvent.wrong:
        a.wrong();
      case GymEvent.tick:
        a.tick();
      case GymEvent.go:
        a.go();
      case GymEvent.falseStart:
        a.falseStart();
      case GymEvent.stroopTimeout:
        a.wrong();
      case GymEvent.gameStart:
        a.gameStart();
        a.startGameMusic();
      case GymEvent.miniDone:
        a.miniDone();
      case GymEvent.win:
        a.win();
      case GymEvent.newBest:
        a.newBest();
      case GymEvent.invalid:
        a.invalid();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Freeze the engine when the app backgrounds so timers can't desync.
    // Unfreeze on return ONLY when the lifecycle itself froze it: if the
    // explicit pause menu is open, only its Resume button may unpause.
    // Without this, the workout would stay frozen forever after a
    // background/resume — a stuck state the watchdog can't recover.
    if (state == AppLifecycleState.paused) {
      _engine.setPaused(true);
    } else if (state == AppLifecycleState.resumed && !_pauseDialogOpen) {
      _engine.setPaused(false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _engine.dispose();
    widget.audio.startMenuMusic();
    super.dispose();
  }

  Future<void> _pauseMenu() async {
    _engine.setPaused(true);
    await widget.audio.click();
    _pauseDialogOpen = true;
    final choice = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _t.woodMid,
        title: Text('Paused', style: Study.display(22, theme: _t)),
        content: Text(
          'Take a breath. Your workout is frozen.',
          style: Study.body(14, theme: _t),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('resume'),
            child: Text('Resume', style: Study.label(13, theme: _t)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('restart'),
            child: Text('Restart', style: Study.label(13, theme: _t)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop('quit'),
            child: Text('Quit', style: Study.label(13, theme: _t)),
          ),
        ],
      ),
    );
    _pauseDialogOpen = false;
    if (!mounted) return;
    if (choice == 'restart') {
      await widget.audio.click();
      _engine.restart();
    } else if (choice == 'quit') {
      Navigator.of(context).pop();
    } else {
      _engine.setPaused(false);
    }
  }

  Future<void> _shareScore() async {
    widget.audio.click();
    final name = widget.settings.playerName;
    await Share.share(
      '$name scored ${_engine.total} in Brain Gym! 🧠💪\n'
      'Can you beat it?\n'
      'https://play.google.com/store/apps/details?id=com.gameswajiha.braingym',
    );
  }

  Future<void> _maybeAskReview() async {
    if (_reviewAsked) return;
    _reviewAsked = true;
    // Sensible moment: right after a finished workout, only occasionally,
    // and never crash when not installed from Play.
    if (widget.settings.gamesPlayed < 2) return;
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await Future.delayed(const Duration(milliseconds: 600));
        await review.requestReview();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return WoodBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _engine,
            builder: (_, _) {
              if (_engine.phase == Phase.workoutDone) {
                _maybeAskReview();
              }
              return Column(
                children: [
                  _header(t),
                  _progressBar(t),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: Text(
                      _engine.banner,
                      textAlign: TextAlign.center,
                      style: Study.body(15, theme: t).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(child: _body(t)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _header(GymThemeDef t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.pause, color: t.accentLight),
            tooltip: 'Pause',
            onPressed: _engine.over ? null : _pauseMenu,
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < _engine.setup!.minis.length; i++)
                  _miniDot(t, _engine.setup!.minis[i], i),
              ],
            ),
          ),
          const SizedBox(width: 40), // balance the pause button
        ],
      ),
    );
  }

  Widget _miniDot(GymThemeDef t, MiniGame m, int i) {
    final done = i < _engine.miniIndex;
    final current = i == _engine.miniIndex && !_engine.over;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done
            ? t.accent.withValues(alpha: 0.85)
            : Colors.black.withValues(alpha: 0.4),
        border: Border.all(
          color: current ? t.accentLight : t.accent.withValues(alpha: 0.4),
          width: current ? 2.5 : 1.5,
        ),
      ),
      child: Center(
        child: Text(
          done ? '✓' : m.emoji,
          style: TextStyle(
            fontSize: 20,
            color: done ? t.woodDeep : null,
            fontWeight: done ? FontWeight.w900 : null,
          ),
        ),
      ),
    );
  }

  Widget _progressBar(GymThemeDef t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          _scoreChip(t, '🔢', _engine.memScore),
          const SizedBox(width: 6),
          _scoreChip(t, '⚡', _engine.reactScore),
          const SizedBox(width: 6),
          _scoreChip(t, '🎨', _engine.stroopScore),
          const Spacer(),
          Text(
            'Σ ${_engine.total}',
            style: Study.display(17, theme: t),
          ),
        ],
      ),
    );
  }

  Widget _scoreChip(GymThemeDef t, String emoji, int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black.withValues(alpha: 0.4),
        border: Border.all(color: t.accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        '$emoji $score',
        style: Study.label(12, theme: t),
      ),
    );
  }

  Widget _body(GymThemeDef t) {
    switch (_engine.phase) {
      case Phase.idle:
      case Phase.countdown:
        return _countdown(t);
      case Phase.memoryShow:
      case Phase.memoryRecall:
      case Phase.memoryRoundEnd:
        return _memory(t);
      case Phase.reactionWait:
      case Phase.reactionGreen:
      case Phase.reactionRest:
        return _reaction(t);
      case Phase.stroopPrompt:
      case Phase.stroopResolve:
        return _stroop(t);
      case Phase.miniSummary:
        return _miniSummary(t);
      case Phase.workoutDone:
        return _workoutDone(t);
    }
  }

  // -------------------------------------------------------------- countdown
  Widget _countdown(GymThemeDef t) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _engine.currentMini.emoji,
            style: const TextStyle(fontSize: 54),
          ),
          const SizedBox(height: 8),
          Text(
            _engine.currentMini.title,
            style: Study.display(30, theme: t),
          ),
          const SizedBox(height: 6),
          Text(
            'Difficulty: ${_engine.difficultyName(_engine.currentMini)}',
            style: Study.label(13, theme: t),
          ),
          const SizedBox(height: 26),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: Tween<double>(begin: 1.6, end: 1.0).animate(
                CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              ),
              child: FadeTransition(opacity: anim, child: child),
            ),
            child: Text(
              _engine.countdownValue > 0
                  ? '${_engine.countdownValue}'
                  : 'GO!',
              key: ValueKey(_engine.countdownValue),
              style: Study.display(84, theme: t).copyWith(
                color: t.accentLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- memory
  Widget _memory(GymThemeDef t) {
    final style = TileStyles.byIndex(widget.settings.tileStyle);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        children: [
          Text(
            'Round ${_engine.memRound}/${_engine.memRounds}',
            style: Study.label(13, theme: t),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: t.felt.withValues(alpha: 0.85),
                border: Border.all(color: t.accent.withValues(alpha: 0.5), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    offset: const Offset(0, 6),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: 16,
                itemBuilder: (_, i) => _MemTile(
                  index: i,
                  state: _engine.memTileState(i),
                  token: _engine.tileToken,
                  style: style,
                  theme: t,
                  onTap: () => _engine.memTap(i),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------- reaction
  Widget _reaction(GymThemeDef t) {
    final green = _engine.phase == Phase.reactionGreen;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        children: [
          Text(
            'Round ${_engine.reactRound}/${_engine.reactRounds}',
            style: Study.label(13, theme: t),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _ReactionPad(
              green: green,
              pulseToken: _engine.reactPulseToken,
              theme: t,
              onTap: _engine.reactTap,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tapping early = +1500ms penalty!',
            style: Study.body(12, theme: t, color: t.muted),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------- stroop
  Widget _stroop(GymThemeDef t) {
    final resolving = _engine.phase == Phase.stroopResolve;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        children: [
          Text(
            'Round ${_engine.stroopRound}/${_engine.stroopRounds}',
            style: Study.label(13, theme: t),
          ),
          const SizedBox(height: 6),
          Expanded(
            flex: 2,
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: Tween<double>(begin: 0.7, end: 1.0).animate(
                    CurvedAnimation(
                        parent: anim, curve: Curves.easeOutBack),
                  ),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Container(
                  key: ValueKey(_engine.stroopId),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 26,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: t.paper,
                    border: Border.all(
                      color: resolving
                          ? (_engine.stroopLastOk
                              ? const Color(0xFF43A047)
                              : const Color(0xFFE53935))
                          : t.accent.withValues(alpha: 0.5),
                      width: resolving ? 4 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        offset: const Offset(0, 6),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Text(
                    _engine.stroopWord,
                    style: TextStyle(
                      color: _engine.stroopInk,
                      fontSize: 58,
                      fontWeight: FontWeight.w900,
                      fontFamily: Study.displayFont,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                for (final e in _engine.stroopChoices)
                  _StroopButton(
                    name: e.key,
                    color: e.value,
                    theme: t,
                    flash: resolving && e.key == _engine.stroopInkName,
                    token: _engine.stroopResolveToken,
                    onTap: () => _engine.stroopTap(e.key),
                  ),
              ],
            ),
          ),
          Text(
            '✅ ${_engine.stroopCorrect}   ❌ ${_engine.stroopWrong}',
            style: Study.body(16, theme: t)
                .copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------ mini summary
  Widget _miniSummary(GymThemeDef t) {
    final m = _engine.currentMini;
    final score = switch (m) {
      MiniGame.memory => _engine.memScore,
      MiniGame.reaction => _engine.reactScore,
      MiniGame.stroop => _engine.stroopScore,
    };
    final detail = switch (m) {
      MiniGame.memory =>
        '${_engine.memRounds} rounds of tile training',
      MiniGame.reaction =>
        'Average ${_engine.reactAvgMs}ms over ${_engine.reactRounds} taps',
      MiniGame.stroop =>
        '${_engine.stroopCorrect}/${_engine.stroopRounds} correct answers',
    };
    return Center(
      child: StudyCard(
        theme: t,
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(m.emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 8),
            Text(m.title, style: Study.display(24, theme: t)),
            const SizedBox(height: 4),
            Text(detail, style: Study.body(13, theme: t, color: t.muted)),
            const SizedBox(height: 12),
            _CountUp(
              target: score,
              style: Study.display(52, theme: t)
                  .copyWith(color: t.accentLight),
            ),
            Text('points', style: Study.label(12, theme: t)),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ workout done
  Widget _workoutDone(GymThemeDef t) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 6),
          Text('Brain Score', style: Study.display(28, theme: t)),
          _CountUp(
            target: _engine.total,
            style:
                Study.display(64, theme: t).copyWith(color: t.accentLight),
          ),
          if (_engine.isNewBest)
            Container(
              margin: const EdgeInsets.only(top: 4, bottom: 4),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: t.accent.withValues(alpha: 0.25),
                border: Border.all(color: t.accentLight),
              ),
              child: Text('✦ NEW BEST! ✦',
                  style: Study.label(14, theme: t)),
            ),
          const SizedBox(height: 10),
          StudyCard(
            theme: t,
            child: Column(
              children: [
                _resultRow(t, '🔢', 'Memory Matrix', _engine.memScore),
                const Divider(height: 14),
                _resultRow(t, '⚡',
                    'Quick Tap (${_engine.reactAvgMs}ms avg)', _engine.reactScore),
                const Divider(height: 14),
                _resultRow(t, '🎨',
                    'Color Clash (${_engine.stroopCorrect}/${_engine.stroopRounds})',
                    _engine.stroopScore),
              ],
            ),
          ),
          const SizedBox(height: 16),
          WoodButton(
            label: '🔁  Train again',
            theme: t,
            width: double.infinity,
            onTap: () {
              widget.audio.click();
              _reviewAsked = false;
              _engine.restart();
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: WoodButton(
                  label: '📤 Share',
                  theme: t,
                  small: true,
                  onTap: _shareScore,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: WoodButton(
                  label: '🏠 Menu',
                  theme: t,
                  small: true,
                  onTap: () {
                    widget.audio.click();
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _resultRow(GymThemeDef t, String emoji, String label, int score) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: Study.body(14, theme: t))),
        Text('$score', style: Study.display(18, theme: t)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
/// Animated count-up for scores: numbers roll up instead of popping in.
class _CountUp extends StatelessWidget {
  final int target;
  final TextStyle style;
  const _CountUp({required this.target, required this.style});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: target.toDouble()),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text('${v.round()}', style: style),
    );
  }
}

/// Memory tile with a staggered flip-in reveal, press-down physicality,
/// and animated state colors. Never pops: every reveal visibly flips.
class _MemTile extends StatefulWidget {
  final int index;
  final int state; // 0 hidden, 1 target, 2 found, 3 missed-reveal
  final int token; // reveal generation: re-run flip when it changes
  final TileStyleDef style;
  final GymThemeDef theme;
  final VoidCallback onTap;
  const _MemTile({
    required this.index,
    required this.state,
    required this.token,
    required this.style,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_MemTile> createState() => _MemTileState();
}

class _MemTileState extends State<_MemTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _flip = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
  }

  @override
  void didUpdateWidget(covariant _MemTile old) {
    super.didUpdateWidget(old);
    // New reveal generation: staggered flip-in for target tiles.
    if (widget.token != old.token && widget.state == 1 && mounted) {
      _flip.reset();
      Future.delayed(Duration(milliseconds: widget.index * 45), () {
        if (mounted) _flip.forward();
      });
    }
  }

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final st = widget.style;
    final (c1, c2, edge) = switch (widget.state) {
      1 => (t.accentLight, t.accent, t.accentDark), // target shown
      2 => (t.accentLight, t.accent, t.accentDark), // found
      3 => (
          const Color(0xFFE08080),
          const Color(0xFFC0392B),
          const Color(0xFF7A231B)
        ), // missed: flash the targets
      _ => (st.light, st.dark, st.edge), // face-down
    };
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _flip,
        builder: (_, child) {
          // Flip from edge-on (invisible) to flat, with ease-out.
          final p = Curves.easeOut.transform(_flip.value);
          final angle = (1 - p) * 1.5708;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.002)
              ..rotateY(widget.state == 1 ? angle : 0)
              ..scale(_pressed ? 0.9 : 1.0),
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [c1, c2],
            ),
            border: Border.all(color: edge, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                offset: const Offset(0, 4),
                blurRadius: 6,
              ),
              BoxShadow(
                color: Colors.white.withValues(
                    alpha: widget.state == 0 ? 0.14 : 0.3),
                offset: const Offset(0, 1.5),
                blurRadius: 1,
              ),
            ],
          ),
          child: widget.state == 2
              ? Center(
                  child: AnimatedScale(
                    scale: 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      '✓',
                      style: TextStyle(
                        color: t.woodDeep,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// Reaction pad: red while waiting, green on GO, with a visible pulse
/// whenever the engine arms a new wait or flips to green.
class _ReactionPad extends StatefulWidget {
  final bool green;
  final int pulseToken;
  final GymThemeDef theme;
  final VoidCallback onTap;
  const _ReactionPad({
    required this.green,
    required this.pulseToken,
    required this.theme,
    required this.onTap,
  });

  @override
  State<_ReactionPad> createState() => _ReactionPadState();
}

class _ReactionPadState extends State<_ReactionPad>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void didUpdateWidget(covariant _ReactionPad old) {
    super.didUpdateWidget(old);
    if (widget.pulseToken != old.pulseToken && mounted) {
      _pulse.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final base = widget.green
        ? const Color(0xFF4CAF50)
        : const Color(0xFFE53935);
    final dark = widget.green
        ? const Color(0xFF2E7D32)
        : const Color(0xFFB71C1C);
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _pulse,
        builder: (_, child) {
          final p = Curves.easeOut.transform(_pulse.value);
          final s = 1.0 + 0.07 * (1 - p) * (p < 0.5 ? p * 2 : (1 - p) * 2);
          return Transform.scale(scale: s, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [base, dark],
            ),
            border: Border.all(color: t.woodDeep, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                offset: const Offset(0, 8),
                blurRadius: 16,
              ),
              if (widget.green)
                BoxShadow(
                  color: base.withValues(alpha: 0.55),
                  blurRadius: 34,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Center(
            child: Text(
              widget.green ? '👆 TAP!' : '✋ WAIT…',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 44,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(0, 3),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Stroop answer button: wooden color puck with a press animation and a
/// visible flash ring when it was the correct answer.
class _StroopButton extends StatefulWidget {
  final String name;
  final Color color;
  final GymThemeDef theme;
  final bool flash;
  final int token;
  final VoidCallback onTap;
  const _StroopButton({
    required this.name,
    required this.color,
    required this.theme,
    required this.flash,
    required this.token,
    required this.onTap,
  });

  @override
  State<_StroopButton> createState() => _StroopButtonState();
}

class _StroopButtonState extends State<_StroopButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hit;
  bool _down = false;

  @override
  void initState() {
    super.initState();
    _hit = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void didUpdateWidget(covariant _StroopButton old) {
    super.didUpdateWidget(old);
    if (widget.token != old.token && widget.flash && mounted) {
      _hit.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _hit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        widget.onTap();
        if (mounted) _hit.forward(from: 0);
      },
      child: AnimatedBuilder(
        animation: _hit,
        builder: (_, child) {
          final p = Curves.easeOut.transform(_hit.value);
          return Transform.scale(
            scale: (1 - 0.12 * p) * (_down ? 0.93 : 1.0),
            child: child,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.color.withValues(alpha: 0.92),
                widget.color,
                widget.color.withValues(alpha: 0.72),
              ],
            ),
            border: Border.all(
              color: widget.flash ? t.accentLight : t.woodDeep,
              width: widget.flash ? 4 : 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                offset: Offset(0, _down ? 2 : 6),
                blurRadius: _down ? 6 : 12,
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
