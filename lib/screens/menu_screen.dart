import 'package:flutter/material.dart';
import '../engine/workout_types.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/gym_themes.dart';
import '../theme/study_widgets.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';
import 'theme_screen.dart';
import 'workout_screen.dart';

/// Main menu: profile, quick workout, daily challenge, difficulty setup,
/// themes, settings, Pro.
class MenuScreen extends StatefulWidget {
  final BrainAudio audio;
  final GymSettings settings;
  final StoreService store;
  const MenuScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  GymThemeDef get _t => GymThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
  }

  void _startWorkout({bool daily = false}) {
    widget.audio.click();
    final s = widget.settings;
    WorkoutSetup setup;
    if (daily) {
      final date = GymSettings.todayKey();
      // Deterministic daily seed: same workout for everyone, all day.
      final seed = date.hashCode & 0x7fffffff;
      setup = WorkoutSetup(
        minis: MiniGame.values.toList(),
        difficulty: {
          MiniGame.memory: 1,
          MiniGame.reaction: 1,
          MiniGame.stroop: 1,
        },
        dailySeed: seed,
        dailyDate: date,
      );
    } else {
      setup = WorkoutSetup(
        minis: MiniGame.values.toList(),
        difficulty: Map.of(s.difficulty),
      );
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WorkoutScreen(
          audio: widget.audio,
          settings: s,
          store: widget.store,
          setup: setup,
        ),
      ),
    );
  }

  /// Rename dialog: persists on EVERY keystroke and commits on focus
  /// loss — the name is never held only until keyboard-done.
  Future<void> _renameProfile() async {
    final s = widget.settings;
    final ctrl = TextEditingController(text: s.playerName);
    final focus = FocusNode();
    void persist() => s.setPlayerName(ctrl.text);
    ctrl.addListener(persist);
    focus.addListener(() {
      if (!focus.hasFocus) persist();
    });
    final done = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _t.woodMid,
        title: Text('Your name', style: Study.display(20, theme: _t)),
        content: TextField(
          controller: ctrl,
          focusNode: focus,
          autofocus: true,
          maxLength: 16,
          style: Study.body(17, theme: _t),
          decoration: InputDecoration(
            hintText: 'e.g. Nova',
            hintStyle: Study.body(15, theme: _t, color: _t.muted),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _t.accent),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _t.accentLight, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: Study.label(13, theme: _t)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Save', style: Study.label(13, theme: _t)),
          ),
        ],
      ),
    );
    ctrl.removeListener(persist);
    focus.dispose();
    ctrl.dispose();
    if (done == true && mounted) await widget.audio.click();
  }

  void _open(Widget screen) {
    widget.audio.click();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final date = GymSettings.todayKey();
    return WoodBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Logo + title.
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: t.accent, width: 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          'assets/braingym_logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Brain Gym',
                                style: Study.display(30, theme: t)),
                            Text(
                              'DAILY MIND WORKOUTS',
                              style: Study.label(11, theme: t),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _open(ProScreen(
                          audio: widget.audio,
                          settings: s,
                          store: widget.store,
                        )),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: s.isPro
                                ? t.accent.withValues(alpha: 0.85)
                                : Colors.black.withValues(alpha: 0.45),
                            border: Border.all(color: t.accent, width: 1.5),
                          ),
                          child: Text(
                            s.isPro ? '✦ PRO' : 'GET PRO',
                            style: Study.label(12, theme: t).copyWith(
                              color:
                                  s.isPro ? t.woodDeep : t.accentLight,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Profile card.
                  StudyCard(
                    theme: t,
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [t.accentLight, t.accentDark],
                            ),
                            border:
                                Border.all(color: t.woodDeep, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              s.playerName.isEmpty
                                  ? '?'
                                  : s.playerName[0].toUpperCase(),
                              style: Study.display(24, theme: t)
                                  .copyWith(color: t.woodDeep),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.playerName,
                                  style: Study.display(19, theme: t)),
                              Text(
                                'Best score ${s.bestScore} · '
                                '${s.gamesPlayed} workouts',
                                style: Study.body(12,
                                    theme: t, color: t.muted),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: t.accentLight),
                          onPressed: _renameProfile,
                          tooltip: 'Rename',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Daily challenge card.
                  StudyCard(
                    theme: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('📅',
                                style: TextStyle(fontSize: 26)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text('Daily Challenge',
                                      style: Study.display(18, theme: t)),
                                  Text(
                                    s.dailyDone(date)
                                        ? 'Done today — best ${s.dailyBest(date)}'
                                        : 'Same workout for everyone, today only',
                                    style: Study.body(12,
                                        theme: t, color: t.muted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        WoodButton(
                          label: s.dailyDone(date)
                              ? '🔁  Beat ${s.dailyBest(date)}'
                              : '▶  Play today\'s challenge',
                          theme: t,
                          width: double.infinity,
                          small: true,
                          onTap: () => _startWorkout(daily: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Training setup: difficulty per mini-game.
                  StudyCard(
                    theme: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Training setup',
                            style: Study.display(18, theme: t)),
                        const SizedBox(height: 4),
                        Text(
                          'Pick a difficulty for each exercise.',
                          style:
                              Study.body(12, theme: t, color: t.muted),
                        ),
                        const SizedBox(height: 8),
                        for (final m in MiniGame.values)
                          _DifficultyRow(
                            mini: m,
                            theme: t,
                            value: s.difficulty[m]!,
                            isPro: s.isPro,
                            onPick: (v) {
                              widget.audio.click();
                              s.setDifficulty(m, v);
                            },
                            onLocked: () => _open(ProScreen(
                              audio: widget.audio,
                              settings: s,
                              store: widget.store,
                            )),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  WoodButton(
                    label: '💪  Start workout',
                    theme: t,
                    width: double.infinity,
                    onTap: () => _startWorkout(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MenuTile(
                          theme: t,
                          emoji: '🎨',
                          label: 'Themes',
                          onTap: () => _open(ThemeScreen(
                            audio: widget.audio,
                            settings: s,
                            store: widget.store,
                          )),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MenuTile(
                          theme: t,
                          emoji: '⚙️',
                          label: 'Settings',
                          onTap: () => _open(SettingsScreen(
                            audio: widget.audio,
                            settings: s,
                            store: widget.store,
                          )),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MenuTile(
                          theme: t,
                          emoji: '📖',
                          label: 'How to play',
                          onTap: () => _showHowTo(t),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHowTo(GymThemeDef t) {
    widget.audio.click();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: t.woodMid,
        title: Text('How to play', style: Study.display(20, theme: t)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final m in MiniGame.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RichText(
                    text: TextSpan(
                      style: Study.body(14, theme: t),
                      children: [
                        TextSpan(
                          text: '${m.emoji} ${m.title}\n',
                          style: Study.body(14, theme: t)
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: m.blurb),
                      ],
                    ),
                  ),
                ),
              Text(
                'Finish all three exercises to earn your Brain Score. '
                'Tapping early in Quick Tap adds a +1500ms penalty. '
                'In Color Clash on Medium/Hard, slow answers count as wrong!',
                style: Study.body(13, theme: t, color: t.muted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Got it!', style: Study.label(13, theme: t)),
          ),
        ],
      ),
    );
  }
}

class _DifficultyRow extends StatelessWidget {
  final MiniGame mini;
  final GymThemeDef theme;
  final int value;
  final bool isPro;
  final ValueChanged<int> onPick;
  final VoidCallback onLocked;
  const _DifficultyRow({
    required this.mini,
    required this.theme,
    required this.value,
    required this.isPro,
    required this.onPick,
    required this.onLocked,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(mini.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mini.title, style: Study.body(14, theme: theme)),
          ),
          for (int i = 0; i < 3; i++)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GestureDetector(
                onTap: () {
                  if (i == 2 && !isPro) {
                    onLocked();
                  } else {
                    onPick(i);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: value == i
                        ? theme.accent.withValues(alpha: 0.9)
                        : Colors.black.withValues(alpha: 0.35),
                    border: Border.all(
                      color: value == i
                          ? theme.accentLight
                          : theme.accent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (i == 2 && !isPro)
                        Padding(
                          padding: const EdgeInsets.only(right: 3),
                          child: Icon(
                            Icons.lock,
                            size: 11,
                            color: theme.accentLight,
                          ),
                        ),
                      Text(
                        DifficultyTable.names[i],
                        style: Study.label(11, theme: theme).copyWith(
                          color: value == i
                              ? theme.woodDeep
                              : theme.accentLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final GymThemeDef theme;
  final String emoji;
  final String label;
  final VoidCallback onTap;
  const _MenuTile({
    required this.theme,
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.woodMid.withValues(alpha: 0.9),
              theme.woodDeep.withValues(alpha: 0.92),
            ],
          ),
          border: Border.all(
            color: theme.accent.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              offset: const Offset(0, 4),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 4),
            Text(label, style: Study.label(12, theme: theme)),
          ],
        ),
      ),
    );
  }
}
