// El Troso - G5 "Storia continua": logica pura.
//
// Vedi `story_page.dart` per la UI. Qui:
//   - selezione del ricordo target (richiede testo abbastanza lungo
//     per essere segmentato in incipit + continuazione)
//   - segmentazione del testo: incipit (prime 1-2 frasi) + continuazione
//   - prompt: feedback caldo che confronta la continuazione raccontata
//     dall'utente con la continuazione "vera" del ricordo
//
// EBM ANCHOR
// ────────────────────────────────────────────────────────────────────
// G5 è la versione "narrativa lunga" della reminiscence therapy.
//
// - Cotelli M et al. (2012) "Cognitive rehabilitation in Alzheimer's
//   disease: A controlled intervention study". Stimolazione narrativa
//   guidata in pazienti AD lievi: miglioramento autobiografico
//   episodico. La continuazione narrativa di un ricordo "innesca"
//   il sistema episodico nei modi più simili al funzionamento
//   spontaneo (vs un quiz a domande chiuse).
//
// - Cochrane Woods 2018 (CD001120). Reminiscence therapy 1:1 con
//   stimolo personalizzato. G5 è esattamente reminiscenza guidata,
//   con l'app come facilitatore al posto del familiare/operatore.
//
// - Bluck S. & Levine LJ (1998) "Reminiscence as autobiographical
//   memory: A catalyst for reminiscence theory development". La
//   continuazione di un ricordo a partire da un cue narrativo è il
//   meccanismo più ecologicamente valido per stimolare la memoria
//   autobiografica in contesto domestico (vs setting clinico).
//
// - Carstensen positivity effect (2012). Il ricordo che scegliamo per
//   il gioco è autobiografico → emotivamente significativo. Questo
//   massimizza l'engagement nei pazienti anziani.
//
// SCELTA DEL RICORDO
// ────────────────────────────────────────────────────────────────────
// Random tra ricordi che:
//   - hanno almeno 2 frasi (servono per separare incipit + resto)
//   - hanno testo >= 80 caratteri (sotto, l'incipit + la continuazione
//     sarebbero troppo corti per essere significativi)
//
// Per gestire i punti dentro le citazioni (es. seed_03 ha "Pippo")
// segmentiamo solo sui punti seguiti da spazio o newline.

import 'dart:math';

import 'package:el_troso/features/memory/memory.dart';

/// Risultato della segmentazione del testo del ricordo.
class StorySegments {
  const StorySegments({
    required this.incipit,
    required this.continuation,
  });

  /// Incipit letto dall'app (a voce + testo a video).
  final String incipit;

  /// Continuazione "vera" del ricordo, usata da Gemma per confrontare
  /// la continuazione raccontata dall'utente. NON viene mostrata al-
  /// l'utente prima che abbia provato a continuare (altrimenti il
  /// gioco non ha senso).
  final String continuation;

  bool get hasContinuation => continuation.trim().isNotEmpty;
}

/// Lista dei ricordi giocabili: testo lungo abbastanza da essere
/// segmentato in incipit + continuazione significativa.
List<Memory> playableMemories(List<Memory> all) {
  return all.where((m) {
    if (m.text.trim().length < 80) return false;
    final segments = segmentForStory(m.text);
    return segments.hasContinuation;
  }).toList();
}

/// Sceglie un ricordo da proporre. Ritorna null se nessun ricordo è
/// abbastanza lungo. [seed] iniettabile per test.
Memory? pickStoryTarget(List<Memory> memories, {int? seed}) {
  final pool = playableMemories(memories);
  if (pool.isEmpty) return null;
  final rnd = seed != null ? Random(seed) : Random();
  return pool[rnd.nextInt(pool.length)];
}

/// Segmenta il testo del ricordo in incipit + continuazione.
///
/// Regola: incipit = la PRIMA frase completa (fino al primo punto
/// seguito da spazio o newline). Se la prima frase è molto corta
/// (< 12 parole) prendiamo le prime DUE frasi come incipit, così
/// l'utente ha un cue abbastanza ricco per continuare.
///
/// Continuazione = tutto il resto del testo dopo l'incipit, fino a
/// massimo ~50 parole (oltre, troppo lungo da confrontare).
StorySegments segmentForStory(String text) {
  final trimmed = text.trim();
  // Punto seguito da spazio o newline OPPURE newline da solo. Non
  // separa i punti dentro le citazioni tipo "Pippo".
  final sentenceEnd = RegExp(r'[.!?]\s+|\n+');
  final matches = sentenceEnd.allMatches(trimmed).toList();
  if (matches.isEmpty) {
    // Una sola frase: niente da continuare.
    return StorySegments(incipit: trimmed, continuation: '');
  }

  // Prima frase: dalla 0 alla fine del primo match.
  var firstEnd = matches.first.end;
  var incipitText = trimmed.substring(0, firstEnd).trim();
  final firstWordCount = incipitText.split(RegExp(r'\s+')).length;

  // Se la prima è troppo corta (< 12 parole) e c'è una seconda frase,
  // includila nell'incipit.
  if (firstWordCount < 12 && matches.length >= 2) {
    firstEnd = matches[1].end;
    incipitText = trimmed.substring(0, firstEnd).trim();
  }

  // Continuazione: il resto, troncato a ~50 parole se molto lungo.
  var rest = trimmed.substring(firstEnd).trim();
  final restWords = rest.split(RegExp(r'\s+'));
  if (restWords.length > 50) {
    rest = '${restWords.take(50).join(' ').trim()}…';
  }
  return StorySegments(incipit: incipitText, continuation: rest);
}

