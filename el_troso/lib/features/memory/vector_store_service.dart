// El Troso - VectorStoreService (Fase 4.5.d).
//
// Wrapper sopra il vector store integrato di flutter_gemma. Il plugin espone
// una API high-level (initializeVectorStore, addDocument, searchSimilar,
// getVectorStoreStats) che gestisce internamente:
//   - generazione embedding tramite l'active embedder
//   - persistenza su SQLite (file nel docsDir)
//   - ricerca HNSW + filtro similarity
// Pattern gia' validato in playground_page.dart (Fase 3.5 / 3.6). Qui lo
// riusiamo 1:1 per il flusso reale della app.
//
// Ciclo di vita:
//   - _ensureReady() e' idempotente: alla prima chiamata installa embedder
//     (~170 MB, 3-5 s), fa getActiveEmbedder con backend GPU, apre il
//     vector store SQLite. Chiamate successive sono no-op.
//   - Lazy: niente init in main.dart (ritarda il cold start di 3-5 s
//     per un utente che magari non fa mai search). Il costo si paga alla
//     prima addMemory o al primo search.
//
// Sync:
//   - syncWithMemories(list) confronta count nel vector store con la
//     lunghezza della list di Memory. Se non combaciano (ricordi salvati
//     in JSON ma non nel vector store, es. addMemory fallita e ripresa
//     dal boot successivo) clear + re-index completo.
//   - Non c'e' API per listare gli id gia' indicizzati, quindi full
//     re-index e' l'unico approccio pratico. Costo: N * ~700 ms, una
//     tantum per scenario di drift.
//
// Errori:
//   - addMemory e' fire-and-forget lato chiamante (RecordPage non aspetta)
//     ma internamente fa try/catch e logga. Se fallisce, al prossimo
//     search syncWithMemories la riprende.
//   - _ensureReady fallisce se i file embedder non sono presenti sul
//     device. Questo avverra' durante sviluppo (files in /sdcard/Android/
//     data/.../files/ mancanti) - l'errore e' loggato e propagato.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';

import 'memory.dart';

// Stesse costanti usate in playground_page.dart. Duplicate qui per non
// introdurre dipendenze trasversali (il playground e' dev-only, non e'
// ragionevole che la feature reale importi da li). Se un giorno cambiamo
// il nome del file embedder, aggiornare entrambi i punti.
const String _kEmbedModelFileName =
    'embeddinggemma-300M_seq512_mixed-precision.tflite';
const String _kEmbedTokenizerFileName = 'sentencepiece.model';

// Nome del DB SQLite del vector store. Path assoluto in
// ApplicationDocumentsDirectory (app-private, non external). Stesso usato
// dal playground per coerenza: se si testa prima nel playground e poi
// nella app, lo stato del vector store persiste.
const String _kVectorStoreFileName = 'el_troso_ricordi.db';

// Default per il search. Threshold e topK calibrati in Fase 3.6 sul
// corpus seed iniziale (6 ricordi). Aggiornato in build 35 (corpus
// 12 seed): 0.40 era troppo selettivo per query corte su entità
// menzionate UNA volta in ricordi lunghi (es. "chi è Pippo?" sul
// ricordo Teolo lungo ~150 parole tornava 0 risultati anche se il
// match c'era a similarity ~0.32). Abbassato a 0.30 con tolleranza
// del rumore: il LLM è bravo a scartare i ricordi marginali in
// fase di sintesi.
const int kDefaultTopK = 3;
const double kDefaultThreshold = 0.30;

class VectorStoreService {
  // Nessun handle all'embedder qui: il plugin top-level (addDocument,
  // searchSimilar) usa internamente l'active embedder settato da
  // getActiveEmbedder. A noi basta flaggare l'init per idempotenza.
  bool _initialized = false;

