// El Troso - widget logo (Fase 4.5.l).
//
// Versioni:
//   - TrosoLogoMark: solo la S sentiero (per icone, header pillola,
//     favicon, stati piccoli).
//   - TrosoLogoFull: logo completo "EL TROSO" con S come sentiero,
//     colore configurabile (per splash su olive: testo crema; per
//     header su parchment: testo olive).
//
// Il logo e' build-time (no asset, no font custom) — la S e' un
// CustomPaint, il testo e' Text con il font di sistema bold. Cosi':
//   - zero dipendenze nuove
//   - scala perfettamente a qualunque size
//   - colorabile ovunque
//   - leggero (no decoding di SVG/PNG)

import 'package:flutter/material.dart';

import 'troso_path.dart';

/// Solo la S sentiero. [size] e' il lato del quadrato di rendering.
class TrosoLogoMark extends StatelessWidget {
  const TrosoLogoMark({
    super.key,
    this.size = 48,
    required this.color,
    this.strokeWidth = 0,
  });

  final double size;
  final Color color;
  /// Spessore stroke. Se 0, viene calcolato come size/9 (proporzionale).
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MarkPainter(
        color: color,
        strokeWidth: strokeWidth > 0 ? strokeWidth : size / 9,
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final p = buildTrosoPath(size.shortestSide);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;
    canvas.drawPath(p, paint);
  }

  @override
  bool shouldRepaint(covariant _MarkPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}

/// Logo completo "EL TROSO" con la S come sentiero che attraversa il
/// gruppo testuale. Layout (mockup branding 2026-04-25):
///   ┌─────────────┐
///   │  EL    ╱    │
///   │  TRO ╲ O    │   (S e' il sentiero che serpeggia tra TRO e O)
///   │      ╱      │
///   └─────────────┘
///
/// In MVP rendiamo "EL" sopra, "TRO" + S-sentiero + "O" sotto. Il
/// testo e' bianco/crema su sfondo olive (splash), o olive su sfondo
/// parchment (header). [textColor] decide il colore del testo + S.
class TrosoLogoFull extends StatelessWidget {
  const TrosoLogoFull({
    super.key,
    required this.textColor,
    this.fontSize = 56,
  });

  final Color textColor;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final smaller = fontSize * 0.6;
    final markSize = fontSize * 1.2;
    final letterStyle = TextStyle(
      color: textColor,
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -1,
      height: 1.0,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Riga 1: "EL" piccolo, allineato a sinistra.
        Text(
          'EL',
          style: letterStyle.copyWith(fontSize: smaller),
        ),
        const SizedBox(height: 2),
        // Riga 2: "TRO" + mark sentiero + "O".
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('TRO', style: letterStyle),
            // Mark inline al posto della S. Leggermente piu' alto del
            // testo per dare l'impressione del sentiero "che esce
            // sopra". marginTop -8 per far sporgere.
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: TrosoLogoMark(
                size: markSize,
                color: textColor,
                strokeWidth: fontSize / 7,
              ),
            ),
            Text('O', style: letterStyle),
          ],
        ),
      ],
    );
  }
}
