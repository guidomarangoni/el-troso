// El Troso - repository per Memory (Fase 4.5.a).
//
// Persistenza JSON su file nel documents directory del device.
// Path: {ApplicationDocumentsDirectory}/memories.json
//
// Formato file:
//   [ {id, text, createdAt}, {...}, ... ]
//
// Scelte:
// - File JSON singolo, non DB (sqflite/drift). In 4.5.a abbiamo ordine di
//   10-100 ricordi per device: un singolo JSON resta < 1 MB e si legge in
//   memoria istantaneamente. Se scala a migliaia di ricordi (improbabile
//   per il testimonial 86enne) si migra a Drift con una migration da JSON.
// - Il file vive in ApplicationDocumentsDirectory (backup iCloud/Google per
//   default), non in Cache. Perdere un ricordo per pulizia cache sarebbe un
//   disastro emotivo.
// - load() tollera file mancante (prima run) e JSON corrotto (non crasha,
//   logga e ritorna lista vuota). La corruzione di questo file e' low-risk
//   perche' lo scriviamo atomicamente (write su tmp + rename), ma la
//   difesa in profondita' vale la riga extra.
// - saveAll() e' atomico: scrive su {path}.tmp e poi rename. Previene
//   corruzione se il processo muore a meta' scrittura.
// - add() ritorna la lista nuova cosi' il Notifier puo' emettere stato
//   senza una seconda load().

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'memory.dart';

class MemoryRepository {
  static const _fileName = 'memories.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  /// Carica tutti i ricordi. Se il file non esiste, ritorna lista vuota.
  Future<List<Memory>> load() async {
    final file = await _file();
    if (!await file.exists()) {
      debugPrint('[memory_repo] load: file assente → []');
      return const [];
    }
    try {
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        debugPrint(
          '[memory_repo] load: root non e\' lista (${decoded.runtimeType}) → []',
        );
        return const [];
      }
      final list = decoded
          .whereType<Map<String, dynamic>>()
          .map(Memory.fromJson)
          .toList();
      debugPrint('[memory_repo] load: ${list.length} ricordi');
      return list;
    } catch (e, st) {
      // Corruzione: logghiamo e ritorniamo vuoto. Non cancelliamo il file
      // cosi' eventuale debug post-mortem resta possibile.
      debugPrint('[memory_repo] load: JSON corrotto ($e)\n$st → []');
      return const [];
    }
  }

  /// Salva TUTTA la lista in modo atomico (tmp + rename).
  Future<void> saveAll(List<Memory> memories) async {
    final file = await _file();
    final tmp = File('${file.path}.tmp');
    final payload =
        jsonEncode(memories.map((m) => m.toJson()).toList(growable: false));
    await tmp.writeAsString(payload, flush: true);
    await tmp.rename(file.path);
    debugPrint(
      '[memory_repo] saveAll: ${memories.length} ricordi → ${file.path}',
    );
  }

  /// Aggiunge un ricordo in testa (piu' recente prima) e persiste.
  /// Ritorna la lista aggiornata.
  Future<List<Memory>> add(Memory m, List<Memory> current) async {
    final updated = [m, ...current];
    await saveAll(updated);
    debugPrint('[memory_repo] add: $m (tot=${updated.length})');
    return updated;
  }

  /// Rimuove il ricordo con [id] e persiste. Ritorna la lista aggiornata.
  Future<List<Memory>> delete(String id, List<Memory> current) async {
    final updated = current.where((m) => m.id != id).toList();
    await saveAll(updated);
    debugPrint(
      '[memory_repo] delete: $id (tot=${updated.length}, before=${current.length})',
    );
    return updated;
  }
}
