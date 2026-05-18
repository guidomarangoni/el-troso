// El Troso - Record page "Racconto" (Fase 4.5.a).
//
// Prima feature vera dell'app: l'utente (Giorgio) tocca "Racconto" in home
// e arriva qui per deporre un nuovo ricordo.
//
// Contenuto schermata (layout minimale, pre-mockup Stitch/Design):
//   AppBar: "Racconto"
//   Body:   prompt "Cosa vuoi raccontarmi?"
//           TextField multiline (min 5 righe) con mic come suffix icon,
//               riceve live STT it_IT (stesso pattern di S1 onboarding)
//           CTA full-width "Custodisci" (abilitato solo con testo non-whitespace)
//
// Save handler:
//   - trim(text) → se vuoto, no-op (CTA e' disabilitato → non dovrebbe servire)
//   - crea Memory con id = millis + suffix random, createdAt = now.toUtc()
//   - ref.read(memoriesProvider.notifier).add(memory)
//   - SnackBar con `recordSavedLabel` ("Ho custodito il tuo ricordo...")
//   - context.go('/home')
//
// Scelte:
// - Niente autofocus sul TextField: se autofocuso parte la tastiera e
//   Giorgio non vede il mic. La tastiera arriva solo se l'utente tocca
//   esplicitamente il campo. Il mic e' il primo affordance visibile.
// - STT stesso pattern di _StepName (onboarding S1): clear → startListening
//   → onResult scrive live → SnackBar su errore init.
// - debugPrint su tutti gli stati visibili a schermo (rule del progetto).

import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:el_troso/core/locale/locale_codes.dart';
import 'package:el_troso/core/version.dart';
import 'package:el_troso/core/voice/stt_provider.dart';
import 'package:el_troso/features/ask/gemma_providers.dart';
import 'package:el_troso/features/memory/memory.dart';
import 'package:el_troso/features/memory/memory_providers.dart';
import 'package:el_troso/features/memory/vector_store_provider.dart';
import 'package:el_troso/features/profile/profile_providers.dart';
import 'package:el_troso/l10n/app_localizations.dart';

class RecordPage extends ConsumerStatefulWidget {
  const RecordPage({super.key});

