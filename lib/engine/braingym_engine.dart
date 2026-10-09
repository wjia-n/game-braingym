import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'workout_types.dart';
import '../services/settings_service.dart';

/// All workout phases, owned entirely by the engine. The UI only renders.
/// Input-waiting phases (memoryRecall, reactionGreen, stroopPrompt with no
/// time limit) need no timer; every timed phase is armed through [_arm] and
/// covered by the watchdog, so stuck states are impossible by construction.
enum Phase {
  idle,
  countdown,
  memoryShow,
  memoryRecall,
  memoryRoundEnd,
  reactionWait,
  reactionGreen,
  reactionRest,
  stroopPrompt,
  stroopResolve,
  miniSummary,
  workoutDone,
}

/// Sounds / haptics the UI should play for engine events.
enum GymEvent {
  click,
  flip,
  reveal,
  correct,
  wrong,
  tick,
  go,
  falseStart,
  stroopTimeout,
  gameStart,
  miniDone,
  win,
  newBest,
  invalid,
}

/// How a workout is configured: which mini-games, in which order, at which
/// difficulty tier each. [dailySeed] makes the workout deterministic (the
/// daily challenge); null = free workout.
class WorkoutSetup {
  final List<MiniGame> minis;
  final Map<MiniGame, int> difficulty; // 0 easy, 1 medium, 2 hard
  final int? dailySeed;
  final String? dailyDate; // set for the daily challenge

  const WorkoutSetup({
    required this.minis,
    required this.difficulty,
    this.dailySeed,
    this.dailyDate,
  });

  bool get isDaily => dailySeed != null;

  WorkoutSetup copy() => WorkoutSetup(
        minis: List.of(minis),
        difficulty: Map.of(difficulty),
        dailySeed: dailySeed,
        dailyDate: dailyDate,
      );
}

/// Brain Gym workout engine: deterministic rules, all phases, watchdog.
/// UI-agnostic: exposes state, takes taps, emits [GymEvent]s for audio.
class BrainGymEngine extends ChangeNotifier {
  final GymSettings settings;

  BrainGymEngine({required this.settings});

  WorkoutSetup? setup;
  int miniIndex = 0;
  Phase phase = Phase.idle;
  String banner = '';
  bool over = false;

  // Countdown.
  int countdownValue = 3;

  // Memory state.
  int memRound = 0;
  int memRounds = 0;
  Set<int> memTargets = {};
  Set<int> memFound = {};
  bool memMissed = false;
  int memScore = 0;
  int tileToken = 0; // increments each time tiles are shown (UI re-animates)

  // Reaction state.
  int reactRound = 0;
  int reactRounds = 0;
  final reactTimes = <int>[];
  int reactScore = 0;
  int reactStartMs = 0;
  int reactPulseToken = 0; // UI pulses the pad on each wait/green change

  // Stroop state.
  int stroopRound = 0;
  int stroopRounds = 0;
  String stroopWord = '';
  String stroopInkName = '';
  Color stroopInk = const Color(0xFFE53935);
  int stroopCorrect = 0;
  int stroopWrong = 0;
  int stroopScore = 0;
  int stroopId = 0; // increments per word (UI cross-fades)
  bool stroopLastOk = true;
  int stroopResolveToken = 0; // UI flashes correct/wrong

  // Totals.
  int get total => memScore + reactScore + stroopScore;
  bool isNewBest = false;

  /// UI hook for sounds. Set by the screen.
  void Function(GymEvent event)? onEvent;

  var _rand = Random();
  Timer? _timer; // single phase-transition timer
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  bool paused = false;

  static const _stroopInks = {
    'RED': Color(0xFFE53935),
    'BLUE': Color(0xFF1E88E5),
    'GREEN': Color(0xFF43A047),
    'YELLOW': Color(0xFFF9A825),
  };

  MiniGame get currentMini =>
      setup != null && miniIndex < setup!.minis.length
          ? setup!.minis[miniIndex]
          : MiniGame.memory;

