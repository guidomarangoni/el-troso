// El Troso - G3 "Riconosci e racconta": logica pura.
//
// Vedi `recognize_page.dart` per la UI. Qui solo:
//   - selezione foto candidata da una List<Memory>
//   - costruzione del prompt grounded errorless-aware per Gemma
//
// EBM ANCHOR
// ────────────────────────────────────────────────────────────────────
// G3 e' la versione MVP della reminiscence therapy mediata da AI:
//
// - Woods B et al., Cochrane CD001120 (2018). Review di 22 RCT, n>1800,
//   reminiscence therapy in demenza. Conclusioni: benefici piccoli ma
//   consistenti su cognizione, mood, qualita' della vita; gli approcci
//   1:1 (persona ↔ stimolo + facilitatore) sono associati al beneficio
//   maggiore in cognizione + mood. G3 e' un 1:1 dove il facilitatore
//   e' Gemma 4 on-device, lo stimolo e' una foto biografica.
//
// - SenseCam corpus (Berry 2007, Memory 2014 PMID 24528204): la
//   revisione di immagini autobiografiche aumenta il numero di dettagli
//   richiamati a 2 settimane vs diario scritto. Cue visivo > cue
//   testuale per memoria autobiografica.
//
// - Carstensen LL, Reed AE (Frontiers in Psychology 2012, PMC3459016):
//   positivity effect / SST. Il prompt template di Gemma deve favorire
//   il "tono caldo + riconoscimento dei dettagli ricordati" — coerente
//   con la motivazione emotivo-positiva dominante in eta' avanzata.
//
// - Clare e coll., PMC3381647 (errorless learning review): NON dire
//   "sbagliato" / "non ti ricordi" mai. Anche di fronte a un mismatch
//   completo, il pattern UX corretto e' MODELLARE la risposta corretta
//   senza enfatizzare l'errore. Il prompt template impone questo
//   esplicitamente. ATTENZIONE: errorless learning != assecondamento
//   compiacente. Se il racconto utente non corrisponde al ricordo,
//   il prompt forza il modello a riportare al ricordo originale, NON
//   a confermare dettagli inventati. Differenza scoperta nel test
//   build 17: il modello rispondeva "Esatto, hai colto..." anche con
//   descrizioni totalmente fuori tema (vedi commento del prompt).
//
// SCELTA DELLA FOTO
// ────────────────────────────────────────────────────────────────────
// Strategia MVP semplice: random uniforme tra ricordi che hanno
// imagePath != null. In v1.x si potra' privilegiare ricordi con
// footprintOpacity < 1.0 (sbiaditi → buoni candidati per ripercorrere)
// e/o evitare ripetizioni nella stessa sessione.

import 'dart:math';

import 'package:el_troso/features/memory/memory.dart';

/// Ritorna la lista dei ricordi giocabili (con foto allegata).
List<Memory> playableMemories(List<Memory> all) {
  return all.where((m) => m.imagePath != null && m.imagePath!.isNotEmpty).toList();
}

/// Sceglie una foto-ricordo da proporre all'utente. Ritorna null se
/// non ci sono ricordi con foto. [seed] e' iniettabile per test.
Memory? pickRecognizeTarget(List<Memory> memories, {int? seed}) {
  final pool = playableMemories(memories);
  if (pool.isEmpty) return null;
  final rnd = seed != null ? Random(seed) : Random();
  return pool[rnd.nextInt(pool.length)];
}

