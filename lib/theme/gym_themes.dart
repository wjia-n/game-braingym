import 'package:flutter/material.dart';

/// Theme + tile-style catalog for Brain Gym.
///
/// Art direction: the scholar's workshop — warm oak, brass, leather, paper,
/// chalk and stone. Everything reads as a real physical material with depth
/// and bevels. No neon, no cyberpunk, no AI-dashboard looks.
class GymThemeDef {
  final String id;
  final String name;
  final Color woodDark; // backdrop base
  final Color woodMid; // panels / cards
  final Color woodDeep; // deepest shadow
  final Color accent; // brass / copper / steel …
  final Color accentLight;
  final Color accentDark;
  final Color paper; // light card surface
  final Color paperInk; // text on paper
  final Color felt; // board base behind the tiles
  final Color tileLight; // default tile face (light)
  final Color tileDark; // default tile face (dark)
  final Color ink; // text on dark backgrounds
  final Color muted; // secondary text on dark

  const GymThemeDef({
    required this.id,
    required this.name,
    required this.woodDark,
    required this.woodMid,
    required this.woodDeep,
    required this.accent,
    required this.accentLight,
    required this.accentDark,
    required this.paper,
    required this.paperInk,
    required this.felt,
    required this.tileLight,
    required this.tileDark,
    required this.ink,
    required this.muted,
  });
}

class GymThemes {
  /// First 4 are the FREE starter themes. The rest are PRO.
  static const List<String> freeThemeIds = [
    'classic',
    'mahogany',
    'chalk',
    'parchment',
  ];

  static bool isProTheme(String id) =>
      !freeThemeIds.contains(id) && id != 'custom';

