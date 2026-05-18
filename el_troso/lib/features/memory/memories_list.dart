// El Troso - widget lista ricordi (Fase 4.5.b → 4.5.k).
//
// Evoluzione:
// - 4.5.f F7: mostra il tag come chip piccolo sulla riga del ricordo.
// - 4.5.f F12: indicatore orme che sbiadiscono — l'icona trailing ha
//   opacity variabile (1.0 / 0.6 / 0.3 a 0/7/14 gg).
// - 4.5.k: animazione "orma che si accende" quando un ricordo e' stato
//   appena calpestato (TweenAnimationBuilder elasticOut da scale 1.4
//   → 1.0 in 800ms). Il signal arriva da lastWalkProvider che il
//   MemoriesController emette in updateMemory quando walks cresce.
// - 4.5.k: leggenda visiva 3 stati orma (FootprintLegend) in cima alla
//   lista la prima volta che ci sono ricordi sbiaditi — chiarisce il
//   simbolo prima che l'utente debba dedurlo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:el_troso/features/memory/memory.dart';
import 'package:el_troso/features/memory/memory_providers.dart';
import 'package:el_troso/l10n/app_localizations.dart';

/// Numero massimo di ricordi mostrati in home.
const int _kHomeListMaxItems = 8;

/// Lunghezza massima del titolo auto-generato.
const int _kTitleMaxChars = 70;

class MemoriesList extends ConsumerWidget {
  const MemoriesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final async = ref.watch(memoriesProvider);
    final lastWalk = ref.watch(lastWalkProvider);

    return async.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) {
        debugPrint('[memories_list] error state: $err');
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            l10n.memoriesLoadError,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        );
      },
      data: (memories) {
        if (memories.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l10n.noMemoriesYet,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        final items = memories.length > _kHomeListMaxItems
            ? memories.sublist(0, _kHomeListMaxItems)
            : memories;

        // F12: controlla se ci sono ricordi sbiaditi per mostrare
        // l'empty state gentile in fondo.
        final hasFading = items.any((m) => m.footprintOpacity < 1.0);

        // 4.5.k: leggenda in cima quando ci sono ricordi sbiaditi —
        // serve per chiarire il simbolo "orma luminosa vs sbiadita".
        // +1 per legenda (se hasFading) +1 per fading empty state finale.
        final itemCount = items.length +
            (hasFading ? 1 : 0) + // legenda
            (hasFading ? 1 : 0); // empty state finale

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: itemCount,
          separatorBuilder: (ctx, i) {
            // Niente divider sopra/sotto legenda.
            if (hasFading && (i == 0 || i == items.length)) {
              return const SizedBox.shrink();
            }
            return const Divider(height: 1);
          },
          itemBuilder: (context, i) {
            // Prima riga: leggenda 3 stati orma (solo se hasFading).
            if (hasFading && i == 0) {
              return _FootprintLegend(theme: theme, l10n: l10n);
            }
            final dataIdx = hasFading ? i - 1 : i;

            // Ultima riga: fading empty state (F12).
            if (dataIdx == items.length) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  l10n.fadingEmptyState,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }

            final m = items[dataIdx];
            final title = _buildTitle(m.text);
            final subtitle = _formatRelativeDate(m.createdAt, l10n);
            final opacity = m.footprintOpacity;

            // 4.5.k: animazione "orma che si accende". La key cambia
            // ogni volta che lastWalk e' su questo memory id (nuovo
            // timestamp ms). TweenAnimationBuilder ri-anima da capo.
            final isJustWalked = lastWalk != null &&
                lastWalk.memoryId == m.id &&
                lastWalk.isFresh(seconds: 5);

            Widget footprintIcon = Opacity(
              opacity: opacity,
              child: Icon(
                Icons.directions_walk,
                color: theme.colorScheme.tertiary,
                size: 28,
              ),
            );
            if (isJustWalked) {
              footprintIcon = TweenAnimationBuilder<double>(
                key: ValueKey('walk_${m.id}_'
                    '${lastWalk.at.millisecondsSinceEpoch}'),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                tween: Tween(begin: 1.4, end: 1.0),
                builder: (_, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: footprintIcon,
              );
            }

            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge,
              ),
              subtitle: Row(
                children: [
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (m.tag != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      _tagLabel(m.tag!, l10n),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: footprintIcon,
              onTap: () => _onTapMemory(context, m),
            );
          },
        );
      },
    );
  }

  static String _buildTitle(String raw) {
    final normalized = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= _kTitleMaxChars) return normalized;

    final cutoffWindow = normalized.substring(0, _kTitleMaxChars);
    final match = RegExp(r'[.!?]\s').allMatches(cutoffWindow).toList();
    if (match.isNotEmpty) {
      final end = match.last.start;
      if (end > 20) {
        return normalized.substring(0, end + 1);
      }
    }

    final lastSpace = cutoffWindow.lastIndexOf(' ');
    final soft = lastSpace > 30
        ? cutoffWindow.substring(0, lastSpace)
        : cutoffWindow;
    return '$soft…';
  }

  static String _formatRelativeDate(
      DateTime createdAt, AppLocalizations l10n) {
    final now = DateTime.now();
    final local = createdAt.toLocal();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(local.year, local.month, local.day);
    final deltaDays = today.difference(d).inDays;

    if (deltaDays <= 0) return l10n.memoryDateToday;
    if (deltaDays == 1) return l10n.memoryDateYesterday;
    if (deltaDays < 7) return l10n.memoryDateDaysAgo(deltaDays);
    if (deltaDays < 30) {
      final weeks = deltaDays ~/ 7;
      return l10n.memoryDateWeeksAgo(weeks);
    }
    if (deltaDays < 365) {
      final months = deltaDays ~/ 30;
      return l10n.memoryDateMonthsAgo(months);
    }
    final years = deltaDays ~/ 365;
    return l10n.memoryDateYearsAgo(years);
  }

  static String _tagLabel(String tag, AppLocalizations l10n) {
    switch (tag) {
      case 'family':
        return l10n.tagFamily;
      case 'work':
        return l10n.tagWork;
      case 'travel':
        return l10n.tagTravel;
      case 'home':
        return l10n.tagHome;
      default:
        return l10n.tagOther;
    }
  }

  void _onTapMemory(BuildContext context, Memory m) {
    debugPrint('[memories_list] tap on ${m.id} → /memory/${m.id}');
    context.go('/memory/${m.id}');
  }
}

/// Leggenda visiva 3 stati orma. Mostra le 3 opacity affiancate con
/// label brevi sotto. Aiuta a "leggere" il simbolo della MemoriesList
/// senza dover dedurlo o leggere docs.
class _FootprintLegend extends StatelessWidget {
  const _FootprintLegend({required this.theme, required this.l10n});

  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _LegendItem(
            opacity: 1.0,
            label: l10n.legendFresh,
            theme: theme,
          ),
          _LegendItem(
            opacity: 0.6,
            label: l10n.legendFading,
            theme: theme,
          ),
          _LegendItem(
            opacity: 0.3,
            label: l10n.legendGhost,
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.opacity,
    required this.label,
    required this.theme,
  });

  final double opacity;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: opacity,
          child: Icon(
            Icons.directions_walk,
            size: 22,
            color: theme.colorScheme.tertiary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
