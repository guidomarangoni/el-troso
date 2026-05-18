// El Troso — HeroTodayCard (build 23, Home v4).
//
// Card grande in cima alla Home che mostra il ricordo proposto da G4
// SRT come "OGGI". Sostituisce la _TodayCard compatta della home v1.
//
// Layout:
//   ┌─────────────────────────────────────┐
//   │  ▢ foto del ricordo full-bleed     │
//   │  (gradient nero ↑→ trasparente)    │
//   │  ┌──┐                              │
//   │  │OGGI│                            │
//   │  └──┘                              │
//   │  Vuoi tornare a [titolo]?          │
//   │  "...estratto dal ricordo..."      │
//   └─────────────────────────────────────┘
//
// Tap ovunque → /memory/:id (la card È il CTA, niente bottoni espliciti).
// Se il ricordo non ha foto, fallback a un panel oliva-pieno con icona.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:el_troso/features/memory/memory.dart';
import 'package:el_troso/l10n/app_localizations.dart';

class HeroTodayCard extends StatelessWidget {
  const HeroTodayCard({super.key, required this.memory});

  final Memory memory;

  /// Titolo dell'hero: prima frase del ricordo, troncata a 12 parole
  /// se troppo lunga (rara su testi distillati). Aggiunge "…" quando
  /// la prima frase è stata accorciata.
  String _distilledTitle() {
    final first = memory.text.split(RegExp(r'[.\n]')).first.trim();
    final allWords = first.split(RegExp(r'\s+'));
    const maxWords = 12;
    if (allWords.length <= maxWords) {
      // Prima frase intera; togli virgola/punto-e-virgola finale.
      var s = first;
      if (s.endsWith(',') || s.endsWith(';')) {
        s = s.substring(0, s.length - 1);
      }
      return s;
    }
    var s = allWords.take(maxWords).join(' ').trim();
    if (s.endsWith(',') || s.endsWith(';')) {
      s = s.substring(0, s.length - 1);
    }
    return '$s…';
  }

  /// Estratto dell'hero: ciò che viene DOPO la prima frase del ricordo,
  /// troncato a ~15 parole. Vuoto se il ricordo è una sola frase (in
  /// quel caso l'hero mostra solo il titolo, niente sotto-riga).
  /// La separazione titolo↔estratto evita la ripetizione delle prime
  /// parole tra le due righe.
  String _excerpt() {
    final firstSepIdx = memory.text.indexOf(RegExp(r'[.\n]'));
    if (firstSepIdx < 0 || firstSepIdx >= memory.text.length - 1) {
      return '';
    }
    var rest = memory.text.substring(firstSepIdx + 1).trim();
    // Salta eventuali separatori residui (es. "..." multipli o newline).
    while (rest.startsWith(RegExp(r'[.\n\s]'))) {
      rest = rest.substring(1);
    }
    if (rest.isEmpty) return '';
    final words = rest.split(RegExp(r'\s+'));
    const maxWords = 15;
    if (words.length <= maxWords) return rest;
    return '${words.take(maxWords).join(' ').trim()}…';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hasImage = memory.imagePath != null &&
        File(memory.imagePath!).existsSync();
    final title = _distilledTitle();

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: () => context.go('/memory/${memory.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          // 4:3 più bassa che 4:5: lascia respirare la home senza
          // sacrificare la leggibilità del titolo + estratto.
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                Image.file(
                  File(memory.imagePath!),
                  fit: BoxFit.cover,
                  // topCenter invece del default Alignment.center: nelle
                  // foto storiche del corpus i volti sono quasi sempre
                  // nel terzo superiore; un crop centrato simmetrico
                  // taglierebbe le teste. Con topCenter sacrifichiamo
                  // il bordo basso (di solito panchina/sfondo/corniche)
                  // mantenendo i visi in cornice.
                  alignment: Alignment.topCenter,
                )
              else
                Container(
                  color: theme.colorScheme.primary.withValues(alpha: 0.85),
                  child: Center(
                    child: Icon(
                      Icons.directions_walk,
                      size: 64,
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              // Gradient scuro dal basso per leggibilità del testo.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xCC1B2613), Color(0x001B2613)],
                    stops: [0.0, 0.7],
                  ),
                ),
              ),
              // Contenuto: eyebrow + titolo + estratto.
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Chip "OGGI"
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.homeTodayTitle.toUpperCase(),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Titolo distillato
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Estratto dopo la prima frase: visibile solo se
                    // c'è davvero del testo aggiuntivo, altrimenti la
                    // hero mostra solo il titolo (niente riga vuota).
                    if (_excerpt().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _excerpt(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                          height: 1.35,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
