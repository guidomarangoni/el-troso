// El Troso - G3 "Riconosci e racconta": pagina (Fase 4.5.i).
//
// Flusso:
//   1. _Phase.viewing      foto mostrata, CTA "Racconta cosa ricordi"
//   2. _Phase.listening    STT IT attivo, trascrizione live
//   3. _Phase.thinking     Gemma 4 confronta racconto vs ricordo
//   4. _Phase.feedback     risposta calda, TTS auto + CTA "Un'altra"
//   5. _Phase.noPhotos     empty state se nessun ricordo ha foto
//   6. _Phase.error        errore tecnico + retry
//
// EBM richiamata:
//   - Reminiscence therapy 1:1 (Cochrane Woods 2018)
//   - Lifelogging autobiografico (SenseCam 2014)
//   - Errorless learning §5c — il prompt impone "no sbagliato"
//   - Positivity effect §5d — tono caldo, valorizza il ricordato
//
// Il "calpestio" del trittico: ogni feedback positivo registra un
// Walk sul ricordo (walker = self, default). Cosi' la sessione di
// gioco contribuisce alla persistenza del ricordo (anti-oblio F12 +
// rinforza spaced retrieval G4).

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:el_troso/core/fullscreen_photo_view.dart';
import 'package:el_troso/core/game_info_sheet.dart';
import 'package:el_troso/core/locale/locale_codes.dart';
import 'package:el_troso/core/version.dart';
import 'package:el_troso/core/voice/stt_provider.dart';
import 'package:el_troso/core/voice/tts_provider.dart';
import 'package:el_troso/features/ask/gemma_providers.dart';
import 'package:el_troso/features/games/recognize_logic.dart';
import 'package:el_troso/features/memory/memory.dart';
import 'package:el_troso/features/memory/memory_providers.dart';
import 'package:el_troso/features/profile/profile_providers.dart';
import 'package:el_troso/l10n/app_localizations.dart';

enum _Phase { viewing, listening, thinking, feedback, noPhotos, error }

class RecognizePage extends ConsumerStatefulWidget {
  const RecognizePage({super.key});

  @override
  ConsumerState<RecognizePage> createState() => _RecognizePageState();
}

class _RecognizePageState extends ConsumerState<RecognizePage> {
  Memory? _target;
  _Phase _phase = _Phase.viewing;
  String _userRecall = '';
  String _feedback = '';
  String _errorMessage = '';

