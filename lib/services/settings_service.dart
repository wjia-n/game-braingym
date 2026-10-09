import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../engine/workout_types.dart';
import '../theme/gym_themes.dart';

/// Persisted settings + profile + stats for Brain Gym.
///
/// The player profile (renameable display names) is stored as ONE
/// order-preserving JSON string via setString — never setStringList:
/// Android's SharedPreferences stores StringLists as an unordered
/// StringSet, which scrambles slot order across restarts. Legacy keys are
/// migrated once and removed.
class GymSettings extends ChangeNotifier {
  static const _kMusic = 'braingym_music_on';
  static const _kSfx = 'braingym_sfx_on';
  static const _kVolume = 'braingym_volume';
  static const _kNames = 'braingym_player_names_json';
  static const _kLegacyProfile = 'braingym_profile_json'; // old single JSON
  static const _kLegacyName = 'braingym_player_name'; // legacy plain key
  static const _kTheme = 'braingym_theme_id';
  static const _kTileStyle = 'braingym_tile_style';
  static const _kDiffPrefix = 'braingym_diff_'; // + memory|reaction|stroop
  static const _kGames = 'braingym_games_played';
  static const _kBest = 'braingym_best_score';
  static const _kIsPro = 'braingym_is_pro';
  static const _kCustomPrefix = 'braingym_custom_';

  static const defaultName = 'Scholar';

  /// Encode the name list as one JSON string (order-preserving).
  static String encodeNames(String name) =>
      jsonEncode([name.trim().isEmpty ? defaultName : name.trim()]);

  /// Decode the name list; also understands the old single-name map format.
  static String decodeNames(String? raw) {
    if (raw == null) return defaultName;
    try {
      final d = jsonDecode(raw);
      if (d is List && d.isNotEmpty) {
        final n = (d.first as String? ?? '').trim();
        if (n.isNotEmpty) return n;
      }
      if (d is Map) {
        final n = (d['name'] as String? ?? '').trim();
        if (n.isNotEmpty) return n;
      }
    } catch (_) {}
    return defaultName;
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  String playerName = defaultName;
  String themeId = 'classic';
  int tileStyle = 0;
  Map<MiniGame, int> difficulty = {
    MiniGame.memory: 1,
    MiniGame.reaction: 1,
    MiniGame.stroop: 1,
  };
  int gamesPlayed = 0;
  int bestScore = 0;
  bool isPro = false;

  /// Custom theme colors (ARGB ints). Defaults mirror the Oak Study.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'woodDark': 0xFF3B2416,
    'woodMid': 0xFF5C3A21,
    'woodDeep': 0xFF241309,
    'accent': 0xFFC9A227,
    'accentLight': 0xFFE8CE7A,
    'accentDark': 0xFF8A6D1A,
    'paper': 0xFFF5EFE0,
    'paperInk': 0xFF2A1B0E,
    'felt': 0xFF1E4D3B,
    'tileLight': 0xFFEFE3C8,
    'tileDark': 0xFFD9C6A0,
    'ink': 0xFFF5EFE0,
    'muted': 0xFFB9A582,
  };

  /// Builds the user-designed custom theme from stored colors.
  GymThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return GymThemeDef(
      id: 'custom',
      name: 'My Creation',
      woodDark: c('woodDark'),
      woodMid: c('woodMid'),
      woodDeep: c('woodDeep'),
      accent: c('accent'),
      accentLight: c('accentLight'),
      accentDark: c('accentDark'),
      paper: c('paper'),
      paperInk: c('paperInk'),
      felt: c('felt'),
      tileLight: c('tileLight'),
      tileDark: c('tileDark'),
      ink: c('ink'),
      muted: c('muted'),
    );
  }

  SharedPreferences? _prefs;

  /// Today's date key, e.g. "2026-10-09".
  static String todayKey() {
    final n = DateTime.now();
    return '${n.year}-${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
  }

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    // Profile: prefer the order-safe JSON list key; one-time migration
    // from the two legacy keys, then drop them for good.
    final raw = p.getString(_kNames);
    if (raw != null) {
      playerName = decodeNames(raw);
    } else {
      final legacyJson = p.getString(_kLegacyProfile);
      if (legacyJson != null) {
        playerName = decodeNames(legacyJson);
      } else {
        final legacy = p.getString(_kLegacyName);
        playerName =
            (legacy ?? '').trim().isEmpty ? defaultName : legacy!.trim();
      }
    }
    themeId = p.getString(_kTheme) ?? 'classic';
    tileStyle = (p.getInt(_kTileStyle) ?? 0).clamp(0, TileStyles.all.length - 1);
    for (final m in MiniGame.values) {
      difficulty[m] = (p.getInt('$_kDiffPrefix${m.name}') ?? 1).clamp(0, 2);
    }
    gamesPlayed = p.getInt(_kGames) ?? 0;
    bestScore = p.getInt(_kBest) ?? 0;
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] =
          p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    await _save(); // persist the legacy migration + limits
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setString(_kNames, encodeNames(playerName));
    await p.remove(_kLegacyProfile); // drop the legacy keys for good
    await p.remove(_kLegacyName);
    await p.setString(_kTheme, themeId);
    await p.setInt(_kTileStyle, tileStyle);
    for (final m in MiniGame.values) {
      await p.setInt('$_kDiffPrefix${m.name}', difficulty[m]!);
    }
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kBest, bestScore);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || GymThemes.isProTheme(themeId)) {
      themeId = 'classic';
      changed = true;
    }
    if (TileStyles.isPro(tileStyle)) {
      tileStyle = 0;
      changed = true;
    }
    for (final m in MiniGame.values) {
      if (difficulty[m]! > 1) {
        difficulty[m] = 1;
        changed = true;
      }
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  Future<void> setPlayerName(String name) async {
    final clean = name.trim();
    playerName = clean.isEmpty ? defaultName : clean;
    notifyListeners();
    await _save();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    // Pro-only themes (incl. the custom creator) require Pro.
    if (!isPro && (id == 'custom' || GymThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setTileStyle(int v) async {
    v = v.clamp(0, TileStyles.all.length - 1);
    if (!isPro && TileStyles.isPro(v)) return;
    tileStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(MiniGame mini, int v) async {
    v = v.clamp(0, 2);
    if (!isPro && v > 1) return; // Hard mode is a Pro feature
    difficulty[mini] = v;
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom theme creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  // ------------------------------------------------------------ daily stats
  String _dailyBestKey(String date) => 'braingym_daily_best_$date';
  String _dailyDoneKey(String date) => 'braingym_daily_done_$date';

  int dailyBest(String date) => _prefs?.getInt(_dailyBestKey(date)) ?? 0;
  bool dailyDone(String date) => _prefs?.getBool(_dailyDoneKey(date)) ?? false;

  /// Record a finished workout. Returns true if it is a new all-time best.
  Future<bool> recordWorkout(int score, {String? dailyDate}) async {
    gamesPlayed++;
    final isNewBest = score > bestScore;
    if (isNewBest) bestScore = score;
    if (dailyDate != null) {
      final p = _prefs;
      if (p != null) {
        await p.setBool(_dailyDoneKey(dailyDate), true);
        if (score > dailyBest(dailyDate)) {
          await p.setInt(_dailyBestKey(dailyDate), score);
        }
      }
    }
    notifyListeners();
    await _save();
    return isNewBest;
  }
}