  @override
  ConsumerState<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends ConsumerState<RecordPage> {
  final _controller = TextEditingController();

  bool _isListening = false;
  bool _micDisabled = false;
  bool _saving = false;

  // F7 - Tag (nullable: utente puo' non scegliere).
  String? _tag;
  // F9 - Walker (nullable: default implicito = self).
  String? _walker;

  // F4.5.f - Immagine allegata.
  // Nota (build 19): la `imageDescription` non viene più generata
  // automaticamente da Gemma al momento del pick. La descrizione
  // visiva di una foto NON è il ricordo autobiografico e usarla come
  // ground truth nei prompt G3 portava il modello a confermare
  // dettagli visivi non presenti nel ricordo vero. La foto resta
  // visualizzata + persistita; il ricordo vero resta solo nel testo
  // dettato dall'utente.
  File? _imageFile;

  // F4.5.f - Audio recording.
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _audioFilePath;
  bool _transcribingAudio = false;

  // Prefisso committato: testo gia' presente nel controller all'avvio
  // della sessione STT corrente. Permette al mic di "riprendere" una
  // dettatura interrotta accodandosi, invece di sovrascrivere.
  //
  // speech_to_text 7.x riparte da zero a ogni listen(): i risultati in
  // `onResult` contengono solo il testo della nuova sessione, non quello
  // gia' nel campo. Senza memoizzare il prefisso, il secondo tap mic
  // cancellerebbe di fatto il racconto precedente.
  String _committedPrefix = '';

  // Hard limit caratteri ricordo.
  //
  // Motivo: EmbeddingGemma 300M seq512 = 512 token massimi per input.
  // Tokenizer Gemma su italiano sta tra 3 e 4 caratteri/token nel caso
  // peggiore (parole brevi, apostrofi, nomi propri). 1500 caratteri / 3
  // = 500 token → resta sotto 512 anche nel caso peggiore. In 4.5.d
  // quando misureremo i token effettivi dall'embedding runtime possiamo
  // alzare a 1800 char (margine realistico ~4 char/token).
  //
  // Scelta di design: limite visibile all'utente (counter "N caratteri
  // rimasti") + truncation hard lato input. NIENTE troncamenti silenti
  // o chunking a valle: rompono il contratto "custodisco ogni tuo ricordo".
  static const int _kMaxChars = 1500;
  // Soglia warning: sotto questo valore il counter diventa rosso per
  // segnalare che conviene chiudere il pensiero.
  static const int _kWarnThreshold = 150;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    // Ferma il plugin se si esce mentre ascolta (stop idempotente).
    if (_isListening) {
      ref.read(sttServiceProvider).stop();
    }
    if (_isRecording) {
      _audioRecorder.stop();
    }
    _audioRecorder.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {}); // ri-valuta hasText → enable/disable CTA
  }

  Future<void> _toggleMic() async {
    final stt = ref.read(sttServiceProvider);
    if (_isListening) {
      debugPrint('[record] mic stop (user tap)');
      await stt.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    FocusScope.of(context).unfocus();
    debugPrint(
      '[record] mic start tap '
      '(resume mode, current len=${_controller.text.length})',
    );
    // Resume mode: il testo gia' nel campo diventa prefisso. La nuova
    // sessione STT si accoda, NON sovrascrive. Se il prefisso non termina
    // gia' con spazio/newline aggiungiamo uno spazio di raccordo per non
    // concatenare in modo appiccicato ("casa" + "era" → "casaera").
    var prefix = _controller.text;
    if (prefix.isNotEmpty &&
        !prefix.endsWith(' ') &&
        !prefix.endsWith('\n')) {
      prefix = '$prefix ';
    }
    _committedPrefix = prefix;
    // Se abbiamo aggiunto lo spazio di raccordo, scriviamolo subito nel
    // campo cosi' il cursore e' in coda quando parte la dettatura (niente
    // "salto" visivo quando arriva il primo onResult).
    if (prefix != _controller.text) {
      _controller.value = TextEditingValue(
        text: prefix,
        selection: TextSelection.collapsed(offset: prefix.length),
      );
    }
    setState(() => _isListening = true);
    // Override espliciti dei default del wrapper (3s/30s) per un racconto
    // riflessivo: un over-80 che racconta un ricordo fa pause lunghe per
    // pensare ("Era il... aspetta... il '58, credo"). Con pauseFor=3s il
    // recognizer spegne il mic troppo in fretta e l'utente deve ri-toccare.
    // - pauseFor=10s: tollera pause di pensiero senza spegnere.
    // - listenFor=90s: sessione lunga. Android SpeechRecognizer ha un suo
    //   cap effettivo (~60s in alcune ROM); se taglia prima, l'utente
    //   ri-tocca il mic e continua - non perde il testo gia' nel campo.
    // Per campi brevi (S1 nome, tag chip) i default del servizio restano ok.
    await stt.startListening(
      localeId: sttLocaleId(Localizations.localeOf(context)),
      pauseFor: const Duration(seconds: 10),
      listenFor: const Duration(seconds: 90),
      onResult: _onSttResult,
    );
    if (!stt.isListening && mounted) {
      debugPrint('[record] mic init/start failed → disabling');
      setState(() {
        _isListening = false;
        _micDisabled = true;
      });
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorTechnical)),
      );
    }
  }

  void _onSttResult(String text, bool isFinal) {
    debugPrint(
      '[record] stt result "$text" isFinal=$isFinal '
      'prefixLen=${_committedPrefix.length}',
    );
    // Concateniamo prefisso + testo della sessione corrente. Il prefisso
    // e' stato fissato in _toggleMic() al momento dello start; da quel
    // momento il controller e' gestito esclusivamente da questo handler
    // fino allo stop (l'utente non dovrebbe editare durante l'ascolto).
    final combined = _committedPrefix + text;
    // Se la dettatura supera il cap, tronchiamo e fermiamo lo STT.
    // Writing via _controller.value bypassa maxLength del TextField (che
    // opera solo sull'input tastiera), quindi DOBBIAMO troncare qui.
    final hitLimit = combined.length >= _kMaxChars;
    final clamped =
        hitLimit ? combined.substring(0, _kMaxChars) : combined;
    _controller.value = TextEditingValue(
      text: clamped,
      selection: TextSelection.collapsed(offset: clamped.length),
    );
    if (hitLimit) {
      debugPrint('[record] stt hit char limit ($_kMaxChars) → auto-stop');
      ref.read(sttServiceProvider).stop();
      if (mounted) {
        setState(() => _isListening = false);
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.recordCharLimitReached)),
        );
      }
      return;
    }
    if (isFinal) {
      debugPrint('[record] stt final → listening=false');
      if (mounted) setState(() => _isListening = false);
    }
  }

  String _newId() {
    final millis = DateTime.now().millisecondsSinceEpoch;
    // Random 4 hex char = 16 bit di entropia. Su single-device single-user
    // basta per escludere collisioni anche con tap doppio.
    final rnd = Random().nextInt(0xFFFF).toRadixString(16).padLeft(4, '0');
    return 'mem_${millis}_$rnd';
  }

  // ─────────────────────────── Image picker (F4.5.f)

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(l10n.recordPhotoCamera),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(l10n.recordPhotoGallery),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
    if (source == null || !mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;

    // Copia il file nella dir app per persistenza.
    final docsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${docsDir.path}/images');
    if (!await imagesDir.exists()) await imagesDir.create(recursive: true);
    final destPath = '${imagesDir.path}/${_newId()}.jpg';
    final destFile = await File(picked.path).copy(destPath);

    setState(() {
      _imageFile = destFile;
    });
    debugPrint('[record] image picked → $destPath');
  }

  // ─────────────────────────── Audio recording (F4.5.f)

  Future<void> _toggleAudioRecording() async {
    if (_isRecording) {
      // Ferma registrazione.
      final path = await _audioRecorder.stop();
      if (!mounted) return;
      debugPrint('[record] audio stopped: $path');
      if (path == null) {
        setState(() => _isRecording = false);
        return;
      }

      setState(() {
        _isRecording = false;
        _audioFilePath = path;
        _transcribingAudio = true;
      });

      // Gemma trascrive l'audio.
      try {
        final audioBytes = await File(path).readAsBytes();
        final transcription =
            await ref.read(gemmaServiceProvider).transcribeAudio(audioBytes);
        if (!mounted) return;
        // Accoda la trascrizione al testo esistente.
        final existing = _controller.text.trim();
        final newText = existing.isEmpty
            ? transcription
            : '$existing\n$transcription';
        _controller.text = newText;
        _controller.selection = TextSelection.fromPosition(
          TextPosition(offset: _controller.text.length),
        );
        setState(() => _transcribingAudio = false);
        debugPrint('[record] audio transcribed: $transcription');
      } catch (e) {
        debugPrint('[record] audio transcription failed: $e');
        if (!mounted) return;
        setState(() => _transcribingAudio = false);
        // Audio salvato ma senza trascrizione. L'utente può scrivere a mano.
      }
    } else {
      // Avvia registrazione WAV.
      final docsDir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${docsDir.path}/audio');
      if (!await audioDir.exists()) await audioDir.create(recursive: true);
      final filePath = '${audioDir.path}/${_newId()}.wav';

      if (await _audioRecorder.hasPermission()) {
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.wav),
          path: filePath,
        );
        if (!mounted) return;
        setState(() => _isRecording = true);
        debugPrint('[record] audio recording started: $filePath');
      } else {
        debugPrint('[record] audio permission denied');
      }
    }
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      debugPrint('[record] save aborted: empty text');
      return;
    }
    if (_saving) return; // evita doppio tap
    setState(() => _saving = true);

    // Se stiamo ascoltando, fermiamo prima di salvare: il plugin continuerebbe
    // a scrivere nel controller dopo che siamo usciti dalla rotta.
    if (_isListening) {
      await ref.read(sttServiceProvider).stop();
      if (mounted) setState(() => _isListening = false);
    }

    // Build 42: cattura la lingua corrente della UI come `originalLang`.
    // Questa è la lingua in cui l'utente ha appena dettato/scritto, e
    // sarà la sorgente per la traduzione on-demand quando il lettore
    // legge il ricordo in un'altra lingua.
    final lang = Localizations.localeOf(context).languageCode;
    final memory = Memory(
      id: _newId(),
      text: text,
      createdAt: DateTime.now().toUtc(),
      tag: _tag,
      walker: _walker ?? 'self',
      imagePath: _imageFile?.path,
      audioPath: _audioFilePath,
      originalLang: lang,
    );
    debugPrint('[record] save → $memory');
    await ref.read(memoriesProvider.notifier).add(memory);
    debugPrint('[record] save done → /home');

    // 4.5.d - indicizza nel vector store. Fire-and-forget: non blocchiamo
    // l'UX del "Custodisci" per l'embedding (~700 ms + 3-5 s al primo uso
    // per init embedder). Se fallisce, al prossimo search di 4.5.e il
    // syncWithMemories del VectorStoreService farà catch-up sul drift
    // tra JSON e vector store.
    // ignore: discarded_futures
    ref.read(vectorStoreServiceProvider).addMemory(memory);

    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.recordSavedLabel)),
    );
    context.go('/home');
  }

  /// Conferma uscita se c'e' testo non salvato.
  Future<void> _confirmExit(BuildContext context) async {
    final hasContent = _controller.text.trim().isNotEmpty ||
        _imageFile != null ||
        _audioFilePath != null;
    if (!hasContent) {
      context.go('/home');
      return;
    }
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.recordExitTitle),
        content: Text(l10n.recordExitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.recordExitCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.recordExitConfirm),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasText = _controller.text.trim().isNotEmpty;

    debugPrint(
      '[record] render isListening=$_isListening micDisabled=$_micDisabled '
      'saving=$_saving hasText=$hasText len=${_controller.text.length}',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeRecordCta),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _confirmExit(context),
        ),
        actions: const [VersionBadge()],
      ),
      // CTA "Custodisci" pinned in basso, fuori dallo scroll.
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
          24, 8, 24,
          MediaQuery.of(context).padding.bottom + 12,
        ),
        child: FilledButton(
          onPressed: (hasText && !_saving && !_transcribingAudio)
              ? _save
              : null,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.recordSaveCta),
        ),
      ),
      body: SafeArea(
        bottom: false, // il bottom è gestito dal bottomNavigationBar
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Prompt ──
              Text(
                l10n.recordPromptQ,
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),

              // ── Campo di testo con mic ──
              TextField(
                controller: _controller,
                style: theme.textTheme.bodyLarge,
                textInputAction: TextInputAction.newline,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                minLines: 5,
                maxLength: _kMaxChars,
                buildCounter: (
                  _, {
                  required int currentLength,
                  required bool isFocused,
                  required int? maxLength,
                }) =>
                    null,
                decoration: InputDecoration(
                  hintText: l10n.recordPromptQ,
                  border: const OutlineInputBorder(),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  suffixIcon: _micDisabled
                      ? null
                      : Padding(
                          padding: const EdgeInsets.only(top: 4, right: 4),
                          child: IconButton(
                            tooltip: l10n.recordMicCta,
                            icon: Icon(
                              _isListening ? Icons.stop_circle : Icons.mic,
                              color: _isListening
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.primary,
                              size: 32,
                            ),
                            onPressed: _toggleMic,
                          ),
                        ),
                ),
              ),

              // Riga info sotto il campo: "Sto ascoltando..." + counter.
              SizedBox(
                height: 28,
                child: Row(
                  children: [
                    if (_isListening)
                      Text(
                        l10n.askListening,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    const Spacer(),
                    Builder(
                      builder: (_) {
                        final remaining = _kMaxChars - _controller.text.length;
                        final isWarn = remaining <= _kWarnThreshold;
                        return Text(
                          l10n.recordCharCounter(remaining.clamp(0, _kMaxChars)),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isWarn
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                            fontWeight:
                                isWarn ? FontWeight.w600 : FontWeight.w400,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Bottoni multimedia: foto + audio ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        _imageFile != null
                            ? Icons.check_circle
                            : Icons.add_a_photo,
                        color: _imageFile != null
                            ? theme.colorScheme.primary
                            : null,
                      ),
                      label: Text(
                        _imageFile != null
                            ? l10n.recordImageAdded
                            : l10n.recordAddPhoto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: (_saving || _transcribingAudio)
                          ? null
                          : _pickImage,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: _transcribingAudio
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              _isRecording
                                  ? Icons.stop_circle
                                  : _audioFilePath != null
                                      ? Icons.check_circle
                                      : Icons.mic,
                              color: _isRecording
                                  ? theme.colorScheme.error
                                  : _audioFilePath != null
                                      ? theme.colorScheme.primary
                                      : null,
                            ),
                      label: Text(
                        _transcribingAudio
                            ? l10n.recordTranscribing
                            : _isRecording
                                ? l10n.recordStopAudio
                                : _audioFilePath != null
                                    ? l10n.recordAudioAdded
                                    : l10n.recordAudio,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onPressed: (_saving || _transcribingAudio)
                          ? null
                          : _toggleAudioRecording,
                    ),
                  ),
                ],
              ),

              // ── Anteprima immagine con stato caricamento ──
              if (_imageFile != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _imageFile != null
                      ? Image.file(
                          _imageFile!,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 180,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                ),
              ],

              // ── Indicatore audio ──
              if (_audioFilePath != null && !_isRecording)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Icon(Icons.graphic_eq,
                          size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        l10n.recordAudioReady,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // ── F7 - Tag chips ──
              Text(
                l10n.recordTagPrompt,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _tagChip('family', l10n.tagFamily),
                  _tagChip('work', l10n.tagWork),
                  _tagChip('travel', l10n.tagTravel),
                  _tagChip('home', l10n.tagHome),
                  _tagChip('other', l10n.tagOther),
                ],
              ),

              const SizedBox(height: 16),

              // ── F9 - Walker chips ──
              Text(
                l10n.walkerChipTellQ,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _walkerChip('self', ref.read(profileProvider)?.name ?? '...'),
                  _walkerChip('child', l10n.walkerChild),
                  _walkerChip('grandchild', l10n.walkerGrandchild),
                  _walkerChip('friend', l10n.walkerFriend),
                ],
              ),

              // Padding extra per non tagliare l'ultimo chip col CTA.
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tagChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _tag == value,
      onSelected: (sel) => setState(() => _tag = sel ? value : null),
    );
  }

  Widget _walkerChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _walker == value,
      onSelected: (sel) => setState(() => _walker = sel ? value : null),
    );
  }
}
