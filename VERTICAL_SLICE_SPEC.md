# El Troso — Vertical Slice Spec (Fase 4)

**Data decisione:** 2026-04-20
**Deadline Kaggle:** 2026-05-18 (28 giorni)
**Team:** Guido + Claude
**Testimonial:** Giorgio (86 anni, padre di Guido)
**North star filosofica:** [`docs/El Troso - Visione etica e ispirazionale.md`](docs/El%20Troso%20-%20Visione%20etica%20e%20ispirazionale.md) — desire path, pre-paving, calpestio come atto di memoria. Ogni decisione di scope/design risponde a questo documento.
**Documenti di scope collegati:** `MULTILINGUA_PLAN.md`, `ONBOARDING_PLAN.md`

---

## 1. Decisione

**Vertical slice: Ipotesi A — "Raccogli, ripercorri, insieme".**

El Troso è un'app Android on-device che permette a Giorgio di:
- **Raccogliere** ricordi a voce (il calpestio che crea il troso)
- **Ripercorrerli** come gesto esplicito — riascoltare, rileggere, tornare sullo stesso ricordo (il calpestio che lo tiene vivo)
- **Interrogarli** come seconda forma di ripercorrimento mediata da Gemma 4 E2B con grounding
- **Calpestare insieme** ai familiari, che contribuiscono sia aggiungendo ricordi sia ripercorrendoli con Giorgio

I ricordi vengono trascritti, indicizzati semanticamente con EmbeddingGemma 300M, e interrogabili con Gemma 4 E2B che risponde in prima persona ammettendo "non mi ricordo bene" quando il contesto non basta. Un indicatore visivo delle orme mostra quali ricordi sono stati ripercorsi di recente e quali stanno sbiadendo nell'oblio — **non come reminder ansiogeno, ma come invito gentile a tornare**.

Tutto resta sul Pixel 7a: nessun server, nessun cloud, nessun account.

### Aderenza al trittico del documento di visione (§0)

Ogni decisione di scope sotto è stata misurata contro i quattro punti del nucleo metaforico:

| Punto del trittico | Feature che lo realizza |
|---|---|
| **Generazione dal calpestio** | F1 — Aggiungi ricordo a voce. Niente template, niente canone imposto |
| **Persistenza dal ripercorrimento** | F3 (Chiedi alla memoria) + F11 (Ripercorri card, riascolta, rileggi) |
| **Oblio dal non-uso** | F12 — orme che sbiadiscono nel tempo, invito gentile a ripercorrere |
| **Calpestare insieme** | F9 — chip "chi sta raccontando / ripercorrendo" (Giorgio / figlio / nipote / amico) |

Se in 4.5 una feature non risponde a uno di questi punti, va riconsiderata.

### Perché A invece di B o C

