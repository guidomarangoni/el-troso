// El Troso - schermata "Sto preparando il sentiero..." (Fase 4.5.l).
//
// Si attiva quando il modello Gemma 4 E2B non e' ancora presente in
// external dir. In MVP questo accade nella pratica solo se l'utente
// ha installato un APK fresco senza modello (ipotesi piu' frequente
// in fase dev). Per la submission Kaggle, il flow definitivo e' quello
// asset-bundled (vedi BACKLOG_POST_HACKATHON o futuro commit asset
// diretto): l'APK conterra' il .litertlm in assets/models/, e questa
// pagina copiera' lo stream da rootBundle a getExternalStorageDirectory()
// con progress reale di bytes.
//
// In QUESTO commit, l'animazione e' VISIVA: simula la copia con timer
// e progress 0→1 in ~6 secondi, dopodiche' redirect a /home. Serve a:
//   - testare il loader animato TrosoLoader nel suo contesto target
//   - dare a Guido un'idea visiva del flow finale prima dell'asset
//     bundle (che richiede APK 2.7 GB e modifiche pubspec separate)
//
// QUANDO IMPLEMENTEREMO IL COPY REALE
// ────────────────────────────────────
// Il `_runFakeCopy` qui sotto va sostituito con:
//   - rootBundle.load('assets/models/gemma-4-E2B-it.litertlm') che
//     ritorna ByteData
//   - convertire a stream / scrivere a chunk a getExternalStorageDirectory()
//   - aggiornare progress = bytesWritten / totalBytes
//   - al termine, scrivere shared_preferences flag 'model_installed'
//     per non riproporre il copy a ogni avvio
//
// Per ora: niente shared_preferences flag. Ogni avvio fresh check del
// file su disco; se presente skip diretto a /home. Questo e' anche
// quello che fa lo splash redirect post-modelLoaded.

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import 'package:el_troso/core/branding/troso_loader.dart';
import 'package:el_troso/core/theme.dart';
import 'package:el_troso/core/version.dart';
import 'package:el_troso/l10n/app_localizations.dart';

const String _kModelFileName = 'gemma-4-E2B-it.litertlm';

/// Controlla se il modello Gemma 4 e' gia' presente sul device.
/// Usato dallo splash redirect e dalla home guard.
Future<bool> isModelInstalled() async {
  final extDir = await getExternalStorageDirectory();
  if (extDir == null) return false;
  final f = File('${extDir.path}/$_kModelFileName');
  return f.exists();
}

class ModelLoadingPage extends ConsumerStatefulWidget {
  const ModelLoadingPage({super.key});

  @override
  ConsumerState<ModelLoadingPage> createState() => _ModelLoadingPageState();
}

class _ModelLoadingPageState extends ConsumerState<ModelLoadingPage> {
  double _progress = 0;
  Timer? _timer;
  bool _checkedExisting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Se il modello e' gia' presente (es. push manuale via adb in
      // dev, o copy completata a sessione precedente), salta.
      final present = await isModelInstalled();
      if (!mounted) return;
      _checkedExisting = true;
      if (present) {
        debugPrint('[model_loading] modello gia\' presente → /home');
        context.go('/home');
        return;
      }
      _runFakeCopy();
    });
  }

  /// Simulazione copy: 6 secondi a step di 200ms.
  ///
  /// In produzione qui andra' il copy reale da rootBundle. Vedi commento
  /// in cima al file.
  void _runFakeCopy() {
    _timer = Timer.periodic(const Duration(milliseconds: 200), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _progress = (_progress + 1 / 30).clamp(0.0, 1.0));
      if (_progress >= 1.0) {
        t.cancel();
        // Pausa breve per far vedere il 100% prima di navigare.
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          debugPrint('[model_loading] simulazione completa → /home');
          context.go('/home');
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final percent = (_progress * 100).round();

    debugPrint(
      '[model_loading] render progress=$_progress%=$percent '
      'checked=$_checkedExisting',
    );

    return Scaffold(
      backgroundColor: ElTrosoColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            const Positioned(top: 8, right: 12, child: VersionBadge()),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Loader S grande in centro. Determinato da progress.
                  TrosoLoader(
                    size: 200,
                    progress: _progress,
                    color: theme.colorScheme.primary,
                    ringColor: theme.colorScheme.tertiary
                        .withValues(alpha: 0.20),
                  ),

                  const SizedBox(height: 32),

                  // Percentuale numerica grande, tabular figures per
                  // evitare jitter delle cifre.
                  Text(
                    '$percent%',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    l10n.modelLoadingTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.modelLoadingBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const Spacer(flex: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
