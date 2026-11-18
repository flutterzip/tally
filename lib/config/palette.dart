import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Every UI colour in Tally is defined in this file.
//
// To re-skin the app, edit [Palette.light] and [Palette.dark] below. Every
// screen, the cards, the receipt and the keypad read their colours from
// here through `context.palette`.
//
// The system: warm paper, violet-black ink and exactly one accent (a deep
// electric violet). Cards are drawn in steps of that one accent. Ink is
// never pure black and paper is never pure white.
// ---------------------------------------------------------------------------

@immutable
class Palette extends ThemeExtension<Palette> {
  const Palette({
    required this.paper,
    required this.card,
    required this.ink,
    required this.inkSoft,
    required this.muted,
    required this.line,
    required this.field,
    required this.accent,
    required this.accentDeep,
    required this.accentGlow,
    required this.onAccent,
    required this.accentWash,
    required this.error,
    required this.eye,
    required this.face,
    required this.shadow,
    required this.scrim,
  });

  /// The page ground.
  final Color paper;

  /// Raised surfaces: rows, sheets, the keypad keys, the receipt paper.
  final Color card;

  /// Headlines and primary type.
  final Color ink;

  /// Body copy.
  final Color inkSoft;

  /// Hints, captions, inactive icons.
  final Color muted;

  /// Hairlines and resting field borders.
  final Color line;

  /// The fill of a field at rest.
  final Color field;

  /// The one accent: buttons, the balance, money coming in, the chosen card.
  final Color accent;

  /// Pressed and emphasised accent.
  final Color accentDeep;

  /// A lighter accent for glows and gradients.
  final Color accentGlow;

  /// Type and icons on top of [accent].
  final Color onAccent;

  /// A pale tint of the accent for selected states and notices.
  final Color accentWash;

  /// Errors stay in the family: a deeper, redder neighbour of the accent.
  final Color error;

  /// The brightest highlight (the shine on a card).
  final Color eye;

  /// The darkest ink, the same in both modes.
  final Color face;

  /// Shadows under raised surfaces.
  final Color shadow;

  /// Behind sheets.
  final Color scrim;

  static const light = Palette(
    paper: Color(0xFFF4F2EE),
    card: Color(0xFFFFFEFB),
    ink: Color(0xFF17151F),
    inkSoft: Color(0xFF4A4757),
    muted: Color(0xFF8B8898),
    line: Color(0xFFE4E1EA),
    field: Color(0xFFECEAF0),
    accent: Color(0xFF5B47E0),
    accentDeep: Color(0xFF3F2DB8),
    accentGlow: Color(0xFF9C8DFF),
    onAccent: Color(0xFFF7F5FF),
    accentWash: Color(0xFFE7E3FD),
    error: Color(0xFFC2416B),
    eye: Color(0xFFFFFFFF),
    face: Color(0xFF17151F),
    shadow: Color(0x2E1F1A3A),
    scrim: Color(0x6617151F),
  );

  static const dark = Palette(
    paper: Color(0xFF0F0E14),
    card: Color(0xFF18171F),
    ink: Color(0xFFEFEDF6),
    inkSoft: Color(0xFFC6C3D3),
    muted: Color(0xFF8A8799),
    line: Color(0xFF27252F),
    field: Color(0xFF1E1D26),
    accent: Color(0xFF9A8CFF),
    accentDeep: Color(0xFF7563F0),
    accentGlow: Color(0xFFC3B9FF),
    onAccent: Color(0xFF140B3D),
    accentWash: Color(0xFF231E3F),
    error: Color(0xFFF08AA6),
    eye: Color(0xFFFFFFFF),
    face: Color(0xFF17151F),
    shadow: Color(0x66000000),
    scrim: Color(0x99000000),
  );

  @override
  Palette copyWith() => this;

  @override
  Palette lerp(Palette? other, double t) {
    if (other == null) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return Palette(
      paper: c(paper, other.paper),
      card: c(card, other.card),
      ink: c(ink, other.ink),
      inkSoft: c(inkSoft, other.inkSoft),
      muted: c(muted, other.muted),
      line: c(line, other.line),
      field: c(field, other.field),
      accent: c(accent, other.accent),
      accentDeep: c(accentDeep, other.accentDeep),
      accentGlow: c(accentGlow, other.accentGlow),
      onAccent: c(onAccent, other.onAccent),
      accentWash: c(accentWash, other.accentWash),
      error: c(error, other.error),
      eye: c(eye, other.eye),
      face: c(face, other.face),
      shadow: c(shadow, other.shadow),
      scrim: c(scrim, other.scrim),
    );
  }
}

extension PaletteContext on BuildContext {
  Palette get palette => Theme.of(this).extension<Palette>()!;
}
