# Credits

El Troso is a small project that stands on a lot of shoulders.
This file is the long version of "thank you".

---

## The heart of the project

### Giorgio Marangoni (86)

Without Giorgio, there is no El Troso. He wrote 12 memories by hand
in the journal *"Nonno parlaci di te"* in January 2026 — that is the
seed corpus of every demo, every game, every screenshot. He let his
son turn his life into an app, validated every photograph, listened
patiently to early prototypes, and gave the project its dialect
name: *el troso*, the path.

This is his app first. We are guests.

---

## The AI foundation

### Google Gemma team
- **Gemma 4 E2B** (`.litertlm`, ~2.4 GB) — the multimodal foundation
  model that runs every game, every prompt, every translation in this
  app. On a Pixel 7a. With no cloud. The fact that this is possible at
  all is the entire premise of the project.
- **EmbeddingGemma 300M** (~171 MB) — semantic embeddings powering
  memory similarity and game variety.
- Project page: <https://ai.google.dev/gemma>

### LiteRT-LM team
- The on-device inference runtime that makes Gemma 4 fit on a phone
  GPU. Documentation: <https://ai.google.dev/edge/litert>

### flutter_gemma maintainers
- The Flutter binding to LiteRT-LM that this app uses
  (`flutter_gemma ^0.13.5`). Source:
  <https://pub.dev/packages/flutter_gemma>

---

## Evidence-based research that shaped the product

The five games and the spaced-retrieval surface in El Troso are not
design intuitions — they are translations of published evidence. We
owe the researchers whose work made this possible.

### Reminiscence therapy (G3 Recognize and Tell)
- **Woods B, O'Philbin L, Farrell EM, Spector AE, Orrell M.**
  *Reminiscence therapy for dementia.* Cochrane Database of Systematic
  Reviews, 2018, Issue 3, Art. No.: CD001120. 22 RCTs, n > 1,800.
  <https://www.cochranelibrary.com/cdsr/doi/10.1002/14651858.CD001120.pub3/full>

### Spaced retrieval training (G4 Today / Hero card)
- **USMART trial** — Bourgeois et al., *Alzheimer's Research & Therapy*,
  2017. First RCT of spaced retrieval training on a tablet platform.
  <https://alzres.biomedcentral.com/articles/10.1186/s13195-017-0289-z>
- **Hopper T, Mahendra N, Kim E, et al.** *Evidence-based practice
  recommendations for working with individuals with dementia: spaced
  retrieval training.* J Med Speech Lang Pathol, 2013. PMID 23886395.
  <https://pubmed.ncbi.nlm.nih.gov/23886395/>

### Retrieval practice (G2 Guess Together — deferred to v1.x)
- **Roediger HL, Karpicke JD.** *Test-enhanced learning: taking memory
  tests improves long-term retention.* Psychological Science, 2006.
  <https://doi.org/10.1111/j.1467-9280.2006.01693.x>

### Cognitive stimulation / memory training (G5 Continuing Story)
- **Cotelli M, Manenti R, Zanetti O.** *Reminiscence therapy in
  dementia: a review.* Maturitas, 2012. PMID 22466023.
  <https://pubmed.ncbi.nlm.nih.gov/22466023/>
- **Bluck S, Levine LJ.** *Reminiscence as autobiographical memory: a
  catalyst for reminiscence theory development.* Memory, 1998.
  <https://doi.org/10.1080/096582198388517>

### Serious games in MCI (G1 Photo Memory)
- **JMIR Serious Games 2024** — systematic review of serious games for
  mild cognitive impairment. PMID 39083796.
  <https://pubmed.ncbi.nlm.nih.gov/39083796/>

### Errorless learning (G2 design constraint)
- **Clare L, Wilson BA, Carter G, Roth I, Hodges JR.** *Relearning of
  face-name associations in Alzheimer's disease.* Neuropsychology, 2002.
  PMC3381647.
  <https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3381647/>

  *This citation is the reason G2 is deferred to v1.x. In MCI, a
  plausible distractor can be remembered as the correct answer.
  Shipping G2 without an errorless-learning redesign would have been
  irresponsible.*

### Socio-emotional selectivity (audience tone calibration)
- **Carstensen LL, Mikels JA.** *At the intersection of emotion and
  cognition: aging and the positivity effect.* PMC3459016.
  <https://www.ncbi.nlm.nih.gov/pmc/articles/PMC3459016/>

