// El Troso - language switcher chip (build 41).
//
// Pillola compatta IT · EN per cambiare lingua al volo. Usata in:
//   - top-right del carousel onboarding (primo accesso)
//   - drawer hamburger (in ogni momento dopo l'onboarding)
//
// La lingua attiva visualizza con peso/colore primary; l'altra è
// dimmed e tappabile. Tap → setLocale → MaterialApp ricostruisce con
// la nuova locale, tutto l'albero ARB si aggiorna immediatamente.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:el_troso/core/locale/locale_provider.dart';
import 'package:el_troso/core/theme.dart';

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({
    super.key,
    this.onLight = false,
  });

  /// Se true, ottimizza i colori per sfondi scuri (es. splash olive).
  final bool onLight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Lingua attiva: explicit override > device locale corrente.
    final override = ref.watch(localeProvider);
    final active = override?.languageCode ??
        Localizations.localeOf(context).languageCode;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LangButton(
          code: 'IT',
          isActive: active == 'it',
          onLight: onLight,
          onTap: () => ref
              .read(localeProvider.notifier)
              .setLocale(const Locale('it')),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '·',
            style: TextStyle(
              color: onLight
                  ? Colors.white.withValues(alpha: 0.5)
                  : ElTrosoColors.textSecondary.withValues(alpha: 0.5),
            ),
          ),
        ),
        _LangButton(
          code: 'EN',
          isActive: active == 'en',
          onLight: onLight,
          onTap: () => ref
              .read(localeProvider.notifier)
              .setLocale(const Locale('en')),
        ),
      ],
    );
  }
}

class _LangButton extends StatelessWidget {
  const _LangButton({
    required this.code,
    required this.isActive,
    required this.onTap,
    required this.onLight,
  });

  final String code;
  final bool isActive;
  final VoidCallback onTap;
  final bool onLight;

  @override
  Widget build(BuildContext context) {
    final activeColor = onLight ? Colors.white : ElTrosoColors.primary;
    final inactiveColor = onLight
        ? Colors.white.withValues(alpha: 0.5)
        : ElTrosoColors.textSecondary.withValues(alpha: 0.7);

    return InkWell(
      onTap: isActive ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          code,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? activeColor : inactiveColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
