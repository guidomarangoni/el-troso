// El Troso — RecentMemoriesGallery (build 23, Home v4).
//
// Galleria orizzontale di tile ricordo (140x180 dp), scrollabile lateral-
// mente. Ordina prima i ricordi più "sbiaditi" (footprintOpacity bassa)
// per invitare l'utente a ripercorrerli — coerente con la metafora del
// trittico (un sentiero che sbiadisce è un invito a tornarci).
//
// Tile:
//   ┌────────────────┐
//   │ foto (clip 16) │
//   │                │
//   │                │
//   ├────────────────┤
//   │ Titolo distill.│
//   │                │
//   │ • • •          │  ← 3 dots con opacity 35/60/100 = stato freschezza
//   └────────────────┘
//
// Tap → /memory/:id.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:el_troso/features/memory/memory.dart';

class RecentMemoriesGallery extends StatelessWidget {
  const RecentMemoriesGallery({super.key, required this.memories});

  final List<Memory> memories;

  /// Ordina prima i sbiaditi (opacity bassa), poi i freschi.
  /// Limita a 10 tile: oltre, l'utente apre il dettaglio o "vedi tutti".
  List<Memory> _orderedForGallery() {
    final list = List<Memory>.from(memories);
    list.sort((a, b) => a.footprintOpacity.compareTo(b.footprintOpacity));
    return list.take(10).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final list = _orderedForGallery();
    if (list.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 200,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, idx) => _GalleryTile(memory: list[idx]),
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  const _GalleryTile({required this.memory});

  final Memory memory;

  String _shortTitle() {
    final first = memory.text.split(RegExp(r'[.\n]')).first.trim();
    final allWords = first.split(RegExp(r'\s+'));
    final words = allWords.take(5).toList();
    final s = words.join(' ').trim();
    final truncated =
        allWords.length > words.length || memory.text.length > first.length;
    return truncated ? '$s…' : s;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = memory.imagePath != null &&
        File(memory.imagePath!).existsSync();
    return SizedBox(
      width: 140,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.go('/memory/${memory.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto (o placeholder oliva)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 140,
                height: 130,
                child: hasImage
                    ? Image.file(
                        File(memory.imagePath!),
                        fit: BoxFit.cover,
                        // topCenter: vedi commento in HeroTodayCard.
                        alignment: Alignment.topCenter,
                      )
                    : Container(
                        color: theme.colorScheme.primary.withValues(alpha: 0.18),
                        child: Center(
                          child: Icon(
                            Icons.directions_walk,
                            size: 32,
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            // Titolo distillato (max 2 righe)
            Text(
              _shortTitle(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // 3 dots di freshness mapping (35 / 60 / 100 in base allo stato)
            _FreshnessDots(opacity: memory.footprintOpacity, theme: theme),
          ],
        ),
      ),
    );
  }
}

/// Tre piccole pillole oliva con opacity diverse: rappresentano 3
/// "impronte" stilizzate. Pattern di freshness:
///   - opacity 1.0 (fresco)   → 100 / 100 / 100
///   - opacity 0.6 (medio)    →  60 /  60 / 100
///   - opacity 0.3 (sbiadito) →  35 /  35 /  35
class _FreshnessDots extends StatelessWidget {
  const _FreshnessDots({required this.opacity, required this.theme});

  final double opacity;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final base = theme.colorScheme.primary;
    final List<double> opacities;
    if (opacity >= 0.9) {
      opacities = const [1.0, 1.0, 1.0];
    } else if (opacity >= 0.55) {
      opacities = const [0.6, 0.6, 1.0];
    } else {
      opacities = const [0.35, 0.35, 0.35];
    }
    return Row(
      children: [
        for (final op in opacities) ...[
          Container(
            width: 10,
            height: 4,
            decoration: BoxDecoration(
              color: base.withValues(alpha: op),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ],
    );
  }
}
