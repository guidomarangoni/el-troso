// El Troso - G1 "Memoria delle foto": pagina (Fase 4.5.j).
//
// Memory matching game con foto autobiografiche dell'utente.
// Griglia 4x3 (12 carte = 6 coppie). Tap → flip → tap altra → match
// o flip back.
//
// EBM richiamata (vedi photo_match_logic.dart §EBM):
//   - Serious games in MCI/AD (JMIR Serious Games 2024 meta-analisi)
//   - Visual recognition memory (dominio preservato in MCI)
//   - Reminiscence + positivity effect (Cochrane Woods 2018 +
//     Carstensen 2012)
//
// Stato del trittico el troso:
//   - Ogni partita rinforza F11/F12: ad ogni coppia trovata, registro
//     un Walk sul ricordo (walker = self), cosi' G4 Spaced Retrieval
//     ricalcola la "freschezza" del ricordo. Il gioco e' calpestio
//     visivo dei ricordi.
//
// State machine:
//   - _Phase.viewing: griglia attiva, l'utente sceglie carte
//   - _Phase.notEnough: empty state se < 6 ricordi con foto
//   - _Phase.won: schermata finale con conteggio mosse
//
// Touch dynamics:
//   - Tap su carta nascosta → flip-show
//   - Una carta gia' aperta visibile → tap su seconda carta
//     - Match → restano aperte permanentemente, registra Walk
//     - No match → entrambe flip-back dopo 1.2s (timeout educativo:
//       lascia tempo al cervello di memorizzare la posizione)
//   - Tap durante timeout no-match: ignorato
//   - Tap su carta gia' matched: ignorato
//
// Animazione:
//   - AnimatedSwitcher con fade 250ms tra back e front. Niente flip
//     3D per MVP — costoso e meno leggibile per anziani.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:el_troso/core/game_info_sheet.dart';
import 'package:el_troso/core/locale/locale_codes.dart';
import 'package:el_troso/core/sound_provider.dart';
import 'package:el_troso/core/version.dart';
import 'package:el_troso/core/voice/tts_provider.dart';
import 'package:el_troso/features/games/photo_match_logic.dart';
import 'package:el_troso/features/profile/profile_providers.dart';
import 'package:el_troso/features/memory/memory.dart';
import 'package:el_troso/features/memory/memory_providers.dart';
import 'package:el_troso/l10n/app_localizations.dart';

enum _Phase { viewing, notEnough, won }

class PhotoMatchPage extends ConsumerStatefulWidget {
  const PhotoMatchPage({super.key});

  @override
  ConsumerState<PhotoMatchPage> createState() => _PhotoMatchPageState();
}

