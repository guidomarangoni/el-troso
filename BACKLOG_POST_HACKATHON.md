# El Troso — Backlog post-hackathon

**Aperto:** 2026-04-25
**Scopo:** raccogliere idee e feature emerse durante la build che NON entrano nell'MVP per la submission Kaggle del 2026-05-18, in modo che il lock di scope resti credibile e nessuna idea venga persa.

> Regola: se durante la Fase 4 emerge una "tentazione di scope", finisce qui — non nel codice MVP.

---

## Giochi serious gaming valutati e non scelti

### G2 — Quiz scelta multipla con distractor generati da Gemma
- **Paradigma EBM**: cognitive training adattivo (Bahar-Fuchs 2017, ACTIVE Rebok 2014) — `docs/El Troso - Studi scientifici.md` §4
- **Perché skip nel MVP**: tensione strutturale con errorless learning (Clare e coll., PMC3381647 — `docs/El Troso - Studi scientifici.md` §5c). In MCI/AD un distractor verosimile può essere ricordato come la risposta corretta; va disegnato con cura altrimenti danneggia l'utente.
- **Riapertura ragionevole**: v1.1 con design errorless-rigoroso (no enfasi sull'errore, modeling della risposta corretta dopo MC, riduzione distractor a 2 facili + 1 vera).
- **Costo stimato**: 4-5 giorni (function calling per generazione distractor + fallback precomputed sui ricordi seed + UI feedback).

### G5 — Riordina cronologico (frammenti di ricordo lungo da ordinare)
- **Paradigma EBM**: episodic memory training, temporal ordering — paradigma noto ma EBM tenue nel corpus paper attuale.
- **Perché skip**: non c'è un paper RCT-tier nel corpus che lo supporti direttamente; richiede segmentazione affidabile via Gemma o fallback precomputed; demo video moderato.
- **Riapertura ragionevole**: v1.2 se emergono RCT specifici o se serve un terzo gioco con difficoltà incrementale.

---

## Feature MVP escluse esplicitamente da `VERTICAL_SLICE_SPEC.md` §3

Queste sono OUT da decisione di scope, **non** da impossibilità tecnica. Riapribili in v1.x.

- **Login / account / cloud sync / backup remoto**: privacy-by-design dell'MVP è on-device totale. v1.1 può aggiungere export/import opt-in (JSON+foto+audio in zip cifrato).
- **Modalità famigliare collaborativa real-time**: due dispositivi che condividono una sessione "ripercorri insieme". EBM solido (`docs/El Troso - Studi scientifici.md` §5e — reminiscenza intergenerazionale, Cochrane 2018 + intergenerational interventions). Costo alto: sync, peering, conflitti di stato. v1.1.
- **Ricerca full-text nei ricordi**: "mostrami tutto quello che parla di Maria" — easy, ma scope freeze.
- **Esporta in JSON/PDF**: utile per backup famigliare ma non urgente.
- **Dark mode**: il design El Troso è dichiaratamente daylight-only (parchment cream). v1.x se famiglia lo richiede.
- **Voce sintetica non-robotica per le risposte**: TTS Android system è il fallback. v1.1 valutare voci neurali on-device se peso accettabile.

---

## Capability Gemma 4 non sfruttate nell'MVP

- **Video nativo (60s @ 1fps)**: registrazione/analisi video di un ricordo lungo. Pesante in inference ma nativo Gemma 4. v1.x.
- **Reasoning mode `<|think|>`**: oggi prompt diretti. In v1.x può migliorare la scelta del cue (Tipo 1 SRT) o la qualità dei feedback (G3).
- **Function calling parallelo**: se G2 entra in v1.x, useremo function calling nativo invece di prompt template.

---

## Storyboard / video

- **Voce sintetica con accento veneto leggero per il TTS**: estensione di v1.x se Piper TTS o equivalente offline supporta inflessione regionale.

---

## Onboarding & UX

- **Onboarding congiunto caregiver+anziano** (Ipotesi C del `PIANO_FASE_4.md`): l'app guida la prima sessione a due voci. v1.1 dopo feedback dei primi utenti.
- **Tutorial inline contestuali**: tap-and-hold per ricevere spiegazione semplice di ogni elemento UI. v1.1.
- **Modalità tablet ottimizzata**: l'MVP dichiara "smartphone primario, tablet con layout non ottimale". v1.1.
- **Auto-load seed corpus in onboarding**: oggi i 6 ricordi del libro di Giorgio si caricano via Playground (debug-only). Per la demo Kaggle valutare uno step di onboarding finale "Hai un libro di ricordi da pre-caricare?" che esegua SeedLoader. Decisione tra 4.6 e Fase 5.

## Polish foto seed

- **Rivedere ridimensionamento e crop** delle 6 foto seppia in `assets/seed/used/`: oggi sono il blob originale del PDF a max 800px lato lungo (q85). Alcune foto (es. matrimonio in studio) hanno cornice/bordo/ombre del libro che si trascinano. Da valutare: crop dei margini, contrast restoration, eventuale upsampling AI per grana fine. Costo: 1-2 ore in fase 4.6 polish, no impatto su altre feature.

---

## Privacy & sicurezza

- **Cifratura at-rest del JSON ricordi e audio/foto**: oggi sono in plain Documents directory. v1.1 con flag opt-in (richiede UX di unlock biometrico).
- **Cancellazione completa del corpus** ("dimenticami"): UI per wipe totale + verifica.

---

## Localizzazione & dialetti

- **Dialetto veneto in trascrizione**: rule-based post-processing su SpeechRecognizer IT. Citato come N1 in `MULTILINGUA_PLAN.md` §4. v1.x.
- **Lingue oltre IT/EN**: spagnolo, francese, tedesco coperti nativamente da Gemma 4 e EmbeddingGemma — manca solo localizzazione UI (costo medio).
- **Lingue RTL e CJK**: arabo/ebraico → font + BiDi layout; cinese/giapponese/coreano → TTS Android scarso. v1.x con design dedicato.

### Traduzione ricordi — varianti eager (v1.x)

Build 42 (2026-05-05) ha implementato la **variante A on-demand**: `Memory.originalLang` salvato al record, traduzione lazy via `gemma.translate()` solo al tap "Traduci", niente persistenza. Vedi `VERTICAL_SLICE_SPEC.md` §12.h.

Le varianti **B** (eager save al primo cambio lingua) e **C** (eager save al record) sono state valutate e rimandate. Riapribili in v1.x se la qualità on-demand viene validata su:
- nomi propri (Pippo, Calvi, Mazzi, Teolo) — devono restare verbatim, non anglicizzati
- dialettalismi veneti — render naturale senza inventare dettagli
- prima persona + tono caldo

**B — Eager al primo cambio lingua** (~1 giorno): notifier in background traduce TUTTI i ricordi al primo switch IT↔EN, salva `Memory.translations: Map<String, String>`. Switch successivi istantanei. Costo prima volta: ~70s per 12 ricordi (con spinner narrativo "Sto traducendo i tuoi ricordi… 3/12" coerente con la metafora del sentiero).

**C — Eager al record** (~2 giorni + edge cases): ogni save fire-and-forget anche la traduzione. Tutti i ricordi sempre pronti in entrambe le lingue. Costo: doppio CPU al save, drift su ogni edit (richiede flag `stale` o re-translate automatico).

**Decisione**: NON promuovere B/C se la qualità on-demand di build 42 si rivela mediocre — meglio mantenere on-demand visibile come "best effort" con "mostra originale" sempre disponibile. Se invece la qualità è solida, B è il candidato preferito (un'unica attesa lunga ben narrata batte un'attesa media ad ogni save).

---

## iOS porting

- **Target**: quando Google rilascerà Swift API LiteRT-LM con multimodale completo. Oggi `.litertlm` è text-only su iOS.
- **Strategia**: Flutter è già investimento architetturale che permette il porting senza riscrivere. Rivalutare a Q3 2026 / Q1 2027.

---

## Caregiver / clinici

- **Caregiver setup mode**: il figlio installa e configura l'app per il genitore (chip walker già supporta self/child/grandchild/friend ma non c'è UX dedicato). v1.1.
- **Dashboard clinico**: out of scope filosofico — l'app è per la persona, non strumento di misura. Eventualmente v2.x come prodotto separato con consenso esplicito.