### Autobiographical memory cueing (UI choice of photo+text+audio)
- **SenseCam research, Imperial College London, 2014.** PMID 24528204.
  <https://pubmed.ncbi.nlm.nih.gov/24528204/>

### Global scale
- **WHO Fact Sheet on Dementia, 2023.** 55M people worldwide,
  +10M/year, projected 139M by 2050.
  <https://www.who.int/news-room/fact-sheets/detail/dementia>

---

## Open-source libraries

The Flutter and Dart ecosystem makes a small team building something
ambitious feasible. Key dependencies:

| Package | Purpose | License |
|---------|---------|---------|
| [`flutter`](https://flutter.dev) | UI framework | BSD-3-Clause |
| [`flutter_gemma`](https://pub.dev/packages/flutter_gemma) | Gemma 4 binding | Apache 2.0 |
| [`flutter_riverpod`](https://pub.dev/packages/flutter_riverpod) | State management | MIT |
| [`go_router`](https://pub.dev/packages/go_router) | Navigation | BSD-3-Clause |
| [`speech_to_text`](https://pub.dev/packages/speech_to_text) | Android STT wrapper | BSD-3-Clause |
| [`flutter_tts`](https://pub.dev/packages/flutter_tts) | Android TTS wrapper | MIT |
| [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Locale persistence | BSD-3-Clause |
| [`image_picker`](https://pub.dev/packages/image_picker) | Photo capture | Apache 2.0 |
| [`path_provider`](https://pub.dev/packages/path_provider) | Documents directory | BSD-3-Clause |

Full dependency tree: see [`el_troso/pubspec.yaml`](el_troso/pubspec.yaml).

---

## Design and visual identity

- **Color palette** — cream parchment `#F2EFEA`, olive green, warm
  terracotta, sepia browns. Inspired by old Italian schoolbooks and
  the typography of mid-century journals.
- **Typography** — serif body, no commercial display fonts.
- **Logo** — *EL TROSO* wordmark with the letter *S* drawn as a
  winding path. Designed by Guido Marangoni in Figma.

---

## Production credits — pitch video

The 3-minute pitch submitted to Kaggle uses the following tools and
assets:

- **Storyboard sketches** — generated with Google Nano Banana Pro
  from prompts in [`STORYBOARD_VIDEO_PITCH.md`](STORYBOARD_VIDEO_PITCH.md).
- **Voiceover (English)** — generated with ElevenLabs from the script
  in [`VOICEOVER_SCRIPT.md`](VOICEOVER_SCRIPT.md).
- **Voiceover (Italian, S04)** — recorded by Guido Marangoni for the
  phrase *"El troso… il sentiero, in dialetto veneto."*
- **Screen recordings** — captured on Pixel 7a, build 0.4.5+43, via
  `scrcpy`. Compositing in Wondershare Filmora.
- **Editing, color grade, subtitles** — Wondershare Filmora.
- **Music** — none. The video is voice and ambient only, by design.

---

## People who helped, directly or by example

- **Anthropic Claude** (claude-opus-4-7, claude-sonnet-4-6) — pair
  programming partner across most of the build. Architectural
  decisions, code review, documentation drafts.
- **The Kaggle Gemma 4 Hackathon organisers** — for setting a
  challenge that rewards on-device thinking instead of cloud-scale
  thinking. It changed how this project was shaped.
- **The 2024 Kaggle Gemma 3 community** — for showing the bar.
- **Italian-speaking friends and family** who tested early builds and
  pointed out where the tone of voice felt wrong. The "el troso"
  metaphor itself emerged from one of those conversations.

---

## A note on AI assistance

This project was built with substantial AI pair-programming
assistance (Anthropic Claude). The design decisions, the metaphor,
the choice of EBM anchors, and the scope-lock discipline are human.
The implementation was a collaboration. We think this is the right
way to build software in 2026, and we're honest about it.

The Gemma 4 model running inside the app, by contrast, was used as
a foundation model with no fine-tuning. We did not train, distill,
or modify the weights — only the prompts.

---

## Contact

- Author: **Guido Marangoni** — `io@guidomarangoni.it`
- Project: <https://github.com/[org]/el-troso> *(to be filled in)*
- Built in **Padova, Italy**, April–May 2026.

---

*If you are a researcher whose work is cited above and you'd like a
different attribution, a correction, or a removal — please reach out.
We will respond within a week.*

*If you are a person caring for a loved one with cognitive decline
and El Troso helped, even a little — please tell us. That feedback
will shape v1.1.*