/// Costruisce il prompt grounded errorless-aware per Gemma 4 E2B.
///
/// Comportamento atteso: il modello confronta il racconto dell'utente
/// con il SOLO testo del ricordo (no descrizione visiva) e risponde
/// con tono caldo MA onesto. Se quello che ha detto l'utente non c'è
/// nel ricordo, deve negarlo esplicitamente prima di raccontare il
/// ricordo vero. "Errorless learning" qui significa "non far sentire
/// l'utente in fallo" — NON significa "confermare cose false".
///
/// Storia (build 17 → 18 → 19 → 20 → 32):
/// - 17→18: 3 regole equivalenti, E2B scivolava sempre su "Esatto,
///   hai colto..." anche con input fuori tema. Aggiunto passo
///   COERENTE / PARZIALE / NON COERENTE + esempi per branch.
/// - 18→19: rimossa `imageDescription` dal prompt — la descrizione
///   visiva non è il ricordo autobiografico e falsava la validazione.
/// - 19→20: esempio NON COERENTE riformulato per NEGARE esplicitamente
///   anziché ripetere "qui in realtà siamo a [X]" (conferma camuffata).
/// - 20→32: prompt-leaking — il modello copiava letteralmente i titoli
///   "CASO NON COERENTE — NEGA esplicitamente..." nell'output utente.
///   Cause: i titoli dei branch sembrano testo da imitare (siamo
///   in zona few-shot per E2B, soglia bassa di confusione tra
///   istruzione e contenuto). Fix: tolto "CASO X" come header,
///   sostituito con esempi puri "Persona dice / La tua risposta",
///   aggiunta regola assoluta che vieta esplicitamente di scrivere
///   meta-etichette ("CASO X", "Esempio X", "La tua risposta:").
/// - 32→33: tono delle negazioni più dolce. "Eh no" / "No, non" /
///   "non c'entra niente" suonavano bruschi: contro il principio
///   errorless learning di Clare et al. (PMC3381647). Riformulato
///   con esitazione modale ("Mmh, non credo...", "Forse stiamo
///   pensando a un altro momento") che redirige al ricordo vero
///   senza far sentire la persona in fallo, mantenendo onestà sul
///   contenuto del ricordo.
/// - 33→38: rimozione delle interiezioni "Mmh" / "Hmm". Su Android
///   il flutter_tts sintetizza "Mmh" come "EMME EMME ACCA" lettera
///   per lettera, invece di trattarla come pausa vocale. Sostituite
///   con formule modali leggibili dal TTS: "Aspetta...", "In realtà...",
///   "A pensarci bene...", "Sai...". Stessa modifica applicata anche
///   ai prompt di G2 (guess) e G5 (story).
///
/// Token budget: ~340 token base. Su maxTokens=1024 restano ~680 per
/// ricordo + recall + risposta.
String buildRecognizePrompt({
  required Memory memory,
  required String userRecall,
  String speakerName = 'Giorgio',
}) {
  final ricordo = memory.text;

  return '''
Sei $speakerName e parli in prima persona, con calma e calore, ma sempre fedele al ricordo vero.
Una persona ti dice cosa pensa di vedere in una foto. Tu confronti SOLO con il testo del ricordo qui sotto: è l'unica verità di cui disponi. Non immaginare cosa ci sia nella foto: non l'hai vista.

Ricordo originale (la verità autobiografica, non parafrasare):
"$ricordo"

Quello che la persona ha appena detto:
"$userRecall"

Decidi in silenzio se quello che la persona ha detto è coerente, parziale o non coerente con il ricordo. POI scrivi UNA SOLA risposta in italiano, in prima persona, di 1-2 frasi.

Esempi di risposte corrette:

A. Persona: "Eravamo in via Adua a giocare a palline."
   La tua risposta: "Sì, era proprio in via Adua, e i giochi con le palline di vetro li ricordo bene."

B. Persona: "Era la parrocchia."
   La tua risposta: "La parrocchia sì, era la Sacra Famiglia — e lì ho anche conosciuto la nonna nel 1954."

C. Persona: "Eravamo alla comunione di Marta."
   La tua risposta: "Aspetta, non credo che fosse quel giorno — qui in realtà sono io appena nato in casa, era il 22 gennaio 1940, in pieno inverno con oltre mezzo metro di neve."

D. Persona: "Era una vacanza al mare."
   La tua risposta: "Forse stiamo pensando a un altro momento — qui siamo in via Adua, la stradina sterrata di Padova dove giocavamo a palline e tappi di bibite."

Regole assolute:
- Scrivi SOLO la frase finale in prima persona. NON scrivere etichette come "CASO X", "Esempio X", "Persona:", "La tua risposta:", "Risposta:". NON scrivere meta-commenti sul ragionamento.
- Mai confermare persone, luoghi o eventi che non sono scritti nel ricordo. Se non c'è corrispondenza, riportala gentilmente al ricordo vero senza farla sentire in fallo.
- Mai usare la formula "qui siamo a [quello che ha detto la persona]" come conferma camuffata.
- Per contraddire usa toni morbidi e modali: "Aspetta, non credo...", "Forse stiamo pensando a un altro momento", "In realtà mi ricordo che...", "A pensarci bene...". Mai iniziare con interiezioni come "Mmh", "Hmm", "Eh" — il sintetizzatore vocale le legge lettera per lettera. Mai "sbagliato", "non ti ricordi", "no" secco, "non c'entra niente".
- Tono caldo, prima persona, italiano semplice. Niente elenchi puntati.

Risposta:''';
}
