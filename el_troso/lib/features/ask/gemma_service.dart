// El Troso - GemmaService (Fase 4.5.e).
//
// Wrapper sopra FlutterGemma per l'inferenza del modello principale
// (gemma-4-E2B-it.litertlm, 2.58 GB). Pattern speculare a
// VectorStoreService: _ensureReady() lazy, fail con Exception esplicita
// se il file modello manca sul device (scenario atteso durante sviluppo),
// log di latenza con Stopwatch.
//
// Ciclo di vita:
//   - _ensureReady() idempotente. Alla prima chiamata: installModel +
//     getActiveModel (GPU). Costa ~10 s; per questo il provider NON e'
//     autoDispose (niente reload ad ogni cambio route).
//   - Lazy: niente init in main.dart. Il costo si paga al primo tap su
//     "Chiedi" nella AskPage. Se si tocca "Fai una domanda" e parte, ok;
//     se non lo si tocca mai, non si e' caricato 2.58 GB di modello.
//
// Stateless lato prompt:
//   - ask(prompt) crea una session nuova ogni volta, la chiude nel
//     finally. Niente multi-turn conversation state qui — il caller
//     costruisce il prompt completo (incluso eventuale RAG block) e lo
//     passa come singolo Message.text.
//   - temperature 0.3 / topK 1: valori validati in Fase 3.6 per
//     rispondere in modo "ancorato ai ricordi" senza divagazioni.
//     Diverso dai 0.8 usati nel playground per le domande generiche.
//
// Errori:
//   - ask() propaga l'eccezione al caller. La AskPage mostra il messaggio
//     in un fallback UI. Niente silent swallow perche' il giro e'
//     user-initiated (l'utente ha premuto "Chiedi"), non fire-and-forget.

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:path_provider/path_provider.dart';

// Stesso nome file usato in playground_page.dart (kModelFileName).
// Duplicato qui per non far dipendere la feature reale da codice
// dev-only. Se un giorno cambiamo modello, aggiornare entrambi i punti.
const String _kModelFileName = 'gemma-4-E2B-it.litertlm';

class GemmaService {
  bool _initialized = false;
  // Tipizzato dynamic come in playground_page.dart: il tipo reale
  // restituito da getActiveModel ha nomi che non vogliamo vincolare
  // a mano qui. Ci basta poter chiamare createSession().
  dynamic _model;

  Future<void> _ensureReady() async {
    if (_initialized) return;

    final sw = Stopwatch()..start();

    final extDir = await getExternalStorageDirectory();
    if (extDir == null) {
      throw Exception(
        'getExternalStorageDirectory() ha restituito null - '
        'impossibile risolvere il path del modello.',
      );
    }
    final modelPath = '${extDir.path}/$_kModelFileName';

    if (!await File(modelPath).exists()) {
      throw Exception(
        'Modello Gemma 4 non presente sul device: $modelPath. '
        'Eseguire adb push del file .litertlm in ${extDir.path}/.',
      );
    }

    // fileType va dichiarato esplicitamente: il plugin non lo deduce
    // dall'estensione e di default assume ModelFileType.task, che
    // formatta il prompt in modo incompatibile e causa
    // nativeSendMessage INTERNAL ERROR. Stesso fix applicato in
    // playground_page.dart in Fase 3.2.
    await FlutterGemma
        .installModel(
          modelType: ModelType.gemmaIt,
          fileType: ModelFileType.litertlm,
        )
        .fromFile(modelPath)
        .install();

    // GPU backend + multimodal flags. supportImage e supportAudio
    // abilitano i rami multimodali del modello (Fase 4.5.f). Stesse
    // flag usate nel playground (Fase 3.2). maxNumImages=1: un ricordo
    // ha al massimo una foto.
    // maxTokens 2048: Gemma 4 E2B supporta nativamente 32K context. Build
    // 39 alzato da 1024 a 2048 dopo `INVALID_ARGUMENT: 1238 >= 1024` su G5
    // con ricordo lungo (es. "le elementari" ~250 token) + paraphrase rule
    // + 4 esempi A/A2/B/C/D (~250 token) + user continuation. Il KV cache
    // marginale di +1024 token e' ~80MB su Pixel 7a (8GB RAM): ok.
    // Se OOM in futuro, prima trimmare il memory.text nel prompt G5 a
    // ~100 parole, poi riportare maxTokens a 1024.
    _model = await FlutterGemma.getActiveModel(
      maxTokens: 2048,
      preferredBackend: PreferredBackend.gpu,
      supportImage: true,
      supportAudio: true,
      maxNumImages: 1,
    );

    _initialized = true;
    sw.stop();
    debugPrint(
      '[gemma] ready in ${sw.elapsedMilliseconds} ms (model=$modelPath)',
    );
  }

