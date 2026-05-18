// El Troso - providers Riverpod per Memory (Fase 4.5.a).
//
// Tre provider:
//   1. memoryRepositoryProvider — singola istanza del repo. Stateless → un
//      solo provider globale, niente override richiesti.
//   2. memoriesProvider — StateNotifierProvider<MemoriesController,
//      AsyncValue<List<Memory>>> — lo stato dei ricordi letti dal disco.
//      AsyncValue perche' il primo load e' async e vogliamo poter mostrare
//      skeleton/loading nella home; dopo il load riuscito le write emettono
//      nuovi AsyncData senza ri-passare da loading.
//   3. (futuro) recentMemoriesProvider — computed sul precedente, top-N
//      ordinati per createdAt desc. Lasciato in 4.5.b dove serve alla home.
//
// Pattern: StateNotifier + AsyncValue (non AsyncNotifier) perche' la app
// gia' usa StateNotifier altrove (profile) → coerenza > purezza. Il costo
// di emettere AsyncValue manualmente e' minimo e resta leggibile.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'memory.dart';
import 'memory_repository.dart';
import 'seed_loader.dart';
import 'vector_store_provider.dart';

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepository();
});

/// Signal globale: id del ricordo appena calpestato + timestamp.
/// Settato da MemoriesController.updateMemory() quando il numero di
/// walks cresce. Letto dalla home per:
///   - mini-card "Calpestio registrato" (visibile 5s)
///   - animazione "orma che si accende" sull'icona corrispondente
///     nella MemoriesList
///
/// Usiamo StateProvider invece di un controller dedicato perche' lo
/// stato e' atomico (singolo evento + auto-cleanup via timestamp
/// check lato consumer), no stream di eventi.
class LastWalk {
  final String memoryId;
  final DateTime at;
  const LastWalk({required this.memoryId, required this.at});

  /// True se il walk e' stato registrato nei ultimi [seconds] secondi.
  bool isFresh({int seconds = 5}) {
    return DateTime.now().difference(at).inSeconds < seconds;
  }
}

final lastWalkProvider = StateProvider<LastWalk?>((ref) => null);

/// SeedLoader: importa i ricordi del libro "Nonno parlaci di te" dal
/// bundle. Usato dal playground (debug) e potenzialmente da uno step
/// dell'onboarding ("hai un libro di ricordi?"). Stateless wrapper su
/// repository + vector store.
final seedLoaderProvider = Provider<SeedLoader>((ref) {
  return SeedLoader(
    repository: ref.watch(memoryRepositoryProvider),
    vectorStore: ref.watch(vectorStoreServiceProvider),
  );
});

class MemoriesController extends StateNotifier<AsyncValue<List<Memory>>> {
  MemoriesController(this._repo, this._ref) : super(const AsyncValue.loading()) {
    _loadInitial();
  }

  final MemoryRepository _repo;
  final Ref _ref;

  Future<void> _loadInitial() async {
    try {
      final list = await _repo.load();
      if (!mounted) return;
      state = AsyncValue.data(list);
      debugPrint('[memories_ctrl] initial load → ${list.length}');
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
      debugPrint('[memories_ctrl] initial load failed: $e');
    }
  }

  /// Reload esplicito (es. dopo import/reset). Passa attraverso loading.
  Future<void> reload() async {
    state = const AsyncValue.loading();
    await _loadInitial();
  }

  /// Aggiunge un ricordo. Fallisce silenziosamente ri-emettendo errore:
  /// chi chiama decide se notificare l'utente via SnackBar.
  Future<void> add(Memory m) async {
    final current = state.valueOrNull ?? const <Memory>[];
    try {
      final updated = await _repo.add(m, current);
      if (!mounted) return;
      state = AsyncValue.data(updated);
    } catch (e, st) {
      if (!mounted) return;
      // Non distruggere lo stato dati precedente: mantieni la lista corrente
      // ma segnala errore. AsyncError con value precedente = pattern Riverpod.
      state = AsyncValue.error(e, st);
      debugPrint('[memories_ctrl] add failed: $e');
    }
  }

  /// Aggiorna un ricordo esistente (es. aggiunta walk in F12).
  /// Cerca per id e sostituisce; se non trovato, no-op silenzioso.
  /// Se il numero di walks e' cresciuto, emette il signal globale
  /// `lastWalkProvider` per animazioni di accensione orma + mini-card
  /// di conferma in home.
  Future<void> updateMemory(Memory updated) async {
    final current = state.valueOrNull ?? const <Memory>[];
    final idx = current.indexWhere((m) => m.id == updated.id);
    if (idx < 0) {
      debugPrint('[memories_ctrl] update: id=${updated.id} not found → no-op');
      return;
    }
    final previous = current[idx];
    final isNewWalk = updated.walks.length > previous.walks.length;
    try {
      final list = List<Memory>.from(current);
      list[idx] = updated;
      await _repo.saveAll(list);
      if (!mounted) return;
      state = AsyncValue.data(list);
      // Emetti il signal SOLO se un walk e' stato effettivamente aggiunto
      // (non per altre modifiche tipo tag/walker rinominati).
      if (isNewWalk) {
        _ref.read(lastWalkProvider.notifier).state = LastWalk(
          memoryId: updated.id,
          at: DateTime.now(),
        );
      }
      debugPrint(
        '[memories_ctrl] update: ${updated.id} ok '
        '(walks ${previous.walks.length}→${updated.walks.length}, '
        'newWalk=$isNewWalk)',
      );
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
      debugPrint('[memories_ctrl] update failed: $e');
    }
  }

  /// Rimuove per id. Stessa filosofia di add().
  Future<void> delete(String id) async {
    final current = state.valueOrNull ?? const <Memory>[];
    try {
      final updated = await _repo.delete(id, current);
      if (!mounted) return;
      state = AsyncValue.data(updated);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
      debugPrint('[memories_ctrl] delete failed: $e');
    }
  }
}

final memoriesProvider =
    StateNotifierProvider<MemoriesController, AsyncValue<List<Memory>>>((ref) {
  final repo = ref.watch(memoryRepositoryProvider);
  return MemoriesController(repo, ref);
});
