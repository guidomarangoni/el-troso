import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// Nome dell'app. Non tradurre.
  ///
  /// In it, this message translates to:
  /// **'El Troso'**
  String get appTitle;

  /// Tagline principale, usata in onboarding S1 e in splash.
  ///
  /// In it, this message translates to:
  /// **'Il sentiero dei tuoi ricordi resta vivo se lo ripercorri.'**
  String get appTagline;

  /// No description provided for @onbStart.
  ///
  /// In it, this message translates to:
  /// **'Comincia'**
  String get onbStart;

  /// Indicatore di step durante l'onboarding, es. '2 di 3'.
  ///
  /// In it, this message translates to:
  /// **'{current} di {total}'**
  String onbStepLabel(int current, int total);

  /// No description provided for @onbBack.
  ///
  /// In it, this message translates to:
  /// **'Indietro'**
  String get onbBack;

  /// No description provided for @onbNameQ.
  ///
  /// In it, this message translates to:
  /// **'Come ti chiami?'**
  String get onbNameQ;

  /// No description provided for @onbNameHint.
  ///
  /// In it, this message translates to:
  /// **'Il tuo nome'**
  String get onbNameHint;

  /// No description provided for @onbNameNext.
  ///
  /// In it, this message translates to:
  /// **'Avanti'**
  String get onbNameNext;

  /// No description provided for @onbVocativeQ.
  ///
  /// In it, this message translates to:
  /// **'E come vuoi che ti chiami?'**
  String get onbVocativeQ;

  /// No description provided for @onbVocativeName.
  ///
  /// In it, this message translates to:
  /// **'Usa il mio nome'**
  String get onbVocativeName;

  /// No description provided for @onbVocativeFormal.
  ///
  /// In it, this message translates to:
  /// **'Signore / Signora'**
  String get onbVocativeFormal;

  /// Valore letterale del vocativo formale (MVP maschile; il gender picker arrivera' in 4.6).
  ///
  /// In it, this message translates to:
  /// **'Signore'**
  String get onbVocativeFormalValue;

  /// No description provided for @onbVocativeFamily.
  ///
  /// In it, this message translates to:
  /// **'Nonno / Nonna'**
  String get onbVocativeFamily;

  /// Valore letterale del vocativo familiare (MVP maschile).
  ///
  /// In it, this message translates to:
  /// **'Nonno'**
  String get onbVocativeFamilyValue;

  /// No description provided for @onbVocativeOther.
  ///
  /// In it, this message translates to:
  /// **'Altro...'**
  String get onbVocativeOther;

  /// No description provided for @onbVocativeCustomHint.
  ///
  /// In it, this message translates to:
  /// **'Come vuoi essere chiamato'**
  String get onbVocativeCustomHint;

  /// No description provided for @onbDecadeQ.
  ///
  /// In it, this message translates to:
  /// **'In che decennio sei nato/a?'**
  String get onbDecadeQ;

  /// No description provided for @onbDecadeOptional.
  ///
  /// In it, this message translates to:
  /// **'Puoi anche non dirlo.'**
  String get onbDecadeOptional;

  /// Etichetta di un chip decennio, es. 'Anni 50' per 1950.
  ///
  /// In it, this message translates to:
  /// **'Anni {shortYear}'**
  String onbDecadeLabel(String shortYear);

  /// No description provided for @onbDecadeSkip.
  ///
  /// In it, this message translates to:
  /// **'Salta'**
  String get onbDecadeSkip;

  /// No description provided for @onbDone.
  ///
  /// In it, this message translates to:
  /// **'Ecco fatto'**
  String get onbDone;

  /// Saluto della home con placeholder nome utente.
  ///
  /// In it, this message translates to:
  /// **'Ciao {name},'**
  String homeGreeting(String name);

  /// No description provided for @homeRecordCta.
  ///
  /// In it, this message translates to:
  /// **'Racconta'**
  String get homeRecordCta;

  /// No description provided for @homeWalkCta.
  ///
  /// In it, this message translates to:
  /// **'Ripercorri'**
  String get homeWalkCta;

  /// No description provided for @homeAskCta.
  ///
  /// In it, this message translates to:
  /// **'Fai una domanda'**
  String get homeAskCta;

  /// No description provided for @recordPromptQ.
  ///
  /// In it, this message translates to:
  /// **'Cosa vuoi raccontarmi?'**
  String get recordPromptQ;

  /// No description provided for @recordMicCta.
  ///
  /// In it, this message translates to:
  /// **'Tocca per parlare'**
  String get recordMicCta;

  /// CTA per salvare un ricordo. 'Custodire' e' scelto per il registro di cura/rispetto (non 'Salva').
  ///
  /// In it, this message translates to:
  /// **'Custodisci'**
  String get recordSaveCta;

  /// Contatore caratteri rimasti sotto il TextField ricordo. Invita alla sintesi prima del limite seq512 di EmbeddingGemma.
  ///
  /// In it, this message translates to:
  /// **'{n, plural, =1{1 carattere rimasto} other{{n} caratteri rimasti}}'**
  String recordCharCounter(int n);

  /// SnackBar mostrato quando la dettatura raggiunge il cap caratteri e viene fermata automaticamente.
  ///
  /// In it, this message translates to:
  /// **'Hai raggiunto il limite. Prova a sintetizzare in meno parole.'**
  String get recordCharLimitReached;

  /// No description provided for @recordSavedLabel.
  ///
  /// In it, this message translates to:
  /// **'Ho custodito il tuo ricordo. Ora il tuo sentiero e\' piu\' vivo.'**
  String get recordSavedLabel;

  /// No description provided for @recordFollowupIntro.
  ///
  /// In it, this message translates to:
  /// **'Un dettaglio in piu\' se ti va:'**
  String get recordFollowupIntro;

  /// No description provided for @recordTagPrompt.
  ///
  /// In it, this message translates to:
  /// **'Di cosa parla questo ricordo?'**
  String get recordTagPrompt;

  /// No description provided for @tagFamily.
  ///
  /// In it, this message translates to:
  /// **'Famiglia'**
  String get tagFamily;

  /// No description provided for @tagWork.
  ///
  /// In it, this message translates to:
  /// **'Lavoro'**
  String get tagWork;

  /// No description provided for @tagTravel.
  ///
  /// In it, this message translates to:
  /// **'Viaggi'**
  String get tagTravel;

  /// No description provided for @tagHome.
  ///
  /// In it, this message translates to:
  /// **'Casa'**
  String get tagHome;

  /// No description provided for @tagOther.
  ///
  /// In it, this message translates to:
  /// **'Altro'**
  String get tagOther;

  /// No description provided for @walkerChipTellQ.
  ///
  /// In it, this message translates to:
  /// **'Chi sta raccontando?'**
  String get walkerChipTellQ;

  /// No description provided for @walkerChipWalkQ.
  ///
  /// In it, this message translates to:
  /// **'Chi lo sta calpestando?'**
  String get walkerChipWalkQ;

  /// Chip walker default, usa il nome dell'utente principale.
  ///
  /// In it, this message translates to:
  /// **'{name}'**
  String walkerGiorgio(String name);

  /// No description provided for @walkerChild.
  ///
  /// In it, this message translates to:
  /// **'Il figlio / la figlia'**
  String get walkerChild;

  /// No description provided for @walkerGrandchild.
  ///
  /// In it, this message translates to:
  /// **'Un nipote'**
  String get walkerGrandchild;

  /// No description provided for @walkerFriend.
  ///
  /// In it, this message translates to:
  /// **'Un amico'**
  String get walkerFriend;

  /// No description provided for @walkCtaLabel.
  ///
  /// In it, this message translates to:
  /// **'Ripercorriamolo insieme'**
  String get walkCtaLabel;

  /// No description provided for @walkDoneLabel.
  ///
  /// In it, this message translates to:
  /// **'Il sentiero e\' di nuovo vivo.'**
  String get walkDoneLabel;

  /// No description provided for @fadingEmptyState.
  ///
  /// In it, this message translates to:
  /// **'Qualcosa sta sbiadendo. Vuoi tornarci?'**
  String get fadingEmptyState;

  /// No description provided for @askPromptQ.
  ///
  /// In it, this message translates to:
  /// **'Cosa vuoi chiedermi?'**
  String get askPromptQ;

  /// No description provided for @askListening.
  ///
  /// In it, this message translates to:
  /// **'Sto ascoltando...'**
  String get askListening;

  /// No description provided for @sourceChipLabel.
  ///
  /// In it, this message translates to:
  /// **'Ho usato questo ricordo'**
  String get sourceChipLabel;

  /// AppBar title della pagina AskPage (Fase 4.5.e).
  ///
  /// In it, this message translates to:
  /// **'Fai una domanda'**
  String get askTitle;

  /// CTA per inviare la domanda al RAG + Gemma.
  ///
  /// In it, this message translates to:
  /// **'Chiedi'**
  String get askSubmitCta;

  /// Tooltip del microfono nella AskPage.
  ///
  /// In it, this message translates to:
  /// **'Tocca per dettare la domanda'**
  String get askMicTooltip;

  /// Messaggio di progress durante il retrieve dal vector store.
  ///
  /// In it, this message translates to:
  /// **'Sto cercando tra i tuoi ricordi...'**
  String get askRetrievingLabel;

  /// Messaggio di progress durante la generazione Gemma.
  ///
  /// In it, this message translates to:
  /// **'Sto pensando...'**
  String get askThinkingLabel;

  /// Header sopra la lista dei ricordi usati per rispondere.
  ///
  /// In it, this message translates to:
  /// **'Ho usato questi ricordi:'**
  String get askSourcesHeader;

  /// Fallback quando nessun ricordo supera la soglia di similarity.
  ///
  /// In it, this message translates to:
  /// **'Non ho trovato ricordi che parlino di questo. Prova a raccontarne uno correlato e poi chiedimi di nuovo.'**
  String get askNoMatchBody;

  /// No description provided for @ragFallback.
  ///
  /// In it, this message translates to:
  /// **'Non mi ricordo bene.'**
  String get ragFallback;

  /// No description provided for @errorTechnical.
  ///
  /// In it, this message translates to:
  /// **'Mi sono fermato un momento. Riproviamo?'**
  String get errorTechnical;

  /// No description provided for @noMemoriesYet.
  ///
  /// In it, this message translates to:
  /// **'Ancora nessun ricordo. Comincia raccontandone uno.'**
  String get noMemoriesYet;

  /// No description provided for @pathBeginsHere.
  ///
  /// In it, this message translates to:
  /// **'Il tuo sentiero inizia qui. Fai il primo passo.'**
  String get pathBeginsHere;

  /// Header della sezione ricordi nella home, sopra la lista degli ultimi N.
  ///
  /// In it, this message translates to:
  /// **'I tuoi ricordi'**
  String get memoriesHeader;

  /// Testo di errore soft se il caricamento della lista ricordi dal disco fallisce. Non e' un crash, e' un messaggio in linea.
  ///
  /// In it, this message translates to:
  /// **'Qualcosa e\' andato storto nel rileggere i ricordi.'**
  String get memoriesLoadError;

  /// No description provided for @memoryDateToday.
  ///
  /// In it, this message translates to:
  /// **'oggi'**
  String get memoryDateToday;

  /// No description provided for @memoryDateYesterday.
  ///
  /// In it, this message translates to:
  /// **'ieri'**
  String get memoryDateYesterday;

  /// Data relativa per ricordi di 2-6 giorni fa.
  ///
  /// In it, this message translates to:
  /// **'{n, plural, =1{1 giorno fa} other{{n} giorni fa}}'**
  String memoryDateDaysAgo(int n);

  /// Data relativa per ricordi di 1-4 settimane fa.
  ///
  /// In it, this message translates to:
  /// **'{n, plural, =1{1 settimana fa} other{{n} settimane fa}}'**
  String memoryDateWeeksAgo(int n);

  /// Data relativa per ricordi di 1-11 mesi fa.
  ///
  /// In it, this message translates to:
  /// **'{n, plural, =1{1 mese fa} other{{n} mesi fa}}'**
  String memoryDateMonthsAgo(int n);

  /// Data relativa per ricordi di 1+ anni fa.
  ///
  /// In it, this message translates to:
  /// **'{n, plural, =1{1 anno fa} other{{n} anni fa}}'**
  String memoryDateYearsAgo(int n);

  /// AppBar title per la pagina di dettaglio di un ricordo (Ripercorro).
  ///
  /// In it, this message translates to:
  /// **'Ricordo'**
  String get memoryDetailTitle;

  /// Messaggio mostrato se apri /memory/:id con un id che non esiste piu' (cancellato, file corrotto).
  ///
  /// In it, this message translates to:
  /// **'Non riesco a trovare questo ricordo.'**
  String get memoryDetailNotFound;

  /// Label mostrato mentre il TTS sta leggendo il ricordo ad alta voce.
  ///
  /// In it, this message translates to:
  /// **'Sto ripercorrendo...'**
  String get walkInProgressLabel;

  /// CTA per interrompere la lettura TTS in corso.
  ///
  /// In it, this message translates to:
  /// **'Fermati'**
  String get walkStopCta;

  /// CTA per tornare alla home dopo aver ripercorso un ricordo.
  ///
  /// In it, this message translates to:
  /// **'Torna al sentiero'**
  String get walkBackHomeCta;

  /// No description provided for @settingsTitle.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get settingsTitle;

  /// No description provided for @settingsRestart.
  ///
  /// In it, this message translates to:
  /// **'Ricomincia il sentiero'**
  String get settingsRestart;

  /// No description provided for @settingsLanguage.
  ///
  /// In it, this message translates to:
  /// **'Lingua'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageIt.
  ///
  /// In it, this message translates to:
  /// **'Italiano'**
  String get settingsLanguageIt;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In it, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @playgroundTitle.
  ///
  /// In it, this message translates to:
  /// **'Playground (dev)'**
  String get playgroundTitle;

  /// No description provided for @playgroundDescription.
  ///
  /// In it, this message translates to:
  /// **'Pannello di test interno. Non visibile agli utenti finali.'**
  String get playgroundDescription;

  /// No description provided for @memoryDeleteTitle.
  ///
  /// In it, this message translates to:
  /// **'Dimenticare questo ricordo?'**
  String get memoryDeleteTitle;

  /// No description provided for @memoryDeleteBody.
  ///
  /// In it, this message translates to:
  /// **'Se lo fai, non potremo più ripercorrerlo insieme. Sei sicuro?'**
  String get memoryDeleteBody;

  /// No description provided for @memoryDeleteCancel.
  ///
  /// In it, this message translates to:
  /// **'No, tienilo'**
  String get memoryDeleteCancel;

  /// No description provided for @memoryDeleteConfirm.
  ///
  /// In it, this message translates to:
  /// **'Sì, dimenticalo'**
  String get memoryDeleteConfirm;

  /// No description provided for @recordAddPhoto.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi foto'**
  String get recordAddPhoto;

  /// No description provided for @recordPhotoCamera.
  ///
  /// In it, this message translates to:
  /// **'Scatta una foto'**
  String get recordPhotoCamera;

  /// No description provided for @recordPhotoGallery.
  ///
  /// In it, this message translates to:
  /// **'Scegli dalla galleria'**
  String get recordPhotoGallery;

  /// No description provided for @recordDescribingImage.
  ///
  /// In it, this message translates to:
  /// **'Sto guardando la foto...'**
  String get recordDescribingImage;

  /// No description provided for @recordImageAdded.
  ///
  /// In it, this message translates to:
  /// **'Foto aggiunta'**
  String get recordImageAdded;

  /// No description provided for @recordAudio.
  ///
  /// In it, this message translates to:
  /// **'Registra audio'**
  String get recordAudio;

  /// No description provided for @recordStopAudio.
  ///
  /// In it, this message translates to:
  /// **'Ferma registrazione'**
  String get recordStopAudio;

  /// No description provided for @recordTranscribing.
  ///
  /// In it, this message translates to:
  /// **'Sto trascrivendo...'**
  String get recordTranscribing;

  /// No description provided for @recordAudioAdded.
  ///
  /// In it, this message translates to:
  /// **'Audio aggiunto'**
  String get recordAudioAdded;

  /// No description provided for @recordAudioReady.
  ///
  /// In it, this message translates to:
  /// **'Audio originale salvato'**
  String get recordAudioReady;

  /// No description provided for @carouselWelcomeTitle.
  ///
  /// In it, this message translates to:
  /// **'El Troso'**
  String get carouselWelcomeTitle;

  /// No description provided for @carouselWelcomeBody.
  ///
  /// In it, this message translates to:
  /// **'Il sentiero dei tuoi ricordi\nresta vivo se lo ripercorri.'**
  String get carouselWelcomeBody;

  /// No description provided for @carouselWelcomeCta.
  ///
  /// In it, this message translates to:
  /// **'Comincia il sentiero'**
  String get carouselWelcomeCta;

  /// No description provided for @carouselCompanionTitle.
  ///
  /// In it, this message translates to:
  /// **'Un compagno per i tuoi ricordi'**
  String get carouselCompanionTitle;

  /// No description provided for @carouselCompanionBody.
  ///
  /// In it, this message translates to:
  /// **'Racconta quello che vuoi ricordare — a voce, con le parole, o con una foto.\nEl Troso lo custodirà per te.'**
  String get carouselCompanionBody;

  /// No description provided for @carouselRecordTitle.
  ///
  /// In it, this message translates to:
  /// **'Raccontami un ricordo'**
  String get carouselRecordTitle;

  /// No description provided for @carouselRecordBody.
  ///
  /// In it, this message translates to:
  /// **'Parla, scrivi, o scatta una foto.\nIo ascolto e ricordo tutto al posto tuo.'**
  String get carouselRecordBody;

  /// No description provided for @carouselRediscoverTitle.
  ///
  /// In it, this message translates to:
  /// **'Ripercorri il sentiero'**
  String get carouselRediscoverTitle;

  /// No description provided for @carouselRediscoverBody.
  ///
  /// In it, this message translates to:
  /// **'Quando vuoi, chiedi.\nIo ti rileggo i tuoi ricordi,\ncon la tua voce e le tue parole.'**
  String get carouselRediscoverBody;

  /// No description provided for @carouselPrivacyTitle.
  ///
  /// In it, this message translates to:
  /// **'Tutto resta qui, con te'**
  String get carouselPrivacyTitle;

  /// No description provided for @carouselPrivacyBody.
  ///
  /// In it, this message translates to:
  /// **'Nessun dato esce dal tuo telefono.\nI tuoi ricordi sono solo tuoi —\nEl Troso funziona senza internet.'**
  String get carouselPrivacyBody;

  /// No description provided for @carouselPrivacyCta.
  ///
  /// In it, this message translates to:
  /// **'Sono pronto'**
  String get carouselPrivacyCta;

  /// No description provided for @carouselSkip.
  ///
  /// In it, this message translates to:
  /// **'Salta'**
  String get carouselSkip;

  /// No description provided for @carouselNext.
  ///
  /// In it, this message translates to:
  /// **'Avanti'**
  String get carouselNext;

  /// No description provided for @drawerHome.
  ///
  /// In it, this message translates to:
  /// **'Casa'**
  String get drawerHome;

  /// No description provided for @drawerRecord.
  ///
  /// In it, this message translates to:
  /// **'Racconta un ricordo'**
  String get drawerRecord;

  /// No description provided for @drawerAsk.
  ///
  /// In it, this message translates to:
  /// **'Fai una domanda'**
  String get drawerAsk;

  /// No description provided for @drawerOnboarding.
  ///
  /// In it, this message translates to:
  /// **'Come funziona'**
  String get drawerOnboarding;

  /// No description provided for @drawerPlayground.
  ///
  /// In it, this message translates to:
  /// **'Playground (dev)'**
  String get drawerPlayground;

  /// No description provided for @drawerLanguage.
  ///
  /// In it, this message translates to:
  /// **'Lingua'**
  String get drawerLanguage;

  /// No description provided for @memoryTranslateCta.
  ///
  /// In it, this message translates to:
  /// **'Traduci'**
  String get memoryTranslateCta;

  /// No description provided for @memoryTranslating.
  ///
  /// In it, this message translates to:
  /// **'Sto traducendo…'**
  String get memoryTranslating;

  /// No description provided for @memoryTranslationLabel.
  ///
  /// In it, this message translates to:
  /// **'Traduzione'**
  String get memoryTranslationLabel;

  /// No description provided for @memoryTranslateError.
  ///
  /// In it, this message translates to:
  /// **'Non sono riuscito a tradurre. Riprova tra un momento.'**
  String get memoryTranslateError;

  /// No description provided for @memoryTranslateRedoCta.
  ///
  /// In it, this message translates to:
  /// **'Traduci di nuovo'**
  String get memoryTranslateRedoCta;

  /// No description provided for @recordExitTitle.
  ///
  /// In it, this message translates to:
  /// **'Vuoi uscire?'**
  String get recordExitTitle;

  /// No description provided for @recordExitBody.
  ///
  /// In it, this message translates to:
  /// **'Il ricordo non sarà custodito.'**
  String get recordExitBody;

  /// No description provided for @recordExitConfirm.
  ///
  /// In it, this message translates to:
  /// **'Sì, esci'**
  String get recordExitConfirm;

  /// No description provided for @recordExitCancel.
  ///
  /// In it, this message translates to:
  /// **'No, resta'**
  String get recordExitCancel;

  /// Header della sezione voce/RAG nella home: racconto, ripercorro, fai una domanda.
  ///
  /// In it, this message translates to:
  /// **'Cammina sul sentiero'**
  String get homeWalkSection;

  /// Header della sezione giochi nella home: G3 riconosci, G1 memoria delle foto.
  ///
  /// In it, this message translates to:
  /// **'Allena la memoria'**
  String get homeTrainSection;

  /// Sotto-saluto della Home v4 quando G4 SRT ha una proposta del giorno (todays != null).
  ///
  /// In it, this message translates to:
  /// **'oggi c\'è un ricordo che vale la pena ripercorrere.'**
  String get homeSubGreetingWithToday;

  /// Sotto-saluto della Home v4 quando G4 non ha proposte (tutti i ricordi freschi).
  ///
  /// In it, this message translates to:
  /// **'il sentiero è tutto fresco. Se vuoi, raccontami qualcosa.'**
  String get homeSubGreetingNoToday;

  /// Header della galleria orizzontale di ricordi recenti nella Home v4.
  ///
  /// In it, this message translates to:
  /// **'I tuoi ricordi'**
  String get homeYourMemories;

  /// CTA breve nella home v4 (riga di 2 outlined button) che apre la modal di scelta tra G3 e G1.
  ///
  /// In it, this message translates to:
  /// **'Gioca'**
  String get homeGamesCta;

  /// Tooltip dell'icona giochi (G1 + G3) nell'AppBar della Home v4.
  ///
  /// In it, this message translates to:
  /// **'Allena la memoria'**
  String get homeAppBarGamesTooltip;

  /// Tooltip dell'icona Ask nell'AppBar della Home v4.
  ///
  /// In it, this message translates to:
  /// **'Fai una domanda'**
  String get homeAppBarAskTooltip;

  /// Titolo della modal sheet che appare al tap sull'icona giochi: lista G1 + G3.
  ///
  /// In it, this message translates to:
  /// **'Allena la memoria'**
  String get homeGamesPickerTitle;

  /// Titolo della card di Spaced Retrieval (G4) in cima alla home.
  ///
  /// In it, this message translates to:
  /// **'Oggi'**
  String get homeTodayTitle;

  /// Testo invitante (non imperativo) della card OGGI.
  ///
  /// In it, this message translates to:
  /// **'C\'è un ricordo che sarebbe bello ripercorrere oggi.'**
  String get homeTodayBody;

  /// No description provided for @homeTodayCta.
  ///
  /// In it, this message translates to:
  /// **'Ripercorrilo ora'**
  String get homeTodayCta;

  /// Nome del gioco G3: una foto del proprio archivio, l'utente racconta cosa ricorda.
  ///
  /// In it, this message translates to:
  /// **'Riconosci e racconta'**
  String get gameRecognizeTitle;

  /// No description provided for @gameRecognizeShort.
  ///
  /// In it, this message translates to:
  /// **'Una foto, una storia'**
  String get gameRecognizeShort;

  /// Nome del gioco G1: memory matching con coppie di foto del proprio archivio.
  ///
  /// In it, this message translates to:
  /// **'Memoria delle foto'**
  String get gamePhotoMatchTitle;

  /// No description provided for @gamePhotoMatchShort.
  ///
  /// In it, this message translates to:
  /// **'Trova le coppie'**
  String get gamePhotoMatchShort;

  /// Riassunto numero ricordi sotto il saluto.
  ///
  /// In it, this message translates to:
  /// **'{n, plural, =0{Ancora nessun ricordo} =1{1 ricordo nel sentiero} other{{n} ricordi nel sentiero}}'**
  String homeMemoriesCount(int n);

  /// Riassunto ricordi con footprintOpacity < 1.0. Concatenato a homeMemoriesCount.
  ///
  /// In it, this message translates to:
  /// **'{n, plural, =1{Uno sta sbiadendo} other{{n} stanno sbiadendo}}'**
  String homeFadingCount(int n);

  /// Prompt principale di G3 sotto la foto.
  ///
  /// In it, this message translates to:
  /// **'Riconosci questa foto? Raccontami cosa ricordi.'**
  String get recognizePromptQ;

  /// No description provided for @recognizeStartCta.
  ///
  /// In it, this message translates to:
  /// **'Comincia a raccontare'**
  String get recognizeStartCta;

  /// No description provided for @recognizeRetryCta.
  ///
  /// In it, this message translates to:
  /// **'Racconta ancora'**
  String get recognizeRetryCta;

  /// No description provided for @recognizeStopCta.
  ///
  /// In it, this message translates to:
  /// **'Ho finito'**
  String get recognizeStopCta;

  /// CTA per inviare il racconto a Gemma e ricevere il feedback caldo.
  ///
  /// In it, this message translates to:
  /// **'Sentiamo cosa ne pensa'**
  String get recognizeSendCta;

  /// No description provided for @recognizeAnotherCta.
  ///
  /// In it, this message translates to:
  /// **'Un\'altra foto'**
  String get recognizeAnotherCta;

  /// Hint del TextField in G3: input alternativo alla voce.
  ///
  /// In it, this message translates to:
  /// **'Scrivi qui, oppure tappa il microfono'**
  String get recognizeTypeHint;

  /// Nome del gioco G2: Gemma genera una domanda specifica su un ricordo dell'utente, l'utente risponde, Gemma valuta.
  ///
  /// In it, this message translates to:
  /// **'Indovina insieme'**
  String get gameGuessTitle;

  /// No description provided for @gameGuessShort.
  ///
  /// In it, this message translates to:
  /// **'Una domanda, una risposta'**
  String get gameGuessShort;

  /// No description provided for @gameGuessGenerating.
  ///
  /// In it, this message translates to:
  /// **'Sto pensando a una domanda…'**
  String get gameGuessGenerating;

  /// No description provided for @gameGuessAnswerHint.
  ///
  /// In it, this message translates to:
  /// **'Scrivi qui la tua risposta, oppure tappa il microfono'**
  String get gameGuessAnswerHint;

  /// No description provided for @gameGuessSpeakCta.
  ///
  /// In it, this message translates to:
  /// **'Rispondi a voce'**
  String get gameGuessSpeakCta;

  /// No description provided for @gameGuessSendCta.
  ///
  /// In it, this message translates to:
  /// **'Vediamo'**
  String get gameGuessSendCta;

  /// No description provided for @gameGuessAnotherCta.
  ///
  /// In it, this message translates to:
  /// **'Un\'altra domanda'**
  String get gameGuessAnotherCta;

  /// No description provided for @gameGuessEmptyBody.
  ///
  /// In it, this message translates to:
  /// **'Per giocare servono ricordi raccontati. Aggiungi qualche ricordo più ricco e torna qui.'**
  String get gameGuessEmptyBody;

  /// No description provided for @guessInfoTitle.
  ///
  /// In it, this message translates to:
  /// **'Indovina insieme'**
  String get guessInfoTitle;

  /// No description provided for @guessInfoWhat.
  ///
  /// In it, this message translates to:
  /// **'L\'app ti pone una domanda specifica su uno dei tuoi ricordi (un anno, un luogo, una persona, un evento). Tu rispondi a voce o per iscritto, e poi senti la risposta giusta presa dal ricordo.'**
  String get guessInfoWhat;

  /// No description provided for @guessInfoWhy.
  ///
  /// In it, this message translates to:
  /// **'Rispondere a una domanda specifica è una forma di richiamo attivo: la memoria si consolida meglio interrogandola che rileggendola passivamente. Lo Spaced Retrieval Training, validato da RCT su pazienti con decadimento cognitivo lieve, è proprio questo — domanda breve, risposta, feedback caldo. Niente punteggi, niente errori sottolineati: se la risposta non c\'è, l\'app riporta gentilmente al fatto.'**
  String get guessInfoWhy;

  /// No description provided for @guessInfoSource1Label.
  ///
  /// In it, this message translates to:
  /// **'USMART RCT (2017) — spaced retrieval training su tablet in MCI'**
  String get guessInfoSource1Label;

  /// No description provided for @guessInfoSource1Url.
  ///
  /// In it, this message translates to:
  /// **'https://doi.org/10.1186/s13195-017-0290-6'**
  String get guessInfoSource1Url;

  /// No description provided for @guessInfoSource2Label.
  ///
  /// In it, this message translates to:
  /// **'Roediger & Karpicke (2006) — testing effect, ricordare interrogando'**
  String get guessInfoSource2Label;

  /// No description provided for @guessInfoSource2Url.
  ///
  /// In it, this message translates to:
  /// **'https://doi.org/10.1111/j.1467-9280.2006.01693.x'**
  String get guessInfoSource2Url;

  /// Nome del gioco G5: app legge l'incipit di un ricordo, l'utente continua a voce, Gemma confronta.
  ///
  /// In it, this message translates to:
  /// **'Storia continua'**
  String get gameStoryTitle;

  /// No description provided for @gameStoryShort.
  ///
  /// In it, this message translates to:
  /// **'Continuala tu'**
  String get gameStoryShort;

  /// Invito che appare sotto l'incipit del ricordo: l'utente è chiamato a continuare la storia.
  ///
  /// In it, this message translates to:
  /// **'…e poi cosa è successo?'**
  String get gameStoryPrompt;

  /// No description provided for @gameStoryContinueHint.
  ///
  /// In it, this message translates to:
  /// **'Continua tu il ricordo… (parla o scrivi)'**
  String get gameStoryContinueHint;

  /// No description provided for @gameStorySendCta.
  ///
  /// In it, this message translates to:
  /// **'Vediamo come continua'**
  String get gameStorySendCta;

  /// No description provided for @gameStoryAnotherCta.
  ///
  /// In it, this message translates to:
  /// **'Un altro ricordo'**
  String get gameStoryAnotherCta;

  /// Etichetta sopra al testo del ricordo intero, mostrato dopo il feedback per consentire rilettura.
  ///
  /// In it, this message translates to:
  /// **'Il ricordo completo'**
  String get gameStoryFullMemoryLabel;

  /// No description provided for @gameStoryEmptyBody.
  ///
  /// In it, this message translates to:
  /// **'Per giocare servono ricordi un po\' lunghi (almeno due frasi). Aggiungi un ricordo più ricco e torna qui.'**
  String get gameStoryEmptyBody;

  /// No description provided for @storyInfoTitle.
  ///
  /// In it, this message translates to:
  /// **'Storia continua'**
  String get storyInfoTitle;

  /// No description provided for @storyInfoWhat.
  ///
  /// In it, this message translates to:
  /// **'L\'app legge a voce le prime frasi di un tuo ricordo, poi ti chiede di continuarlo. Tu racconti come pensi sia andata, e l\'app ti dà un feedback caldo confrontando con il ricordo originale. Alla fine vedi il ricordo per intero.'**
  String get storyInfoWhat;

  /// No description provided for @storyInfoWhy.
  ///
  /// In it, this message translates to:
  /// **'Continuare a voce un ricordo a partire da un cue narrativo è il modo più simile a come la memoria autobiografica funziona spontaneamente: non un quiz a domande chiuse, ma una storia che si srotola. La stimolazione narrativa guidata ha mostrato benefici sulla memoria episodica autobiografica in pazienti con decadimento lieve, soprattutto quando il materiale è personale.'**
  String get storyInfoWhy;

  /// No description provided for @storyInfoSource1Label.
  ///
  /// In it, this message translates to:
  /// **'Cotelli et al. (2012) — riabilitazione cognitiva narrativa in MCI/AD'**
  String get storyInfoSource1Label;

  /// No description provided for @storyInfoSource1Url.
  ///
  /// In it, this message translates to:
  /// **'https://pubmed.ncbi.nlm.nih.gov/22466023/'**
  String get storyInfoSource1Url;

  /// No description provided for @storyInfoSource2Label.
  ///
  /// In it, this message translates to:
  /// **'Woods et al., Cochrane Review (2018) — reminiscence therapy in demenza'**
  String get storyInfoSource2Label;

  /// No description provided for @storyInfoSource2Url.
  ///
  /// In it, this message translates to:
  /// **'https://doi.org/10.1002/14651858.CD001120.pub3'**
  String get storyInfoSource2Url;

  /// No description provided for @recognizeNoPhotosBody.
  ///
  /// In it, this message translates to:
  /// **'Per giocare servono ricordi con una foto. Aggiungi prima una foto a un ricordo, poi torna qui.'**
  String get recognizeNoPhotosBody;

  /// Header della partita G1: quante coppie ha trovato.
  ///
  /// In it, this message translates to:
  /// **'{found} di {total} coppie'**
  String photoMatchPairs(int found, int total);

  /// Conta delle mosse (tap di seconda carta) nella partita G1.
  ///
  /// In it, this message translates to:
  /// **'{n, plural, =1{1 mossa} other{{n} mosse}}'**
  String photoMatchMoves(int n);

  /// Titolo della schermata di vittoria G1. Coerente con la metafora del troso (sentiero che si ricongiunge).
  ///
  /// In it, this message translates to:
  /// **'Sentiero ritrovato'**
  String get photoMatchWonTitle;

  /// No description provided for @photoMatchWonBody.
  ///
  /// In it, this message translates to:
  /// **'{n, plural, =1{Hai trovato tutte le coppie in 1 mossa.} other{Hai trovato tutte le coppie in {n} mosse.}}'**
  String photoMatchWonBody(int n);

  /// No description provided for @photoMatchRetryCta.
  ///
  /// In it, this message translates to:
  /// **'Un\'altra partita'**
  String get photoMatchRetryCta;

  /// No description provided for @photoMatchNotEnoughBody.
  ///
  /// In it, this message translates to:
  /// **'Per giocare servono almeno sei ricordi con una foto. Racconta qualche ricordo in più e torna qui.'**
  String get photoMatchNotEnoughBody;

  /// Messaggio TTS pronunciato a fine gioco G1 quando il profilo ha un nome/vocativo. Coerente con la metafora 'orme che brillano' del trittico el troso.
  ///
  /// In it, this message translates to:
  /// **'Bravissimo {name}, hai ritrovato tutte le coppie. Le orme di questi ricordi tornano luminose.'**
  String photoMatchWonTtsWithName(String name);

  /// Variante del messaggio TTS quando il profilo non ha un nome utilizzabile.
  ///
  /// In it, this message translates to:
  /// **'Bravissimo, hai ritrovato tutte le coppie. Le orme di questi ricordi tornano luminose.'**
  String get photoMatchWonTtsNoName;

  /// Etichetta per orma luminosa (footprintOpacity 1.0): ricordo ripercorso entro gli ultimi 7 giorni.
  ///
  /// In it, this message translates to:
  /// **'appena calpestato'**
  String get legendFresh;

  /// Etichetta per orma a opacity 0.6: ricordo non calpestato da 7-13 giorni.
  ///
  /// In it, this message translates to:
  /// **'sta sbiadendo'**
  String get legendFading;

  /// Etichetta per orma a opacity 0.3: ricordo non calpestato da 14+ giorni.
  ///
  /// In it, this message translates to:
  /// **'quasi dimenticato'**
  String get legendGhost;

  /// Titolo della mini-card che appare in home dopo qualunque walk (G3, G4, G1, Ripercorri normale). Visibile per 5 secondi.
  ///
  /// In it, this message translates to:
  /// **'Hai ripercorso questo ricordo'**
  String get walkConfirmedTitle;

  /// No description provided for @walkConfirmedBody.
  ///
  /// In it, this message translates to:
  /// **'Le orme tornano luminose.'**
  String get walkConfirmedBody;

  /// Titolo della schermata opt-in che chiede se pre-caricare i 12 ricordi seed di Giorgio. Mostrata in onboarding subito dopo il profilo, prima della home.
  ///
  /// In it, this message translates to:
  /// **'Vuoi cominciare con un libro di ricordi?'**
  String get onbSeedTitle;

  /// Testo della schermata seed offer: spiega cosa sono i seed e che sono opzionali / cancellabili.
  ///
  /// In it, this message translates to:
  /// **'Sono le memorie di Giorgio, 86 anni, che ha raccontato la sua vita ai nipoti in un libro. Puoi guardarle, ripercorrerle, e cancellarle quando vuoi per cominciare il tuo sentiero.'**
  String get onbSeedBody;

  /// CTA che carica i 12 ricordi seed dal bundle e va in home.
  ///
  /// In it, this message translates to:
  /// **'Sì, fammi vedere'**
  String get onbSeedCtaYes;

  /// CTA che salta il seed-load e va in home con sentiero vuoto.
  ///
  /// In it, this message translates to:
  /// **'No, comincio io'**
  String get onbSeedCtaNo;

  /// Stato transitorio mostrato mentre SeedLoader copia foto + scrive JSON (alcuni secondi).
  ///
  /// In it, this message translates to:
  /// **'Sto preparando i ricordi di Giorgio...'**
  String get onbSeedLoading;

  /// Titolo della schermata di preparazione del modello Gemma 4 al primo avvio. La metafora del sentiero che si forma e' branding-coerente.
  ///
  /// In it, this message translates to:
  /// **'Sto preparando il sentiero...'**
  String get modelLoadingTitle;

  /// No description provided for @modelLoadingBody.
  ///
  /// In it, this message translates to:
  /// **'Tutto resta nel tuo telefono. Niente esce di qui.'**
  String get modelLoadingBody;

  /// Sotto-titolo della prima sezione della GameInfoSheet (G3, G1, G4). Spiega cosa fa il gioco in parole semplici.
  ///
  /// In it, this message translates to:
  /// **'Di cosa si tratta'**
  String get gameInfoWhatTitle;

  /// Sotto-titolo della seconda sezione della GameInfoSheet. Sintesi EBM in linguaggio non clinico.
  ///
  /// In it, this message translates to:
  /// **'Perché funziona'**
  String get gameInfoWhyTitle;

  /// Sotto-titolo della lista di studi/review citate, tappabili per aprire DOI o PubMed nel browser.
  ///
  /// In it, this message translates to:
  /// **'Fonti'**
  String get gameInfoSourcesTitle;

  /// CTA che chiude la GameInfoSheet.
  ///
  /// In it, this message translates to:
  /// **'Ho capito'**
  String get gameInfoCloseCta;

  /// Titolo della info-sheet del gioco G3.
  ///
  /// In it, this message translates to:
  /// **'Riconosci e racconta'**
  String get recognizeInfoTitle;

  /// No description provided for @recognizeInfoWhat.
  ///
  /// In it, this message translates to:
  /// **'Vedi una foto del tuo album e racconti ad alta voce cosa ricordi. Non c\'è una risposta giusta o sbagliata: conta solo che la voce torni sul ricordo. Alla fine l\'app ti restituisce un piccolo riassunto di quello che hai detto.'**
  String get recognizeInfoWhat;

  /// No description provided for @recognizeInfoWhy.
  ///
  /// In it, this message translates to:
  /// **'Far tornare a parole un ricordo davanti a uno stimolo familiare è il cuore della reminiscence therapy: una conversazione 1-a-1 tra una persona e un suo ricordo, mediata qui dall\'app invece che da un familiare. Le revisioni Cochrane mostrano benefici piccoli ma costanti su umore, cognizione e qualità della vita — soprattutto quando lo stimolo è autobiografico, non generico.'**
  String get recognizeInfoWhy;

  /// No description provided for @recognizeInfoSource1Label.
  ///
  /// In it, this message translates to:
  /// **'Woods et al., Cochrane Review (2018) — reminiscence therapy in demenza'**
  String get recognizeInfoSource1Label;

  /// No description provided for @recognizeInfoSource1Url.
  ///
  /// In it, this message translates to:
  /// **'https://doi.org/10.1002/14651858.CD001120.pub3'**
  String get recognizeInfoSource1Url;

  /// No description provided for @recognizeInfoSource2Label.
  ///
  /// In it, this message translates to:
  /// **'Berry et al. (2014) — SenseCam e memoria autobiografica'**
  String get recognizeInfoSource2Label;

  /// No description provided for @recognizeInfoSource2Url.
  ///
  /// In it, this message translates to:
  /// **'https://pubmed.ncbi.nlm.nih.gov/16194452/'**
  String get recognizeInfoSource2Url;

  /// Titolo della info-sheet del gioco G1.
  ///
  /// In it, this message translates to:
  /// **'Memoria delle foto'**
  String get photoMatchInfoTitle;

  /// No description provided for @photoMatchInfoWhat.
  ///
  /// In it, this message translates to:
  /// **'Un classico memory: 6 coppie di foto coperte, scopri due carte alla volta finché non le hai abbinate tutte. Le foto vengono dal tuo album personale — non sono icone qualunque ma volti, luoghi e momenti che già conosci.'**
  String get photoMatchInfoWhat;

  /// No description provided for @photoMatchInfoWhy.
  ///
  /// In it, this message translates to:
  /// **'La memoria di riconoscimento visivo resta relativamente conservata anche nel decadimento cognitivo lieve, e i giochi seri costruiti su materiale autobiografico personalizzato sono un ingaggio emotivo più forte di un memory generico. Niente magia: serve a stare un po\' di tempo dentro le proprie foto, in modo attivo.'**
  String get photoMatchInfoWhy;

  /// No description provided for @photoMatchInfoSource1Label.
  ///
  /// In it, this message translates to:
  /// **'JMIR Serious Games (2024) — meta-analisi giochi cognitivi in MCI/AD'**
  String get photoMatchInfoSource1Label;

  /// No description provided for @photoMatchInfoSource1Url.
  ///
  /// In it, this message translates to:
  /// **'https://games.jmir.org/2024/1/e55785'**
  String get photoMatchInfoSource1Url;

  /// Titolo della info-sheet della card OGGI (G4 — Spaced Retrieval).
  ///
  /// In it, this message translates to:
  /// **'Oggi'**
  String get homeTodayInfoTitle;

  /// No description provided for @homeTodayInfoWhat.
  ///
  /// In it, this message translates to:
  /// **'Ogni giorno l\'app sceglie un ricordo che non ripercorri da un po\' e te lo propone in cima alla home. Se lo apri e lo riascolti, le sue \"orme\" tornano luminose e l\'app aspetta più giorni prima di riproportelo. Se lo lasci stare, torna prima.'**
  String get homeTodayInfoWhat;

  /// No description provided for @homeTodayInfoWhy.
  ///
  /// In it, this message translates to:
  /// **'Si chiama Spaced Retrieval Training: rinfrescare un\'informazione a intervalli che si allungano nel tempo (1, 3, 7, 14, 30 giorni) è una delle tecniche non-farmacologiche con le prove più solide per la memoria nel decadimento cognitivo lieve e nella demenza lieve. Funziona meglio quando il materiale è personale e quando l\'intervallo si adatta a come va il richiamo.'**
  String get homeTodayInfoWhy;

  /// No description provided for @homeTodayInfoSource1Label.
  ///
  /// In it, this message translates to:
  /// **'Hopper et al. (2013) — review di interventi spaced-retrieval'**
  String get homeTodayInfoSource1Label;

  /// No description provided for @homeTodayInfoSource1Url.
  ///
  /// In it, this message translates to:
  /// **'https://pubmed.ncbi.nlm.nih.gov/23886395/'**
  String get homeTodayInfoSource1Url;

  /// No description provided for @homeTodayInfoSource2Label.
  ///
  /// In it, this message translates to:
  /// **'USMART RCT (2017) — SRT su tablet in pazienti MCI'**
  String get homeTodayInfoSource2Label;

  /// No description provided for @homeTodayInfoSource2Url.
  ///
  /// In it, this message translates to:
  /// **'https://doi.org/10.1186/s13195-017-0290-6'**
  String get homeTodayInfoSource2Url;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
