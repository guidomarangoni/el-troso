// El Troso - widget test smoke (Fase 4.4.e).
//
// Sostituisce il test "counter increments" del template Flutter (che
// referenziava MyApp, rimosso in Fase 4.4.d). Qui verifichiamo solo che
// l'app si monti senza eccezioni e che la splash mostri il nome dell'app.
// Test piu' specifici sulle feature (onboarding, racconto, ripercorri)
// arrivano nelle rispettive sub-fase.
//
// Nota 4.4.e: dobbiamo fornire un SharedPreferences in-memory tramite
// override di sharedPreferencesProvider, altrimenti il provider throw-a
// UnimplementedError (in runtime vero viene overridato in main.dart dopo
// SharedPreferences.getInstance()). Usiamo setMockInitialValues con una
// mappa vuota cosi' profileProvider legge null → splash non redirige.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:el_troso/features/profile/profile_providers.dart';
import 'package:el_troso/main.dart';

void main() {
  testWidgets('ElTrosoApp si monta e mostra la splash', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const ElTrosoApp(),
      ),
    );
    // pumpAndSettle per lasciar risolvere MaterialApp.router + l10n.
    await tester.pumpAndSettle();

    // La SplashPage mostra il titolo "El Troso" in grande. Cerchiamo
    // almeno un'occorrenza - findsWidgets (non findsOneWidget) perche'
    // in futuro l'AppBar di altre schermate potrebbe ripetere la stringa.
    expect(find.text('El Troso'), findsWidgets);
  });
}
