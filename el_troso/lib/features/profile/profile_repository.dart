// El Troso - repository Profile su shared_preferences (Fase 4.4.e).
//
// Contratto: una singola chiave "profile" contiene un JSON-encoded Profile.
// Scegliamo JSON (non chiavi separate name/vocative/decade) perche':
// - atomicita' di lettura: load() e' un singolo decode, non 3 getString.
// - forward-compat: quando aggiungeremo campi (walker preferiti, voce
//   TTS selezionata) non dobbiamo sincronizzare get/set su piu' chiavi.
//
// shared_preferences e' sufficiente per un oggetto di dimensione trascurabile
// come questo. Se in futuro il profilo dovesse diventare grosso si migra a
// Hive o a SQLite, ma e' improbabile: il profilo e' poche stringhe.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile.dart';

/// Chiave unica nel SharedPreferences store.
const String _kProfileKey = 'el_troso.profile.v1';

class ProfileRepository {
  final SharedPreferences _prefs;

  ProfileRepository(this._prefs);

  /// Restituisce il profilo salvato, o null se non esiste ancora
  /// (first-run / profilo cancellato).
  Profile? load() {
    final raw = _prefs.getString(_kProfileKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return Profile.fromJson(decoded);
    } catch (_) {
      // Se il JSON e' corrotto (es. downgrade di schema) lo trattiamo come
      // assenza di profilo: l'onboarding ripartira'. Meglio che crashare.
      return null;
    }
  }

  /// Salva il profilo sovrascrivendo quello precedente.
  Future<void> save(Profile profile) async {
    final raw = jsonEncode(profile.toJson());
    await _prefs.setString(_kProfileKey, raw);
  }

  /// Cancella il profilo (usato da "Ricomincia il sentiero" nei Settings).
  Future<void> clear() async {
    await _prefs.remove(_kProfileKey);
  }
}
