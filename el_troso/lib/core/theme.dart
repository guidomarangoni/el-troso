// El Troso - theme Material 3.
// Fase 4.4.c - implementa palette + typography di STITCH_PROMPT.md §5.
//
// Regole chiave:
// - L'app e' light-only. La metafora parla di sentieri all'alba e diario
//   invecchiato, non di notti (dark mode rimandato a Fase 5).
// - Nessuna dipendenza da Google Fonts ancora: in 4.2 si decide tra
//   Nunito vs Lora vs altro e si integra via google_fonts. Per ora font
//   di sistema - sufficiente per verificare size minime e contrasti.
// - Size minime NON negoziabili (WCAG 2.2 + Pak & McLaughlin 2018):
//   body ricordo 24, CTA 32, chip 20, caption 18. Se serve testo piu'
//   piccolo (metadata interno) si usa bodySmall 14 ma NON deve essere
//   leggibile dall'utente finale.
// - Touch target minimo 48dp garantito via FilledButtonThemeData.

import 'package:flutter/material.dart';

/// Palette El Troso. Hex da STITCH_PROMPT.md §5 (non negoziabili).
class ElTrosoColors {
  ElTrosoColors._();

  static const Color primary = Color(0xFF6B7F5A); // verde oliva
  static const Color accent = Color(0xFFC98C3C); // ocra bruciata
  // Aggiornato al mockup branding 2026-04-25: crema piu' chiara/neutra
  // (#F2EFEA) per coerenza con loader e splash. Vecchio era #F5EBD6
  // (crema-giallo piu' caldo). Il warmth resta nel primary + accent.
  static const Color background = Color(0xFFF2EFEA); // crema pergamena chiara
  static const Color surface = Color(0xFFFFFFFF); // bianco puro
  static const Color textPrimary = Color(0xFF3D2F1F); // bruno scuro
  static const Color textSecondary = Color(0xFF6B5A47); // bruno caldo
  static const Color faded = Color(0xFF8B5A3C); // bruno terra

  // Scale di opacity per il pattern "orme che sbiadiscono" (F12).
  // Applicato come opacity su icona/orma, non come colore separato —
  // cosi' e' coerente per tutti i ricordi.
  static const double footprintBright = 1.0;
  static const double footprintFading = 0.6;
  static const double footprintGhost = 0.3;
}