  static const List<GymThemeDef> all = [
    GymThemeDef(
      id: 'classic',
      name: 'Oak Study',
      woodDark: Color(0xFF3B2416),
      woodMid: Color(0xFF5C3A21),
      woodDeep: Color(0xFF241309),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      paper: Color(0xFFF5EFE0),
      paperInk: Color(0xFF2A1B0E),
      felt: Color(0xFF1E4D3B),
      tileLight: Color(0xFFEFE3C8),
      tileDark: Color(0xFFD9C6A0),
      ink: Color(0xFFF5EFE0),
      muted: Color(0xFFB9A582),
    ),
    GymThemeDef(
      id: 'mahogany',
      name: 'Mahogany Library',
      woodDark: Color(0xFF4A1F14),
      woodMid: Color(0xFF6E2F1C),
      woodDeep: Color(0xFF2B1009),
      accent: Color(0xFFD4AF37),
      accentLight: Color(0xFFF3DC8E),
      accentDark: Color(0xFF96702A),
      paper: Color(0xFFF8F1E2),
      paperInk: Color(0xFF2E150B),
      felt: Color(0xFF3D1F2E),
      tileLight: Color(0xFFF2E6CC),
      tileDark: Color(0xFFDBC49A),
      ink: Color(0xFFF8F1E2),
      muted: Color(0xFFC4A17E),
    ),
    GymThemeDef(
      id: 'chalk',
      name: 'Chalkboard',
      woodDark: Color(0xFF232A27),
      woodMid: Color(0xFF333D38),
      woodDeep: Color(0xFF141918),
      accent: Color(0xFFD9B44A),
      accentLight: Color(0xFFF0D47E),
      accentDark: Color(0xFF96702A),
      paper: Color(0xFF3B4742),
      paperInk: Color(0xFFF7F3E6),
      felt: Color(0xFF24302B),
      tileLight: Color(0xFF4C5A53),
      tileDark: Color(0xFF333D38),
      ink: Color(0xFFF7F3E6),
      muted: Color(0xFFA9B3A8),
    ),
    GymThemeDef(
      id: 'parchment',
      name: 'Old Parchment',
      woodDark: Color(0xFF6B4F2A),
      woodMid: Color(0xFF8A6A3D),
      woodDeep: Color(0xFF4A3319),
      accent: Color(0xFF9A6B1F),
      accentLight: Color(0xFFC9973F),
      accentDark: Color(0xFF6E4C14),
      paper: Color(0xFFF6ECD4),
      paperInk: Color(0xFF3D2A12),
      felt: Color(0xFFA9885A),
      tileLight: Color(0xFFFAF2DC),
      tileDark: Color(0xFFE3CFA3),
      ink: Color(0xFFF6ECD4),
      muted: Color(0xFFD3BC90),
    ),
    GymThemeDef(
      id: 'midnight',
      name: 'Midnight Oil',
      woodDark: Color(0xFF1C2438),
      woodMid: Color(0xFF2C3A55),
      woodDeep: Color(0xFF101624),
      accent: Color(0xFFC0C6D4),
      accentLight: Color(0xFFE8ECF5),
      accentDark: Color(0xFF7E8698),
      paper: Color(0xFFF2EEE4),
      paperInk: Color(0xFF1B2436),
      felt: Color(0xFF1B2A4A),
      tileLight: Color(0xFF3B4C6E),
      tileDark: Color(0xFF27334B),
      ink: Color(0xFFF2EEE4),
      muted: Color(0xFF9AA3B8),
    ),
    GymThemeDef(
      id: 'emerald',
      name: 'Emerald Reading Room',
      woodDark: Color(0xFF2E3B22),
      woodMid: Color(0xFF4A5A34),
      woodDeep: Color(0xFF1A2312),
      accent: Color(0xFFC9A227),
      accentLight: Color(0xFFE8CE7A),
      accentDark: Color(0xFF8A6D1A),
      paper: Color(0xFFF1EAD8),
      paperInk: Color(0xFF2A3319),
      felt: Color(0xFF1E4D3B),
      tileLight: Color(0xFFDCE8CF),
      tileDark: Color(0xFFA9BE92),
      ink: Color(0xFFF1EAD8),
      muted: Color(0xFFA9B893),
    ),
    GymThemeDef(
      id: 'brass',
      name: 'Brass Laboratory',
      woodDark: Color(0xFF4A3B22),
      woodMid: Color(0xFF6B5530),
      woodDeep: Color(0xFF2B2010),
      accent: Color(0xFFE0B13C),
      accentLight: Color(0xFFF7DC8E),
      accentDark: Color(0xFF9A7218),
      paper: Color(0xFFF6EEDD),
      paperInk: Color(0xFF3A2C10),
      felt: Color(0xFF5C4A26),
      tileLight: Color(0xFFF0DFB8),
      tileDark: Color(0xFFCDAF74),
      ink: Color(0xFFF6EEDD),
      muted: Color(0xFFC9B78C),
    ),
    GymThemeDef(
      id: 'botanical',
      name: 'Botanical Study',
      woodDark: Color(0xFF3E4A2A),
      woodMid: Color(0xFF5C6B3E),
      woodDeep: Color(0xFF262D16),
      accent: Color(0xFFB98A2F),
      accentLight: Color(0xFFE0B96A),
      accentDark: Color(0xFF7E5C1C),
      paper: Color(0xFFF4EFDF),
      paperInk: Color(0xFF33401E),
      felt: Color(0xFF2F4A2E),
      tileLight: Color(0xFFE7EAD2),
      tileDark: Color(0xFFBCC394),
      ink: Color(0xFFF4EFDF),
      muted: Color(0xFFB3BA90),
    ),
    GymThemeDef(
      id: 'slate',
      name: 'Slate Workshop',
      woodDark: Color(0xFF3A3F45),
      woodMid: Color(0xFF51575E),
      woodDeep: Color(0xFF23262B),
      accent: Color(0xFFD97B2E),
      accentLight: Color(0xFFEFA763),
      accentDark: Color(0xFF96511A),
      paper: Color(0xFFF0EDE6),
      paperInk: Color(0xFF2B2E33),
      felt: Color(0xFF2E3338),
      tileLight: Color(0xFF6B7278),
      tileDark: Color(0xFF484D53),
      ink: Color(0xFFF0EDE6),
      muted: Color(0xFFA7ADB3),
    ),
    GymThemeDef(
      id: 'copper',
      name: 'Copper Kitchen',
      woodDark: Color(0xFF4E2E1E),
      woodMid: Color(0xFF70422B),
      woodDeep: Color(0xFF2D1810),
      accent: Color(0xFFC97B4A),
      accentLight: Color(0xFFE8A87E),
      accentDark: Color(0xFF8F4E2A),
      paper: Color(0xFFF7EFE2),
      paperInk: Color(0xFF3E2414),
      felt: Color(0xFF5E3620),
      tileLight: Color(0xFFF3DCC6),
      tileDark: Color(0xFFD3A87E),
      ink: Color(0xFFF7EFE2),
      muted: Color(0xFFCDA98E),
    ),
    GymThemeDef(
      id: 'walnut',
      name: 'Walnut Night',
      woodDark: Color(0xFF2A1B10),
      woodMid: Color(0xFF42301E),
      woodDeep: Color(0xFF150D06),
      accent: Color(0xFFD4A24A),
      accentLight: Color(0xFFEBCB8E),
      accentDark: Color(0xFF8F6224),
      paper: Color(0xFFEFE3CC),
      paperInk: Color(0xFF2E1F0E),
      felt: Color(0xFF332415),
      tileLight: Color(0xFF5C4630),
      tileDark: Color(0xFF3A2C1C),
      ink: Color(0xFFEFE3CC),
      muted: Color(0xFFA68E6C),
    ),
    GymThemeDef(
      id: 'typewriter',
      name: 'Vintage Typewriter',
      woodDark: Color(0xFF2E2A26),
      woodMid: Color(0xFF453F37),
      woodDeep: Color(0xFF191614),
      accent: Color(0xFFB03A2E),
      accentLight: Color(0xFFD96A5E),
      accentDark: Color(0xFF7A231B),
      paper: Color(0xFFF5EFDD),
      paperInk: Color(0xFF2E2A24),
      felt: Color(0xFF3A352E),
      tileLight: Color(0xFF575046),
      tileDark: Color(0xFF37322B),
      ink: Color(0xFFF5EFDD),
      muted: Color(0xFFB0A894),
    ),
  ];

