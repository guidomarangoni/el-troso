// El Troso - definizione del Path "S sentiero" del logo (Fase 4.5.l).
//
// La S del logo "EL TROSO" non e' la lettera tipografica: e' un sentiero
// stilizzato che serpeggia. Questa funzione ritorna il Path Flutter
// scalato a un rect normalizzato 0..1, cosi' che chi consuma puo'
// scalarlo a qualunque dimensione (logo grande, mark in icona, S nel
// loader animato).
//
// Il path serpeggia top-right → middle-left → middle-right → bottom-left
// con curve cubic morbide, simulando un sentiero che scende lungo un
// pendio. La forma e' OPEN (non chiusa), per essere disegnata in stroke
// (path tracing nel loader).
//
// Le curve sono state calibrate visualmente sul mockup di branding di
// Guido del 2026-04-25. Tuning futuro lasciato come polish v1.x.
//
// Uso tipico:
//   final p = Path()..addPath(buildTrosoPath(size), Offset.zero);
//   canvas.drawPath(p, paintStroke);

import 'package:flutter/material.dart';

/// Costruisce il Path della "S sentiero" centrato in un rect [size]×[size].
/// Il path va da circa (0.78, 0.08) a (0.22, 0.92) — tre swing morbidi.
Path buildTrosoPath(double size) {
  final s = size;
  return Path()
    ..moveTo(s * 0.78, s * 0.08)
    // primo swing: top-right → upper-left
    ..cubicTo(
      s * 0.30, s * 0.10,
      s * 0.18, s * 0.30,
      s * 0.45, s * 0.42,
    )
    // secondo swing: upper-left → middle-right
    ..cubicTo(
      s * 0.78, s * 0.52,
      s * 0.92, s * 0.68,
      s * 0.55, s * 0.78,
    )
    // terzo swing: middle-right → bottom-left
    ..cubicTo(
      s * 0.22, s * 0.85,
      s * 0.18, s * 0.90,
      s * 0.22, s * 0.92,
    );
}

/// Costruisce il Path del cerchio outline esterno usato dal loader.
/// Centrato e largo [size]; thickness e' settato dal Paint del caller.
Path buildLoaderRing(double size) {
  final r = size / 2 - 2;
  return Path()
    ..addOval(Rect.fromCircle(
      center: Offset(size / 2, size / 2),
      radius: r,
    ));
}