/// TextTheme El Troso. Size minime da STITCH_PROMPT.md §5.
///
/// Mapping intenzionale Material 3 → contesto app:
/// - displayLarge / displayMedium → non usate (l'app non ha schermi-hero)
/// - headlineLarge → tagline onboarding / titoli schermata
/// - headlineSmall → nome ricordo nel detail
/// - titleLarge → section header
/// - bodyLarge → testo ricordo (24pt, leggibilita' primaria)
/// - bodyMedium → testo chat / domande
/// - labelLarge → CTA bottoni (32pt)
/// - labelMedium → chip (20pt)
/// - labelSmall → caption / metadata (18pt, LIMITE ASSOLUTO)
ThemeData buildElTrosoTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme(
      brightness: Brightness.light,
      primary: ElTrosoColors.primary,
      onPrimary: Colors.white,
      secondary: ElTrosoColors.accent,
      onSecondary: Colors.white,
      tertiary: ElTrosoColors.faded,
      onTertiary: Colors.white,
      error: ElTrosoColors.faded, // non rosso: stati neutri, non allarme
      onError: Colors.white,
      surface: ElTrosoColors.surface,
      onSurface: ElTrosoColors.textPrimary,
      surfaceContainerHighest: ElTrosoColors.background,
      onSurfaceVariant: ElTrosoColors.textSecondary,
      outline: ElTrosoColors.textSecondary,
    ),
    scaffoldBackgroundColor: ElTrosoColors.background,
  );

  final textTheme = base.textTheme.copyWith(
    // Headline: tagline onboarding, saluto home
    headlineLarge: base.textTheme.headlineLarge?.copyWith(
      fontSize: 28,
      height: 1.3,
      color: ElTrosoColors.textPrimary,
      fontWeight: FontWeight.w500,
    ),
    headlineMedium: base.textTheme.headlineMedium?.copyWith(
      fontSize: 24,
      height: 1.3,
      color: ElTrosoColors.textPrimary,
      fontWeight: FontWeight.w500,
    ),
    headlineSmall: base.textTheme.headlineSmall?.copyWith(
      fontSize: 22,
      height: 1.3,
      color: ElTrosoColors.textPrimary,
    ),
    titleLarge: base.textTheme.titleLarge?.copyWith(
      fontSize: 22,
      height: 1.3,
      color: ElTrosoColors.textPrimary,
      fontWeight: FontWeight.w600,
    ),
    // Body: testo ricordo 24pt
    bodyLarge: base.textTheme.bodyLarge?.copyWith(
      fontSize: 24,
      height: 1.4,
      color: ElTrosoColors.textPrimary,
    ),
    bodyMedium: base.textTheme.bodyMedium?.copyWith(
      fontSize: 20,
      height: 1.4,
      color: ElTrosoColors.textPrimary,
    ),
    bodySmall: base.textTheme.bodySmall?.copyWith(
      fontSize: 18,
      height: 1.35,
      color: ElTrosoColors.textSecondary,
    ),
    // Label: CTA 32pt, chip 20pt, caption 18pt
    labelLarge: base.textTheme.labelLarge?.copyWith(
      fontSize: 28, // 32 e' spesso troppo su bottoni full-width;
      // usiamo 28 come baseline CTA e lasciamo ai singoli widget di
      // forzare 32 dove la composizione lo sopporta (home H1 cardine).
      height: 1.2,
      fontWeight: FontWeight.w600,
      color: ElTrosoColors.textPrimary,
    ),
    labelMedium: base.textTheme.labelMedium?.copyWith(
      fontSize: 20,
      height: 1.2,
      color: ElTrosoColors.textPrimary,
    ),
    labelSmall: base.textTheme.labelSmall?.copyWith(
      fontSize: 18,
      height: 1.25,
      color: ElTrosoColors.textSecondary,
    ),
  );

  return base.copyWith(
    textTheme: textTheme,

    // CTA bottoni: touch target generoso, angoli morbidi, padding
    // coerente con un tap pollice/indice di anziano.
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: ElTrosoColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 64), // 64 > 48dp WCAG
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        textStyle: textTheme.labelLarge,
      ),
    ),

    // Outlined: secondaria (es. "Salta", "Altro").
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ElTrosoColors.textPrimary,
        side: const BorderSide(color: ElTrosoColors.textSecondary, width: 1.5),
        minimumSize: const Size(0, 56),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: textTheme.labelMedium,
      ),
    ),

    // Chip (tag, walker, vocativo): compatta ma leggibile (20pt).
    chipTheme: ChipThemeData(
      backgroundColor: Colors.white,
      selectedColor: ElTrosoColors.accent,
      labelStyle: textTheme.labelMedium,
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: ElTrosoColors.textSecondary, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    ),

    // Card: ricordi + messaggi chat. Bordo sottile invece di shadow per
    // feel "diario" e non "dashboard".
    cardTheme: CardThemeData(
      color: ElTrosoColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: ElTrosoColors.textSecondary.withValues(alpha: 0.2)),
      ),
      margin: const EdgeInsets.symmetric(vertical: 6),
    ),

    // Input (campo nome in onboarding, campo domanda in Atto 3).
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ElTrosoColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ElTrosoColors.textSecondary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
            color: ElTrosoColors.textSecondary.withValues(alpha: 0.4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: ElTrosoColors.primary, width: 2),
      ),
      hintStyle: textTheme.bodyMedium
          ?.copyWith(color: ElTrosoColors.textSecondary),
      labelStyle: textTheme.bodyMedium?.copyWith(
        color: ElTrosoColors.textSecondary,
      ),
    ),

    // AppBar: sobria, crema su testo bruno. La metafora non vuole
    // inversePrimary/surfaceTint tipici M3 dashboard.
    appBarTheme: AppBarTheme(
      backgroundColor: ElTrosoColors.background,
      foregroundColor: ElTrosoColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),

    // Dividers: sottili, calde.
    dividerTheme: DividerThemeData(
      color: ElTrosoColors.textSecondary.withValues(alpha: 0.2),
      thickness: 1,
      space: 24,
    ),
  );
}
