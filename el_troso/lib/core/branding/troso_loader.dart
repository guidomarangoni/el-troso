// El Troso - loader animato "il sentiero si forma" (Fase 4.5.l).
//
// E' la chicca grafica che Guido ha richiesto: invece di uno spinner
// generico, durante operazioni lunghe (caricamento modello Gemma 4 al
// primo avvio, copia asset → external dir, ~2.6 GB) mostriamo un
// CERCHIO outline che si chiude progressivamente, e DENTRO la S
// sentiero del logo che si TRACCIA da capo a coda al ritmo del
// progress.
//
// Ispirato letteralmente al mockup branding del 2026-04-25 sezione
// "Indicatore di caricamento" (6 stati 0%→100% con anello + S che si
// riempie).
//
// Due modalita' d'uso:
//   - PROGRESS DETERMINATO: passa [progress] da 0.0 a 1.0 (es. download
//     bytes / total bytes). Il loader si aggiorna in modo lineare,
//     con interpolazione smooth via TweenAnimationBuilder per evitare
//     scatti.
//   - INDETERMINATO: passa progress=null. Il sentiero si traccia in
//     loop continuo (~1.5s ciclo), simulando "qualcosa sta succedendo"
//     senza bytes counter (es. inferenza Gemma in corso).
//
// Composizione:
//   - Cerchio esterno: stroke chiaro a 100% (ghost), sopra un arc che
//     copre da 0 a 2*pi*progress in colore primary.
//   - S sentiero centrale: path tracing 0 a 1.0 della lunghezza totale.
//
// Sotto, opzionale: label tipo "Sto preparando il sentiero..." +
// percentuale numerica grande.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'troso_path.dart';

class TrosoLoader extends StatefulWidget {
  const TrosoLoader({
    super.key,
    this.size = 120,
    this.progress,
    this.color,
    this.ringColor,
  });

  /// Lato del quadrato di rendering. 120 e' il default raccomandato
  /// per splash screen.
  final double size;

  /// Se non null: progress 0..1 (determinato).
  /// Se null: animazione indeterminata in loop.
  final double? progress;

  /// Colore primario (S + arc). Default: theme.colorScheme.primary
  /// se [Theme] e' disponibile, altrimenti olive #6B7F5A.
  final Color? color;

  /// Colore del ring "spento" sotto l'arc. Default: tertiary a opacity 0.25.
  final Color? ringColor;

  @override
  State<TrosoLoader> createState() => _TrosoLoaderState();
}

class _TrosoLoaderState extends State<TrosoLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    // Modalita' indeterminata: 1.5s loop. Quando progress != null il
    // controller resta a 0 (non viene letto) ma lo teniamo comunque
    // attivo per evitare hot-toggle se progress passa a null.
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.progress == null) {
      _ctrl.repeat();
    }
  }

  @override
  void didUpdateWidget(TrosoLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasIndeterminate = oldWidget.progress == null;
    final isIndeterminate = widget.progress == null;
    if (isIndeterminate && !wasIndeterminate) {
      _ctrl.repeat();
    } else if (!isIndeterminate && wasIndeterminate) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.color ?? theme.colorScheme.primary;
    final ringColor = widget.ringColor ??
        theme.colorScheme.tertiary.withValues(alpha: 0.25);

    if (widget.progress != null) {
      // Determinato: rebuild con TweenAnimationBuilder per smoothing
      // quando progress salta (es. da 0.30 a 0.45).
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: widget.progress!.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        builder: (_, value, _) => CustomPaint(
          size: Size.square(widget.size),
          painter: _LoaderPainter(
            progress: value,
            color: color,
            ringColor: ringColor,
          ),
        ),
      );
    }

    // Indeterminato: l'animazione "scrive" la S poi resetta. La fase 0..1
    // viene mappata su (1) il tracing della S, (2) un fade out lieve nel
    // 10% finale per far percepire il "loop" senza scatto secco.
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) {
        // Triangolare: 0→0.5 traccia, 0.5→1.0 mantiene + cerchio si
        // riempie. Il reset al loop avviene fluido.
        final t = _ctrl.value;
        final pathPart = (t * 2).clamp(0.0, 1.0);
        // ringPart parte solo dopo aver tracciato il sentiero, cosi' il
        // ciclo visivo e' "prima il sentiero, poi l'anello chiude".
        final ringPart = ((t - 0.4) * 2).clamp(0.0, 1.0);
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _LoaderPainter(
            progress: ringPart,
            sentieroProgress: pathPart,
            color: color,
            ringColor: ringColor,
          ),
        );
      },
    );
  }
}

class _LoaderPainter extends CustomPainter {
  _LoaderPainter({
    required this.progress,
    required this.color,
    required this.ringColor,
    double? sentieroProgress,
  }) : sentieroProgress = sentieroProgress ?? progress;

  /// 0..1. Riempie l'anello esterno.
  final double progress;
  /// 0..1. Traccia la S del sentiero. In modalita' determinata coincide
  /// con [progress]; in indeterminata e' sfasata per dare il feeling
  /// "il sentiero si forma per primo".
  final double sentieroProgress;
  final Color color;
  final Color ringColor;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final strokeRing = s / 14;
    final strokeS = s / 9;

    // 1) Cerchio "spento" sempre visibile.
    final ringRadius = s / 2 - strokeRing / 2;
    final ringCenter = Offset(s / 2, s / 2);
    final ringPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeRing
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(ringCenter, ringRadius, ringPaint);

    // 2) Arc colorato che cresce da -pi/2 (top) in senso orario.
    if (progress > 0) {
      final arcPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeRing
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: ringCenter, radius: ringRadius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        arcPaint,
      );
    }

    // 3) S sentiero al centro, tracciata da 0 a sentieroProgress.
    // Inset 18% del lato per dare respiro al cerchio.
    final inset = s * 0.18;
    final innerSize = s - 2 * inset;
    final fullPath = buildTrosoPath(innerSize);
    final metrics = fullPath.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final totalLen = metrics.fold<double>(0, (sum, m) => sum + m.length);
    final wantedLen = totalLen * sentieroProgress.clamp(0.0, 1.0);
    final partial = Path();
    var consumed = 0.0;
    for (final m in metrics) {
      if (consumed >= wantedLen) break;
      final remaining = wantedLen - consumed;
      final take = remaining < m.length ? remaining : m.length;
      partial.addPath(m.extractPath(0, take), Offset.zero);
      consumed += take;
    }

    final sPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeS
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    canvas.save();
    canvas.translate(inset, inset);
    canvas.drawPath(partial, sPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LoaderPainter old) =>
      old.progress != progress ||
      old.sentieroProgress != sentieroProgress ||
      old.color != color ||
      old.ringColor != ringColor;
}
