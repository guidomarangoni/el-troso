// El Troso - Onboarding Carousel (5 schermate emozionali).
//
// Comportamento:
//   - Mostrato la prima volta che si apre l'app (prima dell'onboarding profilo).
//   - Richiamabile dal menu drawer in qualsiasi momento.
//   - 5 pagine con immagini watercolor, frasi poetiche, indicatore a pallini.
//   - Ultima pagina ha CTA "Sono pronto" che naviga all'onboarding profilo
//     (se primo accesso) o torna alla home (se richiamato dal menu).
//
// Le immagini sono asset statici in assets/onboarding/.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:el_troso/core/locale/language_switcher.dart';
import 'package:el_troso/core/theme.dart';
import 'package:el_troso/features/profile/profile_providers.dart';
import 'package:el_troso/l10n/app_localizations.dart';

/// Chiave SharedPreferences per sapere se l'onboarding carousel e' stato visto.
const String _kCarouselSeenKey = 'carousel_seen';

/// Provider semplice per leggere/scrivere lo stato "carousel visto".
final carouselSeenProvider = Provider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool(_kCarouselSeenKey) ?? false;
});

class OnboardingCarouselPage extends ConsumerStatefulWidget {
  const OnboardingCarouselPage({super.key});

  @override
  ConsumerState<OnboardingCarouselPage> createState() =>
      _OnboardingCarouselPageState();
}

class _OnboardingCarouselPageState
    extends ConsumerState<OnboardingCarouselPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Segna il carousel come visto e naviga avanti.
  Future<void> _complete() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_kCarouselSeenKey, true);

    if (!mounted) return;

    // Se l'utente ha gia' un profilo (richiamato dal menu) → torna a home.
    // Altrimenti (primo accesso) → vai all'onboarding profilo.
    final profile = ref.read(profileProvider);
    if (profile != null) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Dati delle 5 schermate.
    final pages = [
      _CarouselSlide(
        image: 'assets/onboarding/1_welcome.jpg',
        title: l10n.carouselWelcomeTitle,
        body: l10n.carouselWelcomeBody,
        titleStyle: theme.textTheme.headlineLarge?.copyWith(
          fontSize: 48,
          fontWeight: FontWeight.w600,
        ),
        bodyStyle: theme.textTheme.bodyLarge?.copyWith(
          fontStyle: FontStyle.italic,
          color: ElTrosoColors.textSecondary,
        ),
      ),
      _CarouselSlide(
        image: 'assets/onboarding/2_companion.jpg',
        title: l10n.carouselCompanionTitle,
        body: l10n.carouselCompanionBody,
      ),
      _CarouselSlide(
        image: 'assets/onboarding/3_record.jpg',
        title: l10n.carouselRecordTitle,
        body: l10n.carouselRecordBody,
      ),
      _CarouselSlide(
        image: 'assets/onboarding/4_rediscover.jpg',
        title: l10n.carouselRediscoverTitle,
        body: l10n.carouselRediscoverBody,
      ),
      _CarouselSlide(
        image: 'assets/onboarding/5_privacy.jpg',
        title: l10n.carouselPrivacyTitle,
        body: l10n.carouselPrivacyBody,
      ),
    ];

    final isFirst = _currentPage == 0;
    final isLast = _currentPage == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top bar: X chiudi a sinistra (se aperto dal menu),
            // language switcher al centro (build 41), skip a destra.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  // X chiudi: visibile solo se l'utente ha gia' un profilo
                  // (= ha aperto il carousel dal drawer, non e' il primo accesso).
                  if (ref.read(profileProvider) != null)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.go('/home'),
                    )
                  else
                    const SizedBox(width: 48),
                  const Spacer(),
                  // Language switcher: al primo accesso e' la prima
                  // affordance per cambiare lingua. Persistito tramite
                  // localeProvider.
                  const LanguageSwitcher(),
                  const Spacer(),
                  if (!isFirst && !isLast)
                    TextButton(
                      onPressed: _complete,
                      child: Text(
                        l10n.carouselSkip,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ElTrosoColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 48),
                ],
              ),
            ),

            // PageView con le slide.
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (index) =>
                    setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final slide = pages[index];
                  return _buildSlide(context, slide, index, pages.length);
                },
              ),
            ),

            // Dot indicator.
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (i) {
                  final isActive = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? ElTrosoColors.primary
                          : ElTrosoColors.textSecondary.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            // Bottom CTA.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: isLast
                  ? FilledButton(
                      onPressed: _complete,
                      child: Text(l10n.carouselPrivacyCta),
                    )
                  : isFirst
                      ? FilledButton(
                          onPressed: () => _controller.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          ),
                          child: Text(l10n.carouselWelcomeCta),
                        )
                      : OutlinedButton(
                          onPressed: () => _controller.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          ),
                          child: Text(l10n.carouselNext),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(
    BuildContext context,
    _CarouselSlide slide,
    int index,
    int total,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Immagine watercolor — occupa circa il 50% dello spazio.
          Expanded(
            flex: 5,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                slide.image,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Titolo.
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: slide.titleStyle ??
                theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),

          const SizedBox(height: 16),

          // Corpo poetico.
          Expanded(
            flex: 2,
            child: Text(
              slide.body,
              textAlign: TextAlign.center,
              style: slide.bodyStyle ??
                  theme.textTheme.bodyLarge?.copyWith(
                    color: ElTrosoColors.textSecondary,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dati di una singola slide del carousel.
class _CarouselSlide {
  const _CarouselSlide({
    required this.image,
    required this.title,
    required this.body,
    this.titleStyle,
    this.bodyStyle,
  });

  final String image;
  final String title;
  final String body;
  final TextStyle? titleStyle;
  final TextStyle? bodyStyle;
}
