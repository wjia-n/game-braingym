import 'package:flutter/material.dart';
import 'gym_themes.dart';

/// The Scholar's Workshop design system: warm wood, brass fittings, paper
/// cards. Every surface reads as a real physical material with depth,
/// bevels and soft shadows. No neon, no gradients-for-show.
class Study {
  static const displayFont = 'serif';

  static TextStyle display(double size, {GymThemeDef? theme, Color? color}) =>
      TextStyle(
        fontFamily: displayFont,
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color ?? theme?.ink ?? const Color(0xFFF5EFE0),
        letterSpacing: 0.5,
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.45),
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      );

  static TextStyle body(double size, {GymThemeDef? theme, Color? color}) =>
      TextStyle(
        fontSize: size,
        color: color ?? theme?.ink ?? const Color(0xFFF5EFE0),
        height: 1.35,
      );

  static TextStyle label(double size, {GymThemeDef? theme, Color? color}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: color ?? theme?.accentLight ?? const Color(0xFFE8CE7A),
      );

  static ThemeData theme([GymThemeDef? t]) {
    final th = t ?? GymThemes.all.first;
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: th.woodDark,
      colorScheme: ColorScheme.dark(
        primary: th.accent,
        secondary: th.accentLight,
        surface: th.woodMid,
        onSurface: th.ink,
      ),
      textTheme: TextTheme(
        displayLarge: display(32, theme: th),
        bodyMedium: body(15, theme: th),
        labelLarge: label(14, theme: th),
      ),
    );
  }
}

/// Full-screen wooden desk backdrop with painted grain + vignette.
class WoodBackdrop extends StatelessWidget {
  final GymThemeDef theme;
  final Widget child;
  const WoodBackdrop({super.key, required this.theme, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.woodMid, theme.woodDark, theme.woodDeep],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
      child: CustomPaint(
        painter: _WoodGrainPainter(tint: theme.woodDeep),
        child: child,
      ),
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  final Color tint;
  _WoodGrainPainter({required this.tint});

  @override
  void paint(Canvas canvas, Size size) {
    // Subtle vertical grain streaks.
    final p = Paint()
      ..color = tint.withValues(alpha: 0.16)
      ..strokeWidth = 2.5;
    for (double x = 12; x < size.width; x += 34) {
      final wobble = 6 * (x % 71) / 71;
      canvas.drawLine(
        Offset(x + wobble, 0),
        Offset(x - wobble, size.height),
        p,
      );
    }
    // Vignette: darker corners pull focus to the center.
    final rect = Offset.zero & size;
    final v = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.85,
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.42)],
      ).createShader(rect);
    canvas.drawRect(rect, v);
  }

  @override
  bool shouldRepaint(covariant _WoodGrainPainter old) =>
      old.tint != tint;
}

/// Chunky wooden button with brass rim and press-down physicality.
class WoodButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final GymThemeDef theme;
  final double width;
  final bool small;
  const WoodButton({
    super.key,
    required this.label,
    required this.onTap,
    required this.theme,
    this.width = 240,
    this.small = false,
  });

  @override
  State<WoodButton> createState() => _WoodButtonState();
}

class _WoodButtonState extends State<WoodButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.width,
        padding: EdgeInsets.symmetric(
          vertical: widget.small ? 9 : 15,
          horizontal: 18,
        ),
        transform: Matrix4.translationValues(0, _down ? 3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _down
                ? [t.accentDark, t.accent]
                : [t.accentLight, t.accent, t.accentDark],
            stops: _down ? const [0.0, 1.0] : const [0.0, 0.55, 1.0],
          ),
          border: Border.all(color: t.woodDeep, width: 2.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _down ? 0.25 : 0.55),
              offset: Offset(0, _down ? 2 : 6),
              blurRadius: _down ? 6 : 12,
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.22),
              offset: const Offset(0, 1.5),
              blurRadius: 1,
            ),
          ],
        ),
        child: Text(
          widget.label,
          textAlign: TextAlign.center,
          style: Study.label(widget.small ? 14 : 17, theme: t).copyWith(
            color: t.woodDeep,
            shadows: [
              Shadow(
                color: Colors.white.withValues(alpha: 0.35),
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Brass name plaque: engraved-look label strip.
class BrassPlaque extends StatelessWidget {
  final String text;
  final GymThemeDef theme;
  final double fontSize;
  const BrassPlaque({
    super.key,
    required this.text,
    required this.theme,
    this.fontSize = 15,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.accentLight, theme.accent, theme.accentDark],
        ),
        border: Border.all(color: theme.woodDeep, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            offset: const Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: Study.label(fontSize, theme: theme).copyWith(
          color: theme.woodDeep,
          shadows: [
            Shadow(
              color: Colors.white.withValues(alpha: 0.35),
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wooden panel card.
class StudyCard extends StatelessWidget {
  final GymThemeDef theme;
  final Widget child;
  final EdgeInsetsGeometry padding;
  const StudyCard({
    super.key,
    required this.theme,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.woodMid.withValues(alpha: 0.92),
            theme.woodDeep.withValues(alpha: 0.94),
          ],
        ),
        border: Border.all(
          color: theme.accent.withValues(alpha: 0.55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            offset: const Offset(0, 5),
            blurRadius: 12,
          ),
        ],
      ),
      child: child,
    );
  }
}

class StudyToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final GymThemeDef theme;
  const StudyToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 58,
        height: 32,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: value
              ? theme.accent.withValues(alpha: 0.85)
              : Colors.black.withValues(alpha: 0.45),
          border: Border.all(color: theme.accentDark, width: 1.5),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [theme.accentLight, theme.accent],
              ),
              border: Border.all(color: theme.woodDeep, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

class BeadSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final GymThemeDef theme;
  const BeadSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 8,
        activeTrackColor: theme.accent,
        inactiveTrackColor: Colors.black.withValues(alpha: 0.45),
        thumbShape: _BeadThumb(theme: theme),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: Slider(value: value, onChanged: onChanged),
    );
  }
}

class _BeadThumb extends SliderComponentShape {
  final GymThemeDef theme;
  _BeadThumb({required this.theme});

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(26, 26);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final r = 13.0;
    final grad = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [theme.accentLight, theme.accent, theme.accentDark],
    ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, Paint()..shader = grad);
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = theme.woodDeep,
    );
  }
}

class SettingRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget trailing;
  final GymThemeDef theme;
  const SettingRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.trailing,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Study.body(15, theme: theme)),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Study.body(12, theme: theme, color: theme.muted),
                  ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

/// Small "PRO" lock badge.
class LockBadge extends StatelessWidget {
  final GymThemeDef theme;
  const LockBadge({super.key, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withValues(alpha: 0.55),
        border: Border.all(color: theme.accent, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock, size: 11, color: theme.accentLight),
          const SizedBox(width: 3),
          Text('PRO', style: Study.label(10, theme: theme)),
        ],
      ),
    );
  }
}