  // Controller del TextField di input testuale: sincronizzato con
  // _userRecall sia in entrata (STT scrive nel controller) sia in
  // uscita (l'utente digita → onChanged aggiorna _userRecall).
  final TextEditingController _recallController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Il pick avviene sul primo postFrame perche' memoriesProvider
    // e' AsyncValue: a build initState potrebbe essere ancora loading.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pickNew();
    });
  }

  @override
  void dispose() {
    // Stop pulito di STT/TTS se stiamo uscendo a meta' interazione.
    // ignore: discarded_futures
    ref.read(sttServiceProvider).stop();
    // ignore: discarded_futures
    ref.read(ttsServiceProvider).stop();
    _recallController.dispose();
    super.dispose();
  }

  void _pickNew() {
    final memories = ref.read(memoriesProvider).valueOrNull ?? const <Memory>[];
    final pick = pickRecognizeTarget(memories);
    setState(() {
      _target = pick;
      _phase = pick == null ? _Phase.noPhotos : _Phase.viewing;
      _userRecall = '';
      _feedback = '';
      _errorMessage = '';
    });
    _recallController.clear();
    debugPrint('[recognize] pick=${pick?.id} phase=$_phase');
  }

  Future<void> _toggleMic() async {
    final stt = ref.read(sttServiceProvider);
    if (_phase == _Phase.listening) {
      await stt.stop();
      if (!mounted) return;
      setState(() {
        // Se l'utente ha gia' parlato, vai a thinking; altrimenti torna a viewing.
        _phase = _userRecall.trim().isEmpty ? _Phase.viewing : _Phase.viewing;
      });
      return;
    }
    setState(() {
      _phase = _Phase.listening;
      _userRecall = '';
    });
    _recallController.clear();
    await stt.startListening(
      localeId: sttLocaleId(Localizations.localeOf(context)),
      pauseFor: const Duration(seconds: 8),
      listenFor: const Duration(seconds: 60),
      onResult: (text, isFinal) {
        if (!mounted) return;
        setState(() => _userRecall = text);
        // Sincronizza il TextField con il testo dettato, così se
        // l'utente vuole correggere a mano dopo la dettatura può.
        _recallController.text = text;
        _recallController.selection = TextSelection.fromPosition(
          TextPosition(offset: text.length),
        );
        if (isFinal) {
          // Auto-stop quando lo speech recognizer chiude la sessione.
          setState(() => _phase = _Phase.viewing);
        }
      },
    );
    if (!stt.isListening && mounted && _phase == _Phase.listening) {
      // Init/start fallito.
      setState(() {
        _phase = _Phase.error;
        _errorMessage = AppLocalizations.of(context).errorTechnical;
      });
    }
  }

  Future<void> _sendToGemma() async {
    if (_target == null || _userRecall.trim().isEmpty) return;
    // Stop mic se ancora attivo.
    await ref.read(sttServiceProvider).stop();

    setState(() => _phase = _Phase.thinking);

    final profile = ref.read(profileProvider);
    final speakerName = (profile != null && profile.name.isNotEmpty)
        ? profile.name
        : 'la persona';
    final prompt = buildRecognizePrompt(
      memory: _target!,
      userRecall: _userRecall.trim(),
      speakerName: speakerName,
    );
    debugPrint('[recognize] prompt len=${prompt.length} for ${_target!.id}');

    try {
      final answer = await ref.read(gemmaServiceProvider).ask(prompt);
      if (!mounted) return;
      final clean = answer.trim();

      // Registra Walk sul ricordo: la sessione di gioco e' a tutti gli
      // effetti un calpestio (rinforza F11/F12/G4 SRT).
      final walker = profile?.name == _target!.walker ? 'self' : 'self';
      final walk = Walk(
        walkedAt: DateTime.now().toUtc(),
        walker: walker,
      );
      final updated =
          _target!.copyWith(walks: [walk, ..._target!.walks]);
      await ref.read(memoriesProvider.notifier).updateMemory(updated);

      setState(() {
        _feedback = clean;
        _phase = _Phase.feedback;
        _target = updated;
      });

      // Auto-TTS sul feedback. Fire-and-forget.
      // ignore: discarded_futures
      ref.read(ttsServiceProvider).speak(
            clean,
            lang: ttsLanguageCode(Localizations.localeOf(context)),
          );
    } catch (e, st) {
      debugPrint('[recognize] gemma error: $e\n$st');
      if (!mounted) return;
      setState(() {
        _phase = _Phase.error;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final memoriesAsync = ref.watch(memoriesProvider);

    debugPrint(
      '[recognize] render phase=$_phase target=${_target?.id} '
      'recallLen=${_userRecall.length} memoriesAsync=${memoriesAsync.runtimeType}',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gameRecognizeTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: l10n.gameInfoWhatTitle,
            onPressed: () =>
                GameInfoSheet.show(context, GameInfoKind.recognize),
          ),
          const VersionBadge(),
        ],
      ),
      body: SafeArea(
        child: memoriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _ErrorBody(
            message: l10n.memoriesLoadError,
            onBack: () => context.go('/home'),
            backLabel: l10n.walkBackHomeCta,
          ),
          data: (_) => _buildBody(theme, l10n),
        ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n) {
    if (_phase == _Phase.noPhotos) {
      return _NoPhotosBody(
        l10n: l10n,
        onBack: () => context.go('/home'),
      );
    }
    if (_phase == _Phase.error) {
      return _ErrorBody(
        message: '${l10n.errorTechnical}\n\n$_errorMessage'.trim(),
        onBack: () => context.go('/home'),
        backLabel: l10n.walkBackHomeCta,
      );
    }

    final target = _target;
    if (target == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Foto del ricordo, occupazione generosa.
          // BoxFit.contain + sfondo crema: l'utente deve vedere la foto
          // INTERA per raccontare cosa ricorda. Tap → fullscreen viewer
          // con pinch-zoom per leggere dettagli (volti, scritte).
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: target.imagePath != null && File(target.imagePath!).existsSync()
                  ? () => FullscreenPhotoView.open(
                        context,
                        imagePath: target.imagePath!,
                        heroTag: 'photo-${target.id}',
                      )
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: target.imagePath != null && File(target.imagePath!).existsSync()
                      ? Hero(
                          tag: 'photo-${target.id}',
                          child: Image.file(
                            File(target.imagePath!),
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        )
                      : Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 48,
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Area inferiore: cambia in base a phase.
          Expanded(
            flex: 4,
            child: _buildPhaseArea(theme, l10n, target),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseArea(ThemeData theme, AppLocalizations l10n, Memory target) {
    switch (_phase) {
      case _Phase.viewing:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.recognizePromptQ,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            // TextField multiriga: l'utente può scrivere a mano OPPURE
            // dettare con il microfono. Quando dettazione è attiva
            // (_toggleMic) il controller viene popolato in tempo reale
            // dal callback onResult dello speech-to-text e la persona
            // può comunque correggere/aggiungere a mano dopo.
            TextField(
              controller: _recallController,
              maxLines: 3,
              minLines: 2,
              textInputAction: TextInputAction.done,
              style: theme.textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: l10n.recognizeTypeHint,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (v) => setState(() => _userRecall = v),
            ),
            const SizedBox(height: 16),
            // Riga: microfono (icona, secondario) + Invia (primario)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.mic),
                    onPressed: _toggleMic,
                    label: Text(_userRecall.isEmpty
                        ? l10n.recognizeStartCta
                        : l10n.recognizeRetryCta),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.send),
                    onPressed: _userRecall.trim().isEmpty
                        ? null
                        : _sendToGemma,
                    label: Text(l10n.recognizeSendCta),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case _Phase.listening:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Icon(
                Icons.mic,
                size: 48,
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.askListening,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            if (_userRecall.isNotEmpty)
              Text(
                _userRecall,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _toggleMic,
              child: Text(l10n.recognizeStopCta),
            ),
          ],
        );

      case _Phase.thinking:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.askThinkingLabel,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        );

      case _Phase.feedback:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _feedback,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _pickNew,
              child: Text(l10n.recognizeAnotherCta),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.go('/home'),
              child: Text(l10n.walkBackHomeCta),
            ),
          ],
        );

      case _Phase.noPhotos:
      case _Phase.error:
        return const SizedBox.shrink();
    }
  }
}

class _NoPhotosBody extends StatelessWidget {
  const _NoPhotosBody({required this.l10n, required this.onBack});

  final AppLocalizations l10n;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.add_a_photo_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.recognizeNoPhotosBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onBack,
            child: Text(l10n.walkBackHomeCta),
          ),
        ],
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onBack,
    required this.backLabel,
  });

  final String message;
  final VoidCallback onBack;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          OutlinedButton(
            onPressed: onBack,
            child: Text(backLabel),
          ),
        ],
      ),
    );
  }
}