  // ------------------------------------------------------------- lifecycle
  void start(WorkoutSetup s) {
    _timer?.cancel();
    setup = s.copy();
    _rand = s.dailySeed != null ? Random(s.dailySeed) : Random();
    miniIndex = 0;
    over = false;
    paused = false;
    isNewBest = false;
    memScore = 0;
    reactScore = 0;
    stroopScore = 0;
    phase = Phase.idle;
    onEvent?.call(GymEvent.gameStart);
    _watchdog ??=
        Timer.periodic(const Duration(seconds: 3), (_) => _recover());
    _beginMini(0);
  }

  void restart() {
    final s = setup;
    if (s != null) start(s);
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  void _arm(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _timer?.cancel();
    _timer = Timer(d, () {
      _timer = null;
      if (!_disposed && !paused) fn();
    });
  }

  /// Pause: freeze the phase timer. Resume re-arms the current phase.
  void setPaused(bool v) {
    if (paused == v || _disposed) return;
    paused = v;
    if (v) {
      _timer?.cancel();
      _timer = null;
    } else {
      _recover();
    }
    notifyListeners();
  }

  /// Watchdog: if the single phase timer ever dies without progress,
  /// recover the phase. Stuck states impossible by construction.
  void _recover() {
    if (_disposed || over || paused || _timer != null) return;
    switch (phase) {
      case Phase.countdown:
        _arm(const Duration(milliseconds: 700), _countStep);
      case Phase.memoryShow:
        _arm(const Duration(milliseconds: 1200), _memHide);
      case Phase.memoryRoundEnd:
        _arm(const Duration(milliseconds: 600), _memNextRound);
      case Phase.reactionWait:
        _arm(const Duration(milliseconds: 1500), _reactGo);
      case Phase.reactionRest:
        _arm(const Duration(milliseconds: 700), _reactNextRound);
      case Phase.stroopPrompt:
        final limit = _stroopLimitMs();
        if (limit > 0) _arm(Duration(milliseconds: limit), _stroopTimeout);
      case Phase.stroopResolve:
        _arm(const Duration(milliseconds: 500), _stroopNextRound);
      case Phase.miniSummary:
        _arm(const Duration(milliseconds: 1200), _afterSummary);
      case Phase.idle:
      case Phase.memoryRecall:
      case Phase.reactionGreen:
      case Phase.workoutDone:
        break; // input-waiting or terminal: nothing to recover
    }
  }

  // -------------------------------------------------------------- mini flow
  void _beginMini(int i) {
    miniIndex = i;
    countdownValue = 3;
    phase = Phase.countdown;
    final m = setup!.minis[i];
    banner = '${m.emoji} ${m.title} — get ready!';
    onEvent?.call(GymEvent.tick);
    notifyListeners();
    _arm(const Duration(milliseconds: 750), _countStep);
  }

  void _countStep() {
    if (phase != Phase.countdown || over) return;
    countdownValue--;
    if (countdownValue > 0) {
      onEvent?.call(GymEvent.tick);
      notifyListeners();
      _arm(const Duration(milliseconds: 750), _countStep);
    } else {
      onEvent?.call(GymEvent.go);
      banner = 'Go!';
      notifyListeners();
      _arm(const Duration(milliseconds: 450), _startMiniLogic);
    }
  }

  void _startMiniLogic() {
    if (over) return;
    switch (currentMini) {
      case MiniGame.memory:
        memRound = 0;
        memScore = 0;
        memRounds = DifficultyTable.memory(_diff(MiniGame.memory)).rounds;
        _memNextRound();
      case MiniGame.reaction:
        reactRound = 0;
        reactScore = 0;
        reactTimes.clear();
        reactRounds = DifficultyTable.reaction(_diff(MiniGame.reaction)).rounds;
        _reactNextRound();
      case MiniGame.stroop:
        stroopRound = 0;
        stroopScore = 0;
        stroopCorrect = 0;
        stroopWrong = 0;
        stroopRounds = DifficultyTable.stroop(_diff(MiniGame.stroop)).rounds;
        _stroopNextRound();
    }
  }

  int _diff(MiniGame m) => setup?.difficulty[m] ?? 1;

  void _miniDone() {
    phase = Phase.miniSummary;
    banner = '${currentMini.title} complete!';
    onEvent?.call(GymEvent.miniDone);
    notifyListeners();
    _arm(const Duration(milliseconds: 1900), _afterSummary);
  }

  void _afterSummary() {
    if (over || phase != Phase.miniSummary) return;
    if (miniIndex + 1 < setup!.minis.length) {
      _beginMini(miniIndex + 1);
    } else {
      unawaited(_finish());
    }
  }

  Future<void> _finish() async {
    if (over) return;
    over = true;
    phase = Phase.workoutDone;
    isNewBest = await settings.recordWorkout(
      total,
      dailyDate: setup?.dailyDate,
    );
    banner = isNewBest ? 'NEW BEST! 🏆' : 'Workout complete!';
    notifyListeners();
    onEvent?.call(GymEvent.win);
    if (isNewBest) onEvent?.call(GymEvent.newBest);
  }

  // ---------------------------------------------------------------- memory
  void _memNextRound() {
    if (over || phase == Phase.workoutDone) return;
    if (memRound >= memRounds) {
      _miniDone();
      return;
    }
    final cfg = DifficultyTable.memory(_diff(MiniGame.memory));
    final k = cfg.tilesMin + _rand.nextInt(cfg.tilesMax - cfg.tilesMin + 1);
    final t = <int>{};
    while (t.length < k) {
      t.add(_rand.nextInt(16));
    }
    memRound++;
    memTargets = t;
    memFound = {};
    memMissed = false;
    tileToken++; // UI re-runs the reveal animation
    phase = Phase.memoryShow;
    banner = 'Memorize the tiles!';
    onEvent?.call(GymEvent.reveal);
    notifyListeners();
    _arm(Duration(milliseconds: cfg.showMs), _memHide);
  }

  void _memHide() {
    if (over || phase != Phase.memoryShow) return;
    phase = Phase.memoryRecall;
    banner = 'Tap them back!';
    notifyListeners();
  }

  /// Returns the visual state of tile [i]: 0 hidden, 1 target-shown,
  /// 2 found, 3 revealed-after-miss.
  int memTileState(int i) {
    if (phase == Phase.memoryShow) {
      return memTargets.contains(i) ? 1 : 0;
    }
    if (memFound.contains(i)) return 2;
    if (phase == Phase.memoryRoundEnd && memMissed && memTargets.contains(i)) {
      return 3;
    }
    return 0;
  }

  void memTap(int i) {
    if (over || phase != Phase.memoryRecall) {
      return;
    }
    if (memTargets.contains(i) && !memFound.contains(i)) {
      memFound.add(i);
      onEvent?.call(GymEvent.flip);
      if (memFound.length == memTargets.length) {
        memScore += memTargets.length * 20;
        phase = Phase.memoryRoundEnd;
        memMissed = false;
        banner = 'Well remembered! +${memTargets.length * 20}';
        onEvent?.call(GymEvent.correct);
        notifyListeners();
        _arm(const Duration(milliseconds: 1000), _memNextRound);
      } else {
        notifyListeners();
      }
    } else if (!memFound.contains(i)) {
      // Wrong tile: round failed, reveal the targets, move on.
      memMissed = true;
      phase = Phase.memoryRoundEnd;
      tileToken++; // UI flashes the missed targets
      banner = 'Oops — those were the tiles!';
      onEvent?.call(GymEvent.wrong);
      notifyListeners();
      _arm(const Duration(milliseconds: 1500), _memNextRound);
    }
  }

  // --------------------------------------------------------------- reaction
  void _reactNextRound() {
    if (over || phase == Phase.workoutDone) return;
    if (reactRound >= reactRounds) {
      final avg = reactTimes.isEmpty
          ? 0
          : reactTimes.reduce((a, b) => a + b) ~/ reactTimes.length;
      reactScore = ((1500 - avg).clamp(0, 1500) ~/ 3);
      _miniDone();
      return;
    }
    final cfg = DifficultyTable.reaction(_diff(MiniGame.reaction));
    reactRound++;
    phase = Phase.reactionWait;
    reactPulseToken++;
    banner = 'Wait for green…';
    notifyListeners();
    final wait = cfg.waitMinMs +
        _rand.nextInt(cfg.waitMaxMs - cfg.waitMinMs + 1);
    _arm(Duration(milliseconds: wait), _reactGo);
  }

  void _reactGo() {
    if (over || phase != Phase.reactionWait) return;
    phase = Phase.reactionGreen;
    reactStartMs = DateTime.now().millisecondsSinceEpoch;
    reactPulseToken++;
    banner = 'TAP!';
    onEvent?.call(GymEvent.go);
    notifyListeners();
  }

  void reactTap() {
    if (over) return;
    if (phase == Phase.reactionWait) {
      // False start: heavy penalty, like the old rules.
      reactTimes.add(1500);
      phase = Phase.reactionRest;
      banner = 'Too soon! +1500ms penalty';
      onEvent?.call(GymEvent.falseStart);
      notifyListeners();
      _arm(const Duration(milliseconds: 1100), _reactNextRound);
    } else if (phase == Phase.reactionGreen) {
      final ms = DateTime.now().millisecondsSinceEpoch - reactStartMs;
      reactTimes.add(ms);
      phase = Phase.reactionRest;
      banner = '${ms}ms — nice!';
      onEvent?.call(GymEvent.correct);
      notifyListeners();
      _arm(const Duration(milliseconds: 750), _reactNextRound);
    }
  }

  // ----------------------------------------------------------------- stroop
  int _stroopLimitMs() =>
      DifficultyTable.stroop(_diff(MiniGame.stroop)).timeLimitMs;

  void _stroopNextRound() {
    if (over || phase == Phase.workoutDone) return;
    if (stroopRound >= stroopRounds) {
      stroopScore = (stroopCorrect * 60 - stroopWrong * 30).clamp(0, 900);
      _miniDone();
      return;
    }
    final names = _stroopInks.keys.toList();
    final word = names[_rand.nextInt(names.length)];
    var ink = names[_rand.nextInt(names.length)];
    if (_rand.nextDouble() < 0.75 && ink == word) {
      ink = names[(names.indexOf(word) + 1 + _rand.nextInt(3)) % names.length];
    }
    stroopRound++;
    stroopWord = word;
    stroopInkName = ink;
    stroopInk = _stroopInks[ink]!;
    stroopId++; // UI cross-fades to the new word
    phase = Phase.stroopPrompt;
    banner = 'Tap the INK color!';
    notifyListeners();
    final limit = _stroopLimitMs();
    if (limit > 0) _arm(Duration(milliseconds: limit), _stroopTimeout);
  }

  void _stroopTimeout() {
    if (over || phase != Phase.stroopPrompt) return;
    stroopWrong++;
    onEvent?.call(GymEvent.stroopTimeout);
    _stroopResolve(false);
  }

  void stroopTap(String name) {
    if (over || phase != Phase.stroopPrompt) {
      return;
    }
    if (name == stroopInkName) {
      stroopCorrect++;
      onEvent?.call(GymEvent.correct);
      _stroopResolve(true);
    } else {
      stroopWrong++;
      onEvent?.call(GymEvent.wrong);
      _stroopResolve(false);
    }
  }

  void _stroopResolve(bool ok) {
    phase = Phase.stroopResolve;
    stroopLastOk = ok;
    stroopResolveToken++;
    banner = ok ? 'Correct!' : 'That was $stroopInkName!';
    notifyListeners();
    _arm(const Duration(milliseconds: 550), _stroopNextRound);
  }

  // ------------------------------------------------------------ UI helpers
  /// Stroop ink choices in a fixed order for the button grid.
  List<MapEntry<String, Color>> get stroopChoices =>
      _stroopInks.entries.toList();

  int get reactAvgMs => reactTimes.isEmpty
      ? 0
      : reactTimes.reduce((a, b) => a + b) ~/ reactTimes.length;

  String difficultyName(MiniGame m) =>
      DifficultyTable.names[(_diff(m)).clamp(0, 2)];
}
