// El Troso - Drawer (menu hamburger).
//
// Menu laterale leggero, discreto, coerente con la palette El Troso.
// Voci:
//   - Casa (home)
//   - Racconta un ricordo (record/new)
//   - Fai una domanda (ask)
//   - Come funziona (onboarding carousel)
//   - Playground (dev) — solo in debug
//
// Il drawer e' richiamabile dalla home via l'icona hamburger nell'AppBar.
// Nessuna immagine pesante nel drawer: solo icone Material + testo warm brown.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:el_troso/core/branding/troso_logo.dart';
import 'package:el_troso/core/locale/language_switcher.dart';
import 'package:el_troso/core/theme.dart';
import 'package:el_troso/features/profile/profile_providers.dart';
import 'package:el_troso/l10n/app_localizations.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = ref.watch(profileProvider);

    // Vocativo per l'header del drawer.
    final display = profile == null
        ? l10n.appTitle
        : (profile.vocative.isNotEmpty ? profile.vocative : profile.name);

    return Drawer(
      backgroundColor: ElTrosoColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header con logo brand. 4.5.l: usiamo TrosoLogoFull per
            // far vedere il branding ad ogni apertura del menu (frequente
            // contro splash che e' invisibile dopo onboarding).
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 8),
              child: TrosoLogoFull(
                textColor: ElTrosoColors.primary,
                fontSize: 36,
              ),
            ),
            if (profile != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Text(
                  display,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: ElTrosoColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),

            Divider(
              color: ElTrosoColors.textSecondary.withValues(alpha: 0.2),
              height: 1,
            ),

            const SizedBox(height: 8),

            // Menu items.
            _DrawerItem(
              icon: Icons.home_outlined,
              label: l10n.drawerHome,
              onTap: () {
                Navigator.of(context).pop();
                context.go('/home');
              },
            ),
            _DrawerItem(
              icon: Icons.edit_note_outlined,
              label: l10n.drawerRecord,
              onTap: () {
                Navigator.of(context).pop();
                context.go('/record/new');
              },
            ),
            _DrawerItem(
              icon: Icons.chat_bubble_outline,
              label: l10n.drawerAsk,
              onTap: () {
                Navigator.of(context).pop();
                context.go('/ask');
              },
            ),

            const SizedBox(height: 8),
            Divider(
              color: ElTrosoColors.textSecondary.withValues(alpha: 0.2),
              height: 1,
            ),
            const SizedBox(height: 8),

            _DrawerItem(
              icon: Icons.info_outline,
              label: l10n.drawerOnboarding,
              onTap: () {
                Navigator.of(context).pop();
                context.go('/welcome');
              },
            ),

            // Playground: solo in modalita' debug.
            if (kDebugMode)
              _DrawerItem(
                icon: Icons.science_outlined,
                label: l10n.drawerPlayground,
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/playground');
                },
              ),
            // Schermata "preparazione sentiero" (debug): permette a Guido
            // di rivedere il loader animato senza dover disinstallare i
            // modelli. La schermata in produzione si attiva solo se i
            // modelli mancano.
            if (kDebugMode)
              _DrawerItem(
                icon: Icons.downloading_outlined,
                label: 'Loader sentiero (dev)',
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/loading-model');
                },
              ),
            // Splash standalone (debug): permette di vedere il logo
            // grande + loader indeterminato senza dover rifare onboarding.
            if (kDebugMode)
              _DrawerItem(
                icon: Icons.brightness_5_outlined,
                label: 'Splash (dev)',
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/splash-preview');
                },
              ),

            const Spacer(),

            // Sezione lingua (build 41). Visibile in fondo, sopra il
            // footer: scelta esplicita IT/EN persistente. Vedi
            // language_switcher.dart e core/locale/locale_provider.dart.
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.drawerLanguage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: ElTrosoColors.textSecondary,
                    ),
                  ),
                  const LanguageSwitcher(),
                ],
              ),
            ),
            Divider(
              color: ElTrosoColors.textSecondary.withValues(alpha: 0.2),
              height: 1,
              indent: 24,
              endIndent: 24,
            ),

            // Footer discreto: versione.
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'v1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: ElTrosoColors.textSecondary.withValues(alpha: 0.5),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Singola voce del drawer. Touch target generoso (56dp).
class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: ElTrosoColors.textSecondary,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