class _PhotoMatchPageState extends ConsumerState<PhotoMatchPage> {
  List<MatchCard> _deck = const [];
  int? _firstIdx;
  int? _secondIdx;
  final Set<int> _matched = <int>{};
  int _moves = 0;
  bool _busy = false; // true durante il timeout no-match
  _Phase _phase = _Phase.viewing;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _newGame());
  }

  void _newGame() {
    // Se "Un'altra partita" arriva mentre il TTS di vittoria sta ancora
    // parlando, lo interrompiamo: a partita nuova non vogliamo voce
    // sovrapposta ai flip.
    ref.read(ttsServiceProvider).stop().ignore();
    final memories =
        ref.read(memoriesProvider).valueOrNull ?? const <Memory>[];
    final deck = buildDeck(memories);
    setState(() {
      _deck = deck;
      _firstIdx = null;
      _secondIdx = null;
      _matched.clear();
      _moves = 0;
      _busy = false;
      _phase = deck.isEmpty ? _Phase.notEnough : _Phase.viewing;
    });
    debugPrint(
      '[photo_match] new game deck=${deck.length} '
      'memories=${memories.length} phase=$_phase',
    );
  }

  @override
  void dispose() {
    // Ferma il TTS se in corso quando l'utente esce dalla pagina (back
    // o nav home): la voce non deve continuare in altre schermate.
    ref.read(ttsServiceProvider).stop().ignore();
    super.dispose();
  }

  Future<void> _onTap(int idx) async {
    if (_busy) return;
    if (_matched.contains(idx)) return;
    if (_firstIdx == idx) return; // same card double-tap

    debugPrint(
      '[photo_match] tap idx=$idx first=$_firstIdx second=$_secondIdx '
      'matched=${_matched.length}',
    );

    final sound = ref.read(soundServiceProvider);

    if (_firstIdx == null) {
      sound.flip().ignore();
      setState(() => _firstIdx = idx);
      return;
    }

    // Seconda carta scoperta.
    sound.flip().ignore();
    setState(() {
      _secondIdx = idx;
      _moves++;
    });

    if (isMatch(_deck, _firstIdx!, idx)) {
      // Match: registra Walk e mantieni aperte.
      final card = _deck[idx];
      await _registerWalk(card.memoryId);
      if (!mounted) return;
      sound.match().ignore();
      setState(() {
        _matched.add(_firstIdx!);
        _matched.add(idx);
        _firstIdx = null;
        _secondIdx = null;
      });
      if (isWon(_deck, _matched)) {
        setState(() => _phase = _Phase.won);
        debugPrint('[photo_match] WON in $_moves mosse');
        _onWon();
      }
    } else {
      // No match: timeout 1.2s poi flip back.
      setState(() => _busy = true);
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      setState(() {
        _firstIdx = null;
        _secondIdx = null;
        _busy = false;
      });
    }
  }

  /// Cue di vittoria: arpeggio breve + complimento TTS personalizzato.
  /// Fire-and-forget per non bloccare la transizione alla _WonBody.
  void _onWon() {
    ref.read(soundServiceProvider).win().ignore();
    // Lascia che il jingle parta da solo: il TTS si sovrapporrebbe troppo.
    // Avvio del TTS con piccolo delay per non collidere con l'arpeggio.
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      final profile = ref.read(profileProvider);
      final name = profile?.name.trim() ?? '';
      final phrase = name.isNotEmpty
          ? l10n.photoMatchWonTtsWithName(name)
          : l10n.photoMatchWonTtsNoName;
      ref.read(ttsServiceProvider).speak(
            phrase,
            lang: ttsLanguageCode(Localizations.localeOf(context)),
          ).ignore();
    });
  }

  /// Registra un Walk sul ricordo associato alla coppia matched.
  /// Walker = self (chi gioca = la persona principale).
  Future<void> _registerWalk(String memoryId) async {
    final memories =
        ref.read(memoriesProvider).valueOrNull ?? const <Memory>[];
    Memory? m;
    for (final x in memories) {
      if (x.id == memoryId) {
        m = x;
        break;
      }
    }
    if (m == null) return;
    final walk = Walk(walkedAt: DateTime.now().toUtc(), walker: 'self');
    final updated = m.copyWith(walks: [walk, ...m.walks]);
    await ref.read(memoriesProvider.notifier).updateMemory(updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gamePhotoMatchTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: l10n.gameInfoWhatTitle,
            onPressed: () =>
                GameInfoSheet.show(context, GameInfoKind.photoMatch),
          ),
          const VersionBadge(),
        ],
      ),
      body: SafeArea(child: _buildBody(theme, l10n)),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n) {
    if (_phase == _Phase.notEnough) {
      return _NotEnoughBody(l10n: l10n);
    }
    if (_phase == _Phase.won) {
      return _WonBody(
        moves: _moves,
        l10n: l10n,
        onRetry: _newGame,
        onHome: () => context.go('/home'),
      );
    }
    return _GameGrid(
      deck: _deck,
      firstIdx: _firstIdx,
      secondIdx: _secondIdx,
      matched: _matched,
      pairsFound: pairsFound(_matched),
      totalPairs: _deck.length ~/ 2,
      moves: _moves,
      onTap: _onTap,
      l10n: l10n,
      theme: theme,
    );
  }
}

// ─────────────────────────────────────────────── grid

