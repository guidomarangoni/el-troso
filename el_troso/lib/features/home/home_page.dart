// El Troso — Home (build 23, layout v4).
//
// Architettura v4:
//
//   ┌─────────────────────────────────────────┐
//   │ AppBar trasparente: ☰ · EL TROSO · 🎴 ❓│
//   ├─────────────────────────────────────────┤
//   │ Ciao Giorgio,                           │
//   │ oggi c'è un ricordo che vale la pena…  │
//   │                                         │
//   │ ┌───────────────────────────────┐       │
//   │ │  HeroTodayCard (G4)          │       │
//   │ │  foto + OGGI + invito        │       │
//   │ └───────────────────────────────┘       │
//   │                                         │
//   │ I tuoi ricordi                          │
//   │ ▢▢▢▢▢ ←→ galleria orizzontale          │
//   │                                         │
//   │ (banner walk confirmed se entro 5s)     │
//   ├─────────────────────────────────────────┤
//   │ [🎤 Racconta un ricordo] (sticky)       │
//   └─────────────────────────────────────────┘
//
// Sotto a tutto: assets/backgrounds/sentiero.jpg full-screen al 22%
// di opacity. È un foto generata di orme di scarpa in prospettiva,
// rinforza la metafora "el troso / desire path" senza interferire
// con la lettura.
//
// Differenze chiave dalla v1 (Fase 4.5.h):
// - sezioni "Cammina" e "Allena" eliminate: i bottoni Ripercorro / G3 /
//   G1 spariti. Ripercorrere si fa via tap sui ricordi, giochi e Ask
//   si raggiungono dalle 2 icone in AppBar.
// - PathStatus ("X ricordi nel sentiero, Y stanno sbiadendo") sostituito
//   dal sub-saluto poetico ("oggi c'è un ricordo..." / "il sentiero è
//   tutto fresco...") che dice la stessa cosa ma in tono.
// - TodayCard compatto promosso a HeroTodayCard a piena larghezza.
// - MemoriesList verticale → RecentMemoriesGallery orizzontale.
// - CTA primario "Racconta un ricordo" reso sticky nel bottom bar.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:el_troso/core/version.dart';
import 'package:el_troso/features/games/spaced_retrieval.dart';
import 'package:el_troso/features/home/app_drawer.dart';
import 'package:el_troso/features/home/hero_today_card.dart';
import 'package:el_troso/features/home/recent_memories_gallery.dart';
import 'package:el_troso/features/memory/memory.dart';
import 'package:el_troso/features/memory/memory_providers.dart';
import 'package:el_troso/features/profile/profile_providers.dart';
import 'package:el_troso/l10n/app_localizations.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final profile = ref.watch(profileProvider);
    final memoriesAsync = ref.watch(memoriesProvider);
    final todays = ref.watch(todaysMemoryProvider);
    final lastWalk = ref.watch(lastWalkProvider);

    final memories = memoriesAsync.valueOrNull ?? const <Memory>[];
    final latestId = memories.isNotEmpty ? memories.first.id : null;

    final display = profile == null
        ? '...'
        : (profile.vocative.isNotEmpty ? profile.vocative : profile.name);

    final walkConfirmed = lastWalk != null && lastWalk.isFresh(seconds: 5);

    debugPrint(
      '[home] render mem=${memories.length} today=${todays?.id} '
      'walkConfirmed=$walkConfirmed',
    );

    return Scaffold(
      drawer: const AppDrawer(),
      // Trasparente per far affiorare lo sfondo sentiero sotto.
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            tooltip: 'Menu',
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(
          l10n.appTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: theme.colorScheme.primary,
          ),
        ),
        centerTitle: false,
        actions: [
          // Icona Ask: Fai una domanda. L'icona Giochi è stata rimossa
          // perché ora c'è il CTA "Gioca" sotto i ricordi.
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.homeAppBarAskTooltip,
            onPressed: () => context.go('/ask'),
          ),
          const VersionBadge(),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Sfondo: foto orme generata da Nano Banana Pro al 22% di
          // opacity. Sotto, scaffoldBackgroundColor crema fa da base.
          Positioned.fill(
            child: ColoredBox(color: theme.scaffoldBackgroundColor),
          ),
          Positioned.fill(
            child: Opacity(
              opacity: 0.22,
              child: Image.asset(
                'assets/backgrounds/sentiero.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
            ),
          ),
          // Contenuto principale: tutto in unico scrollview, CTA in
          // bottomNavigationBar dello Scaffold (fuori dallo scroll).
          // La galleria sta DENTRO lo scrollview così l'header "I tuoi
          // ricordi" le sta sempre sopra. Padding orizzontale gestito
          // sezione per sezione (la galleria vuole 0 lat per scrollare
          // edge-to-edge).
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 12, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Saluto + sub-saluto
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.homeGreeting(display),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          todays != null
                              ? l10n.homeSubGreetingWithToday
                              : l10n.homeSubGreetingNoToday,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Hero OGGI (4:3, padding lat 24)
                  if (todays != null) ...[
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: HeroTodayCard(memory: todays),
                    ),
                  ],
                  // Header + galleria
                  if (memories.isNotEmpty) ...[
                    const SizedBox(height: 36),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        l10n.homeYourMemories,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Galleria edge-to-edge: il widget interno ha già
                    // padding 24 lat per il primo/ultimo tile.
                    RecentMemoriesGallery(memories: memories),
                  ],
                  // Banner walk-confirmed (se entro 5s da un walk) +
                  // 2 CTA Racconto / Ripercorri. Tutto in linea con
                  // il resto: niente bottomNavigationBar separata, lo
                  // scroll continua da saluto fino al fondo della pagina.
                  const SizedBox(height: 32),
                  if (walkConfirmed)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: _WalkConfirmedPill(l10n: l10n, theme: theme),
                    ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      0,
                      24,
                      MediaQuery.of(context).padding.bottom + 12,
                    ),
                    child: Column(
                      children: [
                        // Primario: Racconto. Pieno, full-width.
                        FilledButton.icon(
                          onPressed: () => context.go('/record/new'),
                          icon: const Icon(Icons.mic_none),
                          label: Text(l10n.homeRecordCta),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(60),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            textStyle: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Riga di 2 secondari outlined: Ripercorri / Gioca
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: latestId == null
                                    ? null
                                    : () => context.go('/memory/$latestId'),
                                icon: const Icon(Icons.directions_walk,
                                    size: 20),
                                label: Text(l10n.homeWalkCta),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _openGamesPicker(
                                    context, l10n, memories),
                                icon: const Icon(Icons.style_outlined,
                                    size: 20),
                                label: Text(l10n.homeGamesCta),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(54),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Modal sheet "Allena la memoria": tile per G3 e G1.
  /// Bypassa la rimozione della sezione Allena dalla home senza
  /// nascondere i giochi: l'icona AppBar li raggiunge in 2 tap.
  Future<void> _openGamesPicker(
    BuildContext context,
    AppLocalizations l10n,
    List<Memory> memories,
  ) {
    final hasPhotoMemory = memories.any((m) => m.imagePath != null);
    final canPhotoMatch =
        memories.where((m) => m.imagePath != null).length >= 6;
    final hasAnyMemory = memories.any((m) => m.text.trim().length >= 30);
    final hasLongMemory =
        memories.any((m) => m.text.trim().length >= 80);
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.homeGamesPickerTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.image_outlined),
                  title: Text(l10n.gameRecognizeTitle),
                  subtitle: Text(l10n.gameRecognizeShort),
                  enabled: hasPhotoMemory,
                  onTap: hasPhotoMemory
                      ? () {
                          Navigator.pop(ctx);
                          context.go('/game/recognize');
                        }
                      : null,
                ),
                ListTile(
                  leading: const Icon(Icons.grid_view_outlined),
                  title: Text(l10n.gamePhotoMatchTitle),
                  subtitle: Text(l10n.gamePhotoMatchShort),
                  enabled: canPhotoMatch,
                  onTap: canPhotoMatch
                      ? () {
                          Navigator.pop(ctx);
                          context.go('/game/photo-match');
                        }
                      : null,
                ),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text(l10n.gameGuessTitle),
                  subtitle: Text(l10n.gameGuessShort),
                  enabled: hasAnyMemory,
                  onTap: hasAnyMemory
                      ? () {
                          Navigator.pop(ctx);
                          context.go('/game/guess');
                        }
                      : null,
                ),
                ListTile(
                  leading: const Icon(Icons.auto_stories_outlined),
                  title: Text(l10n.gameStoryTitle),
                  subtitle: Text(l10n.gameStoryShort),
                  enabled: hasLongMemory,
                  onTap: hasLongMemory
                      ? () {
                          Navigator.pop(ctx);
                          context.go('/game/story');
                        }
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────── walk-confirmed pill

/// Pillola sottile sopra al CTA quando l'utente è appena tornato
/// da un walk (entro 5s). Auto-dismiss via lastWalkProvider state=null.
class _WalkConfirmedPill extends ConsumerStatefulWidget {
  const _WalkConfirmedPill({required this.l10n, required this.theme});
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  ConsumerState<_WalkConfirmedPill> createState() =>
      _WalkConfirmedPillState();
}

class _WalkConfirmedPillState extends ConsumerState<_WalkConfirmedPill> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      ref.read(lastWalkProvider.notifier).state = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final l10n = widget.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${l10n.walkConfirmedTitle} · ${l10n.walkConfirmedBody}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
