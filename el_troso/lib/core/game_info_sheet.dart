// El Troso — GameInfoSheet (Fase 4.5.h+).
//
// Bottom sheet riutilizzabile che spiega "di cosa si tratta" e "perché
// funziona" un esercizio dell'app, con link alle fonti EBM tappabili.
//
// Tre varianti via [GameInfoKind]:
//   - recognize  → G3 Riconosci e racconta (reminiscence therapy)
//   - photoMatch → G1 Memoria delle foto    (visual recognition + reminiscence)
//   - today      → G4 OGGI                  (Spaced Retrieval Training)
//
// Design intenti:
// - L'icona info appare DOVE l'utente sta usando la cosa, non dentro un
//   menu "About" generico: AppBar dei giochi e accanto al titolo di OGGI.
//   La trasparenza scientifica è una feature-prima, non un easter egg.
// - Linguaggio non clinico ma onesto: niente "scientificamente provato",
//   sì "le revisioni Cochrane mostrano benefici piccoli ma costanti".
// - Le fonti sono tappabili e aprono il browser di sistema (DOI/PubMed).
//   Niente WebView in-app: chi vuole leggere lo studio lo legge fuori.
// - Sheet non "scrollable: true" globale ma SingleChildScrollView interno:
//   l'utente può sempre scorrere il body ma la sheet ha altezza fissa
//   ~75% — abbastanza per leggere senza scrollare in dispositivi piccoli.
//
// Manuale uso:
//   IconButton(
//     icon: const Icon(Icons.info_outline),
//     onPressed: () => GameInfoSheet.show(context, GameInfoKind.recognize),
//   )

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:el_troso/l10n/app_localizations.dart';

enum GameInfoKind { recognize, photoMatch, today, guess, story }

class _InfoSource {
  const _InfoSource(this.label, this.url);
  final String label;
  final String url;
}

class _InfoContent {
  const _InfoContent({
    required this.title,
    required this.what,
    required this.why,
    required this.sources,
  });

  final String title;
  final String what;
  final String why;
  final List<_InfoSource> sources;

  factory _InfoContent.from(GameInfoKind kind, AppLocalizations l10n) {
    switch (kind) {
      case GameInfoKind.recognize:
        return _InfoContent(
          title: l10n.recognizeInfoTitle,
          what: l10n.recognizeInfoWhat,
          why: l10n.recognizeInfoWhy,
          sources: [
            _InfoSource(l10n.recognizeInfoSource1Label, l10n.recognizeInfoSource1Url),
            _InfoSource(l10n.recognizeInfoSource2Label, l10n.recognizeInfoSource2Url),
          ],
        );
      case GameInfoKind.photoMatch:
        return _InfoContent(
          title: l10n.photoMatchInfoTitle,
          what: l10n.photoMatchInfoWhat,
          why: l10n.photoMatchInfoWhy,
          sources: [
            _InfoSource(l10n.photoMatchInfoSource1Label, l10n.photoMatchInfoSource1Url),
          ],
        );
      case GameInfoKind.today:
        return _InfoContent(
          title: l10n.homeTodayInfoTitle,
          what: l10n.homeTodayInfoWhat,
          why: l10n.homeTodayInfoWhy,
          sources: [
            _InfoSource(l10n.homeTodayInfoSource1Label, l10n.homeTodayInfoSource1Url),
            _InfoSource(l10n.homeTodayInfoSource2Label, l10n.homeTodayInfoSource2Url),
          ],
        );
      case GameInfoKind.guess:
        return _InfoContent(
          title: l10n.guessInfoTitle,
          what: l10n.guessInfoWhat,
          why: l10n.guessInfoWhy,
          sources: [
            _InfoSource(l10n.guessInfoSource1Label, l10n.guessInfoSource1Url),
            _InfoSource(l10n.guessInfoSource2Label, l10n.guessInfoSource2Url),
          ],
        );
      case GameInfoKind.story:
        return _InfoContent(
          title: l10n.storyInfoTitle,
          what: l10n.storyInfoWhat,
          why: l10n.storyInfoWhy,
          sources: [
            _InfoSource(l10n.storyInfoSource1Label, l10n.storyInfoSource1Url),
            _InfoSource(l10n.storyInfoSource2Label, l10n.storyInfoSource2Url),
          ],
        );
    }
  }
}

class GameInfoSheet extends StatelessWidget {
  const GameInfoSheet._({required this.kind});

  final GameInfoKind kind;

  static Future<void> show(BuildContext context, GameInfoKind kind) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      // 75% del viewport: lascia respirare la home ma dà spazio al body lungo.
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      builder: (_) => GameInfoSheet._(kind: kind),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final content = _InfoContent.from(kind, l10n);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              content.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SectionHeader(label: l10n.gameInfoWhatTitle, theme: theme),
                    const SizedBox(height: 6),
                    Text(content.what, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 20),
                    _SectionHeader(label: l10n.gameInfoWhyTitle, theme: theme),
                    const SizedBox(height: 6),
                    Text(content.why, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 20),
                    _SectionHeader(label: l10n.gameInfoSourcesTitle, theme: theme),
                    const SizedBox(height: 4),
                    for (final s in content.sources)
                      _SourceLink(label: s.label, url: s.url, theme: theme),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.gameInfoCloseCta),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.theme});

  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.labelLarge?.copyWith(
        color: theme.colorScheme.secondary,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SourceLink extends StatelessWidget {
  const _SourceLink({
    required this.label,
    required this.url,
    required this.theme,
  });

  final String label;
  final String url;
  final ThemeData theme;

  Future<void> _open(BuildContext context) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(url)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 8),
              child: Icon(
                Icons.open_in_new,
                size: 16,
                color: theme.colorScheme.primary,
              ),
            ),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
