import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

// Phases: 0 intro, 1 memory, 2 reaction, 3 stroop, 4 results
class BrainGymScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const BrainGymScreen({super.key, required this.players, required this.callbacks});

  @override
  State<BrainGymScreen> createState() => _BrainGymScreenState();
}

class _BrainGymScreenState extends State<BrainGymScreen> {
  final rand = Random();
  int phase = 0;
  int memScore = 0, reactScore = 0, stroopScore = 0;
  int best = 0;
  bool over = false;

  // memory
  int memRound = 0; // 1..5
  Set<int> memTargets = {};
  Set<int> memFound = {};
  bool memShowing = true;
  Timer? memTimer;

  // reaction
  int reactRound = 0; // 1..5
  bool reactGreen = false;
  int reactStart = 0;
  final reactTimes = <int>[];
  Timer? reactTimer;

  // stroop
  int stroopRound = 0; // 1..15
  late String stroopWord;
  late Color stroopInk;
  late String stroopInkName;
  int stroopCorrect = 0, stroopWrong = 0;

  int get total => memScore + reactScore + stroopScore;

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => best = p.getInt('braingym_best') ?? 0);
  }

  @override
  void dispose() {
    memTimer?.cancel();
    reactTimer?.cancel();
    super.dispose();
  }

  // ---------- memory ----------
  void _startMemory() {
    setState(() {
      phase = 1;
      memRound = 0;
      memScore = 0;
    });
    _memNext();
  }

  void _memNext() {
    if (memRound >= 5) {
      _startReaction();
      return;
    }
    final k = 2 + (memRound + 1); // 3..7 tiles
    final t = <int>{};
    while (t.length < k) {
      t.add(rand.nextInt(16));
    }
    setState(() {
      memRound++;
      memTargets = t;
      memFound = {};
      memShowing = true;
    });
    memTimer?.cancel();
    memTimer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => memShowing = false);
    });
  }

  void _memTap(int i) {
    if (memShowing || over) return;
    if (memTargets.contains(i) && !memFound.contains(i)) {
      Sfx.tap();
      setState(() => memFound.add(i));
      if (memFound.length == memTargets.length) {
        memScore += memTargets.length * 20;
        Sfx.move();
        Future.delayed(const Duration(milliseconds: 500), _memNext);
      }
    } else if (!memFound.contains(i)) {
      Sfx.lose();
      // wrong tap: round failed, move on
      Future.delayed(const Duration(milliseconds: 400), _memNext);
    }
  }

  // ---------- reaction ----------
  void _startReaction() {
    setState(() {
      phase = 2;
      reactRound = 0;
      reactTimes.clear();
      reactScore = 0;
    });
    _reactNext();
  }

  void _reactNext() {
    if (reactRound >= 5) {
      final avg = reactTimes.reduce((a, b) => a + b) ~/ reactTimes.length;
      reactScore = ((1500 - avg).clamp(0, 1500) ~/ 3);
      _startStroop();
      return;
    }
    setState(() {
      reactRound++;
      reactGreen = false;
    });
    reactTimer?.cancel();
    reactTimer = Timer(
        Duration(milliseconds: 1000 + rand.nextInt(2500)), () {
      if (!mounted) return;
      setState(() {
        reactGreen = true;
        reactStart = DateTime.now().millisecondsSinceEpoch;
      });
      Sfx.click();
    });
  }

  void _reactTap() {
    if (over) return;
    if (reactGreen) {
      final ms = DateTime.now().millisecondsSinceEpoch - reactStart;
      reactTimes.add(ms);
      Sfx.move();
      setState(() => reactGreen = false);
      Future.delayed(const Duration(milliseconds: 600), _reactNext);
    } else {
      // false start
      reactTimes.add(1500);
      Sfx.lose();
      reactTimer?.cancel();
      setState(() => reactGreen = false);
      Future.delayed(const Duration(milliseconds: 800), _reactNext);
    }
  }

  // ---------- stroop ----------
  static const _stroopColors = {
    'RED': Color(0xFFE53935),
    'BLUE': Color(0xFF1E88E5),
    'GREEN': Color(0xFF43A047),
    'YELLOW': Color(0xFFF9A825),
  };

  void _startStroop() {
    setState(() {
      phase = 3;
      stroopRound = 0;
      stroopCorrect = 0;
      stroopWrong = 0;
      stroopScore = 0;
    });
    _stroopNext();
  }

  void _stroopNext() {
    if (stroopRound >= 15) {
      stroopScore = (stroopCorrect * 60 - stroopWrong * 30).clamp(0, 900);
      _finish();
      return;
    }
    final names = _stroopColors.keys.toList();
    final word = names[rand.nextInt(4)];
    var ink = names[rand.nextInt(4)];
    if (rand.nextDouble() < 0.75 && ink == word) {
      ink = names[(names.indexOf(word) + 1 + rand.nextInt(3)) % 4];
    }
    setState(() {
      stroopRound++;
      stroopWord = word;
      stroopInkName = ink;
      stroopInk = _stroopColors[ink]!;
    });
  }

  void _stroopTap(String name) {
    if (over) return;
    if (name == stroopInkName) {
      stroopCorrect++;
      Sfx.tap();
    } else {
      stroopWrong++;
      Sfx.lose();
    }
    _stroopNext();
  }

  Future<void> _finish() async {
    if (over) return;
    over = true;
    final p = await SharedPreferences.getInstance();
    final isBest = total > (p.getInt('braingym_best') ?? 0);
    if (isBest) await p.setInt('braingym_best', total);
    widget.players.first.score = total;
    Sfx.win();
    final avg = reactTimes.isEmpty ? 0 : reactTimes.reduce((a, b) => a + b) ~/ reactTimes.length;
    widget.callbacks.finish(
        headline: 'Brain Score: $total!',
        subline: 'Memory $memScore · Reaction ${avg}ms avg · Focus $stroopCorrect/15'
            '${isBest ? ' · NEW BEST! 🏆' : ' · best $best'}');
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.of(context).theme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: switch (phase) {
          0 => _intro(theme),
          1 => _memoryUI(theme),
          2 => _reactionUI(theme),
          3 => _stroopUI(theme),
          _ => const SizedBox.shrink(),
        },
      ),
    );
  }

  Widget _intro(GameTheme theme) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🧠', style: TextStyle(fontSize: 72)),
          const SizedBox(height: 8),
          Text('Time to pump some neurons!',
              style: TextStyle(
                  color: theme.text, fontSize: 22, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          _testCard(theme, '🔢', 'Memory Matrix', 'Remember the glowing tiles'),
          _testCard(theme, '⚡', 'Quick Tap', 'Tap the instant it turns green'),
          _testCard(theme, '🎨', 'Color Clash', 'Tap the INK color, not the word'),
          const SizedBox(height: 16),
          if (best > 0)
            Text('Your best Brain Score: $best 🏆',
                style: TextStyle(color: theme.muted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          WajihaButton(label: 'Start workout', emoji: '💪', onTap: () {
            Sfx.click();
            _startMemory();
          }),
        ],
      );

  Widget _testCard(GameTheme theme, String e, String t, String d) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: theme.surface, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Text(e, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t,
                style: TextStyle(
                    color: theme.text, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(d, style: TextStyle(color: theme.muted, fontSize: 13)),
          ]),
        ]),
      );

  Widget _memoryUI(GameTheme theme) => Column(
        children: [
          _phaseHeader(theme, '🔢', 'Memory Matrix', 'Round $memRound/5',
              memShowing ? 'Memorize!' : 'Tap them back!'),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8),
              itemCount: 16,
              itemBuilder: (_, i) {
                final lit = memShowing
                    ? memTargets.contains(i)
                    : memFound.contains(i);
                return GestureDetector(
                  onTap: () => _memTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: lit ? theme.accent : theme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: theme.primary.withValues(alpha: 0.25)),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );

  Widget _reactionUI(GameTheme theme) => Column(
        children: [
          _phaseHeader(theme, '⚡', 'Quick Tap', 'Round $reactRound/5',
              reactGreen ? 'TAP NOW!' : 'Wait for green…'),
          const SizedBox(height: 12),
          Expanded(
            child: GestureDetector(
              onTap: _reactTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: reactGreen ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Center(
                  child: Text(reactGreen ? '👆 TAP!' : '✋ WAIT…',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w900)),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text('tapping early = slow penalty!',
              style: TextStyle(color: theme.muted, fontSize: 12)),
        ],
      );

  Widget _stroopUI(GameTheme theme) => Column(
        children: [
          _phaseHeader(theme, '🎨', 'Color Clash', 'Round $stroopRound/15',
              'Tap the INK color!'),
          const SizedBox(height: 8),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(stroopWord,
                  style: TextStyle(
                      color: stroopInk,
                      fontSize: 64,
                      fontWeight: FontWeight.w900)),
            ),
          ),
          Expanded(
            flex: 3,
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              physics: const NeverScrollableScrollPhysics(),
              children: _stroopColors.entries
                  .map((e) => GestureDetector(
                        onTap: () => _stroopTap(e.key),
                        child: Container(
                          decoration: BoxDecoration(
                              color: e.value,
                              borderRadius: BorderRadius.circular(20)),
                          child: Center(
                            child: Text(e.key,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
          Text('✅ $stroopCorrect   ❌ $stroopWrong',
              style: TextStyle(
                  color: theme.text, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      );

  Widget _phaseHeader(GameTheme theme, String e, String title, String round,
          String hint) =>
      Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(e, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  color: theme.text, fontSize: 20, fontWeight: FontWeight.w900)),
        ]),
        Text('$round · $hint',
            style: TextStyle(color: theme.muted, fontWeight: FontWeight.bold)),
      ]);
}