  /// Idempotente. Alla prima chiamata: installa embedder (se non gia'
  /// installato), fa getActiveEmbedder, apre il vector store SQLite.
  Future<void> _ensureReady() async {
    if (_initialized) return;

    final sw = Stopwatch()..start();

    // 1. Path dei file embedder in external-files dir (stesso path usato
    //    da adb push durante il setup).
    final extDir = await getExternalStorageDirectory();
    if (extDir == null) {
      throw Exception(
        'getExternalStorageDirectory() ha restituito null - '
        'impossibile risolvere il path dell\'embedder.',
      );
    }
    final embedModelPath = '${extDir.path}/$_kEmbedModelFileName';
    final embedTokenizerPath = '${extDir.path}/$_kEmbedTokenizerFileName';

    if (!await File(embedModelPath).exists()) {
      throw Exception(
        'Embedder model non presente sul device: $embedModelPath. '
        'Eseguire adb push del file in ${extDir.path}/.',
      );
    }
    if (!await File(embedTokenizerPath).exists()) {
      throw Exception(
        'Embedder tokenizer non presente sul device: $embedTokenizerPath.',
      );
    }

    // 2. Installa embedder (idempotente lato plugin) e ottienilo attivo.
    await FlutterGemma.installEmbedder()
        .modelFromFile(embedModelPath)
        .tokenizerFromFile(embedTokenizerPath)
        .install();

    // Chiamiamo getActiveEmbedder solo per forzare l'attivazione globale
    // lato plugin. Non salviamo l'handle: addDocument/searchSimilar usano
    // internamente l'active embedder.
    await FlutterGemma.getActiveEmbedder(
      preferredBackend: PreferredBackend.gpu,
    );

    // 3. Inizializza il vector store SQLite.
    final docsDir = await getApplicationDocumentsDirectory();
    final dbPath = '${docsDir.path}/$_kVectorStoreFileName';
    await FlutterGemmaPlugin.instance.initializeVectorStore(dbPath);

    _initialized = true;
    sw.stop();
    debugPrint(
      '[vector_store] ready in ${sw.elapsedMilliseconds} ms '
      '(embedder=$embedModelPath, db=$dbPath)',
    );
  }

  /// Indicizza un Memory nel vector store. Se l'embedder/store non sono
  /// ancora pronti li inizializza. Fallisce silenziosamente (log) perche'
  /// il ricordo e' gia' salvato in JSON dal repo: l'indice si recupera al
  /// prossimo search via syncWithMemories.
  Future<void> addMemory(Memory m) async {
    try {
      await _ensureReady();
      final sw = Stopwatch()..start();
      // Solo testo del ricordo per l'embedding. Storicamente combinavamo
      // anche `imageDescription` (build < 20), ma il campo è stato
      // rimosso: la descrizione visiva non è il ricordo autobiografico
      // vero e ne falsava la validazione G3.
      final content = m.text;
      await FlutterGemmaPlugin.instance.addDocument(
        id: m.id,
        content: content,
        metadata: m.tag,
      );
      sw.stop();
      debugPrint(
        '[vector_store] addMemory id=${m.id} len=${content.length} '
        'in ${sw.elapsedMilliseconds} ms',
      );
    } catch (e, st) {
      debugPrint('[vector_store] addMemory FAILED id=${m.id}: $e\n$st');
    }
  }

  /// Cerca ricordi semanticamente simili a [query]. Torna una lista
  /// di RetrievalResult (vedi flutter_gemma) con id/content/similarity.
  /// Prima del search chiama syncWithMemories per coprire il drift tra
  /// JSON e vector store (vedi commento di classe).
  Future<List<dynamic>> search(
    String query, {
    int topK = kDefaultTopK,
    double threshold = kDefaultThreshold,
    required List<Memory> knownMemories,
  }) async {
    await _ensureReady();
    await syncWithMemories(knownMemories);
    final sw = Stopwatch()..start();
    final results = await FlutterGemmaPlugin.instance.searchSimilar(
      query: query,
      topK: topK,
      threshold: threshold,
    );
    sw.stop();
    debugPrint(
      '[vector_store] search "${_short(query)}" topK=$topK '
      'threshold=$threshold -> ${results.length} results '
      'in ${sw.elapsedMilliseconds} ms',
    );
    return results;
  }

  /// Allinea il vector store alla lista di Memory su JSON.
  /// Strategia: se count nel vector store != memories.length, clear e
  /// re-index completo. Sembra brutale ma e' l'unica opzione pratica
  /// (niente API per listare id indicizzati) ed e' un caso raro.
  /// No-op se gia' allineati.
  Future<void> syncWithMemories(List<Memory> memories) async {
    await _ensureReady();
    final stats = await FlutterGemmaPlugin.instance.getVectorStoreStats();
    final storedCount = stats.documentCount;
    if (storedCount == memories.length) {
      debugPrint(
        '[vector_store] sync: already aligned ($storedCount docs)',
      );
      return;
    }
    debugPrint(
      '[vector_store] sync: drift detected (store=$storedCount, '
      'json=${memories.length}) - full re-index',
    );
    final sw = Stopwatch()..start();
    await FlutterGemmaPlugin.instance.clearVectorStore();
    for (final m in memories) {
      await FlutterGemmaPlugin.instance.addDocument(
        id: m.id,
        content: m.text,
        metadata: m.tag,
      );
    }
    sw.stop();
    debugPrint(
      '[vector_store] sync done: indexed ${memories.length} docs '
      'in ${sw.elapsedMilliseconds} ms',
    );
  }

  String _short(String s) => s.length <= 40 ? s : '${s.substring(0, 40)}...';
}
