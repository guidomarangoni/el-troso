// El Troso - identita' di build (Fase 4.5.h+).
//
// Costanti che identificano la versione corrente dell'app, esposte
// tramite il widget VersionBadge che appare come `actions:` di tutte
// le AppBar dell'app. Cosi' Guido (e chi testa) sa SEMPRE quale build
// sta runnando e non rischia di confondersi tra installazioni vecchie
// e nuove.
//
// Convenzione di versionamento durante la build hackathon:
//   - kAppVersion: stato di fase. 0.4.5 = Fase 4.5, 0.5.0 = Fase 5, ...
//     1.0.0 sara' la submission Kaggle del 2026-05-18.
//   - kAppBuild: numero progressivo incrementato a OGNI commit. Cosi'
//     dopo un install Guido vede subito se l'APK e' la build attesa
//     (es. "build 12 dovrebbe avere il fix X, ma vedo build 10").
//
// Aggiornare entrambi i valori a mano ad ogni commit. La pigrizia su
// questo costa caro: una build "X-1" che sembra "X" si paga in test
// session perse a inseguire bug fantasma.
//
// Sincronizzato manualmente con pubspec.yaml `version: 0.4.5+10`.

import 'package:flutter/material.dart';

const String kAppVersion = '0.4.5';
const int kAppBuild = 45;

/// Stringa human-readable, es. "v0.4.5 · 10".
String get kVersionLabel => 'v$kAppVersion · $kAppBuild';

/// Badge piccolo, sempre presente come `actions:` dell'AppBar di ogni
/// pagina. Tap → SnackBar con info estese (utile per debug remoto: se
/// Guido tappa, vede subito quale build sta runnando senza dover andare
/// in Impostazioni Android).
class VersionBadge extends StatelessWidget {
  const VersionBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Center(
        child: InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('El Troso — $kVersionLabel'),
                duration: const Duration(seconds: 3),
              ),
            );
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              kVersionLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