---

## Modulo QoL Assessment & Activity Recommender (v1.x)

Documento di design completo: [INTEGRAZIONE-MODULO-VALUTAZIONE.md](INTEGRAZIONE-MODULO-VALUTAZIONE.md) (2026-04-30).

- **Cosa è**: modulo che combina QOL-AD (Logsdon 2002, 13 item) + Mini-Cog (Borson 2000) + analisi via Gemma on-device → profilo + 4 attività personalizzate che pescano dai ricordi reali e innescano i giochi esistenti (G3/G1/G4).
- **Paradigma EBM**: QOL-AD validato in italiano, Mini-Cog gratuito, reminiscenza Cochrane Woods 2018 (già nel corpus). Aggiunge un livello "valutazione → personalizzazione" sopra al loop attuale.
- **Perché skip nel MVP Kaggle**:
    1. **Conflitto con scope-lock**: "Diagnosi o screening cognitivo" è OUT esplicito in `VERTICAL_SLICE_SPEC.md` §3 e nel trittico narrativo. Riapertura possibile ma da dichiarare.
    2. **Tempo**: roadmap del documento 4-6 settimane MVP; alla deadline 18/05 mancano ~18 giorni e c'è polish home + video pitch da chiudere.
    3. **Licenza QOL-AD**: serve autorizzazione scritta da Rebecca Logsdon (UW Seattle), tempi non garantiti per il 18/05.
    4. **Tensione narrativa**: linguaggio clinico ("compromissione", "borderline", "consulto specialistico") tira fuori dal registro "sentiero / calpestio". Il pitch ne soffrirebbe.
    5. **AI Act art. 6**: lo screening cognitivo + alert specialistico rischia classificazione "alto rischio" se l'app viene rilasciata. Per hackathon ok, per produzione serve audit dedicato.
- **Riapertura ragionevole**: v1.x post-Kaggle in due tappe.
    - **v1.1 — versione light "termometro del sentiero"** (~3-5 gg): 5 micro-domande casual (no test clinico, no Mini-Cog), output narrativo, reorder dell'SRT G4 in base ad area "debole" del giorno. Linguaggio el-troso-coerente.
    - **v1.2 — modulo completo come da documento** (~6 settimane): QOL-AD 13 item + Mini-Cog touch + caregiver proxy + storico/trend + catalogo `innesco_gioco_app` esteso. Richiede licenza Logsdon e validazione clinica (CREA Firenze, Bertelli).
- **Pre-requisito per v1.2**: estendere `Memory` con tag granulari (luoghi/persone/musica/ricette/eventi) oltre ai 5 attuali (`family/work/travel/home/other`). Costo ~1 settimana.

---

## Note operative

- Quando un'idea sale in priorità verso v1.x post-Kaggle, **promossa a `VERSION_NEXT.md`** con scope, EBM anchor, costo stimato. Questo file resta liste di idee grezze.
- Ogni voce di questo file dovrebbe avere almeno: paradigma EBM (se applicabile), motivo dello skip MVP, costo stimato. Se non riesci a scriverli, l'idea probabilmente non è ancora matura.
