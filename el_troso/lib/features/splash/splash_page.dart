// El Troso - Splash / landing iniziale (Fase 4.4.e → 4.5.l).
//
// Comportamento:
//   - Se il profilo esiste gia' (utente ha gia' completato onboarding) →
//     redirect automatico a /home al primo frame utile.
//   - Altrimenti → landing con tagline + CTA "Comincia" → /onboarding +
//     TextButton discreto "Playground (dev)" → /playground.
//
// 4.5.l: redesign brand-coerente con il mockup branding del 2026-04-25.
//   - Sfondo: olive primary pieno (non piu' parchment) → impatto forte
//     al lancio.
//   - Logo: TrosoLogoFull crema su olive (la "S sentiero" e' al posto
//     della S di TROSO).
//   - Mini loader animato indeterminato sotto il logo durante il
//     postFrame redirect (~1 frame, impercettibile in pratica ma
//     rifinisce il dettaglio "qualcosa sta succedendo").
//
// Nota sul redirect: lo eseguiamo via addPostFrameCallback anziche' dentro
// `build` perche' context.go durante build di un route e' un errore. Con
// addPostFrameCallback navighiamo subito dopo che il primo frame e' stato
// costruito, cosi' go_router vede lo stack stabile e accetta la navigazione.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:el_troso/core/branding/troso_loader.dart';
import 'package:el_troso/core/branding/troso_logo.dart';
import 'package:el_troso/core/theme.dart';
import 'package:el_troso/core/version.dart';
import 'package:el_troso/features/onboarding/onboarding_carousel_page.dart';
import 'package:el_troso/features/profile/profile_providers.dart';
import 'package:el_troso/l10n/app_localizations.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key, this.previewMode = false});

  /// Se true, NON redirige automaticamente: si limita a mostrare la
  /// splash come schermata persistente. Usato dal drawer in debug per
  /// far vedere il logo + loader senza dover rifare onboarding.
  final bool previewMode;

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();
    if (widget.previewMode) {
      debugPrint('[splash] previewMode=true, no redirect');
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profile = ref.read(profileProvider);
      final carouselSeen = ref.read(carouselSeenProvider);
      debugPrint(
          '[splash] postFrame profile=$profile carouselSeen=$carouselSeen');
      if (profile != null) {
        debugPrint('[splash] redirect → /home');
        context.go('/home');
      } else if (!carouselSeen) {
        debugPrint('[splash] redirect → /welcome (carousel)');
        context.go('/welcome');
      } else {
        debugPrint('[splash] no profile → landing');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    debugPrint(
      '[splash] render title="${l10n.appTitle}" '
      'tagline="${l10n.appTagline}" cta="${l10n.onbStart}"',
    );

    // Crema chiaro per testo/logo su sfondo olive (mockup branding).
    const Color onOlive = ElTrosoColors.background; // #F2EFEA

    return Scaffold(
      backgroundColor: ElTrosoColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            // Version badge in alto a destra. Su sfondo olive il colore
            // del badge default (onSurfaceVariant) sarebbe poco
            // leggibile: forziamo color crema con alpha basso per
            // mantenere "discreto".
            const Positioned(
              top: 8,
              right: 12,
              child: _OnOliveVersionBadge(),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),

                  // LOGO grande crema su olive.
                  const TrosoLogoFull(
                    textColor: onOlive,
                    fontSize: 64,
                  ),

                  const SizedBox(height: 32),

                  // Tagline italianizzata. Bianco sporco per leggibilita'.
                  Text(
                    l10n.appTagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: onOlive.withValues(alpha: 0.85),
                      fontStyle: FontStyle.italic,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Loader minimo durante il postFrame redirect. Anche
                  // se in pratica la splash dura 1 frame, il loader
                  // rinforza il branding del sentiero che si forma
                  // (mockup branding sez. "Indicatore di caricamento").
                  TrosoLoader(
                    size: 64,
                    color: onOlive,
                    ringColor: onOlive.withValues(alpha: 0.25),
                  ),

                  const SizedBox(height: 32),

                  // CTA principale (visibile solo se postFrame non ha
                  // navigato altrove). Filled crema su olive per stacco.
                  // In previewMode, "Comincia" diventa "Torna a casa".
                  FilledButton(
                    onPressed: () => context.go(
                      widget.previewMode ? '/home' : '/onboarding',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: onOlive,
                      foregroundColor: ElTrosoColors.primary,
                    ),
                    child: Text(
                      widget.previewMode ? l10n.walkBackHomeCta : l10n.onbStart,
                    ),
                  ),

                  const SizedBox(height: 8),

                  if (!widget.previewMode)
                    TextButton(
                      onPressed: () => context.go('/playground'),
                      child: Text(
                        l10n.playgroundTitle,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: onOlive.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Variante del VersionBadge per sfondi scuri (splash). Il default
/// usa onSurfaceVariant che non si vede su olive primary.
class _OnOliveVersionBadge extends StatelessWidget {
  const _OnOliveVersionBadge();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Text(
        kVersionLabel,
        style: const TextStyle(
          color: Color(0x8CF2EFEA), // crema con alpha 55%
          fontSize: 11,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
