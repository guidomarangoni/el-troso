// El Troso - Riverpod providers per Profile (Fase 4.4.e).
//
// Tre provider:
//   1. sharedPreferencesProvider  - istanza unica SharedPreferences.
//      E' un Provider "puro" che throw-a se non viene overridato: lo
//      facciamo perche' SharedPreferences.getInstance() e' async e lo
//      vogliamo risolvere UNA VOLTA nel main() prima di runApp, senza
//      costringere ogni widget a gestire AsyncValue<SharedPreferences>.
//   2. profileRepositoryProvider  - ProfileRepository semplice, sync.
//   3. profileProvider            - StateNotifier-like che espone il
//      profilo attuale (Profile?) al grafo di widget. null = onboarding
//      non ancora completato. .save()/.clear() modifica lo stato.
//
// Scelta di StateNotifier (anziche' AsyncNotifier): il "load" e' di fatto
// sincrono (SharedPreferences e' gia' in memoria dopo l'override iniziale),
// quindi non abbiamo bisogno del ciclo loading/data/error di AsyncNotifier.
// Le scritture sono async ma emettono stato dopo il complete, senza bisogno
// di un AsyncValue intermedio.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile.dart';
import 'profile_repository.dart';

/// DEVE essere overridato nel ProviderScope root (in main.dart) con
/// l'istanza risolta via SharedPreferences.getInstance().
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider non e\' stato overridato. '
    'In main(): await SharedPreferences.getInstance() poi '
    'ProviderScope(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]).',
  );
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ProfileRepository(prefs);
});

/// Stato: Profile? (null = onboarding non fatto).
///
/// La UI osserva questo provider con ref.watch; la navigazione splash/home
/// e' branched su (state == null).
class ProfileNotifier extends StateNotifier<Profile?> {
  ProfileNotifier(this._repo) : super(_repo.load());

  final ProfileRepository _repo;

  /// Salva il profilo e aggiorna lo stato. Usato da onboarding S3 (completa).
  Future<void> save(Profile profile) async {
    await _repo.save(profile);
    state = profile;
  }

  /// Cancella il profilo (Settings → "Ricomincia il sentiero").
  Future<void> clear() async {
    await _repo.clear();
    state = null;
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, Profile?>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repo);
});
