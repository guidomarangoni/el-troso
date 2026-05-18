// El Troso — FullscreenPhotoView (build 30).
//
// Visualizzatore a tutto schermo per le foto dei ricordi: tap dalla
// MemoryDetailPage o dalla RecognizePage → questa pagina con pinch-
// zoom + pan tramite InteractiveViewer.
//
// Scelte di design:
// - InteractiveViewer NATIVO (no pacchetti esterni come photo_view): zero
//   dipendenze nuove, robusto, supporta pinch-zoom e drag su Android.
//   max scale 5x, min 1x — abbastanza per leggere scritte su giornali
//   d'epoca senza pixelation eccessiva.
// - Scaffold nero a tutto schermo: la foto è IL contenuto, niente
//   distrazioni. Tipico pattern Lightroom / Google Photos.
// - Hero animation con `tag` = memory id per transizione fluida da
//   thumbnail a fullscreen. Reso opzionale: se il caller non passa tag,
//   niente hero (es. RecognizePage dove l'id non è esposto al widget).
// - Close: tap sulla X in alto a destra OPPURE swipe verso il basso
//   (PopScope nativo via Navigator.pop). Niente tap-on-photo per non
//   confliggere con il drag dell'InteractiveViewer.
// - SafeArea: la X resta sotto la status bar.

import 'dart:io';

import 'package:flutter/material.dart';

class FullscreenPhotoView extends StatelessWidget {
  const FullscreenPhotoView({
    super.key,
    required this.imagePath,
    this.heroTag,
    this.semanticLabel,
  });

  final String imagePath;
  final Object? heroTag;
  final String? semanticLabel;

  /// Scorciatoia: spinge la pagina come modale full-screen sul Navigator
  /// corrente. Usata dai chiamanti per evitare di importare MaterialPageRoute.
  static Future<void> open(
    BuildContext context, {
    required String imagePath,
    Object? heroTag,
    String? semanticLabel,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => FullscreenPhotoView(
          imagePath: imagePath,
          heroTag: heroTag,
          semanticLabel: semanticLabel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = Image.file(
      File(imagePath),
      fit: BoxFit.contain,
      semanticLabel: semanticLabel,
    );
    final wrapped = heroTag == null
        ? image
        : Hero(tag: heroTag!, child: image);
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          panEnabled: true,
          scaleEnabled: true,
          minScale: 1.0,
          maxScale: 5.0,
          // Default boundaryMargin = EdgeInsets.zero impedisce di
          // pannare oltre i bordi quando lo zoom è 1.0; con un piccolo
          // margine si può spostare anche a scala bassa, scomodo per gli
          // anziani. Lascio default → solo zoom > 1 abilita il pan.
          child: wrapped,
        ),
      ),
    );
  }
}
