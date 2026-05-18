// El Troso - Playground dev (Fase 4.4.d).
// Preserva INTATTA la UI di test con pulsanti 1-9, spostata qui da main.dart.
// Accessibile in app alla rotta "/playground" - non visibile all'utente finale
// (nessun link diretto dalla UI utente, solo dal bottone "dev" nella splash).
//
// Contratto: i 9 test (load model, ask, image, audio, embedding, seed RAG,
// chat RAG, V1+V2 cross-lingual, V2 prompt sweep) devono continuare a
// funzionare cosi' come funzionavano in Fase 3.x -> 4.1. Zero modifiche
// alla logica: e' proprio il punto del playground, testare senza regressioni.

import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// flutter/foundation.dart esporta gia' Uint8List (via dart:typed_data) e
// debugPrint, quindi basta questo import - evita l'unnecessary_import
// warning su dart:typed_data.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:el_troso/core/version.dart';
import 'package:el_troso/features/memory/memory_providers.dart';

// Nome del file modello. Il path assoluto lo risolviamo a runtime con
// getExternalStorageDirectory() - cosi' usiamo ESATTAMENTE il path che il
// sistema Android autorizza per l'UID della nostra app, invece di hardcodare
// /sdcard/... che su Android 13+ puo' risolvere a un mount point diverso da
// quello che vede la app.
const String kModelFileName = 'gemma-4-E2B-it.litertlm';

// EmbeddingGemma 300M - variante mixed-precision seq=512 (generica, senza
// chipset lock-in: il Tensor G2 e' un Samsung Exynos custom, non ha una
// variante dedicata nei file litert-community). Tokenizer sentencepiece.
const String kEmbedModelFileName =
    'embeddinggemma-300M_seq512_mixed-precision.tflite';
const String kEmbedTokenizerFileName = 'sentencepiece.model';

// Seed corpus per Fase 3.5 - 10 ricordi generici (non di Giorgio) con
// topic diversi, per misurare se EmbeddingGemma+vector store separa bene
// i domini durante il retrieval. Metadata = topic tag, utile per debug.
const List<Map<String, String>> kSeedRicordi = [
  {
    'id': 'm01',
    'topic': 'lavoro',
    'content':
        'Da giovane lavoravo in officina, riparavo i motori delle Vespa con mio zio.',
  },
  {
    'id': 'm02',
    'topic': 'matrimonio',
    'content':
        'Mia moglie Maria e io ci siamo sposati nel 1962, a maggio, sul lago di Garda.',
  },
  {
    'id': 'm03',
    'topic': 'figli',
    'content':
        'Quando mio figlio Paolo aveva cinque anni gli ho insegnato ad andare in bicicletta al parco.',
  },
  {
    'id': 'm04',
    'topic': 'cucina',
    'content':
        'A Natale facevamo sempre i tortellini in brodo, mia madre ne impastava un chilo intero.',
  },
  {
    'id': 'm05',
    'topic': 'viaggio',
    'content':
        'Nel 1978 sono andato in Germania per lavoro, tre mesi ad Amburgo, pioveva sempre.',
  },
  {
    'id': 'm06',
    'topic': 'sport',
    'content':
        'Giocavo a bocce ogni domenica al circolo del paese, con Piero e Giovanni.',
  },
  {
    'id': 'm07',
    'topic': 'casa',
    'content':
        'La casa in campagna aveva un grande ciliegio che a giugno era pieno di frutti rossi.',
  },
  {
    'id': 'm08',
    'topic': 'militare',
    'content':
        'Ho fatto il militare in Friuli, a Cividale, nel 1958 - il mio sergente si chiamava Rossetti.',
  },
  {
    'id': 'm09',
    'topic': 'salute',
    'content':
        'L\'anno scorso il dottore mi ha detto di camminare di piu, cosi vado al parco ogni mattina.',
  },
  {
    'id': 'm10',
    'topic': 'mercato',
    'content':
        'Ogni sabato andavo al mercato di piazza Mazzini con Maria, compravamo il pane e la frutta.',
  },
];

class PlaygroundPage extends ConsumerStatefulWidget {
  const PlaygroundPage({super.key});