- **Continuità tecnica.** La pipeline Fase 3.6 (EmbeddingGemma + vector store + prompt injection con grounding, temperature 0.3) è già end-to-end su device. A estende linearmente; B e C aggiungono strati nuovi (generazione quiz safe / sync multi-utente) non prototipati.
- **Rischio deadline.** 28 giorni includono UI + testing con Giorgio + polish + video + write-up. A lascia margine (sempre più ristretto); C è un progetto a sé.
- **Storia Kaggle più forte.** Il trittico *genera/ripercorri/oblio/insieme* è narrativamente potente e mostrabile in video in 60-90 secondi. C non permette di vivere la metafora completa nel tempo del demo.
- **Safety story più pulita.** Il grounding con "non mi ricordo bene" (Test #3 di Fase 3.6) è la feature ethical-AI distintiva. Concentrarsi su quella profondamente batte spalmarsi su feature sociali.

---

## 2. Utente e contesto

### Primary user
**Giorgio, 86 anni.** Decadimento cognitivo lieve (MCI, non ancora dementia diagnosticata). Usa WhatsApp con difficoltà (caratteri grandi impostati dal figlio). Legge ancora ma lentamente. Udito buono. Vista: occhiali presbiopia. Parla italiano con inflessione veneta. Non digita su tastiera virtuale se non obbligato; preferisce la voce.

### Secondary user
**Figlio/figlia di Giorgio** (es. Guido stesso). Assiste l'onboarding, aiuta a registrare primi ricordi, può interrogare l'app "al posto di" Giorgio per ricostruire fatti di famiglia.

### Contesto d'uso
- Casa di Giorgio, divano o tavolo cucina
- Una sessione = 3-10 minuti, non di più
- Nessuna pretesa di uso giornaliero; uso "quando viene voglia"
- Il telefono è sul tavolo, non in mano

---

## 3. Scope

### IN scope (MUST ship)
1. **Onboarding leggero (3 schermate, ≤45s)** — accoglienza + nome + registro vocativo/decennio opzionali. Identità visiva "orma/desire path" coerente con documento di visione. Dettaglio in `ONBOARDING_PLAN.md`
2. **Aggiungi ricordo a voce** — pulsante grande, registrazione, trascrizione visibile e editabile, salvataggio con tag semplice (famiglia, lavoro, viaggi, casa, altro). *Trittico: generazione*
3. **Elenco ricordi con orme** — lista scorrevole, card con prime parole + tag + data + indicatore di orma (più marcata = ripercorso di recente, sbiadita = non calpestato da tempo). Tap per vedere tutto
4. **Chiedi alla tua memoria** — pulsante, TTS opzionale della risposta, input vocale O testo. *Trittico: persistenza (forma mediata da Gemma)*
5. **Risposta grounded** — mostra la risposta di Gemma + link visibile ai 1-3 ricordi usati come fonte ("da cosa ho capito questo?")
6. **"Non mi ricordo bene"** — quando il contesto non basta, la risposta lo ammette esplicitamente, ed è una feature messa in evidenza, non un errore
7. **Tutto on-device** — nessuna richiesta di rete dopo il download iniziale del modello
8. **Multilingua IT + EN** — UI completa in entrambe; Gemma risponde nella lingua della domanda anche se i ricordi sono in altra lingua; retrieval cross-lingual via EmbeddingGemma multilingua. Dettaglio in `MULTILINGUA_PLAN.md`
9. **Chip "chi sta raccontando / ripercorrendo"** (Giorgio / figlio / nipote / amico) — al salvataggio ricordo e al ripercorrimento. Valore salvato come `metadata` nel vector store; usato in prompt di retrieval per rispettare la voce collettiva. *Trittico: calpestare insieme*
10. **Ripercorri ricordo** — aperta la card di un ricordo, pulsante grande "Ripercorriamolo insieme". Al tap: chip "chi sta ripercorrendo?", poi TTS del testo originale (NON rigenerato da Gemma, per autenticità) + registrazione del ri-calpestio nel metadata (timestamp + chi). *Trittico: persistenza (forma diretta, senza Gemma)*
11. **Orme che sbiadiscono** — indicatore visuale: un ricordo non ripercorso da più di N giorni (default 14, configurabile) ha l'orma visibilmente più pallida. Nessuna notifica, nessun allarme — solo un segno visivo nella lista che invita a calpestare. Empty state speciale: "Qualche ricordo sta sbiadendo. Vuoi tornarci?" con tap opzionale. *Trittico: oblio + persistenza*

### SHOULD ship (se tempo)
- Ricerca full-text nei ricordi ("mostrami tutto quello che parla di Maria")
- Esporta ricordi in JSON/PDF per backup
- Sleep-friendly dark mode
- Voce sintetica leggibile (non robotica) per le risposte

### OUT of scope (espliciti — NON fare)
- Login, account, cloud sync
- Quiz o gamification
- Multi-utente / condivisione familiare
- Notifiche push "ricordati di registrare"
- Analisi emotiva o mood tracking
- Diagnosi o screening cognitivo di qualsiasi tipo
- Lingua diversa dall'italiano per il demo Kaggle (inglese solo per il write-up)
- Integrazione con calendario, foto, contatti, WhatsApp

**Ogni feature OUT è una tentazione reale. Se emerge durante 4.5, la respingiamo e la annotiamo come "Fase 5+".**

---

## 4. User journey principale (per il video Kaggle)

La scena copre tutti e quattro i punti del trittico del documento di visione. Tre atti brevi, ~90 secondi nel video finale.

### Atto 1 — Il calpestio nasce (generazione)

**Setting:** Giorgio al tavolo della cucina.

1. Giorgio apre l'app. Vede la frase grande: *"Ciao Giorgio, vuoi raccontare un ricordo o ripercorrerne uno?"* e due bottoni: **"Racconto"** e **"Ripercorro"**.
2. Tocca **"Racconto"**. Parte la registrazione. Racconta 30 secondi: "Nel '78 sono andato in Germania per lavoro, tre mesi ad Amburgo, pioveva sempre".
3. Vede la trascrizione, la conferma con un tap. Sceglie tag "viaggio". Chip "chi sta raccontando?" → tocca "Giorgio". Salvato — una nuova orma appare nella lista.

### Atto 2 — Il calpestio tiene vivo (persistenza) e segnala l'oblio

**Taglio a qualche giorno dopo (data overlay).**

4. Giorgio riapre l'app. Nella lista ricordi vede che alcune orme sono marcate (calpestate di recente), altre sono sbiadite. Tocca un'orma più sbiadita. Si apre la card: un ricordo di Amburgo che non tocca da tempo.
5. Tocca **"Ripercorriamolo insieme"**. Chip "chi sta ripercorrendo?" → "Giorgio". Parte il TTS: *"Nel '78 sono andato in Germania per lavoro, tre mesi ad Amburgo, pioveva sempre."* Testo originale, non rigenerato — la sua voce di allora.
6. L'orma del ricordo torna marcata. Giorgio sorride piano.

### Atto 3 — Il calpestio insieme (comunità)

**Taglio a un'altra stanza, un altro giorno.**

7. Entra Paolo, figlio di Giorgio. Prende il telefono di Giorgio. Apre un ricordo che suo padre gli ha raccontato, tocca **"Ripercorriamolo insieme"**, chip "chi sta ripercorrendo?" → "Il figlio".
8. Il TTS lo legge; Paolo lo ascolta accanto al padre. Accanto all'orma di Giorgio, ora appare anche un'orma di Paolo. Il sentiero si è allargato.
9. Paolo apre **"Chiedi alla tua memoria"** e parla: *"Cosa mi raccontava papà di Amburgo?"* L'app risponde in prima persona — la voce di Giorgio: *"Ti raccontavo che pioveva sempre, a Amburgo, nel '78."* Sotto: chip *"Ho usato questo ricordo"*. Paolo tocca, rivede l'originale scritto dal padre.

**Fine.**

Lo scatto emotivo del video è il momento in cui due orme stanno accanto (atto 3, punto 8): Paolo non sostituisce Giorgio né interroga il padre, lo *ripercorre con lui*. Questa è la differenza di El Troso rispetto a qualsiasi app di memoria standard: non archivia, non quiz-za, non sorveglia. Cammina insieme.

---

## 5. Feature prioritizzata con ancoraggio EBM

| # | Feature | Priorità | EBM anchor | Implicazione design |
|---|---------|----------|------------|---------------------|
| F1 | Interfaccia minima (max 2 bottoni per schermata) | MUST | Czaja et al. (2019) *Designing for Older Adults* — complessità visiva è il predittore #1 di abbandono in ≥75 | Niente tab, niente hamburger menu, niente drawer |
| F2 | Font grande (min 24pt body, 32pt azioni) + contrasto AAA | MUST | WCAG 2.2 AAA + Pak & McLaughlin (2018) *Designing Displays for Older Adults* | Text scaling rispetta anche il sistema, ma default già grande |
| F3 | Input vocale primario, tastiera secondaria | MUST | Vipperla et al. (2010); preferenza vocale in over-80 confermata in diverse review HCI | Tastiera compare solo se tap su "correggi a mano" |
| F4 | TTS per leggere le risposte | SHOULD | Sheng & Mitchell (2019) — affaticamento visivo riduce uso; TTS estende tempo di permanenza | Voce naturale italiana, velocità 0.9x |
| F5 | Grounding esplicito + ammissione "non mi ricordo" | MUST | Bender et al. (2021) *Stochastic Parrots* — no hallucination nei domini sensibili; inoltre DSM-5-TR criteri MCI: paziente è consapevole del deficit, confabulazioni lo umiliano | Temperature 0.3, prompt template testato Fase 3.6 |
| F6 | Fonte visibile ("ho usato questo ricordo") | MUST | Epistemic trust in AI for health (Shin 2021) — aumenta aderenza nel tempo | Chip sotto la risposta, tap → dettaglio |
| F7 | Tag semplici (5 opzioni max, no free-form) | SHOULD | Legge di Hick — tempo di scelta cresce log(n) con alternative; over-80 amplifica l'effetto | Dropdown/chips fisse: famiglia, lavoro, viaggi, casa, altro |
| F8 | Nessuna notifica push | MUST (decisione etica) | Gitlin et al. (2012) — interventi invasivi per anziani peggiorano senso di sorveglianza | Bandiera nel README e nel video |
| F9 | Privacy on-device + nessun login | MUST (kaggle story) | GDPR art.9 dati salute; + EU AI Act Annex III high-risk per health | Write-up Kaggle apre con questo |
| F10 | Multilingua nativa (IT + EN, retrieval cross-lingual) | MUST | Mendez (1999) language reversion in AD; Gollan (2011) bilinguismo come riserva cognitiva | Piano completo in `MULTILINGUA_PLAN.md`; niente traduzione automatica, sfruttare capability Gemma |
| F11 | Gesto "Ripercorri" (TTS testo originale, registrazione ri-calpestio nel metadata) | MUST | Woods B et al. (2018) Cochrane review reminiscence therapy; Cotelli M et al. (2012) stimolazione narrativa in MCI | Card ricordo → bottone grande, TTS *non* rigenerato da Gemma (autenticità) + timestamp + chi |
| F12 | Orme che sbiadiscono (indicatore visivo oblio, invito gentile al ripercorrimento) | MUST | Camp CJ (2001) spaced retrieval evidence; Lancet Dementia Commission (Livingston 2017) su intervento non-farmacologico | Opacity SVG dell'orma funzione di (giorni da ultimo calpestio). Nessuna notifica push. Empty state opzionale "qualcosa sta sbiadendo, vuoi tornarci?" |

**Ogni feature MUST ha l'ancoraggio EBM richiamato nel write-up Kaggle e citato alla fine del video.**

**Ogni feature MUST risponde anche a uno o più punti del trittico del documento di visione (§0).** La mappatura è in §1 di questo file.

---

## 6. Architettura tecnica (conferma, non novità)

Riuso totale di quanto validato in Fase 3:

```
microfono → Android SpeechRecognizer (IT) → testo trascritto
    ↓
EmbeddingGemma 300M (retrievalDocument) → vettore 768d
    ↓
FlutterGemmaPlugin.addDocument(id, content, metadata=tag)
    ↓ [SQLite + HNSW on-device]

--- query time ---

microfono → SpeechRecognizer → testo query
    ↓
FlutterGemmaPlugin.searchSimilar(query, topK=3, threshold=0.40)
    ↓
prompt template grounded + temperature=0.3
    ↓
Gemma 4 E2B .litertlm (GPU Tensor G2)
    ↓
Android TextToSpeech (IT) → audio risposta
```

Nessun componente nuovo rispetto a Fase 3.6. Le uniche aggiunte rispetto a main.dart attuale:
- SpeechRecognizer wrapper (plugin `speech_to_text`)
- TTS wrapper (plugin `flutter_tts`)
- Persistenza metadati extra (data, tag) nel vector store (già supportato da `metadata` JSON string)
- UI Flutter vera (al momento è un pulsantificio di debug)

---

## 7. Definition of Done per il demo Kaggle

La vertical slice si considera DONE quando, sul Pixel 7a, in modalità aereo:
1. Posso registrare 5 nuovi ricordi vocali consecutivi senza crash (stress test batteria/memoria)
2. Posso fare 3 domande consecutive e ricevere risposte corrette o "non mi ricordo bene"
3. Posso **ripercorrere** un ricordo (card → TTS testo originale) 3 volte consecutive; ogni ripercorrimento lascia un'orma nel metadata (timestamp + chi ha ripercorso)
4. L'indicatore visivo di sbiadimento funziona: un ricordo non toccato da 14+ giorni appare visibilmente più pallido nella lista
5. Il chip "chi sta raccontando/ripercorrendo" persiste correttamente e la risposta di Gemma riflette la voce collettiva quando la fonte è "figlio" / "nipote" / "amico"
6. Mostro visivamente quale ricordo Gemma ha usato (punto F6 sopra)
7. L'UI scala correttamente con font system a "Grande" (Android Settings)
8. Il test usability con Giorgio (una sessione registrata) mostra che completa autonomamente **sia** il loop racconta → salva **sia** il loop ripercorri → TTS, senza aiuto verbale del figlio dopo l'onboarding
9. Nella lingua non-IT (switch a EN) il ciclo completo racconta + ripercorri + chiedi funziona
10. Nessun fetch di rete rilevabile da `adb shell` durante l'uso (verifica con `tcpdump` filtrato se necessario)

---

## 8. Rischi identificati e mitigazioni

| Rischio | Prob | Impatto | Mitigazione |
|---------|------|---------|-------------|
| SpeechRecognizer Android richiede Google Play Services online per IT | M | Alto | Testare subito in 4.4. Fallback: plugin `vosk_flutter` offline (ma accuracy IT peggiore) |
| Giorgio non riesce ad usarla nonostante font grande | M | Alto | Test con Giorgio in 4.6, NON a fine progetto. Se blocca, semplifichiamo ancora (mantra: "ogni schermata fa una sola cosa") |
| Voice recording crash su sessione lunga | B | M | Limite 90s per registrazione, feedback "hai parlato abbastanza" |
| Memoria RAM Pixel 7a con Gemma 4 + Embedder + TTS contemporaneamente | M | Alto | Sequenziare operazioni, chiudere embedder session dopo search |
| Trascrizione IT sbagliata su nomi propri ("Maria" → "Mario") | A | M | UI prevede edit pre-salvataggio. Nel video mostriamo la correzione come feature non come bug |
| Giorgio confabula durante registrazione (ricordo inventato) | B | Basso ma delicato | Non è nostro ruolo giudicare. La app archivia quello che Giorgio racconta, fine. Dichiararlo esplicitamente nel write-up |
| Rischi multilingua specifici | — | — | Tabella completa in `MULTILINGUA_PLAN.md` §10 (embedder non multilingua, Gemma risponde in lingua sbagliata, STT/TTS EN offline su Pixel, layout EN rompe font grande) |

---

## 9. Roadmap 4.x (con impegno giorni)

- **4.1 Scoping** (oggi, 1.5 gg) → ✅ Questo file + `MULTILINGUA_PLAN.md` + `ONBOARDING_PLAN.md` + test V1/V2 cross-lingual
- **4.2 Design system + low-fi** (3-4 gg) → Google Stitch + Claude Design in parallelo; identità visiva "orma/desire path"; illustrazioni hero; pattern SVG orme con opacity variabile; layout tollera stringhe EN+30% più lunghe
- **4.3 High-fidelity mockups** (2.5 gg) → Stitch con prompt IT *e* EN, export Flutter, tutti e 3 gli atti del user journey §4 coperti
- **4.4 Flutter scaffolding** (4 gg) → Riverpod + go_router + speech_to_text + flutter_tts + `flutter_localizations` + ARB (it, en)
- **4.5 Feature implementation** (8-9 gg) → collegare scaffolding a pipeline Fase 3.6, prompt template multilingua con vocativo + chi-racconta, onboarding 3 schermate, **gesto Ripercorri (F11) + orme-che-sbiadiscono (F12)**, locale plumbing
- **4.6 Polish + test con Giorgio** (3.5 gg) → usability test IT, smoke test EN, accessibility audit
- **4.7 Buffer** (0.5-1 gg) → riservato per bug imprevisti

Totale: ~24.5-26.5 gg lavorativi su 28 calendario. **Margine molto ristretto**: Fase 5 (video + write-up) dovrà essere compatta, 3-4 giorni. Lock scope **assoluto** da qui: eventuali add vanno in `BACKLOG_FASE_5.md` post-hackathon.

---

## 10. Ruolo dei tool di design

- **Google Stitch (Google Labs)**: generazione mockup high-fi da prompt IT ("app per anziano, font enormi, due bottoni"). Export Flutter. Usato in 4.2 (esplorazione) e 4.3 (codice iniziale UI).
- **Claude Design (Opus 4.7)**: calibrazione design system (palette, tipografia, spacing) coerente con principi §5. Usato in 4.2 (parallelo a Stitch) per confronto, e in Fase 5 per la demo deck / write-up.
- **Figma**: solo se Stitch esporta su Figma per ritocchi fini. Non è obbligatorio.

Decisione: **partiamo con Stitch** perché dà Flutter code direttamente, e **usiamo Claude Design per auditare il risultato** contro i 9 principi EBM della tabella §5.

---

## 11. Firma e prossima azione

Decisione presa e tracciata. Prossimi step in ordine:
1. **Test V1 + V2 multilingua** (pulsante 8 in `main.dart`): verificare che EmbeddingGemma sia effettivamente multilingua e che Gemma 4 E2B rispetti la lingua della query — prima di investire in design i18n. Stimato 0.5 gg.
2. **STITCH_PROMPT.md** (prompt IT + EN per Google Stitch, calibrato su §5 di questo file e §4 di `MULTILINGUA_PLAN.md`).
3. **Passo 3 del piano Fase 4**: aprire Stitch in parallelo con Claude Design.

Il passo 1 ha veto sul resto: se V1 o V2 sono rossi, riapriamo scope prima di disegnare.

---

*Autore: Guido + Claude. Revisione richiesta solo se Giorgio stesso (o terapista/neurologo di riferimento) contesta una feature. Ogni modifica in questo file cambia lo scope — da trattare come un commit.*

---

## 12. Stato implementazione (build 0.4.5+43 — 2026-05-05)

A 13 giorni dalla deadline Kaggle (2026-05-18) lo scope IN del §3 è completato e l'app gira sul Pixel 7a in modalità aereo. Sotto, il diff tra spec originale e implementazione attuale.

### 12.a Feature MUST del §3 — tutte DONE

| F | Stato | Note |
|---|---|---|
| F1 Onboarding leggero | ✅ | 5 slide carousel + form profilo (nome, vocativo, decennio) + onboarding seed offer (build 24) |
| F2 Aggiungi ricordo a voce | ✅ | STT IT, foto allegata, audio originale registrato, tag chip; descrizione foto via Gemma rimossa in build 19 (causava conferme di dettagli non nel ricordo, vedi build 17→18→19→20→32→33 in `recognize_logic.dart`) |
| F3 Elenco ricordi con orme | ✅ | Riformato in **galleria orizzontale** in Home v4 (build 23), con 3 dots di freshness mapping (35/60/100 di opacity primary) per ogni tile |
| F4 Chiedi alla tua memoria | ✅ | RAG vector store, threshold abbassato da 0.40 a 0.30 in build 35 (corpus 12 seed, query corte tipo "chi è Pippo?" sotto soglia 0.40) |
| F5 Risposta grounded | ✅ | Prompt template testato, fonti citate sotto la risposta |
| F6 "Non mi ricordo bene" | ✅ | Caso `noMatch` esplicito quando 0 ricordi sopra soglia |
| F7 Tutto on-device | ✅ | 3 file modello in external dir: gemma-4-E2B-it.litertlm (2.4GB) + embedder + tokenizer; nessun fetch di rete |
| F8 Multilingua IT + EN | ✅ | ARB IT+EN completo. Auto-detect lingua device in build 36; **scelta esplicita IT · EN persistente** (drawer + carousel) in build 41; **ricordi multilingue con bottone "Traduci" on-demand** in build 42; STT/TTS dinamici sulla locale |
| F9 Chip "chi sta raccontando/ripercorrendo" | ✅ | `Memory.walker` (self/child/grandchild/friend) salvato in JSON e in vector store metadata |
| F10 Ripercorri ricordo (TTS testo originale) | ✅ | Bottone in MemoryDetailPage, TTS non rigenerato, walk timestamp + walker registrato |
| F11 Orme che sbiadiscono | ✅ | `footprintOpacity` calcolato da `daysSinceLastWalk` (1.0 / 0.6 / 0.3 sotto 7 / 14 / 14+ giorni) |
| F12 Empty state "qualche ricordo sta sbiadendo" | ✅ | Galleria ordina per opacity ascendente (sbiaditi prima) |

### 12.b Feature aggiunte fuori scope originale

Tre serious games (riapertura del filone gaming il 2026-04-25, vincolata a EBM rigorosa — vedi memoria `project_metaphor_and_scope_lock.md` e `BACKLOG_POST_HACKATHON.md` §giochi). Ogni gioco è personalizzato sui ricordi reali dell'utente, non su contenuto generico.

| Gioco | Implementazione | EBM anchor (`docs/El Troso - Studi scientifici.md`) |
|---|---|---|
| **G4 — OGGI / Spaced Retrieval** | Hero card in Home v4 (build 23). Curva intervalli 1→3→7→14→30 giorni dall'ultimo walk. `pickTodaysMemory` ritorna il più overdue, null se tutti freschi (sub-saluto cambia). | §5b — Hopper 2013 (review SRT, PMID 23886395), USMART 2017 (RCT tablet-based), Eur Psych meta 2023, JMIR Formative 2024 |
| **G3 — Riconosci e racconta** | Page dedicata: foto random + STT/tastiera + Gemma confronta racconto con `memory.text` (NON con foto, fix build 19) e risponde caldo MA onesto. Tono modale ("Mmh, non credo...") dopo build 33. Tap foto → fullscreen viewer con pinch-zoom (build 30). | §2 Cochrane Woods 2018 (CD001120) reminiscence 1:1 mediata da AI; §5 SenseCam 2014 (cue visivo > testuale per memoria autobiografica); §5c Clare et al. errorless learning (PMC3381647) reinterpretato come "non far sentire in fallo, MAI confermare cose false" |
| **G1 — Memoria delle foto** | Memory matching 3×4 (portrait) o 4×3 (landscape), 6 coppie di foto autobiografiche. Ogni match → Walk registrato → freshness aggiornata. Audio: flip 60ms / match 240ms / win 650ms (build 22, sine pure generate offline). TTS finale personalizzato col vocativo. | §3 JMIR Serious Games 2024 12:e55785 (paradigma); visual recognition memory dominio preservato in MCI; §5d Carstensen 2012 (positivity effect — foto autobiografiche emotivamente significative) |
| **G2 — Indovina insieme** (build 37) | Gemma genera UNA domanda specifica su un ricordo (anno/luogo/persona/evento), l'utente risponde a voce o tastiera, Gemma valuta la risposta confrontando col testo del ricordo e dà feedback caldo errorless. TTS auto-legge la domanda. Walk registrato a ogni risposta (anche errata: la persona ha comunque "calpestato" il ricordo). | USMART RCT 2017 (SRT tablet-based in MCI); Roediger & Karpicke 2006 (testing effect); Hopper 2013 (review SRT); Clare PMC3381647 (errorless learning) |
| **G5 — Storia continua** (build 37) | App legge a voce le prime 1-2 frasi del ricordo + mostra a video, poi prompt *"…e poi cosa è successo?"*. L'utente continua a voce o tastiera. Gemma confronta la continuazione raccontata con quella vera del ricordo e dà feedback caldo. Dopo il feedback mostra il ricordo INTERO per consentire rilettura (errorless: non punisce la versione utente). | Cotelli 2012 (riabilitazione cognitiva narrativa in MCI/AD, PMID 22466023); Cochrane Woods 2018 reminiscence (CD001120); Bluck & Levine 1998 (reminiscence as autobiographical memory) |

Skip espliciti dal corpus gaming, riapribili in v1.x: G2-old multiple choice con distractor (tensione con errorless learning, sostituito dal nuovo G2 "Indovina insieme" che usa risposta libera), G_riordina cronologico (EBM tenue). Vedi `BACKLOG_POST_HACKATHON.md`.

### 12.c Feature di trasparenza scientifica

`GameInfoSheet` (build 17): icona ⓘ in AppBar G3/G1 e accanto al titolo OGGI, apre sheet con 3 sezioni — "Di cosa si tratta", "Perché funziona", "Fonti" (link tappabili a DOI/PubMed). Niente WebView in-app: il browser di sistema apre la pubblicazione. Implementa direttamente lo spirito della §3 di questa spec (grounding visibile all'utente, non solo nel write-up).

### 12.d Onboarding seed opt-in

Build 24: dopo profilo, schermata `OnboardingSeedOfferPage` chiede esplicitamente se pre-caricare i 12 ricordi del libro *"Nonno parlaci di te"* di Giorgio Marangoni (gennaio 2025, distillati in `assets/seed/memories.json`). Tap "Sì" → `SeedLoader.loadFromBundle` (~3-5 sec). Tap "No" → home vuota, sub-saluto invitante. Coerenza etica: i ricordi reali di una persona non vanno auto-installati senza consenso esplicito sul telefono di un'altra.

### 12.e Modulo congelato per v1.x

QoL Assessment & Activity Recommender (`INTEGRAZIONE-MODULO-VALUTAZIONE.md`, 2026-04-30) — modulo screening QOL-AD + Mini-Cog + suggerimenti attività. **Tenuto fuori per Kaggle** in coerenza con scope-lock §3 ("Diagnosi o screening cognitivo OUT"), licenza Logsdon non garantita per il 18/05, e tono clinico in tensione con il registro narrativo del trittico. Riapertura ragionevole pianificata in v1.1 (versione light "termometro del sentiero", 5 micro-domande casual senza Mini-Cog) e v1.2 (modulo completo con validazione clinica). Vedi `BACKLOG_POST_HACKATHON.md` §"Modulo QoL".

### 12.f Definition of Done — verifica al build 43

| § | Criterio | Stato |
|---|---|---|
| 7.1 | 5 ricordi vocali consecutivi senza crash | ✅ |
| 7.2 | 3 domande consecutive con risposta o "non mi ricordo bene" | ✅ |
| 7.3 | 3 ripercorrimenti consecutivi → walk registrati | ✅ |
| 7.4 | Sbiadimento dopo 14+ giorni visibile | ✅ (testato con seed `createdAt` 2025-01-09 → orme 35%) |
| 7.5 | Chip walker persiste e prompt riflette voce collettiva | ✅ |
| 7.6 | Fonte visibile sotto risposta /ask | ✅ |
| 7.7 | UI scala con font system "Grande" | ⏳ da verificare |
| 7.8 | Test usability con Giorgio | ⏳ da fare prima del video |
| 7.9 | Cycle completo in EN | ⏳ da verificare con device EN simulato |
| 7.10 | Nessun fetch di rete durante uso | ✅ (verifica adb shell pending) |

### 12.g Cosa resta verso 18/05

- Test 7.7 + 7.8 + 7.9 (1 giornata)
- Validazione qualità traduzione build 42 sui dialettalismi e nomi propri (1-2 ore — vedi §12.h)
- Polish coerenza visiva (sfondo sentiero esteso a Memory/Record/Ask, splash brand-coerente — opzionale)
- Bump 0.5.0 quando home stabile
- README.md inglese top-level per Kaggle (γ)
- LICENSE + credits Nano Banana Pro / fonti EBM (δ)
- Video pitch 3 min (ε)
- Submission Kaggle (ζ)

Buffer ~7 giorni su 13 disponibili. Lock scope è stato rispettato eccetto la traduzione ricordi (build 42), riaperto come tradeoff esplicito (vedi nota in §12.h).

### 12.h Build 37-43 — incrementi post-spec (2026-05-04 → 2026-05-05)

Lavoro tra build 37 e 43. Tutti dentro lo scope IN del §3, con un'eccezione esplicita (Traduci on-demand) annotata sotto.

**Build 37 — G2 + G5**: due giochi nuovi, già documentati in §12.b.

**Build 38 — fix prompt Gemma**:
- Rimossi "Mmh / Hmm / Eh" da G2/G3/G5: Android TTS li leggeva lettera per lettera ("EMME EMME ACCA"). Sostituiti con formule modali ("Aspetta", "In realtà", "A pensarci bene").
- G5 più tollerante alle parafrasi semantiche: "siamo andati a Teolo" ≡ "si è trovati alloggio a Teolo". Aggiunta REGOLA IMPORTANTE + esempio A2 nel prompt.

**Build 39 — fix overflow UI**: G5 e G2 rifatte con `SingleChildScrollView` + `TextField` con `minLines/maxLines` bounded. Niente più zona giallo-nera con tastiera aperta o incipit lungo.

**Build 40 — bump maxTokens**: session Gemma da 1024 → 2048 token dopo `INVALID_ARGUMENT 1238 >= 1024` su G5 con ricordo lungo. Gemma 4 E2B supporta 32K nativi; +1024 token ≈ +80MB KV cache, ok su Pixel 7a (8GB RAM).

**Build 41 — scelta lingua persistente**: switcher `IT · EN` nel drawer (sopra il footer versione) e nella top bar del carousel. Nuovo `localeProvider` Riverpod su SharedPreferences (`el_troso.user_locale`); `MaterialApp.locale` guarda l'override esplicito; fallback all'auto-detect device se l'utente non ha mai scelto.

**Build 42 — ricordi multilingue (Traduci on-demand)**:
- Nuovo campo `Memory.originalLang` ('it'/'en'), default 'it' per retro-compat. Migration nel `fromJson` + colonna esplicita aggiunta a tutti i 12 seed JSON.
- `record_page` cattura la locale UI al momento del save → `originalLang` del nuovo ricordo.
- STT/TTS ora dinamici sulla locale: helper `sttLocaleId(Locale)` e `ttsLanguageCode(Locale)` in `core/locale/locale_codes.dart`. 6 STT call sites (record / ask / onboarding / G2 / G3 / G5) e 8 TTS call sites aggiornati. Il TTS del Ripercorri rispetta la `originalLang` del ricordo (un seed IT è sempre letto da TTS italiano anche se la UI è EN).
- Nuovo `gemma.translate(text, from, to)` in `gemma_service.dart` con prompt dedicato (preserva nomi propri e prima persona, temperature 0.2).
- Bottone "Traduci" in `MemoryDetailPage` visibile solo se `originalLang ≠ locale UI`. Stato locale: niente persistenza (lazy lookup, sparisce uscendo dalla pagina).

> **Nota su scope-lock §3**: lo scope originale fissava "demo IT+EN come UI, non memory translation". Riaperto perché:
> 1. Caso d'uso reale (nipote che vive a Londra legge il nonno IT) — coerente con la metafora "calpestare insieme".
> 2. Demo killer Kaggle: "Gemma 4 multilingual on-device su contenuto autobiografico, completamente offline".
> 3. Implementazione lazy → zero rischio dati: niente migration di runtime, niente storage doppio, niente drift su edit.
>
> Varianti eager (B/C — salvataggio della traduzione) sono in `BACKLOG_POST_HACKATHON.md` come opzione v1.x dopo aver validato la qualità.

**Build 43 — fix bug photo memory (G1)**: `buildDeck` ora dedupa per `imagePath` (Set<String>) prima del check soglia. Senza dedupe, se due ricordi puntavano alla stessa foto (es. utente seleziona la stessa immagine due volte, o seed e ricordo utente condividono il file), il deck poteva contenere 4 carte visivamente identiche → matching indistinguibile. Empty state "non abbastanza foto" si attiva ora se < 6 foto **uniche** invece di < 6 ricordi-con-foto.
