// El Troso - G2 "Indovina insieme": logica pura.
//
// Vedi `guess_page.dart` per la UI. Qui:
//   - selezione del ricordo target
//   - prompt #1: generazione di UNA domanda specifica sul ricordo
//   - prompt #2: feedback errorless sulla risposta dell'utente
//
// EBM ANCHOR
// ────────────────────────────────────────────────────────────────────
// G2 è la versione "interrogativa breve" della reminiscence therapy
// + spaced retrieval training.
//
// - USMART RCT 2017 (Alzheimer's Research & Therapy 9:26): primo
//   RCT di SRT erogato via tablet su pazienti MCI. Miglioramenti
//   significativi su Word List Recall vs usual care. G2 implementa
//   il paradigma "ricordo → domanda specifica → risposta dell'utente
//   → feedback corretto" che è il cuore di USMART.
//
// - Hopper T. et al. (2013) PMID 23886395 — review di interventi SRT.
//   Le domande possono essere a stimolo verbale (paradigma SRT
//   classico) o a stimolo visuo-verbale combinato. G2 supporta
//   entrambi (foto opzionale + domanda).
//
// - Roediger HL & Karpicke JD (2006) "The power of testing memory:
//   basic research and implications for educational practice".
//   Testing effect: l'interrogazione attiva consolida la memoria
//   meglio della rilettura passiva. Differenza chiave da F11 Ripercorri
//   (rilettura TTS) — G2 è il complemento attivo.
//
// - Clare e coll., PMC3381647 (errorless learning). Stesso spirito di
//   G3: il feedback NON enfatizza l'errore. Se la persona sbaglia,
//   il prompt redirige al fatto vero senza far sentire in fallo.
//
// SCELTA DEL RICORDO
// ────────────────────────────────────────────────────────────────────
// Random uniforme tra TUTTI i ricordi (con o senza foto). Diverso da
// G3 che richiede foto: una domanda testuale può essere posta anche
// su ricordi solo-testo. Filtro minimo: testo non vuoto, lunghezza
// >= 30 caratteri (sotto questa soglia il ricordo è troppo povero per
// generare una domanda significativa).

import 'dart:math';

import 'package:el_troso/features/memory/memory.dart';

/// Lista dei ricordi giocabili: testo non vuoto e lunghezza minima.
List<Memory> playableMemories(List<Memory> all) {
  return all.where((m) => m.text.trim().length >= 30).toList();
}

/// Sceglie un ricordo da proporre. Ritorna null se nessun ricordo è
/// abbastanza ricco. [seed] iniettabile per test.
Memory? pickGuessTarget(List<Memory> memories, {int? seed}) {
  final pool = playableMemories(memories);
  if (pool.isEmpty) return null;
  final rnd = seed != null ? Random(seed) : Random();
  return pool[rnd.nextInt(pool.length)];
}

/// Prompt #1: dato un ricordo, Gemma genera UNA domanda specifica e
/// affettuosa che inviti la persona a richiamare un dettaglio (luogo,
/// anno, persona, evento). La domanda è in seconda persona singolare.
///
/// Su Gemma 4 E2B: temperature 0.4, topK 1, una sola sessione mono-turno.
String buildGuessQuestionPrompt({
  required Memory memory,
}) {
  return '''
Sei un facilitatore caldo che aiuta una persona a tornare su un suo ricordo. Hai davanti il testo del ricordo. Devi formulare UNA domanda specifica e affettuosa che inviti la persona a richiamare un dettaglio del ricordo (un luogo, un anno, una persona, un evento, un nome).

Ricordo:
"${memory.text}"

Regole:
- Una sola domanda, in italiano, breve (max 15 parole).
- Specifica: deve riguardare un fatto preciso menzionato nel ricordo, non aperta tipo "cosa pensi?".
- Tono caldo, in seconda persona singolare ("ti ricordi", "sai dirmi", "raccontami").
- NON includere la risposta nella domanda.
- NON scrivere prefissi come "Domanda:", "Esempio:". Scrivi SOLO la frase della domanda.
- La domanda deve essere rispondibile da chi conosce il ricordo: niente domande retoriche o astratte.

Esempi (per allinearti al tono, non da copiare):
Ricordo che parla di una nascita nel 1940 → "Ti ricordi in che anno sei nato?"
Ricordo che parla di un aereo chiamato Pippo che sorvolava Teolo → "Come si chiamava l'aereo che sorvolava Teolo?"
Ricordo che parla del prof. Mazzi all'Istituto Calvi → "Sai dirmi chi era il professore di Economia al Calvi?"

Domanda:''';
}

/// Prompt #2: dato ricordo + domanda + risposta utente, Gemma valuta
/// e produce feedback caldo errorless. Riusa filosofia G3 (build 33):
/// se la risposta non corrisponde, il prompt redirige gentilmente al
/// fatto vero senza dire "sbagliato".
///
/// Su Gemma 4 E2B: temperature 0.3, topK 1.
String buildGuessFeedbackPrompt({
  required Memory memory,
  required String question,
  required String userAnswer,
  String speakerName = 'Giorgio',
}) {
  return '''
Sei $speakerName e parli in prima persona, con calma e calore, ma sempre fedele al ricordo vero. Una persona ha appena risposto a una domanda specifica sul ricordo qui sotto. Verifica se la risposta è corretta confrontandola SOLO con il testo del ricordo, e dai un feedback caldo in 1-2 frasi.

Ricordo originale (la verità autobiografica, non parafrasare):
"${memory.text}"

Domanda che è stata posta:
"$question"

Risposta della persona:
"$userAnswer"

Decidi in silenzio se la risposta è corretta, parziale, o errata. POI scrivi UNA SOLA frase di feedback in italiano, in prima persona, di 1-2 frasi.

Esempi di risposte corrette:

A. Risposta giusta:
   Domanda: "Ti ricordi in che anno sei nato?"
   Risposta: "1940"
   Il tuo feedback: "Esatto, era il 22 gennaio 1940, l'una e trenta di notte, c'era oltre mezzo metro di neve."

B. Risposta parziale:
   Domanda: "Come si chiamava l'aereo che sorvolava Teolo?"
   Risposta: "Un aereo militare"
   Il tuo feedback: "Sì, era un aereo militare — lo chiamavamo Pippo, sorvolava di notte a bassa quota."

C. Risposta errata o vaga:
   Domanda: "Ti ricordi in che anno sei nato?"
   Risposta: "Forse nel 1950"
   Il tuo feedback: "Aspetta, non era proprio quell'anno — sono nato il 22 gennaio 1940, in casa, in pieno inverno."

D. La persona non sa rispondere:
   Domanda: "Sai dirmi chi era il professore di Economia al Calvi?"
   Risposta: "Non mi ricordo"
   Il tuo feedback: "Tranquillo, era il prof. Mazzi — quello che l'ultimo giorno ci disse 'competenza e onestà'."

Regole assolute:
- Scrivi SOLO la frase di feedback in prima persona. NON scrivere etichette come "Feedback:", "Risposta:", "La tua risposta:".
- Mai confermare dettagli che NON sono nel ricordo.
- Mai dire "sbagliato" o "non ti ricordi". Per ridirigere usa toni morbidi e modali: "Aspetta, non era proprio così…", "Forse stiamo pensando a un altro momento…", "In realtà…".
- Mai iniziare con interiezioni tipo "Mmh", "Hmm", "Eh": il sintetizzatore vocale le legge lettera per lettera (suona "EMME EMME ACCA").
- Tono caldo, prima persona, italiano semplice. Niente elenchi puntati.

Feedback:''';
}