  static GymThemeDef byId(String id, {GymThemeDef? custom}) {
    if (id == 'custom' && custom != null) return custom;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }
}

/// Physical tile-face styles for the memory board. First 4 are FREE,
/// the rest are PRO. Every style keeps the physical, tactile feel.
class TileStyleDef {
  final String id;
  final String name;
  final Color light;
  final Color dark;
  final Color edge;

  const TileStyleDef({
    required this.id,
    required this.name,
    required this.light,
    required this.dark,
    required this.edge,
  });
}

class TileStyles {
  static const List<String> freeIds = ['oak', 'ivory', 'chalk', 'slate'];

  static bool isPro(int index) => index >= freeIds.length;

  static const List<TileStyleDef> all = [
    TileStyleDef(
      id: 'oak',
      name: 'Oak',
      light: Color(0xFFD9B87C),
      dark: Color(0xFFB08D54),
      edge: Color(0xFF7A5C33),
    ),
    TileStyleDef(
      id: 'ivory',
      name: 'Ivory',
      light: Color(0xFFF7F1E3),
      dark: Color(0xFFE2D5B8),
      edge: Color(0xFFB3A37E),
    ),
    TileStyleDef(
      id: 'chalk',
      name: 'Chalk',
      light: Color(0xFFF2F0EA),
      dark: Color(0xFFD5D2C8),
      edge: Color(0xFF9A978C),
    ),
    TileStyleDef(
      id: 'slate',
      name: 'Slate',
      light: Color(0xFF6B7280),
      dark: Color(0xFF434A54),
      edge: Color(0xFF2B3038),
    ),
    TileStyleDef(
      id: 'brass',
      name: 'Brass',
      light: Color(0xFFE3B94E),
      dark: Color(0xFFB08630),
      edge: Color(0xFF7A5C1E),
    ),
    TileStyleDef(
      id: 'leather',
      name: 'Leather',
      light: Color(0xFF8A5A33),
      dark: Color(0xFF5F3A1E),
      edge: Color(0xFF3D2410),
    ),
    TileStyleDef(
      id: 'paper',
      name: 'Paper',
      light: Color(0xFFFFFBF0),
      dark: Color(0xFFD8CFB8),
      edge: Color(0xFFA89B7E),
    ),
    TileStyleDef(
      id: 'marble',
      name: 'Marble',
      light: Color(0xFFEDEAE2),
      dark: Color(0xFFBDB8AC),
      edge: Color(0xFF8E8A80),
    ),
    TileStyleDef(
      id: 'copper',
      name: 'Copper',
      light: Color(0xFFE0995E),
      dark: Color(0xFFB26A38),
      edge: Color(0xFF7A4522),
    ),
    TileStyleDef(
      id: 'walnut',
      name: 'Walnut',
      light: Color(0xFF6E4F2E),
      dark: Color(0xFF4A3319),
      edge: Color(0xFF2C1D0C),
    ),
  ];

  static TileStyleDef byIndex(int i) => all[i.clamp(0, all.length - 1)];
}
