// El Troso - Onboarding reale (Fase 4.4.g1).
//
// 3 step in PageView, orchestrato dallo stato di _OnboardingPageState:
//   S1 — Nome. TextField con validazione "non vuoto dopo trim". "Avanti"
//        abilitato solo con testo.
//   S2 — Vocativo. 3 ChoiceChip preset (Nome / Signore|Sir / Nonno|Grandpa)
//        + "Altro..." che apre un TextField custom. Se l'utente non sceglie
//        nulla, il vocativo di default e' il nome da S1 (il chip "Usa il
//        mio nome" e' pre-selezionato).
//   S3 — Decennio. Wrap di ChoiceChip (Anni 30..Anni 00). Decennio nullable:
//        se nessuno selezionato, decade=null (tap "Ecco fatto" o "Salta").
//
// Al completamento: save Profile via profileProvider e vai a /home. Niente
// STT (arriva in 4.4.g2).
//
// Scelte:
// - PageView con `NeverScrollableScrollPhysics` - la navigazione tra step e'
//   pilotata dai bottoni, NON dal gesture swipe. Motivo: swipe e' scoperta
//   difficile per over-80 e produce progressi involontari. Il controllo
//   esplicito riduce l'ansia.
// - Back on S1 (primo step) e' disabilitato (Spacer). Su S2 e S3 presente.
// - Step indicator minimale "x di 3" in AppBar.subtitle, niente dots -
//   in 4.6 polish si promuove a indicatore grafico.
// - Tutti i testi passano da AppLocalizations: niente hardcoded italiano
//   nei widget.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:el_troso/core/locale/locale_codes.dart';
import 'package:el_troso/core/voice/stt_provider.dart';
import 'package:el_troso/core/version.dart';
import 'package:el_troso/features/profile/profile.dart';
import 'package:el_troso/features/profile/profile_providers.dart';
import 'package:el_troso/l10n/app_localizations.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  static const int _totalSteps = 3;

  final _pageController = PageController();
  int _currentStep = 0;

  // Stato condiviso tra step
  final _nameController = TextEditingController();
  String _vocative = ''; // vuoto = use name (default)
  int? _decade;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentStep >= _totalSteps - 1) return;
    // Dismiss keyboard: senza questo, la tastiera aperta in S1 rimane
    // presente in S2 consumando ~500px di viewport → overflow. Buona igiene
    // a prescindere: il passaggio di step non dovrebbe portarsi dietro
    // focus/IME dello step precedente.
    FocusScope.of(context).unfocus();
    setState(() => _currentStep++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _goBack() {
    if (_currentStep <= 0) return;
    FocusScope.of(context).unfocus();
    setState(() => _currentStep--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    final name = _nameController.text.trim();
    final vocative = _vocative.trim().isNotEmpty ? _vocative.trim() : name;
    final profile = Profile(
      name: name,
      vocative: vocative,
      decade: _decade,
    );
    debugPrint('[onboarding] finish profile=$profile');
    await ref.read(profileProvider.notifier).save(profile);
    debugPrint('[onboarding] save complete → /onboarding/seed-offer');
    if (!mounted) return;
    // build 24: dopo il profilo passa per la schermata opt-in seed,
    // non più direttamente in home.
    context.go('/onboarding/seed-offer');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    debugPrint(
      '[onboarding] render step=${_currentStep + 1}/$_totalSteps '
      'name="${_nameController.text}" vocative="$_vocative" decade=$_decade',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: const [VersionBadge()],
        // Indicatore step minimale - promozione a dots/progress bar in 4.6.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              l10n.onbStepLabel(_currentStep + 1, _totalSteps),
              style: theme.textTheme.labelLarge,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          // Disabilita swipe - navigazione solo via bottoni.
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StepName(
              controller: _nameController,
              onNext: _goNext,
            ),
            _StepVocative(
              name: _nameController.text.trim(),
              selected: _vocative,
              onChanged: (v) => setState(() => _vocative = v),
              onBack: _goBack,
              onNext: _goNext,
            ),
            _StepDecade(
              selected: _decade,
              onChanged: (d) => setState(() => _decade = d),
              onBack: _goBack,
              onDone: _finish,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Step 1 - Nome
// ─────────────────────────────────────────────────────────────────────────

class _StepName extends ConsumerStatefulWidget {
  const _StepName({required this.controller, required this.onNext});

  final TextEditingController controller;
  final VoidCallback onNext;

  @override
  ConsumerState<_StepName> createState() => _StepNameState();
}

class _StepNameState extends ConsumerState<_StepName> {
  // Stato microfono: idle | listening | error-ma-mic-disabilitato.
  bool _isListening = false;
  bool _micDisabled = false; // true dopo init fallita: nasconde l'IconButton.

  @override
  void initState() {
    super.initState();
    // Listener per ri-buildare quando il testo cambia (abilita/disabilita
    // "Avanti"). Usiamo setState su `_hasText` anziche' ValueNotifier per
    // restare nella convenzione setState del file.
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    // Se si esce mentre ascolta, ferma il plugin per non lasciare la sessione
    // appesa. stop() e' idempotente.
    if (_isListening) {
      ref.read(sttServiceProvider).stop();
    }
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {}); // ri-valuta hasText
  }

  Future<void> _toggleMic() async {
    final stt = ref.read(sttServiceProvider);
    if (_isListening) {
      debugPrint('[onboarding] mic stop (user tap)');
      await stt.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }
    // Chiudo la tastiera prima di ascoltare: convivono male
    // (IME copre il campo e il SnackBar di errore) e il mic non ne ha bisogno.
    FocusScope.of(context).unfocus();
    debugPrint('[onboarding] mic start tap');
    // Svuoto il campo prima di ascoltare: over-80 si aspetta che una nuova
    // dettatura ricominci da zero, non che si aggiunga a un eventuale residuo.
    widget.controller.clear();
    setState(() => _isListening = true);
    await stt.startListening(
      localeId: sttLocaleId(Localizations.localeOf(context)),
      onResult: _onSttResult,
    );
    // init fallita / hardware assente: stt.startListening ritorna senza
    // ascoltare; ripristino lo stato e disabilito il mic con SnackBar.
    if (!stt.isListening && mounted) {
      debugPrint('[onboarding] mic init/start failed → disabling');
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
      '[onboarding] stt result "$text" isFinal=$isFinal',
    );
    // Scrivo sempre nel controller (parziali e finale) cosi' l'utente vede
    // il testo crescere in tempo reale. La selection va in fondo per evitare
    // jumping del cursore se l'utente guarda.
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    if (isFinal) {
      debugPrint('[onboarding] stt final → stop + listening=false');
      if (mounted) setState(() => _isListening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final hasText = widget.controller.text.trim().isNotEmpty;

    return _StepScaffold(children: [
          const SizedBox(height: 24),
          Text(
            l10n.onbNameQ,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: widget.controller,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
            textInputAction: TextInputAction.done,
            // Niente autofocus se stiamo per dettare: autofocus riapre la
            // tastiera all'avvio e confonde se l'utente intende usare il mic.
            // Lascio autofocus comunque (maggioranza digita); sara' un tap
            // per chiuderla e passare al mic.
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.onbNameHint,
              border: const OutlineInputBorder(),
              // suffixIcon: mic / stop. Nascosto se init fallita.
              suffixIcon: _micDisabled
                  ? null
                  : IconButton(
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
            onSubmitted: (_) {
              if (hasText) widget.onNext();
            },
          ),
          // Feedback "sto ascoltando" sotto il campo. Altezza fissa per non
          // far saltare il layout quando compare/scompare.
          SizedBox(
            height: 32,
            child: _isListening
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      l10n.askListening,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const Spacer(),
          FilledButton(
            // Disabilitato finche' non c'e' testo non-whitespace.
            onPressed: hasText ? widget.onNext : null,
            child: Text(l10n.onbNameNext),
          ),
        ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Step 2 - Vocativo
// ─────────────────────────────────────────────────────────────────────────

class _StepVocative extends StatefulWidget {
  const _StepVocative({
    required this.name,
    required this.selected,
    required this.onChanged,
    required this.onBack,
    required this.onNext,
  });

  final String name; // per il chip "Usa il mio nome"
  final String selected; // valore corrente nel parent
  final ValueChanged<String> onChanged;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  State<_StepVocative> createState() => _StepVocativeState();
}

class _StepVocativeState extends State<_StepVocative> {
  final _customController = TextEditingController();
  bool _showCustom = false;

  @override
  void initState() {
    super.initState();
    _customController.addListener(_onCustomChanged);
  }

  @override
  void dispose() {
    _customController.removeListener(_onCustomChanged);
    _customController.dispose();
    super.dispose();
  }

  void _onCustomChanged() {
    // Se siamo nel modo custom, propaghiamo il testo al parent in tempo reale.
    if (_showCustom) {
      widget.onChanged(_customController.text);
    }
  }

  void _selectPreset(String value) {
    setState(() => _showCustom = false);
    widget.onChanged(value);
  }

  void _enterCustom() {
    setState(() => _showCustom = true);
    widget.onChanged(_customController.text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Valori dei preset risolti via ARB (MVP maschile; gender picker in 4.6).
    final nameValue = widget.name;
    final formalValue = l10n.onbVocativeFormalValue;
    final familyValue = l10n.onbVocativeFamilyValue;

    // Un chip e' selezionato se il suo value combacia con widget.selected
    // E non siamo in modalita' custom. Eccezione: il chip "Usa il mio nome"
    // e' selezionato anche quando selected e' vuoto (default implicito).
    final isNameSelected =
        !_showCustom && (widget.selected.isEmpty || widget.selected == nameValue);
    final isFormalSelected = !_showCustom && widget.selected == formalValue;
    final isFamilySelected = !_showCustom && widget.selected == familyValue;

    return _StepScaffold(children: [
          const SizedBox(height: 24),
          Text(
            l10n.onbVocativeQ,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge,
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ChoiceChip(
                label: Text(l10n.onbVocativeName),
                selected: isNameSelected,
                onSelected: (sel) => sel ? _selectPreset(nameValue) : null,
              ),
              ChoiceChip(
                label: Text(l10n.onbVocativeFormal),
                selected: isFormalSelected,
                onSelected: (sel) => sel ? _selectPreset(formalValue) : null,
              ),
              ChoiceChip(
                label: Text(l10n.onbVocativeFamily),
                selected: isFamilySelected,
                onSelected: (sel) => sel ? _selectPreset(familyValue) : null,
              ),
              ChoiceChip(
                label: Text(l10n.onbVocativeOther),
                selected: _showCustom,
                onSelected: (sel) => sel ? _enterCustom() : null,
              ),
            ],
          ),
          if (_showCustom) ...[
            const SizedBox(height: 24),
            TextField(
              controller: _customController,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l10n.onbVocativeCustomHint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
          const Spacer(),
          // Layout verticale: Row con due bottoni esplode perche' il
          // FilledButtonTheme ha minimumSize(infinity, 64) per i CTA
          // full-width della app. Stack verticale: primary pieno, Back
          // come TextButton centrato sotto (natural width, niente conflict).
          FilledButton(
            onPressed: widget.onNext,
            child: Text(l10n.onbNameNext),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: widget.onBack,
              child: Text(l10n.onbBack),
            ),
          ),
        ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Step 3 - Decennio
// ─────────────────────────────────────────────────────────────────────────

class _StepDecade extends StatelessWidget {
  const _StepDecade({
    required this.selected,
    required this.onChanged,
    required this.onBack,
    required this.onDone,
  });

  final int? selected;
  final ValueChanged<int?> onChanged;
  final VoidCallback onBack;
  final VoidCallback onDone;

  static const List<int> _decades = [
    1930, 1940, 1950, 1960, 1970, 1980, 1990, 2000,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return _StepScaffold(children: [
          const SizedBox(height: 24),
          Text(
            l10n.onbDecadeQ,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineLarge,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.onbDecadeOptional,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _decades.map((d) {
              // shortYear: '1930' → '30', '2000' → '00'. Due cifre finali.
              final shortYear = d.toString().substring(2);
              return ChoiceChip(
                label: Text(l10n.onbDecadeLabel(shortYear)),
                selected: selected == d,
                onSelected: (sel) => onChanged(sel ? d : null),
              );
            }).toList(),
          ),
          const Spacer(),
          // Stesso motivo dello step vocativo: FilledButton in Row esplode
          // per minimumSize(infinity). Stack verticale:
          // - primary: "Ecco fatto" full-width
          // - sotto: Back | Skip affiancati come TextButton (niente theme
          //   override, natural width → ok in Row).
          // "Salta" e "Ecco fatto" si comportano uguale se nessun decennio
          // e' selezionato; li teniamo comunque entrambi come affordance:
          // "Salta" e' una scorciatoia esplicita per chi non vuole
          // rispondere senza dover deselezionare chip cliccati per errore.
          FilledButton(
            onPressed: onDone,
            child: Text(l10n.onbDone),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: onBack,
                child: Text(l10n.onbBack),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () {
                  onChanged(null);
                  onDone();
                },
                child: Text(l10n.onbDecadeSkip),
              ),
            ],
          ),
        ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Helper layout per gli step
// ─────────────────────────────────────────────────────────────────────────

/// Wrapper comune per i 3 step dell'onboarding.
///
/// Risolve due requisiti in conflitto:
/// 1. I bottoni CTA devono stare in fondo alla pagina (pattern "Spacer
///    prima dei bottoni") quando il contenuto sopra ci sta.
/// 2. Quando il contenuto non ci sta (font grande, tastiera aperta, device
///    stretto), la pagina deve diventare scrollabile per non sfondare.
///
/// Soluzione: `LayoutBuilder → SingleChildScrollView → ConstrainedBox
/// (minHeight=viewport) → IntrinsicHeight → Column`. IntrinsicHeight
/// permette a `Spacer` di funzionare anche dentro un contesto scrollabile
/// (altrimenti Spacer crasha per unbounded height). Il costo computazionale
/// di IntrinsicHeight e' trascurabile per un layout di questa semplicita'.
class _StepScaffold extends StatelessWidget {
  const _StepScaffold({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Sottraggo il padding verticale (24 top + 24 bottom = 48) prima di
        // imporre minHeight, altrimenti la Column interna chiederebbe piu'
        // spazio del viewport e forzerebbe sempre lo scroll.
        final minHeight = constraints.maxHeight - 48;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: minHeight.isFinite && minHeight > 0 ? minHeight : 0,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
          ),
        );
      },
    );
  }
}
