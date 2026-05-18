// El Troso - SeedLoader (Fase 4.5.g).
//
// Carica un set di "ricordi seed" pre-distillati dal libro autobiografico
// di Giorgio ("Nonno parlaci di te", gennaio 2025) per popolare la app a
// uso demo / dev. La loadability del seed e' indispensabile per:
//   - mostrare i giochi (G1 memory matching, G3 riconosci foto, G4 SRT)
//     senza dover prima registrare 10 ricordi a mano
//   - registrare il video Kaggle con materiale reale gia' validato
//   - far girare gli stress test con corpus realistico
//
// Il seed vive in assets/seed/:
//   - memories.json   manifesto: lista di Memory con imagePath relativo
//   - used/seed_*.jpg le 6 foto effettivamente usate (~500 KB totali)
//
// Workflow di import:
//   1. rootBundle.loadString('assets/seed/memories.json')
//   2. parse → List<Map<String, dynamic>>
//   3. per ogni entry:
//      a. carica i bytes della foto dal bundle (rootBundle.load)
//      b. scrivi i bytes in {appDocs}/images/{id}.jpg
//      c. costruisci Memory con imagePath che punta al path locale
//   4. saveAll su MemoryRepository (atomico)
//   5. fire-and-forget addMemory sul VectorStoreService per indicizzare RAG
//
// Comportamento di sicurezza:
//   - Idempotente: se il seed e' gia' stato caricato (rilevato via id
//     che inizia con "seed_") NON ri-importa per evitare duplicati.
//   - Non distrugge i ricordi dell'utente: il seed viene MERGED in cima
//     alla lista esistente (nuovi prima, vecchi dopo). Se l'utente vuole
//     "azzerare e ripartire dai seed" deve passare clearFirst=true.
//   - Non dipende da rete: tutto da bundle assets.
//
// Vincolo etico onorato:
//   - I testi dei ricordi sono distillati LETTERALMENTE dal libro di
//     Giorgio (validation_status nel JSON), NON inventati. Vedi
//     `feedback_no_invented_facts.md` in memory/.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import 'memory.dart';
import 'memory_repository.dart';
import 'vector_store_service.dart';

class SeedLoader {
  SeedLoader({
    required this.repository,
    required this.vectorStore,
  });

  final MemoryRepository repository;
  final VectorStoreService vectorStore;

  static const String _kSeedManifest = 'assets/seed/memories.json';

  /// Carica i ricordi seed dal bundle e li aggiunge al repository.
  ///
  /// Se [clearFirst] e' true, cancella TUTTI i ricordi esistenti prima
  /// di caricare i seed. Default false: il seed viene mergiato in cima
  /// ai ricordi esistenti, evitando duplicati di id.
  ///
  /// Ritorna la lista finale di Memory sul disco (nuova lunghezza).
  Future<List<Memory>> loadFromBundle({bool clearFirst = false}) async {
    final sw = Stopwatch()..start();

    // 1. Leggi il manifesto.
    final raw = await rootBundle.loadString(_kSeedManifest);
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw Exception(
        '[seed] memories.json malformato: root non e\' una lista '
        '(${decoded.runtimeType})',
      );
    }
    debugPrint('[seed] manifesto letto, ${decoded.length} ricordi candidati');

    // 2. Stato esistente (puo' contenere seed gia' caricati o ricordi
    //    dell'utente).
    final existing =
        clearFirst ? <Memory>[] : await repository.load();
    final existingIds = existing.map((m) => m.id).toSet();

    // 3. Prepara la dir per le immagini copiate dal bundle.
    final docsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${docsDir.path}/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }

    // 4. Per ogni entry del manifesto: copia la foto dal bundle e
    //    costruisci la Memory con path locale.
    final imported = <Memory>[];
    int skipped = 0;
    for (final entry in decoded) {
      if (entry is! Map<String, dynamic>) continue;
      final id = entry['id'] as String?;
      if (id == null || id.isEmpty) {
        debugPrint('[seed] skip: entry senza id');
        continue;
      }
      if (existingIds.contains(id)) {
        debugPrint('[seed] skip: $id gia\' presente');
        skipped++;
        continue;
      }

      // Bundle path → app docs path per le foto. Memory.fromJson
      // accetta `imagePath` come stringa qualunque.
      final bundleImagePath = entry['imagePath'] as String?;
      String? localImagePath;
      if (bundleImagePath != null && bundleImagePath.startsWith('assets/')) {
        try {
          final bytes = await rootBundle.load(bundleImagePath);
          final bytesView = bytes.buffer.asUint8List(
            bytes.offsetInBytes,
            bytes.lengthInBytes,
          );
          final destPath = '${imagesDir.path}/$id.jpg';
          await File(destPath).writeAsBytes(bytesView, flush: true);
          localImagePath = destPath;
          debugPrint(
            '[seed] copiata foto $bundleImagePath → $destPath '
            '(${bytesView.length} bytes)',
          );
        } catch (e, st) {
          debugPrint('[seed] foto $bundleImagePath fallita: $e\n$st');
          // Procedi senza foto: il ricordo testuale resta valido.
        }
      }

      // Costruisci Memory tramite fromJson, sostituendo imagePath con
      // il path locale (se la copia e' riuscita). I campi extra del JSON
      // (`_source_book`, `_validation_status`) vengono ignorati da fromJson.
      final patched = Map<String, dynamic>.from(entry);
      if (localImagePath != null) {
        patched['imagePath'] = localImagePath;
      } else {
        patched.remove('imagePath');
      }
      try {
        final memory = Memory.fromJson(patched);
        imported.add(memory);
      } catch (e) {
        debugPrint('[seed] parse ricordo $id fallito: $e');
      }
    }

    if (imported.isEmpty) {
      debugPrint('[seed] nessun nuovo ricordo da importare (skipped=$skipped)');
      return existing;
    }

    // 5. Persisti tutto: nuovi seed in cima, esistenti dopo.
    final merged = [...imported, ...existing];
    await repository.saveAll(merged);

    // 6. Indicizza i nuovi seed nel vector store (fire-and-forget per
    //    evitare di bloccare la UI; al primo search syncWithMemories
    //    riallinea comunque).
    for (final m in imported) {
      // ignore: discarded_futures
      vectorStore.addMemory(m);
    }

    sw.stop();
    debugPrint(
      '[seed] importati ${imported.length} ricordi seed '
      '(skipped=$skipped) in ${sw.elapsedMilliseconds} ms',
    );
    return merged;
  }
}
