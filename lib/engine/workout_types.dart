/// Shared workout types (kept dependency-free so both the engine and the
/// settings service can use them without a circular import).
enum MiniGame { memory, reaction, stroop }

extension MiniGameInfo on MiniGame {
  String get title => switch (this) {
        MiniGame.memory => 'Memory Matrix',
        MiniGame.reaction => 'Quick Tap',
        MiniGame.stroop => 'Color Clash',
      };

  String get emoji => switch (this) {
        MiniGame.memory => '🔢',
        MiniGame.reaction => '⚡',
        MiniGame.stroop => '🎨',
      };

  String get blurb => switch (this) {
        MiniGame.memory => 'Memorize the glowing tiles, then tap them back.',
        MiniGame.reaction => 'Wait for green… then tap as fast as you can!',
        MiniGame.stroop => 'Tap the INK color of the word, not what it says.',
      };
}

/// Difficulty parameters for Memory Matrix.
class MemoryParams {
  final int rounds;
  final int tilesMin;
  final int tilesMax;
  final int showMs;
  const MemoryParams({
    required this.rounds,
    required this.tilesMin,
    required this.tilesMax,
    required this.showMs,
  });
}

/// Difficulty parameters for Quick Tap.
class ReactionParams {
  final int rounds;
  final int waitMinMs;
  final int waitMaxMs;
  const ReactionParams({
    required this.rounds,
    required this.waitMinMs,
    required this.waitMaxMs,
  });
}

/// Difficulty parameters for Color Clash.
class StroopParams {
  final int rounds;
  final int timeLimitMs; // 0 = no per-word time limit
  const StroopParams({required this.rounds, required this.timeLimitMs});
}

/// Difficulty tier (0 Easy, 1 Medium, 2 Hard) → parameters per mini-game.
class DifficultyTable {
  static MemoryParams memory(int d) => switch (d) {
        0 => const MemoryParams(rounds: 5, tilesMin: 3, tilesMax: 5, showMs: 2800),
        2 => const MemoryParams(rounds: 6, tilesMin: 5, tilesMax: 9, showMs: 1600),
        _ => const MemoryParams(rounds: 5, tilesMin: 4, tilesMax: 7, showMs: 2200),
      };

  static ReactionParams reaction(int d) => switch (d) {
        0 => const ReactionParams(rounds: 3, waitMinMs: 1200, waitMaxMs: 2500),
        2 => const ReactionParams(rounds: 7, waitMinMs: 800, waitMaxMs: 3000),
        _ => const ReactionParams(rounds: 5, waitMinMs: 1000, waitMaxMs: 3500),
      };

  static StroopParams stroop(int d) => switch (d) {
        0 => const StroopParams(rounds: 10, timeLimitMs: 0),
        2 => const StroopParams(rounds: 20, timeLimitMs: 3000),
        _ => const StroopParams(rounds: 15, timeLimitMs: 5000),
      };

  static const names = ['Easy', 'Medium', 'Hard'];
}
