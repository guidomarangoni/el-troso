// El Troso - locale override utente (build 41).
//
// Permette all'utente di scegliere esplicitamente la lingua dell'app
// (IT/EN), persistente tra avvii. Quando lo stato e' null, MaterialApp
// ricade sull'auto-detect dal device locale (vedi
// localeListResolutionCallback in main.dart).
//
// Storia: build 36 ha introdotto l'auto-detect IT/EN. Build 41 aggiunge
// la scelta esplicita perche' il device locale non sempre coincide con
// la preferenza dell'utente (es. famiglia italiana che usa il telefono
// in inglese, o tester che vogliono provare le due UI senza dover
// cambiare la system locale).
//
// Persistenza: chiave 'el_troso.user_locale' in SharedPreferences.
// Valori: 'it' | 'en' | (assente = auto).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:el_troso/features/profile/profile_providers.dart';

const String _kUserLocaleKey = 'el_troso.user_locale';

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._prefs) : super(_load(_prefs));

  final SharedPreferences _prefs;

  static Locale? _load(SharedPreferences prefs) {
    final code = prefs.getString(_kUserLocaleKey);
    if (code == 'it') return const Locale('it');
    if (code == 'en') return const Locale('en');
    return null;
  }

  /// Imposta la locale e persiste. Passa null per tornare all'auto-detect.
  Future<void> setLocale(Locale? locale) async {
    if (locale == null) {
      await _prefs.remove(_kUserLocaleKey);
    } else {
      await _prefs.setString(_kUserLocaleKey, locale.languageCode);
    }
    state = locale;
  }
}

/// Stato: Locale? (null = auto-detect dal device).
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});