  @override
  ConsumerState<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends ConsumerState<PlaygroundPage> {
  // dynamic per evitare name mismatch tra README e SDK effettivo -
  // i tipi reali (InferenceModel, InferenceModelSession) non sono
  // stati verificati letteralmente dai sorgenti. Sostituire in 3.2.
  dynamic _model;
  dynamic _embedder;

  String _status = 'Pronto. Tocca "1. Carica modello" per iniziare.';
  String _response = '';
  bool _busy = false;

  Future<void> _loadModel() async {
    setState(() {
      _busy = true;
      _status = 'Caricamento modello in corso (Gemma 4 E2B, ~2.58 GB)...\n'
          'Su Pixel 7a ci si aspetta 10-40 secondi la prima volta.';
      _response = '';
    });

    final stopwatch = Stopwatch()..start();
    try {
      // 0. Risolvi il path della external-files dir che il sistema autorizza
      //    per questo UID. Su Android canonicamente e':
      //    /storage/emulated/0/Android/data/<pkg>/files/
      final extDir = await getExternalStorageDirectory();
      if (extDir == null) {
        throw Exception('getExternalStorageDirectory() ha restituito null.');
      }
      final modelPath = '${extDir.path}/$kModelFileName';
      final modelFile = File(modelPath);
      debugPrint('=== modelPath risolto: $modelPath ===');

      if (!await modelFile.exists()) {
        // Debug: elenca cosa vede davvero la app nella sua dir.
        final listing = <String>[];
        try {
          await for (final entry in extDir.list()) {
            final stat = await entry.stat();
            listing.add('  ${entry.path}  (${stat.size} bytes)');
          }
        } catch (e) {
          listing.add('  <impossibile elencare: $e>');
        }
        throw Exception(
          'File modello non visibile dalla app.\n'
          'Path atteso: $modelPath\n'
          'Contenuto effettivo di ${extDir.path}:\n'
          '${listing.isEmpty ? "  (vuoto)" : listing.join("\n")}\n'
          'Azione: adb push del modello in ${extDir.path}/',
        );
      }

      // 1. Registra il file .litertlm gia' presente sul device come
      //    sorgente di installazione. IMPORTANTE: fileType va dichiarato
      //    esplicitamente, il plugin NON lo deduce dall'estensione e di
      //    default assume ModelFileType.task - che formatta il prompt
      //    in modo incompatibile e causa nativeSendMessage INTERNAL ERROR.
      //    Riferimento: inference_installation_builder.dart:32-36.
      await FlutterGemma
          .installModel(
            modelType: ModelType.gemmaIt,
            fileType: ModelFileType.litertlm,
          )
          .fromFile(modelPath)
          .install();

      // 2. Ottieni il modello pronto all'inferenza.
      //    GPU backend: CPU+XNNPack ha restituito "Failed to invoke the
      //    compiled model" a runtime, sintomo tipico di op mancanti nel
      //    compiled graph per CPU. Mali-G710 MP7 del Tensor G2 supporta
      //    il delegate GPU di LiteRT-LM. In 3.3 confronteremo le due
      //    strade per il benchmark TTFT / tok-s.
      // supportImage/supportAudio: abilitano i rami multimodali del modello.
      // Devono essere passati a getActiveModel (NON a installModel).
      // Fonte: flutter_gemma/lib/core/api/flutter_gemma.dart:233-239.
      // maxNumImages=1: la smoke UI manda una foto alla volta.
      final model = await FlutterGemma.getActiveModel(
        maxTokens: 512,
        preferredBackend: PreferredBackend.gpu,
        supportImage: true,
        supportAudio: true,
        maxNumImages: 1,
      );

      stopwatch.stop();
      _model = model;
      final statusMsg = 'Modello pronto. '
          'Caricato in ${stopwatch.elapsed.inSeconds}s su GPU.\n'
          'Path: $modelPath';
      debugPrint('=== loadModel status ===\n$statusMsg');
      setState(() => _status = statusMsg);
    } catch (e, st) {
      stopwatch.stop();
      debugPrint('=== loadModel error ===\n$e\n$st');
      setState(() {
        _status = 'Errore caricamento modello (dopo '
            '${stopwatch.elapsed.inSeconds}s):\n$e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _askAudio() async {
    final model = _model;
    if (model == null) {
      setState(() => _status = 'Prima carica il modello.');
      return;
    }
    setState(() {
      _busy = true;
      _response = 'Inferenza multimodale (audio) in corso...';
    });

    final stopwatch = Stopwatch()..start();
    dynamic session;
    try {
      final ByteData data =
          await rootBundle.load('assets/sample_audio.wav');
      final Uint8List audioBytes = data.buffer.asUint8List();
      debugPrint('=== sample_audio.wav caricato, ${audioBytes.length} bytes ===');

      session = await model.createSession(temperature: 0.8, topK: 1);
      await session.addQueryChunk(Message.withAudio(
        text: 'Trascrivi in italiano cosa dice questa voce. '
            'Poi riformula in una frase piu breve.',
        audioBytes: audioBytes,
        isUser: true,
      ));
      final out = await session.getResponse();
      stopwatch.stop();
      final responseMsg = '[AUDIO] $out\n\n---\n'
          'Inferenza multimodale: ${stopwatch.elapsed.inMilliseconds} ms\n'
          'Audio: ${audioBytes.length} bytes';
      debugPrint('=== askAudio response ===\n$responseMsg');
      setState(() => _response = responseMsg);
    } catch (e, st) {
      stopwatch.stop();
      debugPrint('=== askAudio error ===\n$e\n$st');
      setState(() {
        _response = 'Errore inferenza audio (dopo '
            '${stopwatch.elapsed.inMilliseconds} ms):\n$e';
      });
    } finally {
      try {
        await session?.close();
      } catch (_) {}
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _askImage() async {
    final model = _model;
    if (model == null) {
      setState(() => _status = 'Prima carica il modello.');
      return;
    }
    setState(() {
      _busy = true;
      _response = 'Inferenza multimodale (immagine) in corso...';
    });

    final stopwatch = Stopwatch()..start();
    dynamic session;
    try {
      // Carica l'asset dall'app bundle in memoria.
      final ByteData data =
          await rootBundle.load('assets/sample_image.jpg');
      final Uint8List imageBytes = data.buffer.asUint8List();
      debugPrint('=== sample_image.jpg caricato, ${imageBytes.length} bytes ===');

      session = await model.createSession(temperature: 0.8, topK: 1);
      await session.addQueryChunk(Message.withImage(
        text: 'Descrivi cosa vedi in questa immagine, '
            'in una frase in italiano.',
        imageBytes: imageBytes,
        isUser: true,
      ));
      final out = await session.getResponse();
      stopwatch.stop();
      final responseMsg = '[IMMAGINE] $out\n\n---\n'
          'Inferenza multimodale: ${stopwatch.elapsed.inMilliseconds} ms\n'
          'Immagine: ${imageBytes.length} bytes';
      debugPrint('=== askImage response ===\n$responseMsg');
      setState(() => _response = responseMsg);
    } catch (e, st) {
      stopwatch.stop();
      debugPrint('=== askImage error ===\n$e\n$st');
      setState(() {
        _response = 'Errore inferenza immagine (dopo '
            '${stopwatch.elapsed.inMilliseconds} ms):\n$e';
      });
    } finally {
      try {
        await session?.close();
      } catch (_) {}
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _testEmbedding() async {
    setState(() {
      _busy = true;
      _response = 'Installazione EmbeddingGemma in corso...';
    });

    final stopwatch = Stopwatch()..start();
    try {
      // 0. Risolvi i path come per il modello principale.
      final extDir = await getExternalStorageDirectory();
      if (extDir == null) {
        throw Exception('getExternalStorageDirectory() ha restituito null.');
      }
      final embedModelPath = '${extDir.path}/$kEmbedModelFileName';
      final embedTokenizerPath = '${extDir.path}/$kEmbedTokenizerFileName';
      debugPrint('=== embedModelPath: $embedModelPath');
      debugPrint('=== embedTokenizerPath: $embedTokenizerPath');

      if (!await File(embedModelPath).exists()) {
        throw Exception('EmbeddingGemma model non presente: $embedModelPath');
      }
      if (!await File(embedTokenizerPath).exists()) {
        throw Exception(
            'EmbeddingGemma tokenizer non presente: $embedTokenizerPath');
      }

      // 1. Installa l'embedder se non gia' fatto.
      //    installEmbedder() e' idempotente e gestisce anche
      //    l'auto-set come active embedder.
      if (_embedder == null) {
        await FlutterGemma.installEmbedder()
            .modelFromFile(embedModelPath)
            .tokenizerFromFile(embedTokenizerPath)
            .install();

        _embedder = await FlutterGemma.getActiveEmbedder(
          preferredBackend: PreferredBackend.gpu,
        );
      }

      // 2. Dimensione dell'embedding (768 per EmbeddingGemma 300M).
      final int dim = await _embedder.getDimension() as int;

      // 3. Smoke test: query embedding + document embedding su testo IT.
      final queryStart = Stopwatch()..start();
      final List<double> queryEmb = (await _embedder.generateEmbedding(
        'Cosa ho fatto oggi al mercato?',
        taskType: TaskType.retrievalQuery,
      ) as List)
          .cast<double>();
      queryStart.stop();

      final docStart = Stopwatch()..start();
      final List<double> docEmb = (await _embedder.generateEmbedding(
        'Oggi sono andato al mercato con mia moglie e ho comprato del pane.',
        taskType: TaskType.retrievalDocument,
      ) as List)
          .cast<double>();
      docStart.stop();

      // 4. Similarita' coseno per verificare che gli embedding abbiano senso.
      double dot = 0, na = 0, nb = 0;
      for (int i = 0; i < queryEmb.length; i++) {
        dot += queryEmb[i] * docEmb[i];
        na += queryEmb[i] * queryEmb[i];
        nb += docEmb[i] * docEmb[i];
      }
      final cosine = dot / (math.sqrt(na) * math.sqrt(nb));

      stopwatch.stop();
      final responseMsg = '[EMBEDDING]\n'
          'Dimensione: $dim (attesa: 768)\n'
          'Query emb latency: ${queryStart.elapsedMilliseconds} ms\n'
          'Doc emb latency: ${docStart.elapsedMilliseconds} ms\n'
          'Cosine similarity query-doc: ${cosine.toStringAsFixed(4)}\n'
          '(query: "Cosa ho fatto oggi al mercato?")\n'
          '(doc: "Oggi sono andato al mercato ...")\n'
          'Primi 5 valori query: '
          '${queryEmb.take(5).map((v) => v.toStringAsFixed(4)).join(", ")}\n'
          '\n---\nTotale: ${stopwatch.elapsed.inMilliseconds} ms';
      debugPrint('=== testEmbedding response ===\n$responseMsg');
      setState(() => _response = responseMsg);
    } catch (e, st) {
      stopwatch.stop();
      debugPrint('=== testEmbedding error ===\n$e\n$st');
      setState(() {
        _response = 'Errore embedding (dopo '
            '${stopwatch.elapsed.inMilliseconds} ms):\n$e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _seedAndTestRag() async {
    if (_embedder == null) {
      setState(() => _status =
          'Prima tocca "5. Test embedding" per inizializzare EmbeddingGemma.');
      return;
    }
    setState(() {
      _busy = true;
      _response =
          'Inizializzo vector store e indicizzo 10 ricordi di esempio...';
    });

    final stopwatch = Stopwatch()..start();
    try {
      // 1. Path DB nella app-private documents dir (non external, piu' sicuro
      //    per dati sensibili). SQLite file, gestito dal plugin.
      final docsDir = await getApplicationDocumentsDirectory();
      final dbPath = '${docsDir.path}/el_troso_ricordi.db';
      debugPrint('=== vector store path: $dbPath');

      final plugin = FlutterGemmaPlugin.instance;

      // 2. Inizializza vector store (apre/crea il file SQLite).
      await plugin.initializeVectorStore(dbPath);

      // 3. Clear per idempotenza: il pulsante puo' essere premuto piu' volte
      //    senza duplicare documenti.
      await plugin.clearVectorStore();

      // 4. Indicizza i 10 ricordi seed. plugin.addDocument usa internamente
      //    l'active embedder con taskType: retrievalDocument.
      final indexStart = Stopwatch()..start();
      for (final m in kSeedRicordi) {
        await plugin.addDocument(
          id: m['id']!,
          content: m['content']!,
          metadata: m['topic'],
        );
      }
      indexStart.stop();

      final stats = await plugin.getVectorStoreStats();

      // 5. Due query di test: una chiara, una ambigua.
      const String q1 = 'Dove siamo andati in viaggio di nozze?';
      final q1Start = Stopwatch()..start();
      final r1 = await plugin.searchSimilar(query: q1, topK: 3);
      q1Start.stop();

      const String q2 = 'Cosa facevo la domenica?';
      final q2Start = Stopwatch()..start();
      final r2 = await plugin.searchSimilar(query: q2, topK: 3);
      q2Start.stop();

      stopwatch.stop();

      String formatResults(List<dynamic> results) {
        if (results.isEmpty) return '  (nessun risultato sopra threshold)';
        return results.asMap().entries.map((e) {
          final i = e.key + 1;
          final r = e.value;
          final sim = r.similarity.toStringAsFixed(3);
          final topic = r.metadata ?? '?';
          return '  $i. [$sim] ($topic) ${r.content}';
        }).join('\n');
      }

      final responseMsg = '[RAG SEED]\n'
          'Indicizzati ${stats.documentCount} ricordi in '
          '${indexStart.elapsedMilliseconds} ms\n'
          'Dimensione vettori: ${stats.vectorDimension}\n\n'
          'Q1: "$q1" (${q1Start.elapsedMilliseconds} ms)\n'
          '${formatResults(r1)}\n\n'
          'Q2: "$q2" (${q2Start.elapsedMilliseconds} ms)\n'
          '${formatResults(r2)}\n\n'
          '---\nTotale: ${stopwatch.elapsed.inMilliseconds} ms';
      debugPrint('=== seedAndTestRag response ===\n$responseMsg');
      setState(() => _response = responseMsg);
    } catch (e, st) {
      stopwatch.stop();
      debugPrint('=== seedAndTestRag error ===\n$e\n$st');
      setState(() {
        _response = 'Errore RAG (dopo ${stopwatch.elapsed.inMilliseconds} ms):\n$e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Tre domande di test per valutare la pipeline RAG end-to-end:
  /// [0] match diretto (deve rispondere confidente)
  /// [1] match semantico su parola chiave ricorrente (deve rispondere)
  /// [2] caso dove retrieve trova un ricordo ma semanticamente non risponde
  ///     (deve ammettere "non mi ricordo bene" - grounding test)
  static const List<String> kTestQuestions = [
    'Dove ci siamo sposati?',
    'Cosa facevo la domenica?',
    'Dove siamo andati in viaggio di nozze?',
  ];

  Future<void> _chatRag() async {
    final model = _model;
    if (model == null) {
      setState(() => _status =
          'Prima carica Gemma 4 ("1. Carica Gemma 4 E2B").');
      return;
    }
    if (_embedder == null) {
      setState(() => _status =
          'Prima tocca "5. Test embedding" per inizializzare EmbeddingGemma.');
      return;
    }
    setState(() {
      _busy = true;
      _response = 'Chat RAG in corso (3 domande di test)...';
    });

    final stopwatch = Stopwatch()..start();
    try {
      // 1. Apri il vector store (se il seed pulsante 6 non e' stato premuto
      //    in questa sessione il DB e' vuoto - gestiamo sotto).
      final plugin = FlutterGemmaPlugin.instance;
      final docsDir = await getApplicationDocumentsDirectory();
      final dbPath = '${docsDir.path}/el_troso_ricordi.db';
      await plugin.initializeVectorStore(dbPath);

      final stats = await plugin.getVectorStoreStats();
      if (stats.documentCount == 0) {
        stopwatch.stop();
        final msg = '[CHAT RAG]\n'
            'Vector store vuoto. Prima premi "6. Seed corpus + test RAG".\n'
            '---\nTotale: ${stopwatch.elapsed.inMilliseconds} ms';
        debugPrint('=== chatRag empty store ===\n$msg');
        setState(() => _response = msg);
        return;
      }

      final buffer = StringBuffer();
      buffer.writeln('[CHAT RAG - 3 domande di test]');
      buffer.writeln('Ricordi nel DB: ${stats.documentCount} '
          '(dim=${stats.vectorDimension})\n');

      for (int qi = 0; qi < kTestQuestions.length; qi++) {
        final domanda = kTestQuestions[qi];
        debugPrint('=== chatRag Q${qi + 1}: $domanda ===');

        // Retrieve top-3 sopra threshold 0.40.
        final retrieveStart = Stopwatch()..start();
        final retrieved = await plugin.searchSimilar(
          query: domanda,
          topK: 3,
          threshold: 0.40,
        );
        retrieveStart.stop();

        buffer.writeln('─── Q${qi + 1}: "$domanda"');
        buffer.writeln(
            'Retrieve (${retrieveStart.elapsedMilliseconds} ms): '
            '${retrieved.length} ricordi sopra 0.40');

        if (retrieved.isEmpty) {
          buffer.writeln('Risposta: (skip - nessun ricordo)\n');
          continue;
        }

        for (int i = 0; i < retrieved.length; i++) {
          final r = retrieved[i];
          final sim = r.similarity.toStringAsFixed(3);
          final topic = r.metadata ?? '?';
          buffer.writeln(
              '  ${i + 1}. [$sim] ($topic) ${r.content}');
        }

        // Costruisci prompt e genera risposta.
        final ricordiBlock =
            retrieved.map((r) => '- ${r.content}').join('\n');
        final prompt =
            'Sei Giorgio, un uomo anziano. Rispondi alla domanda che '
            'ti faccio usando SOLO i ricordi qui sotto. '
            'Se i ricordi non bastano, di\' "non mi ricordo bene". '
            'Parla in prima persona, in italiano, una frase breve.\n\n'
            'Ricordi disponibili:\n$ricordiBlock\n\n'
            'Domanda: $domanda';

        final genStart = Stopwatch()..start();
        dynamic session;
        try {
          session = await model.createSession(temperature: 0.3, topK: 1);
          await session.addQueryChunk(
              Message.text(text: prompt, isUser: true));
          final out = await session.getResponse();
          genStart.stop();
          buffer.writeln(
              'Risposta (${genStart.elapsedMilliseconds} ms): $out\n');
          debugPrint('=== Q${qi + 1} answer: $out');
        } finally {
          try {
            await session?.close();
          } catch (_) {}
        }
      }

      stopwatch.stop();
      buffer.writeln(
          '---\nTotale: ${stopwatch.elapsed.inMilliseconds} ms');
      final responseMsg = buffer.toString();
      debugPrint('=== chatRag response ===\n$responseMsg');
      setState(() => _response = responseMsg);
    } catch (e, st) {
      stopwatch.stop();
      debugPrint('=== chatRag error ===\n$e\n$st');
      setState(() {
        _response = 'Errore chat RAG (dopo '
            '${stopwatch.elapsed.inMilliseconds} ms):\n$e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Fase 4.1a - Test V1+V2 cross-lingual (MULTILINGUA_PLAN.md §5).
  ///
  /// V1: EmbeddingGemma multilingua davvero sul Pixel?
  ///   - Query EN "Where did I work abroad?" vs doc IT m05
  ///     (ricordo originale IT su Amburgo '78). Atteso cosine >= 0.40.
  ///   - Control same-language: query IT "Dove ho lavorato all'estero?" vs
  ///     lo stesso doc IT. Questa deve essere > cross-lingual (sanity).
  ///   - Retrieve top-3 dal vector store usando query EN: deve includere
  ///     m05 sopra threshold 0.40.
  ///
  /// V2: Gemma 4 E2B risponde in EN se la query e' EN con ricordi IT?
  ///   - Retrieve top-3 per "Where did we get married?" (target: m02 IT).
  ///   - Prompt template con ricordi IT + domanda EN + istruzione
  ///     "Respond in the same language as the question".
  ///   - Verifica visiva: la risposta deve essere in EN e citare Garda/1962.
  ///
  /// Red/green gate: se V1 cosine < 0.40 o V2 risponde in IT, la strategia
  /// multilingua del piano cambia (fallback a UI-only multilingua).
  Future<void> _testCrossLingual() async {
    final model = _model;
    if (model == null) {
      setState(() => _status = 'Prima carica Gemma 4 ("1. Carica Gemma 4 E2B").');
      return;
    }
    if (_embedder == null) {
      setState(() => _status =
          'Prima tocca "5. Test embedding" per inizializzare EmbeddingGemma.');
      return;
    }
    setState(() {
      _busy = true;
      _response = 'V1+V2 cross-lingual in corso...';
    });

    final stopwatch = Stopwatch()..start();
    try {
      final buffer = StringBuffer();
      buffer.writeln('[CROSS-LINGUAL V1+V2]');

      // --- V1a: cosine cross-lingual su coppia controllata ---
      const String qEn = 'Where did I work abroad?';
      const String qIt = 'Dove ho lavorato all\'estero?';
      const String docIt =
          'Nel 1978 sono andato in Germania per lavoro, tre mesi ad Amburgo, pioveva sempre.';

      final qEnEmb = (await _embedder.generateEmbedding(
        qEn,
        taskType: TaskType.retrievalQuery,
      ) as List)
          .cast<double>();
      final qItEmb = (await _embedder.generateEmbedding(
        qIt,
        taskType: TaskType.retrievalQuery,
      ) as List)
          .cast<double>();
      final docItEmb = (await _embedder.generateEmbedding(
        docIt,
        taskType: TaskType.retrievalDocument,
      ) as List)
          .cast<double>();

      double cosine(List<double> a, List<double> b) {
        double dot = 0, na = 0, nb = 0;
        for (int i = 0; i < a.length; i++) {
          dot += a[i] * b[i];
          na += a[i] * a[i];
          nb += b[i] * b[i];
        }
        return dot / (math.sqrt(na) * math.sqrt(nb));
      }

      final cosineCross = cosine(qEnEmb, docItEmb);
      final cosineSame = cosine(qItEmb, docItEmb);

      buffer.writeln('─── V1a: cosine diretto');
      buffer.writeln(
          '  Cross-lingual (EN query vs IT doc): ${cosineCross.toStringAsFixed(4)}');
      buffer.writeln(
          '  Same-lingual   (IT query vs IT doc): ${cosineSame.toStringAsFixed(4)}');
      buffer.writeln(
          '  Gate: cross-lingual >= 0.40 → ${cosineCross >= 0.40 ? "✅ verde" : "❌ rosso"}');
      buffer.writeln(
          '  Sanity: same > cross → ${cosineSame > cosineCross ? "✅" : "⚠️  (sospetto)"}');
      buffer.writeln('');

      // --- V1b: retrieve cross-lingual dal vector store ---
      // Assume che il pulsante 6 sia stato premuto in precedenza (10 seed ricordi).
      final plugin = FlutterGemmaPlugin.instance;
      final docsDir = await getApplicationDocumentsDirectory();
      final dbPath = '${docsDir.path}/el_troso_ricordi.db';
      await plugin.initializeVectorStore(dbPath);
      final stats = await plugin.getVectorStoreStats();

      buffer.writeln('─── V1b: retrieve cross-lingual dal DB');
      if (stats.documentCount == 0) {
        buffer.writeln(
            '  Vector store vuoto. Premi "6. Seed corpus" e riprova.');
        buffer.writeln('');
      } else {
        buffer.writeln(
            '  Ricordi nel DB: ${stats.documentCount} (dim=${stats.vectorDimension})');

        final rStart = Stopwatch()..start();
        final retrieved = await plugin.searchSimilar(
          query: qEn,
          topK: 3,
          threshold: 0.40,
        );
        rStart.stop();

        buffer.writeln(
            '  Query EN: "$qEn" (${rStart.elapsedMilliseconds} ms)');
        if (retrieved.isEmpty) {
          buffer.writeln(
              '  ❌ Nessun ricordo sopra 0.40 — cross-lingual retrieval rosso');
        } else {
          for (int i = 0; i < retrieved.length; i++) {
            final r = retrieved[i];
            final sim = r.similarity.toStringAsFixed(3);
            final topic = r.metadata ?? '?';
            buffer.writeln('    ${i + 1}. [$sim] ($topic) ${r.content}');
          }
          final foundM05 = retrieved.any(
              (r) => r.content.toLowerCase().contains('amburgo'));
          buffer.writeln(
              '  Gate: m05 (Amburgo) presente → ${foundM05 ? "✅ verde" : "❌ rosso"}');
        }
        buffer.writeln('');
      }

      // --- V2: Gemma 4 risponde in EN con ricordi IT ---
      buffer.writeln('─── V2: Gemma risponde in EN su ricordi IT');
      if (stats.documentCount == 0) {
        buffer.writeln('  Skip: DB vuoto.');
      } else {
        const String qV2 = 'Where did we get married?';
        final retrieveStart = Stopwatch()..start();
        final retrieved = await plugin.searchSimilar(
          query: qV2,
          topK: 3,
          threshold: 0.40,
        );
        retrieveStart.stop();

        buffer.writeln(
            '  Query EN: "$qV2" (${retrieveStart.elapsedMilliseconds} ms)');
        if (retrieved.isEmpty) {
          buffer.writeln(
              '  ❌ Retrieve vuoto — V2 non eseguibile (upstream V1b rosso)');
        } else {
          for (int i = 0; i < retrieved.length; i++) {
            final r = retrieved[i];
            final sim = r.similarity.toStringAsFixed(3);
            final topic = r.metadata ?? '?';
            buffer.writeln('    ${i + 1}. [$sim] ($topic) ${r.content}');
          }

          final ricordiBlock =
              retrieved.map((r) => '- ${r.content}').join('\n');
          // Prompt multilingua allineato a MULTILINGUA_PLAN.md §8 (v1).
          // Nota: vocativo hardcoded "Giorgio" per ora (onboarding arriva in 4.4).
          final prompt =
              'You are Giorgio. Answer the question using ONLY the memories '
              'below. If the memories are not enough, say "I don\'t remember '
              'well". Answer in FIRST PERSON and IN THE SAME LANGUAGE AS THE '
              'QUESTION. If a memory is in another language, render it '
              'faithfully in the answer\'s language, without inventing details '
              'that are not in the original memory. One short sentence.\n\n'
              'Memories available (these are in Italian):\n$ricordiBlock\n\n'
              'Question: $qV2';

          final genStart = Stopwatch()..start();
          dynamic session;
          try {
            session = await model.createSession(temperature: 0.3, topK: 1);
            await session.addQueryChunk(
                Message.text(text: prompt, isUser: true));
            final out = await session.getResponse();
            genStart.stop();
            buffer.writeln(
                '  Risposta (${genStart.elapsedMilliseconds} ms): $out');

            // Euristica grezza: lingua EN se contiene stopword EN frequenti
            // e NON contiene stopword IT frequenti tipiche del registro.
            final outLower = (out as String).toLowerCase();
            final looksEn = RegExp(r'\b(we|i|the|got|were|our|at|on|in)\b')
                    .allMatches(outLower)
                    .length >=
                2;
            final looksIt = RegExp(r'\b(ci|ho|sono|siamo|nostro|nel|la|al)\b')
                    .allMatches(outLower)
                    .length >=
                2;
            final verdict = looksEn && !looksIt
                ? '✅ EN'
                : (!looksEn && looksIt ? '❌ IT (risposta in lingua sbagliata)' : '⚠️  ambiguo (controllo manuale)');
            buffer.writeln('  Gate: lingua risposta → $verdict');
          } finally {
            try {
              await session?.close();
            } catch (_) {}
          }
        }
      }

      stopwatch.stop();
      buffer.writeln('');
      buffer.writeln('---\nTotale: ${stopwatch.elapsed.inMilliseconds} ms');
      final responseMsg = buffer.toString();
      debugPrint('=== testCrossLingual response ===\n$responseMsg');
      setState(() => _response = responseMsg);
    } catch (e, st) {
      stopwatch.stop();
      debugPrint('=== testCrossLingual error ===\n$e\n$st');
      setState(() {
        _response = 'Errore V1+V2 (dopo ${stopwatch.elapsed.inMilliseconds} ms):\n$e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Fase 4.1a - V2 prompt sweep.
  ///
  /// Obiettivo: capire se il fallimento V2 ("Gemma risponde in IT invece di
  /// EN") e' un problema di prompt engineering risolvibile. Testiamo 3 varianti
  /// di prompt sulla stessa query EN con ricordi IT, e misuriamo quale
  /// produce output in EN.
  ///
  /// Varianti:
  ///   P1 - "Target language header":
  ///        apre con "TARGET LANGUAGE: English" come prima riga assoluta,
  ///        NON menziona che le memorie sono in IT (per evitare che il
  ///        modello venga ancorato al registro IT dalla source text).
  ///   P2 - "Primer prefix":
  ///        chiude il prompt con "Answer (in English): " che fa da primer
  ///        di completamento. Tecnica standard per language steering.
  ///   P3 - "Few-shot":
  ///        include un esempio IT->EN one-shot per mostrare il pattern di
  ///        traduzione faithful senza inventare.
  ///
  /// Output: buffer con 3 risposte + gate automatico sulla lingua.
  Future<void> _v2PromptSweep() async {
    final model = _model;
    if (model == null) {
      setState(() => _status = 'Prima carica Gemma 4.');
      return;
    }
    if (_embedder == null) {
      setState(() => _status = 'Prima tocca "5. Test embedding".');
      return;
    }
    setState(() {
      _busy = true;
      _response = 'V2 prompt sweep (3 varianti) in corso...';
    });

    final stopwatch = Stopwatch()..start();
    try {
      final plugin = FlutterGemmaPlugin.instance;
      final docsDir = await getApplicationDocumentsDirectory();
      final dbPath = '${docsDir.path}/el_troso_ricordi.db';
      await plugin.initializeVectorStore(dbPath);
      final stats = await plugin.getVectorStoreStats();

      final buffer = StringBuffer();
      buffer.writeln('[V2 PROMPT SWEEP]');
      buffer.writeln(
          'DB: ${stats.documentCount} ricordi (dim=${stats.vectorDimension})\n');

      if (stats.documentCount == 0) {
        buffer.writeln('❌ DB vuoto. Premi prima "6. Seed corpus".');
        setState(() => _response = buffer.toString());
        return;
      }

      const String question = 'Where did we get married?';
      final retrieved = await plugin.searchSimilar(
        query: question,
        topK: 3,
        threshold: 0.40,
      );

      buffer.writeln('Query EN: "$question"');
      buffer.writeln('Retrieved: ${retrieved.length} ricordi');
      for (int i = 0; i < retrieved.length; i++) {
        final r = retrieved[i];
        final sim = r.similarity.toStringAsFixed(3);
        buffer.writeln('  ${i + 1}. [$sim] ${r.content}');
      }
      buffer.writeln('');

      if (retrieved.isEmpty) {
        buffer.writeln('❌ Retrieve vuoto, impossibile fare V2.');
        setState(() => _response = buffer.toString());
        return;
      }

      final ricordiBlock =
          retrieved.map((r) => '- ${r.content}').join('\n');

      // ---- P1: Target language header ----
      final p1 = 'TARGET LANGUAGE: English\n'
          '\n'
          'You are Giorgio. Using ONLY the memories below, answer the '
          'question. If the memories are not enough, say "I don\'t remember '
          'well". Answer in first person, one short sentence, in the TARGET '
          'LANGUAGE. Render any foreign-language memory faithfully in the '
          'target language without inventing details.\n'
          '\n'
          'Memories:\n$ricordiBlock\n'
          '\n'
          'Question: $question';

      // ---- P2: Primer prefix ----
      final p2 = 'You are Giorgio, responding in first person. Use ONLY the '
          'memories below to answer the question. If not enough info, say "I '
          'don\'t remember well". One short sentence. Render any memory '
          'faithfully without inventing details.\n'
          '\n'
          'Memories:\n$ricordiBlock\n'
          '\n'
          'Question: $question\n'
          '\n'
          'Answer (in English): ';

      // ---- P3: Few-shot ----
      final p3 = 'You are Giorgio. Answer the question using ONLY the '
          'memories provided. Answer in the SAME LANGUAGE as the question, '
          'even if the memories are in a different language. Render foreign '
          'memories faithfully, without inventing details.\n'
          '\n'
          '--- Example ---\n'
          'Memories:\n'
          '- Sono nato a Verona nel 1940.\n'
          'Question: Where were you born?\n'
          'Answer: I was born in Verona in 1940.\n'
          '--- End of example ---\n'
          '\n'
          'Memories:\n$ricordiBlock\n'
          'Question: $question\n'
          'Answer:';

      final variants = <MapEntry<String, String>>[
        MapEntry('P1 target-language-header', p1),
        MapEntry('P2 primer-prefix', p2),
        MapEntry('P3 few-shot', p3),
      ];

      for (final entry in variants) {
        final label = entry.key;
        final prompt = entry.value;

        debugPrint('=== sweep $label prompt len=${prompt.length} ===');

        final gen = Stopwatch()..start();
        dynamic session;
        String out = '';
        String error = '';
        try {
          session = await model.createSession(temperature: 0.3, topK: 1);
          await session.addQueryChunk(
              Message.text(text: prompt, isUser: true));
          out = (await session.getResponse()) as String;
        } catch (e) {
          error = '$e';
        } finally {
          try {
            await session?.close();
          } catch (_) {}
        }
        gen.stop();

        buffer.writeln('─── $label (${gen.elapsedMilliseconds} ms)');
        if (error.isNotEmpty) {
          buffer.writeln('  ERROR: $error');
          continue;
        }
        buffer.writeln('  Risposta: $out');

        final outLower = out.toLowerCase().trim();
        final looksEn = RegExp(r'\b(we|i|the|got|were|our|at|on|in|was|born)\b')
                .allMatches(outLower)
                .length >=
            2;
        final looksIt = RegExp(r'\b(ci|ho|sono|siamo|nostro|nel|la|al|sposati|sul)\b')
                .allMatches(outLower)
                .length >=
            2;
        final verdict = looksEn && !looksIt
            ? '✅ EN'
            : (!looksEn && looksIt ? '❌ IT' : '⚠️  ambiguo');
        buffer.writeln('  Lingua: $verdict');
        debugPrint('=== sweep $label -> $verdict: $out ===');
      }

      stopwatch.stop();
      buffer.writeln('');
      buffer.writeln('---\nTotale: ${stopwatch.elapsed.inMilliseconds} ms');
      final responseMsg = buffer.toString();
      debugPrint('=== v2PromptSweep response ===\n$responseMsg');
      setState(() => _response = responseMsg);
    } catch (e, st) {
      stopwatch.stop();
      debugPrint('=== v2PromptSweep error ===\n$e\n$st');
      setState(() {
        _response = 'Errore sweep (dopo ${stopwatch.elapsed.inMilliseconds} ms):\n$e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _ask() async {
    final model = _model;
    if (model == null) {
      setState(() => _status = 'Prima carica il modello.');
      return;
    }
    setState(() {
      _busy = true;
      _response = 'Inferenza in corso...';
    });

    final stopwatch = Stopwatch()..start();
    dynamic session;
    try {
      session = await model.createSession(temperature: 0.8, topK: 1);
      await session.addQueryChunk(Message.text(
        text: 'Ciao, chi sei? Rispondi in una sola frase breve in italiano.',
        isUser: true,
      ));
      final out = await session.getResponse();
      stopwatch.stop();
      final responseMsg = '$out\n\n---\n'
          'Inferenza: ${stopwatch.elapsed.inMilliseconds} ms';
      debugPrint('=== ask response ===\n$responseMsg');
      setState(() => _response = responseMsg);
    } catch (e, st) {
      stopwatch.stop();
      debugPrint('=== ask error ===\n$e\n$st');
      setState(() {
        _response = 'Errore inferenza (dopo ${stopwatch.elapsed.inMilliseconds} ms):\n$e';
      });
    } finally {
      try {
        await session?.close();
      } catch (_) {}
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Importa i 6 ricordi seed del libro "Nonno parlaci di te" (Giorgio
  /// Marangoni, gen 2025) dal bundle assets/seed/ nel repository + vector
  /// store. Idempotente: se gia' caricati, skip silenzioso.
  Future<void> _loadGiorgioSeed() async {
    setState(() {
      _busy = true;
      _status = 'Caricamento seed Giorgio (6 ricordi + foto) dal bundle...';
      _response = '';
    });
    final sw = Stopwatch()..start();
    try {
      final loader = ref.read(seedLoaderProvider);
      final list = await loader.loadFromBundle();
      // Forza reload del MemoriesController cosi' la home riflette subito.
      await ref.read(memoriesProvider.notifier).reload();
      sw.stop();
      final imported = list.where((m) => m.id.startsWith('seed_')).length;
      setState(() {
        _status = 'Seed importati. Totale ricordi nel repo: ${list.length} '
            '($imported seed). Tempo: ${sw.elapsedMilliseconds} ms.';
        _response = list
            .where((m) => m.id.startsWith('seed_'))
            .map((m) => '• ${m.id} (${m.tag ?? '-'}): '
                '${m.text.length > 60 ? '${m.text.substring(0, 60)}...' : m.text}')
            .join('\n\n');
      });
    } catch (e, st) {
      sw.stop();
      debugPrint('[playground] seed load error: $e\n$st');
      setState(() {
        _status =
            'Errore caricamento seed (dopo ${sw.elapsedMilliseconds} ms): $e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        // Intenzionalmente colorScheme.inversePrimary per distinguere
        // visivamente il playground "dev" dalle schermate utente.
        backgroundColor: theme.colorScheme.inversePrimary,
        title: const Text('Playground (dev) - smoke test Gemma 4'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              GoRouter.of(context).go('/home');
            }
          },
        ),
        actions: const [VersionBadge()],
      ),
      // Fase 4.4.f fix: la Column della playground ha 9 bottoni + output RAG
      // che puo' essere molto lungo (test xlingual ~300 char di risposta).
      // Senza SingleChildScrollView il viewport del Pixel 7a sfonda di ~300px
      // e i bottoni finali diventano inaccessibili. Scrollamo tutta la pagina
      // e lasciamo che il card della risposta cresca alla sua altezza
      // naturale (rimosso l'Expanded + SingleChildScrollView interno).
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  _status,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _busy ? null : _loadModel,
              icon: const Icon(Icons.download_for_offline_outlined),
              label: const Text('1. Carica Gemma 4 E2B'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _ask,
              icon: const Icon(Icons.question_answer_outlined),
              label: const Text('2. Chiedi: "Ciao, chi sei?"'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _askImage,
              icon: const Icon(Icons.image_outlined),
              label: const Text('3. Descrivi immagine di esempio'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _askAudio,
              icon: const Icon(Icons.mic_outlined),
              label: const Text('4. Trascrivi audio di esempio'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _testEmbedding,
              icon: const Icon(Icons.auto_graph_outlined),
              label: const Text('5. Test embedding (RAG)'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _seedAndTestRag,
              icon: const Icon(Icons.library_books_outlined),
              label: const Text('6. Seed corpus + test RAG'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _chatRag,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('7. Chat RAG (domanda -> risposta)'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _testCrossLingual,
              icon: const Icon(Icons.translate_outlined),
              label: const Text('8. V1+V2 cross-lingual (IT↔EN)'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _v2PromptSweep,
              icon: const Icon(Icons.science_outlined),
              label: const Text('9. V2 prompt sweep (3 varianti EN)'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _busy ? null : _loadGiorgioSeed,
              icon: const Icon(Icons.menu_book_outlined),
              label: const Text('10. Carica seed Giorgio (libro)'),
            ),
            const SizedBox(height: 16),
            Text(
              'Risposta:',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            // Card della risposta: niente piu' Expanded (la pagina ora e'
            // scrollabile dal parent). Cresce all'altezza naturale del testo.
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  _response.isEmpty ? '(nessuna risposta ancora)' : _response,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            if (_busy)
              const Padding(
                padding: EdgeInsets.only(top: 12),
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }
}
