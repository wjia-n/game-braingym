import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/gym_themes.dart';
import '../theme/study_widgets.dart';
import 'pro_screen.dart';

/// Theme + tile-style picker, plus the custom theme creator (Pro).
class ThemeScreen extends StatefulWidget {
  final BrainAudio audio;
  final GymSettings settings;
  final StoreService store;
  const ThemeScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  GymThemeDef get _t => GymThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  void _goPro() {
    widget.audio.click();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProScreen(
          audio: widget.audio,
          settings: widget.settings,
          store: widget.store,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
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
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Workshop Themes', style: Study.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Study themes',
                      style: Study.display(18, theme: t)),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.35,
                    children: [
                      for (final th in GymThemes.all)
                        _themeCard(th, t, s),
                      _customCard(t, s),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text('Tile styles',
                      style: Study.display(18, theme: t)),
                  const SizedBox(height: 4),
                  Text(
                    'The physical faces of your memory tiles.',
                    style: Study.body(12, theme: t, color: t.muted),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (int i = 0; i < TileStyles.all.length; i++)
                        _styleChip(i, t, s),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (s.isPro) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text('Custom theme creator',
                              style: Study.display(18, theme: t)),
                        ),
                        TextButton(
                          onPressed: () {
                            widget.audio.click();
                            s.resetCustomColors();
                          },
                          child: Text('Reset',
                              style: Study.label(12, theme: t)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    StudyCard(
                      theme: t,
                      child: Column(
                        children: [
                          for (final k in _customKeys)
                            _colorRow(k, t, s),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your creation applies instantly when “My Creation” is selected above.',
                      style: Study.body(12, theme: t, color: t.muted),
                    ),
                  ] else
                    StudyCard(
                      theme: t,
                      child: Row(
                        children: [
                          Icon(Icons.lock,
                              color: t.accentLight, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'The custom theme creator is a PRO feature.',
                              style: Study.body(13, theme: t),
                            ),
                          ),
                          TextButton(
                            onPressed: _goPro,
                            child: Text('Go PRO',
                                style: Study.label(12, theme: t)),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _themeCard(GymThemeDef th, GymThemeDef t, GymSettings s) {
    final locked = !s.isPro && GymThemes.isProTheme(th.id);
    final selected = s.themeId == th.id;
    return GestureDetector(
      onTap: () {
        if (locked) {
          _goPro();
        } else {
          widget.audio.click();
          s.setTheme(th.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [th.woodMid, th.woodDeep],
          ),
          border: Border.all(
            color: selected ? t.accentLight : th.accent.withValues(alpha: 0.4),
            width: selected ? 3 : 1.5,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    th.name,
                    style: Study.body(13, theme: th)
                        .copyWith(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (locked)
                  Icon(Icons.lock, size: 14, color: th.accentLight)
                else if (selected)
                  Icon(Icons.check_circle,
                      size: 16, color: th.accentLight),
              ],
            ),
            const Spacer(),
            Row(
              children: [
                for (final c in [
                  th.woodMid,
                  th.accent,
                  th.paper,
                  th.felt,
                  th.tileLight,
                ])
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(right: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c,
                      border: Border.all(
                        color: Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _customCard(GymThemeDef t, GymSettings s) {
    final selected = s.themeId == 'custom';
    final locked = !s.isPro;
    return GestureDetector(
      onTap: () {
        if (locked) {
          _goPro();
        } else {
          widget.audio.click();
          s.setTheme('custom');
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              s.customTheme.woodMid,
              s.customTheme.woodDeep,
            ],
          ),
          border: Border.all(
            color: selected ? t.accentLight : t.accent.withValues(alpha: 0.4),
            width: selected ? 3 : 1.5,
            style: BorderStyle.solid,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'My Creation',
                    style: Study.body(13, theme: t)
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                if (locked)
                  Icon(Icons.lock, size: 14, color: t.accentLight)
                else if (selected)
                  Icon(Icons.check_circle,
                      size: 16, color: t.accentLight),
              ],
            ),
            const Spacer(),
            Text(
              locked ? 'Design your own (PRO)' : 'Your custom palette',
              style: Study.body(11, theme: t, color: t.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _styleChip(int i, GymThemeDef t, GymSettings s) {
    final st = TileStyles.byIndex(i);
    final locked = !s.isPro && TileStyles.isPro(i);
    final selected = s.tileStyle == i;
    return GestureDetector(
      onTap: () {
        if (locked) {
          _goPro();
        } else {
          widget.audio.click();
          s.setTileStyle(i);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [st.light, st.dark],
          ),
          border: Border.all(
            color: selected ? t.accentLight : st.edge,
            width: selected ? 3 : 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (locked)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.lock, size: 12, color: Colors.white70),
              ),
            Text(
              st.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(0, 1),
                    blurRadius: 3,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorRow(String key, GymThemeDef t, GymSettings s) {
    const labels = {
      'woodDark': 'Backdrop dark',
      'woodMid': 'Panels',
      'woodDeep': 'Deep shadow',
      'accent': 'Accent metal',
      'accentLight': 'Accent light',
      'accentDark': 'Accent dark',
      'paper': 'Paper',
      'paperInk': 'Paper ink',
      'felt': 'Board felt',
      'tileLight': 'Tile light',
      'tileDark': 'Tile dark',
      'ink': 'Text ink',
      'muted': 'Muted text',
    };
    const palette = [
      0xFF3B2416, 0xFF5C3A21, 0xFF8A6A3D, 0xFFC9A227, 0xFFE8CE7A,
      0xFFF5EFE0, 0xFF1E4D3B, 0xFF1B2A4A, 0xFFB03A2E, 0xFFD97B2E,
      0xFF3A3F45, 0xFFC0C6D4, 0xFF2A1B10, 0xFF6E4F2E, 0xFF4E2E1E,
    ];
    final current = s.customColors[key] ?? 0xFF000000;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: Color(current),
              border: Border.all(color: t.accent, width: 1.5),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(labels[key] ?? key,
                style: Study.body(14, theme: t)),
          ),
          GestureDetector(
            onTap: () async {
              final picked = await showDialog<int>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: t.woodMid,
                  title: Text(labels[key] ?? key,
                      style: Study.display(18, theme: t)),
                  content: SizedBox(
                    width: 280,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final c in palette)
                          GestureDetector(
                            onTap: () => Navigator.of(ctx).pop(c),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(10),
                                color: Color(c),
                                border: Border.all(
                                  color: c == current
                                      ? t.accentLight
                                      : Colors.black45,
                                  width: c == current ? 3 : 1.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
              if (picked != null) {
                widget.audio.click();
                s.setCustomColor(key, picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: t.accent),
              ),
              child: Text('Change', style: Study.label(12, theme: t)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom-color keys for the theme creator UI.
const _customKeys = [
  'woodDark',
  'woodMid',
  'woodDeep',
  'accent',
  'accentLight',
  'accentDark',
  'paper',
  'paperInk',
  'felt',
  'tileLight',
  'tileDark',
  'ink',
  'muted',
];