  /// Pone [prompt] al modello e ritorna la risposta completa. Crea una
  /// session mono-turno (temp 0.3, topK 1) e la chiude nel finally.
  Future<String> ask(String prompt) async {
    await _ensureReady();
    final sw = Stopwatch()..start();
    dynamic session;
    try {
      session = await _model.createSession(temperature: 0.3, topK: 1);
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      final out = await session.getResponse();
      sw.stop();
      final outStr = out.toString();
      debugPrint(
        '[gemma] ask promptLen=${prompt.length} '
        'in ${sw.elapsedMilliseconds} ms '
        '-> "${_short(outStr)}" (len=${outStr.length})',
      );
      return outStr;
    } finally {
      try {
        await session?.close();
      } catch (_) {
        // session.close() puo' throware se gia' chiusa o se il modello
        // e' stato disposto nel frattempo. Non e' un problema per il
        // caller, che ha gia' la risposta o l'errore.
      }
    }
  }

  String _short(String s) => s.length <= 60 ? s : '${s.substring(0, 60)}...';

  // Nota (build 20): rimosso `describeImage`. La descrizione visiva
  // delle foto non è il ricordo autobiografico vero e usarla nei
  // prompt (G3, embedding semantico) portava il modello a confermare
  // dettagli non presenti nel testo del ricordo. Il ricordo ora è
  // SOLO il testo dettato dall'utente: la foto è un cue visivo non
  // elaborato. Se in futuro servirà reintrodurre describeImage per un
  // uso diverso (es. alt-text accessibilità), considerare di NON
  // farlo entrare in nessun prompt di validazione.

  /// Traduce [text] da [fromLang] a [toLang] (codici ISO 'it' / 'en')
  /// usando Gemma 4 E2B on-device. Build 42 — feature "Traduci" on-demand
  /// nel dettaglio ricordo.
  ///
  /// Prompt design:
  ///   - Esplicita le lingue (Gemma è multilingual ma performa meglio
  ///     con la coppia from/to dichiarata che con language detection
  ///     implicita).
  ///   - Preserva nomi propri e prima persona (i ricordi di Giorgio
  ///     hanno molti nomi storici: Pippo, Calvi, Mazzi, Teolo).
  ///   - Output puro, niente "Translation:" o virgolette: parsing più
  ///     stabile, niente regex di pulizia.
  ///   - temperature 0.2 (più bassa di ask 0.3): per la traduzione
  ///     vogliamo coerenza, non creatività.
  ///
  /// Ritorna la traduzione pulita (trim). Throw se Gemma fallisce.
  Future<String> translate(
    String text, {
    required String fromLang,
    required String toLang,
  }) async {
    if (fromLang == toLang) return text;
    final prompt = _buildTranslatePrompt(
      text,
      fromLang: fromLang,
      toLang: toLang,
    );
    await _ensureReady();
    final sw = Stopwatch()..start();
    dynamic session;
    try {
      session = await _model.createSession(temperature: 0.2, topK: 1);
      await session.addQueryChunk(Message.text(text: prompt, isUser: true));
      final out = await session.getResponse();
      sw.stop();
      var s = out.toString().trim();
      // Pulizia difensiva: a volte il modello mette virgolette di
      // apertura/chiusura nonostante l'istruzione esplicita.
      s = s.replaceFirst(RegExp(r'^["“”]'), '').trim();
      s = s.replaceFirst(RegExp(r'["“”]$'), '').trim();
      debugPrint(
        '[gemma] translate $fromLang→$toLang '
        'inLen=${text.length} outLen=${s.length} '
        'in ${sw.elapsedMilliseconds} ms',
      );
      return s;
    } finally {
      try {
        await session?.close();
      } catch (_) {}
    }
  }

  String _buildTranslatePrompt(
    String text, {
    required String fromLang,
    required String toLang,
  }) {
    final fromName = fromLang == 'it' ? 'Italian' : 'English';
    final toName = toLang == 'it' ? 'Italian' : 'English';
    return '''
You are a careful translator. Translate the autobiographical memory below from $fromName to $toName.

Rules:
- Preserve proper names exactly (people, places, named objects). Examples to keep verbatim if present: Pippo, Teolo, Calvi, Mazzi, Padova, Adua.
- Keep the first-person voice and the warm narrative tone.
- For dialect or regional expressions with no direct equivalent, render them in natural ${toName.toLowerCase()} without adding details that are not in the original.
- Do NOT add explanations, footnotes, or commentary.
- Output ONLY the translated text. No quotes, no preamble like "Translation:" or "Here is".

Original ($fromName):
$text

$toName translation:''';
  }

  /// Trascrive un file audio (WAV) in italiano usando Gemma 4 E2B.
  /// Ritorna la trascrizione testuale.
  Future<String> transcribeAudio(Uint8List audioBytes) async {
    await _ensureReady();
    final sw = Stopwatch()..start();
    dynamic session;
    try {
      session = await _model.createSession(temperature: 0.3, topK: 1);
      await session.addQueryChunk(Message.withAudio(
        text: 'Trascrivi in italiano cosa dice questa voce. '
            'Riporta fedelmente le parole pronunciate.',
        audioBytes: audioBytes,
        isUser: true,
      ));
      final out = await session.getResponse();
      sw.stop();
      final outStr = out.toString().trim();
      debugPrint(
        '[gemma] transcribeAudio ${audioBytes.length} bytes '
        'in ${sw.elapsedMilliseconds} ms -> "${_short(outStr)}"',
      );
      return outStr;
    } finally {
      try {
        await session?.close();
      } catch (_) {}
    }
  }
}
