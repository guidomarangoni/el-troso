// El Troso - G1 "Memoria delle foto": logica pura.
//
// Memory matching game con foto del proprio archivio biografico. Vedi
// `photo_match_page.dart` per la UI. Qui solo:
//   - costruzione del mazzo (6 coppie da N foto disponibili)
//   - match check
//   - win condition
//
// EBM ANCHOR
// ────────────────────────────────────────────────────────────────────
// G1 si aggancia al filone "serious games in MCI/AD" del corpus
// `docs/El Troso - Studi scientifici.md` §3:
//
//   - JMIR Serious Games 2024 (PMID 39083796, PMC 11324188): meta-
//     analisi di 14 RCT (n=714, 2017-2023) su serious games digitali
//     in AD e MCI. Conclusione: serious games digitali superano le
//     modalita' di training tradizionali su cognizione globale,
//     comportamento quotidiano e depressione. → giustifica il PARADIGMA
//     "gioco digitale come intervento terapeutico in MCI".
//
//   - JMIR 2023 (PMID 37043277): effetto positivo su VERBAL LEARNING
//     in MCI e AD, simile tra i due gruppi.
//
//   - Visual recognition memory: storicamente uno dei domini meglio
//     preservati in MCI (vs. recall libero che cala prima). → un gioco
//     di matching visivo e' calibrato sul dominio piu' robusto, evita
//     frustration e fa leva sull'errorless learning §5c.
//
// ONESTA' SCIENTIFICA
// ────────────────────────────────────────────────────────────────────
// Il design specifico "memory matching su foto autobiografiche" NON
// e' direttamente testato in un RCT del corpus paper attuale. Cio' che
// e' supportato e':
//   (a) il PARADIGMA "serious gaming digitale in MCI" (JMIR 2024)
//   (b) la SCELTA del dominio "visual recognition" (preservato in MCI)
//   (c) l'USO di materiale autobiografico personalizzato come engager
//       emotivo (Cochrane Woods 2018 reminiscence + Carstensen
//       positivity §5d)
//
// Nel pitch Kaggle e write-up: dichiararlo come "design integrato che
// applica principi RCT-validati", NON come "intervento clinicamente
// validato". Questa onesta' va nel write-up §6 di Studi scientifici.
//
// PERSONALIZZAZIONE = ENGAGER EMOTIVO
// ────────────────────────────────────────────────────────────────────
// Le carte non sono pittogrammi generici (le tipiche memory cards di
// Pinterest/MemoryMate): sono FOTO della persona stessa. Il calpestio
// del ricordo (G4 SRT) avviene anche quando si gira una carta-foto e
// si rivede un volto, un luogo, un evento. Per questo ogni partita
// registra un Walk per ogni coppia matched (vedi photo_match_page.dart).

import 'dart:math';

import 'package:el_troso/features/memory/memory.dart';

/// Numero di coppie di default. 6 = 12 carte = griglia 4x3 — adatto a
/// un Pixel 7a in portrait con touch target ≥ 80dp.
const int kDefaultPairCount = 6;

/// Una singola "card" del mazzo. [slot] e' 0 o 1 — la stessa memory
/// genera due cards con slot diversi cosi' possiamo distinguerle nel
/// matching anche se hanno lo stesso memoryId.
class MatchCard {
  final String memoryId;
  final String imagePath;
  final int slot; // 0 o 1: due card per memoria

  const MatchCard({
    required this.memoryId,
    required this.imagePath,
    required this.slot,
  });

  @override
  String toString() => 'MatchCard(${memoryId}_$slot)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MatchCard &&
          memoryId == other.memoryId &&
          slot == other.slot;

  @override
  int get hashCode => Object.hash(memoryId, slot);
}

/// Costruisce il mazzo: prende [pairCount] memorie a caso tra quelle
/// con foto, genera 2 cards per ognuna, mescola l'ordine. Ritorna una
/// lista di [pairCount * 2] MatchCard.
///
/// Dedupa per `imagePath` (build 43): se due ricordi puntano allo
/// stesso file foto (succede se l'utente seleziona dalla galleria la
/// stessa immagine due volte, o se un seed e un ricordo utente
/// condividono il file), una sola entry entra nel pool. Senza questa
/// dedupe il deck poteva contenere 4 carte visivamente identiche
/// (2 coppie con stessa foto, memoryId diversi) → matching
/// indistinguibile, gioco rotto.
///
/// Se dopo dedupe ci sono meno di [pairCount] foto uniche, ritorna
/// lista vuota (la pagina mostrera' empty state "non abbastanza foto").
///
/// [seed] e' iniettabile per test deterministici.
List<MatchCard> buildDeck(
  List<Memory> memories, {
  int pairCount = kDefaultPairCount,
  int? seed,
}) {
  // Filtro + dedupe per imagePath. Manteniamo l'ordine di prima
  // apparizione (Set<String> + lista parallela) per stabilità: il
  // primo ricordo che usa una foto vince.
  final seenPaths = <String>{};
  final uniquePhoto = <Memory>[];
  for (final m in memories) {
    final p = m.imagePath;
    if (p == null || p.isEmpty) continue;
    if (!seenPaths.add(p)) continue; // stessa foto già contata
    uniquePhoto.add(m);
  }
  if (uniquePhoto.length < pairCount) return const [];

  final rnd = seed != null ? Random(seed) : Random();
  // Scegli pairCount memorie senza ripetizione.
  final shuffledMems = List<Memory>.from(uniquePhoto)..shuffle(rnd);
  final picked = shuffledMems.take(pairCount).toList();

  // Genera 2 card per memoria.
  final deck = <MatchCard>[];
  for (final m in picked) {
    deck.add(MatchCard(memoryId: m.id, imagePath: m.imagePath!, slot: 0));
    deck.add(MatchCard(memoryId: m.id, imagePath: m.imagePath!, slot: 1));
  }
  // Mescola l'ordine finale.
  deck.shuffle(rnd);
  return deck;
}

/// Verifica se due indici nel deck rappresentano un match (stessa
/// memoria, slot diversi).
bool isMatch(List<MatchCard> deck, int a, int b) {
  if (a == b) return false;
  if (a < 0 || b < 0 || a >= deck.length || b >= deck.length) return false;
  return deck[a].memoryId == deck[b].memoryId;
}

/// Win condition: tutte le carte sono "matched".
bool isWon(List<MatchCard> deck, Set<int> matched) {
  return matched.length == deck.length && deck.isNotEmpty;
}

/// Conta le coppie risolte (quante coppie sono state matched). Pari a
/// `matched.length / 2`.
int pairsFound(Set<int> matched) => matched.length ~/ 2;
