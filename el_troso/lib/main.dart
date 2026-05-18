// El Troso - app entry point (Fase 4.4.e).
//
// Da qui in poi la UI di test (pulsanti 1-9) non vive piu' qui: e' stata
// spostata a lib/features/playground/playground_page.dart e raggiungibile
// alla rotta /playground (link "dev" nella SplashPage, icona scienziato in
// AppBar di HomePage). Questo file ora fa:
//   1. Init WidgetsBinding + FlutterGemma
//   2. Preload SharedPreferences PRIMA di runApp (async) cosi' il resto
//      dell'app puo' leggere il profilo in modo sincrono tramite Riverpod
//      (override di sharedPreferencesProvider)
//   3. Monta ProviderScope (Riverpod root) con override
//   4. Costruisce MaterialApp.router con theme + l10n delegates + go_router
//
// La locale iniziale e' lasciata a sistema (MaterialApp sceglie tra le
// supportedLocales guardando Locale.of(context) = device locale).
// In una fase successiva aggiungeremo un `languageProvider` che legge la
// scelta utente da shared_preferences ed esegue l'override esplicito.

import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:el_troso/core/locale/locale_provider.dart';
import 'package:el_troso/core/router.dart';
import 'package:el_troso/core/theme.dart';
import 'package:el_troso/features/profile/profile_providers.dart';
import 'package:el_troso/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Modern API v0.13.x: init del plugin prima di runApp.
  // Tutti i parametri sono opzionali (fonte: README flutter_gemma main).
  FlutterGemma.initialize();

  // intl date symbols: serve per DateFormat('... MMMM ...', 'it') nella
  // pagina dettaglio ricordo (4.5.c). Senza init lancia LocaleDataException.
  // Passando null carichiamo tutte le locali supportate (payload piccolo).
  await initializeDateFormatting();

  // Preload SharedPreferences: SharedPreferences.getInstance() e' async ma
  // serve solo una volta. Risolvendolo qui e passando l'istanza via override
  // del provider, evitiamo di dover gestire AsyncValue<SharedPreferences>
  // nel grafo widget (niente spinner sul profilo in home).
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const ElTrosoApp(),
    ),
  );
}

class ElTrosoApp extends ConsumerWidget {
  const ElTrosoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Build 41: scelta lingua esplicita dell'utente. Se l'utente ha
    // scelto IT/EN dal drawer/carousel, override; altrimenti null →
    // si usa la localeListResolutionCallback (auto-detect device).
    final userLocale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'El Troso',
      debugShowCheckedModeBanner: false,
      theme: buildElTrosoTheme(),
      // Light-only fino a Fase 5. Forziamo light esplicitamente cosi' la
      // app non si "scurisce" se il device e' in dark mode (il design El
      // Troso e' pensato su crema pergamena, non su sfondo scuro).
      themeMode: ThemeMode.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Override esplicito (build 41). Quando non null vince sulla
      // localeListResolutionCallback. La UI ricostruisce automaticamente
      // perche' watchiamo localeProvider sopra.
      locale: userLocale,
      // Risoluzione locale custom (build 36): se la lingua del device
      // è italiano → IT, qualunque altra lingua → EN. Si attiva solo
      // quando userLocale e' null (= utente non ha scelto esplicitamente).
      // Senza questa callback Flutter usa BasicLocaleListResolutionCallback
      // che fa fallback al PRIMO supportedLocale (it) per le lingue non
      // supportate, dando UI italiana a un utente tedesco / spagnolo.
      // Coerente con la decisione di scope "demo IT + EN, le altre
      // lingue sono capability di Gemma, non UI" (BACKLOG_POST_HACKATHON).
      localeListResolutionCallback: (deviceLocales, supported) {
        if (deviceLocales != null) {
          for (final loc in deviceLocales) {
            if (loc.languageCode == 'it') return const Locale('it');
          }
        }
        return const Locale('en');
      },
      routerConfig: appRouter,
    );
  }
}
