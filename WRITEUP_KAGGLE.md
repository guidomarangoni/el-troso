# El Troso — Kaggle Gemma 4 Hackathon submission writeup

> **Watch the 3-minute pitch first** — `[video link to be filled in]`
>
> Repository: `[GitHub link to be filled in]`
> Build used for the demo: `0.4.5+43` (2026-05-05)
> Target: Pixel 7a, Android 14, fully on-device

---

## One line

**El Troso** is a private, on-device companion for elderly people with
mild cognitive decline, built on **Gemma 4 E2B** and grounded in five
games that map one-to-one to published reminiscence-therapy research.

It's named after the Veneto-dialect word for **path**: *a path is born
when you walk it; it fades when no one walks it any more.*

---

## The 30-second problem

- **55 million** people worldwide live with cognitive decline today
  ([WHO, 2023](https://www.who.int/news-room/fact-sheets/detail/dementia)).
- **+10 million** new cases every year.
- By 2050, **139 million**.
- Evidence-based interventions exist — reminiscence therapy, spaced
  retrieval, retrieval practice — but most live inside clinical
  settings and trained facilitators.
- For most families, a hand to hold costs more than the phone already
  in their pocket.

We asked: *what if a 2.4 GB model running on a €350 phone could be a
gentle, evidence-based facilitator at home — without ever sending a
single memory to the cloud?*

---

## What El Troso is

A Flutter app for Android. The user is an elderly person, optionally
with a family caregiver. They record memories with their own voice
(text + audio + optional photo). The app turns those raw memories into:

1. **A personal corpus** — a small, intimate gallery of their life.
2. **A spaced-retrieval surface** — the Home v4 "Today" card surfaces
   one memory per day on a curve (1 → 3 → 7 → 14 → 30 days), validated
   by the [USMART RCT 2017](https://alzres.biomedcentral.com/articles/10.1186/s13195-017-0289-z)
   — the first randomised trial of spaced retrieval training on a tablet.
3. **Five evidence-anchored games**, each plugging into the same corpus.
4. **A bilingual experience** — Italian original, English translation on
   demand, both produced on-device by Gemma 4.

The seed corpus for our demo is **Giorgio Marangoni's actual memoir**:
12 memories written in January 2026 in his 86-year-old hand, in the
book "Nonno parlaci di te". Real photographs from the family archive,
real text, validated by him.

---

## How we use Gemma 4

This is a Kaggle Gemma 4 hackathon. Gemma is not a feature — it's the
scaffolding. Here are the seven distinct uses of Gemma 4 in El Troso:

### 1 — Memory enrichment (text in, structured fields out)
After raw transcription (Android system STT), Gemma 4 takes the free
text and produces: a suggested title, a 1-2 sentence summary, tags
(family / work / travel / home / other), an era hint, and a mood.
Temperature 0.4, max tokens 1024.

### 2 — G3 Recognize and Tell feedback
Cochrane reminiscence therapy 1:1 protocol implemented as a game. Given
a photo + the user's spoken description, Gemma evaluates and produces
a warm, scaffolding response: *"Yes, that's the day of your fifth
elementary class. You mentioned the boy with the cap — that was
Pippo, your best friend."* Never punitive, always errorless-learning
compliant ([Clare PMC3381647](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3381647/)).

### 3 — G4 Today's spaced retrieval prompt
Gemma generates the natural-language phrasing of the daily prompt
that the Hero card surfaces: *"Today let's walk through that summer
in Caorle again. Tell me what the sea looked like that morning."*
Temperature 0.6 for warmth.

### 4 — G5 Continuing Story paraphrase
For longer memories, Gemma paraphrases on each replay so the user
hears the same story slightly differently — sustained engagement
without rote repetition. Inspired by retrieval-practice variance
([Roediger & Karpicke 2006](https://doi.org/10.1111/j.1467-9280.2006.01693.x)).

### 5 — IT ↔ EN translation on-demand
Native multilingual Gemma 4 handles translation. Temperature 0.2.
Prompt engineered to **preserve proper names** (Pippo, Calvi, Mazzi,
Teolo) verbatim — the most common failure mode of generic translators
on intimate first-person text. Result: the grandson in London hears
"my friend Pippo" not "my friend Goofy".

### 6 — EmbeddingGemma 300M for memory similarity
Semantic embeddings power G1 Photo Memory variety (avoid serving the
same pair twice in a session) and OGGI card selection (don't pick the
memory we just visited yesterday).

### 7 — Multimodal vision (photo description fallback)
When a memory has a photo but no spoken text (rare but supported),
Gemma 4's vision modality generates a one-line caption to scaffold
the first game session. Used sparingly to preserve compute budget.

**Why E2B and not larger?** Gemma 4 E2B (2.4 GB on disk, runs on Pixel
7a GPU via LiteRT-LM) is the sweet spot: large enough for tone and
warmth in Italian, small enough that a 4-year-old Android phone is
all you need. Bigger models would lock the project to flagship
hardware — incompatible with the demographic we want to reach.

---

## The five games — each anchored to a published study

| # | Game | What it does | Evidence anchor |
|---|------|--------------|-----------------|
| **G1** | **Photo Memory** | Concentration with pairs of the user's own photos | [JMIR Serious Games 2024](https://pubmed.ncbi.nlm.nih.gov/39083796/) — serious games in MCI |
| **G2** | **Guess Together** | (deferred to v1.x — see Limitations) | [Roediger & Karpicke 2006](https://doi.org/10.1111/j.1467-9280.2006.01693.x) + [USMART 2017](https://alzres.biomedcentral.com/articles/10.1186/s13195-017-0289-z) |
| **G3** | **Recognize and Tell** | Reminiscence 1:1 with Gemma as facilitator | [Cochrane CD001120 Woods 2018](https://www.cochranelibrary.com/cdsr/doi/10.1002/14651858.CD001120.pub3/full) — 22 RCTs, n > 1,800 |
| **G4** | **Today / Spaced Retrieval** | Daily prompt on adaptive retrieval curve | [Hopper 2013 PMID 23886395](https://pubmed.ncbi.nlm.nih.gov/23886395/) + [USMART 2017](https://alzres.biomedcentral.com/articles/10.1186/s13195-017-0289-z) |
| **G5** | **Continuing Story** | Long memory re-told in paraphrase | [Cotelli 2012 PMID 22466023](https://pubmed.ncbi.nlm.nih.gov/22466023/) + [Bluck & Levine 1998](https://doi.org/10.1080/096582198388517) |

We didn't invent these games. We translated established
evidence-based protocols into a phone app, with Gemma 4 playing the
role that a trained clinician or family member would normally play
in a research study.

---

## Privacy: a hard line, not a feature

- **100% on-device inference**. The Gemma 4 weights, the embedding
  model, the SpeechRecognizer, the TTS, every game, every prompt — all
  on the phone.
- **Zero network calls** during normal operation. We verified this with
  airplane mode: the app is fully functional with Wi-Fi off and SIM
  removed. The demo video is shot in airplane mode.
- **No telemetry**. No analytics SDK. No crash reporting service.
- **No cloud backup**. Memories live in the phone's Documents
  directory, plain JSON + WAV + JPEG. Export/import is on the backlog
  but not in the MVP.
- This is **the right default for a person with cognitive decline**.
  They cannot meaningfully consent to data sharing they don't
  understand. So we don't ask.

---

## What we knew we couldn't ship

Being honest about limits is part of the pitch.

### iOS support
**Not in the MVP**. Two real reasons, not excuses:
1. Google's **LiteRT-LM Swift API for `.litertlm` is currently
   text-only**. The multimodal pipeline (image + audio in) we use on
   Android is not yet exposed on iOS. Tracked upstream.
2. **iOS model distribution for 2.4 GB files** is unsettled. App Store
   max IPA size and on-demand resources don't fit this model size
   pattern cleanly. We need a clear story before we ship — not a hack.

Re-evaluation: Q3 2026 / Q1 2027 when LiteRT-LM iOS catches up. Flutter
investment means the port is real, not a rewrite.

### Translation quality on Veneto dialect
On-demand IT↔EN translation works well on standard Italian. On
heavy Veneto regional expressions ("el troso", "vecio", "ostia") it's
best-effort. We mark this honestly in the UI ("show original always
available") rather than pretend.

### The G2 distractor problem
G2 multiple-choice with Gemma-generated distractors tested poorly: a
plausible distractor can be remembered AS the correct answer in MCI
([Clare PMC3381647](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3381647/)).
We deferred G2 to v1.x with an errorless-learning redesign instead of
shipping something that could harm a user.

### QoL assessment / activity recommender
Designed in [INTEGRAZIONE-MODULO-VALUTAZIONE.md] but deferred. Clinical
language ("compromised", "borderline") breaks the metaphor. AI Act
Article 6 classification implications are non-trivial. Right thing to
defer.

---

## Architecture in one paragraph

**Flutter 3.x + Riverpod + go_router** for the app shell. **flutter_gemma
0.13.5** wrapping **LiteRT-LM** for Gemma 4 E2B inference (GPU backend
on Pixel 7a). **EmbeddingGemma 300M** for semantic search.
**SpeechRecognizer** (Android system) for STT in IT and EN.
**flutter_tts** for response playback. Models pushed once to
`/storage/emulated/0/Android/data/.../models/` via `adb push` (2.4 GB +
171 MB + 4.4 MB sentencepiece). App size itself: 28 MB APK. Persistence:
plain JSON in app Documents. No database, no ORM. No backend, no
servers. No accounts.

---

## What we built in 3 weeks

- **43 builds**, 12 of which were narrative pivots after testing with
  Giorgio in person.
- **2,300 lines of Dart**, 700 lines of ARB l10n (IT+EN).
- **5 games** wired end-to-end to the corpus.
- **12 seed memories** from real life, photos digitised from the family
  archive.
- **2 languages** fully supported with on-device translation.
- **0 cloud calls** in the entire stack.

---

## Try it

```bash
# Clone
git clone https://github.com/[org]/el-troso
cd el-troso

# Get the models (one-time, 2.6 GB total)
# Place the following in your downloads directory:
#   - gemma-4-e2b.litertlm  (2.4 GB)
#   - embeddinggemma-300m.litertlm  (171 MB)
#   - sentencepiece.model  (4.4 MB)

# Push to device (Pixel 7a or similar Android with GPU)
adb push gemma-4-e2b.litertlm /storage/emulated/0/Android/data/com.guidomarangoni.eltroso/files/models/
adb push embeddinggemma-300m.litertlm /storage/emulated/0/Android/data/com.guidomarangoni.eltroso/files/models/
adb push sentencepiece.model /storage/emulated/0/Android/data/com.guidomarangoni.eltroso/files/models/

# Build
cd el_troso
flutter pub get
flutter run --release
```

First launch will create an empty corpus. Open Playground from the
debug drawer → "Load seed memories" to populate the demo dataset.

---

## Team

**Guido Marangoni** (`@guidomarangoni`) — design + Flutter + Gemma
integration + memoir digitisation. Software engineer, two-time Gemma
hackathon winner. Italian. Father of two. Son of Giorgio.

**Giorgio Marangoni** (86) — the heart of the project and the source
of the seed corpus. Wrote 12 memories by hand in January 2026 in the
journal "Nonno parlaci di te". Reviewed and validated every photo and
text caption in the demo.

---

## Acknowledgements

The five EBM anchors above are not citations of convenience — they
shaped concrete product decisions, from the SRT retrieval curve to
the errorless-learning constraint that killed G2. We owe the
researchers behind those papers.

The Google Gemma team for shipping a 2.4 GB model that runs on a
mid-range phone GPU. The flutter_gemma maintainers for the binding.
The LiteRT-LM team for the runtime that makes this possible.

And most of all: thanks to Giorgio, who at 86 sat down with his son
and wrote 12 memories — and then let him turn them into an app.

---

## Links

- 📹 Pitch video (3 min): `[link]`
- 🐙 Repository: `[link]`
- 📄 Long-form README: [`README.md`](README.md)
- 📜 License: Apache 2.0 ([`LICENSE`](LICENSE))
- 🙏 Credits: [`CREDITS.md`](CREDITS.md)

---

*Submitted to Kaggle Gemma 4 Hackathon — 2026-05-18.*
*Built in Padova, Italy. With love and dialect.*
