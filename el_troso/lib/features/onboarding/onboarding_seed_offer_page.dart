// El Troso — OnboardingSeedOfferPage (build 24).
//
// Schermata opt-in: subito dopo la creazione del profilo, prima di
// andare in home, chiede se l'utente vuole pre-caricare i 12 ricordi
// seed (libro "Nonno parlaci di te" di Giorgio Marangoni).
//
// Perché opt-in e non auto-load silenzioso:
// - eticamente: caricare la storia di una persona reale nel telefono
//   di un'altra senza chiedere è scorretto.
// - pitch Kaggle: la giuria vede esplicitamente che il pre-load è
//   opt-in (privacy by design rinforzato).
// - reset-friendly: se domani Giorgio o un parente decide di partire
//   da zero, "No, comincio io" gli dà subito il sentiero vuoto.
//
// UX:
// - Due bottoni stessa importanza visiva (FilledButton + OutlinedButton):
//   nessun dark pattern.
// - Tap "Sì" → loader animato (~3-5 sec, copia 12 foto + scrittura
//   JSON + indicizzazione vector store) → /home.
// - Tap "No" → /home immediato con sentiero vuoto.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:el_troso/features/memory/memory_providers.dart';
import 'package:el_troso/l10n/app_localizations.dart';

class OnboardingSeedOfferPage extends ConsumerStatefulWidget {
  const OnboardingSeedOfferPage({super.key});

  @override
  ConsumerState<OnboardingSeedOfferPage> createState() =>
      _OnboardingSeedOfferPageState();
}

class _OnboardingSeedOfferPageState
    extends ConsumerState<OnboardingSeedOfferPage> {
  bool _loading = false;

  Future<void> _acceptAndLoad() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final loader = ref.read(seedLoaderProvider);
      final list = await loader.loadFromBundle();
      debugPrint('[onb-seed] loaded ${list.length} memories');
    } catch (e, st) {
      debugPrint('[onb-seed] failed: $e\n$st');
      // In caso di errore non blocchiamo l'utente: comunque va in home
      // (vuota). Mostra una snackbar prima.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Caricamento non riuscito.')),
        );
      }
    }
    if (!mounted) return;
    context.go('/home');
  }

  void _decline() => context.go('/home');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
          child: _loading
              ? _LoadingBody(l10n: l10n, theme: theme)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Icon(
                      Icons.menu_book_outlined,
                      size: 56,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.onbSeedTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.onbSeedBody,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _acceptAndLoad,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(l10n.onbSeedCtaYes),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: _decline,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(l10n.onbSeedCtaNo),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.l10n, required this.theme});
  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: theme.colorScheme.primary,
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            l10n.onbSeedLoading,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