class _GameGrid extends StatelessWidget {
  const _GameGrid({
    required this.deck,
    required this.firstIdx,
    required this.secondIdx,
    required this.matched,
    required this.pairsFound,
    required this.totalPairs,
    required this.moves,
    required this.onTap,
    required this.l10n,
    required this.theme,
  });

  final List<MatchCard> deck;
  final int? firstIdx;
  final int? secondIdx;
  final Set<int> matched;
  final int pairsFound;
  final int totalPairs;
  final int moves;
  final ValueChanged<int> onTap;
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header status: coppie trovate + mosse.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.photoMatchPairs(pairsFound, totalPairs),
                style: theme.textTheme.titleMedium,
              ),
              Text(
                l10n.photoMatchMoves(moves),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Griglia 3×4 in portrait, 4×3 in landscape: calcola
          // childAspectRatio dinamicamente per RIEMPIRE lo spazio
          // disponibile invece di lasciarlo vuoto sotto. Prima usavamo
          // childAspectRatio: 0.78 fisso e in portrait lo Expanded
          // restava per metà inutilizzato.
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const gap = 8.0;
                final isPortrait = constraints.maxHeight > constraints.maxWidth;
                final cols = isPortrait ? 3 : 4;
                final rows = isPortrait ? 4 : 3;
                final cellW =
                    (constraints.maxWidth - gap * (cols - 1)) / cols;
                final cellH =
                    (constraints.maxHeight - gap * (rows - 1)) / rows;
                final aspect = cellW / cellH;
                return GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: gap,
                    crossAxisSpacing: gap,
                    childAspectRatio: aspect,
                  ),
                  itemCount: deck.length,
                  itemBuilder: (context, idx) {
                    final isOpen = idx == firstIdx ||
                        idx == secondIdx ||
                        matched.contains(idx);
                    final isMatched = matched.contains(idx);
                    return _Card(
                      card: deck[idx],
                      isOpen: isOpen,
                      isMatched: isMatched,
                      theme: theme,
                      onTap: () => onTap(idx),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.card,
    required this.isOpen,
    required this.isMatched,
    required this.theme,
    required this.onTap,
  });

  final MatchCard card;
  final bool isOpen;
  final bool isMatched;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: isOpen
              ? _CardFront(
                  key: ValueKey('front_${card.memoryId}_${card.slot}'),
                  imagePath: card.imagePath,
                  isMatched: isMatched,
                  theme: theme,
                )
              : _CardBack(
                  key: ValueKey('back_${card.memoryId}_${card.slot}'),
                  theme: theme,
                ),
        ),
      ),
    );
  }
}

class _CardBack extends StatelessWidget {
  const _CardBack({super.key, required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.directions_walk,
          size: 32,
          color: theme.colorScheme.tertiary.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _CardFront extends StatelessWidget {
  const _CardFront({
    super.key,
    required this.imagePath,
    required this.isMatched,
    required this.theme,
  });

  final String imagePath;
  final bool isMatched;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final borderColor = isMatched
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isMatched ? 2 : 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: File(imagePath).existsSync()
            ? Image.file(
                File(imagePath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
            : Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: Icon(Icons.broken_image_outlined, size: 24),
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────── empty state

class _NotEnoughBody extends StatelessWidget {
  const _NotEnoughBody({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.photoMatchNotEnoughBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go('/home'),
            child: Text(l10n.walkBackHomeCta),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────── win

class _WonBody extends StatelessWidget {
  const _WonBody({
    required this.moves,
    required this.l10n,
    required this.onRetry,
    required this.onHome,
  });

  final int moves;
  final AppLocalizations l10n;
  final VoidCallback onRetry;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.celebration_outlined,
            size: 72,
            color: theme.colorScheme.secondary,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.photoMatchWonTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.photoMatchWonBody(moves),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: onRetry,
            child: Text(l10n.photoMatchRetryCta),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: onHome,
            child: Text(l10n.walkBackHomeCta),
          ),
        ],
      ),
    );
  }
}