/// Prompt: dato il ricordo + l'incipit letto + la continuazione "vera"
/// + la continuazione raccontata dall'utente, Gemma produce un
/// feedback caldo errorless. Stesso spirito di G3 (build 33): se la
/// versione utente non corrisponde, il prompt redirige al fatto vero.
///
/// Differenza rispetto a G3 e G2: qui la persona ha appena RACCONTATO
/// liberamente la continuazione di una storia, quindi il feedback può
/// essere più discorsivo ("Esatto, e poi…", "Mmh, in realtà la storia
/// continuava così…"). Il modello vede sia la continuazione vera sia
/// quella dell'utente e sintetizza.
///
/// Su Gemma 4 E2B: temperature 0.3, topK 1.
String buildStoryFeedbackPrompt({
  required Memory memory,
  required String incipit,
  required String trueContinuation,
  required String userContinuation,
  String speakerName = 'Giorgio',
}) {
  return '''
Sei $speakerName e parli in prima persona, con calma e calore, ma sempre fedele al ricordo vero. Una persona ha appena continuato a voce un ricordo che le hai letto. Il tuo lavoro: confrontare la sua continuazione con la versione vera del ricordo qui sotto e darle un feedback caldo di 1-2 frasi.

Ricordo originale completo (la verità autobiografica, non parafrasare):
"${memory.text}"

L'incipit che la persona ha sentito leggere:
"$incipit"

Come continua davvero il ricordo:
"$trueContinuation"

Come ha continuato la persona:
"$userContinuation"

Decidi in silenzio se la sua continuazione è COERENTE, PARZIALE o NON COERENTE con quella vera. POI scrivi UNA SOLA risposta in italiano, in prima persona, di 1-2 frasi.

REGOLA IMPORTANTE: la persona NON deve riprodurre il testo letterale del ricordo. Se la sua frase ESPRIME LO STESSO FATTO con parole diverse (parafrasi), considerala COERENTE. Esempi di parafrasi che valgono come coerenti:
- "siamo andati a Teolo" ≡ "si trovò alloggio a Teolo" → stessa cosa
- "papà ha avuto un incidente" ≡ "il papà è rimasto coinvolto in un incidente" → stessa cosa
- "ho conosciuto la nonna alla parrocchia" ≡ "abbiamo conosciuto la nonna al patronato" → stessa cosa
Concentrati sui FATTI CHIAVE (luogo, persona, evento), non sulle parole esatte.

Esempi di feedback corretti:

A. La persona ha colto (anche con parole diverse):
   Vero: "...c'era questo aereo che chiamavamo Pippo, sorvolava di notte..."
   Persona: "C'era un aereo che chiamavamo Pippo che passava di notte"
   Tuo feedback: "Esatto, era proprio Pippo, sorvolava a bassa quota e bombardava dove vedeva luci accese."

A2. Parafrasi semantica (vale come coerente):
   Vero: "...si trovò alloggio a Teolo nei Colli Euganei..."
   Persona: "Siamo andati a Teolo"
   Tuo feedback: "Sì, ci siamo trasferiti a Teolo nei Colli Euganei, in una casa di amici della mamma."

B. La persona ha colto in parte:
   Vero: "...i miei genitori hanno cercato una sistemazione fuori città..."
   Persona: "Sono andati via da Padova"
   Tuo feedback: "Sì, sono andati via da Padova e hanno trovato alloggio a Teolo, in casa di amici della mamma."

C. La persona ha continuato in modo davvero diverso dal ricordo (NON parafrasi):
   Vero: "...ho conosciuto la nonna nel 1954 alla parrocchia..."
   Persona: "Ci siamo conosciuti al lavoro"
   Tuo feedback: "Aspetta, in realtà la storia continua un po' diversamente — ci siamo conosciuti nel 1954 al patronato della parrocchia, dove andavo a giocare ogni giorno."

D. La persona non sa o non ricorda:
   Persona: "Non mi ricordo bene"
   Tuo feedback: "Tranquillo, te lo racconto io: il ricordo continua così, [riassumi brevemente la continuazione vera]."

Regole assolute:
- Scrivi SOLO la frase di feedback in prima persona. NON scrivere etichette tipo "Feedback:", "Tuo feedback:", "Persona:".
- Mai confermare dettagli che NON sono nel ricordo originale.
- Mai trattare come "diverso" un fatto espresso in parole diverse: focus su luogo/persona/evento chiave, non sulla forma esatta.
- Mai dire "sbagliato" o "non ti ricordi". Per ridirigere usa toni morbidi: "Aspetta, in realtà…", "A pensarci bene…", "In realtà la storia continua…".
- Mai iniziare con interiezioni tipo "Mmh", "Hmm", "Eh": il sintetizzatore vocale le legge lettera per lettera (suona "EMME EMME ACCA").
- Tono caldo, prima persona, italiano semplice. Niente elenchi puntati.

Feedback:''';
}
