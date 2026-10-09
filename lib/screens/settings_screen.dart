import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/gym_themes.dart';
import '../theme/study_widgets.dart';
import 'pro_screen.dart';

/// Settings: profile name, audio controls, stats, share, rate.
class SettingsScreen extends StatefulWidget {
  final BrainAudio audio;
  final GymSettings settings;
  final StoreService store;
  const SettingsScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  GymThemeDef get _t => GymThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  /// Rename dialog: the name persists on EVERY keystroke (never only on
  /// keyboard-done) and the final value is committed when the field loses
  /// focus or Save is tapped. Backed by the order-safe JSON list key.
  Future<void> _rename() async {
    final s = widget.settings;
    final ctrl = TextEditingController(text: s.playerName);
    final focus = FocusNode();
    void persist() => s.setPlayerName(ctrl.text);
    ctrl.addListener(persist); // every keystroke
    focus.addListener(() {
      if (!focus.hasFocus) persist(); // commit on focus loss
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

  Future<void> _shareApp() async {
    widget.audio.click();
    await Share.share(
      'Train your brain with Brain Gym! 🧠💪\n'
      'https://play.google.com/store/apps/details?id=com.gameswajiha.braingym',
    );
  }

  Future<void> _rateApp() async {
    widget.audio.click();
    try {
      final review = InAppReview.instance;
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(
          appStoreId: 'com.gameswajiha.braingym',
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final a = widget.audio;
    return WoodBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accentLight),
            onPressed: () {
              a.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Settings', style: Study.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  StudyCard(
                    theme: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Profile',
                            style: Study.display(17, theme: t)),
                        SettingRow(
                          title: s.playerName,
                          subtitle: 'Tap to rename your scholar',
                          theme: t,
                          trailing: IconButton(
                            icon: Icon(Icons.edit,
                                color: t.accentLight),
                            onPressed: _rename,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  StudyCard(
                    theme: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Sound & music',
                            style: Study.display(17, theme: t)),
                        SettingRow(
                          title: 'Music',
                          subtitle: 'Workshop melodies',
                          theme: t,
                          trailing: StudyToggle(
                            value: s.musicOn,
                            theme: t,
                            onChanged: (v) {
                              a.click();
                              s.setMusic(v);
                              a.configure(
                                musicOn: v,
                                sfxOn: s.sfxOn,
                                volume: s.volume,
                              );
                              if (v) a.startMenuMusic();
                            },
                          ),
                        ),
                        SettingRow(
                          title: 'Sound effects',
                          subtitle: 'Knocks, flips & chimes',
                          theme: t,
                          trailing: StudyToggle(
                            value: s.sfxOn,
                            theme: t,
                            onChanged: (v) {
                              s.setSfx(v);
                              a.configure(
                                musicOn: s.musicOn,
                                sfxOn: v,
                                volume: s.volume,
                              );
                              if (v) a.click();
                            },
                          ),
                        ),
                        SettingRow(
                          title: 'Volume',
                          theme: t,
                          trailing: SizedBox(
                            width: 170,
                            child: BeadSlider(
                              value: s.volume,
                              theme: t,
                              onChanged: (v) {
                                s.setVolume(v);
                                a.configure(
                                  musicOn: s.musicOn,
                                  sfxOn: s.sfxOn,
                                  volume: v,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  StudyCard(
                    theme: t,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your training',
                            style: Study.display(17, theme: t)),
                        const SizedBox(height: 6),
                        _statRow(t, '🏋️', 'Workouts completed',
                            '${s.gamesPlayed}'),
                        _statRow(t, '🧠', 'Best Brain Score',
                            '${s.bestScore}'),
                        _statRow(t, '📅', "Today's challenge best",
                            '${s.dailyBest(GymSettings.todayKey())}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  StudyCard(
                    theme: t,
                    child: Column(
                      children: [
                        _actionRow(
                          t,
                          Icons.share,
                          'Share Brain Gym',
                          'Tell a friend to train along',
                          _shareApp,
                        ),
                        _actionRow(
                          t,
                          Icons.star,
                          'Rate Brain Gym',
                          'A kind review keeps us going',
                          _rateApp,
                        ),
                        _actionRow(
                          t,
                          Icons.workspace_premium,
                          s.isPro ? 'Brain Gym PRO ✓' : 'Get PRO',
                          s.isPro
                              ? 'Thank you for supporting us!'
                              : 'Unlock everything, forever',
                          () {
                            a.click();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProScreen(
                                  audio: a,
                                  settings: s,
                                  store: widget.store,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Brain Gym v1.1 · Made with ♥ by WAJIHA',
                    style: Study.body(12, theme: t, color: t.muted),
                    textAlign: TextAlign.center,
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

  Widget _statRow(
      GymThemeDef t, String emoji, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: Study.body(14, theme: t))),
          Text(value, style: Study.display(16, theme: t)),
        ],
      ),
    );
  }

  Widget _actionRow(GymThemeDef t, IconData icon, String title,
      String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: t.accentLight, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Study.body(15, theme: t)),
                  Text(subtitle,
                      style: Study.body(12, theme: t, color: t.muted)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: t.muted),
          ],
        ),
      ),
    );
  }
}
